#!/bin/bash
# 安装脚本示例

# 推荐：通过 loader 加载完整模块集（默认包含 rollback 模块）
# source "$(dirname "$0")/lib/loader.sh"
# 可选：逐一 source 特定库（如果不想通过 loader）：
# source "$(dirname "$0")/lib/rollback-manager.sh"
# source "$(dirname "$0")/lib/rollback-file-ops.sh"
# source "$(dirname "$0")/lib/rollback-conf-change.sh"
# source "$(dirname "$0")/lib/rollback-service-manage.sh"

# 支持 --restore 参数调用恢复工具（确保 loader 已加载或按需 source rollback-manager）
source "$(dirname "$0")/lib/loader.sh" 2>/dev/null || source "$(dirname "$0")/lib/rollback-manager.sh"

# 支持 --restore 参数调用恢复工具
if [[ "$1" == "--restore" ]]; then
    TXDIR="${ROLLBACK_PREFIX}/${TRANSACTION_ID}"
    # 如果没传 Transaction ID，可以让用户指定第二个参数
    if [[ -n "$2" ]]; then
        TXDIR="$2"
    fi
    "$(dirname "$0")/lib/rollback-recover.sh" "$TXDIR"
    exit $?
fi

# 初始化回滚系统
init_rollback_system

# 记录所有操作码
declare -a my_ops

# 执行一系列操作
log_info "=== 开始执行操作 ==="

# 1. 备份重要文件
backup_op=$(safe_cp "/etc/nginx/nginx.conf" "/etc/nginx/nginx.conf.backup")
if [[ -n "$backup_op" ]]; then
    my_ops+=("$backup_op")
fi

# 2. 更新配置文件
sed_op=$(safe_sed_replace "/etc/nginx/nginx.conf" "worker_processes 1;" "worker_processes 4;")
if [[ -n "$sed_op" ]]; then
    my_ops+=("$sed_op")
fi

# 3. 添加新配置
cp_op=$(safe_cp "./new-site.conf" "/etc/nginx/conf.d/new-site.conf")
if [[ -n "$cp_op" ]]; then
    my_ops+=("$cp_op")
fi

# 4. 重启服务
service_op=$(safe_service_restart "nginx")
if [[ -n "$service_op" ]]; then
    my_ops+=("$service_op")
fi

# 检查是否有失败的操作
if [[ ${#my_ops[@]} -lt 4 ]]; then
    log_warn "部分操作失败，开始回滚..."
    for ((i=${#my_ops[@]}-1; i>=0; i--)); do
        rollback_operation "${my_ops[$i]}"
    done
    exit 1
fi

log_info "=== 所有操作成功完成 ==="