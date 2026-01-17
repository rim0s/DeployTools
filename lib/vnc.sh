#!/bin/bash
#################################################################################################
# VNC远程桌面管理模块
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
# X11VNC服务器使用说明
#################################################################################################
setup_x11vnc_server_usage(){
    echo -ne "${GREEN}
    --setup-x11vnc-server ${NC}配置x11vnc远程桌面访问服务${GREEN}"
    echo
}

#################################################################################################
# 设置X11VNC服务器(旧版本)
#################################################################################################
setup_x11vnc_server(){
    show_who_call
    local ltmp_is_kylin_V10SP3_x86="$(is_kylin_V10SP3_x86 "Boolean")"
    log_message "判断函数is_kylin_V10SP3_x86 返回值为: [ $ltmp_is_kylin_V10SP3_x86 ]" "WARNING"

    local ltmp_is_UnionTech_e="$(is_UnionTech_e "Boolean")"
    log_message "判断函数is_UnionTech_e返回值为: [ $ltmp_is_UnionTech_e ]" "WARNING"

    local ltmp_is_neokylin_8=""
    ltmp_is_neokylin_8="$(is_neokylin_8 "Boolean")"
    log_message "是否为中标麒麟高级服务器操作系统软件8: [ $ltmp_is_neokylin_8 ]" "WARNING"

    if [ $ltmp_is_kylin_V10SP3_x86 == "True" ] || [ $ltmp_is_neokylin_8 == "True" ];then
        log_message "当前系统为:银河麒麟/中标麒麟,准备使用 RPM 包方式进行 x11vnc 安装." "WARNING"
        local ltmp_is_x11vnc_installed="$(rpm -qa | grep -i x11vnc)"
        if [ -z "$ltmp_is_x11vnc_installed" ];then
            log_message "x11vnc软件未安装,开始安装..." "WARNING"
            sudo_execute "rpm -Uvh ./static_resources/rpms/kylin/x11vnc-0.9.16-5.ky10.x86_64.rpm"
        else
            log_message "x11vnc软件已安装,跳过安装步骤." "WARNING"
        fi
        
        log_message "下面开始创建 x11vnc 服务的用户态配置文件..." "WARNING"
        local ltmp_x11vnc_service_content="[Unit]
Description=x11vnc (Remote access)
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -display :0 -auth /var/run/lightdm/root/:0 -forever -bg -o /var/log/x11vnc.log -rfbport 5900
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target"
        
        echo "$ltmp_x11vnc_service_content" | sudo_execute "tee /usr/lib/systemd/system/x11vnc.service"
        sudo_execute "systemctl daemon-reload"
        sudo_execute "systemctl enable x11vnc.service"
        sudo_execute "systemctl restart x11vnc.service"
        
        log_message "开启防火墙对5900端口的规则." "WARNING"
        sudo_execute "firewall-cmd --add-port=5900/tcp $this_permanent"

    elif [ $ltmp_is_UnionTech_e == "True" ];then
        log_message "当前系统为:统信服务器E版,准备使用 DEB 包方式进行 x11vnc 安装." "WARNING"
        sudo_execute "apt install -y ./static_resources/debs/uos_e/x11vnc_*.deb"
        
        log_message "下面开始创建 x11vnc 服务的用户态配置文件..." "WARNING"
        local ltmp_x11vnc_service_content_uos_e="[Unit]
Description=x11vnc (Remote access)
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -display :0 -auth /var/run/lightdm/root/:0 -forever -bg -o /var/log/x11vnc.log -rfbport 5900
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target"
        
        echo "$ltmp_x11vnc_service_content_uos_e" | sudo_execute "tee /usr/lib/systemd/system/x11vnc.service"
        sudo_execute "systemctl daemon-reload"
        sudo_execute "systemctl enable x11vnc.service"
        sudo_execute "systemctl restart x11vnc.service"
        
        log_message "开启防火墙对5900端口的规则." "WARNING"
        sudo_execute "firewall-cmd --add-port=5900/tcp $this_permanent"
        
    else
        log_message "其他系统的x11vnc自动化配置逻辑暂未编写." "ERROR"
    fi

    return 0
}

#################################################################################################
# 设置X11VNC服务器(新版本)
#################################################################################################
setup_x11vnc_server_new(){
    show_who_call
    local ltmp_is_kylin_V10SP3_x86="$(is_kylin_V10SP3_x86 "Boolean")"
    log_message "判断函数is_kylin_V10SP3_x86 返回值为: [ $ltmp_is_kylin_V10SP3_x86 ]" "WARNING"

    local ltmp_is_UnionTech_e="$(is_UnionTech_e "Boolean")"
    log_message "判断函数is_UnionTech_e返回值为: [ $ltmp_is_UnionTech_e ]" "WARNING"

    local ltmp_is_neokylin_8=""
    ltmp_is_neokylin_8="$(is_neokylin_8 "Boolean")"
    log_message "是否为中标麒麟高级服务器操作系统软件8: [ $ltmp_is_neokylin_8 ]" "WARNING"

    local ltmp_is_fedora="$(is_fedora "Boolean")"
    log_message "是否为Fedora系统: [ $ltmp_is_fedora ]" "WARNING"

    if [ "$ltmp_is_kylin_V10SP3_x86" == "True" ] || [ "$ltmp_is_neokylin_8" == "True" ];then
        log_message "当前系统为:银河麒麟/中标麒麟,准备使用 RPM 包方式进行 x11vnc 安装." "WARNING"
        local ltmp_is_x11vnc_installed="$(rpm -qa | grep -i x11vnc)"
        if [ -z "$ltmp_is_x11vnc_installed" ];then
            log_message "x11vnc软件未安装,开始安装..." "WARNING"
            sudo_execute "rpm -Uvh ./static_resources/rpms/kylin/x11vnc-0.9.16-5.ky10.x86_64.rpm"
        else
            log_message "x11vnc软件已安装,跳过安装步骤." "WARNING"
        fi
        
        read -p "请输入远程登录的端口号[ 建议使用59XY形式,XY为01-99之间 ] : " ltmp_set_port
        read -p "请输入远程登录的密码: " ltmp_set_password

        if [ -z "$ltmp_set_port" ] || [ -z "$ltmp_set_password" ];then
            log_message "错误: 端口号或密码不能为空,脚本退出." "ERROR"
            return 1
        fi
        
        local ltmp_password_file="/root/.vnc_passwd"
        sudo_execute "x11vnc -storepasswd $ltmp_set_password $ltmp_password_file"

        log_message "下面开始创建 x11vnc 服务的用户态配置文件..." "WARNING"
        local ltmp_x11vnc_service_content="[Unit]
Description=x11vnc (Remote access)
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -display :0 -auth /var/run/lightdm/root/:0 -forever -bg -o /var/log/x11vnc.log -rfbport $ltmp_set_port -rfbauth $ltmp_password_file
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target"
        
        echo "$ltmp_x11vnc_service_content" | sudo_execute "tee /usr/lib/systemd/system/x11vnc.service"
        sudo_execute "systemctl daemon-reload"
        sudo_execute "systemctl enable x11vnc.service"
        sudo_execute "systemctl restart x11vnc.service"
        
        log_message "开启防火墙对${ltmp_set_port}端口的规则." "WARNING"
        sudo_execute "firewall-cmd --add-port=${ltmp_set_port}/tcp $this_permanent"

    elif [ "$ltmp_is_UnionTech_e" == "True" ];then
        log_message "当前系统为:统信服务器E版,准备使用 DEB 包方式进行 x11vnc 安装." "WARNING"
        sudo_execute "apt install -y ./static_resources/debs/uos_e/x11vnc_*.deb"
        
        read -p "请输入远程登录的端口号[ 建议使用59XY形式,XY为01-99之间 ] : " ltmp_set_port
        read -p "请输入远程登录的密码: " ltmp_set_password

        if [ -z "$ltmp_set_port" ] || [ -z "$ltmp_set_password" ];then
            log_message "错误: 端口号或密码不能为空,脚本退出." "ERROR"
            return 1
        fi
        
        local ltmp_password_file="/root/.vnc_passwd"
        sudo_execute "x11vnc -storepasswd $ltmp_set_password $ltmp_password_file"

        log_message "下面开始创建 x11vnc 服务的用户态配置文件..." "WARNING"
        local ltmp_x11vnc_service_content_uos_e="[Unit]
Description=x11vnc (Remote access)
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -display :0 -auth /var/run/lightdm/root/:0 -forever -bg -o /var/log/x11vnc.log -rfbport $ltmp_set_port -rfbauth $ltmp_password_file
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target"
        
        echo "$ltmp_x11vnc_service_content_uos_e" | sudo_execute "tee /usr/lib/systemd/system/x11vnc.service"
        sudo_execute "systemctl daemon-reload"
        sudo_execute "systemctl enable x11vnc.service"
        sudo_execute "systemctl restart x11vnc.service"
        
        log_message "开启防火墙对${ltmp_set_port}端口的规则." "WARNING"
        sudo_execute "firewall-cmd --add-port=${ltmp_set_port}/tcp $this_permanent"
        
    elif [ "$ltmp_is_fedora" == "True" ];then
        log_message "当前系统为:Fedora,准备使用 dnf 方式进行 x11vnc 安装." "WARNING"
        check_packages_installed "x11vnc"
        if [ -n "$this_not_installed_packages" ];then
            install_package "$this_not_installed_packages"
        fi
        
        read -p "请输入远程登录的端口号[ 建议使用59XY形式,XY为01-99之间 ] : " ltmp_set_port
        read -p "请输入远程登录的密码: " ltmp_set_password

        if [ -z "$ltmp_set_port" ] || [ -z "$ltmp_set_password" ];then
            log_message "错误: 端口号或密码不能为空,脚本退出." "ERROR"
            return 1
        fi
        
        local ltmp_password_file="/root/.vnc_passwd"
        sudo_execute "x11vnc -storepasswd $ltmp_set_password $ltmp_password_file"

        log_message "下面开始创建 x11vnc 服务的用户态配置文件..." "WARNING"
        log_message "Fedora系统暂时使用gdm的auth文件路径,如有问题请手动修改." "WARNING"
        
        local ltmp_x11vnc_service_content_fedora="[Unit]
Description=x11vnc (Remote access)
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -display :0 -auth /run/user/$(id -u gdm)/gdm/Xauthority -forever -bg -o /var/log/x11vnc.log -rfbport $ltmp_set_port -rfbauth $ltmp_password_file
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target"
        
        echo "$ltmp_x11vnc_service_content_fedora" | sudo_execute "tee /usr/lib/systemd/system/x11vnc.service"
        sudo_execute "systemctl daemon-reload"
        sudo_execute "systemctl enable x11vnc.service"
        sudo_execute "systemctl restart x11vnc.service"
        
        log_message "开启防火墙对${ltmp_set_port}端口的规则." "WARNING"
        sudo_execute "firewall-cmd --add-port=${ltmp_set_port}/tcp $this_permanent"
        
    else
        log_message "其他系统的x11vnc自动化配置逻辑暂未编写." "ERROR"
    fi

    return 0
}
