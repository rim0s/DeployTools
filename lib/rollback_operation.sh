#!/bin/bash
# rollback_operation.sh

# 执行单个操作的回滚（安全、记录结果）
rollback_operation() {
    local op_code="$1"

    if [[ -z "$op_code" ]]; then
        log_error "rollback_operation: missing op_code"
        return 2
    fi

    local cmd="${ROLLBACK_COMMANDS[$op_code]}"
    if [[ -z "$cmd" ]]; then
        log_warn "未找到回滚命令，跳过: $op_code"
        return 0
    fi

    log_info "开始回滚: $op_code"
    log_debug "回滚命令: $cmd"

    # 执行回滚命令并记录结果
    if eval "$cmd"; then
        log_info "回滚成功: $op_code"
        local ts
        ts="$(date --rfc-3339=seconds 2>/dev/null || date +"%Y-%m-%d %H:%M:%S")"
        echo "ROLLED | $ts | $op_code | 0" >> "$(rollback_tx_dir)/operations.log"
        unset "ROLLBACK_COMMANDS[$op_code]"
        return 0
    else
        local rc=$?
        log_error "回滚失败: $op_code (rc=$rc)"
        local ts
        ts="$(date --rfc-3339=seconds 2>/dev/null || date +"%Y-%m-%d %H:%M:%S")"
        echo "FAILED | $ts | $op_code | $rc" >> "$(rollback_tx_dir)/operations.log"
        return $rc
    fi
}

# 回滚所有注册的操作（逆序执行）。遇到失败继续执行其余操作，最后返回非0表示至少有一次失败。
rollback_all() {
    log_info "开始回滚所有操作（逆序执行）..."

    local any_failed=0
    for ((i=${#OPERATION_STACK[@]}-1; i>=0; i--)); do
        local op_code="${OPERATION_STACK[$i]}"
        # 跳过已经被 unset 的操作（可能已在 earlier rollback）
        if [[ -z "${ROLLBACK_COMMANDS[$op_code]}" ]]; then
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