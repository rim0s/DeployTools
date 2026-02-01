#!/bin/bash
# rallback-batch-manage.sh
#!/bin/bash
# rallback-batch-manage.sh

# 开始一个事务批次
begin_batch() {
    local batch_id="batch_$(date +%s)_${RANDOM}"
    local batch_file="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/batch_${batch_id}.txt"

    echo "# Batch: $batch_id" > "$batch_file"
    echo "$batch_id"
}

# 提交操作到批次
add_to_batch() {
    local batch_id="$1"
    shift
    local operation_codes=("$@")
    local batch_file="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/batch_${batch_id}.txt"

    for op_code in "${operation_codes[@]}"; do
        echo "$op_code" >> "$batch_file"
    done
}

# 执行批次回滚（按反序）
rollback_batch() {
    local batch_id="$1"
    local batch_file="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/batch_${batch_id}.txt"

    if [[ ! -f "$batch_file" ]]; then
        log_error "批次不存在: $batch_id"
        return 1
    fi

    log_info "回滚批次: $batch_id"

    # 读取操作码（反序执行）
    local op_codes=()
    while IFS= read -r line; do
        [[ -n "$line" && ! "$line" =~ ^# ]] && op_codes+=("$line")
    done < "$batch_file"

    # 反序执行回滚
    for ((i=${#op_codes[@]}-1; i>=0; i--)); do
        local op_code="${op_codes[$i]}"
        rollback_operation "$op_code"
    done

    log_info "批次回滚完成: $batch_id"
}