#!/bin/bash


write_class_file_AI_written() {
    local ltmp_file="$1"
    local ltmp_class_name="$2"
    local ltmp_item="$3"
    local ltmp_value="$4"
    local ltmp_class_end_with=""
    local ltmp_force=0
    local ltmp_useeq=0
    local ltmp_line_end_semi=0
    local ltmp_endsemi=0
    local ltmp_comment_use_sharp=0

    # 检查参数数量
    if [ "$#" -lt 4 ]; then
        echo "Usage: write_class_file_AI_written file class item value [--force] [--useeq] [--line_end_semi] [--endsemi] [--comment_use_sharp]"
        return 1
    fi

    # 解析参数
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --force)
                ltmp_force=1
                ;;
            --useeq)
                ltmp_useeq=1
                ;;
            --line_end_semi)
                ltmp_line_end_semi=1
                ;;
            --endsemi)
                ltmp_endsemi=1
                ;;
            --comment_use_sharp)
                ltmp_comment_use_sharp=1
                ;;
            *)
                break
                ;;
        esac
        shift
    done

    # 检查文件是否存在
    if [ ! -f "$ltmp_file" ]; then
        echo "File $ltmp_file does not exist."
        return 1
    fi

    # 读取文件内容
    local file_content=$(cat "$ltmp_file")

    # 检查类是否存在
    if [[ "$file_content" =~ "^[[:space:]]*$ltmp_class_name[[:space:]]*\\{" || "$file_content" =~ "^[[:space:]]*$ltmp_class_name\\{" ]]; then
        # 类存在，更新或添加项目值
        if [ "$ltmp_force" -eq 1 ]; then
            # 使用严格模式，删除旧的类内容
            file_content=$(echo "$file_content" | sed "/^[[:space:]]*$ltmp_class_name[[:space:]]*\\{/,/^}/d")
        fi

        # 检查项目是否存在
        if [[ "$file_content" =~ "$ltmp_item" ]]; then
            # 项目存在，更新其值
            file_content=$(echo "$file_content" | sed "s|$ltmp_item.*|$ltmp_item $ltmp_value|")
        else
            # 项目不存在，添加新项目
            local new_item_content="\n    $ltmp_item $ltmp_value"
            if [ "$ltmp_line_end_semi" -eq 1 ]; then
                new_item_content="$new_item_content;"
            fi
            # Bug 修复：添加转义字符
            file_content=$(echo "$file_content" | sed "s|^[[:space:]]*$ltmp_class_name[[:space:]]*\\{|$ltmp_class_name{\n$new_item_content\n|")
        fi
    else
        # 类不存在，创建新类
        local new_class_content="\n$ltmp_class_name{"
        if [ "$ltmp_useeq" -eq 1 ]; then
            new_class_content="$new_class_content\n    $ltmp_item=$ltmp_value"
        else
            new_class_content="$new_class_content\n    $ltmp_item $ltmp_value"
        fi
        if [ "$ltmp_line_end_semi" -eq 1 ]; then
            new_class_content="$new_class_content;"
        fi
        new_class_content="$new_class_content\n}"
        if [ "$ltmp_endsemi" -eq 1 ]; then
            new_class_content="$new_class_content;"
        fi
        file_content="$file_content$new_class_content"
    fi

    # 写入文件
    echo -e "$file_content" > "$ltmp_file"

    # 输出修改的行号
    echo "Modified lines:"
    echo "$file_content" | grep -n "$ltmp_class_name"
}

    touch "/home/pangu/java.txt"
    # 在调用 write_class_file 函数之前设置支持的注释符号
    comment_symbol_array=("#" "//")
    write_class_file_AI_written "/home/pangu/java.txt" "classA" "item1" "valueofitem1" #--endsemi --useeq
    write_class_file_AI_written "/home/pangu/java.txt" "classB" "item2" "valueofitem2"
    write_class_file_AI_written "/home/pangu/java.txt" "classC" "item3" "valueofitem3"
    write_class_file_AI_written "/home/pangu/java.txt" "classC" "item4" "valueofitem4"
    write_class_file_AI_written "/home/pangu/java.txt" "classC" "item5" "value1ofitem5 value2ofitem5 value3ofitem5"
    write_class_file_AI_written "/home/pangu/java.txt" "classC" "item4" "valueofitem4_new_vaule"
    
