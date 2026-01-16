#!/bin/bash

write_class_file() {
    local ltmp_file_path=$1
    local ltmp_class_name=$2
    local ltmp_item_name=$3
    local ltmp_item_value=$4
    local ltmp_endsemi=false
    local ltmp_use_eq=false

    # 处理可选参数
    shift 4
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --endsemi)
                ltmp_endsemi=true
                ;;
            --useeq)
                ltmp_use_eq=true
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done
    
    # 确定项目和值之间的连接符
    local ltmp_connector
    if $ltmp_use_eq; then
        ltmp_connector="="
    else
        ltmp_connector=" "
    fi

    # 检查是否设置了注释符号数组
    if [ ${#comment_symbol_array[@]} -eq 0 ]; then
        # 如果没有设置，使用默认注释符号
        local ltmp_comment_symbols=("//" "#")
    else
        # 使用全局数组中的注释符号
        local ltmp_comment_symbols=("${comment_symbol_array[@]}")
    fi

    comment_regex=$(IFS="|"; echo "${ltmp_comment_symbols[*]}")
    comment_regex="([[:space:]]*(${comment_regex}).*$)"

    # 临时文件来存储修改后的内容
    local ltmp_temp_file=$(mktemp)

    # 标记是否处于指定的类定义内部
    local ltmp_inside_class=false

    # 标记是否处于其他类定义内部
    local ltmp_other_class=false

    # 标记是否已经在该类中添加了项目
    local ltmp_project_added=false

    # 可能的类名临时变量
    local ltmp_potential_class_name=""

    # 取出的项目名临时变量
    local ltmp_current_project_name=""

    # 用于行是否是注释行
    local is_comment=false

    bool_line_might_be_class_start=false
    bool_line_might_be_inside_class=false
    bool_line_might_be_other_class=false
    bool_finash_class_this_line=false

    local ltmp_first_str=""
    local trimmed_line=""
    local remaining_line=""
    local remaining_line_without_comments=""
    local first_char=""

    # 读取原文件并处理
    while IFS= read -r line; do
        # 去除行尾的空格
        #trimmed_line=$(echo "$line" | sed 's/[[:space:]]*$//')

        # 去除行首的空格
        #trimmed_line=$(echo "$line" | sed 's/[[:space:]]*//')

        # 去除行首和行尾的空格
        trimmed_line=$(echo "$line" | sed 's/[[:space:]]*//;s/[[:space:]]*$//')
    

        # 空行直接搬运
        if [ -z "$trimmed_line" ];then
            echo "$line" >> "$ltmp_temp_file"
            continue
        fi

        # 先假设不是注释行
        is_comment=false
        for symbol in "${comment_symbols[@]}"; do
            if [[ "$trimmed_line" == "$symbol"* ]]; then
                is_comment=true
                break
            fi
        done

        # 注释行 直接搬运
        if [[ "$is_comment" == true ]]; then
            echo "$line" >> "$temp_file"
            continue
        fi

        bool_finash_class_this_line=false

        # 分号(";")起始,有两种可能 
        #   1.此次循环之前的部分可能是个完整的类定义
        #   2.此次循环之前的部分可能是个 project_name project_value 的行
        if [[ "$trimmed_line" == ";"* ]]; then
            # 不确定的情况是检测到字符串但未找到类开始符号.既然看到分号了说明确定不是开始了,所以清除一下变量状态后可以直接搬运了
            if [[ $bool_line_might_be_inside_class = true ]] || [[ $bool_line_might_be_other_class = true ]] ;then
                bool_line_might_be_inside_class=false
                bool_line_might_be_other_class=false
                #bool_finash_class_this_line=false
                ltmp_inside_class=false
                ltmp_other_class=false
            fi

            # 对于已经确定的,由于未看到结束符号,因此把";"当作空行或者一个project_name project_value写在了第二行的结束符号,无脑搬运且不改变状态
            echo "$line" >> "$temp_file"
            continue
        fi

        # 结束符号起始
        if [[ "$trimmed_line" == "}"* ]] || if [[ "$trimmed_line" == "};"* ]]; then
            # 清除一下这两个变量的状态,不确定的都已经确定或者无所谓了
            if [[ $bool_line_might_be_inside_class = true ]] || [[ $bool_line_might_be_other_class = true ]] ;then
                bool_line_might_be_inside_class=false
                bool_line_might_be_other_class=false
            fi
            
            bool_finash_class_this_line=true
            ltmp_inside_class=false
            ltmp_other_class=false

            echo "$line" >> "$temp_file"
            continue
        fi

        # 实锤
        if [[ "$trimmed_line" == "{"* ]] ; then
            if [[ $bool_line_might_be_other_class = true ]] ;then
                bool_line_might_be_other_class=false
                ltmp_other_class=true
            elif [[ $bool_line_might_be_inside_class = true ]];then
                bool_line_might_be_inside_class=false
                ltmp_inside_class=true
            else
                # 不能确定就还是搬运.
                echo "$line" >> "$temp_file"
            fi

            # 清除一下这两个变量的状态,不确定的都已经确定或者无所谓了
            if [[ $bool_line_might_be_inside_class = true ]] || [[ $bool_line_might_be_other_class = true ]] ;then
                bool_line_might_be_inside_class=false
                bool_line_might_be_other_class=false
            fi

            # 精神错乱
            if [[ $ltmp_other_class = true ]] && [[ $ltmp_inside_class = true ]];then
                log_message "因为工资少,所以工资多..." "ERROR"
                return 1
            fi
        fi

        ######################################################################################################################################
        # 在其他类内 无脑输出.遇到包含结束符的行就设置一下ltmp_other_class=false 以便下次循环不再进入此段
        if [ $ltmp_other_class = true ];then
            # 去掉注释
            ltmp_trimmed_line_without_comments=$(echo "$trimmed_line" | sed -E "s/$comment_regex//")

            # 如果本行结尾包含 }
            if [[ "$ltmp_trimmed_line_without_comments" == *"};" ]] || [[ "$ltmp_trimmed_line_without_comments" == *"}" ]] ; then
                bool_finash_class_this_line=true
                ltmp_other_class=false
            fi

            echo "$line" >> "$ltmp_temp_file"
            continue
        fi
        ######################################################################################################################################
        
        ######################################################################################################################################
        # 如果也不是在目标类中,就看看这行是啥
        if [[ $ltmp_inside_class = false ]]; then
            # 提取行首的字符串，直到遇到非字母数字字符、空格、制表符、左大括号或注释符号
            ltmp_first_str=$(echo "$trimmed_line" | sed -E "s/([[:alnum:]]+)([[:space:]]*{|}|$comment_regex|[[:alnum:]]).*/\1/")

            # 检查行首是否是 "ltmp_first_str;"（考虑空格和制表符）(这里主要是字符串后面紧跟分号的单行这种形式)
            if [[ "$trimmed_line" =~ [[:space:]]*"$ltmp_first_str"[[:space:]]*\; ]]; then
                # 行首是 "ltmp_first_str;"，不符合我们要找的类 
                # 如果类的定义有变化,即空白名字被视为未包含内容的类可以在这里修改代码
                # 如 classA ; 如果将来被视为等同 classA {};
                echo "Skipping line: $line"
                echo "$line" >> "$ltmp_temp_file"
                continue
            fi

            # 与目标类名不相同(其他类)
            if [[  "$ltmp_first_str" != "$ltmp_class_name" ]];then

                # 这时还不能确定是进入了类(非目标类)
                bool_line_might_be_other_class=true

                # 去掉类名后的部分，并去掉行首的空格
                remaining_line=$(echo "$trimmed_line" | sed -E "s/$ltmp_first_str[[:space:]]*//")

                # 去掉行尾的注释部分
                remaining_line_without_comments=$(echo "$remaining_line" | sed -E "s/$comment_regex//")
        
                # 检查剩余部分的第一个字符是否是注释符号或左大括号
                first_char=$(echo "$remaining_line" | head -c 1)

                # 不是被认为有实际意义(我们可以理解的)的内容就直接搬运了
                if [[ "$first_char" != "{" && "$remaining_line" =~ $comment_regex ]]; then
                    # 如果不是左大括号也不是注释，则继续下一行
                    echo "$line" >> "$ltmp_temp_file"
                    continue
                fi

                # 如果是左大括号，则标记为处于其他类(非目标类)定义内部
                if [[ "$first_char" == "{"  ]];then
                    #自信点,把"可能"去掉
                    bool_line_might_be_other_class=false
                    ltmp_other_class=true

                    echo "$line" >> "$ltmp_temp_file"

                    # 如果本行结尾包含 }, 则 ltmp_other_class=false 下次循环就不再继续处理.
                    if [[ "$remaining_line_without_comments" == *"};" ]] || [[ "$remaining_line_without_comments" == *"}" ]] ; then
                        bool_finash_class_this_line=true
                        ltmp_other_class=false
                    fi

                    # 清除一下这两个变量的状态,不确定的都已经确定或者无所谓了
                    if [[ $bool_line_might_be_inside_class = true ]] || [[ $bool_line_might_be_other_class = true ]] ;then
                        bool_line_might_be_inside_class=false
                        bool_line_might_be_other_class=false
                    fi

                    continue
                fi
                

            else
                # 与目标类名相同
                bool_line_might_be_inside_class=true

                # 去掉类名后的部分，并去掉行首的空格
                remaining_line=$(echo "$trimmed_line" | sed -E "s/$ltmp_first_str[[:space:]]*//")

                # 去掉行尾的注释部分
                remaining_line_without_comments=$(echo "$remaining_line" | sed -E "s/$comment_regex//")

                # 检查剩余部分的第一个字符是否是注释符号或左大括号
                first_char=$(echo "$remaining_line" | head -c 1)

                # 不是被认为有实际意义(我们可以理解的)的内容就直接搬运了
                if [[ "$first_char" != "{" && "$remaining_line" =~ $comment_regex ]]; then
                    # 如果不是左大括号也不是注释，则继续下一行
                    echo "$line" >> "$ltmp_temp_file"
                    continue
                fi
            
                # 如果是左大括号，则标记为处于目标类定义内部
                if [[ "$first_char" == "{"  ]];then
                    #自信点,把"可能"去掉
                    bool_line_might_be_inside_class=false
                    ltmp_inside_class=true
                fi

                # ?????
                # 如果本行结尾包含 }, 则 ltmp_other_class=false 下次循环就不再继续处理.
                if [[ "$remaining_line_without_comments" == *"};" ]] || [[ "$remaining_line_without_comments" == *"}" ]] ; then
                    bool_finash_class_this_line=true
                    ltmp_other_class=false
                fi

                # 检查该行末尾是否以右大括号结束
                # if [[ "$remaining_line_without_comments" =~ \}$ ]] || [[ "$remaining_line_without_comments" =~ \};$ ]]; then
                #     # 如果是右大括号，则输出到新行，并保持注释部分不变
                #     #echo "${trimmed_line%%}*" | sed -E "s/.*}//}" > "new_line.txt"
                #     # 标记为不再处于类定义内部
                #     bool_line_might_be_other_class=false
                #     ltmp_other_class=false
                # fi

                echo "$line" >> "$ltmp_temp_file"

                
            fi

        fi
        ######################################################################################################################################

        ######################################################################################################################################
        # 检查是否处于指定的类定义内部
        if $ltmp_inside_class; then            
            if [[ "$line" != "};" ]] && [[ "$line" != "}" ]] ; then

                # 提取行首的项目名（假设项目名后面紧跟一个空格或连接符）
                ltmp_current_project_name=$(echo "$line" | awk '{print $1}')

                # 去除项目名末尾的空格（如果有的话）
                ltmp_current_project_name=$(echo "$ltmp_current_project_name" | sed 's/[[:space:]]*$//')

                # 去掉类名后的部分，并去掉行首的空格
                remaining_line_intp=$(echo "$trimmed_line" | sed -E "s/$ltmp_first_str[[:space:]]*//")

                # 去掉行尾的注释部分
                remaining_line_without_comments_intp=$(echo "$remaining_line_intp" | sed -E "s/$comment_regex//")
                
                # 找到project_name
                if [[ "$ltmp_current_project_name" == "$ltmp_item_name" ]]; then
                    echo "      ${ltmp_item_name}${ltmp_connector}${ltmp_item_value};" >> "$ltmp_temp_file"
                    ltmp_project_added=true

                # 如果本行原文结尾包含 }, 则 ltmp_inside_class=false 下次循环就不再继续处理.
                elif [[ "$remaining_line_without_comments_intp" == *"};" ]] || [[ "$remaining_line_without_comments_intp" == *"}" ]] ; then
                    
                    # 搬运
                    echo "$line" >> "$ltmp_temp_file"

                    # 既然包含注释,项目也已经输出,就补一个类结束标记.
                    if $ltmp_endsemi; then
                        echo "};" >> "$ltmp_temp_file"
                    else
                        echo "}" >> "$ltmp_temp_file"
                    fi

                    bool_finash_class_this_line=true
                    ltmp_inside_class=false               
                else
                    echo "$line" >> "$ltmp_temp_file"
                fi
            else
                # 已经在要操作的类内部,到最后还没找到项目,就该添加了.
                if ! $ltmp_project_added; then
                    # 替换或添加项目行
                    echo "      ${ltmp_item_name}${ltmp_connector}${ltmp_item_value};"
                    echo "      ${ltmp_item_name}${ltmp_connector}${ltmp_item_value};" >> "$ltmp_temp_file"
                    ltmp_project_added=true
                fi
                
                # 其实这行是原类定义的结束标志,这里搬运一下
                echo "$line" >> "$ltmp_temp_file"
                # 类结束，重置标记，并输出类结束符号
                ltmp_inside_class=false
            fi
            
        fi

        
    done < "$ltmp_file_path"

    # 如果在整个文件中都没有添加或修改过项目就新建
    
    if [ $ltmp_project_added = false ]; then
        #echo_double_line
        #echo "File is end ,and find no class ,now add it."
        #echo_double_line
        #echo "${ltmp_class_name} {"
        echo "${ltmp_class_name} {" >> "$ltmp_temp_file"

        #echo "      ${ltmp_item_name}${ltmp_connector}${ltmp_item_value};"
        echo "      ${ltmp_item_name}${ltmp_connector}${ltmp_item_value};" >> "$ltmp_temp_file"
        
        if $ltmp_endsemi; then
            #echo "};"
            echo "};" >> "$ltmp_temp_file"
        else
            #echo "}"
            echo "}" >> "$ltmp_temp_file"
        fi

        #echo ""
        echo "" >> "$ltmp_temp_file" # 添加空行以分隔类
    fi

    # 替换原文件
    mv "$ltmp_temp_file" "$ltmp_file_path"

}


touch "/home/pangu/testP.txt"
    # 在调用 write_class_file 函数之前设置支持的注释符号
    comment_symbol_array=("#" "//")
    write_class_file "/home/pangu/java.txt" "classA" "item1" "valueofitem1" #--endsemi --useeq
    write_class_file "/home/pangu/java.txt" "classB" "item2" "valueofitem2"
    write_class_file "/home/pangu/java.txt" "classC" "item3" "valueofitem3"
    write_class_file "/home/pangu/java.txt" "classC" "item4" "valueofitem4"
    write_class_file "/home/pangu/java.txt" "classC" "item5" "value1ofitem5 value2ofitem5 value3ofitem5"
