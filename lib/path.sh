#!/bin/bash
#################################################################################################
# 路径管理模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/sudo.sh" 2>/dev/null || source "./lib/sudo.sh"

#################################################################################################
# 检查路径是否可用
#################################################################################################
check_path_available() {
    local ltmp_PATH_TO_CHECK=$1
    local ltmp_operate=$2
    local ltmp_PARENT_DIR

    if [ -z "$ltmp_PATH_TO_CHECK" ]; then
        log_message "输入的路径为空。" "ERROR"
        return 1
    fi

    # 检查路径是否存在
    if [ ! -e "$ltmp_PATH_TO_CHECK" ]; then
        log_message "输入的路径不存在：$ltmp_PATH_TO_CHECK" "ERROR"
        ltmp_PARENT_DIR=$(dirname "$ltmp_PATH_TO_CHECK")
        
        # 检查上层目录是否存在和是否有写权限
        if [ ! -d "$ltmp_PARENT_DIR" ]; then
            log_message "上层目录不存在：$ltmp_PARENT_DIR" "ERROR"
            return 2
        elif [ ! -w "$ltmp_PARENT_DIR" ]; then
            log_message "上层目录没有写权限：$ltmp_PARENT_DIR" "ERROR"
            return 2
        else
            # 上层目录存在且有写权限，但原路径不存在
            log_message "路径不存在但上层目录有权限，请检查您的输入或创建路径：$ltmp_PATH_TO_CHECK" "ERROR"
            return 3
        fi
    else
        # 路径存在，检查是否为允许的类型（文件或目录）
        if [ ! -f "$ltmp_PATH_TO_CHECK" ] && [ ! -d "$ltmp_PATH_TO_CHECK" ]; then
            log_message "输入的路径既不是文件也不是目录：$ltmp_PATH_TO_CHECK" "ERROR"
            return 1
        fi

        # 检查路径是否有写权限
        if [ ! -w "$ltmp_PATH_TO_CHECK" ]; then
            log_message "输入的路径没有写权限：$ltmp_PATH_TO_CHECK" "ERROR"
            return 1
        fi

        # 如果到这里，路径是有效的
        return 0
    fi
}

#################################################################################################
# 创建软链接
#################################################################################################
make_s_ln() {
    local args=("$@")
    local src=""
    local dest=""
    local force=false
    local timestamp=$(date +"%Y%m%d%H%M%S")

    # 遍历参数数组
    for ((i=0; i<${#args[@]}; i++)); do
        if [ "${args[i]}" == "--force" ]; then
            force=true
        elif [ -z "$src" ]; then
            src="${args[i]}"
        else
            dest="${args[i]}"
            break
        fi
    done

    # 检查是否提供了足够的参数
    if [ -z "$src" ] || [ -z "$dest" ]; then
        log_message "参数不足,应该为 make_s_ln src_file_or_dir dest_file_or_dir  --force.其中force是可选的,且可以出现在这三个参数的任意位置."
        return 1
    fi

    # 检查源文件/目录是否存在
    if ! check_path_available "$src" ""; then
        log_message "Source path is not available." "ERROR"
        return 1
    fi

    # 检查目标路径
    local result
    check_path_available "$dest" ""
    result=$?

    if [ "$result" -eq 1 ]; then
        local parent_dir=$(dirname "$dest")
        if [ ! -d "$parent_dir" ] || [ ! -w "$parent_dir" ]; then
            log_message "Attempting to create parent directory with sudo..."
            if ! sudo_execute "mkdir -p $parent_dir"; then
                log_message "Failed to create parent directory with sudo." "ERROR"
                return 1
            fi
        fi
        if ! mkdir -p "$dest"; then
            log_message "Failed to create destination directory. Attempting with sudo..." "TRACE"
            if ! sudo_execute "mkdir -p $dest"; then
                log_message "Failed to create destination directory with sudo." "ERROR"
                return 1
            fi
        fi
    elif [ "$result" -ne 0 ]; then
        if $force; then
            local backup_dest="${dest}_${timestamp}"
            log_message "Moving existing destination to backup: $backup_dest" "TRACE"
            if ! sudo_execute "mv $dest $backup_dest"; then
                log_message "Failed to move existing destination to backup." "ERROR"
                return 1
            fi
        else
            log_message "Destination path is not available and --force was not used." "ERROR"
            return 1
        fi
    fi

    # 尝试创建软链接
    if ! ln -s "$src" "$dest"; then
        if [ ! -w "$dest" ] || [ ! -w "$(dirname "$dest")" ]; then
            log_message "Attempting to create symbolic link with sudo..." "TRACE"
            if sudo_execute "ln -s $src  $dest"; then
                return 0
            else
                log_message "Failed to create symbolic link with sudo." "ERROR"
                return 1
            fi
        else
            log_message "Failed to create symbolic link for unknown reasons." "ERROR"
            return 1
        fi
    fi

    return 0
}

#################################################################################################
# 创建目录
# 参数1 目标目录
# 参数2 --force 强制创建
#################################################################################################
create_directory() {
    local target_dir="$1"
    local force=false
    local create_cmd="mkdir -p \"$target_dir\""

    # 检查是否有 --force 参数
    if [[ "$2" == "--force" ]]; then
        force=true
    fi

    # 检查目录是否存在
    if [[ -d "$target_dir" ]]; then
        echo "Directory already exists: $target_dir"
        original_permissions=$(stat -c "%a" "$target_dir")
        chmod u+rw "$target_dir"
        return 0
    fi

    # 尝试创建目录
    if eval "$create_cmd"; then
        echo "Directory created successfully: $target_dir"
        return 0
    else
        if $force; then
            echo "Initial attempt to create directory failed, trying with sudo..."
            create_cmd="sudo mkdir -p \"$target_dir\""
            if eval "$create_cmd"; then
                echo "Directory created successfully with sudo: $target_dir"
                return 0
            else
                echo "Failed to create directory with sudo: $target_dir"
                return 1
            fi
        else
            echo "Failed to create directory: $target_dir"
            return 1
        fi
    fi
}

#################################################################################################
# 创建目录 获取root密码时候使用图形密码框
# 参数1 目标目录
# 参数2 --force 强制创建
#################################################################################################
create_directory_gui() {
    local target_dir="$1"
    local force=false
    local create_cmd="mkdir -p \"$target_dir\""

    # 检查是否有 --force 参数
    if [[ "$2" == "--force" ]]; then
        force=true
    fi

    show_who_call

    # 检查目录是否存在
    if [[ -d "$target_dir" ]]; then
        echo "Directory already exists: $target_dir"
        original_permissions=$(stat -c "%a" "$target_dir")
        chmod u+rw "$target_dir"
        return 0
    fi

    # 尝试创建目录
    if eval "$create_cmd"; then
        echo "Directory created successfully: $target_dir"
        return 0
    else
        if $force; then
            echo "Initial attempt to create directory failed, trying with sudo..."
            create_cmd="sudo_execute_gui mkdir -p \"$target_dir\""
            if eval "$create_cmd"; then
                echo "Directory created successfully with sudo: $target_dir"
                return 0
            else
                echo "Failed to create directory with sudo: $target_dir"
                return 1
            fi
        else
            echo "Failed to create directory: $target_dir"
            return 1
        fi
    fi
}
