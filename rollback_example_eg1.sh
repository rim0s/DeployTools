#!/bin/bash
set -euo pipefail

# rollback_example_eg1.sh
# 安全替换jar的示例脚本 (支持 --yes, --dryrun, --restore <session>)

_libdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
# 在 source 时避免污染位置参数
saved_args=("$@")
set --
source "${_libdir}/logger.sh" 2>/dev/null || true
source "${_libdir}/utils.sh" 2>/dev/null || true
source "${_libdir}/sudo.sh" 2>/dev/null || true
source "${_libdir}/rollback-manager.sh" 2>/dev/null || true
# 配置读取 helpers
source "${_libdir}/config_file.sh" 2>/dev/null || true
set -- "${saved_args[@]}"

# 不在脚本中硬编码敏感内容：敏感变量必须由配置文件提供。
# 脚本在未从配置文件读取到必需项时会中止执行以避免泄露信息。
TARGET_DIR=""
JAR_NAME=""
CONTAINER_NAME=""
BACKUP_NAME=""

# 配置文件位置（可由环境变量 CONFIG_FILE 覆盖）
CONFIG_FILE="${CONFIG_FILE:-$(dirname "${_libdir}")/etc/rollback_example.conf}"
if [[ -f "${CONFIG_FILE}" ]]; then
    # 使用项目已有的 read_ini_file 函数读取 INI 格式配置（强制要求配置文件提供敏感项）
    cfg_val=$(read_ini_file "${CONFIG_FILE}" "example" "TARGET_DIR" 2>/dev/null || echo "")
    [[ -n "$cfg_val" ]] && TARGET_DIR="$cfg_val"
    cfg_val=$(read_ini_file "${CONFIG_FILE}" "example" "JAR_NAME" 2>/dev/null || echo "")
    [[ -n "$cfg_val" ]] && JAR_NAME="$cfg_val"
    cfg_val=$(read_ini_file "${CONFIG_FILE}" "example" "CONTAINER_NAME" 2>/dev/null || echo "")
    [[ -n "$cfg_val" ]] && CONTAINER_NAME="$cfg_val"
    cfg_val=$(read_ini_file "${CONFIG_FILE}" "example" "BACKUP_NAME" 2>/dev/null || echo "")
    [[ -n "$cfg_val" ]] && BACKUP_NAME="$cfg_val"
else
    log_error "配置文件未找到: ${CONFIG_FILE}" || true
    echo "为避免在脚本中暴露敏感信息，脚本仅支持通过配置文件提供 TARGET_DIR, JAR_NAME, CONTAINER_NAME。请创建配置文件或通过设置 CONFIG_FILE 指向有效文件。" >&2
    exit 2
fi

# 配置文件已读取完毕，校验必填项（缺少则中止执行）
if [[ -z "${TARGET_DIR:-}" || -z "${JAR_NAME:-}" || -z "${CONTAINER_NAME:-}" ]]; then
    log_error "配置文件 ${CONFIG_FILE} 缺少必填项：TARGET_DIR/JAR_NAME/CONTAINER_NAME（至少一项为空）" || true
    echo "请在 ${CONFIG_FILE} 的 [example] 段中填写 TARGET_DIR、JAR_NAME、CONTAINER_NAME 后重试。" >&2
    exit 2
fi

# 若未提供 BACKUP_NAME，则在已知 JAR_NAME 的情况下生成一个备份名
if [[ -z "${BACKUP_NAME:-}" ]]; then
    BACKUP_NAME="bak$(date +%Y%m%d%H%M%S)-${JAR_NAME}"
fi

validate_params() {
    local missing=()
    [[ -z "${JAR_NAME:-}" ]] && missing+=("JAR_NAME")
    [[ -z "${CONTAINER_NAME:-}" ]] && missing+=("CONTAINER_NAME")
    [[ -z "${TARGET_DIR:-}" ]] && missing+=("TARGET_DIR")
    if (( ${#missing[@]} > 0 )); then
        log_error "缺少必填变量: ${missing[*]}"
        log_error "请通过环境变量或修改脚本顶部来设置这些变量。示例: JAR_NAME=${JAR_NAME:-traffic-2.1.1_42.jar} CONTAINER_NAME=${CONTAINER_NAME:-traffic} TARGET_DIR=${TARGET_DIR} $0 --yes"
        exit 2
    fi
    log_info "使用参数: TARGET_DIR=${TARGET_DIR}, JAR_NAME=${JAR_NAME}, CONTAINER_NAME=${CONTAINER_NAME}, BACKUP_NAME=${BACKUP_NAME}"
}

MODE="update"
RESTORE_SESSION=""
ENFORCE_YES=0
DRYRUN=0

run_system_cmd() {
    local cmd="$1"
    if [[ "$DRYRUN" -eq 1 ]]; then
        echo "[DRYRUN] $cmd"
        return 0
    fi
    sudo_execute "$cmd"
}

print_help() {
    cat <<EOF
Usage: $0 --yes [--dryrun]
       $0 --restore <sessionNO> [--dryrun]

--yes           必须 (防止误操作)，允许执行替换流程。
--dryrun        演练 (打印命令, 不实际执行).
--restore id    使用历史会话 id 执行回滚 (不需要 --yes).
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes)
                ENFORCE_YES=1; shift ;;
            --dryrun)
                DRYRUN=1; shift ;;
            --restore)
                MODE="restore"; RESTORE_SESSION="$2"; shift 2 ;;
            -h|--help)
                print_help; exit 0 ;;
            *)
                echo "未知参数: $1" >&2; print_help; exit 2 ;;
        esac
    done

    if [[ "$MODE" != "restore" && $ENFORCE_YES -ne 1 ]]; then
        log_error "为防止误操作，必须加 --yes 才会执行更新。若要恢复历史会话，使用 --restore <sessionNO>。"
        exit 2
    fi
}

_do_restore() {
    local RESTORE_SESSION_LOCAL="$1"
    if ! _load_transaction_into_memory "$RESTORE_SESSION_LOCAL"; then
        log_error "加载会话失败: $RESTORE_SESSION_LOCAL"
        return 1
    fi
    log_info "开始回滚会话: $RESTORE_SESSION_LOCAL"
    if [[ "$DRYRUN" -eq 1 ]]; then
        log_info "[DRYRUN] 会话回滚演练: 以下回滚命令将按逆序执行 (仅演示, 不执行)"
        for ((i=${#OPERATION_STACK[@]}-1; i>=0; i--)); do
            opid=${OPERATION_STACK[$i]}
            log_info "  op=$opid -> ${ROLLBACK_COMMANDS[$opid]}"
        done
        return 0
    fi
    return $(rollback_all)
}

init_session() {
    sid=$(init_rollback_system_return) || {
        echo "无法初始化回滚系统" >&2
        exit 1
    }
    log_info "初始化事务，SESSION_ID=${sid}"
    echo "SESSION_ID=${sid}"
    validate_params
}

# ensure logger dir exists (use logger module helpers)
this_LOG_FILE="${this_LOG_FILE:-/tmp/rollback_example.log}"
this_LOG_DIR="${this_LOG_DIR:-$(dirname "$this_LOG_FILE") }"
if ! init_log >/dev/null 2>&1; then
    echo "无法创建或初始化日志目录: ${this_LOG_DIR:-}" >&2
    exit 1
fi

_COMMITTED=0

on_error() {
    local rc=$?
    trap - ERR
    if [[ "$_COMMITTED" -ne 1 ]]; then
        log_error "发生错误 (rc=$rc)，触发回滚..."
        rollback_all || log_warn "回滚过程返回非0"
    fi
    exit $rc
}

finish() {
    if [[ "$MODE" == "restore" ]]; then
        return 0
    fi
    local sid_to_show="${sid:-${TRANSACTION_ID:-}}"
    if [[ -n "$sid_to_show" ]]; then
        if [[ "$DRYRUN" -eq 1 ]]; then
            echo "DRYRUN: SESSION_ID=$sid_to_show (演练用)。要恢复: $0 --restore $sid_to_show" >&2
        else
            echo "SESSION_ID=$sid_to_show" >&2
            echo "若需恢复此次操作，可执行: $0 --restore $sid_to_show" >&2
        fi
    fi
}

register_rollback_op() {
    # 兼容占位: 实际在 backup_jar 成功后注册 restart (见 backup_jar 中会设置 MV_OPID)
    if [[ "$DRYRUN" -eq 1 ]]; then
        RESTART_OPID="dryrun-op-$(date +%s)"
    else
        RESTART_OPID=""
    fi
}

# 在 backup 成功后调用: 将 restart 插入到 MV_OPID 之前, 确保回滚逆序为 mv -> restart
register_restart_before_mv() {
    local mvop="$1"
    if [[ -z "$mvop" ]]; then
        log_warn "register_restart_before_mv: missing mv op id; skip"
        return 1
    fi
    if [[ "$DRYRUN" -eq 1 ]]; then
        log_info "[DRYRUN] would register restart before $mvop: docker start ${CONTAINER_NAME}"
        RESTART_OPID="dryrun-op-$(date +%s)"
        return 0
    fi
    # 创建 restart 操作 (作为普通 op)，然后插入到 mvop 前
    local rid
    rid=$(register_operation "" "docker start ${CONTAINER_NAME}" "start ${CONTAINER_NAME} on restore") || {
        log_error "register_operation(start) 失败"
        return 1
    }
    # 找到 mvop 索引并在其前面插入 restart
    register_operation_before "$mvop" "$rid" "docker start ${CONTAINER_NAME}" "start ${CONTAINER_NAME} on restore" >/dev/null 2>&1 || true
    RESTART_OPID="$rid"
    log_info "已插入 restart 回滚项 $RESTART_OPID 在 $mvop 之前"
}

stop_service() {
    # 记录容器在停止前是否处于运行状态，恢复时仅针对之前运行的容器启动
    PREV_CONTAINER_RUNNING=$(docker inspect -f '{{.State.Running}}' "${CONTAINER_NAME}" 2>/dev/null || echo "false")
    if [[ "$PREV_CONTAINER_RUNNING" != "true" ]]; then
        log_info "容器 ${CONTAINER_NAME} 在停止前未运行 (状态=${PREV_CONTAINER_RUNNING})，跳过停止操作"
        return 0
    fi
    log_info "停止容器: ${CONTAINER_NAME}"
    run_system_cmd "docker stop ${CONTAINER_NAME}"
}

backup_jar() {
    local src="${TARGET_DIR}/${JAR_NAME}"
    local dst="${TARGET_DIR}/${BACKUP_NAME}"
    if [[ ! -f "$src" ]]; then
        if [[ "$DRYRUN" -eq 1 ]]; then
            echo "[DRYRUN] 原始 jar 不存在，演练模式下将模拟备份: $src -> $dst"
            return 0
        fi
        log_error "未找到原始 jar: $src"
        return 1
    fi
    log_info "备份原始 jar -> $dst"
    # 使用 safe_mv 来完成带回滚的移动操作
    if [[ "$DRYRUN" -eq 1 ]]; then
        echo "[DRYRUN] safe_mv '$src' '$dst'"
        return 0
    fi
    # safe_mv 会在成功时 op_commit 并返回 opid
    local mv_opid
    mv_opid=$(safe_mv "$src" "$dst") || {
        log_error "safe_mv 失败: $src -> $dst"
        return 1
    }
    log_info "safe_mv 已生成回滚项 opid=$mv_opid"
    return 0
}

check_new_package() {
    if [[ ! -f "${TARGET_DIR}/${JAR_NAME}" ]]; then
        if [[ "$DRYRUN" -eq 1 ]]; then
            echo "[DRYRUN] 新包 ${TARGET_DIR}/${JAR_NAME} 未找到，演练模式下将继续展示后续动作"
            return 0
        fi
        log_error "新包 ${TARGET_DIR}/${JAR_NAME} 未找到，取消更新并回滚"
        return 1
    fi
    return 0
}

start_service() {
    # 仅在容器原先处于运行状态时启动，以避免不必要的启动/错误
    if [[ "${PREV_CONTAINER_RUNNING:-false}" != "true" ]]; then
        log_info "容器 ${CONTAINER_NAME} 在变更前并未运行，跳过启动"
        return 0
    fi
    log_info "启动容器: ${CONTAINER_NAME} (使用 docker start)"
    run_system_cmd "docker start ${CONTAINER_NAME}"
}

verify_service() {
    log_info "验证进程: 检查是否存在 ${JAR_NAME}"
    if [[ "$DRYRUN" -eq 1 ]]; then
        echo "[DRYRUN] 演练模式跳过实际进程检查: 将模拟查找 ${JAR_NAME} 的结果"
        return 0
    fi
    if ps -ef | grep java | grep -v grep | grep -q "${JAR_NAME}"; then
        log_info "验证通过: 已找到进程包含 ${JAR_NAME}"
        return 0
    else
        log_error "验证失败: 未在进程中找到 ${JAR_NAME}"
        return 1
    fi
}

commit_ops() {
    if [[ "$DRYRUN" -eq 1 ]]; then
        echo "[DRYRUN] would op_commit ${RESTART_OPID:-}" 
        return 0
    fi
    if [[ -n "${RESTART_OPID:-}" ]]; then
        op_commit "$RESTART_OPID" || log_warn "op_commit 失败: $RESTART_OPID"
    fi
}

main() {
    trap 'on_error' ERR
    trap finish EXIT

    log_info "开始更新 ${TARGET_DIR}/${JAR_NAME} (container=${CONTAINER_NAME})"

    # ---- 示例/框架 说明注释（便于阅读） ----
    # 以下函数说明：
    # - `register_rollback_op`: 本示例内的辅助函数，用于准备/记录将要注册的 restart 回滚项（示例逻辑）。
    # - `stop_service` / `start_service` / `verify_service`: 本示例脚本实现的业务逻辑函数（演示如何在变更流程中停止/启动/验证服务）。
    # - `backup_jar` / `check_new_package`: 本示例实现的文件操作与校验流程；其中内部使用框架提供的 `safe_mv` / `safe_cp` 来执行带回滚的文件操作。
    # - `commit_ops`: 本示例的封装，调用框架的 `op_commit` 提交回滚条目。
    # - 框架提供的核心函数（位于 `lib/rollback-*.sh`）包括：`init_rollback_system`、`op_prewrite`、`op_commit`、`rollback_operation`、`rollback_all`、`register_operation`、`register_operation_before` 等。
    # 请区分：框架函数在 `lib/` 中实现；示例脚本只演示如何调用这些接口并处理业务流程。

    # 注册占位回滚项（示例）
    register_rollback_op

    # 停止服务（示例实现，真实项目请根据服务管理替换实现）
    stop_service

    # 备份并移动旧 JAR（示例实现，内部使用框架的 safe_mv 进行带回滚的移动）
    backup_jar || { false; }

    # 检查新包是否存在（示例实现）
    check_new_package || { false; }

    # 启动/重启服务（示例实现）
    start_service

    # 验证服务是否按预期运行（示例实现）
    verify_service || { false; }

    # 提交本次操作对应的回滚条目（示例：会调用框架的 op_commit）
    commit_ops

    # 标记已提交，避免 on_error 中触发回滚
    _COMMITTED=1
    trap - ERR

    log_info "更新完成，备份保留为 ${TARGET_DIR}/${BACKUP_NAME}."
    return 0
}

### 执行主函数
parse_args "$@"
if [[ "$MODE" == "restore" ]]; then
    if [[ -z "$RESTORE_SESSION" ]]; then
        echo "--restore 需要一个 session id" >&2
        exit 2
    fi
    _do_restore "$RESTORE_SESSION" || exit $?
else
    init_session
    main
fi

exit 0
