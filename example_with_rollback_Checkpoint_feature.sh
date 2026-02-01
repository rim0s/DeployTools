#!/bin/bash
# 推荐：通过 loader 加载完整模块集（默认包含 rollback 模块）
# source "$(dirname "$0")/lib/loader.sh"
# 可选逐一加载：
# source "$(dirname "$0")/lib/rollback-manager.sh"
# source "$(dirname "$0")/lib/rollback-file-ops.sh"
# source "$(dirname "$0")/lib/rollback-batch-manage.sh"
source "$(dirname "$0")/lib/loader.sh" 2>/dev/null || source "$(dirname "$0")/lib/rollback-manager.sh"

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
# 可选：直接 source 单个模块（由 loader 管理更推荐）
# source ./rollback-manager.sh

# init_rollback_system (已在上方调用)

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