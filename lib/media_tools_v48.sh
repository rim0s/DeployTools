#!/bin/bash
#################################################################################################
# 媒体与校验工具（V48 版本）
# 包含验证码与图片筛选功能。
#################################################################################################

source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/sudo.sh" 2>/dev/null || source "./lib/sudo.sh"

#################################################################################################
# 生成验证码并校验
#################################################################################################
generate_verification_code() {
    local complexity="$1"
    local length="$2"
    local characters=""
    local verification_code=""

    if [[ "$complexity" -eq 1 ]]; then
        characters="0123456789"
    elif [[ "$complexity" -eq 2 ]]; then
        characters="0123456789abcdefghijklmnopqrstuvwxyz"
    elif [[ "$complexity" -eq 3 ]]; then
        characters="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    else
        echo "Invalid complexity level. Please choose between 1 and 3."
        return 1
    fi

    for ((i = 0; i < length; i++)); do
        verification_code+="${characters:RANDOM%${#characters}:1}"
    done

    echo -en "Your verification code is: $verification_code \n"
    echo -n "Please enter the verification code: "
    read -r user_input

    if [[ "$user_input" == "$verification_code" ]]; then
        echo "Verification successful!"
        return 0
    else
        echo "Verification failed."
        return 1
    fi
}

#################################################################################################
# 查找符合尺寸的图片并执行指定操作
#################################################################################################
find_pic() {
    local ltmp_width_range=""
    local ltmp_height_range=""
    local ltmp_from_dir=""
    local ltmp_action=""
    local ltmp_target_dir=""
    local delete_verification_resault=1
    local ltmp_find_timestamp=$(date +%Y%m%d_%H%M%S)
    local ltmp_b_quiet=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -w)
                ltmp_width_range="$2"; shift 2 ;;
            -h)
                ltmp_height_range="$2"; shift 2 ;;
            --mv)
                ltmp_action="mv"; ltmp_target_dir="$2"; shift 2 ;;
            --cp)
                ltmp_action="cp"; ltmp_target_dir="$2"; shift 2 ;;
            --delete)
                ltmp_action="delete"; shift 1 ;;
            --quiet)
                ltmp_b_quiet=true; shift 1 ;;
            *)
                if [[ -z "$ltmp_from_dir" ]]; then
                    ltmp_from_dir="$1"; shift
                else
                    echo "Usage: find_pic -w width_range -h height_range from_dir [--mv|--cp target_dir|--delete]"
                    return 1
                fi
                ;;
        esac
    done

    local delete_decision_retault="n"
    if [[ "$ltmp_action" == "delete" ]]; then
        echo -en "Are you sure to delete all the files in $ltmp_from_dir? (y/n)\n"
        read -r delete_decision_retault
        if [[ "$delete_decision_retault" != "y" ]]; then
            echo "Delete operation canceled."
            return 0
        fi
        generate_verification_code 3 8 || return 1
        if [[ ! -d "${ltmp_from_dir}_bak_${ltmp_find_timestamp}" ]]; then
            mkdir -p "${ltmp_from_dir}_bak_${ltmp_find_timestamp}" || { echo "备份用文件夹创建失败"; return 1; }
        fi
        cp -rf "$ltmp_from_dir"/* "${ltmp_from_dir}_bak_${ltmp_find_timestamp}" || { echo "备份失败"; return 1; }
    fi

    if [[ -z "$ltmp_width_range" || -z "$ltmp_height_range" || -z "$ltmp_from_dir" ]]; then
        echo "Usage: find_pic -w width_range -h height_range from_dir [--mv|--cp target_dir|--delete]"
        return 1
    fi

    local width_min width_max height_min height_max
    if [[ "$ltmp_width_range" =~ ^[0-9]+-[0-9]+$ ]]; then
        IFS='-' read -r width_min width_max <<< "$ltmp_width_range"
    else
        width_min="$ltmp_width_range"; width_max="$ltmp_width_range"
    fi
    if [[ "$ltmp_height_range" =~ ^[0-9]+-[0-9]+$ ]]; then
        IFS='-' read -r height_min height_max <<< "$ltmp_height_range"
    else
        height_min="$ltmp_height_range"; height_max="$ltmp_height_range"
    fi

    if [ $ltmp_b_quiet = false ]; then
        echo "Parameters:"
        echo "width_min=$width_min"; echo "width_max=$width_max"; echo "height_min=$height_min"; echo "height_max=$height_max"
        echo "from_dir=$ltmp_from_dir"; echo "action=$ltmp_action"; echo "target_dir=$ltmp_target_dir"
    fi

    find "$ltmp_from_dir" -type f | while read -r file; do
        width=$(identify -format "%W" "$file" 2>/dev/null)
        height=$(identify -format "%H" "$file" 2>/dev/null)
        if [[ -z "$width" || -z "$height" ]]; then
            continue
        fi
        if [[ "$width" -ge "$width_min" && "$width" -le "$width_max" && "$height" -ge "$height_min" && "$height" -le "$height_max" ]]; then
            case "$ltmp_action" in
                mv)
                    echo "Moving: $file -> $ltmp_target_dir"
                    mv "$file" "$ltmp_target_dir" || echo "Failed to move $file"
                    ;;
                cp)
                    echo "Copying: $file -> $ltmp_target_dir"
                    cp "$file" "$ltmp_target_dir" || echo "Failed to copy $file"
                    ;;
                delete)
                    echo "Deleting: $file"
                    rm "$file" || echo "Failed to delete $file"
                    ;;
                "")
                    echo "$file"
                    ;;
                *)
                    echo "Invalid action: $ltmp_action"; return 1 ;;
            esac
        fi
    done
}
