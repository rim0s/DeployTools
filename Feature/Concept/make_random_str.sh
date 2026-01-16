#!/bin/bash
#get_random_str(){
    # 设置随机字符串的长度
    ltmp_LENGTH=$1

    if [ -z "$ltmp_LENGTH" ];then
        ltmp_LENGTH=16
    fi

    # 定义字符集，包含字母（大小写）和数字
     CHARSET="a-zA-Z0-9"

    # 从/dev/urandom生成随机字节，并通过tr命令过滤成指定字符集的字符
    # 使用head和tail命令来确保只获取所需长度的字符
     random_string=$(cat /dev/urandom | tr -cd "$CHARSET" | head -c $ltmp_LENGTH)
    
    echo "$random_string"

#}