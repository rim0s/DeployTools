#!/bin/bash
# 生成验证码并要求用户输入验证码
# 参数1:验证码的复杂度)1:数字，2:字母，3:数字和字母)
# 参数2:验证码的长度
# 返回值:0表示验证成功，1表示验证失败
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

# Example usage:
# generate_verification_code 2 8

# 查找符合条件的图片并执行指定操作
# 参数1:宽度范围)例如:500-600)
# 参数2:高度范围)例如:780-790)
# 参数3:查找的起始目录
# 参数4:操作类型)可选:mv、cp、delete)
# 参数5:目标目录)如果指定了操作类型)
# 返回值:0表示操作成功，1表示操作失败
# find_pic() {
#     local width_range="$1"
#     local height_range="$2"
#     local from_dir="$3"
#     local action="$4"
#     local target_dir="$5"
#
#     # 解析宽度和高度范围
#     IFS='-' read -r width_min width_max <<< "$width_range"
#     IFS='-' read -r height_min height_max <<< "$height_range"
#
#     # 查找符合条件的图片并执行指定操作
find_pic() {
    local ltmp_width_range=""
    local ltmp_height_range=""
    local ltmp_from_dir=""
    local ltmp_action=""
    local ltmp_target_dir=""
    local delete_verification_resault=1
    local ltmp_find_timestamp=$(date +%Y%m%d_%H%M%S)
    local ltmp_b_quiet=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -w)
                ltmp_width_range="$2"
                shift 2
                ;;
            -h)
                ltmp_height_range="$2"
                shift 2
                ;;
            --mv)
                ltmp_action="mv"
                ltmp_target_dir="$2"
                shift 2
                ;;
            --cp)
                ltmp_action="cp"
                ltmp_target_dir="$2"
                shift 2
                ;;
            --delete)
                ltmp_action="delete"
                shift 1
                ;;
            --quiet)
                ltmp_b_quiet=true
                shift 1
                ;;
            *)
                if [[ -z "$ltmp_from_dir" ]]; then
                    ltmp_from_dir="$1"
                    shift
                else
                    echo "Usage: find_pic -w ltmp_width_range -h ltmp_height_range ltmp_from_dir [--mv|--cp ltmp_target_dir]"
                    return 1
                fi
                ;;
        esac
    done

    # Check if verification is required
    local delete_decision_retault="n"
    if [[ "$ltmp_action" == "delete" ]]; then
        echo -en "Are you sure to delete all the files in $ltmp_from_dir? (y/n)\n"
        read -r delete_decision_retault
        if [[ "$delete_decision_retault" != "y" ]]; then
            echo "Delete operation canceled."
            return 0
        else
            # 删除操作需要验证,为了防止误操作,需要用户输入验证码.
            generate_verification_code 3 8 
            delete_verification_resault=$?
            if [ $delete_verification_resault -ne 0 ]; then
                echo "验证码错误,程序不会执行任何操作."
                return 1
            fi
            if [[ ! -f "${ltmp_from_dir}_bak_${ltmp_find_timestamp}" ]]; then
                mkdir "${ltmp_from_dir}_bak_${ltmp_find_timestamp}"
            fi
            if [[ ! -f "${ltmp_from_dir}_bak_${ltmp_find_timestamp}" ]]; then
               echo "备份用文件夹创建失败,安全起见,我先退了."
               return 1
            else
                cp -rf "$ltmp_from_dir"/* "${ltmp_from_dir}_bak_${ltmp_find_timestamp}"
                if [ $? -ne 0 ]; then
                    echo "备份用文件夹创建失败,安全起见,我先退了."
                    return 1
                fi
            fi
        fi
    fi

    # Check if required arguments are provided
    if [[ -z "$ltmp_width_range" || -z "$ltmp_height_range" || -z "$ltmp_from_dir" ]]; then
        echo "Usage: find_pic -w ltmp_width_range -h ltmp_height_range ltmp_from_dir [--mv|--cp ltmp_target_dir]"
        return 1
    fi

    # Extract width and height ranges
    if [[ "$ltmp_width_range" =~ ^[0-9]+-[0-9]+$ ]]; then
        IFS='-' read -r width_min width_max <<< "$ltmp_width_range"
    else
        width_min="$ltmp_width_range"
        width_max="$ltmp_width_range"
    fi

    if [[ "$ltmp_height_range" =~ ^[0-9]+-[0-9]+$ ]]; then
        IFS='-' read -r height_min height_max <<< "$ltmp_height_range"
    else
        height_min="$ltmp_height_range"
        height_max="$ltmp_height_range"
    fi

    # Print parameters
    if [ $ltmp_b_quiet = false ];then
        echo 
        echo -en "Parameters: \n"
        echo -en "width_min=$width_min \nwidth_max=$width_max \nheight_min=$height_min \nheight_max=$height_max \nltmp_from_dir=$ltmp_from_dir \nltmp_action=$ltmp_action \nltmp_target_dir=$ltmp_target_dir \n"
        echo 
    fi
    
    # Find and process images
    find "$ltmp_from_dir" -type f | while read -r file; do
        width=$(identify -format "%W" "$file" 2> /dev/null)
        height=$(identify -format "%H" "$file" 2> /dev/null)

        if [[ "$width" -ge "$width_min" && "$width" -le "$width_max" && "$height" -ge "$height_min" && "$height" -le "$height_max" ]]; then

            #echo "Fond: $file, width: $width, height: $height"
            # Process the image
            if [[ -n "$ltmp_action" ]]; then
                case "$ltmp_action" in
                    mv)
                        echo "Moveing: $file to $ltmp_target_dir"
                        mv "$file" "$ltmp_target_dir" || { echo "Failed to move $file"; }
                        ;;
                    cp)
                        echo "Copying: $file to $ltmp_target_dir"
                        cp "$file" "$ltmp_target_dir" || { echo "Failed to copy $file"; }
                        ;;
                    delete)
                        echo "Deleting: $file"
                        rm "$file" || { echo "Failed to delete $file"; }
                        ;;
                    *)
                        echo "Invalid action: $ltmp_action"
                        return 1
                        ;;
                esac
            else
                echo "$file"
            fi
        fi
    done
}

find_pic "$@"

# Example usage:
# find_pic -w "500-600" -h "780-790" "/home/saint/Pictures"
# find_pic -w "500" -h "780" "/home/saint/Pictures" --mv "/home/saint/backup/myPicture"