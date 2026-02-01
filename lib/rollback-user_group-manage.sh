#!/bin/bash
# user-management.sh

# 安全的用户添加
safe_useradd() {
    local username="$1"
    local op_id="useradd_$(date +%s)_${RANDOM}"

    if id "$username" &>/dev/null; then
        # 用户已存在
        register_operation "$op_id" "echo '用户已存在，无需回滚'" "useradd noop"
        echo "$op_id"
        return 0
    fi

    # 记录回滚命令：删除用户
    register_operation "$op_id" "userdel -r '$username' 2>/dev/null" "useradd rollback: remove $username"

    if useradd "$username"; then
        echo "$op_id: useradd '$username'" >> "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/operations.log"
        echo "$op_id"
        return 0
    else
        log_error "添加用户失败: $username"
        return 1
    fi
}