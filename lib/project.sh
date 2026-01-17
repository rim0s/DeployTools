#!/bin/bash
#################################################################################################
# 项目特定代码模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/utils.sh" 2>/dev/null || source "./lib/utils.sh"
source "$(dirname "$0")/system.sh" 2>/dev/null || source "./lib/system.sh"
source "$(dirname "$0")/init.sh" 2>/dev/null || source "./lib/init.sh"

#################################################################################################
# 项目 PJ_1234
#################################################################################################
PJ_1234() {
    echo "=========================================================================="
    echo "Executing project PJ_1234..."
    echo "=========================================================================="
    local ltmp_long_long_str_par_array=(
        "A B C"
        "D E F" 
        "H I J"
    )

    local ltmp_long_long_str_par=""
    for line in "${ltmp_long_long_str_par_array[@]}"; do
        ltmp_long_long_str_par+="$line "
    done

    # 去除最后一个多余的空格
    ltmp_long_long_str_par=${ltmp_long_long_str_par% }

    # 最终的值
    echo "$ltmp_long_long_str_par"
    echo "=========================================================================="
    
    # 在这里实现具体的项目功能
    echo_sharp_line
    echo_double_line
    echo_mid_line
    echo_low_line

    # 判断桌面环境并调用对应的图形交互程序
    local ltmp_desktop_env=$(get_desktop_environment)
    if [ -n "$SSH_TTY" ]; then
        echo "当前是通过SSH登录的远程shell，不使用zenity进行图形交互。"
    else
        echo "当前不是通过SSH登录的远程shell，进行图形交互调用测试..."
        if [ "$ltmp_desktop_env" == "gnome" ]; then
            echo "GNOME桌面环境"
            zenity --info --text="当前是${ltmp_desktop_env} 桌面环境.\n可用 zenity 与图形交互."
        elif [ "$ltmp_desktop_env" == "kde" ]; then
            echo "KDE桌面环境"
            KDialog --title "KDE桌面环境" --msgbox "当前是${ltmp_desktop_env} 桌面环境.\n可用 KDialog 与图形交互."
        elif [ "$ltmp_desktop_env" == "xfce" ]; then
            echo "XFCE桌面环境"
            xfce4-terminal --title "XFCE桌面环境" --command "echo '当前是${ltmp_desktop_env} 桌面环境.\n可用 xfce4-terminal 与图形交互.'"
        else
            echo "未知桌面环境"
        fi
    fi

    end_the_batch
    echo "=========================================================================="
}

#################################################################################################
# 项目 PJ_5678
#################################################################################################
PJ_5678() {
    echo "Executing project PJ_5678..."
    # 在这里实现具体的项目功能
}

#################################################################################################
# 项目 PJ_20241128
#################################################################################################
PJ_20241128()
{
    project_set_user_never_expiration
}

#################################################################################################
# 项目 PJ_set_new_fedora_workstation
#################################################################################################
PJ_set_new_fedora_workstation()
{
    project_set_record_his_with_datetime

    # 用以打开老式服务器 BMC 内置的 JVM 生成的 Jnlp文件.
    sudo dnf -y install icedtea-web
    sudo dnf -y install openjdk
    sudo dnf -y install java

    # 开发包组
    sudo dnf -y groupinstall develop-tools

    # 其他常用的和需要的包
    local ltmp_pakage_list_of_fedora="aircrack aisleriot amule anjuta ardour ark at audacity autodesk-dwgtrueview aview basemarkgpu bavarder biglybt brasero builder bz bz2 bzip bzip2-devel cambalache cavestory ccat chromium clonezilla clutter-devel clutter-doc cluttermm-devel cmake cmospwd cobbler cockpit codeblock codeblocks collision cowpatty cpeditor Cutter czkawka dbeaver detwinner development-libs development-tools devhelp dialog dnf drawio dwg-viewer edb etherape ettercap exploitdb fgdump figlet filezila filezilla firmware flatseal freecad g++ g3l g4l gcc gcc-c++ gdb gdm gdmsetting gdmsettings geany gear ghex gimp gimp-data-extras gimp-dds-plugin gimp-devel gimp-devel-tools gimp-elsamuko gimpfx-foundry gimp-help gimp-help-zh_CN gimp-high-pass-filter gimp-layer-via-copy-cut gimp-libs gimp-luminosity-masks gimp-paint-studio gimp-resynthesizer gimp-save-for-web gimp-separate+ gimp-wavelet-decompose git gitg glade glade3 glibc glibc-devel gmp-devel gnome-software-development gnome-tweaks gobject-introspection-devel godot google-chrome gparted gpuviewer group groupinstall gstreamer1-plugins gstreamer-devel gstreamer-devel-docs gstreamermm-doc gtk3-devel gtk3-devel-docs gtkmm gtkmm30-devel gtkmm30-doc gtkmm4.0-devel hashcat heaptrack helvum httpd hydra hydra-gtk imhex Inkscape insomnia inspector install jad jadx java java-21-openjdk-devel jdk john jp2a kernel-devel kernel-headers l0phtcrack libappindicator libappindicator-gtk3-12.10.1-4.fc40.i686 libappindicator-gtk3-12.10.1-4.fc40.x86_64 libavcodec libcl libde265 liberation-fonts libfreeaptx libgda-devel libgdamm-devel libgl libgtkmm libpcap-devel libQt5Help librecad libredwg librtmp libvncserver libwacom libxml libxml2 libxml3 libXScrnSaver lightzone live-build lm_sensors lsblk make mandelbulber man-pages-zh man-pages-zh-CN Manuals medusa Multimedia muon natron ncat nessus netbeans newelle nfs-utils ngrep nikto nmap nping nvdtools obs-studio ocrfeeder octave opencv openjdk openmpi openssl openssl-devel opera ophcrack ophrack partclone perl photoflare pk-gtk-module prometheus-jmx-exporter-openjdk8 putty pwgen python python3 qgis quadrapassel reaper redhat-lsb rpcbind samba shim sigil Simple-Fuzzer simulide skipfish snowflake speedtest sqlmap sqlninja ssh_mitm streamermm-devel sublime-text sudo tabby thunderbird tmux uefitool ueiftool vlc vncpwd w3af warp weasis webkitgtk3-devel wfuzz wireshark workbench xhydra xmllint xmlstarlet xsltproc yasm zenmap dhcp-server"
    dnf_install_packages  $ltmp_pakage_list_of_fedora
}

#################################################################################################
# 测试用函数
#################################################################################################
test_batch(){
    # 记录信息级别日志到日志文件
    log_MESSAGE "脚本开始执行1" "INFO"
    LOG_message "脚本开始执行1" "INFO"
    log_message "日志记录内容2" "INFO"
    log_message "日志记录内容3" "WARNING"
    log_message "日志记录内容4" "ERROR"
    log_message "日志记录内容5" "DEBUG"
    log_message "日志记录内容6" "TRACE"
}
