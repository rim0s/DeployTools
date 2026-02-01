# ProjectManage - 模块化Linux项目管理脚本

## 概述

本项目对原 `ProjectManage_V48.sh` (7542 行) 进行模块化重构，拆分为可维护的功能模块。项目主入口为项目根目录的 `ProjectManage.sh` (包含 main)。README 中提到的 `main.sh` 是留给使用者基于本框架自定义的示例入口文件。

## 目录结构

```
ProjectManage/
├── ProjectManage.sh        # 主函数入口 (本项目实际运行入口)
├── lib/                    # 功能模块目录
│   ├── 基础与工具: constants.sh, config.sh, utils.sh, logger.sh, banner.sh, sudo.sh, firewall.sh, init.sh, loader.sh
│   ├── 网络与包管理: network.sh, package.sh, package_advanced.sh, path.sh
│   ├── 配置解析: config_file.sh, parser.sh
│   ├── 项目任务: project.sh
│   ├── 服务与系统: nfs.sh, vnc.sh, httpd.sh, security.sh, device.sh, system.sh
│   └── 其他: monitor.sh, help.sh, debug.sh, constants.sh 等
├── history_release/        # 历史版本
├── docs/                   # 文档
└── README.md               # 本文件
```

## 模块说明与函数清单 (未测试标记仅针对今日新增模块)

### 基础与通用
- **constants.sh**: 颜色常量、版本信息、Banner 编码、日志级别映射
- **config.sh**: 全局变量、路径、开关、系统/防火墙/服务配置
- **utils.sh**: 字符串处理、随机串、终端响铃、中文检测
- **logger.sh**: `log_message`/`LOG_message`/`LOG_line`/`log_MESSAGE`、调用链追踪、日志初始化
- **sudo.sh**: `sudo_execute`/`sudo_execute_gui`/`sudo_execute_quiet`/`sudo_execute_once`/`unsudo_execute`
- **banner.sh**: `show_banner`/`show_banner_base64`/`show_banner_ascii`/`show_tail`
- **firewall.sh**: `is_firewalld_active`/`is_iptables_active`/`get_active_firewall`/`add_firewall_ports`/`remove_firewall_ports`/`add_icmp_reply_block_rule`/`remove_icmp_reply_block_rule`
- **init.sh**: `init_tmp`/`init_the_batch`/`end_the_batch`
- **loader.sh**: 模块加载器
- **debug.sh**: `bp`/`breakpoint`/`run_command`/`end_debug` (调试辅助)

### 网络与包管理
- **network.sh**: `check_internet`/`check_intranet_ip`/`check_connectivity`/`get_all_ip`
- **package.sh**: 基础包管理封装
- **package_advanced.sh**: `check_Package_installed`/`check_packages_installed`/`install_package`/`dnf_install_packages`
- **path.sh**: `check_path_available`/`make_s_ln`/`create_directory`/`create_directory_gui`

### 配置解析与参数处理
- **config_file.sh**: `extract_item_grep`/`extract_item_sed`/`extract_item_awk`/`read_ini_file`/`write_ini_file`
- **parser.sh**: `parse_short_options`/`parse_long_options`/`main_planB`

### 项目任务
- **project.sh**: `PJ_1234`/`PJ_5678`/`PJ_20241128`/`PJ_set_new_fedora_workstation`/`test_batch`

### 2026-01-17 新增系统管理模块 (由AI拆分, 状态: 未测试)
- **nfs.sh**: NFS 共享管理
  - `empty_nfs_exports`/`nfs_share_usage`/`set_dir_2_nfs`/`remove_nfs_config`/`mount_nfs`/`mount_nfs_with_zenity`
- **vnc.sh**: X11VNC 远程桌面
  - `setup_x11vnc_server_usage`/`setup_x11vnc_server`/`setup_x11vnc_server_new`
- **httpd.sh**: Apache HTTP 服务
  - `start_my_httpd_usage`/`get_site_directories`/`start_my_httpd`/`stop_my_httpd_usage`/`stop_my_httpd`/`py_install`
- **security.sh**: 安全配置
  - `change_sshd_port`/`lock_user_randomly`/`unlock_user`/`project_set_user_never_expiration`/`project_set_record_his_with_datetime`/`add_ntp_server`
- **device.sh**: 设备挂载
  - `mount_new_device_usage`/`mount_new_device`/`wait_for_input_2_exit`

### 2026-01-17 新增V48遗留功能模块（由AI拆分，状态：未测试）
- **config_file_v48_legacy.sh**: 配置文件读写 (V48旧版实现)
  - `write_conf_file_old`/`get_item_from_conf`/`write_conf_file` (legacy版)
- **class_file_v48_legacy.sh**: 类文件写入（V48旧版实现）
  - `write_class_file_` (未优化版) / `write_class_file_Modifing` (改进中版) / `write_class_file_error` (失败版保留)
-- **media_tools_v48.sh**: 媒体与校验工具
  - `generate_verification_code` (验证码生成与校验)/`find_pic` (图片筛选与操作)
- **misc_legacy_v48.sh**: 杂项功能
  - `start_x_virtual_shell`（模拟交互shell）/`bash_description`（功能描述）/`process_file`（文件处理示例）
- **system_boot.sh**: 引导与虚拟化信息
  - `which_bootfirmware`（检测UEFI/BIOS）/`list_grub_entries`（列举GRUB条目）/`list_support_vmtech`（虚拟化技术支持）

### 其他现有模块
- **system.sh**: 系统信息/操作封装、`backup_and_log`备份功能
- **monitor.sh**: 系统资源监控
- **help.sh**: 使用说明与帮助信息

## 使用方法

### 在其他脚本中引用模块

```bash
#!/bin/bash

# 方式1：使用loader.sh加载所有模块
source "$(dirname "$0")/lib/loader.sh"

# 方式2：按需加载特定模块
source "$(dirname "$0")/lib/constants.sh"
source "$(dirname "$0")/lib/config.sh"
source "$(dirname "$0")/lib/logger.sh"
source "$(dirname "$0")/lib/sudo.sh"

# 使用模块功能
log_message "这是一条日志信息" "INFO"
sudo_execute "systemctl status firewalld"
```

> 注意: 回滚子系统的详细行为 (包括文件操作的校验策略、环境变量 `ROLLBACK_DIR_VERIFY_CHECKSUM` / `ROLLBACK_VERIFY_CHECKSUM`、以及单文件操作现在执行的 sha256+md5 双重校验) 详见 `ROLLBACK_README.md`。
 
## 回滚：使用示例与常用环境变量

下面给出一些常见的运行示例与可配置环境变量，方便在脚本或 CI 中集成回滚子系统。

- 常用环境变量说明：
  - `ROLLBACK_PREFIX`：回滚数据存放根目录（默认：项目下 `.rollback_data`，可覆盖）。
  - `ROLLBACK_VERIFY_CHECKSUM`：历史通用开关，控制目录校验的默认值（`true`/`false`，默认 `true`）。
  - `ROLLBACK_DIR_VERIFY_CHECKSUM`：目录递归校验开关（若未设置则继承 `ROLLBACK_VERIFY_CHECKSUM`）。
  - `ROLLBACK_LARGE_FILE_THRESHOLD_BYTES`：大文件阈值（默认 `52428800`，即 50MB），超过阈值目录校验会跳过 checksum 改用 size/mtime。
  - `ROLLBACK_ROLLBACK_CONFLICT_MODE`：冲突处理模式（`skip`|`overwrite`|`merge`，默认 `skip`）。
  - `ROLLBACK_AUTO_LOAD_TXID`：若在非交互脚本中需要自动加载某个事务，可设置该变量。

- 基本运行与演练：

```bash
# 演练模式（仅打印操作，不会对系统做变更）
export ROLLBACK_PREFIX="$PWD/.rollback_data"
./rollback_example_eg1.sh --yes --dryrun

# 真正执行（谨慎）：
./rollback_example_eg1.sh --yes

# 使用历史会话回滚（不需要 --yes）
./rollback_example_eg1.sh --restore tx_1610000000_abcd
```

- 在脚本中通过环境变量控制目录校验与阈值示例：

```bash
# 禁用目录递归的 checksum（但单文件双哈希仍强制启用）
export ROLLBACK_DIR_VERIFY_CHECKSUM=false

# 调整大文件阈值为 200MB
export ROLLBACK_LARGE_FILE_THRESHOLD_BYTES=$((200*1024*1024))

# 运行示例脚本
./rollback_example_eg1.sh --yes --dryrun
```

- 使用 `safe_cp` / `safe_mv` 示例（脚本内调用）：

```bash
source ./lib/loader.sh
init_rollback_system

# 复制单文件（内部会强制执行 sha256+md5 校验）
opid=$(safe_cp /tmp/new.jar /opt/app/new.jar)
if [[ -n "$opid" ]]; then
  # 主操作成功后提交回滚记录
  op_commit "$opid"
fi

# 递归目录复制（是否计算 checksum 取决于 ROLLBACK_DIR_VERIFY_CHECKSUM）
opid=$(safe_cp -r /tmp/configs /etc/myapp/configs)
case $? in
  0) op_commit "$opid" ;; 
  2) echo "存在冲突，查看 ${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/${opid}.merge" ;;
  *) echo "复制失败" ;;
esac
```

更多细节请参阅 `ROLLBACK_README.md`，该文件包含 manifest、合并模式与事务加载的完整说明。

### 回滚触发条件与注意事项（新增）

问题概述:
- 本脚本在主流程中启用了 `set -euo pipefail` 并通过 `trap 'on_error' ERR` 捕获错误；这意味着“任何命令返回非0 的退出码”会触发 `on_error`，进而执行 `rollback_all`。
- 因此某些系统命令（例如 `docker stop`/`docker start`/`docker restart`）在出现错误或超时等情形时返回非0，会被视作需要回滚的故障点；而仅有 stderr 输出但返回 0 的命令不会触发回滚。

触发回滚的具体条件:
- 脚本层面：任何未被显式捕获或屏蔽（例如 `|| true`）的命令返回非0，将触发 ERR trap，从而调用 `rollback_all`。
- 管道/子命令：启用了 `pipefail`，因此管道中任一环节返回非0 会导致整个管道返回非0 并触发回滚。
- 显式调用：代码中若直接调用 `rollback_all` / `rollback_operation` 也会触发回滚流程。

关于输出 vs 退出码:
- 只有非0 的退出码会触发自动回滚；单纯的 stderr 输出（但进程返回0）不会触发。

与 Docker 操作相关的风险:
- `docker restart` 可能在失败时返回非0 或输出额外的 stderr，从而误触发回滚。为降低误触发风险，建议：
  - 在停止操作前记录容器的运行状态（脚本当前已记录 `PREV_CONTAINER_RUNNING`），并在恢复/启动时只对此前处于运行状态的容器执行 `docker start`。这样可避免对本就未运行的容器重复 `restart` 产生的异常影响。

改进建议（已应用 / 建议尽快实施）:
1. 明确错误判定而非只依赖命令退出码：对关键命令使用显式返回码检查与日志记录，例如 `cmd; rc=$?; if (( rc != 0 )); then log_error ...; rollback_all; fi`。这样可在触发回滚前记录更多上下文并对特定返回码做白名单处理。
2. 将 `verify_service()` 改为更可靠的健康检查方式：优先使用 `docker inspect --format '{{.State.Health.Status}}'`（若容器配置了 healthcheck）、或使用 HTTP/端口探针，只有在健康检查通过后才 `op_commit`。
3. 对 `start/stop` 命令加入重试与超时策略，在确认多次失败后再触发回滚以减少偶发网络/超时引起的误判。
4. 引入 `safe_cmd()` 辅助函数：统一执行命令、捕获 stdout/stderr/rc，并基于可配置的白名单/黑名单规则决定是否触发回滚或仅记录警告。
5. 对回滚命令本身（`ROLLBACK_COMMANDS`）增加日志记录与返回值容错，以便 `rollback_all` 在部分回滚失败时仍能完成其余操作并保留失败记录供人工处理（脚本当前已记录 operations.log）。

后续行动建议:
- 优先在 `verify_service()` 中实现更可靠的健康检查并在通过后再 `op_commit`（可显著降低误触发率）。
- 若需要，我可以把上述 `safe_cmd()` 和更严格的 `verify_service()` 实现合并进 `rollback_example_eg1.sh` 并提交测试。请选择是否要我继续实现这些改进。

### 添加防火墙端口示例

```bash
#!/bin/bash
source "./lib/loader.sh"

# 设置要添加的端口
GLOBAL_PORT_LIST='"8080 8443 3306"'

# 添加TCP端口到public区域
add_firewall_ports "tcp" "public"
```

### 使用日志功能示例

```bash
#!/bin/bash
source "./lib/loader.sh"

# 记录不同级别的日志
log_message "普通信息" "INFO"
log_message "警告信息" "WARNING"
log_message "错误信息" "ERROR"
log_message "调试信息" "DEBUG"

# 仅写入日志文件
LOG_message "仅写入日志" "INFO"

# 仅输出到屏幕
log_MESSAGE "仅输出屏幕" "INFO"
```

## 开发指南

### 添加新模块

1. 在 `lib/` 目录下创建新的 `.sh` 文件
2. 在文件开头添加模块说明和依赖加载
3. 在 `loader.sh` 中添加模块加载语句
4. 更新本README文档

### 模块依赖规则

- 基础模块（constants.sh, config.sh）不应依赖其他模块
- 工具模块（utils.sh, logger.sh）可以依赖基础模块
- 功能模块（firewall.sh, sudo.sh）可以依赖工具模块和基础模块
- 避免循环依赖

### 变量命名规范

- 全局变量：使用 `this_` 前缀
- 局部变量：使用 `ltmp_` 前缀，并使用 `local` 声明
- 常量：使用 `readonly` 声明，全大写

### 函数命名规范

- 使用小写字母和下划线
- 函数名应清晰描述功能
- 私有函数可以使用 `_` 前缀

## 测试

每个模块都可以独立测试。建议为每个模块编写测试脚本。

## 兼容性

- 支持 Bash 4.0+
- 支持 Fedora/CentOS/RHEL
- 支持 firewalld 和 iptables

## 许可证

本项目遵循原脚本的许可证。

## 贡献

欢迎提交Issue和Pull Request来改进本项目。

## 联系方式

- Mail: 
- 作者: rim0s-team ( Deepseek, copilot, Cursor, rim0s )  


## Git 钩子（防止将配置文件误推送到 GitHub）

本项目提供可选的本地 Git 钩子，帮助在向 GitHub 推送时阻止包含敏感配置文件（如 `*.conf`、`*.ini` 或指定的 `etc/rollback_example.conf`）的提交。该钩子仅在本地启用（通过设置 `core.hooksPath` 指向仓库的 `.githooks` 目录），并不会自动在远端生效。

当前仓库包含：

- `.githooks/pre-push`：pre-push 钩子脚本。行为概要：
  - 当推送目标 remote URL 中包含 `github.com` 时启用检查（即仅在推送到 GitHub 时生效）。
  - 检查本次推送范围内的所有新增/修改文件名，如果匹配 `*.conf`、`*.ini`，或匹配钩子脚本中列出的具体路径（默认包含 `etc/rollback_example.conf`），则中止推送并打印错误说明。
  - 该检查针对提交中的文件名匹配，不会读取或泄露文件内容。

- `scripts/install-git-hooks.sh`：安装脚本。使用方法见下。
- `.githooks/README.md`：钩子使用说明与规则说明。

安装与使用（在每个需要启用该钩子的开发者本地执行一次）：

```bash
# 在仓库根目录执行一次：
bash scripts/install-git-hooks.sh
```

安装脚本会：
- 将 `git config core.hooksPath .githooks` 写入本地仓库配置，使 Git 使用该目录下的钩子脚本。
- 确保 `.githooks/pre-push` 为可执行状态。

行为与限制说明：

- 钩子为“本地执行机制”，因此仓库可以将 `.githooks` 目录加入版本控制，团队成员需在本地运行安装脚本以启用本地钩子。
- 钩子中止推送的判定基于远端 URL 包含 `github.com` 的简单匹配；如果你的 GitHub Enterprise 或自建服务使用不同域名，请修改 `.githooks/pre-push` 中的判断逻辑以匹配你的域名。
- 钩子当前通过文件名模式匹配阻止敏感配置被推送；如果你需要更严格的检查（例如拒绝包含特定关键字的文件内容），建议在 CI 中加入额外检查（例如 `grep` 或专门的扫描工具），注意避免在 CI 中泄露敏感内容。

如何放行某些文件或调整策略：

- 编辑 `.githooks/pre-push`，调整 `forbidden_patterns` 数组以添加/移除受限路径或模式。
- 若需要对 GitHub 推送进行例外（本地临时推送），可在推送前使用 `git push --no-verify` 绕过本地钩子（慎用）。

安全建议：

- 尽量不要在版本库中保留包含凭证或敏感路径的配置文件；把示例配置（如 `etc/rollback_example.conf`）保留为无敏感默认值的示例文件。
- 对于必须存在但敏感的配置，考虑在部署流程中通过私有配置管理（Vault、CI Secret、服务器端配置）注入。


##  History
- 2026-01-17        由 AI 完成剩余模块拆分（第二批）：
                  - 新增 V48 遗留功能模块5个：config_file_v48_legacy、class_file_v48_legacy、media_tools_v48、misc_legacy_v48、system_boot（状态：未测试）
                  - 更新 loader.sh 追加所有新模块加载，按时间和类型分组注释
                  - 更新 README 补充新增模块清单
- 2026-01-17        由 AI 拆分新增模块（第一批）：
                  - 核心模块7个：debug、network、package_advanced、path、config_file、parser、project
                  - 系统管理模块5个：nfs、vnc、httpd、security、device（状态：未测试）
                  - 同步更新 README，补充模块清单与函数说明
- 2025-11-09 15:30  由 Cursor 对 ProjectManage.sh 的第48版进行了模块化拆分。
                  暂未测试。
                  下一步先阅读和比对，确保逻辑完整无遗漏。
- 2026-02-01        若干安全和文档更新（作者: rim0s-team）：
                 - 新增本地 Git 钩子与安装脚本：`.githooks/pre-push` + `scripts/install-git-hooks.sh`，用于在推送到 GitHub 时阻止 `*.conf` / `*.ini` 或指定敏感配置文件（默认 `etc/rollback_example.conf`）被误推送（commit: bb07988）。
                 - 新增示例配置文件：`etc/rollback_example.conf`（带注释），示例用于 `rollback_example_eg1.sh` 的配置化部署（commit: bb07988）。
                 - 修复示例脚本 `rollback_example_eg1.sh` 的敏感信息暴露问题：移除脚本内硬编码的 `TARGET_DIR`/`JAR_NAME`/`CONTAINER_NAME`，强制从配置文件读取必要参数，若缺失则中止执行（commit: 13cbb05）。
                 - 改进容器控制与回滚语义：记录容器停止前运行状态，恢复时使用 `docker start`（仅对原先运行的容器）并将回滚注册命令改为启动而非 restart，减少因 restart 导致的误触发（commit: 648262d）。
                 - 在 `README.md` 中补充“回滚触发条件与注意事项”段，详细说明触发回滚的条件（exit code vs stdout、pipefail 行为、docker 操作风险）并列出后续改进建议（commit: 532a1d8）。
                 - 所有上述变更已本地提交，可根据项目策略决定是否 push 到远端 `develop`（部分提交已在远端，详见版本历史）。