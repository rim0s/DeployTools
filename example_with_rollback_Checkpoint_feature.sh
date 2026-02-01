#!/bin/bash
source "$(dirname "$0")/lib/rollback-manager.sh"

init_rollback_system

# 第一阶段：准备
log_info "=== 第一阶段：准备 ==="
safe_cp "/etc/app/config.yaml" "/etc/app/config.yaml.backup"
checkpoint1=$(create_checkpoint)

# 第二阶段：修改
log_info "=== 第二阶段：修改 ==="
safe_sed_replace "/etc/app/config.yaml" "port: 8080" "port: 9090"
checkpoint2=$(create_checkpoint)

# 第三阶段：验证
log_info "=== 第三阶段：验证 ==="
if ! validate_config; then
    log_warn "配置验证失败，恢复到检查点2"
    restore_to_checkpoint "$checkpoint2"
    
    # 或者恢复到更早的检查点
    # restore_to_checkpoint "$checkpoint1"
fi
#!/bin/bash
source ./rollback-manager.sh

init_rollback_system

# 第一阶段：准备
echo "=== 第一阶段：准备 ==="
safe_cp "/etc/app/config.yaml" "/etc/app/config.yaml.backup"
checkpoint1=$(create_checkpoint)

# 第二阶段：修改
echo "=== 第二阶段：修改 ==="
safe_sed_replace "/etc/app/config.yaml" "port: 8080" "port: 9090"
checkpoint2=$(create_checkpoint)

# 第三阶段：验证
echo "=== 第三阶段：验证 ==="
if ! validate_config; then
    echo "配置验证失败，恢复到检查点2"
    restore_to_checkpoint "$checkpoint2"
    
    # 或者恢复到更早的检查点
    # restore_to_checkpoint "$checkpoint1"
fi