#!/bin/bash
#################################################################################################
# 调试模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/banner.sh" 2>/dev/null || source "./lib/banner.sh"
source "$(dirname "$0")/sudo.sh" 2>/dev/null || source "./lib/sudo.sh"

#################################################################################################
# 运行命令（调试模式下需用户确认）
#################################################################################################
run_command(){
    local ltmp_command=$1
    local ltmp_ys_or_no
    local ltmp_pwd_
    this_b_trace=true

    while true;do
        show_tail
        # \033[1A 回到上一行行首
        echo -e "\033[1A    Your command is :${RED} $ltmp_command.${NC}
    Will you run it? 
    Please Type ${RED} \"yes\" ${NC}or${GREEN} \"no\" ${NC}."
        echo -e "       ${RED}回车${NC} = ${RED}YES${NC} = ${RED}yes${NC} = ${RED}y${NC} "
        echo -e "       ${GREEN}其他输入${NC} = ${GREEN}NO${NC} = ${GREEN}no${NC} = ${GREEN}n${NC} "
        show_tail
        ltmp_pwd_="$this_script_name is Debuging. PWD = $(pwd). DEBUG-->run_command
Answer >"
        read  -p "$ltmp_pwd_"  ltmp_ys_or_no

        case $ltmp_ys_or_no in 
            "y"|"yes"|"YES")
                show_tail
                log_message "用户确认了命令 [ $ltmp_command ] 需执行,执行开始... ..." "DEBUG"
                unsudo_execute "$ltmp_command"
                return 0
                ;;
            "n"|"NO"|"no")
                show_tail
                log_message "用户否决了命令 [ $ltmp_command ] 的执行" "DEBUG"
                show_tail
                return 1
                ;;
            "")
                show_tail
                log_message "用户确认了命令 [ $ltmp_command ] 需执行,执行开始... ..." "DEBUG"
                unsudo_execute "$ltmp_command"
                return 0
                ;;
            *)
                log_message "用户否决了命令 [ $ltmp_command ] 的执行" "DEBUG"
                show_tail
                return 0
                ;;
        esac
    done
    return 0
}

#################################################################################################
# 结束调试
#################################################################################################
end_debug(){
    # 结束debug

    # 关闭 trace
    this_b_trace=false

    local ltmp_return="return 0"
    return $ltmp_return

    this_b_end_debug=true
}

#################################################################################################
# 断点使用说明
#################################################################################################
bp_usage(){
    
    echo -ne "${GREEN}
    --debug         ${NC}调试模式,此模式用以调试和测试.支持断点等调试常用功能.具体方法如下:
                    代码内插入 bp 或 breakpoint,然后附加 --debug参数来执行程序.
                    程序会在 bp 或 breakpoint 处停止执行等待用户输入,此时可输入各种命令以继续调试.
                    此模式下:${GREEN}
                    o q 或 quit : ${NC}退出脚本程序${GREEN}
                    o show_all  : ${NC}查看目前所有 局部 和 全局 变量${GREEN}
                    o show_this_all : ${NC}查看目前所有 全局 变量${GREEN}
                    o show_ltmp_all : ${NC}查看目前所有 局部 变量${GREEN}
                    o who_call 或 who call : ${NC}查看调用链(脚本目前的推展中函数调用关系)${GREEN}
                    o trace_run 或 trace run : ${NC}开启追踪模式(最大化输出,且保留临时文件)并继续执行脚本${GREEN}
                    o run : ${NC}继续执行脚本,且追踪模式会被关闭.即 --trace 选项被关闭${GREEN}
                    o ex 【 任意命令 ${BLUE}命令的参数${GREEN} 】: ${NC}ex 后跟命令可执行命令. 如 \"ex ls -lh\"${PINK}
                    待编辑...${PINK}"
}

#################################################################################################
# 断点函数,在代码任意行独立使用 bp 或 breakpoint 则可以使用本方法以调试
#################################################################################################
bp(){
    #断点,当 this_b_debug 变量值为 true 时触发,等待输入并据其进行进一步操作.
    if [ ! ${this_b_debug} == true ];then
        return 0
    fi

    # 开启trace
    this_b_trace=true

    local ltmp_pwd_
    local ltmp_wait_input
    b_finish=false

    while true;do
        log_message "【 $this_script_name 】:【 PWD = $(pwd)】"
        show_tail
        bp_usage
        echo 
        ltmp_pwd_="Debug >"
        read  -p "$ltmp_pwd_ " ltmp_wait_input
        case $ltmp_wait_input in 
            "q"|"quit")
                show_tail
                end_the_batch
                ;;
            "show_all")
                echo -e "${NC}"
                show_tail
                set | grep -E '^(this|ltmp)'
                ;;
            "show_this_all")
                echo -e "${NC}"
                show_tail
                set | grep -E '^this'
                ;;
            "show_ltmp_all")
                echo -e "${NC}"
                show_tail
                set | grep -E '^ltmp'
                ;;
            "who_call"|"who call")
                echo -e "${NC}"
                show_tail
                show_who_call
                show_tail
                ;;
            "trace_run"|"trace run")
                echo -e "${NC}"
                show_tail
                this_b_trace=true
                return 0
                ;;
            "run")
                echo -e "${NC}"
                show_tail
                this_b_trace=false
                return 0
                ;;
            *)
                local ltmp_find_str_ex="\bex"
                echo $ltmp_wait_input |grep  -q "$ltmp_find_str_ex"
                local grep_ex_ret=$?
                local ltmp_str_ex_="ex"
                if [ $grep_ex_ret -eq 0 ];then
                    local ltmp_commend2=${ltmp_wait_input#*$ltmp_str_ex_ }
                    run_command "$ltmp_commend2"
                else
                    echo 该命令未曾定义.
                fi
                ;;
        esac
    done 
}

#################################################################################################
# 断点,为了便于阅读和理解
#################################################################################################
breakpoint(){
    #断点
    bp
}
