#!/bin/bash
#################################################################################################
# 使用示例脚本
# 演示如何使用模块化的ProjectManage功能
#################################################################################################

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载所有模块
source "${SCRIPT_DIR}/lib/loader.sh"

# 初始化
init_the_batch "$@"

# 示例1 : 使用日志功能
echo "=== 示例1 : 日志功能 ==="
log_message "这是一条INFO级别的日志" "INFO"
log_message "这是一条WARNING级别的日志" "WARNING"
log_message "这是一条ERROR级别的日志" "ERROR"

# 示例2 : 使用sudo执行功能
echo "=== 示例2 : sudo执行功能 ==="
# sudo_execute "whoami"

# 示例3 : 使用防火墙功能
echo "=== 示例3 : 防火墙功能 ==="
# 检查当前防火墙类型
firewall_type=$(get_active_firewall)
log_message "当前激活的防火墙类型: $firewall_type" "INFO"

# 示例4 : 添加防火墙端口（需要取消注释并设置正确的端口)
# GLOBAL_PORT_LIST='"8080 8443"'
# add_firewall_ports "tcp" "public"

# 清理和结束
end_the_batch
