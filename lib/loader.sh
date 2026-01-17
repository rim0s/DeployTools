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

# 2026-01-17 由AI拆分的核心模块
source "${LIB_DIR}/debug.sh" 2>/dev/null || source "./lib/debug.sh"
source "${LIB_DIR}/network.sh" 2>/dev/null || source "./lib/network.sh"
source "${LIB_DIR}/package_advanced.sh" 2>/dev/null || source "./lib/package_advanced.sh"
source "${LIB_DIR}/path.sh" 2>/dev/null || source "./lib/path.sh"
source "${LIB_DIR}/config_file.sh" 2>/dev/null || source "./lib/config_file.sh"
source "${LIB_DIR}/parser.sh" 2>/dev/null || source "./lib/parser.sh"
source "${LIB_DIR}/project.sh" 2>/dev/null || source "./lib/project.sh"

# 2026-01-17 由AI拆分的系统管理模块（未测试）
source "${LIB_DIR}/nfs.sh" 2>/dev/null || source "./lib/nfs.sh"
source "${LIB_DIR}/vnc.sh" 2>/dev/null || source "./lib/vnc.sh"
source "${LIB_DIR}/httpd.sh" 2>/dev/null || source "./lib/httpd.sh"
source "${LIB_DIR}/security.sh" 2>/dev/null || source "./lib/security.sh"
source "${LIB_DIR}/device.sh" 2>/dev/null || source "./lib/device.sh"

# 2026-01-17 由AI拆分的V48遗留功能模块（未测试）
source "${LIB_DIR}/config_file_v48_legacy.sh" 2>/dev/null || source "./lib/config_file_v48_legacy.sh"
source "${LIB_DIR}/class_file_v48_legacy.sh" 2>/dev/null || source "./lib/class_file_v48_legacy.sh"
source "${LIB_DIR}/media_tools_v48.sh" 2>/dev/null || source "./lib/media_tools_v48.sh"
source "${LIB_DIR}/misc_legacy_v48.sh" 2>/dev/null || source "./lib/misc_legacy_v48.sh"
source "${LIB_DIR}/system_boot.sh" 2>/dev/null || source "./lib/system_boot.sh"

# 初始化日志(需要在config加载后)
init_log 2>/dev/null

# 记录模块加载
LOG_message "模块加载器已加载所有基础模块" "INFO" 2>/dev/null || true
