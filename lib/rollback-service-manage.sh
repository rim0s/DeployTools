#!/bin/bash

# 安全的服务重启
safe_service_restart() {
    local service="$1"
    local op_id="service_$(date +%s)_${RANDOM}"

    # 1. 检查服务是否存在
    if ! systemctl is-active "$service" >/dev/null 2>&1; then
        log_error "服务不存在或未运行: $service"
        return 1
    fi

    # 2. 记录当前状态
    local status_file="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/service_${service}.status"
    systemctl status "$service" > "$status_file" 2>/dev/null || true

    # 3. 记录回滚命令：恢复到之前状态
    register_operation "$op_id" "systemctl restart '$service'" "restart service $service"

    # 4. 执行重启
    if systemctl restart "$service"; then
        echo "$op_id: restart service $service" >> "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/operations.log"
        echo "$op_id"

        # 等待并验证
        sleep 2
        if systemctl is-active "$service" >/dev/null 2>&1; then
            return 0
        else
            log_error "服务重启后未运行: $service"
            return 1
        fi
    else
        log_error "服务重启失败: $service"
        return 1
    fi
}