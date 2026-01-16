#!/bin/bash
#################################################################################################
# 系统操作模块（备份、文件操作等）
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/utils.sh" 2>/dev/null || source "./lib/utils.sh"
source "$(dirname "$0")/sudo.sh" 2>/dev/null || source "./lib/sudo.sh"

#################################################################################################
# 备份 和 记账 函数 参数是要备份的文件,返回值是一个唯一标识符
# 备份成功返回 一个10位的唯一标识
# 失败返回 1
#################################################################################################
backup_and_log() {
    local ltmp_ITEM_TO_BACKUP=$1
    local ltmp_IDENTIFIER=$(get_random_str "10")
    local ltmp_REAL_PATH
    local ltmp_BACKUP_FILE
    local ltmp_BACKUP_CMD
    local ltmp_RETRY_WITH_SUDO=0
    
    # 检查输入是文件、目录还是链接
    if [ -L "$ltmp_ITEM_TO_BACKUP" ]; then
        # 如果是链接，解析实际路径
        ltmp_REAL_PATH=$(readlink -f "$ltmp_ITEM_TO_BACKUP")
        LOG_line "即将备份的文件或目录 $ltmp_ITEM_TO_BACKUP 为链接,实际路径为 $ltmp_REAL_PATH . " "WARNING"
    else
        # 如果不是链接，则直接使用输入路径
        ltmp_REAL_PATH="$ltmp_ITEM_TO_BACKUP"
        LOG_line "即将备份文件或目录 $ltmp_REAL_PATH . " "WARNING"
    fi
    
    if [ -z "$ltmp_IDENTIFIER" ];then
        ltmp_IDENTIFIER=$(get_random_str "10")
    fi

    # 检查实际路径是文件还是目录
    if [ -f "$ltmp_REAL_PATH" ]; then
        # 如果是文件，直接备份
        ltmp_BACKUP_FILE="${this_BACKUP_DIR}/$(basename "$ltmp_REAL_PATH")_${ltmp_IDENTIFIER}"
        ltmp_BACKUP_CMD="cp -f \"$ltmp_REAL_PATH\" \"$ltmp_BACKUP_FILE\""
    elif [ -d "$ltmp_REAL_PATH" ]; then
        # 如果是目录，使用tar备份
        ltmp_BACKUP_FILE="${this_BACKUP_DIR}/$(basename "$ltmp_REAL_PATH")_${ltmp_IDENTIFIER}.tar.gz"
        ltmp_BACKUP_CMD="tar -czf \"$ltmp_BACKUP_FILE\" \"$ltmp_REAL_PATH\""
    else
        LOG_message "备份目标不存在或不是有效的文件/目录: $ltmp_REAL_PATH" "ERROR"
        return 1
    fi
    
    # 尝试备份
    eval $ltmp_BACKUP_CMD
    local ltmp_backup_ret=$?
    
    if [ $ltmp_backup_ret -eq 0 ]; then
        # 备份成功，记录到账目文件
        echo "$(date '+%Y-%m-%d %H:%M:%S') | $ltmp_REAL_PATH | $ltmp_BACKUP_FILE | $ltmp_IDENTIFIER" >> "$this_ACCOUNT_FILE"
        LOG_message "备份成功: $ltmp_REAL_PATH -> $ltmp_BACKUP_FILE (ID: $ltmp_IDENTIFIER)" "INFO"
        this_backup_IDENTIFIER="$ltmp_IDENTIFIER"
        echo "$ltmp_IDENTIFIER"
        return 0
    else
        # 备份失败，如果是因为权限问题，尝试使用sudo
        if [ $ltmp_RETRY_WITH_SUDO -eq 0 ]; then
            LOG_message "普通备份失败，尝试使用sudo权限备份" "WARNING"
            ltmp_BACKUP_CMD="sudo $ltmp_BACKUP_CMD"
            eval $ltmp_BACKUP_CMD
            ltmp_backup_ret=$?
            ltmp_RETRY_WITH_SUDO=1
            
            if [ $ltmp_backup_ret -eq 0 ]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') | $ltmp_REAL_PATH | $ltmp_BACKUP_FILE | $ltmp_IDENTIFIER" >> "$this_ACCOUNT_FILE"
                LOG_message "使用sudo备份成功: $ltmp_REAL_PATH -> $ltmp_BACKUP_FILE (ID: $ltmp_IDENTIFIER)" "INFO"
                this_backup_IDENTIFIER="$ltmp_IDENTIFIER"
                echo "$ltmp_IDENTIFIER"
                return 0
            fi
        fi
        
        LOG_message "备份失败: $ltmp_REAL_PATH (返回码: $ltmp_backup_ret)" "ERROR"
        return 1
    fi
}
