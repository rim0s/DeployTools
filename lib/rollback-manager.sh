#!/bin/bash
# rollback-manager.sh (clean minimal implementation)

# 加载依赖
_rb_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_rb_dir}/logger.sh" 2>/dev/null || true
source "${_rb_dir}/utils.sh" 2>/dev/null || true

# 全局变量
declare -A ROLLBACK_COMMANDS
declare -a OPERATION_STACK
ROLLBACK_PREFIX="${ROLLBACK_PREFIX:-${_rb_dir}/../.rollback_data}"
TRANSACTION_ID=""

generate_op_id() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen
    elif [[ -r /proc/sys/kernel/random/uuid ]]; then
        cat /proc/sys/kernel/random/uuid
    else
        echo "$(hostname -s)-$$-$(date +%s%N)-$RANDOM"
    fi
}

_ensure_tx_dirs() {
    mkdir -p "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending"
    mkdir -p "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/committed"
}

init_rollback_system() {
    TRANSACTION_ID="tx_$(date +%s)_${RANDOM}"
    mkdir -p "${ROLLBACK_PREFIX}/${TRANSACTION_ID}" || return 1
    _ensure_tx_dirs
    echo "started=$(date '+%Y-%m-%d %H:%M:%S')" > "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/session.meta"
    echo "created_by=${0:-}" >> "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/session.meta"
    echo "$TRANSACTION_ID" > "${ROLLBACK_PREFIX}/last_session.txt" 2>/dev/null || true
    echo "$TRANSACTION_ID"
}

init_rollback_system_return(){
    init_rollback_system "$@" >/dev/null || return $?
    printf '%s' "${TRANSACTION_ID}"
}

op_prewrite() {
    local op_id="$1"; shift
    local rollback_cmd="$1"; shift
    local description="$*"
    _ensure_tx_dirs
    if [[ -z "$op_id" ]]; then
        op_id=$(generate_op_id)
    fi
    echo "${op_id}|${description}|${rollback_cmd}" > "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/${op_id}"
    ROLLBACK_COMMANDS["$op_id"]="$rollback_cmd"
    OPERATION_STACK+=("$op_id")
    echo "$op_id"
}

op_commit() {
    local op_id="$1"
    local pending_file="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/${op_id}"
    local committed_dir="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/committed"
    if [[ ! -f "$pending_file" ]]; then
        return 1
    fi
    mkdir -p "$committed_dir"
    cat "$pending_file" >> "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/operations.log"
    mv "$pending_file" "$committed_dir/" || return 1
    return 0
}

rollback_operation() {
    local op_code="$1"
    if [[ -z "$op_code" ]]; then
        log_error "rollback_operation: missing op_code"
        return 2
    fi
    local cmd="${ROLLBACK_COMMANDS[$op_code]:-}"
    if [[ -z "$cmd" ]]; then
        log_warn "未找到回滚命令，跳过: $op_code"
        return 0
    fi
    log_info "开始回滚: $op_code"
    if eval "$cmd"; then
        log_info "回滚成功: $op_code"
        unset 'ROLLBACK_COMMANDS[$op_code]'
        return 0
    else
        local rc=$?
        log_error "回滚失败: $op_code (rc=$rc)"
        return $rc
    fi
}

rollback_all() {
    log_info "开始回滚所有操作（逆序执行）..."
    local any_failed=0
    for ((i=${#OPERATION_STACK[@]}-1; i>=0; i--)); do
        local op_code="${OPERATION_STACK[$i]}"
        if [[ -z "${ROLLBACK_COMMANDS[$op_code]:-}" ]]; then
            log_debug "跳过已无命令的操作: $op_code"
            continue
        fi
        if ! rollback_operation "$op_code"; then
            any_failed=1
        fi
    done
    if [[ $any_failed -eq 1 ]]; then
        log_warn "回滚完成，部分操作失败（查看 ${ROLLBACK_PREFIX}/${TRANSACTION_ID}/operations.log 获取详情）"
        return 1
    fi
    log_info "所有操作已回滚"
    return 0
}

_load_transaction_into_memory() {
    local txid="$1"
    local txdir="${ROLLBACK_PREFIX}/${txid}"
    if [[ ! -d "$txdir" ]]; then
        log_error "transaction not found: $txid"
        return 1
    fi
    local pending_dir="$txdir/pending"
    if [[ ! -d "$pending_dir" ]]; then
        log_error "no pending dir for tx: $txid"
        return 1
    fi
    OPERATION_STACK=()
    for f in "$pending_dir"/*; do
        [[ -f "$f" ]] || continue
        opid=$(basename "$f")
        OPERATION_STACK+=("$opid")
        IFS='|' read -r fid fdesc fcmd < "$f" || true
        ROLLBACK_COMMANDS["$opid"]="$fcmd"
    done
    TRANSACTION_ID="$txid"
    log_info "Loaded pending transaction into memory: $txid (ops=${#OPERATION_STACK[@]})"
    return 0
}
