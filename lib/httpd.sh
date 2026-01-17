#!/bin/bash
#################################################################################################
# HTTP服务管理模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/sudo.sh" 2>/dev/null || source "./lib/sudo.sh"
source "$(dirname "$0")/package_advanced.sh" 2>/dev/null || source "./lib/package_advanced.sh"
source "$(dirname "$0")/system.sh" 2>/dev/null || source "./lib/system.sh"
source "$(dirname "$0")/firewall.sh" 2>/dev/null || source "./lib/firewall.sh"
source "$(dirname "$0")/network.sh" 2>/dev/null || source "./lib/network.sh"

#################################################################################################
# 启动HTTP服务使用说明
#################################################################################################
start_my_httpd_usage(){
    echo -ne "${GREEN}
    --start-my-httpd${BLUE} <dir_1> <dir_2> <dir_3> ...  ${NC}从[ 个人主目录下的指定目录 ] 启动httpd服务,作为http网站根目录${GREEN}"
    echo
}

#################################################################################################
# 获取网站目录
#################################################################################################
get_site_directories() {
    echo "$@"
}

#################################################################################################
# 启动HTTP服务
#################################################################################################
start_my_httpd(){
    show_who_call
    
    case $app_manager in 
        dnf)
            check_packages_installed "httpd"
            if [ -n "$this_not_installed_packages" ];then
                install_package "$this_not_installed_packages"
            fi
            ;;
        *)
            log_message "其他包管理器: [ $app_manager ] 对应的包安装逻辑暂未编写." "ERROR"
            return 1
            ;;
    esac

    local ltmp_site_directorys=$(get_site_directories "$@")

    if [ -z "$ltmp_site_directorys" ];then
        log_message "未提供网站根目录,请提供至少一个目录作为网站根目录." "ERROR"
        return 1
    fi

    log_message "将要设置网站根目录为: [ $ltmp_site_directorys ]" "WARNING"

    # 修改httpd.conf配置文件中的DocumentRoot指向新的网站根目录
    local ltmp_httpd_conf="/etc/httpd/conf/httpd.conf"
    local ltmp_backup_identifier=$(backup_and_log "$ltmp_httpd_conf")
    
    if [ -z "$ltmp_backup_identifier" ] || [ "$ltmp_backup_identifier" == "1" ]; then
        log_message "$ltmp_httpd_conf 文件备份失败." "ERROR"
        return 1
    else
        log_message "$ltmp_httpd_conf 文件备份成功,唯一标识为 [ $ltmp_backup_identifier ] " "WARNING"
    fi

    for site_directory in $ltmp_site_directorys; do
        local ltmp_full_path="$HOME/$site_directory"
        
        if [ ! -d "$ltmp_full_path" ]; then
            log_message "目录 $ltmp_full_path 不存在,创建中..." "WARNING"
            mkdir -p "$ltmp_full_path"
        fi

        log_message "设置目录 $ltmp_full_path 权限为755..." "WARNING"
        chmod -R 755 "$ltmp_full_path"
        
        log_message "设置目录 $ltmp_full_path 的SELinux上下文..." "WARNING"
        sudo_execute "chcon -R -t httpd_sys_content_t $ltmp_full_path"

        local ltmp_old_DocumentRoot=$(grep "^DocumentRoot" "$ltmp_httpd_conf" | awk '{print $2}' | tr -d '"')
        log_message "原DocumentRoot为: [ $ltmp_old_DocumentRoot ]" "WARNING"
        
        log_message "修改DocumentRoot为: [ $ltmp_full_path ]" "WARNING"
        sudo_execute "sed -i 's|^DocumentRoot.*|DocumentRoot \"$ltmp_full_path\"|g' $ltmp_httpd_conf"
        
        log_message "修改Directory配置..." "WARNING"
        sudo_execute "sed -i 's|<Directory \"$ltmp_old_DocumentRoot\">|<Directory \"$ltmp_full_path\">|g' $ltmp_httpd_conf"
    done

    log_message "启动httpd服务..." "WARNING"
    sudo_execute "systemctl start httpd"
    sudo_execute "systemctl enable httpd"
    
    log_message "开启防火墙对http服务的规则." "WARNING"
    sudo_execute "firewall-cmd --add-service=http $this_permanent"

    get_all_ip
    log_message "HTTP服务已启动,服务器IP地址列表：${this_host_ip_list[@]}" "WARNING"
    for IP in "${this_host_ip_list[@]}"; do
        echo "访问地址：http://$IP"
    done

    return 0
}

#################################################################################################
# 停止HTTP服务使用说明
#################################################################################################
stop_my_httpd_usage(){
    echo -ne "${GREEN}
    --stop-my-httpd  ${NC}停止httpd服务${GREEN}"
    echo
}

#################################################################################################
# 停止HTTP服务
#################################################################################################
stop_my_httpd(){
    show_who_call
    log_message "停止httpd服务..." "WARNING"
    sudo_execute "systemctl stop httpd"
    sudo_execute "systemctl disable httpd"
    
    log_message "关闭防火墙对http服务的规则." "WARNING"
    sudo_execute "firewall-cmd --remove-service=http $this_permanent"
    
    log_message "httpd服务已停止." "WARNING"
    return 0
}

#################################################################################################
# Python安装(HTTP服务的简单替代)
#################################################################################################
py_install(){
    show_who_call
    check_packages_installed "python3"
    if [ -n "$this_not_installed_packages" ];then
        install_package "$this_not_installed_packages"
    fi
    return 0
}
