#!/bin/bash
#################################################################################################
# 配置文件处理模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/sudo.sh" 2>/dev/null || source "./lib/sudo.sh"
source "$(dirname "$0")/system.sh" 2>/dev/null || source "./lib/system.sh"

#################################################################################################
# 使用 grep 提取配置项
#################################################################################################
extract_item_grep() {
    local input_string="$1"
    local item="$2"
    echo "$input_string" | grep -oP "(?<=$item )\S+" | head -n 1
}

#################################################################################################
# 使用 sed 提取配置项
#################################################################################################
extract_item_sed() {
    local input_string="$1"
    local item="$2"
    echo "$input_string" | sed -n "s/.*$item \([^ ]*\).*/\1/p" | head -n 1
}

#################################################################################################
# 使用 awk 提取配置项
#################################################################################################
extract_item_awk() {
    local input_string="$1"
    local item="$2"
    echo "$input_string" | awk -v item="$item" '{
        for (i = 1; i <= NF; i++) {
            if ($i == item && i+1 <= NF) {
                print $(i+1);
                break;
            }
        }
    }' | head -n 1
}

#################################################################################################
# 读取INI文件
# 使用echo 返回获取到的值,因此此函数内部需要避免输出任何信息到终端.
#################################################################################################
read_ini_file(){
    local ini_file=$1
    local section=$2
    local option=$3
    local value

    value=`awk -F '=' '/\['${section}'\]/{a=1}a==1&&$1~/'${option}'/{print $2;exit}' ${ini_file}`

    if [ -z "$value" ];then
        LOG_message "获取文件 $ini_file 中 [$section] 内 $option 的值 失败:$value ." "ERROR"
        return 1
    else
        LOG_message "获取文件 $ini_file 中 [$section] 内 $option 的值 成功:$value ." "INFO"
        # 因为只能 return 数字,所以为了能传递较复杂的字符串,使用了echo.
        echo $value
    fi
}

#################################################################################################
# 写入INI文件
#################################################################################################
write_ini_file(){
    local ini_file=$1
    local section=$2
    local option=$3
    local value=$4

    local ltmp_b_get_attr_use_root=false
    local ltmp_b_writable=true
    local ini_file_tp=$1
    local ltmp_ini_backup_no=""
    local backup_file="${this_BACKUP_DIR}/$(basename $ini_file).backup"
    local temp_file="${this_TMP_DIR}/$(basename $ini_file).temp"

    # 检查文件是否存在
    if [[ ! -f "$ini_file" ]]; then
        log_message "File '$ini_file' does not exist." "WARNING"
        echo 
        read -p "Do you want to create it? 文件不存在,是否创建? yes (y) / no (n): " ltmp_create_response
        if [[ "$ltmp_create_response" == "yes" || "$ltmp_create_response" == "y" ]]; then
            touch "${ini_file}"
            local ltmp_touch_ret1=$?
            case $ltmp_touch_ret1 in
                1)
                    sudo_execute "touch ${ini_file}"
                    ;;
                *)
                    log_message "创建文件 ${ini_file} 成功."
                    ;;
            esac               
        else
            log_message "No changes made based on your choice." "WARNING"
            return 1
        fi
    fi

    ltmp_ini_backup_no=$(backup_and_log "$ini_file") 
    if [ -z "$ltmp_ini_backup_no" ] || [ "$ltmp_ini_backup_no" == "1" ]; then
        log_message "使用脚本函数 backup_and_log 备份文件 $ini_file 失败,返回值 $ltmp_ini_backup_no .即将使用cp命令备份." "ERROR"
        sudo_execute "cp $ini_file $backup_file"
        if [ "$?" == "1" ];then
            log_message "备份失败,即将退出." "ERROR"
            exit 1
        fi
    else
        log_message "使用函数 backup_and_log 备份文件 $ini_file 获得的唯一编码为 $ltmp_ini_backup_no .该编码可用于查找该备份文件,以便在出现问题时能用于恢复."
    fi

    # 检查文件是否有写权限
    if [[ ! -w "$ini_file" ]]; then
        log_message "No write permission for '$ini_file'. "  "WARNING"
        ltmp_b_writable=false

        # 获取文件属性
        local file_owner=$(stat -c '%U' "$ini_file")
        local file_group=$(stat -c '%G' "$ini_file")
        local file_mode=$(stat -c '%A' "$ini_file")
        local file_perm=$(stat -c '%a' "$ini_file")

        if [ -z "$file_owner" ] || [ -z "$file_group" ] || [ -z "$file_mode" ] || [ -z "$file_perm" ]; then
            log_message "获取文件 $ini_file 属性失败: file_owner=$file_owner file_group=$file_group file_mode=$file_mode file_perm=$file_perm ."  "ERROR"
            file_owner=$(sudo_execute "stat -c '%U' $ini_file")
            file_group=$(sudo_execute "stat -c '%G' $ini_file")
            file_mode=$(sudo_execute "stat -c '%A' $ini_file")
            file_perm=$(sudo_execute "stat -c '%a' $ini_file")
            ltmp_b_get_attr_use_root=true
        fi
        
        # 使用 sudo 复制文件到临时目录
        sudo_execute "cp $ini_file $temp_file"
        
        # 修改文件副本权限以便当前用户可以写入
        sudo_execute "chmod 666 $temp_file "  

        # 将变量 ini_file 指向临时文件,供后面继续修改操作.
        ini_file="$temp_file"
        log_message "变量 ini_file 已修改为 $ini_file ." "WARNING"
    fi

    log_message "正在对文件 $ini_file 进行操作."  "WARNING"

    # 检查并添加section
    if ! grep -q "\[$section\]" $ini_file; then
        log_message "写入空行到文件 $ini_file ." "TRACE"
        echo  >> $ini_file

        log_message "写入 [$section] 到文件 $ini_file ." "TRACE"
        echo "[$section]" >> $ini_file
    fi

    # 检查并替换或添加option=value
    if ! grep -q "^$option=" $ini_file; then
        log_message "写入 $option=$value 到文件 $ini_file 的 [$section]." "TRACE"
        echo "$option=$value" >> $ini_file
    else
        log_message "即将修改文件 $ini_file 段 $section ,$option = $value ." "TRACE"

        local ltmp_line_no_array
        local ltmp_line_no=""
        local ltmp_newline_no=""

        # 使用 mapfile 获取匹配行的行号到数组中
        mapfile -t ltmp_line_no_array < <(sed -n "/${option}=/=" "$ini_file")

        # 检查数组是否为空
        if [ ${#ltmp_line_no_array[@]} -eq 0 ]; then
            echo "未找到匹配项。"
            return 1
        fi

        # 检查数组长度是否大于1
        if [ ${#ltmp_line_no_array[@]} -gt 1 ]; then
            echo "#### $ini_file 文件内容  ###########################"
            echo "  行号    内容"
            cat $ini_file -n
            echo "#### $ini_file 文件匹配 ${option}\= 内容的行 ###########"
            cat $ini_file -n | grep  "${option}\="
            echo "#### $ini_file 检索结果  ###########################"
            echo "找到多个匹配项，请输入行号或输入 'all' 来替换所有行.(直接回车则只替换第一个匹配的行)："
            
            local ltmp_ini_user_input
            read -r ltmp_ini_user_input
            
            if [[ "$ltmp_ini_user_input" =~ [0-9]+$ ]]; then
                if [[ " ${ltmp_line_no_array[*]} " =~ " ${ltmp_ini_user_input} " ]]; then
                    ltmp_line_no=$ltmp_ini_user_input
                    ltmp_newline_no=$(expr $ltmp_line_no - 1)
                    sed  -i  "$ltmp_line_no  d"   "$ini_file"
                    sed -i "${ltmp_newline_no} a\\${option}=${value}"  "$ini_file"
                else
                    echo "输入的行号不在匹配列表中。"
                fi
            elif [ "$ltmp_ini_user_input" == "all" ]; then
                for ltmp_line_no in "${ltmp_line_no_array[@]}"; do
                    ltmp_newline_no=$(expr $ltmp_line_no - 1)
                    sed  -i  "$ltmp_line_no  d"   "$ini_file"
                    sed -i "${ltmp_newline_no} a\\${option}=${value}"  "$ini_file"
                done
            else
                ltmp_line_no=${ltmp_line_no_array}
                ltmp_newline_no=$(expr $ltmp_line_no - 1)
                sed  -i  "$ltmp_line_no  d"   "$ini_file"
                sed -i "${ltmp_newline_no} a\\${option}=${value}"  "$ini_file"
            fi
        else
            ltmp_line_no=${ltmp_line_no_array}
            ltmp_newline_no=$(expr $ltmp_line_no - 1)
            sed  -i  "$ltmp_line_no  d"   "$ini_file"
            sed -i "${ltmp_newline_no} a\\${option}=${value}"  "$ini_file"
        fi
    fi

    if [ $ltmp_b_writable = false ];then
        log_message "恢复文件 $ini_file 属性信息." "TRACE"
        sudo_execute "chown $file_owner:$file_group  $ini_file"
        sudo_execute "chmod $file_perm $ini_file"
        sudo_execute "cp -f $ini_file $ini_file_tp"
    fi

    return 0
}
