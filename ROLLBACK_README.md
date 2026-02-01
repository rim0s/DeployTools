## 当前变更摘要 (2026-02-01)

注意: 仓库近期对回滚示例与管理器做了若干清理与改进, 下面列出会影响使用或需要文档同步的要点:
- 会话元数据与 last_session: `init_rollback_system` / `init_rollback_system_return` 在事务目录写入 `session.meta`，并向 `${ROLLBACK_PREFIX}/last_session.txt` 写入最新会话 ID，便于脚本打印与后续恢复 (示例脚本会在完成时打印 `SESSION_ID`).
- 新增工具: `tools/rollback_sessions.sh`, 用于列出和查看已保存的回滚会话 (session meta / operations.log). README 之前未列出该工具.
- 示例脚本: 新增 `rollback_example_eg1.sh`, 支持 `--yes` (防止误操作)、`--dryrun` (仅打印命令, 不执行) 和 `--restore <session>` (从持久化会话恢复). 建议在 README 中参考该示例的用法进行演练和集成测试.
- 日志模块健壮性：`lib/logger.sh` 已做健壮性修正（如避免在 `set -u` 下访问未定义数组时报错），脚本在被 `source` 时更稳定。
- 管理器实现说明：仓库中 `lib/rollback-manager.sh` 已被替换为一个更小、更稳健的实现以恢复基础 API（`op_prewrite`/`op_commit`/`rollback_all`/`_load_transaction_into_memory` 等）。README 中对若些高级特性的描述（例如 `--auto-load`、`register_operation_at`、`.stack_order` 快照交互加载等）可能与当前最小实现不完全一致——请以代码为准或在需要时同步实现/文档。

建议：我已把这些要点记录在本节。若你希望我把 README 中的高级特性说明与当前代码完全对齐（要么实现功能，要么删除/降级文档），我可以继续实现或调整文档并提交 PR。
**Rollback 子系统 总览**

- **目的**: 为项目提供一致、可注册、可回放的回滚 (undo) 能力，支持单次操作回滚、批次回滚与检查点恢复。

**相关文件 (位于 `lib/`)**
- `rollback-manager.sh`: 回滚子系统初始化、全局变量与自动加载 `rollback-*.sh` 模块。
- `rollback_operation.sh`: 执行单个或全部回滚操作的引擎 (`rollback_operation` / `rollback_all`).
- `rollback-batch-manage.sh`: 批次（transaction/batch）管理：开始批次、回滚批次等。
- `rollback-checkpoint-manage.sh`: 检查点保存/恢复接口。
- `rollback-file-ops.sh`: 带回滚的文件操作（`safe_cp` / `safe_mv`）。
- `rollback-dir-manage.sh`, `rollback-conf-change.sh`, `rollback-pkg-change.sh`,
  `rollback-service-manage.sh`, `rollback-user_group-manage.sh`：各类操作的封装模块。
- `logger.sh`: 日志输出（供回滚模块记录信息与错误）。

**核心概念与流程**
- 注册: 各操作通过 `register_operation <op_id> <rollback_cmd> <desc>` 向回滚系统注册回滚命令，并将 `op_id` 推入 `OPERATION_STACK`。请注意: `register_operation` 仅做预写 (prewrite, 写入 pending)，并**不会**自动把条目标记为 committed; 调用者必须在主操作成功后显式调用 `op_commit <op_id>` 来完成提交.
- 记录: 会在当前事务目录 (由 `ROLLBACK_PREFIX` 与 `TRANSACTION_ID` 组成) 中记录 `operations.log` (含 `op_id` 与简短描述).
- 回滚执行: `rollback_operation <op_id>` 会按注册的回滚命令执行 (通常用 `eval` 或安全替代), 并从状态中移除该操作. `rollback_all`/按批次回滚会逆序执行 `OPERATION_STACK` 中的命令.
- 批次/检查点: `begin_batch`/`add_to_batch` 用于把若干操作归为一组; 检查点 (checkpoint) 会将当前 `OPERATION_STACK` 与回滚命令快照到文件, 供后续 `restore_to_checkpoint` 使用.

**配置变量**
- `ROLLBACK_PREFIX`: 回滚数据存放根目录 (默认实现在项目下 `.rollback_data` 或者可由环境覆盖).
- `TRANSACTION_ID`：当前事务/批次唯一标识（脚本通常在 `init_rollback_system` 中生成）。

**如何在脚本中使用 (示例)**
1. 在脚本顶部 source 回滚管理：

```bash
source "$(dirname "$0")/lib/rollback-manager.sh"
init_rollback_system   # 可选参数：自定义 ROLLBACK_PREFIX
```

2. 使用封装好的安全函数（示例）：

```bash
# 复制并在需要时可回滚
safe_cp "/tmp/foo" "/etc/foo.conf"

# 或者注册自定义回滚命令（注意：register_operation 仅 prewrite）
opid=$(register_operation "edit_conf_$(date +%s)" "cp /backup/foo /etc/foo.conf" "restore foo.conf")

# 在执行主操作并确认成功后，显式提交回滚记录：
if do_main_edit; then
  op_commit "$opid"
else
  rollback_operation "$opid"
fi
```

3. 当需要回滚时：

```bash
# 回滚单个操作
rollback_operation "$opid"

# 全部回滚（逆序）
rollback_all
```

**扩展开发指南（添加新的 `rollback-*.sh` 模块）**
- 文件位置：把新模块放在 `lib/`，并以 `rollback-` 前缀命名（例如 `rollback-ssh-keys.sh`），`rollback-manager.sh` 会自动 `source` 加载。
- 接口约定：实现功能函数（例如 `safe_add_ssh_key()`），在变更系统前或变更成功后调用 `register_operation`：

  - `register_operation <op_id> <rollback_cmd> <desc>` 返回 `op_id`（可省略返回值），并将该条目写为 pending（预写）。调用者负责在主操作成功后调用 `op_commit <op_id>` 将其转为 committed 并追加到 `operations.log`。保持 `op_id` 唯一。
  - 回滚命令应为可在 shell 中直接执行的语句串（必要时用单引号包裹路径与参数）。
  - 回滚命令应尽量保证幂等或在执行失败时可安全继续（并记录失败）。

- 日志：请用 `log_info` / `log_warn` / `log_error`（来自 `logger.sh`）记录操作状态与错误。
- 输入校验：对外部路径/用户输入做严格验证，避免向 `register_operation` 注册危险命令。
- 原子性与顺序：如果操作由多个子步骤组成，建议把恢复命令合并为单个回滚命令串，或为每一步分别注册并确保回滚顺序正确（后注册先回滚）。

**测试与 CI 建议**
- 在 CI 或本地测试中，避免对真实系统目录（如 `/etc`）直接修改，改用临时目录（如 `/tmp/test-rollback`）。
- 提供测试脚本覆盖：
  - 成功路径：执行操作并验证回滚后资源恢复。
  - 失败路径：模拟中间失败并验证部分回滚与清理行为。

**注意事项与安全**
- 权限：某些回滚命令需要 root 权限；在测试或自动化环境中请使用受控容器或虚拟机。
- 干净的回滚：回滚命令本身可能失败，请在 `rollback_operation` 中记录失败并继续执行其他回滚项（避免中断导致不完整回滚）。
- 并发：当前实现以简单文件/目录存储状态，没有复杂锁机制。若并发运行回滚/操作，请添加进程锁（`flock`）或基于原子重命名的策略以避免 race 条件。

**目录/大文件操作增强（已更新）**

- 核心变更摘要：
  - 单文件操作（`safe_cp` / `safe_mv` 的文件分支）现在强制执行双重哈希校验：先使用 `sha256`（通过 `sha256sum` 或 `shasum -a 256`），再使用 `md5`（通过 `md5sum` 或 `md5`）。若任一哈希工具不可用或任一哈希不匹配，操作将回滚并返回错误。此行为不可被关闭（为保证单文件一致性）。
  - 目录递归（多文件）操作仍使用 manifest 校验机制，但是否启用目录校验现在由 `ROLLBACK_DIR_VERIFY_CHECKSUM` 控制（默认继承自 `ROLLBACK_VERIFY_CHECKSUM`）。大文件仍可根据阈值降级为 size+mtime 判断。

- 具体函数与变量：
  - `compute_sha256 <file>` / `compute_md5 <file>`: 分别计算文件的 sha256 与 md5 (优先使用系统工具 `sha256sum`/`shasum` 与 `md5sum`/`md5`).
  - 单文件流程：在执行单文件复制/移动前会计算源文件的 sha256 与 md5，执行后再分别计算目标文件两种哈希并逐一比较；若无法计算任一哈希或比较不一致，回滚操作并失败。
  - 目录流程 (递归): `generate_manifest <srcdir> <manifest_out>` 仍生成 TSV (relpath, size, mtime, checksum); 实际是否计算 checksum 由 `ROLLBACK_DIR_VERIFY_CHECKSUM` 控制, 并且对于大于 `ROLLBACK_LARGE_FILE_THRESHOLD_BYTES` (默认 50MB) 的文件会跳过 checksum, 仅比较 size/mtime.

- 配置与安全：
  - `ROLLBACK_DIR_VERIFY_CHECKSUM`：控制目录递归时是否对每个小文件计算 checksum（默认值继承自 `ROLLBACK_VERIFY_CHECKSUM`）。
  - `ROLLBACK_VERIFY_CHECKSUM`：历史通用开关（保留并作为默认继承源），但单文件操作的双哈希校验为强制行为，不受此变量关闭影响。
  - `ROLLBACK_LARGE_FILE_THRESHOLD_BYTES`：大文件阈值（默认 50MB），超过后会在目录校验中跳过 checksum，仅使用 size/mtime 判断以节省时间/IO。
  - 依赖工具：`sha256sum` 或 `shasum -a 256`，以及 `md5sum` 或 `md5`。在缺少相应工具时，单文件操作会失败并回滚，以避免不安全的假设。

- 空间评估与备份策略（保持不变）：
  - `check_space_for_operation <src> <backup_root>`：估算源大小并与备份目录所在分区可用空间比较。若空间不足，目录操作可能退化为 manifest-only 模式（不复制完整目标到事务备份目录），并记录警告。

- 冲突处理模式（无改动）：
  - `ROLLBACK_ROLLBACK_CONFLICT_MODE` 可取 `skip`|`overwrite`|`merge`，`merge` 模式仍会在 pending 下生成 `.merge` 目录与合并报告，返回特殊退出码 `2` 以便人工介入。

**示例：目录复制（带 merge 模式）**

```bash
# 预初始化回滚系统
source "$(dirname "$0")/lib/rollback-manager.sh"
init_rollback_system

# 设置为 merge 模式（可在环境或脚本中设定）
export ROLLBACK_ROLLBACK_CONFLICT_MODE=merge

# 执行递归复制（内部会 prewrite -> copy -> verify）
opid=$(safe_cp -r /tmp/source_dir /opt/app/configs)
rc=$?
if [[ $rc -eq 0 ]]; then
  echo "复制完成，opid=$opid"
elif [[ $rc -eq 2 ]]; then
  echo "复制存在冲突，生成合并目录: ${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/${opid}.merge"
  echo "请查看合并报告并手动合并后再调用 op_commit $opid 或手动清理。"
else
  echo "复制失败或回滚已触发" >&2
fi
```

**交互式合并辅助（快速示例）**

如果你希望在冲突文件上逐个做出决定，可以使用仓库提供的交互式工具 `tools/merge-helper.sh`：

```bash
# 进入交互式模式并把选择写回目标目录
tools/merge-helper.sh --merge-dir "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/<opid>.merge" interactive /path/to/target

# 快速列出冲突并查看报告
tools/merge-helper.sh --merge-dir "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/<opid>.merge" list
tools/merge-helper.sh --merge-dir "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/<opid>.merge" show-report
```

交互式模式支持查看单文件 diff、接受 `ours` 或 `theirs`、跳过单个项、一次性接受全部等操作，并且在修改目标前会为目标文件做 `.bak.<timestamp>` 备份以便回滚。


**注意**：当 `merge` 模式生成合并目录后，回滚记录尚未 commit（pending）；你可以在人工合并并确认后调用 `op_commit <opid>`；若合并不可接受，可调用 `rollback_operation <opid>` 来恢复备份（如果存在）。

**在回滚序列中插入自定义操作**

你可以在运行时把新的回滚操作插入到回滚序列的任意位置，以便定制回滚逻辑（例如在某些关键步骤之前插入额外的清理或审计操作）。有两种方法：

- 内存中插入（临时，当前进程有效）：
  - 调用 `register_operation`（或 `op_prewrite`）创建 `opid`，然后直接修改内存数组 `OPERATION_STACK`，例如在索引 N 前插入：

```bash
# 在脚本中（当前 shell 进程）
opid=$(register_operation "" "echo 'cleanup A'" "cleanup A")
N=2
OPERATION_STACK=( "${OPERATION_STACK[@]:0:N}" "$opid" "${OPERATION_STACK[@]:N}" )
```

  - 这种方式简单快速，但不是持久化的：进程退出或脚本崩溃后插入顺序会丢失。

- 使用新增的 `register_operation_at`（推荐，用于持久化插入）：
  - 函数签名：`register_operation_at <index|end> <op_id_or_empty> <rollback_cmd> [description]`
  - 示例：在索引 1 前插入并持久化顺序快照：

```bash
# 在脚本中使用（index 从 0 开始）
opid=$(register_operation_at 1 "" "cp /backup/conf /etc/conf" "restore conf")
# 返回 opid，且会把 pending 条目写入事务 pending 目录，并在
# ${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/.stack_order 中保存当前 OPERATION_STACK 快照。
```

  - 该函数会：
    - 在内存中把新 `opid` 插入 `OPERATION_STACK` 的指定位置；
    - 调用 `op_prewrite` 把回滚命令写入 pending；
    - 将当前 `OPERATION_STACK` 的快照写入 `${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/.stack_order`，便于重启或恢复时参考。

注意事项：
  - 插入新操作后仍需在主操作成功后调用 `op_commit <opid>` 来把 pending 转为 committed；若你希望把整个序列的变更一次性固化，请使用检查点/批次接口保存快照。
  - 在并发场景，请在修改 `OPERATION_STACK` 或写入 `.stack_order` 时加文件锁（`flock`）以避免竞态。

**自动恢复与加载已有 pending 事务**

`init_rollback_system` 现在会在初始化后扫描 `${ROLLBACK_PREFIX}` 下是否存在其它含有 pending 文件的事务目录。如果发现，会询问用户是否要把其中一个 pending 事务加载到当前会话（交互式提示）。

加载行为：
- 如果用户选择加载某个事务，脚本会把该事务的 `pending/.stack_order` （若存在）读入 `OPERATION_STACK`，并从 `pending/<opid>` 文件中读取回滚命令以填充 `ROLLBACK_COMMANDS`。
- 同时会把 `TRANSACTION_ID` 切换为所选事务 ID，使后续的 `op_commit`/`rollback_operation` 针对该事务工作。

安全提示：
- 加载操作会覆盖当前会话内存中 `OPERATION_STACK` 的内容，请确保在执行此操作前没有未提交的重要内存变更。
- 如果你在非交互环境（CI、systemd 等）使用，请不要依赖交互提示；可以通过脚本化选择或直接调用 `_load_transaction_into_memory <txid>`（内部函数）来恢复特定事务。

非交互自动加载

- `init_rollback_system` 现在支持可选参数 `--auto-load <txid>`：在初始化时直接加载指定事务并返回（不会弹出交互提示）。
- 也可以通过环境变量 `ROLLBACK_AUTO_LOAD_TXID` 指定要自动加载的事务 ID（优先级低于 `--auto-load` 参数）。

示例：非交互脚本中自动加载事务 `tx_1610000000_abcd`：

```bash
# 使用参数方式
init_rollback_system --auto-load tx_1610000000_abcd

# 或使用环境变量
export ROLLBACK_AUTO_LOAD_TXID=tx_1610000000_abcd
init_rollback_system
```

注意：自动加载会覆盖当前内存中的 `OPERATION_STACK`，请在自动加载前确认没有未提交的重要内存变更。


便捷函数：

- `register_operation_before <existing_opid> <op_id_or_empty> <rollback_cmd> [description]`：在 `existing_opid` 前插入新操作并持久化 pending 与栈快照。
- `register_operation_after <existing_opid> <op_id_or_empty> <rollback_cmd> [description]`：在 `existing_opid` 后插入新操作。

示例：在已存在的 `op123` 之后插入一个清理操作并持久化：

```bash
newop=$(register_operation_after op123 "" "rm -f /tmp/tempfile" "cleanup tempfile")
# 执行主操作，成功后提交回滚条目
do_something && op_commit "$newop"
```



**示例目录/文件定位**
- 查看主实现：`lib/rollback-manager.sh`、`lib/rollback_operation.sh`。
- 操作封装示例：`lib/rollback-file-ops.sh`、`lib/rollback-conf-change.sh`。


