#!/bin/bash
#################################################################################################
# 配置文件读写（V48 legacy 版本）
# 说明：保留原 V48 的实现，以兼容旧逻辑；与现有 config_file.sh 并行存在。
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/sudo.sh" 2>/dev/null || source "./lib/sudo.sh"
source "$(dirname "$0")/system.sh" 2>/dev/null || source "./lib/system.sh"

#################################################################################################
# write_conf_file_old
#################################################################################################
write_conf_file_old() {
    local file=$1
    local item=$2
    local value=$3
    local useeq=false
    local noblank=false

    # 解析可选参数
    while [[ $# -gt 3 ]]; do
        case "$4" in
            --useeq)
                useeq=true
                ;;
            --noblank)
                noblank=true
                ;;
            *)
                echo "Invalid option: $4"
                return 1
                ;;
        esac
        shift
    done

    # 备份文件
    local backup_str=$(backup_and_log "$file")
    if [ $? -ne 0 ]; then
        echo "Failed to backup file: $file"
        return 1
    fi

    [ -f "$file" ] || touch "$file"

    # 注释旧项
    if grep -q "^$item" "$file"; then
        sed -i "/^$item/s/^/# /" "$file"
        sed -i "/^# $item/a # comment by ${0} from $(date +%Y%m%d-%H%M%S) $backup_str" "$file"
    fi

    echo "# 下面一行的 $item 内容由批次编号 $backup_str 于 $(date +%Y%m%d-%H%M%S) 添加" >> "$file"

    if $useeq; then
        if $noblank; then
            echo "$item=$value" >> "$file"
        else
            echo "$item = $value" >> "$file"
        fi
    else
        echo "$item $value" >> "$file"
    fi
    return 0
}

#################################################################################################
# get_item_from_conf
#################################################################################################
get_item_from_conf() {
    local file=$1
    local item=$2
    local ltmp_connector=" "
    local useeq=false
    local noblank=false
    local all=false
    local return_value=""

    while [[ $# -gt 2 ]]; do
        case "$3" in
            --useeq)
                useeq=true
                ;;
            --noblank)
                noblank=true
                ;;
            --all)
                all=true
                ;;
            *)
                echo "Invalid option: $3"
                return 1
                ;;
        esac
        shift
    done

    [ -f "$file" ] || { echo "File does not exist: $file"; return 1; }

    if $useeq; then
        if $noblank; then
            ltmp_connector="="
        else
            ltmp_connector=" = "
        fi
    fi

    if grep -q "^$item" "$file"; then
        local ltmp_cut_temp=$(grep -ho "^[[:space:]]*${item}${ltmp_connector}\(.*\)" "$file" | cut -d: -f2- | cut --delimiter="${ltmp_connector}" -f2- )
        return_value=$(echo "$ltmp_cut_temp" | cut --delimiter="#" -f1- )
        echo "$return_value"
    else
        log_message "指定项目未找到." "ERROR"
        return 1
    fi
    return 0
}

#################################################################################################
# write_conf_file（legacy版，保留 add_only 逻辑）
#################################################################################################
write_conf_file() {
    local file=$1
    local item=$2
    local value=$3
    local useeq=false
    local noblank=false
    local add_only=false
    local ltmp_connector=" "
    local ltmp_read_conf_parm=""

    while [[ $# -gt 3 ]]; do
        case "$4" in
            --useeq)
                useeq=true
                ltmp_read_conf_parm=$ltmp_read_conf_parm" --useeq"
                ;;
            --noblank)
                noblank=true
                ltmp_read_conf_parm=$ltmp_read_conf_parm" --noblank"
                ;;
            --add)
                add_only=true
                ;;
            *)
                echo "Invalid option: $4"
                return 1
                ;;
        esac
        shift
    done

    local backup_str=$(backup_and_log "$file")
    if [ $? -ne 0 ]; then
        echo "Failed to backup file: $file"
        return 1
    fi

    [ -f "$file" ] || touch "$file"

    if $useeq; then
        if $noblank; then
            ltmp_connector="="
        else
            ltmp_connector=" = "
        fi
    fi

    local ltmp_read_conf_resault=$(get_item_from_conf "$file" "$item" $ltmp_read_conf_parm)
    if [ $? -eq 0 ]; then
        local line_number=$(grep -n "^[[:space:]]*$item${ltmp_connector}" "$file" | cut -d: -f1 | head -n 1)
        if [ -z "$line_number" ]; then
            echo "# 下面一行的 $item 内容由批次编号 $backup_str 于 $(date +%Y%m%d-%H%M%S) 添加" >> "$file"
            echo "${item}${ltmp_connector}${value}" >> "$file"
            return 0
        fi

        if $add_only; then
            echo "# 下面一行的 $item 内容由批次编号 $backup_str 于 $(date +%Y%m%d-%H%M%S) 添加" >> "$file"
            echo "${item}${ltmp_connector}${value}" >> "$file"
            return 0
        fi

        sed -i "/^${item}${ltmp_connector}/s/$/ #$backup_str/" "$file"
        sed -i "/^${item}${ltmp_connector}/s/^/#/" "$file"
        sed -i "$((line_number + 0))a # 下面一行的 $item 内容由批次编号 $backup_str 于 $(date +%Y%m%d-%H%M%S) 添加" "$file"
        sed -i "$((line_number + 1))a ${item}${ltmp_connector}${value}" "$file"
    else
        echo "# 下面一行的 $item 内容由批次编号 $backup_str 于 $(date +%Y%m%d-%H%M%S) 添加" >> "$file"
        echo "${item}${ltmp_connector}${value}" >> "$file"
    fi
    return 0
}
