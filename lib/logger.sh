#!/bin/bash
#################################################################################################
# 日志模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/constants.sh" 2>/dev/null || source "./lib/constants.sh"

#################################################################################################
# 初始化日志文件夹
#################################################################################################
init_log(){
    if [ ! -d "${this_LOG_DIR}" ]; then
        mkdir -p "${this_LOG_DIR}"
        local ltmp_ret_init_log=$?
        case $ltmp_ret_init_log in
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
# 查看调用链
#################################################################################################
show_who_call(){
    local ltmp_func_name=${FUNCNAME[0]}
    local ltmp_func_name1=${FUNCNAME[1]}
    local ltmp_func_name2=${FUNCNAME[2]}
    local ltmp_func_name3=${FUNCNAME[3]}
    local ltmp_func_name4=${FUNCNAME[4]}
    local ltmp_func_name5=${FUNCNAME[5]}
    local ltmp_func_name6=${FUNCNAME[6]}
    local ltmp_func_name7=${FUNCNAME[7]}
    local ltmp_func_name8=${FUNCNAME[8]}
    local ltmp_func_name9=${FUNCNAME[9]}
    local ltmp_message=$1
    local ltmp_log_level="$2"
    local ltmp_timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [ $# -eq 1 ]; then
        ltmp_log_level="DEBUG"
    fi

    if [ $# -eq 0 ];then
        ltmp_log_level="DEBUG"
    fi

    if [ $this_b_trace = false ] && [ $this_b_debug = false ];then
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】【$ltmp_log_level】【 $ltmp_message ::调用链 : $ltmp_func_name9 ->$ltmp_func_name8 ->$ltmp_func_name7 ->$ltmp_func_name6 ->$ltmp_func_name5 ->$ltmp_func_name4 ->$ltmp_func_name3 ->$ltmp_func_name2 ->$ltmp_func_name1】" >> "$this_LOG_FILE"  2>&1
        return 0
    fi 

    if [[ -n "${LOG_LEVEL_COLORS[$ltmp_log_level]}" ]]; then
        local ltmp_color="${LOG_LEVEL_COLORS[$ltmp_log_level]}"
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】【$ltmp_log_level】【 $ltmp_message ::调用链 : $ltmp_func_name9 ->$ltmp_func_name8 ->$ltmp_func_name7 ->$ltmp_func_name6 ->$ltmp_func_name5 ->$ltmp_func_name4 ->$ltmp_func_name3 ->$ltmp_func_name2 ->$ltmp_func_name1】" >> "$this_LOG_FILE"
        echo -e "${ltmp_color}【$ltmp_timestamp】【$ltmp_func_name{}】【$ltmp_log_level】【 $ltmp_message ::调用链 : $ltmp_func_name9 ->$ltmp_func_name8 ->$ltmp_func_name7 ->$ltmp_func_name6 ->$ltmp_func_name5 ->$ltmp_func_name4 ->$ltmp_func_name3 ->$ltmp_func_name2 ->$ltmp_func_name1】${NC}" 
    else
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】【$ltmp_log_level】【 $ltmp_message ::调用链 : $ltmp_func_name9 ->$ltmp_func_name8 ->$ltmp_func_name7 ->$ltmp_func_name6 ->$ltmp_func_name5 ->$ltmp_func_name4 ->$ltmp_func_name3 ->$ltmp_func_name2 ->$ltmp_func_name1】" | tee -a "$this_LOG_FILE"
    fi
}

#################################################################################################
# 定义日志函数，同时输出到标准输出和日志文件
#################################################################################################
log_message(){
    local ltmp_func_name=${FUNCNAME[1]}
    local ltmp_message=$1
    local ltmp_log_level="$2"
    local ltmp_timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [ $# -eq 1 ]; then
        ltmp_log_level="INFO"
    fi
    show_who_call
    
    if [[ -n "${LOG_LEVEL_COLORS[$ltmp_log_level]}" ]]; then
        local ltmp_color="${LOG_LEVEL_COLORS[$ltmp_log_level]}"
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】" >> "$this_LOG_FILE"
        echo -e "${ltmp_color}【$ltmp_timestamp】${GREEN}【$ltmp_func_name{}】${NC}:${ltmp_color}【$ltmp_log_level】${NC}:【 $ltmp_message 】" 
    else
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】" | tee -a "$this_LOG_FILE"
    fi
}

#################################################################################################
# 常规仅写日志,不输出到屏幕
# 当--trace 选项启用时,同时输出到屏幕
#################################################################################################
LOG_message(){
    local ltmp_func_name=${FUNCNAME[1]}
    local ltmp_message=$1
    local ltmp_log_level="$2"
    local ltmp_timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [ $# -eq 1 ]; then
        ltmp_log_level="INFO"
    fi

    if [ $this_b_trace = false ];then
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】" >> "$this_LOG_FILE"  2>&1
        return 0
    fi 

    if [[ -n "${LOG_LEVEL_COLORS[$ltmp_log_level]}" ]]; then
        local ltmp_color="${LOG_LEVEL_COLORS[$ltmp_log_level]}"
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】" >> "$this_LOG_FILE"
        echo -e "${ltmp_color}【$ltmp_timestamp】${GREEN}【$ltmp_func_name{}】${NC}:${ltmp_color}【$ltmp_log_level】${NC}:【 $ltmp_message 】" 
    else
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】" | tee -a "$this_LOG_FILE"
    fi
}

#################################################################################################
# 仅写日志,不输出到屏幕
#################################################################################################
LOG_line(){
    local ltmp_func_name=${FUNCNAME[1]}
    local ltmp_message=$1
    local ltmp_log_level="$2"
    local ltmp_timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [ $# -eq 1 ]; then
        ltmp_log_level="INFO"
    fi

    echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】" >> "$this_LOG_FILE"  2>&1
    return 0
}

#################################################################################################
# 仅输出到终端,不写日志文件
#################################################################################################
log_MESSAGE(){
    local ltmp_func_name=${FUNCNAME[1]}
    local ltmp_message=$1
    local ltmp_log_level="$2"
    local ltmp_timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [ $# -eq 1 ]; then
        ltmp_log_level="INFO"
    fi

    if [[ -n "${LOG_LEVEL_COLORS[$ltmp_log_level]}" ]]; then
        local ltmp_color="${LOG_LEVEL_COLORS[$ltmp_log_level]}"
        echo -e "${ltmp_color}【$ltmp_timestamp】${GREEN}【$ltmp_func_name{}】${NC}:${ltmp_color}【$ltmp_log_level】${NC}:【 $ltmp_message 】" 
    else
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】" 
    fi
}
