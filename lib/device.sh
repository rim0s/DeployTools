#!/bin/bash
#################################################################################################
# 设备挂载管理模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/sudo.sh" 2>/dev/null || source "./lib/sudo.sh"
source "$(dirname "$0")/system.sh" 2>/dev/null || source "./lib/system.sh"
source "$(dirname "$0")/path.sh" 2>/dev/null || source "./lib/path.sh"

#################################################################################################
# 挂载新设备使用说明
#################################################################################################
mount_new_device_usage(){
    echo -ne "${GREEN}
    --mount-new-device ${NC}挂载新设备到系统${GREEN}"
    echo
}

#################################################################################################
# 等待输入以退出
#################################################################################################
wait_for_input_2_exit(){
    echo
    echo "----------------------------------------"
    echo "按 Enter 键退出..."
    read -r
}

#################################################################################################
# 挂载新设备
#################################################################################################
mount_new_device(){
    show_who_call
    
    # 列出所有磁盘设备
    log_message "列出系统中的所有磁盘设备:" "INFO"
    lsblk -d -o NAME,SIZE,TYPE | grep disk
    
    # 提示用户输入要操作的磁盘设备名
    read -p "请输入要操作的磁盘设备名(例如: sdb): " ltmp_DISK_NAME
    
    if [ -z "$ltmp_DISK_NAME" ]; then
        log_message "错误: 未提供磁盘设备名" "ERROR"
        wait_for_input_2_exit
        return 1
    fi
    
    ltmp_DISK="/dev/$ltmp_DISK_NAME"
    
    # 检查设备是否存在
    if [ ! -b "$ltmp_DISK" ]; then
        log_message "错误: 设备 $ltmp_DISK 不存在" "ERROR"
        wait_for_input_2_exit
        return 1
    fi
    
    log_message "选择的磁盘设备: $ltmp_DISK" "WARNING"
    lsblk "$ltmp_DISK"
    
    # 警告用户
    echo "========================================"
    echo "警告: 此操作将删除 $ltmp_DISK 上的所有数据!"
    echo "========================================"
    read -p "确认要继续吗? (yes/no): " ltmp_CONFIRM
    
    if [ "$ltmp_CONFIRM" != "yes" ]; then
        log_message "操作已取消" "WARNING"
        wait_for_input_2_exit
        return 0
    fi
    
    # 检查磁盘是否已有分区
    ltmp_PARTITIONS=$(lsblk -ln -o NAME "$ltmp_DISK" | grep -v "^${ltmp_DISK_NAME}$")
    
    if [ -n "$ltmp_PARTITIONS" ]; then
        log_message "磁盘 $ltmp_DISK 已有分区:" "WARNING"
        echo "$ltmp_PARTITIONS"
        read -p "是否删除所有现有分区? (yes/no): " ltmp_DELETE_CONFIRM
        
        if [ "$ltmp_DELETE_CONFIRM" == "yes" ]; then
            log_message "删除现有分区..." "WARNING"
            # 使用parted删除所有分区
            sudo_execute "parted -s $ltmp_DISK mklabel gpt"
        else
            log_message "操作已取消" "WARNING"
            wait_for_input_2_exit
            return 0
        fi
    fi
    
    # 创建GPT分区表
    log_message "创建GPT分区表..." "WARNING"
    sudo_execute "parted -s $ltmp_DISK mklabel gpt"
    
    # 创建分区
    log_message "创建主分区..." "WARNING"
    sudo_execute "parted -s $ltmp_DISK mkpart primary 0% 100%"
    
    # 等待设备节点创建
    sleep 2
    
    # 确定分区名称
    if [ -b "${ltmp_DISK}1" ]; then
        ltmp_PARTITION="${ltmp_DISK}1"
    elif [ -b "${ltmp_DISK}p1" ]; then
        ltmp_PARTITION="${ltmp_DISK}p1"
    else
        log_message "错误: 无法确定分区名称" "ERROR"
        wait_for_input_2_exit
        return 1
    fi
    
    log_message "分区已创建: $ltmp_PARTITION" "WARNING"
    
    # 选择文件系统类型
    echo "请选择文件系统类型:"
    echo "1) ext4 (推荐,Linux默认)"
    echo "2) xfs (适合大文件)"
    echo "3) btrfs (高级功能)"
    echo "4) ntfs (Windows兼容)"
    read -p "请输入选择 (1-4, 默认为1): " ltmp_FS_CHOICE
    
    ltmp_FS_CHOICE=${ltmp_FS_CHOICE:-1}
    
    case $ltmp_FS_CHOICE in
        1)
            ltmp_FS_TYPE="ext4"
            ltmp_MKFS_CMD="mkfs.ext4"
            ;;
        2)
            ltmp_FS_TYPE="xfs"
            ltmp_MKFS_CMD="mkfs.xfs"
            ;;
        3)
            ltmp_FS_TYPE="btrfs"
            ltmp_MKFS_CMD="mkfs.btrfs"
            ;;
        4)
            ltmp_FS_TYPE="ntfs"
            ltmp_MKFS_CMD="mkfs.ntfs"
            check_packages_installed "ntfs-3g"
            if [ -n "$this_not_installed_packages" ];then
                install_package "$this_not_installed_packages"
            fi
            ;;
        *)
            log_message "无效选择,使用默认ext4" "WARNING"
            ltmp_FS_TYPE="ext4"
            ltmp_MKFS_CMD="mkfs.ext4"
            ;;
    esac
    
    # 格式化分区
    log_message "格式化分区为 $ltmp_FS_TYPE ..." "WARNING"
    sudo_execute "$ltmp_MKFS_CMD -F $ltmp_PARTITION"
    
    # 获取UUID
    ltmp_UUID=$(sudo lsblk -no UUID "$ltmp_PARTITION")
    log_message "分区UUID: $ltmp_UUID" "WARNING"
    
    # 提示用户输入挂载点
    read -p "请输入挂载点(例如: /mnt/data): " ltmp_MOUNT_POINT
    
    if [ -z "$ltmp_MOUNT_POINT" ]; then
        log_message "错误: 未提供挂载点" "ERROR"
        wait_for_input_2_exit
        return 1
    fi
    
    # 创建挂载点
    create_directory "$ltmp_MOUNT_POINT" --force
    
    # 临时挂载以测试
    log_message "临时挂载分区..." "WARNING"
    sudo_execute "mount $ltmp_PARTITION $ltmp_MOUNT_POINT"
    
    if [ $? -eq 0 ]; then
        log_message "临时挂载成功,路径: $ltmp_MOUNT_POINT" "WARNING"
        df -h "$ltmp_MOUNT_POINT"
    else
        log_message "错误: 临时挂载失败" "ERROR"
        wait_for_input_2_exit
        return 1
    fi
    
    # 询问是否添加到fstab
    read -p "是否将此分区添加到/etc/fstab以实现开机自动挂载? (yes/no): " ltmp_FSTAB_CONFIRM
    
    if [ "$ltmp_FSTAB_CONFIRM" == "yes" ]; then
        ltmp_FSTAB="/etc/fstab"
        
        # 备份fstab
        local ltmp_backup_identifier=$(backup_and_log "$ltmp_FSTAB")
        
        if [ -z "$ltmp_backup_identifier" ] || [ "$ltmp_backup_identifier" == "1" ]; then
            log_message "$ltmp_FSTAB 文件备份失败." "ERROR"
            wait_for_input_2_exit
            return 1
        else
            log_message "$ltmp_FSTAB 文件备份成功,唯一标识为 [ $ltmp_backup_identifier ]" "WARNING"
        fi
        
        # 检查是否已存在该UUID的条目
        if grep -q "$ltmp_UUID" "$ltmp_FSTAB"; then
            log_message "警告: fstab中已存在此UUID的条目" "WARNING"
        else
            # 添加fstab条目
            ltmp_FSTAB_ENTRY="UUID=$ltmp_UUID $ltmp_MOUNT_POINT $ltmp_FS_TYPE defaults 0 2"
            echo "$ltmp_FSTAB_ENTRY" | sudo_execute "tee -a $ltmp_FSTAB"
            log_message "已添加到fstab: $ltmp_FSTAB_ENTRY" "WARNING"
            
            # 测试fstab
            log_message "测试fstab配置..." "WARNING"
            sudo_execute "umount $ltmp_MOUNT_POINT"
            sudo_execute "mount -a"
            
            if mountpoint -q "$ltmp_MOUNT_POINT"; then
                log_message "fstab配置成功,分区已通过fstab挂载" "WARNING"
            else
                log_message "错误: fstab配置可能有问题" "ERROR"
            fi
        fi
    fi
    
    # 最终状态
    log_message "操作完成,当前挂载状态:" "INFO"
    df -h "$ltmp_MOUNT_POINT"
    
    wait_for_input_2_exit
    return 0
}
