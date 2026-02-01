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

# 兼容层：历史代码可能调用 register_operation
# 保持向后兼容性：register_operation -> op_prewrite
register_operation() {
    op_prewrite "$@"
}

# Helper: find op index in OPERATION_STACK (echo index or return 1)
_find_op_index() {
    local target="$1"
    local i
    for i in "${!OPERATION_STACK[@]}"; do
        if [[ "${OPERATION_STACK[$i]}" == "$target" ]]; then
            printf '%s' "$i"
            return 0
        fi
    done
    return 1
}

# Persist current OPERATION_STACK into pending/.stack_order
_persist_stack_order() {
    local pending_dir="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending"
    mkdir -p "$pending_dir" || return 1
    local order_file="$pending_dir/.stack_order"
    : > "$order_file"
    local op
    for op in "${OPERATION_STACK[@]}"; do
        printf '%s\n' "$op" >> "$order_file"
    done
}

# register_operation_at <index|end> <op_id_or_empty> <rollback_cmd> [description]
# index can be a number (0-based) or the literal 'end'
register_operation_at() {
    local index_spec="$1"; shift
    local op_id="$1"; shift
    local rollback_cmd="$1"; shift
    local description="$*"
    _ensure_tx_dirs

    # create op if not provided; op_prewrite will append to stack, we'll reposition
    if [[ -z "$op_id" ]]; then
        op_id=$(op_prewrite "" "$rollback_cmd" "$description") || return 1
        # remove the last appended element (we will re-insert at desired index)
        local last_index=$(( ${#OPERATION_STACK[@]} - 1 ))
        unset 'OPERATION_STACK[$last_index]'
    else
        # write pending file for provided id
        echo "${op_id}|${description}|${rollback_cmd}" > "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/${op_id}" || return 1
    fi

    # determine numeric index
    local idx
    if [[ "$index_spec" == "end" ]]; then
        idx=${#OPERATION_STACK[@]}
    elif [[ "$index_spec" =~ ^[0-9]+$ ]]; then
        idx=$index_spec
        if (( idx < 0 )); then idx=0; fi
        if (( idx > ${#OPERATION_STACK[@]} )); then idx=${#OPERATION_STACK[@]}; fi
    else
        idx=${#OPERATION_STACK[@]}
    fi

    # insert op_id at idx
    local new_stack=()
    local i
    for ((i=0;i<idx;i++)); do
        new_stack+=("${OPERATION_STACK[$i]}")
    done
    new_stack+=("$op_id")
    for ((i=idx;i<${#OPERATION_STACK[@]};i++)); do
        new_stack+=("${OPERATION_STACK[$i]}")
    done
    OPERATION_STACK=("${new_stack[@]}")

    # persist order and command mapping
    ROLLBACK_COMMANDS["$op_id"]="$rollback_cmd"
    _persist_stack_order || true
    printf '%s' "$op_id"
}

# register_operation_before <existing_opid> <op_id_or_empty> <rollback_cmd> [description]
register_operation_before() {
    local existing_op="$1"; shift
    local op_id="$1"; shift
    local rollback_cmd="$1"; shift
    local description="$*"
    local idx
    if idx=$(_find_op_index "$existing_op") 2>/dev/null; then
        register_operation_at "$idx" "$op_id" "$rollback_cmd" "$description"
    else
        register_operation_at end "$op_id" "$rollback_cmd" "$description"
    fi
}

# register_operation_after <existing_opid> <op_id_or_empty> <rollback_cmd> [description]
register_operation_after() {
    local existing_op="$1"; shift
    local op_id="$1"; shift
    local rollback_cmd="$1"; shift
    local description="$*"
    local idx
    if idx=$(_find_op_index "$existing_op") 2>/dev/null; then
        idx=$((idx + 1))
        register_operation_at "$idx" "$op_id" "$rollback_cmd" "$description"
    else
        register_operation_at end "$op_id" "$rollback_cmd" "$description"
    fi
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
