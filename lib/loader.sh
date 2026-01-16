#!/bin/bash
#################################################################################################
# 模块加载器
# 用于统一加载所有模块
#################################################################################################

# 获取脚本所在目录
if [ -z "$LIB_DIR" ]; then
    if [ -n "${BASH_SOURCE[0]}" ]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    fi
    export LIB_DIR="${SCRIPT_DIR}"
else
    SCRIPT_DIR="${LIB_DIR}"
fi

# 加载基础模块（按依赖顺序）
source "${LIB_DIR}/constants.sh" 2>/dev/null || source "./lib/constants.sh"
source "${LIB_DIR}/config.sh" 2>/dev/null || source "./lib/config.sh"
source "${LIB_DIR}/utils.sh" 2>/dev/null || source "./lib/utils.sh"
source "${LIB_DIR}/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "${LIB_DIR}/help.sh" 2>/dev/null || source "./lib/help.sh"
source "${LIB_DIR}/package.sh" 2>/dev/null || source "./lib/package.sh"
source "${LIB_DIR}/sudo.sh" 2>/dev/null || source "./lib/sudo.sh"
source "${LIB_DIR}/banner.sh" 2>/dev/null || source "./lib/banner.sh"
source "${LIB_DIR}/init.sh" 2>/dev/null || source "./lib/init.sh"
source "${LIB_DIR}/firewall.sh" 2>/dev/null || source "./lib/firewall.sh"
source "${LIB_DIR}/system.sh" 2>/dev/null || source "./lib/system.sh"
source "${LIB_DIR}/monitor.sh" 2>/dev/null || source "./lib/monitor.sh"

# 初始化日志(需要在config加载后)
init_log 2>/dev/null

# 记录模块加载
LOG_message "模块加载器已加载所有基础模块" "INFO" 2>/dev/null || true
