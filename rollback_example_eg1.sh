#!/bin/bash
set -euo pipefail

# 例子：替换 /home/yunxi/traffic 下的 jar 并保证可回滚
# 步骤（按要求）：
# 1. 停服务: docker stop traffic
# 2. 备份: mv traffic-2.1.1_42.jar bak20260129traffic-2.1.1_42.jar
#    新包 traffic-2.1.1_42.jar 需要已上传到同目录
# 3. 启动: docker restart traffic
# 4. 验证: ps -ef | grep java 中存在 traffic-2.1.1_42.jar

# 加载项目公共库（依赖 logger, rollback 框架, sudo wrapper）
_libdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
# 为避免被 source 的脚本（如 rollback-recover.sh）将主脚本的命令行参数误当作它们自己的参数，
# 在 source 时临时清空位置参数，然后恢复。
saved_args=("$@")
set --
source "${_libdir}/logger.sh" 2>/dev/null || true
source "${_libdir}/utils.sh" 2>/dev/null || true
source "${_libdir}/sudo.sh" 2>/dev/null || true
source "${_libdir}/rollback-manager.sh" 2>/dev/null || true
set -- "${saved_args[@]}"

TARGET_DIR="/home/yunxi/traffic"
JAR_NAME="traffic-2.1.1_42.jar"
BACKUP_NAME="bak20260129${JAR_NAME}"
CONTAINER_NAME="traffic"

# 参数解析
MODE="update"    # update 或 restore
RESTORE_SESSION=""
ENFORCE_YES=0
DRYRUN=0

run_system_cmd() {
    local cmd="$1"
    if [[ "$DRYRUN" -eq 1 ]]; then
        echo "[DRYRUN] $cmd"
        return 0
    fi
    # 使用项目 sudo 封装执行（记录日志）
    sudo_execute "$cmd"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --yes)
            ENFORCE_YES=1
            shift
            ;;
        --dryrun)
            DRYRUN=1
            shift
            ;;
        --restore)
            MODE="restore"
            RESTORE_SESSION="$2"
            shift 2
            ;;
        -h|--help)
            cat <<EOF
Usage: $0 --yes
       $0 --restore <sessionNO>

--yes           必须（防误操作），允许执行替换流程。
--restore id    使用历史会话 id 执行回滚（不需要 --yes）。
EOF
            exit 0
            ;;
        *)
            echo "未知参数: $1" >&2
            exit 2
            ;;
    esac
done

# 参数校验：如果不是 restore，则必须传 --yes
if [[ "$MODE" != "restore" && $ENFORCE_YES -ne 1 ]]; then
    echo "为防止误操作，必须加 --yes 才会执行更新。若要恢复历史会话，使用 --restore <sessionNO>。" >&2
    exit 2
fi

if [[ "$MODE" == "restore" ]]; then
    # 直接恢复历史会话：不需要创建新的会话，直接加载并回滚
    if [[ -z "$RESTORE_SESSION" ]]; then
        echo "--restore 需要一个 session id" >&2
        exit 2
    fi
    # 加载 rollback 框架（确保函数存在）已在文件顶部 source
    if ! _load_transaction_into_memory "$RESTORE_SESSION"; then
        log_error "加载会话失败: $RESTORE_SESSION"
        exit 1
    fi
    log_info "开始回滚会话: $RESTORE_SESSION"
    if [[ "$DRYRUN" -eq 1 ]]; then
        echo "[DRYRUN] 会话回滚演练: 以下回滚命令将按逆序执行（仅演示，不执行）"
        for ((i=${#OPERATION_STACK[@]}-1; i>=0; i--)); do
            opid=${OPERATION_STACK[$i]}
            echo "  op=$opid -> ${ROLLBACK_COMMANDS[$opid]}"
        done
        exit 0
    fi
    if rollback_all; then
        log_info "回滚会话 $RESTORE_SESSION 完成"
        exit 0
    else
        log_error "回滚会话 $RESTORE_SESSION 部分失败"
        exit 2
    fi
else
    # 初始化事务并以可编程方式获取 session id
    sid=""
    sid=$(init_rollback_system_return) || {
        echo "无法初始化回滚系统" >&2
        exit 1
    }
    log_info "初始化事务，SESSION_ID=${sid}"
    # 也把 session id 写到 stdout 便于调用者捕获
    echo "SESSION_ID=${sid}"
fi
        # 确保日志目录存在（logger 依赖此路径）
        _logdir_parent="$(dirname "${this_LOG_FILE:-/tmp/rollback_example.log}")"
        if [[ -e "$_logdir_parent" ]]; then
            if [[ ! -d "$_logdir_parent" ]]; then
                echo "日志路径冲突：$_logdir_parent 已存在且不是目录" >&2
                exit 1
            fi
        else
            mkdir -p "$_logdir_parent" || {
                echo "无法创建日志目录: $_logdir_parent" >&2
                exit 1
            }
        fi

# 全局标志：是否已提交（成功完成后设为1，防止 trap 回滚）
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

trap 'on_error' ERR

# 退出时提示 session id 可用于恢复
finish() {
    # 当处于 restore 模式时不重复提示
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
trap finish EXIT

log_info "开始更新 ${TARGET_DIR}/${JAR_NAME} (container=${CONTAINER_NAME})"

# 预写回滚命令：把备份还原回原文件并重启容器
ROLLBACK_CMD="mv '${TARGET_DIR}/${BACKUP_NAME}' '${TARGET_DIR}/${JAR_NAME}' && docker restart ${CONTAINER_NAME}"
# 使用 register_operation（prewrite），调用者在成功后调用 op_commit
if [[ "$DRYRUN" -eq 1 ]]; then
    echo "[DRYRUN] will register rollback: $ROLLBACK_CMD"
    opid="dryrun-op-$(date +%s)"
else
    opid=$(register_operation "" "$ROLLBACK_CMD" "restore original jar and restart ${CONTAINER_NAME}") || {
        log_error "register_operation 失败"
        exit 1
    }
    log_info "已预写回滚操作 opid=$opid"
fi

# 1) 停服务
log_info "停止容器: ${CONTAINER_NAME}"
run_system_cmd "docker stop ${CONTAINER_NAME}"

# 2) 备份当前 jar
if [[ ! -f "${TARGET_DIR}/${JAR_NAME}" ]]; then
    log_error "未找到原始 jar: ${TARGET_DIR}/${JAR_NAME}"
    exit 1
fi

log_info "备份原始 jar -> ${BACKUP_NAME}"
run_system_cmd "mv '${TARGET_DIR}/${JAR_NAME}' '${TARGET_DIR}/${BACKUP_NAME}'"

# 检查新包是否已上传（期望新包占位为同名 ${JAR_NAME}）
if [[ ! -f "${TARGET_DIR}/${JAR_NAME}" ]]; then
    log_error "新包 ${TARGET_DIR}/${JAR_NAME} 未找到，取消更新并回滚"
    # 触发错误以调用 trap -> rollback
    false
fi

# 3) 启动
log_info "重启容器: ${CONTAINER_NAME}"
run_system_cmd "docker restart ${CONTAINER_NAME}"

# 4) 验证进程中包含目标 jar 名称
log_info "验证进程: 检查是否存在 ${JAR_NAME}"
if ps -ef | grep java | grep -v grep | grep -q "${JAR_NAME}"; then
    log_info "验证通过：已找到进程包含 ${JAR_NAME}"
else
    log_error "验证失败：未在进程中找到 ${JAR_NAME}"
    # 触发错误 -> on_error -> rollback
    false
fi

# 一切成功：将先前的预写 pending 提交为已完成
if [[ "$DRYRUN" -eq 0 ]]; then
    op_commit "$opid" || {
        log_warn "op_commit 失败: $opid (但更新已完成)"
    }
else
    echo "[DRYRUN] would op_commit $opid"
fi

_COMMITTED=1
trap - ERR

log_info "更新完成，备份保留为 ${TARGET_DIR}/${BACKUP_NAME}。"
exit 0
