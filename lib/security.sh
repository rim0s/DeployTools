#!/bin/bash
#################################################################################################
# 系统安全配置管理模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/sudo.sh" 2>/dev/null || source "./lib/sudo.sh"
source "$(dirname "$0")/package_advanced.sh" 2>/dev/null || source "./lib/package_advanced.sh"
source "$(dirname "$0")/system.sh" 2>/dev/null || source "./lib/system.sh"
source "$(dirname "$0")/firewall.sh" 2>/dev/null || source "./lib/firewall.sh"

#################################################################################################
# 修改SSH端口
#################################################################################################
change_sshd_port(){
    show_who_call
    local ltmp_new_port=$1
    
    if [ -z "$ltmp_new_port" ];then
        log_message "请提供新的SSH端口号" "ERROR"
        return 1
    fi

    log_message "准备修改SSH端口为: [ $ltmp_new_port ]" "WARNING"
    
    local ltmp_sshd_config="/etc/ssh/sshd_config"
    local ltmp_backup_identifier=$(backup_and_log "$ltmp_sshd_config")
    
    if [ -z "$ltmp_backup_identifier" ] || [ "$ltmp_backup_identifier" == "1" ]; then
        log_message "$ltmp_sshd_config 文件备份失败." "ERROR"
        return 1
    else
        log_message "$ltmp_sshd_config 文件备份成功,唯一标识为 [ $ltmp_backup_identifier ] " "WARNING"
    fi

    # 修改sshd_config文件
    local ltmp_old_port=$(grep "^Port" "$ltmp_sshd_config" | awk '{print $2}')
    if [ -z "$ltmp_old_port" ];then
        ltmp_old_port="22"
    fi
    
    log_message "原SSH端口为: [ $ltmp_old_port ]" "WARNING"
    
    sudo_execute "sed -i 's/^#Port 22/Port $ltmp_new_port/g' $ltmp_sshd_config"
    sudo_execute "sed -i 's/^Port.*/Port $ltmp_new_port/g' $ltmp_sshd_config"

    # SELinux设置
    log_message "配置SELinux允许新端口..." "WARNING"
    sudo_execute "semanage port -a -t ssh_port_t -p tcp $ltmp_new_port" || log_message "SELinux端口添加失败,可能已存在" "WARNING"

    # 防火墙设置
    log_message "开启防火墙对${ltmp_new_port}端口的规则." "WARNING"
    sudo_execute "firewall-cmd --add-port=${ltmp_new_port}/tcp $this_permanent"
    
    # 重启sshd服务
    log_message "重启sshd服务..." "WARNING"
    sudo_execute "systemctl restart sshd"
    
    log_message "SSH端口已修改为: [ $ltmp_new_port ]" "WARNING"
    log_message "请使用新端口进行连接: ssh -p $ltmp_new_port user@host" "WARNING"
    
    return 0
}

#################################################################################################
# 随机锁定用户
#################################################################################################
lock_user_randomly(){
    show_who_call
    local ltmp_user=$1
    
    if [ -z "$ltmp_user" ];then
        log_message "请提供要锁定的用户名" "ERROR"
        return 1
    fi

    log_message "准备锁定用户: [ $ltmp_user ]" "WARNING"
    
    # 随机选择锁定方式
    local ltmp_lock_method=$((RANDOM % 3))
    
    case $ltmp_lock_method in
        0)
            log_message "使用方法1: usermod -L 锁定用户" "WARNING"
            sudo_execute "usermod -L $ltmp_user"
            ;;
        1)
            log_message "使用方法2: 修改shell为/sbin/nologin" "WARNING"
            sudo_execute "usermod -s /sbin/nologin $ltmp_user"
            ;;
        2)
            log_message "使用方法3: 修改shell为/bin/false" "WARNING"
            sudo_execute "usermod -s /bin/false $ltmp_user"
            ;;
    esac
    
    log_message "用户 [ $ltmp_user ] 已被锁定" "WARNING"
    return 0
}

#################################################################################################
# 解锁用户
#################################################################################################
unlock_user(){
    show_who_call
    local ltmp_user=$1
    
    if [ -z "$ltmp_user" ];then
        log_message "请提供要解锁的用户名" "ERROR"
        return 1
    fi

    log_message "准备解锁用户: [ $ltmp_user ]" "WARNING"
    
    # 检查用户当前状态
    local ltmp_current_shell=$(grep "^$ltmp_user:" /etc/passwd | cut -d: -f7)
    log_message "用户当前shell: [ $ltmp_current_shell ]" "WARNING"
    
    # 解锁密码
    sudo_execute "usermod -U $ltmp_user"
    
    # 如果shell是nologin或false,恢复为bash
    if [ "$ltmp_current_shell" == "/sbin/nologin" ] || [ "$ltmp_current_shell" == "/bin/false" ];then
        log_message "恢复用户shell为/bin/bash" "WARNING"
        sudo_execute "usermod -s /bin/bash $ltmp_user"
    fi
    
    log_message "用户 [ $ltmp_user ] 已被解锁" "WARNING"
    return 0
}

#################################################################################################
# 设置用户永不过期
#################################################################################################
project_set_user_never_expiration(){
    show_who_call
    local ltmp_user=$1
    
    if [ -z "$ltmp_user" ];then
        log_message "请提供用户名" "ERROR"
        return 1
    fi

    log_message "设置用户 [ $ltmp_user ] 永不过期..." "WARNING"
    sudo_execute "chage -M 99999 $ltmp_user"
    sudo_execute "chage -E -1 $ltmp_user"
    
    log_message "用户 [ $ltmp_user ] 已设置为永不过期" "WARNING"
    return 0
}

#################################################################################################
# 设置历史命令记录时间戳
#################################################################################################
project_set_record_his_with_datetime(){
    show_who_call
    
    local ltmp_bashrc="/etc/bashrc"
    local ltmp_backup_identifier=$(backup_and_log "$ltmp_bashrc")
    
    if [ -z "$ltmp_backup_identifier" ] || [ "$ltmp_backup_identifier" == "1" ]; then
        log_message "$ltmp_bashrc 文件备份失败." "ERROR"
        return 1
    else
        log_message "$ltmp_bashrc 文件备份成功,唯一标识为 [ $ltmp_backup_identifier ] " "WARNING"
    fi

    local ltmp_histtimeformat='export HISTTIMEFORMAT="%F %T "'
    
    if grep -q "HISTTIMEFORMAT" "$ltmp_bashrc"; then
        log_message "HISTTIMEFORMAT已配置,跳过" "WARNING"
    else
        echo "$ltmp_histtimeformat" | sudo_execute "tee -a $ltmp_bashrc"
        log_message "已添加历史命令时间戳记录" "WARNING"
    fi
    
    return 0
}

#################################################################################################
# 添加NTP时间服务器
#################################################################################################
add_ntp_server(){
    show_who_call
    local ltmp_ntp_server=$1
    
    if [ -z "$ltmp_ntp_server" ];then
        log_message "请提供NTP服务器地址" "ERROR"
        return 1
    fi

    check_packages_installed "chrony"
    if [ -n "$this_not_installed_packages" ];then
        install_package "$this_not_installed_packages"
    fi

    local ltmp_chrony_conf="/etc/chrony.conf"
    local ltmp_backup_identifier=$(backup_and_log "$ltmp_chrony_conf")
    
    if [ -z "$ltmp_backup_identifier" ] || [ "$ltmp_backup_identifier" == "1" ]; then
        log_message "$ltmp_chrony_conf 文件备份失败." "ERROR"
        return 1
    else
        log_message "$ltmp_chrony_conf 文件备份成功,唯一标识为 [ $ltmp_backup_identifier ] " "WARNING"
    fi

    if grep -q "^server $ltmp_ntp_server" "$ltmp_chrony_conf"; then
        log_message "NTP服务器 [ $ltmp_ntp_server ] 已配置" "WARNING"
    else
        echo "server $ltmp_ntp_server iburst" | sudo_execute "tee -a $ltmp_chrony_conf"
        log_message "已添加NTP服务器: [ $ltmp_ntp_server ]" "WARNING"
    fi

    sudo_execute "systemctl restart chronyd"
    sudo_execute "systemctl enable chronyd"
    
    log_message "NTP服务已配置并启动" "WARNING"
    return 0
}
