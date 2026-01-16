#!/bin/bash
#################################################################################################
# 工具函数模块
#################################################################################################

# 加载常量
source "$(dirname "$0")/constants.sh" 2>/dev/null || source "./lib/constants.sh"
# 加载logger（某些函数需要）
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh" 2>/dev/null || true

#################################################################################################
# 输出分隔线函数
#################################################################################################
echo_sharp_line() {
    echo "##########################################################################"
}

echo_double_line() {
    echo "=========================================================================="
}

echo_low_line() {
    echo "__________________________________________________________________________"
}

echo_mid_line() {
    echo "--------------------------------------------------------------------------"
}

#################################################################################################
# 字符串处理函数
#################################################################################################
trim_with_sed() {
    echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

trim_with_awk() {
    echo "$1" | awk '{gsub(/^[[:space:]]+|[[:space:]]+$/,"")}1'
}

trim_with_bash() {
    local trimmed="${1#"${1%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    echo "$trimmed"
}

trim() {
    local var="$1"
    trim_with_awk "$var"
}

#################################################################################################
# 随机字符串生成
#################################################################################################
get_random_str(){
    local ltmp_LENGTH=$1
    if [ -z "$ltmp_LENGTH" ];then
        ltmp_LENGTH=16
    fi
    local CHARSET="a-zA-Z0-9"
    local random_string=$(cat /dev/urandom | tr -cd "$CHARSET" | head -c $ltmp_LENGTH)
    echo "$random_string"
}

#################################################################################################
# 终端响铃函数
#################################################################################################
fn_run_bel1() {
    echo -e "\a"
}

fn_run_bel2() {
    tput bel
}

fn_run_bel3() {
    printf '\a'
}

#################################################################################################
# 检查系统是否支持中文显示
#################################################################################################
check_chinese_support() {
    local output=$(locale -a 2>/dev/null | grep -i 'zh_CN')
    if [ -n "$output" ]; then
        echo "系统支持中文显示。"
        return 0
    else
        echo "系统不支持中文显示。"
        return 1
    fi
}

#################################################################################################
# 带日志记录的删除文件函数
#################################################################################################
delete_file(){
    local ltmp_del_file=$1
    local ltmp_func_name=${FUNCNAME[0]}
    local ltmp_delete_file_timestamp=$(date +%Y%m%d-%H%M%S)
    local ltmp_error_output_file=${this_TMP_DIR}/${ltmp_func_name}_output_tmp_${ltmp_delete_file_timestamp}.tmp
    
    LOG_message "Deleting file 【 $ltmp_del_file 】 " "WARNING"
    
    if [ ${this_b_trace} == true ];then
        log_message "TRACE is ${this_b_trace},file $ltmp_del_file will not be deleted." "TRACE"
    else
        local ltmp_output_of_rm=$(rm -vf "$ltmp_del_file" 2>$ltmp_error_output_file)
        local ltmp_RET_DEL=$?
        case "$ltmp_RET_DEL" in
            0)
                LOG_message "Deleted file 【 $ltmp_del_file 】SUCESS,RETCODE=$ltmp_RET_DEL." "WARNING"
                ;;
            *)
                LOG_message "Deleting file 【 $ltmp_del_file 】FAIL,RETCODE=$ltmp_RET_DEL." "WARNING"
                ;;
        esac
        rm -f "$ltmp_error_output_file" 2>/dev/null
    fi
    return $ltmp_RET_DEL
}

#################################################################################################
# 检查操作系统版本
#################################################################################################
check_which_os_release(){
    show_who_call 2>/dev/null || true
    # 读取/etc/os-release文件
    if [ ! -f /etc/os-release ]; then
        log_message "无法找到 /etc/os-release 文件。" "WARNING" 2>/dev/null || echo "无法找到 /etc/os-release 文件。"
        return 1
    fi

    # 读取操作系统信息（避免变量冲突）
    local ltmp_os_name=$(grep "^NAME=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    local ltmp_os_version=$(grep "^VERSION_ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"' 2>/dev/null || echo "unknown")
    local ltmp_os_id=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')

    # 显示发行版和版本号
    log_message "发行版: $ltmp_os_name" "INFO" 2>/dev/null || echo "发行版: $ltmp_os_name"
    log_message "版本号: $ltmp_os_version" "INFO" 2>/dev/null || echo "版本号: $ltmp_os_version"

    # 操作系统品牌
    this_os_release_logo_name="$ltmp_os_id"

    # 判断是桌面操作系统还是服务器操作系统
    case "$ltmp_os_id" in
        ubuntu|debian|linuxmint)
            log_message "类型: 桌面操作系统" "INFO" 2>/dev/null || echo "类型: 桌面操作系统"
            this_os_release_type="workstation"
            ;;
        centos|rhel|fedora|almalinux|rockylinux)
            log_message "类型: 服务器操作系统" "INFO" 2>/dev/null || echo "类型: 服务器操作系统"
            log_message "CentOS、RHEL、Fedora、AlmaLinux和Rocky Linux通常按服务器版处理，即便是workstation版。" "INFO" 2>/dev/null || true
            this_os_release_type="server"
            ;;
        opensuse|suse)
            if [[ "$ltmp_os_version" == *"Leap"* ]] || [[ "$ltmp_os_name" == *"Enterprise"* ]]; then
                log_message "类型: 服务器操作系统" "INFO" 2>/dev/null || echo "类型: 服务器操作系统"
                this_os_release_type="server"
            else
                log_message "类型: 桌面操作系统" "INFO" 2>/dev/null || echo "类型: 桌面操作系统"
                this_os_release_type="workstation"
            fi
            ;;
        kylin)
            if [[ "$ltmp_os_version" == *"Leap"* ]] || [[ "$ltmp_os_name" == *"Server"* ]]; then
                log_message "类型: kylin 服务器操作系统. (kylin 是 银河麒麟操作系统的品牌名称)" "INFO" 2>/dev/null || echo "类型: kylin 服务器操作系统"
                this_os_release_type="server"
            else
                log_message "类型: kylin 桌面操作系统. (kylin 是 银河麒麟操作系统的品牌名称)" "INFO" 2>/dev/null || echo "类型: kylin 桌面操作系统"
                this_os_release_type="desktop"
            fi
            ;;
        uos)
            local ltmp_distrib_desc=$(grep "^DISTRIB_DESCRIPTION=" /etc/lsb-release 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "")
            if [[ "$ltmp_distrib_desc" == *"Server"* ]] || [[ "$ltmp_os_name" == *"Server"* ]]; then
                log_message "类型: uos 服务器操作系统. (UOS 是 统信操作系统的品牌名称)" "INFO" 2>/dev/null || echo "类型: uos 服务器操作系统"
                this_os_release_type="server"
            else
                log_message "类型: uos 桌面操作系统. (UOS 是 统信操作系统的品牌名称)" "INFO" 2>/dev/null || echo "类型: uos 桌面操作系统"
                this_os_release_type="desktop"
            fi
            ;;
        nfsdesktop)
            log_message "类型: NFS 桌面操作系统.(NFS 是 中科方德操作系统的品牌名称)" "INFO" 2>/dev/null || echo "类型: NFS 桌面操作系统"
            this_os_release_type="desktop"
            ;;
        NFS)
            log_message "类型: NFS 服务器操作系统.(NFS 是 中科方德操作系统的品牌名称)" "INFO" 2>/dev/null || echo "类型: NFS 服务器操作系统"
            this_os_release_type="server"
            ;;
        *)
            log_message "类型: 未知" "INFO" 2>/dev/null || echo "类型: 未知"
            this_os_release_type="unknown"
            ;;
    esac

    # 额外的判断可以基于特定的环境变量或文件
    if [ -f /etc/lsb-release ]; then
        local ltmp_distrib_desc=$(grep "^DISTRIB_DESCRIPTION=" /etc/lsb-release 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "")
        case "$ltmp_distrib_desc" in
            *"Server"*)
                log_message "（根据 /etc/lsb-release，这是一台服务器操作系统）" "INFO" 2>/dev/null || true
                ;;
            *"Workstation"*)
                log_message "（根据 /etc/lsb-release，这是一台工作站操作系统）" "INFO" 2>/dev/null || true
                ;;
            *"Desktop"*)
                log_message "（根据 /etc/lsb-release，这是一台桌面操作系统）" "INFO" 2>/dev/null || true
                ;;
        esac
    fi

    return 0
}
