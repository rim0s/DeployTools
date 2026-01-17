#!/bin/bash
#################################################################################################
# 类文件写入（V48 legacy 版本）
# 保留原始 V48 的 write_class_file_* 三个实现。
#################################################################################################

source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/utils.sh" 2>/dev/null || source "./lib/utils.sh"

############################################################
# 未优化版本
############################################################
write_class_file_() {
    local file_path=$1
    local class_name=$2
    local project_name=$3
    local project_value=$4
    local endsemi=false
    local use_eq=false

    shift 4
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --endsemi) endsemi=true ;;
            --useeq)   use_eq=true ;;
            *) echo "Unknown option: $1"; return 1 ;;
        esac
        shift
    done

    local connector=" "
    $use_eq && connector="="

    local temp_file=$(mktemp)
    local inside_class=false
    local other_class=false
    local project_added=false
    local potential_class_name=""
    local current_project_name=""

    echo_double_line
    echo "Func is start"
    echo_double_line

    while IFS= read -r line; do
        line=$(echo "$line" | sed 's/[[:space:]]*$//')
        if [ -z "$line" ]; then
            echo "$line" >> "$temp_file"
            continue
        fi

        if $inside_class; then
            if [[ "$line" != "};" ]] && [[ "$line" != "}" ]]; then
                current_project_name=$(echo "$line" | awk '{print $1}' | sed 's/[[:space:]]*$//')
                if [[ "$current_project_name" == "$project_name" ]]; then
                    echo "      ${project_name}${connector}${project_value};" >> "$temp_file"
                    project_added=true
                else
                    echo "$line" >> "$temp_file"
                fi
            else
                if ! $project_added; then
                    echo "      ${project_name}${connector}${project_value};" >> "$temp_file"
                    project_added=true
                fi
                echo "$line" >> "$temp_file"
                inside_class=false
            fi
        else
            if [ $project_added == true ]; then
                echo "$line" >> "$temp_file"
                continue
            fi

            if [ $other_class == true ]; then
                if [[ "$line" == "};" ]] || [[ "$line" == "}" ]]; then
                    other_class=false
                fi
                echo "$line" >> "$temp_file"
                continue
            fi

            potential_class_name=$(echo "$line" | sed 's/{.*$//' | sed 's/[[:space:]]*$//')

            if [[ "$potential_class_name" == "$class_name" ]]; then
                inside_class=true
            else
                other_class=true
            fi
            echo "$line" >> "$temp_file"
        fi
    done < "$file_path"

    if [ $project_added = false ]; then
        echo "${class_name} {" >> "$temp_file"
        echo "      ${project_name}${connector}${project_value};" >> "$temp_file"
        $endsemi && echo "};" >> "$temp_file" || echo "}" >> "$temp_file"
        echo "" >> "$temp_file"
    fi

    mv "$temp_file" "$file_path"
}

############################################################
# 改进中的版本（保持原逻辑，含注释支持）
############################################################
declare -a comment_symbol_array
write_class_file_Modifing() {
    local ltmp_file_path=$1
    local ltmp_class_name=$2
    local ltmp_item_name=$3
    local ltmp_item_value=$4
    local ltmp_endsemi=false
    local ltmp_use_eq=false

    shift 4
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --endsemi) ltmp_endsemi=true ;;
            --useeq)   ltmp_use_eq=true ;;
            *) echo "Unknown option: $1"; return 1 ;;
        esac
        shift
    done

    local ltmp_connector=" "
    $ltmp_use_eq && ltmp_connector="="

    local ltmp_comment_symbols=()
    if [ ${#comment_symbol_array[@]} -eq 0 ]; then
        ltmp_comment_symbols=("//" "#")
    else
        ltmp_comment_symbols=("${comment_symbol_array[@]}")
    fi

    local ltmp_temp_file=$(mktemp)
    local ltmp_inside_class=false
    local ltmp_other_class=false
    local ltmp_project_added=false
    local ltmp_potential_class_name=""
    local ltmp_current_project_name=""
    local is_comment=false

    while IFS= read -r line; do
        line=$(echo "$line" | sed 's/[[:space:]]*$//')
        if [ -z "$line" ]; then
            echo "$line" >> "$ltmp_temp_file"
            continue
        fi

        is_comment=false
        for symbol in "${ltmp_comment_symbols[@]}"; do
            if [[ "$line" == "$symbol"* ]]; then
                is_comment=true
                break
            fi
        done
        if [[ "$is_comment" == true ]]; then
            echo "$line" >> "$ltmp_temp_file"
            continue
        fi

        if $ltmp_inside_class; then
            if [[ "$line" != "};" ]] && [[ "$line" != "}" ]]; then
                ltmp_current_project_name=$(echo "$line" | awk '{print $1}' | sed 's/[[:space:]]*$//')
                if [[ "$ltmp_current_project_name" == "$ltmp_item_name" ]]; then
                    echo "      ${ltmp_item_name}${ltmp_connector}${ltmp_item_value};" >> "$ltmp_temp_file"
                    ltmp_project_added=true
                else
                    echo "$line" >> "$ltmp_temp_file"
                fi
            else
                if ! $ltmp_project_added; then
                    echo "      ${ltmp_item_name}${ltmp_connector}${ltmp_item_value};" >> "$ltmp_temp_file"
                    ltmp_project_added=true
                fi
                echo "$line" >> "$ltmp_temp_file"
                ltmp_inside_class=false
            fi
        else
            echo "$line" >> "$ltmp_temp_file"
            if [ $ltmp_project_added == true ]; then
                continue
            fi
            if [ $ltmp_other_class == true ]; then
                if [[ "$line" == "};" ]] || [[ "$line" == "}" ]]; then
                    ltmp_other_class=false
                fi
                continue
            fi

            ltmp_potential_class_name=$(echo "$line" | sed 's/{.*$//' | sed 's/[[:space:]]*$//')
            if [[ "$ltmp_potential_class_name" == "$ltmp_class_name" ]]; then
                if [[ "$line" == *"{"* ]]; then
                    ltmp_inside_class=true
                fi
            else
                ltmp_other_class=true
            fi
        fi
    done < "$ltmp_file_path"

    if [ $ltmp_project_added = false ]; then
        echo "${ltmp_class_name} {" >> "$ltmp_temp_file"
        echo "      ${ltmp_item_name}${ltmp_connector}${ltmp_item_value};" >> "$ltmp_temp_file"
        $ltmp_endsemi && echo "};" >> "$ltmp_temp_file" || echo "}" >> "$ltmp_temp_file"
        echo "" >> "$ltmp_temp_file"
    fi

    mv "$ltmp_temp_file" "$ltmp_file_path"
}

############################################################
# 失败版本（保留以兼容历史）
############################################################
write_class_file_error() {
    local ltmp_file_path=$1
    local ltmp_class_name=$2
    local ltmp_item_name=$3
    local ltmp_item_value=$4
    local ltmp_endsemi=false
    local ltmp_use_eq=false

    shift 4
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --endsemi) ltmp_endsemi=true ;;
            --useeq)   ltmp_use_eq=true ;;
            *) echo "Unknown option: $1"; return 1 ;;
        esac
        shift
    done

    local ltmp_connector=" "
    $ltmp_use_eq && ltmp_connector="="
    log_message "write_class_file_error 保留原始实现(正则复杂未完成)" "WARNING"
    # 原脚本未完成，此处保持占位，便于后续重构
    return 1
}
