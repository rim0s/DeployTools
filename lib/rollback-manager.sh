#!/bin/bash
# rollback-manager.sh

# 加载依赖
_rb_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_rb_dir}/logger.sh" 2>/dev/null || true
source "${_rb_dir}/utils.sh" 2>/dev/null || true

# 全局变量
declare -A ROLLBACK_COMMANDS    # 操作码 -> 回滚命令
declare -a OPERATION_STACK      # 操作码栈（按执行顺序）
# 支持外部覆盖 ROLLBACK_PREFIX，否则默认使用项目目录下的 .rollback_data（避免无权限写入 /var）
ROLLBACK_PREFIX="${ROLLBACK_PREFIX:-${_rb_dir}/../.rollback_data}"
TRANSACTION_ID=""               # 当前事务ID

# 初始化回滚系统
init_rollback_system() {
    # 支持参数： init_rollback_system [rollback_prefix] [--auto-load <txid>]
    local auto_load_txid=""
    local prefix_arg=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --auto-load)
                shift
                auto_load_txid="$1"
                shift
                ;;
            *)
                if [[ -z "$prefix_arg" ]]; then
                    prefix_arg="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -n "$prefix_arg" ]]; then
        ROLLBACK_PREFIX="$prefix_arg"
    fi

    TRANSACTION_ID="tx_$(date +%s)_${RANDOM}"
    mkdir -p "${ROLLBACK_PREFIX}/${TRANSACTION_ID}" || return 1
    mkdir -p "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending" || return 1
    mkdir -p "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/committed" || return 1

    # 初始化操作序号
    OPERATION_SEQ=0

    # 创建操作日志（结构化行形式 JSON-like，便于后续解析）
    echo "# Transaction: $TRANSACTION_ID" > "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/operations.log"
    echo "# Started: $(date)" >> "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/operations.log"

    # 写 session 元信息并向用户打印可用于恢复的 session id
    printf '%s\n' "started=$(date --rfc-3339=seconds 2>/dev/null || date '+%Y-%m-%d %H:%M:%S')" > "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/session.meta"
    printf 'created_by=%s\n' "${0:-}" >> "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/session.meta"
    # 便于快速查找，记录 last_session（标准位置）
    echo "$TRANSACTION_ID" > "${ROLLBACK_PREFIX}/last_session.txt" 2>/dev/null || true

    # 优先从环境或参数决定自动加载
    if [[ -n "${auto_load_txid:-}" ]]; then
        _load_transaction_into_memory "$auto_load_txid"
        return $?
    fi
    if [[ -n "${ROLLBACK_AUTO_LOAD_TXID:-}" ]]; then
        _load_transaction_into_memory "$ROLLBACK_AUTO_LOAD_TXID"
        return $?
    fi

    # 如果没有 auto-load 指定，则询问用户是否加载已有 pending 事务
    _offer_restore_existing_pending
}

# 列出所有含 pending 条目的事务ID（不包括当前 TRANSACTION_ID）
_list_pending_transactions() {
    local dir
    for dir in "${ROLLBACK_PREFIX}"/*/pending; do
        [[ -d "$dir" ]] || continue
        # 是否有实际 pending 文件（不包含 .stack_order）
        if find "$dir" -maxdepth 1 -type f ! -name '.stack_order' | read -r; then
            basename "$(dirname "$dir")"
        fi
    done
}

# 从指定事务加载 .stack_order 与 pending 文件至内存
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

    # 清理当前内存映射
    OPERATION_STACK=()
    for k in "${!ROLLBACK_COMMANDS[@]}"; do
        unset ROLLBACK_COMMANDS["$k"]
    done

    # 优先使用 .stack_order
    local order_file="$pending_dir/.stack_order"
    if [[ -f "$order_file" ]]; then
        while IFS= read -r lid; do
            [[ -z "$lid" ]] && continue
            OPERATION_STACK+=("$lid")
        done < "$order_file"
    else
        # 按文件名顺序加载
        while IFS= read -r f; do
            opid=$(basename "$f")
            OPERATION_STACK+=("$opid")
        done < <(find "$pending_dir" -maxdepth 1 -type f -print | sort)
    fi

    # 读取每个 pending 文件以恢复回滚命令
    for opid in "${OPERATION_STACK[@]}"; do
        local pf="$pending_dir/$opid"
        if [[ -f "$pf" ]]; then
            # file format: opid|description|rollback_cmd
            IFS='|' read -r fid fdesc fcmd < <(cat "$pf") || true
            ROLLBACK_COMMANDS["$opid"]="$fcmd"
        else
            log_warn "pending file missing for opid: $opid"
        fi
    done

    TRANSACTION_ID="$txid"
    log_info "Loaded pending transaction into memory: $txid (ops=${#OPERATION_STACK[@]})"
    return 0
}

# 提示用户是否加载已有的 pending 事务
_offer_restore_existing_pending() {
    # 搜索其它 tx 目录
    local txs=()
    local tx
    for tx in "${ROLLBACK_PREFIX}"/*; do
        [[ -d "$tx" ]] || continue
        local txid; txid=$(basename "$tx")
        # skip current
        [[ "$txid" == "$TRANSACTION_ID" ]] && continue
        if find "$tx/pending" -maxdepth 1 -type f ! -name '.stack_order' | read -r; then
            txs+=("$txid")
        fi
    done
    if [[ ${#txs[@]} -eq 0 ]]; then
        return 0
    fi

    echo "Detected pending transactions:" >&2
    local i=0
    for txid in "${txs[@]}"; do
        echo "  [$i] $txid" >&2
        i=$((i+1))
    done
    echo -n "Load one of these pending transactions into current session? (y/N) " >&2
    read -r ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        echo -n "Select index (number): " >&2
        read -r sel
        if ! [[ "$sel" =~ ^[0-9]+$ ]] || (( sel < 0 || sel >= ${#txs[@]} )); then
            echo "Invalid selection" >&2
            return 1
        fi
        local chosen=${txs[$sel]}
        _load_transaction_into_memory "$chosen"
    fi
}

# 注册一个操作及其回滚命令（统一接口）
# register_operation <op_id> <rollback_cmd> [description]
generate_op_id() {
    local id
    if command -v uuidgen >/dev/null 2>&1; then
        id=$(uuidgen)
    elif [[ -r /proc/sys/kernel/random/uuid ]]; then
        id=$(cat /proc/sys/kernel/random/uuid)
    else
        id="$(hostname -s)-$$-$(date +%s%N)-$RANDOM"
    fi
    printf '%s' "$id"
}

_ensure_tx_dirs() {
    mkdir -p "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending"
    mkdir -p "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/committed"
}

# op_prewrite <op_id> <rollback_cmd> <description>
op_prewrite() {
    local op_id="$1"; shift
    local rollback_cmd="$1"; shift
    local description="$*"
    _ensure_tx_dirs
    if [[ -z "$op_id" ]]; then
        op_id=$(generate_op_id)
    fi
    local tmp
    tmp=$(mktemp "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/.op.XXXXXX") || return 1
    printf '%s|%s|%s\n' "$op_id" "$description" "$rollback_cmd" > "$tmp"
    mv "$tmp" "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/${op_id}" || return 1
    sync || true
    echo "$op_id"
}

# op_commit <op_id>
op_commit() {
    local op_id="$1"
    local pending_file="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/${op_id}"
    local committed_dir="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/committed"
    if [[ ! -f "$pending_file" ]]; then
        return 1
    fi
    mkdir -p "$committed_dir"
    while IFS= read -r line; do
        printf '%s\n' "$line" >> "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/operations.log"
    done < "$pending_file"
    mv "$pending_file" "$committed_dir/" || return 1
    return 0
}

register_operation(){
    local provided_id="$1"
    local rollback_cmd="$2"
    local description="${3:-$2}"

    if [[ -z "$provided_id" ]]; then
        provided_id=$(generate_op_id)
    fi
    local op_id="$provided_id"

    # 内存映射（便于运行时直接访问）
    ROLLBACK_COMMANDS["$op_id"]="$rollback_cmd"
    OPERATION_STACK+=("$op_id")

    # 只 prewrite（写入 pending），不自动 commit；由调用者在主操作成功后调用 op_commit
    op_prewrite "$op_id" "$rollback_cmd" "$description" || return 1

    echo "$op_id"
}

# register_operation_at <index> <op_id_or_empty> <rollback_cmd> [description]
# 在 OPERATION_STACK 的指定位置插入操作，并 prewrite 到 pending。
# index: 0 开头；若 index 为 end 或 超出范围则追加到末尾。
register_operation_at() {
    local idx="$1"; shift
    local provided_id="$1"; shift
    local rollback_cmd="$1"; shift
    local description="$*"

    if [[ -z "$rollback_cmd" ]]; then
        log_error "register_operation_at 用法: register_operation_at <index|end> <op_id|''> <rollback_cmd> [description]"
        return 1
    fi

    if [[ -z "$provided_id" ]]; then
        provided_id=$(generate_op_id)
    fi
    local op_id="$provided_id"

    # 内存映射
    ROLLBACK_COMMANDS["$op_id"]="$rollback_cmd"

    # 计算插入位置
    local new_stack=()
    local inserted=0
    if [[ "$idx" == "end" ]]; then
        OPERATION_STACK+=("$op_id")
        inserted=1
    else
        # ensure numeric
        if ! [[ "$idx" =~ ^[0-9]+$ ]]; then
            log_error "index must be numeric or 'end'"
            return 1
        fi
        local i=0
        for existing in "${OPERATION_STACK[@]}"; do
            if [[ $i -eq $idx && $inserted -eq 0 ]]; then
                new_stack+=("$op_id")
                inserted=1
            fi
            new_stack+=("$existing")
            i=$((i+1))
        done
        if [[ $inserted -eq 0 ]]; then
            # index beyond end -> append
            new_stack+=("$op_id")
        fi
        OPERATION_STACK=("${new_stack[@]}")
    fi

    # prewrite pending entry
    op_prewrite "$op_id" "$rollback_cmd" "$description" || return 1

    # 持久化当前栈顺序的 snapshot（便于恢复）
    _ensure_tx_dirs
    local order_file="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/.stack_order"
    printf '%s\n' "${OPERATION_STACK[@]}" > "$order_file" || true
    sync || true

    echo "$op_id"
}

# register_operation_before <existing_opid> <op_id_or_empty> <rollback_cmd> [description]
# 在指定 existing_opid 之前插入新操作（持久化 pending 与栈快照）
register_operation_before() {
    local existing="$1"; shift
    local provided_id="$1"; shift
    local rollback_cmd="$1"; shift
    local description="$*"
    if [[ -z "$existing" ]]; then
        log_error "register_operation_before: existing_opid required"
        return 1
    fi
    # find index
    local idx=-1 i=0
    for id in "${OPERATION_STACK[@]}"; do
        if [[ "$id" == "$existing" ]]; then
            idx=$i
            break
        fi
        i=$((i+1))
    done
    if [[ $idx -lt 0 ]]; then
        log_error "register_operation_before: existing op_id not found: $existing"
        return 1
    fi
    register_operation_at "$idx" "$provided_id" "$rollback_cmd" "$description"
}

# register_operation_after <existing_opid> <op_id_or_empty> <rollback_cmd> [description]
# 在指定 existing_opid 之后插入新操作
register_operation_after() {
    local existing="$1"; shift
    local provided_id="$1"; shift
    local rollback_cmd="$1"; shift
    local description="$*"
    if [[ -z "$existing" ]]; then
        log_error "register_operation_after: existing_opid required"
        return 1
    fi
    # find index
    local idx=-1 i=0
    for id in "${OPERATION_STACK[@]}"; do
        if [[ "$id" == "$existing" ]]; then
            idx=$i
            break
        fi
        i=$((i+1))
    done
    if [[ $idx -lt 0 ]]; then
        log_error "register_operation_after: existing op_id not found: $existing"
        return 1
    fi
    # insert after -> index+1
    local ins=$((idx+1))
    register_operation_at "$ins" "$provided_id" "$rollback_cmd" "$description"
}

# 获取当前事务目录
rollback_tx_dir(){
    echo "${ROLLBACK_PREFIX}/${TRANSACTION_ID}"
}

# 返回最近记录的 session id（从 last_session.txt）
get_last_session_id(){
    local f="${ROLLBACK_PREFIX}/last_session.txt"
    if [[ -f "$f" ]]; then
        cat "$f"
        return 0
    fi
    return 1
}

# 程序化接口：初始化并将 session id 输出到 stdout，便于脚本捕获
# 用法：sid=$(init_rollback_system_return [rollback_prefix] [--auto-load <txid>])
init_rollback_system_return(){
    init_rollback_system "$@" || return $?
    printf '%s' "${TRANSACTION_ID}"
}
## 自动加载同目录下的其他 rollback-* 脚本（保证 register_operation 可用）
for _f in "${_rb_dir}"/rollback-*.sh; do
    # 跳过自己
    [[ "$_f" = "${_rb_dir}/rollback-manager.sh" ]] && continue
    # 仅在文件存在时 source
    [[ -f "$_f" ]] && source "$_f"
done