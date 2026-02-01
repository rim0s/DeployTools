#!/bin/bash

# 创建系统快照（检查点）
create_checkpoint() {
    local checkpoint_id="checkpoint_$(date +%s)_${RANDOM}"
    local checkpoint_dir="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/checkpoints/${checkpoint_id}"

    mkdir -p "$checkpoint_dir"

    # 记录当前操作栈
    printf "%s\n" "${OPERATION_STACK[@]}" > "${checkpoint_dir}/operation_stack.txt"

    # 记录所有回滚命令
    for key in "${!ROLLBACK_COMMANDS[@]}"; do
        echo "$key: ${ROLLBACK_COMMANDS[$key]}" >> "${checkpoint_dir}/rollback_commands.txt"
    done

    echo "$checkpoint_id"
}

# 恢复到检查点
restore_to_checkpoint() {
    local checkpoint_id="$1"
    local checkpoint_dir="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/checkpoints/${checkpoint_id}"

    if [[ ! -d "$checkpoint_dir" ]]; then
        log_error "检查点不存在: $checkpoint_id"
        return 1
    fi

    log_info "恢复到检查点: $checkpoint_id"

    # 获取检查点中的操作清单
    local current_stack_file="${checkpoint_dir}/operation_stack.txt"
    local checkpoint_ops=()
    if [[ -f "$current_stack_file" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" ]] && checkpoint_ops+=("$line")
        done < "$current_stack_file"
    fi

    # 回滚检查点之后的所有操作
    for ((i=${#OPERATION_STACK[@]}-1; i>=0; i--)); do
        local op_code="${OPERATION_STACK[$i]}"
        # 如果这个操作在检查点中不存在，就回滚它
        if ! printf '%s\n' "${checkpoint_ops[@]}" | grep -q "^${op_code}$"; then
            rollback_operation "$op_code"
        fi
    done

    log_info "已恢复到检查点: $checkpoint_id"
}