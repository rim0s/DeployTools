#!/bin/bash
#################################################################################################
# 防火墙模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/sudo.sh" 2>/dev/null || source "./lib/sudo.sh"

is_firewalld_active() {
    systemctl is-active --quiet firewalld && systemctl is-enabled --quiet firewalld
}

#################################################################################################
# 检查 iptables 是否启用并正在运行
#################################################################################################
is_iptables_active() {
    for service in iptables iptables6 ipfilter ip6tables; do
        systemctl is-active --quiet "$service" && systemctl is-enabled --quiet "$service" && return 0
    done
    return 1
}

#################################################################################################
# 获取正在使用的防火墙类型
#################################################################################################
get_active_firewall() {
    if is_firewalld_active; then
        echo "firewalld"
    elif is_iptables_active; then
        echo "iptables"
    else
        echo "none"
    fi
}

#################################################################################################
# 检查 firewalld 是否成功添加了端口（仅用于firewalld）
#################################################################################################
check_firewalld_port() {
    local zone="$1"
    local port="$2"
    local protocol="$3"
    firewall-cmd --list-all --zone="$zone" | grep -q "ports:.*$port/$protocol"
}

#################################################################################################
# 添加 firewalld 端口并检查是否成功
#################################################################################################
add_firewalld_ports() {
    local zone="$1"
    local protocol="$2"
    local success=true
    local ports=($(echo $GLOBAL_PORT_LIST | tr -d '"' | tr ' ' '\n'))

    for port in "${ports[@]}"; do
        sudo_execute "firewall-cmd --permanent --zone=$zone --add-port=$port/$protocol "
        if ! sudo_execute "firewall-cmd --reload"; then
            log_message "Failed to reload firewalld rules." "ERROR"
            success=false
            break
        fi
        # 可选：检查端口是否成功添加（根据需要决定是否保留这个检查）
        # if ! firewall-cmd --list-all --zone="$zone" | grep -q "ports:.*$port/$protocol"; then
        #     echo "Failed to add port $port/$protocol to firewalld zone $zone."
        #     success=false
        #     break
        # fi
        
        sudo_execute_ "firewall-cmd --query-port=$port/$protocol --zone=$zone"
        if [ "$SUDO_EXECUTE__OUTPUT" = "no" ];then
            log_message "Failed to add port $port/$protocol to firewalld zone $zone."
            success=false
        else
            log_message "Success to add port $port/$protocol to firewalld zone $zone."
        fi

    done

    if $success; then
        log_message "Ports added successfully for firewalld in zone $zone." "INFO"
    else
        log_message "Some ports failed to add for firewalld in zone $zone." "ERROR"
        return 1
    fi

    return 0
}

#################################################################################################
# 添加 iptables 端口（不直接检查规则添加是否成功）
#################################################################################################
add_iptables_ports() {
    local protocol="$1"
    local success=true
    local ports=($(echo $GLOBAL_PORT_LIST | tr -d '"' | tr ' ' '\n'))

    log_message "iptables 对应的删除和添加端口函数并为经过测试,为避免问题会直接退出"
    return 1

    for port in "${ports[@]}"; do
        sudo_execute "iptables -A INPUT -p $protocol --dport $port -j ACCEPT"
        if [[ $? -ne 0 ]]; then
            log_message "Failed to add iptables rule for port $port/$protocol." "ERROR"
            success=false
            break
        fi
    done

    # 保存 iptables 规则（根据系统不同，使用不同的命令）
    if command -v service &> /dev/null; then
        sudo_execute "service iptables save"
    elif command -v systemctl &> /dev/null; then
        iptables-save | sudo_execute "tee /etc/iptables/rules.v4"
    else
        log_message "Failed to save iptables rules." "ERROR"
        success=false
    fi

    if $success; then
        log_message "Ports added successfully for iptables (assuming rules were added correctly)." "INFO"
    else
        log_message "Some ports failed to add for iptables." "ERROR"
        return 1
    fi
}

add_icmp_reply_block_rule()
{
    local firewall_type="$1"
    local zone="${2:-public}"  # 如果第二个参数为空，则默认为"public"

    if [ "$firewall_type" == "firewalld" ];then
        sudo_execute "firewall-cmd --permanent --add-icmp-block=echo-request --zone=$zone"
        sudo_execute "firewall-cmd --reload"

        sudo_execute_ "firewall-cmd --zone=$zone --query-icmp-block=echo-request"
        if [ "$SUDO_EXECUTE__OUTPUT" == "yes" ];then 
            log_message "ICMP echo-request will be Block .ICMP 回应的 屏蔽规则已添加."
            log_message "注意,本函数仅适用管理员初始化设置时规则的变更.如需添加更复杂屏蔽规则,需要自行设置."
        else
            log_message "ICMP echo-request Block rule add fail.ICMP 回应的 屏蔽规则添加失败." "ERROR"
            return 1
        fi
    elif [ "$firewall_type" == "iptables" ];then
        echo "Er...,UnSupport yet"
    fi
    
    return 0
}

remove_icmp_reply_block_rule()
{
    local firewall_type="$1"
    local zone="${2:-public}"  # 如果第二个参数为空，则默认为"public"

    if [ "$firewall_type" == "firewalld" ];then
        sudo_execute "firewall-cmd --permanent --remove-icmp-block=echo-request --zone=$zone"
        sudo_execute "firewall-cmd --reload"

        sudo_execute_ "firewall-cmd --zone=$zone --query-icmp-block=echo-request"
        if [ "$SUDO_EXECUTE__OUTPUT" == "no" ];then 
            log_message "ICMP echo-request will not Block any more.ICMP 回应的 屏蔽规则已删除."
            log_message "注意,本函数仅适用管理员初始化设置时规则的变更.如存在其他屏蔽规则,需要自行修改."
        else
            log_message "ICMP echo-request Block rule remove fail.ICMP 回应的 屏蔽规则删除失败." "ERROR"
            return 1
        fi
    elif [ "$firewall_type" == "iptables" ];then
        echo "Er...,UnSupport yet"
    fi
    
    return 0
}

#################################################################################################
# 添加防火墙端口函数
# 示例：设置全局变量并调用 add_firewall_ports 函数
#       假设用户输入了 "8080 8443"
#           user_input="8080 8443"
#           GLOBAL_PORT_LIST="\"$user_input\""
#           add_firewall_ports "tcp" "public"
#################################################################################################
add_firewall_ports_usage(){
    
    echo -ne "${GREEN}
    --add_fw_port ${BLUE}\"port_list\"  ${GREEN}--type ${BLUE}[tcp/udp${NC}] [${GREEN}--zone ${BLUE}public${NC}] ${GREEN}-p ${NC}[${GREEN}--permanent${NC}]  
                    ${NC}添加端口清单 port_list 类型tcp或udp端口至防火墙 ${NC}
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}--zone ${BLUE}public ${GREEN}-p${NC}
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}--zone ${BLUE}trusted ${GREEN}-p${NC}
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}--zone ${BLUE}work ${GREEN}-p${NC}
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}--zone ${BLUE}home ${NC}
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}-p${NC}
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} 
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088 6300\"${NC} ${GREEN}--icmp_reply ${BLUE}add${NC} 
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088\"${NC} ${GREEN}--icmp_reply ${BLUE}remove${NC} 
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"\"${NC} ${GREEN}--icmp_reply ${BLUE}remove${NC} "
    echo
}
#################################################################################################
add_firewall_ports() {
    local port_type="$1"
    local zone="${2:-public}"  # 如果第二个参数为空，则默认为"public"
    local ltmp_icmp_reply="$this_icmp_reply"
    local firewall_type
    local protocol
    #local ports=()
    local success=true

    # 处理端口类型
    echo "PORT_TYPE is : $port_type"
    case "$port_type" in
        tcp|t)
            protocol="tcp"
            ;;
        udp|u)
            protocol="udp"
            ;;
        *)
            log_message "Invalid port type specified. Use 'tcp', 't', 'udp', or 'u'." "ERROR"
            return 1
            ;;
    esac

    # 将端口字符串转换为数组
    #IFS=' ' read -r -a ports <<< "$ports_str"

    # 获取正在使用的防火墙类型
    firewall_type=$(get_active_firewall)

    if [[ "$firewall_type" == "none" ]]; then
        log_message "No supported firewall found on this system or firewall is not active." "ERROR"
        return 1
    fi

    case "$ltmp_icmp_reply" in
        "add")
            add_icmp_reply_block_rule "$firewall_type" "$zone"
            ;;
        "remove")
            remove_icmp_reply_block_rule "$firewall_type" "$zone"
            ;;
        *)
            log_message "ltmp_icmp_reply=$ltmp_icmp_reply,Not Support yet."
            ;;
    esac

    # 确保 GLOBAL_PORT_LIST 已经被正确设置
    if [ "$GLOBAL_PORT_LIST" == "" ] || [ "$GLOBAL_PORT_LIST" == "\"\"" ];then
        log_message "port_list is empty.Will not add any port." "WARNING"
        log_message "port_list 为空,将不会添加任何端口." "WARNING"
        #end_the_batch
        return 1
    fi

    # 根据正在使用的防火墙添加端口
    if [[ "$firewall_type" == "firewalld" ]]; then
        add_firewalld_ports "$zone" "$protocol"
    elif [[ "$firewall_type" == "iptables" ]]; then
        add_iptables_ports "$protocol"
    else
        # 如果系统同时启用了 firewalld 和 iptables（不常见），则向两者都添加端口
        # 注意：这里可能会存在逻辑冲突或重复添加的问题，需要根据实际需求调整
        if is_firewalld_active; then
            add_firewalld_ports "$zone" "${ports[@]}" "$protocol"
            if [[ $? -ne 0 ]]; then
                success=false
            fi
        fi
        if is_iptables_active; then
            add_iptables_ports "${ports[@]}" "$protocol"
            if [[ $? -ne 0 ]]; then
                success=false
            fi
        fi
    fi

    if $success; then
        log_message "Ports added successfully for $firewall_type in zone $zone." "INFO"
    else
        log_message "Some ports failed to add for $firewall_type in zone $zone." "ERROR"
        return 1
    fi

    echo "当前防火墙规则:"
    echo "==========================================================================" 
    echo "$(sudo_execute "firewall-cmd --list-all-zone")"
    echo "==========================================================================" 

    log_message "执行成功"
}

#################################################################################################
# 删除 firewalld 端口并检查是否成功
#################################################################################################
remove_firewalld_ports() {
    local zone="$1"
    local protocol="$2"
    local success=true
    local ports=($(echo $GLOBAL_PORT_LIST_TO_REMOVE | tr -d '"' | tr ' ' '\n'))

    for port in "${ports[@]}"; do
        sudo_execute "firewall-cmd --permanent --zone=$zone --remove-port=$port/$protocol"
        if ! sudo_execute "firewall-cmd --reload"; then
            log_message "Failed to reload firewalld rules." "ERROR"
            success=false
            break
        fi

        sudo_execute_ "firewall-cmd --query-port=$port/$protocol --zone=$zone"
        if [ "$SUDO_EXECUTE__OUTPUT" = "yes" ];then
            log_message "Failed to remove port $port/$protocol from firewalld zone $zone."
            success=false
        else
            log_message "Success to remove port $port/$protocol from firewalld zone $zone."
        fi

    done

    if $success; then
        log_message "Ports removed successfully for firewalld in zone $zone." "INFO"
    else
        log_message "Some ports failed to remove for firewalld in zone $zone." "ERROR"
        return 1
    fi
    return 0
}

#################################################################################################
# 删除 iptables 端口（不直接检查规则删除是否成功）
#################################################################################################
remove_iptables_ports() {
    local protocol="$1"
    local success=true
    local ports=($(echo $GLOBAL_PORT_LIST_TO_REMOVE | tr -d '"' | tr ' ' '\n'))

    log_message "iptables 对应的删除和添加端口函数并为经过测试,为避免问题会直接退出"
    return 1

    # iptables 删除规则通常比较复杂，因为需要精确匹配已有的规则
    # 这里我们假设只是简单地删除所有匹配的端口规则（这可能不是最佳实践）
    for port in "${ports[@]}"; do
        sudo_execute "iptables -D INPUT -p $protocol --dport $port -j ACCEPT" || true
        
        # 注意：上面的命令可能会删除多条匹配的规则，或者没有规则被删除时也会返回成功
        # 在实际应用中，您可能需要更精确地定位要删除的规则
    done

    # 保存 iptables 规则（根据系统不同，使用不同的命令）
    # ...（与之前相同）

    if $success; then
        log_message "Ports removed successfully for iptables (assuming rules were removed correctly)." "INFO"
    else
        log_message "Some ports failed to remove for iptables." "ERROR"
        return 1
    fi
}

#################################################################################################
# 删除 iptables 端口函数 V2版本实现方式,因为两版均未测试,因此函数名末尾加了_后缀.
#   需要注意的是，由于iptables规则的复杂性，精确删除特定规则可能需要更多的信息（如规则编号、链名等）。
#       不过，为了简化，这里我们假设要删除所有匹配指定协议和端口的INPUT链规则。
#################################################################################################
remove_iptables_ports_() {
    local protocol="$1"
    local ports=($(echo $GLOBAL_PORT_LIST_TO_REMOVE | tr -d '"' | tr ' ' '\n'))
    local rule_num
    local success=true

    log_message "iptables 对应的删除和添加端口函数并为经过测试,为避免问题会直接退出"
    return 1

    # 遍历每个端口，尝试删除匹配的规则
    for port in "${ports[@]}"; do
        # 列出所有 INPUT 链的规则，并查找匹配端口和协议的规则编号
        # 注意：这个命令可能会输出多条规则，我们需要处理所有匹配的规则
        rule_nums=$(iptables -L INPUT -n -v --line-numbers | grep "\->$port\s*$protocol" | awk '{print $1}')

        # 删除匹配的规则
        for rule_num in $rule_nums; do
            sudo_execute "iptables -D INPUT $rule_num" || {
                log_message "Failed to remove iptables rule number $rule_num for port $port/$protocol." "ERROR"
                success=false
            }
        done
    done

    # 保存 iptables 规则（根据系统不同，使用不同的命令）
    # 对于基于 Debian 的系统（如 Ubuntu），使用 iptables-persistent
    if command -v iptables-save &> /dev/null; then
        sudo_execute " iptables-save > /etc/iptables/rules.v4 "  # 对于 IPv4 规则
        # 如果需要，也可以保存 IPv6 规则：iptables-save -6 > /etc/iptables/rules.v6
    # 对于基于 Red Hat 的系统（如 CentOS、Fedora），使用 service iptables save
    elif command -v service &> /dev/null; then
        sudo_execute "service iptables save"
    else
        log_message "Unknown system. Failed to save iptables rules." "ERROR"
        success=false
    fi

    if $success; then
        log_message "Ports removed successfully for iptables." "INFO"
    else
        log_message "Some ports failed to remove for iptables." "ERROR"
        return 1
    fi
# 在这个实现中，我们首先解析全局变量GLOBAL_PORT_LIST_TO_REMOVE来获取要删除的端口列表。
#   然后，对于每个端口，我们使用iptables -L INPUT -n -v --line-numbers命令来列出INPUT链的所有规则，
#       并使用grep和awk来查找匹配指定端口和协议的规则编号。最后，我们使用iptables -D INPUT命令来删除这些规则。
# 请注意以下几点：
#  o   这个实现假设GLOBAL_PORT_LIST_TO_REMOVE已经包含要删除的端口号列表，并且这些端口号是以空格分隔的。
#  o   我们使用iptables -L命令的--line-numbers选项来获取规则的编号，这对于删除规则是必需的。
#  o   我们使用grep来匹配规则的端口和协议，这可能会受到其他规则中相似内容的影响。因此，在实际应用中，您可能需要更精确的匹配逻辑。
#  o   我们使用iptables-save或service iptables save命令来保存更改后的规则，这取决于系统的类型。您可能需要根据您的系统调整这部分逻辑。
#  o   这个实现没有处理iptables规则删除失败的情况（除了打印一条错误消息和设置success变量为false之外）。在实际应用中，您可能需要更复杂的错误处理逻辑。

}

#################################################################################################
# 添加防火墙端口函数
# 示例：设置全局变量并调用 add_firewall_ports 函数
#       假设用户输入了 "8080 8443"
#           user_input="8080 8443"
#           GLOBAL_PORT_LIST="\"$user_input\""
#           add_firewall_ports "tcp" "public"

remove_firewall_ports_usage(){
    
    echo -ne "${GREEN}
    --remove_fw_port ${BLUE}\"port_list\"  ${GREEN}--type ${BLUE}[tcp/udp${NC}] [${GREEN}--zone ${BLUE}public${NC}] ${GREEN}-p ${NC}[${GREEN}--permanent${NC}]  
                    ${NC}从防火墙移除清单 port_list 中类型tcp或udp的所有端口 ${NC}
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}--zone ${BLUE}trusted ${GREEN}-p${NC}
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}--zone ${BLUE}work ${GREEN}-p${NC}
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}--zone ${BLUE}home ${NC}
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}-p${NC}
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} 
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"9060 8088 6300\"${NC} ${GREEN}--icmp_reply ${BLUE}add${NC} 
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"9060 8088\"${NC} ${GREEN}--icmp_reply ${BLUE}remove${NC} 
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"\"${NC} ${GREEN}--icmp_reply ${BLUE}remove${NC} "
    echo 
}
#################################################################################################

#################################################################################################
# 删除防火墙端口函数
#################################################################################################
remove_firewall_ports() {
    local port_type="$1"
    local zone="${2:-public}"  # 如果第二个参数为空，则默认为 "public"
    local ltmp_icmp_reply="$this_icmp_reply"
    local firewall_type
    local protocol
    #local ports=()
    local success=true

    # 处理端口类型
    echo "PORT_TYPE is : $port_type"
    case "$port_type" in
        tcp|t)
            protocol="tcp"
            ;;
        udp|u)
            protocol="udp"
            ;;
        *)
            log_message "Invalid port type specified. Use 'tcp', 't', 'udp', or 'u'." "ERROR"
            return 1
            ;;
    esac

    # 将端口字符串转换为数组
    #IFS=' ' read -r -a ports <<< "$ports_str"

    # 获取正在使用的防火墙类型,get_active_firewall这个函数已经实现并返回"firewalld"或"iptables"
    firewall_type=$(get_active_firewall) 

    if [[ "$firewall_type" == "none" ]]; then
        log_message "No supported firewall found on this system or firewall is not active." "ERROR"
        return 1
    fi

    case "$ltmp_icmp_reply" in
        "add")
            add_icmp_reply_block_rule "$firewall_type" "$zone"
            ;;
        "remove")
            remove_icmp_reply_block_rule "$firewall_type" "$zone"
            ;;
        *)
            log_message "ltmp_icmp_reply=$ltmp_icmp_reply,Not Support yet."
            ;;
    esac

    # 确保 GLOBAL_PORT_LIST_TO_REMOVE 已经被正确设置
    if [ -z "$GLOBAL_PORT_LIST_TO_REMOVE" ] || [ "$GLOBAL_PORT_LIST_TO_REMOVE" == "\"\"" ];then
        log_message "port_list is empty.Will not remove any port." "WARNING"
        log_message "port_list 为空,将不会移除任何端口." "WARNING"
        #end_the_batch
        return 1
    fi
   
    # 根据正在使用的防火墙删除端口
    if [[ "$firewall_type" == "firewalld" ]]; then
        # 调用删除 firewalld 端口的函数
        remove_firewalld_ports "$zone" "$protocol"
        if [[ $? -ne 0 ]]; then
            success=false
        fi
    elif [[ "$firewall_type" == "iptables" ]]; then
        # 调用删除 iptables 端口的函数
        remove_iptables_ports "$protocol"
        if [[ $? -ne 0 ]]; then
            success=false
        fi
    else
        log_message "Unknown firewall type: $firewall_type" "ERROR"
        return 1
    fi

    # 输出操作结果
    if $success; then
        log_message "Ports removed successfully for $firewall_type in zone $zone." "INFO"
    else
        log_message "Some ports failed to remove for $firewall_type in zone $zone." "ERROR"
        return 1
    fi
    
    echo "当前防火墙规则:"
    echo "==========================================================================" 
    echo "$(sudo_execute "firewall-cmd --list-all-zone")"
    echo "==========================================================================" 

    log_message "执行成功"
}

############################