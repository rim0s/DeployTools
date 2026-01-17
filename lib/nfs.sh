#!/bin/bash
#################################################################################################
# NFS共享管理模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/sudo.sh" 2>/dev/null || source "./lib/sudo.sh"
source "$(dirname "$0")/package_advanced.sh" 2>/dev/null || source "./lib/package_advanced.sh"
source "$(dirname "$0")/system.sh" 2>/dev/null || source "./lib/system.sh"
source "$(dirname "$0")/firewall.sh" 2>/dev/null || source "./lib/firewall.sh"
source "$(dirname "$0")/network.sh" 2>/dev/null || source "./lib/network.sh"
source "$(dirname "$0")/path.sh" 2>/dev/null || source "./lib/path.sh"

#################################################################################################
# 清空NFS exports文件
#################################################################################################
empty_nfs_exports(){
    show_who_call
    sudo_execute "sh -c 'echo  > /etc/exports' "
    local ret_sudo_tp=$?
    if [ $ret_sudo_tp -eq 1 ];then
        log_message "清空 NFS 服务配置文件失败." "ERROR"
    fi
    return 0
}

#################################################################################################
# NFS共享使用说明
#################################################################################################
nfs_share_usage(){
    echo -ne "${GREEN}
    --nfs-share ${BLUE}target_dir     ${NC}设置${BLUE}target_dir${NC}目录为nfs共享${GREEN}"
    echo
}

#################################################################################################
# 将目录设为nfs共享
#   o 启用 NFS 服务(如果没有启用),此处通过默认包管理器下载安装,需要网络.
#   o 将目录设为局域网可读写(如果文件目录存在)
#   o 打开 NFS 服务所需的防火墙端口
#################################################################################################
set_dir_2_nfs(){
    # 检查需要的软件包是否已经安装
    case $app_manager in 
        apt)
            check_packages_installed "nfs-kernel-server"
            ;;
        dnf)
            check_packages_installed "nfs-utils rpcbind"
            ;;
        *)
            log_message "其他包管理器: [ $app_manager ] 对应的包安装逻辑暂未编写."
            return 1
            ;;
    esac
    
    # 没有安装软件包则进行安装
    if [ -n "$this_not_installed_packages" ];then
        install_package "$this_not_installed_packages"
    fi

    # 参数是否为空,空则提示需要一个参数.
    if [ -z "$1" ]; then
        log_message "请提供一个目录作为NFS共享" "ERROR"
        return 1
    fi

    # 启动nfs的服务
    case $app_manager in 
        apt)
            sudo_execute "systemctl start nfs-kernel-server"
            ;;
        dnf)
            sudo_execute "systemctl start nfs-server"
            ;;
        *)
            log_message "其他包管理器: [ $app_manager ] 对应的包安装逻辑暂未编写."
            return 1
            ;;
    esac

    # 设置给定目录为NFS共享
    local ltmp_SHARED_DIR=$1
    local ltmp_EXPORTS_FILE="/etc/exports"
    local ltmp_NFS_CONFIG_BASE="$ltmp_SHARED_DIR *(rw,sync,no_subtree_check)"
 
    # 确保目录存在
    if [ ! -d "$ltmp_SHARED_DIR" ]; then
        log_message "目录 $ltmp_SHARED_DIR 不存在，创建中..." "WARNING"
        sudo_execute "mkdir -p $ltmp_SHARED_DIR "
    fi

    # 设置目录权限为可读写，并允许所有用户访问
    log_message "配置目录 $ltmp_SHARED_DIR 为NFS共享..." "WARNING"
    sudo_execute "chmod 777 $ltmp_SHARED_DIR"
    sudo_execute "chown root:root $ltmp_SHARED_DIR"

    # 备份exports文件
    local ltmp_IDENTIFIER=$(backup_and_log "/etc/exports")

    if [ -z "$ltmp_IDENTIFIER" ] || [ "$ltmp_IDENTIFIER" == "1" ]; then
        log_message "/etc/exports 文件备份失败." "ERROR"
        return 1
    else
        log_message "/etc/exports 文件备份成功,唯一标识为 [ $ltmp_IDENTIFIER ] " "WARNING"
    fi

    # 检查exports文件中是否已经存在该目录的配置
    if grep -Fq "$ltmp_NFS_CONFIG_BASE" "$ltmp_EXPORTS_FILE"; then
        log_message "目录 $ltmp_SHARED_DIR 的配置已存在,不再重复添加" "ERROR"
    else
        # 添加目录到exports文件
        local ltmp_NFS_CONFIG="$ltmp_NFS_CONFIG_BASE # $ltmp_IDENTIFIER"
        log_message "将目录 $ltmp_SHARED_DIR 添加到exports文件..." "WARNING"
        echo "$ltmp_NFS_CONFIG" | sudo_execute "tee -a $ltmp_EXPORTS_FILE" > /dev/null
    fi

    # 重新导出目录
    sudo_execute "exportfs -a"

    # 打印目前已共享的所有目录和对应的权限
    log_message "目前已共享的所有目录和对应的权限:" "INFO"
    unsudo_execute "cat $ltmp_EXPORTS_FILE"

    # 开启防火墙端口
    log_message "即将开启防火墙策略以允许客户端访问 NFS 服务." "WARNING"
    sudo_execute "firewall-cmd --add-service=rpc-bind $this_permanent"
    sudo_execute "firewall-cmd --add-service=mountd $this_permanent"
    sudo_execute "firewall-cmd --add-service=nfs $this_permanent"

    # 获取IP地址列表
    get_all_ip
    
    # 检查是否成功获取到IP地址
    if [ ${#this_host_ip_list[@]} -eq 0 ]; then
        log_message "错误：无法确定NFS服务器的IP地址。" "ERROR"
        return 1
    fi

    # 输出成功信息
    log_message "NFS设置成功，服务器IP地址列表：${this_host_ip_list[@]}" "WARNING"

    for IP in "${this_host_ip_list[@]}"; do
        local ltmp_CLIENT_MOUNT_CMD="sudo mount -t nfs $IP:$ltmp_SHARED_DIR  /mnt/NFS_mount_point_of_$IP"
        echo "客户端挂载命令（IP: $IP）：$ltmp_CLIENT_MOUNT_CMD"
    done

    log_message "NFS服务配置完成,并成功共享目录 $ltmp_SHARED_DIR" "WARNING"
    return 0
}

#################################################################################################
# 移除NFS配置
#################################################################################################
remove_nfs_config() {
    local REMOVE_PARAM=$1
    local FOUND=0
    local MATCH_LINE=""

    # 如果参数是以特定前缀开始的（假设是备份文件的标识符），则认为是标识符删除
    if [[ "$REMOVE_PARAM" == *"_"* ]]; then
        IDENTIFIER_TO_REMOVE=$(echo "$REMOVE_PARAM" | cut -d'_' -f2)
        while IFS= read -r LINE; do
            if [[ "$LINE" == *"# $IDENTIFIER_TO_REMOVE"* ]]; then
                MATCH_LINE="$LINE"
                sudo sed -i "/$MATCH_LINE/d" "$EXPORTS_FILE"
                FOUND=1
                break
            fi
        done < "$EXPORTS_FILE"
    else
        # 否则认为是目录名删除
        while IFS= read -r LINE; do
            if [[ "$LINE" == *"$REMOVE_PARAM"* ]]; then
                MATCH_LINE="$LINE"
                sudo sed -i "/$MATCH_LINE/d" "$EXPORTS_FILE"
                FOUND=1
            fi
        done < "$EXPORTS_FILE"
    fi
}

#################################################################################################
# 挂载 NFS 共享目录
#################################################################################################
mount_nfs() {
    local nfs_server="$1"
    local mount_point="$2"
    local all_option="$3"

    # 检查是否提供了必要的参数
    if [ -z "$nfs_server" ] || [ -z "$mount_point" ]; then
        echo "请提供 NFS 服务器的主机名或 IP 以及挂载目录。"
        return 1
    fi

    # 检查挂载点是否存在，如果不存在则创建
    if [ ! -d "$mount_point" ]; then
        create_directory "$mount_point" --force
    fi

    # 获取 NFS 服务器上的共享目录列表
    local shares=$(showmount -e "$nfs_server" | awk '{if (NR!=1) print $1}')

    if [ $? -ne 0 ]; then
        log_message "无法获取 NFS 服务器 $nfs_server 上的共享目录列表：$shares" "ERROR"
        return 1
    fi

    if [ -z "$shares" ]; then
        echo "NFS 服务器 $nfs_server 上没有共享目录。"
        return 1
    fi

    # 如果指定了 --all 参数，则挂载所有共享目录
    if [ "$all_option" == "--all" ]; then
        for share in $shares; do
            local share_name=$(basename "$share")
            local mount_dir="$mount_point/$share_name"
            create_directory "$mount_dir" --force
            sudo_execute "mount -t nfs $nfs_server:$share  $mount_dir "
            if [ $? -ne 0 ]; then
                echo "无法挂载 $nfs_server:$share 到 $mount_dir"
                return 1
            fi
            echo "已挂载 $nfs_server:$share 到 $mount_dir"
        done
    else
        # 列出共享目录并提示用户选择
        echo "请选择要挂载的 NFS 共享目录："
        local i=1
        for share in $shares; do
            echo "$i. $share"
            i=$((i+1))
        done

        read -p "请输入编号: " choice

        if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -ge "$i" ]; then
            echo "无效的选择。"
            return 1
        fi

        local selected_share=$(echo "$shares" | sed -n "${choice}p")
        local share_name=$(basename "$selected_share")
        local mount_dir="$mount_point/$share_name"
        create_directory  "$mount_dir"  --force
        sudo_execute "mount -t nfs $nfs_server:$selected_share  $mount_dir "
        if [ $? -ne 0 ]; then
            echo "无法挂载 $nfs_server:$selected_share 到 $mount_dir"
            return 1
        fi
        echo "已挂载 $nfs_server:$selected_share 到 $mount_dir"
    fi
}

#################################################################################################
# 使用Zenity图形界面挂载NFS
#################################################################################################
mount_nfs_with_zenity() {
    local nfs_server="$1"
    local mount_point="$2"
    local all_option="$3"

    if [ -z "$nfs_server" ] || [ -z "$mount_point" ]; then
        echo "请提供 NFS 服务器的主机名或 IP 以及挂载目录。"
        return 1
    fi

    if [ ! -d "$mount_point" ]; then
        create_directory_gui "$mount_point" --force
    fi

    local shares=$(showmount -e "$nfs_server" | awk '{if (NR!=1) print $1}')

    if [ $? -ne 0 ]; then
        log_message "无法获取 NFS 服务器 $nfs_server 上的共享目录列表" "ERROR"
        return 1
    fi

    if [ -z "$shares" ]; then
        echo "NFS 服务器 $nfs_server 上没有共享目录。"
        return 1
    fi

    if [ "$all_option" == "--all" ]; then
        for share in $shares; do
            local share_name=$(basename "$share")
            local mount_dir="$mount_point/$share_name"
            create_directory_gui "$mount_dir" --force
            sudo_execute_gui "mount -t nfs $nfs_server:$share  $mount_dir "
            if [ $? -ne 0 ]; then
                echo "无法挂载 $nfs_server:$share 到 $mount_dir"
                return 1
            fi
            echo "已挂载 $nfs_server:$share 到 $mount_dir"
        done
    else
        local ltmp_nfs_dir_choice=$(zenity --list --title="选择要挂载的 NFS 共享目录" --column="共享目录" $shares )
        if [ -z "$ltmp_nfs_dir_choice" ]; then
            zenity --error --text="未选择任何共享目录。"
            return 1
        fi
        zenity --info --text="您选择了 $ltmp_nfs_dir_choice "
        
        local share_name_sg=$(basename "$ltmp_nfs_dir_choice")
        local mount_dir="$mount_point/$share_name_sg"
        create_directory_gui  "$mount_dir"  --force
        sudo_execute_gui "mount -t nfs $nfs_server:$ltmp_nfs_dir_choice  $mount_dir "
        zenity --info --text="返回值为 $? "
        if [ $? -ne 0 ]; then
            echo "无法挂载 $nfs_server:$ltmp_nfs_dir_choice 到 $mount_dir"
            return 1
        fi
        echo "已挂载 $nfs_server:$ltmp_nfs_dir_choice 到 $mount_dir"
    fi
}
