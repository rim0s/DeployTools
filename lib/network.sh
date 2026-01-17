#!/bin/bash
#################################################################################################
# 网络模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"

#################################################################################################
# 检查是否可以访问互联网
#################################################################################################
check_internet() {
    if ping -c 1 223.5.5.5 > /dev/null 2>&1; then
        echo "可以访问互联网"
        return 0
    else
        echo "无法访问互联网"
        return 1
    fi
}

#################################################################################################
# 检查是否可以访问指定的内网IP
#################################################################################################
check_intranet_ip() {
    local ip=$1
    if ping -c 1 $ip > /dev/null 2>&1; then
        echo "可以访问内网IP: $ip"
        return 0
    else
        echo "无法访问内网IP: $ip"
        return 1
    fi
}

#################################################################################################
# 网络连接检查使用说明
#################################################################################################
check_connectivity_innerusage() {
    echo "用法: $0 <功能> [内网IP]"
    echo "功能: internet - 检查互联网连接"
    echo "      intranet - 检查到指定内网IP的连接"
    exit 1
}

#################################################################################################
# 检查是否可以访问网络
# 可以访问 返回 0 
# 不可以  返回 1
#################################################################################################
check_connectivity(){
    # 检查是否提供了足够的参数
    if [ $# -lt 1 ]; then
        check_connectivity_innerusage
    fi

    # 根据提供的功能参数执行相应的检查
    case $1 in
        internet)
            check_internet
            ;;
        intranet)
            if [ -z "$2" ]; then
                echo "请指定一个内网IP地址"
                check_connectivity_innerusage
            fi
            check_intranet_ip $2
            ;;
        *)
            check_connectivity_innerusage
            ;;
    esac
}

#################################################################################################
# 获取所有IP地址
#################################################################################################
get_all_ip() {
    local ltmp_b_network_promision=false

    # 检查网络是否开启
    ip link show | grep -q 'state UP'
    local ltmp_ret_ip_link_show=$?

    case $ltmp_ret_ip_link_show in
        0)
            ltmp_b_network_promision=true
            LOG_message "网络已开启" "INFO"
            ;;
        *)
            ltmp_b_network_promision=false
            LOG_message "网络未开启" "WARNING"
            return 1
            ;;
    esac

    # 获取IP地址
    this_host_ip_list=$(ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1')
    
    LOG_message "本机IP地址列表: $this_host_ip_list" "INFO"
    echo "$this_host_ip_list"
    
    return 0
}
