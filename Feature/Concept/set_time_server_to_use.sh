#!/bin/bash

add_ntp_server() {
    local ntp_server_ip="$1"
    
    # 检查是否提供了IP地址参数
    if [ -z "$ntp_server_ip" ]; then
        echo "请提供一个有效的NTP服务器IP地址."
        return 1
    fi
    
    # 检查chrony服务是否正在运行 #systemctl is-active chronyd
    #if systemctl is-active --quiet chrony; then
    if systemctl is-active --quiet chronyd; then
        #chrony_conf="/etc/chrony/chrony.conf"
        chrony_conf="/etc/chrony.conf"
        echo "本机系统默认使用 chrony 同步时间."
        
        # 检查chrony配置文件是否存在
        if [ ! -f "$chrony_conf" ]; then
            echo "chrony配置文件未找到: $chrony_conf"
            return 1
        fi
        
        # 添加NTP服务器IP地址到chrony配置文件中
        #sudo "sh -c \'echo \"server $ntp_server_ip iburst\" >> $chrony_conf"
        echo "server $ntp_server_ip prefer" | sudo  "sh -c 'tee -a $chrony_conf' "
        #echo "$ltmp_SHARED_DIR *(rw,sync,no_subtree_check)" | sudo_execute "tee -a $ltmp_EXPORTS_FILE" #> /dev/null

        # sudo  "sh -c 'echo \"$ltmp_SHARED_DIR *(rw,sync,no_subtree_check) \" >> /etc/exports' "
    # 可用的方法 -->> echo "$ltmp_SHARED_DIR *(rw,sync,no_subtree_check)" | sudo_execute "tee -a $ltmp_EXPORTS_FILE" #> /dev/null

        # 确保配置更改生效，重启chrony服务
        if sudo systemctl restart chronyd; then
            echo "NTP服务器 $ntp_server_ip 已成功添加到 chrony 并生效."
        else
            echo "无法重启chrony服务."
            return 1
        fi
    # 检查ntpd服务是否正在运行
    elif systemctl is-active --quiet ntpd; then
        ntpd_conf="/etc/ntp.conf"
        echo "本机系统默认使用 ntpd 同步时间."
        
        # 检查ntpd配置文件是否存在
        if [ ! -f "$ntpd_conf" ]; then
            echo "ntpd配置文件未找到: $ntpd_conf"
            return 1
        fi
        
        # 添加NTP服务器IP地址到ntpd配置文件中
        echo "server $ntp_server_ip prefer" >> "$ntpd_conf"
        
        # 确保配置更改生效，重启ntpd服务
        if sudo systemctl restart ntpd; then
            echo "NTP服务器 $ntp_server_ip 已成功添加到 ntpd 并生效."
        else
            echo "无法重启ntpd服务."
            return 1
        fi
    else
        echo "未检测到 chrony 或 ntpd 服务正在运行."
        return 1
    fi
}


if [ -n "$1" ];then
    add_ntp_server $1
else 
    echo "请输入一个IP地址作为参数"
fi