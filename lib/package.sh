#!/bin/bash
#################################################################################################
# 包管理模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"

#################################################################################################
# 检测系统包管理器
#################################################################################################
which_app_manager(){
    # command -v用于检查命令是否存在，并显示其路径。
    # 如果命令不存在，则返回错误。该命令可以忽略环境变量，直接查找系统路径中的命令。

    # 检查 dnf 命令是否存在 (Fedora|Red Hat Enterprise Linux|CentOS|RHEL 及其他基于 Linux 内核服务器操作系统)
    if command -v dnf &> /dev/null
    then
        LOG_message "当前系统的包管理器是 dnf " "INFO"
        app_manager=dnf
    # 检查 apt-get 命令是否存在（对于Debian系Linux,如Ubuntu,mint,kali 及其他基于 Linux 内核桌面操作系统）
    elif command -v apt-get &> /dev/null
    then
        LOG_message "当前系统的包管理器是 apt " "INFO"
        app_manager=apt
    # 检查 pkg 命令是否存在（对于FreeBSD系Linux）
    elif command -v pkg &> /dev/null
    then
        LOG_message "当前系统的包管理器是 pkg " "INFO"
        app_manager=pkg
    # 检查 zypper 命令是否存在（对于 openSUSE|SUSE 系Linux）
    elif command -v zypper &> /dev/null
    then
        LOG_message "当前系统的包管理器是 zypper " "INFO"
        app_manager=zypper
    else
        log_message "无法确定当前系统的包管理器 " "ERROR"
        app_manager=unknow
        return 1
    fi
    return 0
}
