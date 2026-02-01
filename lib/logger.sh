#!/bin/bash
#################################################################################################
# 日志模块（已清理）：提供向后兼容的日志函数
#################################################################################################

# 加载依赖
_logger_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_logger_dir}/config.sh" 2>/dev/null || true
source "${_logger_dir}/constants.sh" 2>/dev/null || true

# 安全默认值（避免被作为模块 source 时缺少外部变量导致 set -u 报错）
this_LOG_DIR="${this_LOG_DIR:-${_logger_dir}/../logs}"
this_LOG_FILE="${this_LOG_FILE:-${this_LOG_DIR}/deploy.log}"
this_b_trace="${this_b_trace:-false}"
this_b_debug="${this_b_debug:-false}"

# 确保 LOG_LEVEL_COLORS 是已声明的关联数组（不覆盖已有定义）
if ! declare -p LOG_LEVEL_COLORS >/dev/null 2>&1; then
    declare -A LOG_LEVEL_COLORS
fi

#################################################################################################
# 初始化日志文件夹
#################################################################################################
init_log(){
    if [ ! -d "${this_LOG_DIR}" ]; then
        mkdir -p "${this_LOG_DIR}" || return 1
    fi
    return 0
}

#################################################################################################
# 查看调用链
#################################################################################################
show_who_call(){
    local ltmp_func_name=${FUNCNAME[0]:-main}
    local ltmp_func_name1=${FUNCNAME[1]:-}
    local ltmp_func_name2=${FUNCNAME[2]:-}
    local ltmp_func_name3=${FUNCNAME[3]:-}
    local ltmp_func_name4=${FUNCNAME[4]:-}
    local ltmp_func_name5=${FUNCNAME[5]:-}
    local ltmp_func_name6=${FUNCNAME[6]:-}
    local ltmp_func_name7=${FUNCNAME[7]:-}
    local ltmp_func_name8=${FUNCNAME[8]:-}
    local ltmp_func_name9=${FUNCNAME[9]:-}
    local ltmp_message="${1:-}"
    local ltmp_log_level="${2:-}"
    local ltmp_timestamp
    ltmp_timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    if [[ $# -le 1 ]]; then
        ltmp_log_level="DEBUG"
    fi

    if [[ "${this_b_trace}" = "false" ]] && [[ "${this_b_debug}" = "false" ]]; then
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】【$ltmp_log_level】【 $ltmp_message ::调用链 : $ltmp_func_name9 ->$ltmp_func_name8 ->$ltmp_func_name7 ->$ltmp_func_name6 ->$ltmp_func_name5 ->$ltmp_func_name4 ->$ltmp_func_name3 ->$ltmp_func_name2 ->$ltmp_func_name1】" >> "${this_LOG_FILE}"  2>&1
        return 0
    fi

    if [[ -n "${LOG_LEVEL_COLORS[$ltmp_log_level]:-}" ]]; then
        local ltmp_color="${LOG_LEVEL_COLORS[$ltmp_log_level]:-}"
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】【$ltmp_log_level】【 $ltmp_message ::调用链 : $ltmp_func_name9 ->$ltmp_func_name8 ->$ltmp_func_name7 ->$ltmp_func_name6 ->$ltmp_func_name5 ->$ltmp_func_name4 ->$ltmp_func_name3 ->$ltmp_func_name2 ->$ltmp_func_name1】" >> "${this_LOG_FILE}"
        echo -e "${ltmp_color}【$ltmp_timestamp】【$ltmp_func_name{}】【$ltmp_log_level】【 $ltmp_message ::调用链 : $ltmp_func_name9 ->$ltmp_func_name8 ->$ltmp_func_name7 ->$ltmp_func_name6 ->$ltmp_func_name5 ->$ltmp_func_name4 ->$ltmp_func_name3 ->$ltmp_func_name2 ->$ltmp_func_name1】${NC}"
    else
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】【$ltmp_log_level】【 $ltmp_message ::调用链 : $ltmp_func_name9 ->$ltmp_func_name8 ->$ltmp_func_name7 ->$ltmp_func_name6 ->$ltmp_func_name5 ->$ltmp_func_name4 ->$ltmp_func_name3 ->$ltmp_func_name2 ->$ltmp_func_name1】" | tee -a "${this_LOG_FILE}"
    fi
}

#################################################################################################
# 定义日志函数，同时输出到标准输出和日志文件
#################################################################################################
log_message(){
    local ltmp_func_name=${FUNCNAME[1]:-main}
    local ltmp_message=$1
    local ltmp_log_level="$2"
    local ltmp_timestamp
    ltmp_timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [ $# -eq 1 ]; then
        ltmp_log_level="INFO"
    fi
    show_who_call

    if [[ -n "${LOG_LEVEL_COLORS[$ltmp_log_level]:-}" ]]; then
        local ltmp_color="${LOG_LEVEL_COLORS[$ltmp_log_level]:-}"
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】" >> "${this_LOG_FILE}"
        echo -e "${ltmp_color}【$ltmp_timestamp】${GREEN}【$ltmp_func_name{}】${NC}:${ltmp_color}【$ltmp_log_level】${NC}:【 $ltmp_message 】"
    else
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】" | tee -a "${this_LOG_FILE}"
    fi
}

#################################################################################################
# 常规仅写日志,不输出到屏幕
# 当--trace 选项启用时,同时输出到屏幕
#################################################################################################
LOG_message(){
    local ltmp_func_name=${FUNCNAME[1]:-main}
    local ltmp_message=$1
    local ltmp_log_level="$2"
    local ltmp_timestamp
    ltmp_timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [ $# -eq 1 ]; then
        ltmp_log_level="INFO"
    fi

    if [ "$this_b_trace" = false ];then
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】" >> "${this_LOG_FILE}"  2>&1
        return 0
    fi

    if [[ -n "${LOG_LEVEL_COLORS[$ltmp_log_level]:-}" ]]; then
        local ltmp_color="${LOG_LEVEL_COLORS[$ltmp_log_level]:-}"
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】" >> "${this_LOG_FILE}"
        echo -e "${ltmp_color}【$ltmp_timestamp】${GREEN}【$ltmp_func_name{}】${NC}:${ltmp_color}【$ltmp_log_level】${NC}:【 $ltmp_message 】"
    else
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】" | tee -a "${this_LOG_FILE}"
    fi
}

#################################################################################################
# 仅写日志,不输出到屏幕
#################################################################################################
LOG_line(){
    local ltmp_func_name=${FUNCNAME[1]:-main}
    local ltmp_message=$1
    local ltmp_log_level="$2"
    local ltmp_timestamp
    ltmp_timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [ $# -eq 1 ]; then
        ltmp_log_level="INFO"
    fi

    echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】" >> "${this_LOG_FILE}"  2>&1
    return 0
}

#################################################################################################
# 仅输出到终端,不写日志文件
#################################################################################################
log_MESSAGE(){
    local ltmp_func_name=${FUNCNAME[1]:-main}
    local ltmp_message=$1
    local ltmp_log_level="$2"
    local ltmp_timestamp
    ltmp_timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [ $# -eq 1 ]; then
        ltmp_log_level="INFO"
    fi

    if [[ -n "${LOG_LEVEL_COLORS[$ltmp_log_level]:-}" ]]; then
        local ltmp_color="${LOG_LEVEL_COLORS[$ltmp_log_level]:-}"
        echo -e "${ltmp_color}【$ltmp_timestamp】${GREEN}【$ltmp_func_name{}】${NC}:${ltmp_color}【$ltmp_log_level】${NC}:【 $ltmp_message 】"
    else
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】"
    fi
}

#################################################################################################
# 简单兼容封装：常用级别的便捷函数
#################################################################################################
log_error(){
    log_message "$1" "ERROR"
}

log_warn(){
    log_message "$1" "WARN"
}

log_info(){
    log_message "$1" "INFO"
}

log_debug(){
    log_message "$1" "DEBUG"
}
#!/bin/bash
#################################################################################################
# 日志模块
#################################################################################################

# 加载依赖
_logger_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_logger_dir}/config.sh" 2>/dev/null || true
source "${_logger_dir}/constants.sh" 2>/dev/null || true

# 安全默认值（避免被作为模块 source 时缺少外部变量导致 set -u 报错）
this_LOG_DIR="${this_LOG_DIR:-${_logger_dir}/../logs}"
this_LOG_FILE="${this_LOG_FILE:-${this_LOG_DIR}/deploy.log}"
this_b_trace="${this_b_trace:-false}"
this_b_debug="${this_b_debug:-false}"
if ! declare -p LOG_LEVEL_COLORS >/dev/null 2>&1; then
    declare -A LOG_LEVEL_COLORS
fi

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
    local ltmp_func_name=${FUNCNAME[0]:-main}
    local ltmp_func_name1=${FUNCNAME[1]:-}
    local ltmp_func_name2=${FUNCNAME[2]:-}
    local ltmp_func_name3=${FUNCNAME[3]:-}
    local ltmp_func_name4=${FUNCNAME[4]:-}
    local ltmp_func_name5=${FUNCNAME[5]:-}
    local ltmp_func_name6=${FUNCNAME[6]:-}
    local ltmp_func_name7=${FUNCNAME[7]:-}
    local ltmp_func_name8=${FUNCNAME[8]:-}
    local ltmp_func_name9=${FUNCNAME[9]:-}
    local ltmp_message="${1:-}"
    local ltmp_log_level="${2:-}"
    local ltmp_timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    if [[ $# -le 1 ]]; then
        ltmp_log_level="DEBUG"
    fi

    if [[ "$this_b_trace" = "false" ]] && [[ "$this_b_debug" = "false" ]]; then
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
    local ltmp_func_name=${FUNCNAME[1]:-main}
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
    local ltmp_func_name=${FUNCNAME[1]:-main}
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
    local ltmp_func_name=${FUNCNAME[1]:-main}
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
    local ltmp_func_name=${FUNCNAME[1]:-main}
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

#################################################################################################
# 简单兼容封装：常用级别的便捷函数
#################################################################################################
log_error(){
    log_message "$1" "ERROR"
}

log_warn(){
    log_message "$1" "WARN"
}

log_info(){
    log_message "$1" "INFO"
}

log_debug(){
    log_message "$1" "DEBUG"
}
