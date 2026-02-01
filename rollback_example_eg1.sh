#!/bin/bash
set -euo pipefail

# rollback_example_eg1.sh
# 安全替换jar的示例脚本（支持 --yes, --dryrun, --restore <session>）

_libdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
# 在 source 时避免污染位置参数
saved_args=("$@")
set --
source "${_libdir}/logger.sh" 2>/dev/null || true
source "${_libdir}/utils.sh" 2>/dev/null || true
source "${_libdir}/sudo.sh" 2>/dev/null || true
source "${_libdir}/rollback-manager.sh" 2>/dev/null || true
set -- "${saved_args[@]}"

TARGET_DIR="/home/yunxi/traffic"
JAR_NAME="${JAR_NAME:-traffic-2.1.1_42.jar}"
CONTAINER_NAME="${CONTAINER_NAME:-traffic}"
BACKUP_NAME="${BACKUP_NAME:-bak$(date +%Y%m%d%H%M%S)-${JAR_NAME}}"

validate_params() {
    local missing=()
    [[ -z "${JAR_NAME:-}" ]] && missing+=("JAR_NAME")
    [[ -z "${CONTAINER_NAME:-}" ]] && missing+=("CONTAINER_NAME")
    [[ -z "${TARGET_DIR:-}" ]] && missing+=("TARGET_DIR")
    if (( ${#missing[@]} > 0 )); then
        log_error "缺少必填变量: ${missing[*]}"
        log_error "请通过环境变量或修改脚本顶部来设置这些变量。示例： JAR_NAME=${JAR_NAME:-traffic-2.1.1_42.jar} CONTAINER_NAME=${CONTAINER_NAME:-traffic} TARGET_DIR=${TARGET_DIR} $0 --yes"
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

--yes           必须（防止误操作），允许执行替换流程。
--dryrun        演练（打印命令，不实际执行）。
--restore id    使用历史会话 id 执行回滚（不需要 --yes）。
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
        log_info "[DRYRUN] 会话回滚演练: 以下回滚命令将按逆序执行（仅演示，不执行）"
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
    # 兼容占位：实际在 backup_jar 成功后注册 restart（见 backup_jar 中会设置 MV_OPID）
    if [[ "$DRYRUN" -eq 1 ]]; then
        RESTART_OPID="dryrun-op-$(date +%s)"
    else
        RESTART_OPID=""
    fi
}

# 在 backup 成功后调用：将 restart 插入到 MV_OPID 之前，确保回滚逆序为 mv -> restart
register_restart_before_mv() {
    local mvop="$1"
    if [[ -z "$mvop" ]]; then
        log_warn "register_restart_before_mv: missing mv op id; skip"
        return 1
    fi
    if [[ "$DRYRUN" -eq 1 ]]; then
        log_info "[DRYRUN] would register restart before $mvop: docker restart ${CONTAINER_NAME}"
        RESTART_OPID="dryrun-op-$(date +%s)"
        return 0
    fi
    # 创建 restart 操作（作为普通 op），然后插入到 mvop 前
    local rid
    rid=$(register_operation "" "docker restart ${CONTAINER_NAME}" "restart ${CONTAINER_NAME} on restore") || {
        log_error "register_operation(restart) 失败"
        return 1
    }
    # 找到 mvop 索引并在其前面插入 restart
    register_operation_before "$mvop" "$rid" "docker restart ${CONTAINER_NAME}" "restart ${CONTAINER_NAME} on restore" >/dev/null 2>&1 || true
    RESTART_OPID="$rid"
    log_info "已插入 restart 回滚项 $RESTART_OPID 在 $mvop 之前"
}

stop_service() {
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
    log_info "重启容器: ${CONTAINER_NAME}"
    run_system_cmd "docker restart ${CONTAINER_NAME}"
}

verify_service() {
    log_info "验证进程: 检查是否存在 ${JAR_NAME}"
    if [[ "$DRYRUN" -eq 1 ]]; then
        echo "[DRYRUN] 演练模式跳过实际进程检查：将模拟查找 ${JAR_NAME} 的结果"
        return 0
    fi
    if ps -ef | grep java | grep -v grep | grep -q "${JAR_NAME}"; then
        log_info "验证通过：已找到进程包含 ${JAR_NAME}"
        return 0
    else
        log_error "验证失败：未在进程中找到 ${JAR_NAME}"
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

    register_rollback_op

    stop_service

    backup_jar || { false; }

    check_new_package || { false; }

    start_service

    verify_service || { false; }

    commit_ops

    _COMMITTED=1
    trap - ERR

    log_info "更新完成，备份保留为 ${TARGET_DIR}/${BACKUP_NAME}。"
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
