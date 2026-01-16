#!/bin/bash
#################################################################################################
# 初始化模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/utils.sh" 2>/dev/null || source "./lib/utils.sh"

#################################################################################################
# 检查当前解释器是否为 Bash
#################################################################################################
check_bash_interpreter() {
    if [ -z "$BASH_VERSION" ]; then
        echo "此脚本需要使用 Bash 解释器运行。"
        echo "正在尝试使用 Bash 重新启动脚本..."

        # 获取脚本的名称
        G_SCRIPT="$0"

        # 如果脚本是通过相对路径或符号链接运行的，解析出实际路径
        while [ -h "$G_SCRIPT" ]; do
            # 解析符号链接
            LINK=$(readlink "$G_SCRIPT")
            if [[ $LINK == /* ]]; then
                # 绝对符号链接
                G_SCRIPT="$LINK"
            else
                # 相对符号链接
                G_SCRIPT="$(dirname "$G_SCRIPT")/$LINK"
            fi
        done

        # 获取脚本所在的目录
        SCRIPT_DIR=$(dirname "$G_SCRIPT")
        # 获取脚本的文件名
        SCRIPT_NAME=$(basename "$G_SCRIPT")

        # 使用 Bash 重新启动脚本
        exec bash "$SCRIPT_DIR/$SCRIPT_NAME" "$@"
        # 如果 exec 失败，下面的代码将不会执行
        exit 1
    fi
}

#################################################################################################
# 初始化TMP文件夹
#################################################################################################
init_tmp(){
    if [ ! -d "${this_TMP_DIR}" ]; then
        mkdir -p "${this_TMP_DIR}"
        local ltmp_ret_init_tmp=$?
        case $ltmp_ret_init_tmp in
            0)
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    else
        return 0
    fi
}

#################################################################################################
# 初始化脚本环境
#################################################################################################
init_the_batch(){
    # 首先检查Bash解释器
    check_bash_interpreter
    
    show_who_call
    
    # 检查是否已经初始化
    if [ ${this_b_init} = true ];then
        return 0
    fi
    
    this_b_init=true
    
    # 获取父进程信息
    if [ -n "$PPID" ]; then
        local parent_script_name=$(ps -o comm= -p $PPID)
        local parent_script_dir=$(dirname $(readlink /proc/$PPID/exe 2>/dev/null || echo ""))
        local parent_script_command=$(ps -o args= -p $PPID)
        log_message "This script was called by $parent_script_name located at $parent_script_dir with command: $parent_script_command"
        log_message "本脚本调用自 $parent_script_name ,其所在目录 $parent_script_dir 父脚本完整命令: $parent_script_command"
    fi
    
    # 初始化临时文件夹,日志文件夹
    init_tmp
    init_log
    
    # 获取终端宽度
    term_width=$(tput cols)
    
    # 运行环境信息
    LOG_message "用户 $this_username 运行了脚本文件 : $BASH_SOURCE" "INFO"
    LOG_message "运行的脚本文件及参数 : $BASH_SOURCE $@" "INFO"   
    
    # 获取当前系统的包管理器
    which_app_manager
    
    # 未输入任何参数则显示 usage 内容
    if [ $# -eq 0 ]; then
       print_help
       end_the_batch
    fi
    
    # 如果参数是 -h 或 --help 则不显示 BANNER
    local string_t=$@
    local find_str1_="help"
    local find_str2_="\bh\b"
    
    echo $@ | grep -q  "${find_str1_}" 
    local grep1_ret=$?
    
    case $grep1_ret in
        0)
            this_show_start_end_timestamp=false
            ;;
        *)
            echo $@ | grep -q  "${find_str2_}" 
            local grep2_ret=$?
            case $grep2_ret in
                0)
                    this_show_start_end_timestamp=false
                    ;;
                *)
                    this_show_start_end_timestamp=true
                    ;;
            esac
            ;;
    esac
        
    # 显示Banner信息
    if [ ${this_show_start_end_timestamp} == true ];then
        show_banner
        log_MESSAGE "bash_start." "INFO"
        log_message "运行的脚本及参数为 $0 $this_GLOBAL_PARAMETER "
    fi
    
    # 获取操作系统版本情况
    check_which_os_release
}

#################################################################################################
# 结束脚本时做的工作
#################################################################################################
end_the_batch(){
    show_who_call
    
    # 删除临时文件夹内的文件
    rm -vf ${this_TMP_DIR}/tmp_sudo_pass_input.sh 2>/dev/null
    
    # 显示tail_banner
    local ltmp_bash_end_timestamp=$(date +%Y%m%d-%H%M%S)
    
    if [ ${this_show_start_end_timestamp} == true ];then
        if [ ${this_b_trace} = false ];then  
            log_MESSAGE "bash_finish." "INFO"
        fi
    fi
    
    if [ ${this_b_trace} = false ];then
        show_tail
    fi
    
    # 清理临时文件夹
    if [ ${this_b_trace} = false ];then
        LOG_message "清理脚本运行时生成的临时文件... ..." "WARNING"
        local ltmp_output2_of_rm=$(rm -rvf "$this_TMP_DIR" 2>&1)
        local ltmp_RET_DEL=$?
        case "$ltmp_RET_DEL" in
            0)
                LOG_message "Deleted direcory 【 $this_TMP_DIR 】SUCESS,RETCODE=$ltmp_RET_DEL." "WARNING"
                ;;
            *)
                LOG_message "Deleting direcory 【 $this_TMP_DIR 】FAIL,RETCODE=$ltmp_RET_DEL." "WARNING"
                ;;
        esac
    else
        LOG_message " \"--trace\" 参数被使用.或脚本的\"this_b_trace\"值为 \"true\" 【清理脚本运行时生成的临时文件】已被取消." "WARNING"
    fi
    
    # 运行时间统计
    local ltmp_end_time=$(date +%s)
    local ltmp_cost_time=$[$ltmp_end_time - $this_start_bash_time]
    LOG_message "脚本执行耗时约为 : $ltmp_cost_time 秒." "INFO"
    
    # 结束时间戳
    ltmp_bash_end_timestamp=$(date +%Y%m%d-%H%M%S)
    LOG_message "Bash_end at ${ltmp_bash_end_timestamp}" "INFO"
    
    # --trace 选项开启后,在真正退出脚本前输入 tail
    if [ ${this_b_trace} == true ];then
        show_tail
    fi
    
    # 终端响铃
    ${functions[random_index]}
    
    # 完全结束脚本
    exit 0
}
