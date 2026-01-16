#!/bin/bash
############################################################
# It's a mess, but it works well.
############################################################
# 全局变量用 this_ 前缀
# 局部变量用 ltmp_ 前缀,local 声明.
# 当作静态使用的动态变量不遵循上述前缀要求
# 用于判断程序返回结果的变量可以不循循上述前缀要求.
# 未遵循上面原则的部分,是从AI拷贝过来还没来得及优化的代码
############################################################

this_bash_start_timestamp=$(date +%Y%m%d-%H%M%S)
this_start_bash_time=$(date +%s)
this_b_base64support=false
this_b_network_promision=false 

#获取当前脚本的文件名不含路径和目录
this_script_name=$(basename "$0")

#设置备份文件夹
this_BACKUP_DIR=~/.BACKUP/${this_script_name}_bak
mkdir -p "$this_BACKUP_DIR"

# 重要操作账目
this_ACCOUNT_FILE="${this_BACKUP_DIR}/account.log"

#是否打印脚本开始和结束时间,不可修改.
this_show_start_end_timestamp=true

# Version
this_version=47.1

# 显示版本信息
print_version(){
    echo "Version : $this_version "
    return 0
}

# 架构信息
this_arch=$(arch)

# 操作系统品牌
this_os_release_logo_name=""

# 操作系统类型 server or workstation
this_os_release_type=""

# 执行针对特定项目编写的代码组合
this_b_project_manage=false

# (PJ_开头的函数名作为参数)
this_project_code=""

############################################################
# 检查当前解释器是否为 Bash
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
############################################################


# 脚本的主体部分，这里可以安全地使用 Bash 特性

echo_sharp_line()
{
    echo "##########################################################################"
}

echo_double_line()
{
    echo "=========================================================================="
}

echo_low_line()
{
    echo "__________________________________________________________________________"
}

echo_mid_line()
{
    echo "--------------------------------------------------------------------------"
}



# 启动一个假的shell,执行脚本的函数
start_x_virtual_shell(){
    while true; do
        # Prompt the user
        read -p "$this_username x --> " ltmp_x_user_input

        # Log the user input (optionally with a timestamp)
        # echo "$(date '+%Y-%m-%d %H:%M:%S') - $user_input" >> user_input_log.txt
        #printf "%s - %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$user_input" >> user_input_log.txt

        # Parse the user input
        if [[ "$user_input" == "show ip addr" ]]; then
            show_ip_addr
        elif [[ "$user_input" == my_echo* ]]; then
            # Use bash's built-in string manipulation to extract the arguments
            # Note: This assumes that "my_echo" is always the first word in the input
            args=("${user_input#my_echo }")
            my_echo "${args[@]}"
        else
            echo "Unknown command: $user_input"
        fi

        # Optionally, break out of the loop on some condition (e.g., specific command)
        # if [[ "$user_input" == "exit" ]]; then
        #     break
        # fi
    done
}

# 用于保存一份完整参数
this_GLOBAL_PARAMETER="$@"

# test函数的参数
this_test_parameter=""

# 一些需要的信息
this_username=$USER

# 包管理器
app_manager=null

# 本机 IP 清单
this_host_ip_list=""

# check_packages_installed 函数执行后分割的 已 安装包清单
this_installed_packages=""

# check_packages_installed 函数执行后分割的 未 安装包清单
this_not_installed_packages=""

# Debug or not
this_b_debug=false

# end debug siginal
this_b_end_debug=false

# TRACE or not 
this_b_trace=false

# run test fun or not
this_b_test_fn=false

# 是否要执行 undo 操作
this_b_undo=false

# 是否已经初始化unsudo
this_b_init=false

# 是否已经显示BANNER
this_b_banner_shown=false

# 是否启用交互的shell界面(模拟)
this_b_start_x_virtual_shell=false

# 防火墙或服务设置是否持续
this_permanent=""

# 存储单个端口号,用于各函数或模块通用的单个端口号参数
this_single_port=""

# 是否要添加防火墙端口
this_add_firewall_ports=false
this_add_fw_ports=""

# 默认要操作的端口类型 tcp
this_port_type_parameter=tcp

# 默认要操作的防火墙区域
this_port_zone_parameter=""

# 是否需要删除防火墙端口
this_remove_firewall_ports=false
this_rm_fw_ports=""

# icmp_reply 
this_icmp_reply=""

# 是否要设置x11vnc服务
this_b_setup_x11vnc_server=false
this_x11vnc_server_from_dir=""
this_x11vnc_server_password=""

# 全局变量，用于存储需要添加的端口号列表
GLOBAL_PORT_LIST=""

# 全局变量，用于存储需要删除的端口号列表（以空格分隔，双引号括定）
GLOBAL_PORT_LIST_TO_REMOVE=""

# 是否要安装python
this_b_py_install=false
this_will_install_python_version=3.9.0

# 是否要安装 nfs 服务
this_b_install_nfs=false

# 是否要设置 nfs 服务(增加共享目录)
this_b_add_dir_2_nfs=false
this_add_nfs_dir=""

# 是否要取消设置 nfs 服务(取消指定目录的共享)
this_b_unset_dir_2_nfs=false

# 参数 dev 如 /dev/sda
this_parameter_device=""

# 参数 fs 如 ext4 btrfs
this_parameter_fstype=""

# 参数 url
this_parameter_url="NULL"

# 是否要初始化,挂载,新disk
this_b_init_new_disk=false
this_new_disk_mount_point=""

# 参数NTP_server
this_ntp_server=""

# 是否作为NTP客户端
this_b_ntp_client=false

# 是否作为NTP服务端
this_b_ntp_server=false
############################################################


############################################################################################
# backup_and_log 函数生成的唯一编号
this_backup_IDENTIFIER=""

# 设置日志及临时文件路径
this_LOG_DIR=~/.LOG/${this_script_name}_LOG

# 设置日志文件
this_LOG_FILE=${this_LOG_DIR}/${this_script_name}_${this_bash_start_timestamp}.log

# 临时文件的存放位置 
this_TMP_DIR=${this_LOG_DIR}/${this_script_name}_${this_bash_start_timestamp}_TEMP

############################################################################################
# 定义两个函数
function fn_run_bel1 {
    echo -e "\a"
}

function fn_run_bel2 {
    tput bel
}

function fn_run_bel3 {
    printf '\a'
}

# 将函数名存储在数组中
functions=("fn_run_bel1" "fn_run_bel2" "fn_run_bel3")

# 生成一个随机数（0或1）
random_index=$((RANDOM % 3))

# 调用随机选择的函数
${functions[random_index]}

# 其他生成随机数012的方法
# 方法 1: 使用 $RANDOM 和取模运算
# Bash 内置了一个变量 $RANDOM，它会生成一个 0 到 32767 之间的随机数。你可以通过对 3 取模来得到一个 0 到 2 之间的随机数。

# random_num=$((RANDOM % 3))
# echo $random_num

# 方法 2: 使用 shuf 命令
# shuf 是一个 GNU coreutils 包中的命令，用于随机打乱输入行或范围的顺序。你可以使用它来生成一个随机数。

# random_num=$(shuf -i 0-2 -n 1)
# echo $random_num


# 这里 -i 0-2 指定了输入范围，-n 1 指定了输出的行数。

# 方法 3: 使用 /dev/urandom 和 head 命令

# /dev/urandom 是一个伪随机数生成器设备文件，你可以从中读取随机字节，并通过适当的处理得到一个随机数。

# random_num=$(head -c 1 /dev/urandom | od -An -N1 -tu1 | tr -d ' ')
# random_num=$((random_num % 3))
# echo $random_num

# 这里 head -c 1 从 /dev/urandom 中读取一个字节，od -An -N1 -tu1 将这个字节转换为无符号的 8 位整数，tr -d ' ' 删除可能存在的空白字符。

# 方法 4: 使用 awk 的随机数函数
# 如果你在使用 awk，你可以利用它的内置随机数函数 rand()。

# random_num=$(awk 'BEGIN{srand(); print int(rand()*3)}')
# echo $random_num

# 这里 srand() 初始化随机数生成器，rand() 生成一个 0 到 1 之间的浮点数，int(rand()*3) 将其转换为 0 到 2 之间的整数。

# 方法 5: 使用 date 和取模运算
# 也可以利用 date 命令生成的当前时间的某种表示（如秒数或纳秒数）来生成随机数，尽管这种方法可能不是真正随机的，但在某些情况下可能足够用。

# random_num=$(date +%s%N | cut -b1-1 | tr -d '\n')
# random_num=$((random_num % 3))
# echo $random_num

# 这里 date +%s%N 生成当前时间的纳秒数，cut -b1-1 取第一个字符，tr -d '\n' 删除换行符。然后取模得到 0 到 2 之间的随机数。不过这种方法依赖于系统时钟的分辨率，可能不是真正随机的。
# 选择哪种方法取决于你的具体需求和可用的工具。在大多数情况下，使用 $RANDOM 或 shuf 命令是最简单和最直接的方法。

#其他生成随机数123的方法 例如下面
# 生成 1 到 3 之间的随机数方法一
# random_number=$(( ( RANDOM % 3 ) + 1 ))
# echo $random_index

# # 使用 shuf 生成 1 到 3 之间的随机数
# random_index=$(shuf -i 1-3 -n 1)
# echo $random_index

# # 使用 awk 和 /dev/urandom 生成 1 到 3 之间的随机数
# random_index=$(awk -v min=1 -v max=3 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
# echo $random_index

# # 使用 date 和取模运算生成 1 到 3 之间的随机数
# random_index=$(( ( $(date +%s) % 3 ) + 1 ))
# echo $random_index

# # 使用 python 生成 1 到 3 之间的随机数
# random_index=$(python -c "import random; print(random.randint(1, 3))")
# echo $random_index

# # 或者使用 python3
# random_index=$(python3 -c "import random; print(random.randint(1, 3))")
# echo $random_index


# 或者，如果你喜欢使用更“Bash”的方式，可以使用以下替代方案：
# eval "${functions[random_index]}"
# 但请注意，eval通常被认为是不安全的，因为它会执行任何传递给它的字符串，
# 所以只有在你确定输入是安全的情况下才应该使用它。
############################################################################################

# 定义颜色变量 1是高亮.此处变量作为常量使用,不遵循变量加前缀 this_ 的要求.
GREEN='\033[1;32m' green='\033[0;32m'  WHITE='\e[1;37m'  NC='\e[0m'  NC='\033[0m' # No Color       
RED='\033[1;31m'   red='\033[0;31m'    YELLOW='\E[1;33m'  yellow='\E[0;33m'    
BLUE='\E[1;34m'    blue='\E[0;34m'     PINK='\E[1;35m'   pink='\E[0;35m'  
purple='\e[0;35m'  PURPLE='\e[1;35m'   cyan='\e[0;36this_b_py_installm'   CYAN='\e[1;36m'

#################################################################################################
# 描述信息
#################################################################################################
bash_description(){
    #脚本功能描述
    echo 
    # echo -e "${GREEN} 脚本程序【 $0 】 主要功能 :
     
    echo -e "${WHITE}程序功能\r"
    echo -e "${RED}    启停本机 httpd 服务 
    1.更改 httpd 目录文件selinux标签.解决新增文件 httpd 无法访问问题.
    2.实时增加或删除防火墙【 80 】端口.避免手工操作,提升效率,减少出错概率.
    3.通过【 sudo 】命令以管理员身份启动或停止【 httpd 】服务.
    ${NC}\r\n"
}

#################################################################################################
# 检查系统是否支持中文显示
# 函数: check_chinese_support
# 描述: 检查系统是否支持中文显示
# 返回值: 0 - 支持中文显示
#         1 - 不支持中文显示
#################################################################################################
check_chinese_support() {
    # 检查系统是否支持中文编码
    output=$(locale -a 2>/dev/null | grep -i 'zh_CN')
    
    if [ -n "$output" ]; then
        # 如果找到了中文编码，则表示系统支持中文
        echo "系统支持中文显示。"
        return 0
    else
        # 如果没有找到中文编码，则表示系统不支持中文
        echo "系统不支持中文显示。"
        return 1
    fi
}

#################################################################################################
# 初始化TMP文件夹
#################################################################################################
init_tmp(){
    # 建立TMP文件夹
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
# 初始化日志文件夹
#################################################################################################
init_log(){
    # 建立日志文件夹
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
#################################################################################################
init_tmp
init_log
#################################################################################################
#################################################################################################

#################################################################################################
# 函数: trim
# 描述: 去除字符串前后的空格
# 参数: $1 - 要处理的字符串
# 示例
# input="  This is a test string.  "
# trimmed=$(trim "$input")
# echo "Trimmed string: $trimmed"
#################################################################################################
trim_with_sed() {
    echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

trim_with_awk() {
    echo "$1" | awk '{gsub(/^[[:space:]]+|[[:space:]]+$/,"")}1'
}

trim_with_bash() {
    local trimmed="${1#"${1%%[![:space:]]*}"}"   # Remove leading spaces
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"   # Remove trailing spaces
    echo "$trimmed"
}

trim() {
    local var="$1"
    # 这里我选择了使用 awk 作为默认的实现
    trim_with_awk "$var"
    echo "$var"
}
#################################################################################################

#################################################################################################
# 查看调用链
#################################################################################################
show_who_call(){
    #查看谁调用了当前函数或方法.默认输出至日志,当 --trace 选项被使用,同时输出到终端.
    local ltmp_func_name=${FUNCNAME[0]}  # 获取当前函数名
    local ltmp_func_name1=${FUNCNAME[1]}  # 获取上一级函数名
    local ltmp_func_name2=${FUNCNAME[2]}  # 获取上两级函数名
    local ltmp_func_name3=${FUNCNAME[3]}  # 获取上三级函数名
    local ltmp_func_name4=${FUNCNAME[3]}  # 获取上四级函数名
    local ltmp_func_name5=${FUNCNAME[5]}  # 获取上五级函数名
    local ltmp_func_name6=${FUNCNAME[6]}  # 获取上六级函数名
    local ltmp_func_name7=${FUNCNAME[7]}  # 获取上七级函数名
    local ltmp_func_name8=${FUNCNAME[8]}  # 获取上八级函数名
    local ltmp_func_name9=${FUNCNAME[9]}  # 获取上九级函数名
    local ltmp_message=$1
    local ltmp_log_level="$2"
    local ltmp_timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [ $# -eq 1 ]; then
        ltmp_log_level="DEBUG"
    fi

    if [ $# -eq 0 ];then
        ltmp_log_level="DEBUG"
    fi

    #写入日志:当 --trace 选项 未 被使用时直接写入日志
    #if [ $this_b_trace = false ];then
    if [ $this_b_trace = false ] && [ $this_b_debug = false ];then
        #此处显示的调用链不一定存在那么多,由于使用场景有限,因此没有深入去数理,目前显示的信息已经可以使用.使用时根据自身对程序逻辑的了解推断调用是从第几级开始.多余的重复的可自行忽略.
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】【$ltmp_log_level】【 $ltmp_message ::调用链 : $ltmp_func_name9 ->$ltmp_func_name8 ->$ltmp_func_name7 ->$ltmp_func_name6 ->$ltmp_func_name5 ->$ltmp_func_name4 ->$ltmp_func_name3 ->$ltmp_func_name2 ->$ltmp_func_name1】" >> "$this_LOG_FILE"  2>&1
        return 0
    fi 

    #写入日志:当 --trace 选项 有 被使用时写入日志同时输出屏幕
    if [[ -n "${LOG_LEVEL_COLORS[$ltmp_log_level]}" ]]; then
        local ltmp_color="${LOG_LEVEL_COLORS[$ltmp_log_level]}"
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】【$ltmp_log_level】【 $ltmp_message ::调用链 : $ltmp_func_name9 ->$ltmp_func_name8 ->$ltmp_func_name7 ->$ltmp_func_name6 ->$ltmp_func_name5 ->$ltmp_func_name4 ->$ltmp_func_name3 ->$ltmp_func_name2 ->$ltmp_func_name1】" >> "$this_LOG_FILE"
        echo -e "${ltmp_color}【$ltmp_timestamp】【$ltmp_func_name{}】【$ltmp_log_level】【 $ltmp_message ::调用链 : $ltmp_func_name9 ->$ltmp_func_name8 ->$ltmp_func_name7 ->$ltmp_func_name6 ->$ltmp_func_name5 ->$ltmp_func_name4 ->$ltmp_func_name3 ->$ltmp_func_name2 ->$ltmp_func_name1】${NC}" 
    else
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】【$ltmp_log_level】【 $ltmp_message ::调用链 : $ltmp_func_name9 ->$ltmp_func_name8 ->$ltmp_func_name7 ->$ltmp_func_name6 ->$ltmp_func_name5 ->$ltmp_func_name4 ->$ltmp_func_name3 ->$ltmp_func_name2 ->$ltmp_func_name1】" | tee -a "$this_LOG_FILE"
    fi

    # if [ $this_b_trace == true ];then
    #     log_MESSAGE "调用者为:$ltmp_func_name " "ERROR"
    # fi
}

#################################################################################################
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
#################################################################################################
end_debug(){
    # 结束debug

    # 关闭 trace
    this_b_trace=false

    local ltmp_return="return 0"
    return $ltmp_return

    this_b_end_debug=true
}
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
# 断点函数,在代码任意行独立使用 bp 或 breakpoint 则可以使用本方法以调试 该功能处于构思中,暂未完整实现此处仅提供入口
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
        #echo -ne "${WHITE}使用方法:${NC}"
        bp_usage
        echo 
        ltmp_pwd_="Debug >"
        #read  -p " Debug /> " ltmp_wait_input
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
                #set | grep this
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

                # local ltmp_find_str_exec="\bexec"
                # echo $ltmp_wait_input |grep  -q "$ltmp_find_str_exec"
                # local grep_exec_ret=$?
                # local ltmp_str_exec_="exec"
                # if [ $grep_exec_ret -eq 0 ];then
                #     local ltmp_commend=${ltmp_wait_input#*$ltmp_str_exec_ }
                #     run_command "$ltmp_commend"
                #     #break
                # fi
                ;;
        esac
    done 

    #ltmp_tt=$(end_debug)

}

#################################################################################################
# 断点,为了便于阅读和理解
#################################################################################################
breakpoint(){
    #断点
    bp
}

#################################################################################################
#################################################################################################
#################################################################################################
#################################################################################################
# Banner
this_saintlogo="ICAgICAgICAgICAgICAgIOKWiOKWiOKWiOKWiOKWiOKWiCAg4paE4paE4paEICAgICAgIOKWiOKW
iOKWkyDilojilojilojiloQgICAg4paIIOKWhOKWhOKWhOKWiOKWiOKWiOKWiOKWiOKWkwogICAg
ICAgICAgICAgIOKWkuKWiOKWiCAgICDilpIg4paS4paI4paI4paI4paI4paEICAgIOKWk+KWiOKW
iOKWkiDilojilogg4paA4paIICAg4paIIOKWkyAg4paI4paI4paSIOKWk+KWkgogICAgICAgICAg
ICAgIOKWkSDilpPilojilojiloQgICDilpLilojiloggIOKWgOKWiOKWhCAg4paS4paI4paI4paS
4paT4paI4paIICDiloDilogg4paI4paI4paS4paSIOKWk+KWiOKWiOKWkSDilpLilpEKICAgICAg
ICAgICAgICAgIOKWkiAgIOKWiOKWiOKWkuKWkeKWiOKWiOKWhOKWhOKWhOKWhOKWiOKWiCDilpHi
lojilojilpHilpPilojilojilpIgIOKWkOKWjOKWiOKWiOKWkuKWkSDilpPilojilojilpMg4paR
IAogICAgICAgICAgICAgIOKWkuKWiOKWiOKWiOKWiOKWiOKWiOKWkuKWkiDilpPiloggICDilpPi
lojilojilpLilpHilojilojilpHilpLilojilojilpEgICDilpPilojilojilpEgIOKWkuKWiOKW
iOKWkiDilpEgCiAgICAgICAgICAgICAg4paSIOKWkuKWk+KWkiDilpIg4paRIOKWkuKWkiAgIOKW
k+KWkuKWiOKWkeKWkeKWkyAg4paRIOKWkuKWkSAgIOKWkiDilpIgICDilpIg4paR4paRICAgCiAg
ICAgICAgICAgICAg4paRIOKWkeKWkiAg4paRIOKWkSAg4paSICAg4paS4paSIOKWkSDilpIg4paR
4paRIOKWkeKWkSAgIOKWkSDilpLilpEgICAg4paRICAgIAogICAgICAgICAgICAgIOKWkSAg4paR
ICDilpEgICAg4paRICAg4paSICAgIOKWkiDilpEgICDilpEgICDilpEg4paRICAg4paRICAgICAg
CiAgICAgICAgICAgICAgICAgICAg4paRICAgICAgICDilpEgIOKWkSDilpEgICAgICAgICAgIOKW
kSAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAK"

this_developer="ICBBIExpbnV4IGVudGh1c2lhc3Qgd2hvIGhhcyBiZWVuIGFyb3VuZCBzaW5jZSAyMDA3LiBNYWls
IDogd2RpbHlAcXEuY29tCj09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09Cg=="

# this_tailline="PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
# PT09PT09PT09PT09PT09PT0K"

this_tailline="PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
PT09PT09PT09PT09PT09"

this_taillogo=""
#################################################################################################
#################################################################################################
#################################################################################################
#################################################################################################

#################################################################################################
# 不同级别日志显示的不同颜色.LOG_LEVEL_COLORS 数组作为常量使用,不遵循变量加前缀 _this的要求.
#################################################################################################
declare -A LOG_LEVEL_COLORS
LOG_LEVEL_COLORS=([ERROR]=${RED} [WARNING]=${YELLOW} [INFO]=${blue} [DEBUG]=${PINK} [TRACE]=${BLUE})

# 日志实现的示例,本脚本几乎不使用该日志方法.仅做演示用.
log_line(){
    local ltmp_level="$1"
    shift
    local ltmp_message="$@"
    show_who_call
    # 检查日志级别是否有对应的颜色
    if [[ -n "${LOG_LEVEL_COLORS[$ltmp_level]}" ]]; then
        local ltmp_color="${LOG_LEVEL_COLORS[$ltmp_level]}"
        echo -e "${ltmp_color} ${ltmp_level} ${NC}${ltmp_message}"
    else
        echo " $ltmp_level $ltmp_message "
    fi
    
}

#################################################################################################
# 定义日志函数，同时输出到标准输出和日志文件
#################################################################################################
log_message(){
    local ltmp_func_name=${FUNCNAME[1]}  # 获取上一级函数名
    local ltmp_message=$1
    local ltmp_log_level="$2"
    local ltmp_timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [ $# -eq 1 ]; then
        ltmp_log_level="INFO"
    fi
    show_who_call
    #由于增加了以不同颜色显示不同级别日志的功能,因此日志文件的写入被从下面单行中拆出,具体可见下列IF语句执行部分
    #echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$log_level】:【$ltmp_message 】" | tee -a "$this_LOG_FILE"
    
    #local show_color="${LOG_LEVEL_COLORS[$ltmp_log_level]}"
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
    local ltmp_func_name=${FUNCNAME[1]}  # 获取上一级函数名
    local ltmp_message=$1
    local ltmp_log_level="$2"
    local ltmp_timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [ $# -eq 1 ]; then
        ltmp_log_level="INFO"
    fi

    #写入日志:当 --trace 选项 未 被使用时直接写入日志
    if [ $this_b_trace = false ];then
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】" >> "$this_LOG_FILE"  2>&1
        return 0
    fi 

    #写入日志:当 --trace 选项 有 被使用时写入日志同时输出屏幕
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
    local ltmp_func_name=${FUNCNAME[1]}  # 获取上一级函数名
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
# 立即记录
#################################################################################################
LOG_message "Bash_start at ${this_bash_start_timestamp}." "INFO"
echo -e "日志各个字段 ( 列 ) 如下:
【日期\t\t时间】【\t当前函数(方法)\t】:【日志级别】:【\t日志正文\t\t】
" >> ${this_LOG_FILE}
#【2024-10-22 09:59:29】【show_banner_base64{}】:【TRACE】:【 Creating tempfile /home/saint/tp/test/tmp_V5_Linux_Shell脚本_模板.sh.tmp/20241022095929.mailtmp 】
#################################################################################################

#################################################################################################
# 仅输出到终端,不写日志文件
#################################################################################################
log_MESSAGE(){
    local ltmp_func_name=${FUNCNAME[1]}  # 获取上一级函数名
    local ltmp_message=$1
    local ltmp_log_level="$2"
    local ltmp_timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [ $# -eq 1 ]; then
        ltmp_log_level="INFO"
    fi

    #echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$log_level】:【$message】" 

    #local show_color="${LOG_LEVEL_COLORS[$ltmp_log_level]}"
    if [[ -n "${LOG_LEVEL_COLORS[$ltmp_log_level]}" ]]; then
        local ltmp_color="${LOG_LEVEL_COLORS[$ltmp_log_level]}"
        echo -e "${ltmp_color}【$ltmp_timestamp】${GREEN}【$ltmp_func_name{}】${NC}:${ltmp_color}【$ltmp_log_level】${NC}:【 $ltmp_message 】" 
    else
        echo -e "【$ltmp_timestamp】【$ltmp_func_name{}】:【$ltmp_log_level】:【 $ltmp_message 】" 
    fi
}

#################################################################################################
#带日志记录的删除文件函数
#################################################################################################
delete_file(){
    local ltmp_del_file=$1
    local ltmp_func_name=${FUNCNAME[0]}  # 获取当前函数名
    local ltmp_func_name1=${FUNCNAME[1]}  # 获取上一级函数名
    local ltmp_delete_file_timestamp=$(date +%Y%m%d-%H%M%S)
    local ltmp_error_output_file=${this_TMP_DIR}/${ltmp_func_name}_output_tmp_${ltmp_delete_file_timestamp}.tmp
    LOG_message "Deleting file 【 $ltmp_del_file 】 " "WARNING"
    LOG_message "文件SHA256 : $(sha256sum $ltmp_del_file)" "INFO"
    LOG_message "文件MD5 : $(md5sum $ltmp_del_file)" "INFO"

    if [ $this_b_banner_shown == true ];then
        LOG_message "$ltmp_func_name 函数执行生成临时文件 : $ltmp_error_output_file" "INFO"
    fi

    if [ ${this_b_trace} == true ];then
        log_message "TRACE is ${this_b_trace},file $ltmp_del_file will not be deleted." "TRACE"
    else
        local ltmp_output_of_rm=$(rm -vf "$ltmp_del_file" 2>$ltmp_error_output_file)
        #rm -vf "$ltmp_del_file"  >>$this_LOG_FILE
        local ltmp_RET_DEL=$?
        case "$ltmp_RET_DEL" in
            0)
                LOG_message "Deleted file 【 $ltmp_del_file 】SUCESS,RETCODE=$ltmp_RET_DEL." "WARNING"
                LOG_message "rm 命令输出 : $ltmp_output_of_rm" "WARNING"
                LOG_message "$ltmp_func_name 命令错误/警告输出 : $(cat $ltmp_error_output_file)" "WARNING"
                rm -rf ${ltmp_error_output_file}
                return 0
                ;;
            *)
                LOG_message "Deleting file 【 $ltmp_del_file 】FAIL,RETCODE=$ltmp_RET_DEL." "WARNING"
                LOG_message "rm 命令输出 : $ltmp_output_of_rm" "WARNING"
                LOG_message "$ltmp_func_name 命令错误/警告输出 : $(cat $ltmp_error_output_file)" "WARNING"
                rm -rf ${ltmp_error_output_file}
                return $ltmp_RET_DEL
                ;;
        esac
    fi

}

#################################################################################################
#################################################################################################
delete_sudo_file(){
    local ltmp_del_file=$1
    local ltmp_func_name=${FUNCNAME[0]}  # 获取当前函数名
    local ltmp_func_name1=${FUNCNAME[1]}  # 获取上一级函数名
    local ltmp_del_sudo_file_timestamp=$(date +%Y%m%d-%H%M%S)
    local ltmp_error_output_file=${this_TMP_DIR}/${ltmp_func_name}_output_tmp_${ltmp_del_sudo_file_timestamp}.tmp

    LOG_message "Deleting file 【 $ltmp_del_file 】 " "WARNING"
    LOG_message "文件SHA256 : $(sha256sum $ltmp_del_file)" "INFO"
    LOG_message "文件MD5 : $(md5sum $ltmp_del_file)" "INFO"

    if [ $this_b_banner_shown == true ];then
        LOG_message "$ltmp_func_name 函数执行生成临时文件 : $ltmp_error_output_file" "INFO"
    fi
    
    if [ ${this_b_trace} == true ];then
        log_message "TRACE is ${this_b_trace},file $ltmp_del_file will not be deleted." "TRACE"
    else
        local ltmp_output_of_rm=$(sudo rm -vf "$ltmp_del_file" 2>$ltmp_error_output_file)
        #rm -vf "$ltmp_del_file"  >>$this_LOG_FILE
        local ltmp_RET_DEL=$?
        case "$ltmp_RET_DEL" in
            0)
                LOG_message "Deleted file 【 $ltmp_del_file 】SUCESS,RETCODE=$ltmp_RET_DEL." "WARNING"
                LOG_message "rm 命令完整输出 : $ltmp_output_of_rm" "WARNING"
                LOG_message "$ltmp_func_name 命令错误/警告输出 : $(cat $ltmp_error_output_file)" "WARNING"
                rm -rf ${ltmp_error_output_file}
                return 0
                ;;
            *)
                LOG_message "Deleting file 【 $ltmp_del_file 】FAIL,RETCODE=$ltmp_RET_DEL." "WARNING"
                LOG_message "rm 命令完整输出 : $ltmp_output_of_rm" "WARNING"
                LOG_message "$ltmp_func_name 命令错误/警告输出 : $(cat $ltmp_error_output_file)" "WARNING"
                rm -rf ${ltmp_error_output_file}
                return $ltmp_RET_DEL
                ;;
        esac
    fi

}

#################################################################################################
# 常规print_usage 的内容
#################################################################################################
print_Usage(){
    # 使用方法描述
    #echo "Usage: $0 [-h|--help] [-v|--version] [-f|--file <file>]"
    echo -ne "${GREEN}
    --help ${NC}或${GREEN} -h    ${NC}显示帮助信息${GREEN}
    --version ${NC}或${GREEN} -v ${NC}显示版本信息${GREEN}
    --test ${NC}或${GREEN} -t    ${NC}程序启动后执行test函数的功能,用以开发和测试特定功能. ${GREEN}
    --trace         ${NC}追踪模式.临时文件一律保留,日志输出最为详尽.用以排查问题.${GREEN} 
    ${NC}"
    echo 
}
#################################################################################################
# 常规print_usage 的内容
#################################################################################################
project_PJ_usage(){
    echo -ne "${GREEN}
    --project ${BLUE}PJ_project_code    ${NC}执行项目代码${BLUE}PJ_project_code${NC}对应的函数
                        例:     ${GREEN}$0 --project ${BLUE} PJ_1234 

    ${NC}"
    echo 
}

#################################################################################################
# 帮助信息显示函数
#################################################################################################
print_help(){
    # 描述信息
    #bash_description  #comment from 20241117 
    
    # 使用方法
    echo "==========================================================================" 
    echo 
    echo -ne "${WHITE}使用方法: "
    echo -ne "${WHITE}

    $0 ${GREEN}  [选项]  ${BLUE}参数...${GREEN}
    ${NC}"
    echo 


    # 遍历所有定义的_usage后缀的函数并执行.字母顺序显示
    for func in $(compgen -A function); do
        # 检查函数名是否以_usage结尾
        if [[ "$func" == *_usage ]]; then
            # 调用函数
            "$func"
        fi
    done

    # 常规帮助信息
    print_Usage

    this_show_start_end_timestamp=false
}

#################################################################################################
# 帮助信息显示函数:兼容多数网上copy的代码.
#################################################################################################
usage(){
    print_help
}

#################################################################################################
# 显示脚本进入的 lOGO .为了避免内容导致使用者分心,在-h 和 --help 参数使用时,不显示LOGO
#################################################################################################
show_banner(){
    #base64命令是否可用
    base64 --version  >/dev/null 2>&1
    
    local ltmp_RET=$?
    case "$ltmp_RET" in
        0)
            this_b_base64support=true
            show_banner_base64
            # 根据需要进行处理
            ;;
        *)
            this_b_base64support=false
            show_banner_ascii
            # end_the_batch
            ;;
    esac

}

#################################################################################################
#################################################################################################
show_banner_base64(){
    # 输出一行等号，宽度与终端宽度相同
    #printf "%${term_width}s" | tr ' ' '='

    local ltmp_tempfilename=$(date +"%Y%m%d%H%M%S")
    LOG_message "Creating tempfile ${this_TMP_DIR}/${ltmp_tempfilename}.logotmp" "TRACE"
    echo "${this_saintlogo}" >${this_TMP_DIR}/${ltmp_tempfilename}.logotmp

    echo -e "${GREEN}
    "

    cat ${this_TMP_DIR}/${ltmp_tempfilename}.logotmp | base64 -d   
    delete_file  ${this_TMP_DIR}/${ltmp_tempfilename}.logotmp

    local ltmp_tempfilename2=$(date +"%Y%m%d%H%M%S")
    LOG_message "Creating tempfile ${this_TMP_DIR}/${ltmp_tempfilename2}.mailtmp" "TRACE"
    echo "${this_developer}">${this_TMP_DIR}/${ltmp_tempfilename2}.mailtmp

    echo -e "${WHITE}

    "

    cat ${this_TMP_DIR}/${ltmp_tempfilename2}.mailtmp | base64 -d   
    delete_file  ${this_TMP_DIR}/${ltmp_tempfilename2}.mailtmp

    # \033[1A 回到上一行行首
    #echo -e "${NC}\033[1A" 

    # 已经显示banner
    this_b_banner_shown=true

}

#################################################################################################
#################################################################################################
show_banner_ascii(){
    echo -e "${RED}
               ██████  ▄▄▄       ██▓ ███▄    █ ▄▄▄█████▓
             ▒██    ▒ ▒████▄    ▓██▒ ██ ▀█   █ ▓  ██▒ ▓▒
             ░ ▓██▄   ▒██  ▀█▄  ▒██▒▓██  ▀█ ██▒▒ ▓██░ ▒░
               ▒   ██▒░██▄▄▄▄██ ░██░▓██▒  ▐▌██▒░ ▓██▓ ░ 
             ▒██████▒▒ ▓█   ▓██▒░██░▒██░   ▓██░  ▒██▒ ░ 
             ▒ ▒▓▒ ▒ ░ ▒▒   ▓▒█░░▓  ░ ▒░   ▒ ▒   ▒ ░░   
             ░ ░▒  ░ ░  ▒   ▒▒ ░ ▒ ░░ ░░   ░ ▒░    ░    
             ░  ░  ░    ░   ▒    ▒ ░   ░   ░ ░   ░      
                   ░        ░  ░ ░           ░          
                                                    
    ${NC}\r\n"
    #echo -e "${NC}\033[1A" 
    echo -ne "${WHITE}\r\n【A Linux enthusiast who has been around since 2007. Mail : wdily@qq.com】 \r\n"
    echo -ne "==========================================================================${NC}\r\n"
    
    # 输出一行等号，宽度与终端宽度相同
    #printf "%${term_width}s" | tr ' ' '='
    
    # 已经显示banner
    this_b_banner_shown=true

}

#################################################################################################
#显示文件结束banner
#################################################################################################
show_tail_base64(){
    #显示程序结束line
    #echo -e "${WHITE}\033[1A"

    local ltmp_tempfilename3=$(date +"%Y%m%d%H%M%S")
    LOG_message "Creating tempfile ${this_TMP_DIR}/${ltmp_tempfilename3}.taillinetmp" "TRACE"
    echo "${this_tailline}" >${this_TMP_DIR}/${ltmp_tempfilename3}.taillinetmp

    cat ${this_TMP_DIR}/${ltmp_tempfilename3}.taillinetmp | base64 -d   
    delete_file  ${this_TMP_DIR}/${ltmp_tempfilename3}.taillinetmp

    echo -e "${NC}"
}

show_tail_ascii(){
    #显示程序结束line

    echo -ne "${WHITE}==========================================================================${NC}\r\n"
    echo 
}

show_tail(){
    #显示程序结束line
    if [ this_b_base64support == "true" ];then
        show_tail_base64
    else
        show_tail_ascii
    fi

}


#################################################################################################
# 使用sudo权限执行命令的函数
# 密码输入框为图形
#################################################################################################
function sudo_execute_gui() {
    local ltmp_command=$1
    local ltmp_func_name=${FUNCNAME[0]}  # 获取当前函数名
    local ltmp_func_name1=${FUNCNAME[1]}  # 获取上一级函数名
    local sudo_execute_gui_RET=0
    #调用链
    show_who_call
    # 下面变量是个shell脚本,用于输入sudo密码时显示图形密码输入框
    local ltmp_sudo_pass_input_method="IyEvYmluL2Jhc2gKI+S4gOS4queugOWNleeahCBhc2twYXNzIOiEmuacrO+8jOeUqOS6juS4uiBz
dWRvIOaYvuekuuWbvuW9oueahOWvhueggei+k+WFpeahhgpsdG1wX3N1ZG9fcGFzc3dvcmRfdHA9
IiIKCiMg5L2/55SoIHplbml0eSDmmL7npLrlr4bnoIHovpPlhaXmoYYKI2x0bXBfc3Vkb19wYXNz
d29yZF90cD0kKHplbml0eSAtLWZvcm1zIC0tdGl0bGU9IlN1ZG8gUGFzc3dvcmQiIFwKIyAgICAt
LXRleHQ9IkVudGVyIHlvdXIgc3VkbyBwYXNzd29yZDoiIFwKIyAgICAtLWFkZC1lbnRyeT0iUGFz
c3dvcmQiIFwKICAgICMtLWhpZGUtdGV4dCBcCiAgICAjLS1zZXBhcmF0b3I9IiwiKQpsdG1wX3N1
ZG9fcGFzc3dvcmRfdHA9JCh6ZW5pdHkgLS1wYXNzd29yZCAyPi9kZXYvbnVsbCkKIyDmo4Dmn6Ug
emVuaXR5IOeahOmAgOWHuueKtuaAgQppZiBbICQ/IC1uZSAwIF07IHRoZW4KCSMg55So5oi35Y+W
5raI5oiW5YWz6Zet5LqG5a+56K+d5qGGCgllY2hvICIiCglleGl0IDEKZmkKCgppZiBbIC16ICIk
bHRtcF9zdWRvX3Bhc3N3b3JkX3RwIiBdOyB0aGVuCglleGl0IDEKZWxzZQoJCgllY2hvICIkbHRt
cF9zdWRvX3Bhc3N3b3JkX3RwIgpmaQoKCg==
"
    if [ ! -f "${this_TMP_DIR}/tmp_sudo_pass_input.sh" ]; then
        echo "${ltmp_sudo_pass_input_method}" | base64 -d  > ${this_TMP_DIR}/tmp_sudo_pass_input.sh
        chmod +x ${this_TMP_DIR}/tmp_sudo_pass_input.sh
    else
        diff <(echo "${ltmp_sudo_pass_input_method}" | base64 -d) ${this_TMP_DIR}/tmp_sudo_pass_input.sh
        if [ $? -ne 0 ]; then
            echo "${ltmp_sudo_pass_input_method}" | base64 -d  > ${this_TMP_DIR}/tmp_sudo_pass_input.sh
            chmod +x ${this_TMP_DIR}/tmp_sudo_pass_input.sh
        fi
    fi
    #echo "${ltmp_sudo_pass_input_method}" | base64 -d  > ${this_TMP_DIR}/tmp_sudo_pass_input.sh
    #chmod +x ${this_TMP_DIR}/tmp_sudo_pass_input.sh
    export SUDO_ASKPASS="${this_TMP_DIR}/tmp_sudo_pass_input.sh"
    LOG_message "执行命令: sudo $ltmp_command | tee -a \"$this_LOG_FILE\" " "WARNING"
    LOG_message "sudo $ltmp_command 命令输出 : \n\r" "WARNING"
    sudo -A ${ltmp_command} | tee -a "$this_LOG_FILE"

    #local ltmp_output_of_sudo=$(sudo ${ltmp_command} ) 
    # ${PIPESTATUS[@]} 是 bash 特有的功能
    # 在 bash 中，可以通过 ${PIPESTATUS[@]} 数组来获取管道中每个命令的返回值。
    # ${PIPESTATUS} 将是第一个命令的返回值，
    # ${PIPESTATUS} 将是第二个命令的返回值，依此类推。
    sudo_execute_gui_RET=("${PIPESTATUS[@]}")

    # if [ ${PIPESTATUS} -eq 0 ]; then
    #     LOG_message "sudo $ltmp_command 命令执行成功.返回码: ${PIPESTATUS}" "INFO"    
    #     log_MESSAGE "sudo $ltmp_command ${GREEN}命令执行成功.返回码: ${PIPESTATUS}${NC}" "INFO"    
    #     #exit $status
    # else
    #     LOG_message "sudo $ltmp_command 命令执行失败，退出码: ${PIPESTATUS}" "ERROR"   
    # fi

    if [ ${sudo_execute_gui_RET} -eq 0 ]; then
        LOG_message "sudo $ltmp_command 命令执行成功.返回码: ${sudo_execute_gui_RET}" "INFO"    
        log_MESSAGE "sudo $ltmp_command ${GREEN}命令执行成功.返回码: ${sudo_execute_gui_RET}${NC}" "INFO"    
        #exit $status
    else
        LOG_message "sudo $ltmp_command 命令执行失败，退出码: ${sudo_execute_gui_RET}" "ERROR"   
    fi
    
    SUDO_ASKPASS=""
    return ${sudo_execute_gui_RET}
    
}
#################################################################################################
# 使用sudo权限执行命令的函数
#################################################################################################
function sudo_execute() {
    local ltmp_command=$1
    local ltmp_func_name=${FUNCNAME[0]}  # 获取当前函数名
    local ltmp_func_name1=${FUNCNAME[1]}  # 获取上一级函数名
    local sudo_execute_RET=0
    
    #调用链
    show_who_call
    
    LOG_message "执行命令: sudo $ltmp_command | tee -a \"$this_LOG_FILE\" " "WARNING"
    LOG_message "sudo $ltmp_command 命令输出 : \n\r" "WARNING"
    sudo ${ltmp_command} | tee -a "$this_LOG_FILE"
    sudo_execute_RET=("${PIPESTATUS[@]}")
    #local ltmp_output_of_sudo=$(sudo ${ltmp_command} ) 
    # ${PIPESTATUS[@]} 是 bash 特有的功能
    # 在 bash 中，可以通过 ${PIPESTATUS[@]} 数组来获取管道中每个命令的返回值。
    # ${PIPESTATUS} 将是第一个命令的返回值，
    # ${PIPESTATUS} 将是第二个命令的返回值，依此类推。

    if [ ${sudo_execute_RET} -eq 0 ]; then
        LOG_message "sudo $ltmp_command 命令执行成功.返回码: ${sudo_execute_RET}" "INFO"    
        log_MESSAGE "sudo $ltmp_command ${GREEN}命令执行成功.返回码: ${sudo_execute_RET}${NC}" "INFO"    
        #exit $status
    else
        LOG_message "sudo $ltmp_command 命令执行失败，退出码: ${sudo_execute_RET}" "ERROR"   
    fi

    return ${sudo_execute_RET}
}


#################################################################################################
# 全局变量，用于存储 sudo_execute_ 执行的命令输出
SUDO_EXECUTE__OUTPUT=""
#################################################################################################
# 使用sudo权限执行命令的函数
# 某些情况下无法直接通过命令的返回值判断命令的运行结果.因此设置了一个全局变量 SUDO_EXECUTE__OUTPUT 用于存储
# 改写了程序运行结果写入日志的函数.
# 注意:仅适用无交互情况下的命令执行结果的判断时
# 该函数 2024.11.23 15:41 添加.目的为判断  firewall-cmd --query-port=PORT_NUMBER/tcp 的执行结果 yes 还是 no 
#   该命令需使用sudo 权限,且根据是否运行的返回值无法确定能准确判断,因此引入此函数.平时还是需要使用sudo_execute来
#   使用sudo权限执行命令
#################################################################################################
function sudo_execute_() {
    local ltmp_command=$1
    local ltmp_output=""
    
    # 执行命令并捕获输出
    ltmp_output=$(sudo ${ltmp_command} 2>&1)  # 将标准错误也重定向到标准输出中
    local ltmp_exit_code=$?
    
    # 将命令输出追加到日志文件中
    LOG_message "执行命令: sudo $ltmp_command" "WARNING"
    LOG_message "sudo $ltmp_command 命令输出:\n$ltmp_output" "WARNING"
    echo "$ltmp_output" | tee -a "$this_LOG_FILE"
    
    # 更新全局变量 SUDO_EXECUTE__OUTPUT
    SUDO_EXECUTE__OUTPUT="$ltmp_output"
    
    # 检查命令是否成功执行
    if [ $ltmp_exit_code -eq 0 ]; then
        LOG_message "sudo $ltmp_command 命令执行成功. 返回码: $ltmp_exit_code" "INFO"
        log_MESSAGE "sudo $ltmp_command ${GREEN}命令执行成功. 返回码: $ltmp_exit_code${NC}" "INFO"
    else
        LOG_message "sudo $ltmp_command 命令执行失败，退出码: $ltmp_exit_code" "ERROR"
    fi
    
    # 返回命令的退出状态码
    return $ltmp_exit_code
}

#################################################################################################
# 使用sudo权限执行命令的函数 安静版:
#   操作一些诸如设置密码一类的敏感操作时为避免记录日志,
#   又考虑到增加过多判断在原函数中可能导致未预料的风险和遗漏
#################################################################################################
function sudo_execute_quiet() {
    local ltmp_command=$1
    local ltmp_func_name=${FUNCNAME[0]}  # 获取当前函数名
    local ltmp_func_name1=${FUNCNAME[1]}  # 获取上一级函数名

    #调用链
    show_who_call
    
    sudo ${ltmp_command} 

    #local ltmp_output_of_sudo=$(sudo ${ltmp_command} ) 
    # ${PIPESTATUS[@]} 是 bash 特有的功能
    # 在 bash 中，可以通过 ${PIPESTATUS[@]} 数组来获取管道中每个命令的返回值。
    # ${PIPESTATUS} 将是第一个命令的返回值，
    # ${PIPESTATUS} 将是第二个命令的返回值，依此类推。

    if [ ${PIPESTATUS} -eq 0 ]; then
        log_MESSAGE "sudo $ltmp_command ${GREEN}命令执行成功.返回码: ${PIPESTATUS}${NC}" "INFO"    
    else
        log_MESSAGE "sudo $ltmp_command 命令执行失败，退出码: ${PIPESTATUS}" "ERROR"   
    fi

    return ${PIPESTATUS}
}

#################################################################################################
# 使用sudo权限执行命令的函数,程序执行后会运行 sudo -k 来立即终止当前的sudo认证状态.
#################################################################################################
function sudo_execute_once() {
    local ltmp_command=$1
    local ltmp_func_name=${FUNCNAME[0]}  # 获取当前函数名
    local ltmp_func_name1=${FUNCNAME[1]}  # 获取上一级函数名
    local sudo_execute_once_RET=0
    local sudo_execute_once_RET2=0

    #调用链
    show_who_call
    
    LOG_message "执行命令: sudo $ltmp_command | tee -a \"$this_LOG_FILE\" " "WARNING"
    LOG_message "sudo $ltmp_command 命令输出 : \n\r" "WARNING"
    sudo ${ltmp_command} | tee -a "$this_LOG_FILE"
    sudo_execute_once_RET=("${PIPESTATUS[@]}")
    #local ltmp_output_of_sudo=$(sudo ${ltmp_command} ) 
    # ${PIPESTATUS[@]} 是 bash 特有的功能
    # 在 bash 中，可以通过 ${PIPESTATUS[@]} 数组来获取管道中每个命令的返回值。
    # ${PIPESTATUS} 将是第一个命令的返回值，
    # ${PIPESTATUS} 将是第二个命令的返回值，依此类推。

    if [ ${sudo_execute_once_RET} -eq 0 ]; then
        LOG_message "sudo $ltmp_command 命令执行成功.返回码: ${sudo_execute_once_RET}" "INFO"    
        log_MESSAGE "sudo $ltmp_command ${GREEN}命令执行成功.返回码: ${sudo_execute_once_RET}${NC}" "INFO"    
        #exit $status
    else
        LOG_message "sudo $ltmp_command 命令执行失败，退出码: ${sudo_execute_once_RET}" "ERROR"   
    fi

    local ltmp_command2="-k"

    #终止sudo认证状态
    LOG_message "执行:终止sudo认证状态 " "WARNING"
    LOG_message "执行命令: sudo $ltmp_command | tee -a \"$this_LOG_FILE\" " "WARNING"
    sudo ${ltmp_command2} | tee -a "$this_LOG_FILE"
    sudo_execute_once_RET2=("${PIPESTATUS[@]}")

    if [ ${sudo_execute_once_RET2} -eq 0 ]; then
        LOG_message "sudo $ltmp_command 命令执行成功.返回码: ${sudo_execute_once_RET2}" "INFO"    
        log_MESSAGE "sudo $ltmp_command ${GREEN}命令执行成功.返回码: ${sudo_execute_once_RET2}${NC}" "INFO"    
        #exit $status
    else
        LOG_message "sudo $ltmp_command 命令执行失败，退出码: ${sudo_execute_once_RET2}" "ERROR"   
    fi
    
    # 返回命令的退出状态码
    return ${sudo_execute_once_RET}
}

#################################################################################################
# sudo_execute_base64函数，接受base64编码后的脚本内容作为参数，并解码执行
# 待测
#################################################################################################
sudo_execute_base64() {
    local encoded_script="$1"
    local decoded_script=$(echo "$encoded_script" | base64 --decode)
    
    # 创建一个临时文件来保存解码后的脚本
    local script_file=$(mktemp ${this_TMP_DIR}/edit_ini_sudo.XXXXXX.sh)
    echo "$decoded_script" > "$script_file"
    
    # 确保脚本文件是可执行的
    chmod +x "$script_file"
    
    # 执行脚本
    sudo "$script_file"
    
    # 清理脚本文件
    rm -f "$script_file"
}


#################################################################################################
# 取消sudo权限执行命令的函数 #2025年1月1日22:17 我正考虑是否要取消这个函数
#################################################################################################
function unsudo_execute() {
    local ltmp_command=$1
    local ltmp_func_name=${FUNCNAME[0]}  # 获取当前函数名
    local ltmp_func_name1=${FUNCNAME[1]}  # 获取上一级函数名

    #调用链
    show_who_call

    LOG_message "执行命令: $ltmp_command | tee -a \"$this_LOG_FILE\" " "WARNING"
    LOG_message "$ltmp_command 命令输出 : \n\r" "WARNING"
    ${ltmp_command} | tee -a "$this_LOG_FILE"

    #local ltmp_output_of_sudo=$(sudo ${ltmp_command} ) 
    # ${PIPESTATUS[@]} 是 bash 特有的功能
    # 在 bash 中，可以通过 ${PIPESTATUS[@]} 数组来获取管道中每个命令的返回值。
    # ${PIPESTATUS} 将是第一个命令的返回值，
    # ${PIPESTATUS} 将是第二个命令的返回值，依此类推。

    if [ ${PIPESTATUS} -eq 0 ]; then
        LOG_message "$ltmp_command 命令执行成功.返回码: ${PIPESTATUS}" "INFO"    
        log_MESSAGE "$ltmp_command ${GREEN}命令执行成功.返回码: ${PIPESTATUS}${NC}" "INFO"    
        #exit $status
    else
        LOG_message "$ltmp_command 命令执行失败，退出码: ${PIPESTATUS}" "ERROR"   
    fi

    return ${PIPESTATUS}
}

get_random_str(){
    # 设置随机字符串的长度
    local ltmp_LENGTH=$1

    if [ -z "$ltmp_LENGTH" ];then
        ltmp_LENGTH=16
    fi

    # 定义字符集，包含字母（大小写）和数字
    local CHARSET="a-zA-Z0-9"

    # 从/dev/urandom生成随机字节，并通过tr命令过滤成指定字符集的字符
    # 使用head和tail命令来确保只获取所需长度的字符
    local random_string=$(cat /dev/urandom | tr -cd "$CHARSET" | head -c $ltmp_LENGTH)
    
    echo "$random_string"

}

#################################################################################################
# 备份 和 记账 函数 参数是要备份的文件,返回值是一个唯一标识符
# 备份成功返回 一个10位的唯一标识
# 失败返回 1
#################################################################################################
backup_and_log() {
    local ltmp_ITEM_TO_BACKUP=$1
    #local ltmp_IDENTIFIER=$(echo -n "$ltmp_ITEM_TO_BACKUP $(date +%s)" | sha256sum | head -c 10)
    local ltmp_IDENTIFIER=$(get_random_str "10")
    local ltmp_REAL_PATH
    local ltmp_BACKUP_FILE
    local ltmp_BACKUP_CMD
    local ltmp_RETRY_WITH_SUDO=0
    
    # 检查输入是文件、目录还是链接
    if [ -L "$ltmp_ITEM_TO_BACKUP" ]; then
        # 如果是链接，解析实际路径
        ltmp_REAL_PATH=$(readlink -f "$ltmp_ITEM_TO_BACKUP")
        LOG_line "即将备份的文件或目录 $ltmp_ITEM_TO_BACKUP 为链接,实际路径为 $ltmp_REAL_PATH . " "WARNING"
    else
        # 如果不是链接，则直接使用输入路径
        ltmp_REAL_PATH="$ltmp_ITEM_TO_BACKUP"
        LOG_line "即将备份文件或目录 $ltmp_REAL_PATH . " "WARNING"
    fi
    
    if [ -z "$ltmp_IDENTIFIER" ];then
        ltmp_IDENTIFIER=$(get_random_str "10")
    fi

    #bp

    # 检查实际路径是文件还是目录
    if [ -f "$ltmp_REAL_PATH" ]; then
        # 如果是文件，直接备份
        ltmp_BACKUP_FILE="${this_BACKUP_DIR}/$(basename "$ltmp_REAL_PATH")_${ltmp_IDENTIFIER}"
        ltmp_BACKUP_CMD="cp -f \"$ltmp_REAL_PATH\" \"$ltmp_BACKUP_FILE\""
    elif [ -d "$ltmp_REAL_PATH" ]; then
        # 如果是目录，压缩后备份
        ltmp_BACKUP_FILE="${this_BACKUP_DIR}/$(basename "$ltmp_REAL_PATH")_${ltmp_IDENTIFIER}.tar.gz"
        ltmp_BACKUP_CMD="tar -czf \"$ltmp_BACKUP_FILE\" -C \"$(dirname \"$ltmp_REAL_PATH\")\" \"$(basename \"$ltmp_REAL_PATH\")\" "
    else
        LOG_line "错误：输入的路径或链接指向的路径既不是文件也不是目录。" "ERROR"
        return 1
    fi
    
    # 尝试执行备份命令
    eval "$ltmp_BACKUP_CMD"  >> "$this_LOG_FILE"
    local ltmp_EXIT_CODE=$?

    # 检查是否因权限问题失败
    if [ $ltmp_EXIT_CODE -eq 1 ]; then
        # 可能是权限问题，尝试使用sudo（注意：这里假设脚本已经以root权限运行，但某些情况下可能需要额外的sudo）
        LOG_message "备份失败,尝试使用sudo重新执行。" "ERROR"
        ltmp_RETRY_WITH_SUDO=1
    fi

    # 如果需要使用sudo重新执行
    if [ $ltmp_RETRY_WITH_SUDO -eq 1 ]; then
        # 使用sudo执行备份命令（注意：这里可能会要求输入密码，取决于sudo的配置）
        sudo eval "$BACKUP_CMD" | tee -a "$this_LOG_FILE"
        local ltmp_SUDO_EXIT_CODE=$?

        # 检查sudo命令是否成功
        if [ $ltmp_SUDO_EXIT_CODE -ne 0 ]; then
            LOG_message "使用sudo备份仍然失败,退出代码:$ltmp_SUDO_EXIT_CODE" "ERROR"
            return 1
        fi
    fi

    # 记录操作账目
    this_ACCOUNT_FILE="${this_BACKUP_DIR}/account.log"
    local ltmp_TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    local ltmp_USERNAME=$(whoami)
    # 注意：这里记录的是原始输入的路径，而不是解析后的实际路径
    echo "时间: $ltmp_TIMESTAMP, 唯一标识: $ltmp_IDENTIFIER, 脚本名: $this_script_name, 用户名: $ltmp_USERNAME, 备份文件: $ltmp_BACKUP_FILE, 原始文件: $ltmp_ITEM_TO_BACKUP" >> "$this_ACCOUNT_FILE"
    
    # 返回唯一标识符
    echo "$ltmp_IDENTIFIER"

    # 唯一标识符的另一种使用方式
    this_backup_IDENTIFIER="$ltmp_IDENTIFIER"
}

#################################################################################################
# 函数：get_desktop_environment
# 描述：判断当前操作系统正在使用的桌面环境
# 返回值：桌面环境名称，如 "gnome", "kde", "mate", "xfce" 等，或者 "unknown" 如果无法确定
#################################################################################################
# 示例用法
# desktop_env=$(get_desktop_environment)
# echo "当前桌面环境是: $desktop_env"
#################################################################################################
get_desktop_environment() {
    local desktop_env=""

    # 检查环境变量
    if [ -n "$DESKTOP_SESSION" ]; then
        desktop_env="$DESKTOP_SESSION"
    elif [ -n "$XDG_CURRENT_DESKTOP" ]; then
        desktop_env="$XDG_CURRENT_DESKTOP"
    fi

    # 检查窗口管理器
    if [ -z "$desktop_env" ]; then
        if pgrep -x "gnome-session" >/dev/null; then
            desktop_env="gnome"
        elif pgrep -x "kdeinit" >/dev/null; then
            desktop_env="kde"
        elif pgrep -x "mate-session" >/dev/null; then
            desktop_env="mate"
        elif pgrep -x "xfce4-session" >/dev/null; then
            desktop_env="xfce"
        elif pgrep -x "cinnamon" >/dev/null; then
            desktop_env="cinnamon"
        elif pgrep -x "ukui-greeter" >/dev/null; then
            desktop_env="ukui"
        elif pgrep -x "ukui-session" >/dev/null; then
            desktop_env="ukui"
        elif pgrep -x "dde-session-daemon" >/dev/null; then
            desktop_env="deepin"
            #深度的 DDE桌面环境,宣传时使用的名字是DDE,但实际上值是deepin
        elif pgrep -x "dde-desktop" >/dev/null; then
            desktop_env="deepin"
            #桌面版操作系统的DDE
        elif pgrep -x "cdos-desktop" >/dev/null; then 
            desktop_env="cdos"
            # 中科方德桌面操作系统的桌面环境
        elif pgrep -x "gnome-shell" >/dev/null; then
            desktop_env="gnome"
            # 中科方德服务器版操作系统默认桌面环境为gnome
        fi
    fi

    # 如果仍然无法确定，尝试使用特定命令 (这种方法并不可靠,一个操作系统可安装多个桌面环境,通常我们只关注当前正在使用的)
    if [ -z "$desktop_env" ]; then
        if command -v gnome-shell >/dev/null 2>&1; then
            desktop_env="gnome"
        elif command -v startkde >/dev/null 2>&1; then
            desktop_env="kde"
        elif command -v mate-session >/dev/null 2>&1; then
            desktop_env="mate"
        elif command -v xfce4-session >/dev/null 2>&1; then
            desktop_env="xfce"
        elif command -v ukui-greeter >/dev/null 2>&1; then
            desktop_env="ukui"
        fi
    fi

    # 如果仍然无法确定，返回 "unknown"
    if [ -z "$desktop_env" ]; then
        desktop_env="unknown"
    fi

    echo "$desktop_env"
}

#################################################################################################
# 判断操作系统的默认包管理器.函数没有返回值,通过前面已经定义的变量 app_manager 来传递结果.
#################################################################################################
which_app_manager(){
    # command -v‌用于检查命令是否存在，并显示其路径。
    # 如果命令不存在，则返回错误。该命令可以忽略环境变量，直接查找系统路径中的命令。
    #   参数:
    #     -v 或 --verbose：显示命令的描述，如果是外部命令，显示其路径。
    #     -p：使用一个安全的路径来搜索和执行命令，忽略用户定义的路径变量。
    #     -V：显示命令的详细描述，与type命令类似。

    # 检查 dnf 命令是否存在 (Fedora|Red Hat Enterprise Linux|CentOS|RHEL 及其他XC基于 Linux 内核服务器操作系统)
    if command -v dnf &> /dev/null
    then
        LOG_message "当前系统的包管理器是 dnf " "INFO"
        app_manager=dnf
    # 检查 apt-get 命令是否存在（对于Debian系Linux,如Ubuntu,mint,kali 及其他XC基于 Linux 内核桌面操作系统）
    elif command -v apt-get &> /dev/null
    then
        LOG_message "当前系统的包管理器是 apt " "INFO"
        app_manager=apt
    # 检查 pkg 命令是否存在（对于FreeBSD系Linux）
    elif command -v pkg &> /dev/null
    then
        LOG_message "当前系统的包管理器是 pkg " "INFO"
        app_manager=pkg
    # 检查 zypper 命令是否存在（对于 openSUSE|SUSE 系Linux）
    elif command -v zypper &> /dev/null
    then
        LOG_message "当前系统的包管理器是 zypper " "INFO"
        app_manager=zypper
    else
        log_message "无法确定当前系统的包管理器 " "ERROR"
        #freebse和suse操作系统的包管理器与常见GNU系统不同,后续需要补充
        #?
        app_manager=unknow
        return 1
    fi
    return 0
}

#################################################################################################
# 获取本机所有 IP.存储到 数组 host_ip_list
#################################################################################################
get_all_ip() {
    # 这里展示了几种获取IP地址的方法，你可以根据实际情况选择一种或多种
    # 并将获取到的IP地址添加到NFS_SERVER_IPS数组中
    
    # 示例：假设我们使用了一个命令来获取所有IP地址（这里使用hostname -I作为示例）
    # 在实际应用中，你可能需要使用更具体的命令或方法来获取NFS服务器的IP地址
    IFS=' ' read -r -a this_host_ip_list <<< "$(hostname -I)"
    
    # 如果你知道NFS服务器有哪些特定的网络接口，你可以使用ip addr show命令来获取
    # 例如，对于eth0接口：
    # IFS=$'\n' read -d '' -r -a this_host_ip_list <<< "$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)"
    
    # 如果你有一个包含NFS服务器IP地址的配置文件，你可以从文件中读取
    # 例如：
    # IFS=$'\n' read -d '' -r -a this_host_ip_list <<< "$(grep -oP '(?<=nfs_server_ip=)\d+(\.\d+){3}' /path/to/config/file)"
}

#################################################################################################
# 2024-10-27 saint:该方式仅支持单个包名作为参数 修改版的函数为 check_packages_installed
# 封装判断包是否安装的函数(根据百度AI的回复稍作修改实现的)
#   o 已经安装  返回 0
#   o 未安装    返回 2
#   o 包管理器未在脚本定义,或未提供执行所需参数  返回 1
#################################################################################################
check_Package_installed() {
    show_who_call
    if [ -z "$1" ]; then
        log_message "请提供一个包名作为参数。" "ERROR"
        return 1
    fi

    local package_name="$1"
    
    if [ "$app_manager" == "null" ];then
        which_app_manager
    fi

    # 检查是否存在 apt 命令.
    if [ "$app_manager" == "apt" ];then
        # 使用 apt 检查包是否安装
        if $app_manager list --installed "$package_name" 2> /dev/null | grep -q "$package_name"; then
            log_message "包 '$package_name' 已经安装 (使用 apt)。" "INFO"
        else
            log_message "包 '$package_name' 未安装 (使用 apt)。" "ERROR"
            return 2
        fi
    # 检查是否存在 dnf 命令
    elif [ "$app_manager" == "dnf" ];then
        # 使用 dnf 检查包是否安装
        if $app_manager list installed "$package_name" 2> /dev/null | grep -q "$package_name"; then
            log_message "包 '$package_name' 已经安装 (使用 dnf)。" "INFO"
        else
            log_message "包 '$package_name' 未安装 (使用 dnf)。" "ERROR"
            return 2
        fi
    # 检查是否存在 pkg 命令
    elif [ "$app_manager" == "pkg" ];then
        # 使用 dnf 检查包是否安装
        if $app_manager info  2> /dev/null | grep -q "$package_name"; then
            log_message "包 '$package_name' 已经安装 (使用 pkg)。" "INFO"
        else
            log_message "包 '$package_name' 未安装 (使用 pkg)。" "ERROR"
            return 2
        fi
    # 检查是否存在 zypper 命令
    elif [ "$app_manager" == "zypper" ];then
        # 使用 dnf 检查包是否安装
        if $app_manager se --installed-only  2> /dev/null | grep -q "$package_name"; then
            log_message "包 '$package_name' 已经安装 (使用 zypper)。" "INFO"
        else
            log_message "包 '$package_name' 未安装 (使用 zypper)。" "ERROR"
            return 2
        fi
    else
        log_message "包管理系统未识别:未检测到 apt | dnf | pkg | zypper ." "ERROR"
        return 1
    fi

    return 0
}

#################################################################################################
# 2024-10-27 修改版的函数为 封装判断包清单是否安装的函数
#   o 已经安装 的包清单  存储到 this_installed_packages
#   o 未安装 的包清单   存储到 this_not_installed_packages
#   o 包管理器未在脚本定义,或未提供执行所需参数  返回 1
#   o 顺利执行完成  返回 0
#################################################################################################
check_packages_installed(){
    show_who_call
    if [ -z "$1" ]; then
        log_message "请提供一个或多个以空格分隔的包名作为参数，并用双引号括起来。" "ERROR"
        return 1
    else
        log_message "参数是:$1" "WARNING"
    fi

    local ltmp_packages="$1"
    local ltmp_package_manager=$app_manager

    # 分割包名
    IFS=' ' read -r -a ltmp_package_list <<< "$ltmp_packages"

    # 清空已安装和未安装的包名列表
    this_installed_packages=""
    this_not_installed_packages=""

    # 遍历包名并检查是否安装
    for ltmp_tp_package in "${ltmp_package_list[@]}"; do
        ltmp_installed=false
        case "$ltmp_package_manager" in
            apt)
                if dpkg -l | grep -q "ii\s*$ltmp_tp_package"; then
                    ltmp_installed=true
                fi
                ;;
            dnf)
                if dnf list installed | grep -q "$ltmp_tp_package"; then
                    ltmp_installed=true
                fi
                ;;
            pkg)
                if pkg info | grep -q "$ltmp_tp_package"; then
                    ltmp_installed=true
                fi
                ;;
            zypper)
                if zypper se --installed-only | grep -q "$ltmp_tp_package"; then
                    ltmp_installed=true
                fi
                ;;
        esac

        # 根据安装状态更新列表
        if $ltmp_installed; then
            if [ -z "$this_installed_packages" ]; then
                this_installed_packages="$ltmp_tp_package"
            else
                this_installed_packages="$this_installed_packages $ltmp_tp_package"
            fi
        else
            if [ -z "$this_not_installed_packages" ]; then
                this_not_installed_packages="$ltmp_tp_package"
            else
                this_not_installed_packages="$this_not_installed_packages $ltmp_tp_package"
            fi
        fi
    done

    # 虽然不知道为什么,但还是清空一下这个变量.
    ltmp_tp_package=""
    return 0
}

#################################################################################################
# 封装判断包是否安装的函数(根据百度AI的回复稍作修改实现的)
#   o 已经安装  返回 0
#   o 未安装    返回 2
#   o 包管理器未在脚本定义  返回 1
#################################################################################################
install_package() {
    show_who_call
    # this_installed_packages 为 check_packages_installed 函数执行后分割的 已 安装包清单
    # this_not_installed_packages 为 check_packages_installed 函数执行后分割的 未 安装包清单
    if [ -z "$1" ]; then
        log_message "请提供一个或多个以空格分隔的包名作为参数，并用双引号括起来。" "ERROR"
        log_message "当前栈中参数是:$this_not_installed_packages ,是否安装 [ $this_not_installed_packages ]" "WARNING"

        local ltmp_y_or_n_or_q="NULL"
        read  -p "Please Type: yes(y) or no(n) or quit(q)"  ltmp_y_or_n_or_q

        case $ltmp_y_or_n_or_q in 
            "y"|"yes"|"YES")
                log_message "用户 确认 了包清单 [ $this_not_installed_packages ] 需安装,执行开始... ..." "DEBUG"
                local ltmp_package_name=$this_not_installed_packages
                ;;
            "n"|"NO"|"no")
                log_message "用户 否决 了包清单 [ $this_not_installed_packages ] 的安装" "DEBUG"
                return 1
                ;;
            "")
                log_message "用户 否决 了包清单 [ $this_not_installed_packages ] 需安装,执行开始... ..." "DEBUG"
                return 1
                ;;
            *)
                log_message "用户否决了包清单 [ $this_not_installed_packages ] 的安装" "DEBUG"
                return 1
                ;;
        esac

    else
        log_message "参数是:$1" "WARNING"
        local ltmp_package_name="$1"
    fi

    if [ "$app_manager" == "null" ];then
        which_app_manager
        local ltmp_ret_tp_apm=$?
        if [ $ltmp_ret_tp_apm -eq 0 ];then
            local package_manager=$app_manager
        else
            log_message "由于包管理器:$app_manager 未在脚本中定义,无法继续安装."
        fi
    else 
        local package_manager=$app_manager
    fi

    # 使用相应的包管理器安装包
    case "$package_manager" in
        dnf)
            sudo_execute "$package_manager install -y $ltmp_package_name"
            ;;
        apt)
            sudo_execute "$package_manager update" && sudo_execute "$package_manager install -y \"$ltmp_package_name\" "
            ;;
        pkg)
            sudo_execute $package_manager install -y "$ltmp_package_name"
            ;;
        zypper)
            sudo_execute $package_manager install -y "$ltmp_package_name"
            ;;
        *)
            echo "未识别包管理器：$package_manager"
            return 1
            ;;
    esac

    #检测一下包是否已经安装
    check_packages_installed "$ltmp_package_name"
    if [ -z "$this_not_installed_packages" ];then
    log_message "提供的软件包清单: $ltmp_package_name 均已安装" "WARNING"
        return 0
    else
        log_message "提供的软件包清单: $ltmp_package_name 安装异常失败,可能存在遗漏或其他未预见错误,清手动检查安装结果后手动安装." "WARNING"
        return 1
    fi

    return 0
}

#################################################################################################
#2024-11-28添加,目的为了新装或重装fedora时候能够快速重装需要的包
#################################################################################################
# 封装使用DNF安装包的函数(根据百度AI的回复稍作修改实现的)  
#   o 已经安装  返回 0
#   o 未安装    返回 2
#   o 包管理器未在脚本定义  返回 1
#################################################################################################
# 示例调用函数（这里使用你之前定义的变量作为参数）
# local ltmp_pakage_list_of_fedora="aircrack aisleriot amule anjuta ..."  # 其他包名
# install_packages "$ltmp_pakage_list_of_fedora"
#################################################################################################
dnf_install_packages() {
    local package_list=$1
    local installed_packages=()
    local failed_packages=()
    local skipped_packages=()
    local existing_packages=()
    local reinstall_packages=()
    local ltmp_return_value=0

    # 将包名以空格分隔存入数组
    IFS=' ' read -r -a packages <<< "$package_list"

    # 遍历数组并安装每个包
    for pkg in "${packages[@]}"; do
        log_message "正在尝试安装 $pkg..."
        
        # 检查包是否已经安装，并获取完整包名（如果已安装）
        if sudo_execute "dnf list installed $pkg" &> /dev/null; then
            existing_version=$(dnf list installed "$pkg" | awk '{print $2}')
            existing_packages+=("$pkg-$existing_version")
            log_message "$pkg 已经存在，版本为 $existing_version"
        else
            # 尝试安装包
            if sudo_execute "dnf install -y $pkg" &> /dev/null; then
                # 获取安装成功的包的完整名称
                installed_version=$( sudo_execute "dnf list installed $pkg" | awk '{print $2}')
                installed_packages+=("$pkg-$installed_version")
                log_message "$pkg 安装成功，版本为 $installed_version"
            else
                # 判断安装失败的原因（这里简单处理为超时或无法连接等问题）
                # 实际应用中可能需要更复杂的逻辑来判断具体失败原因
                if [[ $? -eq 124 ]]; then  # 124 通常是超时错误码，但这可能因系统而异
                    skipped_packages+=("$pkg")
                    log_message "$pkg 安装跳过（可能是超时或无法连接）" "TRACE"
                    ltmp_return_value=1
                else
                    failed_packages+=("$pkg")
                    log_message "$pkg 安装失败" "ERROR"
                    ltmp_return_value=1
                fi
                
                # 询问是否重新安装失败的包
                reinstall_packages+=("$pkg")
                ltmp_return_value=1
            fi
        fi
    done

    # 输出安装结果
    echo "安装成功的包："
    printf "%s\n" "${installed_packages[@]}"

    echo "已经存在的包（包含版本号）："
    printf "%s\n" "${existing_packages[@]}"

    echo "安装失败的包："
    printf "%s\n" "${failed_packages[@]}"

    echo "安装跳过（超时或无法连接）的包："
    printf "%s\n" "${skipped_packages[@]}"

    # 询问是否重新安装未成功或跳过的包
    if [[ ${#reinstall_packages[@]} -gt 0 ]]; then
        read -p "是否对未安装成功或者因为超时或无法连接问题跳过安装的包进行重新安装？(y/n): " answer
        if [[ "$answer" == "y" || "$answer" == "yes" ]]; then
            for pkg in "${reinstall_packages[@]}"; do
                echo "正在重新安装 $pkg..."
                if sudo_execute "dnf install -y $pkg" &> /dev/null; then
                    log_message "$pkg 重新安装成功"
                else
                    log_message "$pkg 重新安装失败" "ERROR"
                fi
            done
        fi
    fi

    return $ltmp_return_value
}

#################################################################################################
# 生成验证码并要求用户输入验证码
# 参数1：验证码的复杂度（1：数字，2：字母，3：数字和字母）
# 参数2：验证码的长度
# 返回值：0表示验证成功，1表示验证失败
#################################################################################################
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
#################################################################################################

#################################################################################################
# 查找符合条件的图片并执行指定操作
# 参数1：宽度范围（例如：500-600）
# 参数2：高度范围（例如：780-790）
# 参数3：查找的起始目录
# 参数4：操作类型（可选：mv、cp、delete）
# 参数5：目标目录（如果指定了操作类型）
# 返回值：0表示操作成功，1表示操作失败
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
#################################################################################################
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

# Example usage:
# find_pic -w "500-600" -h "780-790" "/home/saint/Pictures"
# find_pic -w "500" -h "780" "/home/saint/Pictures" --mv "/home/saint/backup/myPicture"
#################################################################################################

#################################################################################################
# 检查路径是否有效
# 参数1 要检查的文件或目录
# 参数2 
# 异常返回 1
# 可用返回 0
# 不存在 目录没权限 返回 2
# 不存在 目录有权限 返回 3
# 其他不可用情况    返回 4
#################################################################################################
check_path_available() {
    local ltmp_PATH_TO_CHECK=$1
    local ltmp_operate=$2  # 这个变量在您的原始脚本中没有使用，我将其保留以防将来需要
    local ltmp_PARENT_DIR

    if [ -z "$ltmp_PATH_TO_CHECK" ]; then
        log_message "输入的路径为空。" "ERROR"
        return 1
    fi

    # 检查路径是否存在
    if [ ! -e "$ltmp_PATH_TO_CHECK" ]; then
        log_message "输入的路径不存在：$ltmp_PATH_TO_CHECK" "ERROR"
        ltmp_PARENT_DIR=$(dirname "$ltmp_PATH_TO_CHECK")
        
        # 检查上层目录是否存在和是否有写权限
        if [ ! -d "$ltmp_PARENT_DIR" ]; then
            log_message "上层目录不存在：$ltmp_PARENT_DIR" "ERROR"
            return 2
        elif [ ! -w "$ltmp_PARENT_DIR" ]; then
            log_message "上层目录没有写权限：$ltmp_PARENT_DIR" "ERROR"
            return 2
        else
            # 上层目录存在且有写权限，但原路径不存在
            log_message "路径不存在但上层目录有权限，请检查您的输入或创建路径：$ltmp_PATH_TO_CHECK" "ERROR"
            return 3
        fi
    else
        # 路径存在，检查是否为允许的类型（文件或目录）
        if [ ! -f "$ltmp_PATH_TO_CHECK" ] && [ ! -d "$ltmp_PATH_TO_CHECK" ]; then
            log_message "输入的路径既不是文件也不是目录：$ltmp_PATH_TO_CHECK" "ERROR"
            return 1
        fi

        # 检查路径是否有写权限
        if [ ! -w "$ltmp_PATH_TO_CHECK" ]; then
            log_message "输入的路径没有写权限：$ltmp_PATH_TO_CHECK" "ERROR"
            return 1
        fi

        # 如果到这里，路径是有效的
        return 0
    fi
}

#################################################################################################
# 看看是哪个系统发行 20241107用于判断系统是否是麒麟的服务器系统
# 未完成 
#################################################################################################
check_which_os_release(){
    show_who_call
    # 读取/etc/os-release文件
    if [ ! -f /etc/os-release ]; then
        echo "无法找到 /etc/os-release 文件。"
        return 1
    fi

    # 加载文件中的变量
    . /etc/os-release

    # 显示发行版和版本号
    log_message "发行版: $NAME" "INFO"
    log_message "版本号: $VERSION" "INFO"

    # 操作系统品牌
    this_os_release_logo_name="$ID"

    # 操作系统类型 server or workstation or desktop
    #this_os_release_type=""

    # 判断是桌面操作系统还是服务器操作系统
    case "$ID" in
        ubuntu|debian|linuxmint)
            # Ubuntu、Debian和Linux Mint通常没有明确的桌面或服务器标识，但可以通过其他方式判断
            # 这里我们简单假设它们都是桌面版，除非有更具体的标识（如UBUNTU_CODENAME等）
            log_message "类型: 桌面操作系统"
            this_os_release_type="workstation"
            ;;
        centos|rhel|fedora|almalinux|rockylinux)
            # CentOS、RHEL、Fedora、AlmaLinux和Rocky Linux通常默认为服务器版，除非另有说明
            log_message "类型: 服务器操作系统"
            log_message "CentOS、RHEL、Fedora、AlmaLinux和Rocky Linux通常按服务器版处理，即便是workstation版。"
            this_os_release_type="server"
            ;;
        opensuse|suse)
            # openSUSE和SUSE Linux Enterprise Server
            if [[ "$VERSION_ID" == *"Leap"* ]] || [[ "$NAME" == *"Enterprise"* ]]; then
                log_message "类型: 服务器操作系统"
                this_os_release_type="server"
            else
                log_message "类型: 桌面操作系统"
                this_os_release_type="workstation"
            fi
            ;;
        kylin)
            # 银河麒麟
            if [[ "$VERSION_ID" == *"Leap"* ]] || [[ "$NAME" == *"Server"* ]]; then
                log_message "类型: kylin 服务器操作系统. (kylin 是 银河麒麟操作系统的品牌名称)"
                this_os_release_type="server"
            else
                log_message "类型: kylin 桌面操作系统. (kylin 是 银河麒麟操作系统的品牌名称)"
                this_os_release_type="desktop"
            fi
            ;;
        uos)
            # 统信
            if [[ "$DISTRIB_DESCRIPTION" == *"Server"* ]] || [[ "$NAME" == *"Server"* ]]; then
                log_message "类型: uos 服务器操作系统. (UOS 是 统信操作系统的品牌名称)"
                this_os_release_type="server"
            else
                log_message "类型: uos 桌面操作系统. (UOS 是 统信操作系统的品牌名称)"
                this_os_release_type="desktop"
            fi
            ;;
        nfsdesktop)
            # NFS桌面版 中科方德
            log_message "类型: NFS 桌面操作系统.(NFS 是 中科方德操作系统的品牌名称)"
            this_os_release_type="desktop"
            ;;
        NFS)
            # NFS服务器版 中科方德
            log_message "类型: NFS 服务器操作系统.(NFS 是 中科方德操作系统的品牌名称)"
            this_os_release_type="server"
            ;;
        *)
            # 对于其他不明确的发行版，我们默认不做出判断
            log_message "类型: 未知"
            ;;
    esac

    # 额外的判断可以基于特定的环境变量或文件，这取决于具体的发行版
    # 例如，Ubuntu的某些版本可能在/etc/lsb-release中有更详细的信息
    if [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        case "$DISTRIB_DESCRIPTION" in
            *"Server"*)
                log_message "（根据 /etc/lsb-release，这是一台服务器操作系统）"
                ;;
            *"Workstation"*)
                log_message "（根据 /etc/lsb-release，这是一台工作站操作系统）"
                ;;
            *"Desktop"*)
                log_message "（根据 /etc/lsb-release，这是一台桌面操作系统）"
                ;;
        esac
    fi

    ##此处后期增加 cat /etc/*release 并输出到日志 的代码
}

#################################################################################################
# 创建软链接,依赖上面定义的函数 check_path_available
#################################################################################################
# make_s_ln_usage()
# {
#     echo "Nothing"
# }
#################################################################################################
make_s_ln() {
    local args=("$@")  # 将所有参数放入一个数组中
    local src=""
    local dest=""
    local force=false
    local timestamp=$(date +"%Y%m%d%H%M%S")  # 生成时间戳，精确到秒

    # 遍历参数数组
    for ((i=0; i<${#args[@]}; i++)); do
        if [ "${args[i]}" == "--force" ]; then
            force=true
        elif [ -z "$src" ]; then
            src="${args[i]}"  # 如果还没有设置源文件/目录，则将其设置为当前参数
        else
            dest="${args[i]}"  # 如果已经设置了源文件/目录，则将当前参数设置为目标文件/目录
            break  # 找到目标文件/目录后退出循环
        fi
    done

    # 检查是否提供了足够的参数
    if [ -z "$src" ] || [ -z "$dest" ]; then
        #echo "Usage: make_s_ln [--force] <source> <destination>"
        log_message "参数不足,应该为 make_s_ln src_file_or_dir dest_file_or_dir  --force.其中force是可选的,且可以出现在这三个参数的任意位置."
        return 1
    fi

    # 检查源文件/目录是否存在
    if ! check_path_available "$src" ""; then
        log_message "Source path is not available." "ERROR"
        return 1
    fi

    # 检查目标路径
    local result
    check_path_available "$dest" ""
    result=$?

    if [ "$result" -eq 1 ]; then
        # 目标路径不存在
        local parent_dir=$(dirname "$dest")
        if [ ! -d "$parent_dir" ] || [ ! -w "$parent_dir" ]; then
            # 上层目录不存在或没有写权限，使用 sudo 创建
            log_message "Attempting to create parent directory with sudo..."
            if ! sudo_execute "mkdir -p $parent_dir"; then
                log_message "Failed to create parent directory with sudo." "ERROR"
                return 1
            fi
        fi
        # 尝试不提升权限下直接创建目录（如果上层目录已有写权限）
        if ! mkdir -p "$dest"; then
            log_message "Failed to create destination directory. Attempting with sudo..." "TRACE"
            if ! sudo_execute "mkdir -p $dest"; then
                log_message "Failed to create destination directory with sudo." "ERROR"
                return 1
            fi
        fi
    elif [ "$result" -ne 0 ]; then
        # 目标路径存在但不是文件或目录，或者没有写权限
        if $force; then
            # 使用 --force 选项，备份目标路径
            local backup_dest="${dest}_${timestamp}"
            log_message "Moving existing destination to backup: $backup_dest" "TRACE"
            if ! sudo_execute "mv $dest $backup_dest"; then
                log_message "Failed to move existing destination to backup." "ERROR"
                return 1
            fi
        else
            log_message "Destination path is not available and --force was not used." "ERROR"
            return 1
        fi
    fi

    # 尝试创建软链接
    if ! ln -s "$src" "$dest"; then
        # 如果失败，检查是否由于权限问题
        if [ ! -w "$dest" ] || [ ! -w "$(dirname "$dest")" ]; then
            log_message "Attempting to create symbolic link with sudo..." "TRACE"
            if sudo_execute "ln -s $src  $dest"; then
                return 0
            else
                log_message "Failed to create symbolic link with sudo." "ERROR"
                return 1
            fi
        else
            log_message "Failed to create symbolic link for unknown reasons." "ERROR"
            return 1
        fi
    fi

    # 如果到这里，软链接创建成功
    return 0
}


#################################################################################################
# 创建目录
# 参数1 目标目录
# 参数2 --force 强制创建
#################################################################################################
create_directory() {
    local target_dir="$1"
    local force=false
    local create_cmd="mkdir -p \"$target_dir\""

    # 检查是否有 --force 参数
    if [[ "$2" == "--force" ]]; then
        force=true
    fi

    # 检查目录是否存在
    if [[ -d "$target_dir" ]]; then
        echo "Directory already exists: $target_dir"
        original_permissions=$(stat -c "%a" "$target_dir")
        chmod u+rw "$target_dir"
        # 如果需要恢复原始权限，可以使用以下命令
        # chmod "$original_permissions" "$target_dir"
        return 0
    fi

    # 尝试创建目录
    if eval "$create_cmd"; then
        echo "Directory created successfully: $target_dir"
        return 0
    else
        # 如果创建失败并且使用了 --force 参数，则尝试使用 sudo
        if $force; then
            echo "Initial attempt to create directory failed, trying with sudo..."
            create_cmd="sudo mkdir -p \"$target_dir\""
            if eval "$create_cmd"; then
                echo "Directory created successfully with sudo: $target_dir"
                return 0
            else
                echo "Failed to create directory with sudo: $target_dir"
                return 1
            fi
        else
            echo "Failed to create directory: $target_dir"
            return 1
        fi
    fi
}
#################################################################################################
# 创建目录 获取root密码时候使用图形密码框
# 参数1 目标目录
# 参数2 --force 强制创建
#################################################################################################
create_directory_gui() {
    local target_dir="$1"
    local force=false
    local create_cmd="mkdir -p \"$target_dir\""

    # 检查是否有 --force 参数
    if [[ "$2" == "--force" ]]; then
        force=true
    fi

    show_who_call

    # 检查目录是否存在
    if [[ -d "$target_dir" ]]; then
        echo "Directory already exists: $target_dir"
        original_permissions=$(stat -c "%a" "$target_dir")
        chmod u+rw "$target_dir"
        # 如果需要恢复原始权限，可以使用以下命令
        # chmod "$original_permissions" "$target_dir"
        return 0
    fi

    # 尝试创建目录
    if eval "$create_cmd"; then
        echo "Directory created successfully: $target_dir"
        return 0
    else
        # 如果创建失败并且使用了 --force 参数，则尝试使用 sudo
        if $force; then
            echo "Initial attempt to create directory failed, trying with sudo..."
            create_cmd="sudo_execute_gui mkdir -p \"$target_dir\""
            if eval "$create_cmd"; then
                echo "Directory created successfully with sudo: $target_dir"
                return 0
            else
                echo "Failed to create directory with sudo: $target_dir"
                return 1
            fi
        else
            echo "Failed to create directory: $target_dir"
            return 1
        fi
    fi
}
#################################################################################################
# 检查是否可以访问互联网
#################################################################################################
check_internet() {
    if ping -c 1 223.5.5.5 > /dev/null 2>&1; then
        echo "可以访问互联网"
        return 0
    else
        echo "无法访问互联网"
        return 1
    fi
}

#################################################################################################
# 检查是否可以访问指定的内网IP
#################################################################################################
check_intranet_ip() {
    local ip=$1
    if ping -c 1 $ip > /dev/null 2>&1; then
        echo "可以访问内网IP: $ip"
        return 0
    else
        echo "无法访问内网IP: $ip"
        return 1
    fi
}

#################################################################################################
check_connectivity_innerusage() {
        echo "用法: $0 <功能> [内网IP]"
        echo "功能: internet - 检查互联网连接"
        echo "      intranet - 检查到指定内网IP的连接"
        exit 1
    }

#################################################################################################
# 检查是否可以访问网络
# 可以访问 返回 0 
# 不可以  返回 1
#################################################################################################
check_connectivity(){
    # 检查是否提供了足够的参数
    if [ $# -lt 1 ]; then
        check_connectivity_innerusage
    fi

    # 根据提供的功能参数执行相应的检查
    case $1 in
        internet)
            check_internet
            ;;
        intranet)
            if [ -z "$2" ]; then
                echo "请指定一个内网IP地址"
                check_connectivity_innerusage
            fi
            check_intranet_ip $2
            ;;
        *)
            check_connectivity_innerusage
            ;;
    esac
}

#################################################################################################
# 使用 grep 和 cut 和 awk 实现的获取指定字符串中的项目的值的函数
# 主要用于获取包含复杂参数组合的程序启动命令字符串中指定项目的值 如下面一行命令里的端口号等
# /usr/bin/x11vnc -display :0 -auth guess -forever -rfbauth /etc/x11vnc.pass -shared -rfbport 55900

# 在下面三个实现中，都假设项目后面的值是由空格分隔的。
# 如果实际字符串中项目和值之间可能有其他字符（如等号、冒号等），
# 需要相应地调整正则表达式或 awk 脚本。
# 此外，如果字符串中有多个相同的项目，这些函数将只返回第一个匹配项的值。
# 如果需要所有匹配项的值，可以移除 head -n 1 并处理输出的多个行。
#################################################################################################
extract_item_grep() {
    local input_string="$1"
    local item="$2"
    echo "$input_string" | grep -oP "(?<=$item )\S+" | head -n 1
}

# 示例用法
# input_string="/usr/bin/x11vnc -display :0 -auth guess -forever -rfbauth /etc/x11vnc.pass -shared -rfbport 55900"
# item_value=$(extract_item_grep "$input_string" "auth")
# echo "AUTH value: $item_value"  # 输出: guess

# item_value=$(extract_item_grep "$input_string" "rfbport")
# echo "RFBPORT value: $item_value"  # 输出: 55900


# 这里使用了 grep 的 -oP 选项，其中 -o 表示只输出匹配的部分，-P 表示使用 Perl 兼容的正则表达式。正则表达式 (?<=$item )\S+ 匹配指定项目后面的非空白字符序列。head -n 1 确保只输出第一个匹配项，以防有多个相同的项目在字符串中出现。

#################################################################################################
# 使用 sed 的实现 (功能见上面 extract_item_grep 函数的介绍部分)
#################################################################################################
extract_item_sed() {
    local input_string="$1"
    local item="$2"
    echo "$input_string" | sed -n "s/.*$item \([ ]*\).*/\1/p" | head -n 1
}

# 示例用法
# input_string="/usr/bin/x11vnc -display :0 -auth guess -forever -rfbauth /etc/x11vnc.pass -shared -rfbport 55900"
# item_value=$(extract_item_sed "$input_string" "auth")
# echo "AUTH value: $item_value"  # 输出: guess

# item_value=$(extract_item_sed "$input_string" "rfbport")
# echo "RFBPORT value: $item_value"  # 输出: 55900

# 这里使用了 sed 的 -n 选项和 s 命令。正则表达式 .*$item \([ ]*\).* 匹配整个字符串，但只替换为指定项目后面的非空白字符序列（由 \([ ]*\) 捕获），并通过 \1 输出这个捕获的部分。head -n 1 同样用于确保只输出第一个匹配项。

#################################################################################################
# 使用 awk 的实现 (功能见上面 extract_item_grep 函数的介绍部分)
#################################################################################################
extract_item_awk() {
    local input_string="$1"
    local item="$2"
    echo "$input_string" | awk -v item="$item" '{
        for (i = 1; i <= NF; i++) {
            if ($i == item && i+1 <= NF) {
                print $(i+1);
                break;
            }
        }
    }' | head -n 1
}

# 示例用法
# input_string="/usr/bin/x11vnc -display :0 -auth guess -forever -rfbauth /etc/x11vnc.pass -shared -rfbport 55900"
# item_value=$(extract_item_awk "$input_string" "auth")
# echo "AUTH value: $item_value"  # 输出: guess

# item_value=$(extract_item_awk "$input_string" "rfbport")
# echo "RFBPORT value: $item_value"  # 输出: 55900


# 这里使用了 awk 的 -v 选项来传递一个变量 item 到 awk 脚本中。然后，我们遍历每个字段，检查它是否等于指定的项目。如果是，并且下一个字段存在（i+1 <= NF），则打印下一个字段的值。head -n 1 同样用于确保只输出第一个匹配项。

#################################################################################################
# 读取INI文件
#   使用echo 返回获取到的值,因此此函数内部需要避免输出任何信息到终端.
#################################################################################################
read_ini_file(){
    local ini_file=$1
    local section=$2
    local option=$3
    local value

    #value=$(awk -F '=' "/\[$section\]/, /^\[.*\]/ { if (\$1 == \"$option\") print \$2 }" $ini_file)
    value=`awk -F '=' '/\['${section}'\]/{a=1}a==1&&$1~/'${option}'/{print $2;exit}' ${ini_file}`

    if [ -z "$value" ];then
        LOG_message "获取文件 $ini_file 中 [$section] 内 $option 的值 失败:$value ." "ERROR"
        return 1
    else
        LOG_message "获取文件 $ini_file 中 [$section] 内 $option 的值 成功:$value ." "INFO"
        # 因为只能 return 数字,所以为了能传递较复杂的字符串,使用了echo.
        echo $value
    fi
}

#################################################################################################
# 写入INI文件
#################################################################################################
write_ini_file(){
    local ini_file=$1
    local section=$2
    local option=$3
    local value=$4

    local ltmp_b_get_attr_use_root=false
    local ltmp_b_writable=true

    local ini_file_tp=$1
    local ltmp_ini_backup_no=""

    local backup_file="${this_BACKUP_DIR}/$(basename $ini_file).backup"  # 临时文件夹，可以根据需要修改
    local temp_file="${this_TMP_DIR}/$(basename $ini_file).temp"

    # 检查文件是否存在
    if [[ ! -f "$ini_file" ]]; then
        log_message "File '$ini_file' does not exist." "WARNING"
        echo 
        read -p "Do you want to create it? 文件不存在,是否创建? yes (y) / no (n): " ltmp_create_response
        if [[ "$ltmp_create_response" == "yes" || "$ltmp_create_response" == "y" ]]; then
            touch "${ini_file}"
            local ltmp_touch_ret1=$?
            case $ltmp_touch_ret1 in
                1)
                    sudo_execute "touch ${ini_file}"
                    case $ltmp_touch_ret in
                        1)
                            log_message "创建文件 ${ini_file} 失败. 返回值 ${ltmp_touch_ret} ." "ERROR"
                            ;;
                        *)
                            log_message "创建文件 ${ini_file} 成功. 返回值 ${ltmp_touch_ret} ." "INFO"
                            ;;
                    esac
                    ;;
                *)
                    log_message "创建文件 ${ini_file} 成功."
                    ;;
            esac               
        else
            log_message "No changes made based on your choice." "WARNING"
            return 1
        fi
    fi

    ltmp_ini_backup_no=$(backup_and_log "$ini_file") 
    if [ -z "$ltmp_ini_backup_no" ] || [ "$ltmp_ini_backup_no" == "1" ]; then
        log_message "使用脚本函数 backup_and_log 备份文件 $ini_file 失败,返回值 $ltmp_ini_backup_no .即将使用cp命令备份." "ERROR"
        sudo_execute "cp $ini_file $backup_file"
        if [ "$?" == "1" ];then
            log_message "备份失败,即将退出." "ERROR"
            exit 1
        fi
    else
        log_message "使用函数 backup_and_log 备份文件 $ini_file 获得的唯一编码为 $ltmp_ini_backup_no .该编码可用于查找该备份文件,以便在出现问题时能用于恢复."
    fi

    # 检查文件是否有写权限
    if [[ ! -w "$ini_file" ]]; then
        log_message "No write permission for '$ini_file'. "  "WARNING"
        ltmp_b_writable=false

        # 获取文件属性
        local file_owner=$(stat -c '%U' "$ini_file")
        local file_group=$(stat -c '%G' "$ini_file")
        local file_mode=$(stat -c '%A' "$ini_file")
        local file_perm=$(stat -c '%a' "$ini_file")  # 数值形式的权限

        if [ -z "$file_owner" ] || [ -z "$file_group" ] || [ -z "$file_mode" ] || [ -z "$file_perm" ]; then
            log_message "获取文件 $ini_file 属性失败: file_owner=$file_owner file_group=$file_group file_mode=$file_mode file_perm=$file_perm ."  "ERROR"
            file_owner=$(sudo_execute "stat -c '%U' $ini_file")
            file_group=$(sudo_execute "stat -c '%G' $ini_file")
            file_mode=$(sudo_execute "stat -c '%A' $ini_file")
            file_perm=$(sudo_execute "stat -c '%a' $ini_file")
            ltmp_b_get_attr_use_root=true
            if [ -z "$file_owner" ] || [ -z "$file_group" ] || [ -z "$file_mode" ] || [ -z "$file_perm" ]; then
                log_message "使用ROOT权限获取文件 $ini_file 属性失败: file_owner=$file_owner file_group=$file_group file_mode=$file_mode file_perm=$file_perm ."  "ERROR"  
                return 1
            fi
        else
            log_message "获取文件 $ini_file 属性: file_owner=$file_owner file_group=$file_group file_mode=$file_mode file_perm=$file_perm ." "INFO"
        fi
        
        # 使用 sudo 复制文件到临时目录
        sudo_execute "cp $ini_file $temp_file"
        
        # 修改文件副本权限以便当前用户可以写入
        #   这里设置为可读写，也可以根据需要设置其他权限
        sudo_execute "chmod 666 $temp_file "  

        # 将变量 ini_file 指向临时文件,供后面继续修改操作.
        #   ini_file_tp 同样保存了原始的文件名
        ini_file="$temp_file"
        log_message "变量 ini_file 已修改为 $ini_file ." "WARNING"
        
    fi

    log_message "正在对文件 $ini_file 进行操作."  "WARNING"

    # 检查并添加section
    if ! grep -q "\[$section\]" $ini_file; then
        
        log_message "写入空行到文件 $ini_file ." "TRACE"
        echo  >> $ini_file

        log_message "写入 [$section] 到文件 $ini_file ." "TRACE"
        echo "[$section]" >> $ini_file
    fi

    # 检查并替换或添加option=value
    if ! grep -q "^$option=" $ini_file; then
        log_message "写入 $option=$value 到文件 $ini_file 的 [$section]." "TRACE"
        echo "$option=$value" >> $ini_file
    else

        log_message "即将修改文件 $ini_file 段 $section ,$option = $value ." "TRACE"
        #set -x 

        #获取要修改文件的行号
        #local ltmp_line_no=$(sed -n "/${option}=/=" "$ini_file")  #虽然多数情况是确定的,但仍有可能出现结果为多行因此作以下修改 2024-11-27
        # 使用 sed 获取匹配行的行号，并将结果存储到数组中
        # 注意：这里使用了 IFS（内部字段分隔符）来确保行号被正确分割到数组中
        local ltmp_line_no_array
        local ltmp_line_no=""
        local ltmp_newline_no=""
        #IFS=$'\n' read -d '' -r -a ltmp_line_no_array < <(sed -n "/${option}=/=" "$ini_file")

        # 使用 mapfile（或 readarray）获取匹配行的行号到数组中
        mapfile -t ltmp_line_no_array < <(sed -n "/${option}=/=" "$ini_file")


        # 检查数组是否为空,这里有点多余了但为了以后写代码时候能够多 COPY 所以还是加上了.
        if [ ${#ltmp_line_no_array[@]} -eq 0 ]; then
            echo "未找到匹配项。"
            return 1
        fi

        # 检查数组长度是否大于1
        if [ ${#ltmp_line_no_array[@]} -gt 1 ]; then
            echo "#### $ini_file 文件内容  ###########################"
            echo "  行号    内容"
            cat $ini_file -n
            echo "#### $ini_file 文件匹配 ${option}\= 内容的行 ###########"
            cat $ini_file -n | grep  "${option}\="
            echo "#### $ini_file 检索结果  ###########################"
            echo "找到多个匹配项，请输入行号或输入 'all' 来替换所有行.(直接回车则只替换第一个匹配的行)："
            # 读取用户输入
            local ltmp_ini_user_input
            read -r ltmp_ini_user_input
            
            # 检查用户输入
            if [[ "$ltmp_ini_user_input" =~ [0-9]+$ ]]; then
                # 如果用户输入的是数字，检查是否在数组范围内
                if [[ " ${ltmp_line_no_array[*]} " =~ " ${ltmp_ini_user_input} " ]]; then
                    echo "你选择了行号：$ltmp_ini_user_input"

                    ltmp_line_no=$ltmp_ini_user_input
                    ######这部分可以复用,暂时没空,有时间再写####### 开始 #############
                    ltmp_newline_no=$(expr $ltmp_line_no - 1)
                    
                    log_message "插入新内容的行号 $ltmp_newline_no" "WARNING"
                    
                    # 删除行
                    sed  -i  "$ltmp_line_no  d"   "$ini_file"

                    # 将拼接好的字符串写入行
                    sed -i "${ltmp_newline_no} a\\${option}=${value}"  "$ini_file"
                    if [ $? -eq 0 ];then
                        log_message "修改 $option 的值为 $value 到文件 $ini_file 成功." "TRACE"
                    fi 
                    ######这部分可以复用,暂时没空,有时间再写####### 结束 #############
                else
                    echo "输入的行号不在匹配列表中。"
                fi
            elif [ "$ltmp_ini_user_input" == "all" ]; then
                # 如果用户输入的是 'all'，循环输出所有行号
                for ltmp_line_no in "${ltmp_line_no_array[@]}"; do
                    echo "处理行号：$ltmp_line_no"
                    ######这部分可以复用,暂时没空,有时间再写####### 开始 #############
                    ltmp_newline_no=$(expr $ltmp_line_no - 1)
                    
                    log_message "插入新内容的行号 $ltmp_newline_no" "WARNING"
                    
                    # 删除行
                    sed  -i  "$ltmp_line_no  d"   "$ini_file"

                    # 将拼接好的字符串写入行
                    sed -i "${ltmp_newline_no} a\\${option}=${value}"  "$ini_file"
                    if [ $? -eq 0 ];then
                        log_message "修改 $option 的值为 $value 到文件 $ini_file 成功." "TRACE"
                    fi 
                    ######这部分可以复用,暂时没空,有时间再写####### 结束 #############
                done
            else
                # 如果用户没有输入或输入无效，默认选择第一个行号
                echo "没有输入或输入无效，默认处理第一个匹配项，行号为：${ltmp_line_no_array}"
                ltmp_line_no=${ltmp_line_no_array}
                ######这部分可以复用,暂时没空,有时间再写####### 开始 #############
                ltmp_newline_no=$(expr $ltmp_line_no - 1)
                    
                log_message "插入新内容的行号 $ltmp_newline_no" "WARNING"
                
                # 删除行
                sed  -i  "$ltmp_line_no  d"   "$ini_file"

                # 将拼接好的字符串写入行
                sed -i "${ltmp_newline_no} a\\${option}=${value}"  "$ini_file"
                if [ $? -eq 0 ];then
                    log_message "修改 $option 的值为 $value 到文件 $ini_file 成功." "TRACE"
                fi 
                ######这部分可以复用,暂时没空,有时间再写####### 结束 #############
            fi
        else
            # 如果只有一个匹配项，直接输出行号
            echo "找到单个匹配项，行号为：${ltmp_line_no_array}"
            ltmp_line_no=${ltmp_line_no_array}
            ######这部分可以复用,暂时没空,有时间再写####### 开始 #############
            ltmp_newline_no=$(expr $ltmp_line_no - 1)
                    
            log_message "插入新内容的行号 $ltmp_newline_no" "WARNING"
            
            # 删除行
            sed  -i  "$ltmp_line_no  d"   "$ini_file"

            # 将拼接好的字符串写入行
            sed -i "${ltmp_newline_no} a\\${option}=${value}"  "$ini_file"
            if [ $? -eq 0 ];then
                log_message "修改 $option 的值为 $value 到文件 $ini_file 成功." "TRACE"
            fi 
            ######这部分可以复用,暂时没空,有时间再写####### 结束 #############
        fi




        log_message "获取要修改的项目在文件的行号为 $ltmp_line_no" "WARNING"

        # 计算插入文件的新的位置 后面使用追加方式修改文本,故这里 ltmp_line_no-１
        #local ltmp_newline_no=$(expr "$ltmp_line_no" - "1")  #2024-11-27  收到错误提示 expr: 非整数参数

        ### 下面部分 从 2024-11-27 开始注释,因为已经将代码挪到上面了 ######开始#########
        # ltmp_newline_no=$(expr $ltmp_line_no - 1)
        # log_message "插入新内容的行号 $ltmp_newline_no" "WARNING"
        
        # # 删除行
        # sed  -i  "$ltmp_line_no  d"   "$ini_file"

        # # 将拼接好的字符串写入行
        # sed -i "${ltmp_newline_no} a\\${option}=${value}"  "$ini_file"
        # if [ $? -eq 0 ];then
        #     log_message "修改 $option 的值为 $value 到文件 $ini_file 成功." "TRACE"
        # fi 
        ### 下面部分 从 2024-11-27 开始注释,因为已经将代码挪到上面了 ###### 结束 #########

        # 检查替换是否成功(实验,不影响结果)
        # if awk -v section="[$section]" -v item="$item" -v value="$value" '
        #     BEGIN { found = 0 }
        #     $0 ~ section && $0 ~ item "=" value { found = 1 }
        #     END { exit !found }
        # ' "$ini_file"; then
        #     success=1
        # fi

    fi

    if [ $ltmp_b_writable = false ];then
        #if [ $ltmp_b_get_attr_use_root == true ];then
        log_message "恢复文件 $ini_file 属性信息." "TRACE"
        # 恢复文件权限和属性
        sudo_execute "chown $file_owner:$file_group  $ini_file"
        sudo_execute "chmod $file_perm $ini_file"

        # 使用文件副本替换原始文件. ini_file_tp 保存原始文件名 
        sudo_execute "cp -f $ini_file $ini_file_tp"
    fi

    return 0
}



#################################################################################################
# 写入class文件
#################################################################################################
# 示例用法
#write_class_file "/path/to/your/file.txt" "classC" "item5" "new value1 new value2 new value3" --endsemi --useeq
#################################################################################################
# 要修改或建立的文件的主要内容如下
# classA {
#     item1 valueofitem1
# }

# classB{item2 valueofitem2}

# classC{
#     item 3 valueofitem3
#     item4 valueofitem4
#     item5 value1ofitem5 value2ofitem5 value3ofitem6
# }
#################################################################################################

# 调用示例
#write_class_file "/path/to/your/file.policy" "myClass" "permission" "java.security.AllPermission" --endsemi --useeq
    # 下面是我的脚本调用函数的语句
    # write_class_file "/home/pangu/java.txt" "classA" "item1" "valueofitem1" 
    # write_class_file "/home/pangu/java.txt" "classB" "item2" "valueofitem2"
    # write_class_file "/home/pangu/java.txt" "classC" "item3" "valueofitem3"
    # write_class_file "/home/pangu/java.txt" "classC" "item4" "valueofitem4"
    # write_class_file "/home/pangu/java.txt" "classC" "item5" "value1ofitem5 value2ofitem5 value3ofitem5"

    # 下面是生成的文件内容
  
#未优化的版本
write_class_file_() {
    local file_path=$1
    local class_name=$2
    local project_name=$3
    local project_value=$4
    local endsemi=false
    local use_eq=false

    # 处理可选参数
    shift 4
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --endsemi)
                endsemi=true
                ;;
            --useeq)
                use_eq=true
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done
    
    # 确定项目和值之间的连接符
    local connector
    if $use_eq; then
        connector="="
    else
        connector=" "
    fi

    # 临时文件来存储修改后的内容
    local temp_file=$(mktemp)

    # 标记是否处于指定的类定义内部
    local inside_class=false

    # 标记是否处于其他类定义内部
    local other_class=false

    # 标记是否已经在该类中添加了项目
    local project_added=false

    # 可能的类名临时变量
    local potential_class_name=""

    # 取出的项目名临时变量
    local current_project_name=""

    echo_double_line
    echo "Func is start"
    echo_double_line

    # 读取原文件并处理
    while IFS= read -r line; do
        # 去除行尾的空格
        line=$(echo "$line" | sed 's/[[:space:]]*$//')

        if [ -z "$line" ];then
            echo "$line" >> "$temp_file"
        else
            # 检查是否处于指定的类定义内部
            if $inside_class; then            
                if [[ "$line" != "};" ]] && [[ "$line" != "}" ]] ; then
                    # 提取行首的项目名（假设项目名后面紧跟一个空格或连接符）
                    current_project_name=$(echo "$line" | awk '{print $1}')
                    # 去除项目名末尾的空格（如果有的话）
                    current_project_name=$(echo "$current_project_name" | sed 's/[[:space:]]*$//')
                    
                    if [[ "$current_project_name" == "$project_name" ]]; then
                        echo "      ${project_name}${connector}${project_value};" >> "$temp_file"
                        project_added=true
                    else
                        # 如果不是指定的项目名行，直接复制行到临时文件
                        echo "$line" >> "$temp_file"
                    fi
                else
                    # 类结束
                    # 已经在要操作的类内部,到最后还没找到项目,就该添加了.
                    if ! $project_added; then
                        # 替换或添加项目行
                        echo "      ${project_name}${connector}${project_value};"
                        echo "      ${project_name}${connector}${project_value};" >> "$temp_file"
                        project_added=true
                    fi
                    echo "$line"
                    echo "$line" >> "$temp_file"
                    # 类结束，重置标记，并输出类结束符号
                    inside_class=false
                fi
                
            
            else
            
                # 因为函数的一次调用只会操作一个Project_name条目,因此一旦前面已经添加或修改了条目,后面就不必浪费操作了.
                if [ $project_added == true ];then
                    #echo "$line" >> "$temp_file"
                    log_message "指定条目已经修改或添加,此后将不再判断直接输出."  "TRACE"
                else
                    if [ $other_class == true ];then
                        if [[ "$line" == "};" ]] || [[ "$line" == "}" ]] ; then
                            other_class=false
                        fi    
                    else              
                        # 提取{之前的部分作为潜在的类名，并去掉末尾的空格
                        echo "......Geting a string which like a classname."
                        echo "The line is : [$line] .."
                        potential_class_name=$(echo "$line" | sed 's/{.*$//' | sed 's/[[:space:]]*$//')

                        echo ""potential_class_name == class_name""
                        echo ""$potential_class_name == $class_name""
                        
                        if [[ "$potential_class_name" == "$class_name" ]]; then
                            # 找到了指定的类名，设置标记
                            inside_class=true
                            #project_added=false # 重置项目添加标记
                            #echo "$line" >> "$temp_file"
                        else
                            # 如果不是指定的类名定义开始，直接复制行到临时文件
                            other_class=true
                            #echo "$line" >> "$temp_file"
                        fi
                    fi
                
                fi
                
                echo "$line"
                echo "$line" >> "$temp_file"
                
            fi
        fi
    done < "$file_path"

    # 如果在整个文件中都没有添加或修改过项目就新建
    
    if [ $project_added = false ]; then
        #echo_double_line
        #echo "File is end ,and find no class ,now add it."
        #echo_double_line
        #echo "${class_name} {"
        echo "${class_name} {" >> "$temp_file"

        #echo "      ${project_name}${connector}${project_value};"
        echo "      ${project_name}${connector}${project_value};" >> "$temp_file"
        
        if $endsemi; then
            #echo "};"
            echo "};" >> "$temp_file"
        else
            #echo "}"
            echo "}" >> "$temp_file"
        fi

        #echo ""
        echo "" >> "$temp_file" # 添加空行以分隔类
    fi

    # 替换原文件
    mv "$temp_file" "$file_path"

}

####################################################################
# 正在优化

declare -a comment_symbol_array

# 在调用 write_class_file 函数之前设置支持的注释符号
#   comment_symbol_array=("#" "//")

write_class_file_Modifing() {
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

    # 读取原文件并处理
    while IFS= read -r line; do
        # 去除行尾的空格
        line=$(echo "$line" | sed 's/[[:space:]]*$//')

        if [ -z "$line" ];then
            echo "$line" >> "$ltmp_temp_file"
            continue
        fi

        # 先假设不是注释行
        is_comment=false
        for symbol in "${comment_symbols[@]}"; do
            if [[ "$line" == "$symbol"* ]]; then
                is_comment=true
                break
            fi
        done

        # 如果行是注释，则直接写入临时文件并继续下一行
        if [[ "$is_comment" == true ]]; then
            echo "$line" >> "$temp_file"
            continue
        fi

        # 这里还需要增加其他判断或在 # LABLE__B 处增加判断,
        #   如含注释的行,item 的 value也包含大括号.
        #   或是同一行内同时也出现值的定义的情况.
        
        # 检查是否处于指定的类定义内部
        if $ltmp_inside_class; then            
            if [[ "$line" != "};" ]] && [[ "$line" != "}" ]] ; then
                # LABLE__B
                # 存在item value };或
                #     item value } 的情况.这样后面就找不到类范围的结束符号了.

                # 提取行首的项目名（假设项目名后面紧跟一个空格或连接符）
                ltmp_current_project_name=$(echo "$line" | awk '{print $1}')
                # 去除项目名末尾的空格（如果有的话）
                ltmp_current_project_name=$(echo "$ltmp_current_project_name" | sed 's/[[:space:]]*$//')
                
                if [[ "$ltmp_current_project_name" == "$ltmp_item_name" ]]; then
                    echo "      ${ltmp_item_name}${ltmp_connector}${ltmp_item_value};" >> "$ltmp_temp_file"
                    ltmp_project_added=true
                else
                    # 如果不是指定的项目名行，直接复制行到临时文件
                    echo "$line" >> "$ltmp_temp_file"
                fi
            else
                # 这行如果是整行只有类结束符的情况,现实情况可能出现类结束符出现在item itemvalue 后面.
                #   这种情况暂未考虑,需后期增加.

                # 已经在要操作的类内部,到最后还没找到项目,就该添加了.
                if ! $ltmp_project_added; then
                    # 替换或添加项目行
                    #echo "      ${ltmp_item_name}${ltmp_connector}${ltmp_item_value};"
                    echo "      ${ltmp_item_name}${ltmp_connector}${ltmp_item_value};" >> "$ltmp_temp_file"
                    ltmp_project_added=true
                fi
                
                echo "$line" >> "$ltmp_temp_file"
                # 类结束，重置标记，并输出类结束符号
                ltmp_inside_class=false
            fi
            
        
        else
            echo "$line" >> "$ltmp_temp_file"

            # 因为函数的一次调用只会操作一个ltmp_item_name条目,因此一旦前面已经添加或修改了条目,后面就不必浪费操作了.
            if [ $ltmp_project_added == true ];then
                #echo "$line" >> "$ltmp_temp_file"
                continue
                log_message "指定条目已经修改或添加,此后将不再判断直接无脑输出."  "TRACE"
            fi

            if [ $ltmp_other_class == true ];then
                if [[ "$line" == "};" ]] || [[ "$line" == "}" ]] ; then
                    ltmp_other_class=false
                fi
                continue
            fi

            # 提取{之前的部分作为潜在的类名，并去掉末尾的空格
            ltmp_potential_class_name=$(echo "$line" | sed 's/{.*$//' | sed 's/[[:space:]]*$//')

            #echo ""$ltmp_potential_class_name == $ltmp_class_name""
            
            if [[ "$ltmp_potential_class_name" == "$ltmp_class_name" ]]; then
                # 找到了指定的类名，设置标记
                if [[ "$line" == *"{"* ]]; then
                    ltmp_inside_class=true
                    #ltmp_project_added=false # 重置项目添加标记
                fi
                
                #echo "$line" >> "$ltmp_temp_file"
            else
                # 如果不是指定的类名定义开始，直接复制行到临时文件
                ltmp_other_class=true
                #echo "$line" >> "$ltmp_temp_file"
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

######################################################
# 正则表达式过于复杂导致bash无法正确处理.正寻求其他解决方案
######################################################
write_class_file_error() {
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
        # is_comment=false
        # for symbol_tp in "${comment_symbols[@]}"; do
        #     if [[ "$trimmed_line" == "$symbol_tp"* ]]; then
        #         is_comment=true
        #         break
        #     fi
        # done

        # 辨别是否是注释行
        if [[ "$trimmed_line" =~ $comment_regex ]];then
            is_comment=true
        else
            is_comment=false
        fi

        # 注释行 直接搬运
        if [[ "$is_comment" == true ]]; then
            echo "$line" >> "$ltmp_temp_file"
            continue
        fi

        bool_finash_class_this_line=false

        # 分号(";")起始,有两种可能 
        #   1.此次循环之前的部分可能是个完整的类定义
        #   2.此次循环之前的部分可能是个 project_name project_value 的行
        if [[ "$trimmed_line" == ";"* ]]; then
            # 不确定的情况是检测到字符串但未找到类开始符号.既然看到分号了说明确定不是开始了,所以清除一下变量状态后可以直接搬运了
            if [[ $bool_line_might_be_inside_class == true ]] || [[ $bool_line_might_be_other_class == true ]] ;then
                bool_line_might_be_inside_class=false
                bool_line_might_be_other_class=false
                #bool_finash_class_this_line=false
                ltmp_inside_class=false
                ltmp_other_class=false
            fi

            # 对于已经确定的,由于未看到结束符号,因此把";"当作空行或者一个project_name project_value写在了第二行的结束符号,无脑搬运且不改变状态
            echo "$line" >> "$ltmp_temp_file"
            continue
        fi

        # 结束符号起始
        if [[ "$trimmed_line" == "}"* ]] || [[ "$trimmed_line" == "};"* ]]; then
            # 清除一下这两个变量的状态,不确定的都已经确定或者无所谓了
            if [[ $bool_line_might_be_inside_class == true ]] || [[ $bool_line_might_be_other_class == true ]] ;then
                bool_line_might_be_inside_class=false
                bool_line_might_be_other_class=false
            fi
            
            bool_finash_class_this_line=true
            ltmp_inside_class=false
            ltmp_other_class=false

            echo "$line" >> "$ltmp_temp_file"
            continue
        fi

        # 实锤
        if [[ "$trimmed_line" == "{"* ]] ; then
            if [[ $bool_line_might_be_other_class == true ]] ;then
                bool_line_might_be_other_class=false
                ltmp_other_class=true
            elif [[ $bool_line_might_be_inside_class == true ]];then
                bool_line_might_be_inside_class=false
                ltmp_inside_class=true
            else
                # 不能确定就还是搬运.
                echo "$line" >> "$ltmp_temp_file"
            fi

            # 清除一下这两个变量的状态,不确定的都已经确定或者无所谓了
            if [[ $bool_line_might_be_inside_class == true ]] || [[ $bool_line_might_be_other_class == true ]] ;then
                bool_line_might_be_inside_class=false
                bool_line_might_be_other_class=false
            fi

            # 精神错乱
            if [[ $ltmp_other_class == true ]] && [[ $ltmp_inside_class == true ]];then
                log_message "因为工资少,所以工资多..." "ERROR"
                return 1
            fi
        fi

        ######################################################################################################################################
        # 在其他类内 无脑输出.遇到包含结束符的行就设置一下ltmp_other_class=false 以便下次循环不再进入此段
        if [ $ltmp_other_class == true ];then
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
            #ltmp_first_str=$(echo "$trimmed_line" | sed -E "s/([[:alnum:]]+)([[:space:]]*{|}|$comment_regex|[[:alnum:]]).*/\1/")
            ltmp_first_str=$(echo "$trimmed_line" | awk -F '[[:space:]]*{|}|' '{print $1}')

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
                    if [[ $bool_line_might_be_inside_class == true ]] || [[ $bool_line_might_be_other_class == true ]] ;then
                        bool_line_might_be_inside_class=false
                        bool_line_might_be_other_class=false
                    fi

                    continue
                fi
                
                #这段没用了,逻辑梳理了一下.此处仅用于语法参考 2024-12-02 23:22  
                # 检查该行末尾是否以右大括号结束 假设类内项目的值或者名字不以大括号括定 如右边这种情况假设不存在:  class_user_info{ bin_dir {/usr/bin /opt/bin}}
                # if [[ "$remaining_line_without_comments" =~ \}$ ]] || [[ "$remaining_line_without_comments" =~ \};$ ]]; then
                #     # 如果是右大括号，则输出到新行，并保持注释部分不变
                #     #echo "${trimmed_line%%}*" | sed -E "s/.*}//}" > "new_line.txt"
                #     # 标记为不再处于类定义内部
                #     bool_finash_class_this_line=true
                #     bool_line_might_be_other_class=false
                #     ltmp_other_class=false
                #     continue
                # fi
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
        if [[ $ltmp_inside_class == true ]]; then            
            if [[ "$line" != "};" ]] && [[ "$line" != "}" ]] ; then
                
                # 提取行首的项目名（假设项目名后面紧跟一个空格或连接符）
                ltmp_current_project_name=$(echo "$line" | awk '{print $1}')

                # 去除项目名末尾的空格（如果有的话）
                ltmp_current_project_name=$(echo "$ltmp_current_project_name" | sed 's/[[:space:]]*$//')

                # 去掉类名后的部分，并去掉行首的空格
                remaining_line_intp=$(echo "$trimmed_line" | sed -E "s/$ltmp_first_str[[:space:]]*//")

                # 去掉行尾的注释部分
                remaining_line_without_comments_intp=$(echo "$remaining_line_intp" | sed -E "s/$comment_regex//")
              
                # 目标类已经找到了且添加或修改完成了,剩下的部分就不需要再浪费操作去分析了.只看这行是不是要结束就可以了.
                if [[ $ltmp_project_added == true ]];then
                    echo "$line" >> "$ltmp_temp_file"

                    # 如果本行原文结尾包含 }, 则 ltmp_inside_class=false 下次循环就不再继续处理.并且在需要补一个结束符
                    if [[ "$remaining_line_without_comments_intp" == *"};" ]] || [[ "$remaining_line_without_comments_intp" == *"}" ]] ; then
                        if $ltmp_endsemi; then
                            echo "};" >> "$ltmp_temp_file"
                        else
                            echo "}" >> "$ltmp_temp_file"
                        fi

                        bool_finash_class_this_line=true
                        ltmp_inside_class=false
                        continue
                    fi

                    continue
                fi

                # 找到project_name
                if [[ "$ltmp_current_project_name" == "$ltmp_item_name" ]]; then

                    # 改写为新值
                    echo "      ${ltmp_item_name}${ltmp_connector}${ltmp_item_value};" >> "$ltmp_temp_file"
                    ltmp_project_added=true

                    # 如果本行原文结尾包含 }, 则 ltmp_inside_class=false 下次循环就不再继续处理.并且在需要补一个结束符
                    if [[ "$remaining_line_without_comments_intp" == *"};" ]] || [[ "$remaining_line_without_comments_intp" == *"}" ]] ; then

                        if $ltmp_endsemi; then
                            echo "};" >> "$ltmp_temp_file"
                        else
                            echo "}" >> "$ltmp_temp_file"
                        fi

                        bool_finash_class_this_line=true
                        ltmp_inside_class=false
                        continue

                    fi
                    continue
                else
                    # 本行处理时目标项目并未添加或修改,此时本行的项目名不匹配
                    
                    # 如果本行原文结尾包含 }, 则 ltmp_inside_class=false 下次循环就不再继续处理.
                    if [[ "$remaining_line_without_comments_intp" == *"};" ]] || [[ "$remaining_line_without_comments_intp" == *"}" ]] ; then

                        # 输出去掉类结束符的本行内容(避免还没添加目标项目就结束了)
                        
                        if $ltmp_endsemi; then
                            line_without_class_endsemi=$(echo "$line" | sed -E "s/[[:space:]]*};//")
                            #echo "};" >> "$ltmp_temp_file"
                        else
                            line_without_class_endsemi=$(echo "$line" | sed -E "s/[[:space:]]*}//")
                            #echo "}" >> "$ltmp_temp_file"
                        fi

                        echo "$line_without_class_endsemi" >> "$ltmp_temp_file"
                        echo "      ${ltmp_item_name}${ltmp_connector}${ltmp_item_value};" >> "$ltmp_temp_file"

                        if $ltmp_endsemi; then
                            echo "};" >> "$ltmp_temp_file"
                        else
                            echo "}" >> "$ltmp_temp_file"
                        fi

                        ltmp_project_added=true
                        bool_finash_class_this_line=true
                        ltmp_inside_class=false

                        continue
                    else
                        #确定本行不会结束该类的定义,则可以安全输出
                        echo "$line" >> "$ltmp_temp_file"
                    fi
                fi
                
                   
                
            else
                # 已经在要操作的类内部,到最后还没找到项目,就该添加了.
                if ! $ltmp_project_added; then
                    # 替换或添加项目行
                    #echo "      ${ltmp_item_name}${ltmp_connector}${ltmp_item_value};"
                    echo "      ${ltmp_item_name}${ltmp_connector}${ltmp_item_value};" >> "$ltmp_temp_file"
                    ltmp_project_added=true
                fi
                
                # 其实这行是原类定义的结束标志,这里搬运一下
                echo "$line" >> "$ltmp_temp_file"
                # 类结束，重置标记，并输出类结束符号
                ltmp_inside_class=false
            fi
            
        fi

        ######################################################################################
        # 逻辑变更了,下面没用了 comment from 2024-12-03 00:35    start 
        ######################################################################################
        # else
            
        #     #echo "$line" >> "$ltmp_temp_file"

        #     # 因为函数的一次调用只会操作一个ltmp_item_name条目,因此一旦前面已经添加或修改了条目,后面就不必浪费操作了.
        #     #comment from 20240-12-02  (start)
        #     # if [ $ltmp_project_added == true ];then
        #     #     #echo "$line" >> "$ltmp_temp_file"
        #     #     echo "$line" >> "$ltmp_temp_file"
        #     #     continue
        #     #     log_message "指定条目已经修改或添加,此后将不再判断直接无脑输出."  "TRACE"
        #     # fi

        #     # if [ $ltmp_other_class == true ];then
        #     #     if [[ "$line" == "};" ]] || [[ "$line" == "}" ]] ; then
        #     #         ltmp_other_class=false
        #     #     fi
        #     #     echo "$line" >> "$ltmp_temp_file"
        #     #     continue
        #     # fi
        #     # comment from 20240-12-02   (end)
            

        #     # 提取行首的字符串，直到遇到非字母数字字符、空格、制表符、左大括号或注释符号
        #     ltmp_first_str=$(echo "$trimmed_line" | sed -E "s/([[:alnum:]]+)([[:space:]]*{|}|$comment_regex|[[:alnum:]]).*/\1/")
    
        #     # 检查行首是否是 "ltmp_first_str;"（考虑空格和制表符）
        #     if [[ "$trimmed_line" =~ [[:space:]]*"$ltmp_first_str"[[:space:]]*\; ]]; then
        #         # 行首是 "ltmp_first_str;"，不符合我们要找的类 
        #         # 如果类的定义有变化,即空白名字被视为未包含内容的类可以在这里修改代码
        #         # 如 classA ; 如果将来被视为等同 classA {};
        #         echo "Skipping line: $line"
        #         echo "$line" >> "$ltmp_temp_file"
        #         continue
        #     fi

        #     # 检查行是否可能是类的开始（即包含类名）
        #     if [[ "$ltmp_first_str" == "$class_name"* ]]; then
        #         bool_line_might_be_class_start=true
        #         # 将这一行写入临时文件，因为它可能是类定义的开始
        #         echo "$line" >> "$temp_file"
        #         continue
        #     fi
            
        #     # 如果上一行可能是类的开始，检查这一行是否是类的实际开始
        #     if [[ "$bool_line_might_be_class_start" === true ]]; then
        #         # 去除行首的注释符号（使用之前定义的注释符号数组）
        #         line_without_comments=$(echo "$trimmed_line" | sed -E "s/${comment_regex}//")
                

        #         # 检查去除注释后的行首是否是左大括号
        #         if [[ "$line_without_comments" == "{"* ]]; then
        #             inside_class=true
        #             bool_line_might_be_class_start=false # 重置标志，因为我们已经找到了类的开始
        #         else
        #             # 如果这一行不是类的开始，重置标志
        #             bool_line_might_be_class_start=false
        #         fi
        #     fi

        #     # 提取{之前的部分作为潜在的类名，并去掉末尾的空格
        #     ltmp_potential_class_name=$(echo "$line" | sed 's/{.*$//' | sed 's/[[:space:]]*$//')

        #     echo ""$ltmp_potential_class_name == $ltmp_class_name""
            
        #     if [[ "$ltmp_potential_class_name" == "$ltmp_class_name" ]]; then
        #         # 找到了指定的类名，设置标记
        #         if [[ "$line" == *"{"* ]]; then
        #             ltmp_inside_class=true
        #             #ltmp_project_added=false # 重置项目添加标记
        #         fi
                
        #         #echo "$line" >> "$ltmp_temp_file"
        #     else
        #         # 如果不是指定的类名定义开始，直接复制行到临时文件
        #         ltmp_other_class=true
        #         #echo "$line" >> "$ltmp_temp_file"
        #     fi
        #     # classA
        #     # {
        #     #     itemA valueofitemA;
        #     #     itemB valueofitemB
        #     # }

        #     # classB
        #     # {   itemA valueofitemA;}

        #     # classC{itemB valueofitemB}

        #     # classD{
        #     #     itemE {value1 value2 value3}
        #     # }
            

        #fi
        ######################################################################################
        # 逻辑变更了,下面没用了 comment from 2024-12-03 00:35    end 
        ######################################################################################
        ######################################################################################################################################
        
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
#################################################################################################
# 函数定义
# 函数名：write_conf_file
# 描述：将指定的项目和值写入到文件中。
# 参数：
#   $1：文件路径。
#   $2：项目名。
#   $3：项目的值。
#   $4：可选参数 --useeq
#   $5：可选参数 --noblank
# 返回值：
#   0：成功。
#   1：失败。
# 示例：
#   write_conf_file "/path/to/file.conf" "item1" "value1" --useeq --noblank
#   write_conf_file "/path/to/file.conf" "item1" "value1" --useeq 
#   write_conf_file "/path/to/file.conf" "item2" "value2"
#################################################################################################
# 作者:MARSCODE_AI
# 日期:2024-12-08 11:01:00
# 审核人:saint
# 日期:2024-12-08 11:09:00
#################################################################################################  
write_conf_file_old() {
    local file=$1
    local item=$2
    local value=$3
    local useeq=false
    local noblank=false

    # 解析可选参数
    while [[ $# -gt 3 ]]; do
        case "$4" in
            --useeq)
                useeq=true
                ;;
            --noblank)
                noblank=true
                ;;
            *)
                echo "Invalid option: $4"
                return 1
                ;;
        esac
        shift
    done

    # 备份文件并获取唯一字符串
    local backup_str=$(backup_and_log "$file")
    if [ $? -ne 0 ]; then
        echo "Failed to backup file: $file"
        return 1
    fi

    # 如果文件不存在，则创建一个新文件
    if [ ! -f "$file" ]; then
        touch "$file"
    fi

    # 检查项目是否已经存在
    if grep -q "^$item" "$file"; then
        # 如果项目存在，则注释掉原有的项目
        sed -i "/^$item/s/^/# /" "$file"
        # 在注释行末尾添加注释
        sed -i "/^# $item/a # comment by ${0} from $(date +%Y%m%d-%H%M%S) $backup_str" "$file"
    fi

    # 添加注释行
    echo "# 下面一行的 $item 内容由批次编号 $backup_str 于 $(date +%Y%m%d-%H%M%S) 添加" >> "$file"

    # 添加新的项目和值
    if $useeq; then
        if $noblank; then
            echo "$item=$value" >> "$file"
        else
            echo "$item = $value" >> "$file"
        fi
    else
        echo "$item $value" >> "$file"
    fi

    

    return 0
}

#################################################################################################
# 函数定义
# get_item_from_conf
# 描述：读取指定的文件中的指定项目的值
# 参数：
#   $1：文件路径。
#   $2：项目名。
#   $3：可选参数 --all  # 暂未能实现
#   $4：可选参数 --useeq
#   $5：可选参数 --noblank
# 返回值：
#   项目的值：成功。
#   1：失败。
# 示例：
#   get_item_from_conf "/path/to/file.conf" "item1"  --useeq --noblank
#   get_item_from_conf "/path/to/file.conf" "item2" --all
#################################################################################################
# 作者:MARSCODE_AI
# 日期:2024-12-08 11:15:00
# 审核人:saint
# 日期:2024-12-08 11:19:00
#################################################################################################  
get_item_from_conf() {
    local file=$1
    local item=$2
    local ltmp_connector=" "
    local useeq=false
    local noblank=false
    local all=false
    local return_value=""

    # 解析可选参数
    while [[ $# -gt 2 ]]; do
        case "$3" in
            --useeq)
                useeq=true
                ;;
            --noblank)
                noblank=true
                ;;
            --all)
                all=true
                ;;
            *)
                echo "Invalid option: $3"
                return 1
                ;;
        esac
        shift
    done

    # 检查文件是否存在
    if [ ! -f "$file" ]; then
        echo "File does not exist: $file"
        return 1
    fi

    if $useeq; then
        if $noblank; then
            ltmp_connector="="
        else
            ltmp_connector=" = "
        fi
    fi

    
    # 检查项目是否已经存在
    if grep -q "^$item" "$file"; then
        # 如果项目存在
        #local ltmp_cut_temp=$(grep -ho "^${item}${ltmp_connector}\(.*\)" "$file" | cut -d: -f2- | cut --delimiter="${ltmp_connector}" -f2- )
        local ltmp_cut_temp=$(grep -ho "^[[:space:]]*${item}${ltmp_connector}\(.*\)" "$file" | cut -d: -f2- | cut --delimiter="${ltmp_connector}" -f2- )
        return_value=$(echo "$ltmp_cut_temp" | cut --delimiter="#" -f1- )
        echo  "$return_value"
        # if $all; then
        #     echo  "$return_value"
        # else
        #     echo  "$return_value"
        # fi       
    else
        log_message "指定项目未找到."  "ERROR"
        return 1
    fi

    return 0
}

#################################################################################################
# 函数定义
# 函数名：write_conf_file
# 描述：将指定的项目和值写入到文件中。
# 参数：
#   $1：文件路径。
#   $2：项目名。
#   $3：项目的值。
#   $4：可选参数 --useeq
#   $5：可选参数 --noblank
#   $6：可选参数 --add_only  #只添加,不注释已存在的项目
# 返回值：
#   0：成功。
#   1：失败。
# 示例：
#   write_conf_file "/path/to/file.conf" "item1" "value1" --useeq --noblank
#   write_conf_file "/path/to/file.conf" "item2" "value2"
#################################################################################################
# 作者:MARSCODE_AI
# 日期:2024-12-08 11:15:00
# 审核人:saint
# 日期:2024-12-08 11:19:00
# 已知问题:
#   1. 仅能处理项目名在行首的情况.当存在多个空格和制表符时,无法处理. 待修复
#  
#################################################################################################  
write_conf_file() {
    local file=$1
    local item=$2
    local value=$3
    local useeq=false
    local noblank=false
    local add_only=false
    local ltmp_connector=" "
    local ltmp_read_conf_parm=""

    # 解析可选参数
    while [[ $# -gt 3 ]]; do
        case "$4" in
            --useeq)
                useeq=true
                ltmp_read_conf_parm=$ltmp_read_conf_parm" --useeq"
                ;;
            --noblank)
                noblank=true
                ltmp_read_conf_parm=$ltmp_read_conf_parm" --noblank"
                ;;
            --add)
                add_only=true
                ;;
            *)
                echo "Invalid option: $4"
                return 1
                ;;
        esac
        shift
    done

    # 备份文件并获取唯一字符串
    local backup_str=$(backup_and_log "$file")
    if [ $? -ne 0 ]; then
        echo "Failed to backup file: $file"
        return 1
    fi

    # 如果文件不存在，则创建一个新文件
    if [ ! -f "$file" ]; then
        touch "$file"
    fi

    if $useeq; then
        if $noblank; then
            ltmp_connector="="
        else
            ltmp_connector=" = "
        fi
    fi

    if ! $add_only; then
        local ltmp_src_value_of_item=$(get_item_from_conf "$file" "$item" $ltmp_read_conf_parm ) 
        if [ "$ltmp_src_value_of_item" == "$value" ]; then
            # 如果项目存在,且内容一致,则不做任何操作
            log_message "文件 $file 中 $item 原内容为 $ltmp_src_value_of_item ,内容一致,不做任何操作." "TRACE"
            return 0
        fi
        log_message "文件 /home/pangu/temp/sshd_config 中 PermitRootLogin 原内容为 $ltmp_src_value_of_item ." "TRACE"
    fi

    # 检查项目是否已经存在
    if grep -q "^$item" "$file"; then
        # 如果项目存在，则获取其所在行号
        local line_number=$(grep -n "^${item}${ltmp_connector}" "$file" | cut -d: -f1)

        # 如果 --add_only 选项被指定，则不进行注释操作
        if $add_only; then
            #local line_number=$(grep -n "^${item}${ltmp_connector}" "$file" | cut -d: -f1 | sort -nr | head -n 1)
             local line_number=$(grep -n "^[[:space:]]*${item}${ltmp_connector}" "$file" | cut -d: -f1 | sort -nr | head -n 1)
        else
            # 注释掉原有的项目
            local ltmp_num_lines=$(echo "$line_numbers" | wc -l)
            if [ "$ltmp_num_lines" -gt 1 ]; then
                echo "Multiple line numbers found: $line_numbers"
                return 1
            fi
            sed -i "/^${item}${ltmp_connector}/s/$/ #$backup_str/" "$file"
            sed -i "/^${item}${ltmp_connector}/s/^/#/" "$file"
        fi
       
        # 在该行所在位置的下一行开始添加新内容
        sed -i "$((line_number + 0))a # 下面一行的 $item 内容由批次编号 $backup_str 于 $(date +%Y%m%d-%H%M%S) 添加" "$file"
        sed -i "$((line_number + 1))a ${item}${ltmp_connector}${value}" "$file"
        
    else
        # 添加注释行
        echo "# 下面一行的 $item 内容由批次编号 $backup_str 于 $(date +%Y%m%d-%H%M%S) 添加" >> "$file"
        # 添加新的项目和值
        echo "${item}${ltmp_connector}${value}" >> "$file"
    fi

    return 0
}

#################################################################################################
# 函数定义
# 函数名:which_bootloader
# 描述：获取当前系统的引导固件类型。
#################################################################################################
which_bootfirmware() {
    [ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
}

#################################################################################################
# 函数定义
# 函数名:list_grub_entries
# 描述：列出所有 GRUB 条目。
#################################################################################################
list_grub_entries() {
    # 列出所有 GRUB 条目
    # 这里破例直接使用了sudo,因为后面的命令使用了正则,为了避免参数传递时候出现未预料的问题,所以直接使用sudo.
    sudo grep -P "^menuentry" /boot/grub2/grub.cfg | cut -d "'" -f2 
}

#################################################################################################
# 函数定义
# 函数名:list_support_vmtech
# 描述：列出所有当前硬件支持的虚拟机技术。
# 当没有输出任何内容时说明当前硬件环境不支持虚拟技术.(这种情况当今极少存在)
#################################################################################################
list_support_vmtech() {
    grep -E '^flags.*(vmx|svm)' /proc/cpuinfo
}

#################################################################################################
# 检查 firewalld 是否启用并正在运行
#################################################################################################
is_firewalld_active() {
    systemctl is-active --quiet firewalld && systemctl is-enabled --quiet firewalld
}

#################################################################################################
# 检查 iptables 是否启用并正在运行
#################################################################################################
is_iptables_active() {
    for service in iptables iptables6 ipfilter ip6tables; do
        systemctl is-active --quiet "$service" && systemctl is-enabled --quiet "$service" && return 0
    done
    return 1
}

#################################################################################################
# 获取正在使用的防火墙类型
#################################################################################################
get_active_firewall() {
    if is_firewalld_active; then
        echo "firewalld"
    elif is_iptables_active; then
        echo "iptables"
    else
        echo "none"
    fi
}

#################################################################################################
# 检查 firewalld 是否成功添加了端口（仅用于firewalld）
#################################################################################################
check_firewalld_port() {
    local zone="$1"
    local port="$2"
    local protocol="$3"
    firewall-cmd --list-all --zone="$zone" | grep -q "ports:.*$port/$protocol"
}

#################################################################################################
# 添加 firewalld 端口并检查是否成功
#################################################################################################
add_firewalld_ports() {
    local zone="$1"
    local protocol="$2"
    local success=true
    local ports=($(echo $GLOBAL_PORT_LIST | tr -d '"' | tr ' ' '\n'))

    for port in "${ports[@]}"; do
        sudo_execute "firewall-cmd --permanent --zone=$zone --add-port=$port/$protocol "
        if ! sudo_execute "firewall-cmd --reload"; then
            log_message "Failed to reload firewalld rules." "ERROR"
            success=false
            break
        fi
        # 可选：检查端口是否成功添加（根据需要决定是否保留这个检查）
        # if ! firewall-cmd --list-all --zone="$zone" | grep -q "ports:.*$port/$protocol"; then
        #     echo "Failed to add port $port/$protocol to firewalld zone $zone."
        #     success=false
        #     break
        # fi
        
        sudo_execute_ "firewall-cmd --query-port=$port/$protocol --zone=$zone"
        if [ "$SUDO_EXECUTE__OUTPUT" = "no" ];then
            log_message "Failed to add port $port/$protocol to firewalld zone $zone."
            success=false
        else
            log_message "Success to add port $port/$protocol to firewalld zone $zone."
        fi

    done

    if $success; then
        log_message "Ports added successfully for firewalld in zone $zone." "INFO"
    else
        log_message "Some ports failed to add for firewalld in zone $zone." "ERROR"
        return 1
    fi

    return 0
}

#################################################################################################
# 添加 iptables 端口（不直接检查规则添加是否成功）
#################################################################################################
add_iptables_ports() {
    local protocol="$1"
    local success=true
    local ports=($(echo $GLOBAL_PORT_LIST | tr -d '"' | tr ' ' '\n'))

    log_message "iptables 对应的删除和添加端口函数并为经过测试,为避免问题会直接退出"
    return 1

    for port in "${ports[@]}"; do
        sudo_execute "iptables -A INPUT -p $protocol --dport $port -j ACCEPT"
        if [[ $? -ne 0 ]]; then
            log_message "Failed to add iptables rule for port $port/$protocol." "ERROR"
            success=false
            break
        fi
    done

    # 保存 iptables 规则（根据系统不同，使用不同的命令）
    if command -v service &> /dev/null; then
        sudo_execute "service iptables save"
    elif command -v systemctl &> /dev/null; then
        iptables-save | sudo_execute "tee /etc/iptables/rules.v4"
    else
        log_message "Failed to save iptables rules." "ERROR"
        success=false
    fi

    if $success; then
        log_message "Ports added successfully for iptables (assuming rules were added correctly)." "INFO"
    else
        log_message "Some ports failed to add for iptables." "ERROR"
        return 1
    fi
}

add_icmp_reply_block_rule()
{
    local firewall_type="$1"
    local zone="${2:-public}"  # 如果第二个参数为空，则默认为"public"

    if [ "$firewall_type" == "firewalld" ];then
        sudo_execute "firewall-cmd --permanent --add-icmp-block=echo-request --zone=$zone"
        sudo_execute "firewall-cmd --reload"

        sudo_execute_ "firewall-cmd --zone=$zone --query-icmp-block=echo-request"
        if [ "$SUDO_EXECUTE__OUTPUT" == "yes" ];then 
            log_message "ICMP echo-request will be Block .ICMP 回应的 屏蔽规则已添加."
            log_message "注意,本函数仅适用管理员初始化设置时规则的变更.如需添加更复杂屏蔽规则,需要自行设置."
        else
            log_message "ICMP echo-request Block rule add fail.ICMP 回应的 屏蔽规则添加失败." "ERROR"
            return 1
        fi
    elif [ "$firewall_type" == "iptables" ];then
        echo "Er...,UnSupport yet"
    fi
    
    return 0
}

remove_icmp_reply_block_rule()
{
    local firewall_type="$1"
    local zone="${2:-public}"  # 如果第二个参数为空，则默认为"public"

    if [ "$firewall_type" == "firewalld" ];then
        sudo_execute "firewall-cmd --permanent --remove-icmp-block=echo-request --zone=$zone"
        sudo_execute "firewall-cmd --reload"

        sudo_execute_ "firewall-cmd --zone=$zone --query-icmp-block=echo-request"
        if [ "$SUDO_EXECUTE__OUTPUT" == "no" ];then 
            log_message "ICMP echo-request will not Block any more.ICMP 回应的 屏蔽规则已删除."
            log_message "注意,本函数仅适用管理员初始化设置时规则的变更.如存在其他屏蔽规则,需要自行修改."
        else
            log_message "ICMP echo-request Block rule remove fail.ICMP 回应的 屏蔽规则删除失败." "ERROR"
            return 1
        fi
    elif [ "$firewall_type" == "iptables" ];then
        echo "Er...,UnSupport yet"
    fi
    
    return 0
}

#################################################################################################
# 添加防火墙端口函数
# 示例：设置全局变量并调用 add_firewall_ports 函数
#       假设用户输入了 "8080 8443"
#           user_input="8080 8443"
#           GLOBAL_PORT_LIST="\"$user_input\""
#           add_firewall_ports "tcp" "public"
#################################################################################################
add_firewall_ports_usage(){
    
    echo -ne "${GREEN}
    --add_fw_port ${BLUE}\"port_list\"  ${GREEN}--type ${BLUE}[tcp/udp${NC}] [${GREEN}--zone ${BLUE}public${NC}] ${GREEN}-p ${NC}[${GREEN}--permanent${NC}]  
                    ${NC}添加端口清单 port_list 类型tcp或udp端口至防火墙 ${NC}
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}--zone ${BLUE}public ${GREEN}-p${NC}
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}--zone ${BLUE}trusted ${GREEN}-p${NC}
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}--zone ${BLUE}work ${GREEN}-p${NC}
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}--zone ${BLUE}home ${NC}
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}-p${NC}
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} 
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088 6300\"${NC} ${GREEN}--icmp_reply ${BLUE}add${NC} 
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"9060 8088\"${NC} ${GREEN}--icmp_reply ${BLUE}remove${NC} 
                        例:     ${GREEN}$0 --add_fw_port ${BLUE}\"\"${NC} ${GREEN}--icmp_reply ${BLUE}remove${NC} "
    echo
}
#################################################################################################
add_firewall_ports() {
    local port_type="$1"
    local zone="${2:-public}"  # 如果第二个参数为空，则默认为"public"
    local ltmp_icmp_reply="$this_icmp_reply"
    local firewall_type
    local protocol
    #local ports=()
    local success=true

    # 处理端口类型
    echo "PORT_TYPE is : $port_type"
    case "$port_type" in
        tcp|t)
            protocol="tcp"
            ;;
        udp|u)
            protocol="udp"
            ;;
        *)
            log_message "Invalid port type specified. Use 'tcp', 't', 'udp', or 'u'." "ERROR"
            return 1
            ;;
    esac

    # 将端口字符串转换为数组
    #IFS=' ' read -r -a ports <<< "$ports_str"

    # 获取正在使用的防火墙类型
    firewall_type=$(get_active_firewall)

    if [[ "$firewall_type" == "none" ]]; then
        log_message "No supported firewall found on this system or firewall is not active." "ERROR"
        return 1
    fi

    case "$ltmp_icmp_reply" in
        "add")
            add_icmp_reply_block_rule "$firewall_type" "$zone"
            ;;
        "remove")
            remove_icmp_reply_block_rule "$firewall_type" "$zone"
            ;;
        *)
            log_message "ltmp_icmp_reply=$ltmp_icmp_reply,Not Support yet."
            ;;
    esac

    # 确保 GLOBAL_PORT_LIST 已经被正确设置
    if [ "$GLOBAL_PORT_LIST" == "" ] || [ "$GLOBAL_PORT_LIST" == "\"\"" ];then
        log_message "port_list is empty.Will not add any port." "WARNING"
        log_message "port_list 为空,将不会添加任何端口." "WARNING"
        #end_the_batch
        return 1
    fi

    # 根据正在使用的防火墙添加端口
    if [[ "$firewall_type" == "firewalld" ]]; then
        add_firewalld_ports "$zone" "$protocol"
    elif [[ "$firewall_type" == "iptables" ]]; then
        add_iptables_ports "$protocol"
    else
        # 如果系统同时启用了 firewalld 和 iptables（不常见），则向两者都添加端口
        # 注意：这里可能会存在逻辑冲突或重复添加的问题，需要根据实际需求调整
        if is_firewalld_active; then
            add_firewalld_ports "$zone" "${ports[@]}" "$protocol"
            if [[ $? -ne 0 ]]; then
                success=false
            fi
        fi
        if is_iptables_active; then
            add_iptables_ports "${ports[@]}" "$protocol"
            if [[ $? -ne 0 ]]; then
                success=false
            fi
        fi
    fi

    if $success; then
        log_message "Ports added successfully for $firewall_type in zone $zone." "INFO"
    else
        log_message "Some ports failed to add for $firewall_type in zone $zone." "ERROR"
        return 1
    fi

    echo "当前防火墙规则:"
    echo "==========================================================================" 
    echo "$(sudo_execute "firewall-cmd --list-all-zone")"
    echo "==========================================================================" 

    log_message "执行成功"
}

#################################################################################################
# 删除 firewalld 端口并检查是否成功
#################################################################################################
remove_firewalld_ports() {
    local zone="$1"
    local protocol="$2"
    local success=true
    local ports=($(echo $GLOBAL_PORT_LIST_TO_REMOVE | tr -d '"' | tr ' ' '\n'))

    for port in "${ports[@]}"; do
        sudo_execute "firewall-cmd --permanent --zone=$zone --remove-port=$port/$protocol"
        if ! sudo_execute "firewall-cmd --reload"; then
            log_message "Failed to reload firewalld rules." "ERROR"
            success=false
            break
        fi

        sudo_execute_ "firewall-cmd --query-port=$port/$protocol --zone=$zone"
        if [ "$SUDO_EXECUTE__OUTPUT" = "yes" ];then
            log_message "Failed to remove port $port/$protocol from firewalld zone $zone."
            success=false
        else
            log_message "Success to remove port $port/$protocol from firewalld zone $zone."
        fi

    done

    if $success; then
        log_message "Ports removed successfully for firewalld in zone $zone." "INFO"
    else
        log_message "Some ports failed to remove for firewalld in zone $zone." "ERROR"
        return 1
    fi
    return 0
}

#################################################################################################
# 删除 iptables 端口（不直接检查规则删除是否成功）
#################################################################################################
remove_iptables_ports() {
    local protocol="$1"
    local success=true
    local ports=($(echo $GLOBAL_PORT_LIST_TO_REMOVE | tr -d '"' | tr ' ' '\n'))

    log_message "iptables 对应的删除和添加端口函数并为经过测试,为避免问题会直接退出"
    return 1

    # iptables 删除规则通常比较复杂，因为需要精确匹配已有的规则
    # 这里我们假设只是简单地删除所有匹配的端口规则（这可能不是最佳实践）
    for port in "${ports[@]}"; do
        sudo_execute "iptables -D INPUT -p $protocol --dport $port -j ACCEPT" || true
        
        # 注意：上面的命令可能会删除多条匹配的规则，或者没有规则被删除时也会返回成功
        # 在实际应用中，您可能需要更精确地定位要删除的规则
    done

    # 保存 iptables 规则（根据系统不同，使用不同的命令）
    # ...（与之前相同）

    if $success; then
        log_message "Ports removed successfully for iptables (assuming rules were removed correctly)." "INFO"
    else
        log_message "Some ports failed to remove for iptables." "ERROR"
        return 1
    fi
}

#################################################################################################
# 删除 iptables 端口函数 V2版本实现方式,因为两版均未测试,因此函数名末尾加了_后缀.
#   需要注意的是，由于iptables规则的复杂性，精确删除特定规则可能需要更多的信息（如规则编号、链名等）。
#       不过，为了简化，这里我们假设要删除所有匹配指定协议和端口的INPUT链规则。
#################################################################################################
remove_iptables_ports_() {
    local protocol="$1"
    local ports=($(echo $GLOBAL_PORT_LIST_TO_REMOVE | tr -d '"' | tr ' ' '\n'))
    local rule_num
    local success=true

    log_message "iptables 对应的删除和添加端口函数并为经过测试,为避免问题会直接退出"
    return 1

    # 遍历每个端口，尝试删除匹配的规则
    for port in "${ports[@]}"; do
        # 列出所有 INPUT 链的规则，并查找匹配端口和协议的规则编号
        # 注意：这个命令可能会输出多条规则，我们需要处理所有匹配的规则
        rule_nums=$(iptables -L INPUT -n -v --line-numbers | grep "\->$port\s*$protocol" | awk '{print $1}')

        # 删除匹配的规则
        for rule_num in $rule_nums; do
            sudo_execute "iptables -D INPUT $rule_num" || {
                log_message "Failed to remove iptables rule number $rule_num for port $port/$protocol." "ERROR"
                success=false
            }
        done
    done

    # 保存 iptables 规则（根据系统不同，使用不同的命令）
    # 对于基于 Debian 的系统（如 Ubuntu），使用 iptables-persistent
    if command -v iptables-save &> /dev/null; then
        sudo_execute " iptables-save > /etc/iptables/rules.v4 "  # 对于 IPv4 规则
        # 如果需要，也可以保存 IPv6 规则：iptables-save -6 > /etc/iptables/rules.v6
    # 对于基于 Red Hat 的系统（如 CentOS、Fedora），使用 service iptables save
    elif command -v service &> /dev/null; then
        sudo_execute "service iptables save"
    else
        log_message "Unknown system. Failed to save iptables rules." "ERROR"
        success=false
    fi

    if $success; then
        log_message "Ports removed successfully for iptables." "INFO"
    else
        log_message "Some ports failed to remove for iptables." "ERROR"
        return 1
    fi
# 在这个实现中，我们首先解析全局变量GLOBAL_PORT_LIST_TO_REMOVE来获取要删除的端口列表。
#   然后，对于每个端口，我们使用iptables -L INPUT -n -v --line-numbers命令来列出INPUT链的所有规则，
#       并使用grep和awk来查找匹配指定端口和协议的规则编号。最后，我们使用iptables -D INPUT命令来删除这些规则。
# 请注意以下几点：
#  o   这个实现假设GLOBAL_PORT_LIST_TO_REMOVE已经包含要删除的端口号列表，并且这些端口号是以空格分隔的。
#  o   我们使用iptables -L命令的--line-numbers选项来获取规则的编号，这对于删除规则是必需的。
#  o   我们使用grep来匹配规则的端口和协议，这可能会受到其他规则中相似内容的影响。因此，在实际应用中，您可能需要更精确的匹配逻辑。
#  o   我们使用iptables-save或service iptables save命令来保存更改后的规则，这取决于系统的类型。您可能需要根据您的系统调整这部分逻辑。
#  o   这个实现没有处理iptables规则删除失败的情况（除了打印一条错误消息和设置success变量为false之外）。在实际应用中，您可能需要更复杂的错误处理逻辑。

}

#################################################################################################
# 添加防火墙端口函数
# 示例：设置全局变量并调用 add_firewall_ports 函数
#       假设用户输入了 "8080 8443"
#           user_input="8080 8443"
#           GLOBAL_PORT_LIST="\"$user_input\""
#           add_firewall_ports "tcp" "public"

remove_firewall_ports_usage(){
    
    echo -ne "${GREEN}
    --remove_fw_port ${BLUE}\"port_list\"  ${GREEN}--type ${BLUE}[tcp/udp${NC}] [${GREEN}--zone ${BLUE}public${NC}] ${GREEN}-p ${NC}[${GREEN}--permanent${NC}]  
                    ${NC}从防火墙移除清单 port_list 中类型tcp或udp的所有端口 ${NC}
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}--zone ${BLUE}trusted ${GREEN}-p${NC}
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}--zone ${BLUE}work ${GREEN}-p${NC}
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}--zone ${BLUE}home ${NC}
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} ${GREEN}-p${NC}
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"9060 8088 6300 6200 6379 8083\"${NC} ${GREEN}--type ${BLUE}tcp${NC} 
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"9060 8088 6300\"${NC} ${GREEN}--icmp_reply ${BLUE}add${NC} 
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"9060 8088\"${NC} ${GREEN}--icmp_reply ${BLUE}remove${NC} 
                        例:     ${GREEN}$0 --remove_fw_port ${BLUE}\"\"${NC} ${GREEN}--icmp_reply ${BLUE}remove${NC} "
    echo 
}
#################################################################################################

#################################################################################################
# 删除防火墙端口函数
#################################################################################################
remove_firewall_ports() {
    local port_type="$1"
    local zone="${2:-public}"  # 如果第二个参数为空，则默认为 "public"
    local ltmp_icmp_reply="$this_icmp_reply"
    local firewall_type
    local protocol
    #local ports=()
    local success=true

    # 处理端口类型
    echo "PORT_TYPE is : $port_type"
    case "$port_type" in
        tcp|t)
            protocol="tcp"
            ;;
        udp|u)
            protocol="udp"
            ;;
        *)
            log_message "Invalid port type specified. Use 'tcp', 't', 'udp', or 'u'." "ERROR"
            return 1
            ;;
    esac

    # 将端口字符串转换为数组
    #IFS=' ' read -r -a ports <<< "$ports_str"

    # 获取正在使用的防火墙类型,get_active_firewall这个函数已经实现并返回"firewalld"或"iptables"
    firewall_type=$(get_active_firewall) 

    if [[ "$firewall_type" == "none" ]]; then
        log_message "No supported firewall found on this system or firewall is not active." "ERROR"
        return 1
    fi

    case "$ltmp_icmp_reply" in
        "add")
            add_icmp_reply_block_rule "$firewall_type" "$zone"
            ;;
        "remove")
            remove_icmp_reply_block_rule "$firewall_type" "$zone"
            ;;
        *)
            log_message "ltmp_icmp_reply=$ltmp_icmp_reply,Not Support yet."
            ;;
    esac

    # 确保 GLOBAL_PORT_LIST_TO_REMOVE 已经被正确设置
    if [ -z "$GLOBAL_PORT_LIST_TO_REMOVE" ] || [ "$GLOBAL_PORT_LIST_TO_REMOVE" == "\"\"" ];then
        log_message "port_list is empty.Will not remove any port." "WARNING"
        log_message "port_list 为空,将不会移除任何端口." "WARNING"
        #end_the_batch
        return 1
    fi
   
    # 根据正在使用的防火墙删除端口
    if [[ "$firewall_type" == "firewalld" ]]; then
        # 调用删除 firewalld 端口的函数
        remove_firewalld_ports "$zone" "$protocol"
        if [[ $? -ne 0 ]]; then
            success=false
        fi
    elif [[ "$firewall_type" == "iptables" ]]; then
        # 调用删除 iptables 端口的函数
        remove_iptables_ports "$protocol"
        if [[ $? -ne 0 ]]; then
            success=false
        fi
    else
        log_message "Unknown firewall type: $firewall_type" "ERROR"
        return 1
    fi

    # 输出操作结果
    if $success; then
        log_message "Ports removed successfully for $firewall_type in zone $zone." "INFO"
    else
        log_message "Some ports failed to remove for $firewall_type in zone $zone." "ERROR"
        return 1
    fi
    
    echo "当前防火墙规则:"
    echo "==========================================================================" 
    echo "$(sudo_execute "firewall-cmd --list-all-zone")"
    echo "==========================================================================" 

    log_message "执行成功"
}

#################################################################################################
# 交互方式挂载分区到 参数指定挂载点
#   Example usage:
#   mount_partition /mnt/my_mount_point
#################################################################################################
# mount_partition_manual() {

# #  注意事项：
# #     ‌lsblk 过滤‌： 过滤掉了一些常见的设备类型（如sda, sr0, loop, ram, nvme, mmcblk），你可能需要根据你的系统情况调整过滤条件。
# #     ‌权限‌：挂载操作通常需要超级用户权限，所以你可能需要使用sudo来运行这个脚本，例如：sudo mount_partition /mnt/my_mount_point。
# #     ‌分区格式和文件系统‌：请确保目标分区格式和文件系统类型是你系统支持的，并且确保在执行挂载操作前，分区没有被其他进程使用。

#     local target_dir="$1"

#     if [[ ! -d "$ltmp_target_dir" ]]; then
#         echo "Target directory $ltmp_target_dir does not exist. Creating..."
#         sudo_execute "mkdir -p \"$ltmp_target_dir\"" || { echo "Failed to create directory $ltmp_target_dir"; return 1; }
#     fi

#     echo "Listing unmounted partitions:"
#     echo -e "NUM\tNAME\tMAJ:MIN\tRM\tSIZE\tRO\tTYPE\tMOUNTPOINT"

#     # Get the list of unmounted partitions and assign a number to each
#     local partitions=()
#     local index=1
#     while read -r line; do
#         # lsblk output format: NAME MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
#         if [[ "$line" != "NAME"* && "$line" != *"/"* ]]; then  # Filter out header line and mounted partitions
#             partitions+=("$index $line")
#             index=$((index + 1))
#         fi
#     done < <(lsblk -n -o NAME,MAJ:MIN,RM,SIZE,RO,TYPE,MOUNTPOINT | grep -vE '(NAME\| )|(sda|sr0|loop|ram|nvme|mmcblk)')

#     # Print the list with numbers
#     printf "%s\n" "${partitions[@]}" | column -t

#     if [[ ${#partitions[@]} -eq 0 ]]; then
#         echo "No unmounted partitions found."
#         return 1
#     fi

#     # Prompt user to select a partition by number
#     read -p "Enter the number of the partition to mount: " partition_num

#     if ! [[ "$partition_num" =~ [0-9]+$ ]] || (( partition_num < 1 || partition_num > ${#partitions[@]} )); then
#         echo "Invalid selection."
#         return 1
#     fi

#     # Get the selected partition details
#     local selected_partition=(${partitions[partition_num-1]})
#     local partition_name=${selected_partition}  # The partition name is the second field in the array

#     # Mount the selected partition
#     echo "Mounting $partition_name to $ltmp_target_dir..."
#     sudo_execute "mount \"$partition_name\" \"$ltmp_target_dir\" " || { echo "Failed to mount $partition_name to $ltmp_target_dir"; return 1; }

#     echo "$partition_name mounted successfully to $ltmp_target_dir."
# }

#################################################################################################
# 挂载新添加的存储设备.
# Example usage:
# sudo mount_new_device /mnt/my_new_mount_point
# 注意事项：
#  o 权限‌：此脚本需要超级用户权限来执行分区和挂载操作，因此应该使用sudo来运行。
#  o 文件系统格式‌：在上面的脚本中，我假设使用ext4文件系统格式。如果你需要不同的文件系统格式，请相应地修改mkfs.ext4命令。
#  o 设备识别‌：lsblk命令用于列出设备，并通过过滤来找到未分区的设备。你可能需要根据你的系统情况调整过滤条件。
#  o partprobe‌：在某些系统上，partprobe命令可能不是必需的，但它在某些情况下有助于确保内核重新读取分区表。如果你的系统不需要它，你可以移除该命令。

mount_new_device_usage(){
    
    echo -ne "${GREEN}
                        
    --init_new_disk ${BLUE}mount_point --dev devicename --fs fstype  
                        ${NC}挂载devicename 至 ${BLUE}mount_point${NC} 新分区格式化为{BLUE}fstype{NC}.
                        mount_point      挂载点,必选参数,不可省略.需指定具体的挂载点,形式如 /data 或 /DB 等.
                        --dev devicename 指定设备名称,可以为 /dev/sdb 或 sdb.该参数不指定则会由程序搜索已识别但
                                         未分区的disk类型设备,
                                         以列表形式展现,并提示用户选择要分区并挂载的disk对应列表中的编号.选择后对
                                         其进行操作.
                        --fs  fstype     指定新分区文件系统类型,即要格式化为哪种格式.该参数不指定则为 ext4
    
                        例:     ${GREEN}$0 --init_new_disk ${BLUE}/Ddata${NC} --dev ${BLUE}/dev/sdc${NC} --fs ${BLUE}ext4${NC}
                        例:     ${GREEN}$0 --init_new_disk ${BLUE}/Ddata${NC} --dev ${BLUE}/dev/sdc${NC}
                        例:     ${GREEN}$0 --init_new_disk ${BLUE}/Ddata${NC} --dev ${BLUE}sdc${NC}
                        例:     ${GREEN}$0 --init_new_disk ${BLUE}/Ddata${NC} --fs ${BLUE}ext4${NC}
                        例:     ${GREEN}$0 --init_new_disk ${BLUE}/Ddata${NC} --fs ${BLUE}btrfs${NC}
                        例:     ${GREEN}$0 --init_new_disk ${BLUE}/Ddata${NC} "
    echo 
}

#################################################################################################
mount_new_device() {
    local ltmp_param="$@"
    local ltmp_target_dev=""
    local ltmp_target_dir=""
    local ltmp_filesystem_type="ext4"
    
    echo "参数个数 $#"
    # case "$#" in
    #     3)
            
    #         ltmp_target_dev=“$1”
    #         ltmp_target_dir="$2"
    #         ltmp_filesystem_type="$3"
    #         ;;
    #     2)
    #         if [ $(echo "$2" | grep -E '(ext4|xfs|btrfs)$' ) -eq 1 ];then
    #             ltmp_target_dir="$1"
    #             ltmp_filesystem_type="$2"
    #         else
    #             ltmp_target_dev="$1"
    #             ltmp_target_dir="$2"
    #         fi
    #         ;;
    #     1)
    #         ltmp_target_dir=$1
    #         ;;
    # esac

    case "$#" in
        3)
            ltmp_target_dev="$1"
            ltmp_target_dir="$2"
            ltmp_filesystem_type="$3"
            ;;
        2)
            if [[ "$2" =~ (ext4|xfs|btrfs|ntfs)$ ]]; then
                ltmp_target_dir="$1"
                ltmp_filesystem_type="$2"
            else
                ltmp_target_dev="$1"
                ltmp_target_dir="$2"
            fi
            ;;
        1)
            ltmp_target_dir="$1"
            ;;
        *)
            echo "错误的参数数量"
            return 1
            ;;
    esac

    log_message "ltmp_target_dev=$ltmp_target_dev"
    log_message "ltmp_target_dir=$ltmp_target_dir"
    log_message "ltmp_filesystem_type=$ltmp_filesystem_type"
    

    if [[ ! -d "$ltmp_target_dir" ]]; then
        echo "Target directory $ltmp_target_dir does not exist. Creating..."
        sudo_execute "mkdir -p $ltmp_target_dir" || { 
            echo "Failed to create directory $ltmp_target_dir"
            return 1 
        }
    fi
    
    local ltmp_selected_device=""

    if [ -z  "$ltmp_target_dev" ];then


        log_message "列出未分区的设备:" "INFO"
        echo
        echo "==========================================================================" 
        echo -e "NUM  NAME   SIZE  TYPE"

        # 获取所有设备的清单
        local ltmp_all_devices=$(lsblk -n -l -o NAME,SIZE,TYPE | grep -vE '(NAME|sr|loop|ram|nvme|mmcblk)')

        # 获取未分区设备清单并且给他们拟定编号
        local devices=()
        local index=1
        
        # 循环,直到找到未分区的一个
        while read -r line; do
            local device_name=$(echo "$line" | awk '{print $1}')
            local device_size=$(echo "$line" | awk '{print $2}')
            local device_type=$(echo "$line" | awk '{print $3}')

            # 假定这个设备是未被分区的,直到找到一个分区名称是以这个设备的名称为前缀
            local ltmp_is_partitioned=false

            # 检查是否有其他设备以这个设备name为前缀 (indicating a partition)
            while read -r other_line; do
                local ltmp_other_device_name=$(echo "$other_line" | awk '{print $1}')
                
                # If the other device name starts with this device name and is followed by a digit, it's a partition
                # 如果其他设备的name 以这个设备的名字开头,且后面跟着一个数字.则认定是个分区.
                #2024-10-30 21:02 saint增加了一个可选字母p在结尾的数字之前,
                #   发现Fedora操作系统的nvme固态硬盘的分区是以磁盘name加上p1、p2这样的编号结尾
                # 使用 [[ ... ]] 结构和 =~ 操作符来进行正则表达式匹配，但这需要开启 extglob 选项（通常默认是开启的）

                if [[ "$ltmp_other_device_name" =~ ${device_name}p?[0-9]+$ ]]; then
                    ltmp_is_partitioned=true
                    break
                fi
            done <<< "$ltmp_all_devices"

            # 如果一个设备未被分区，且是disk,将它加入列表。
            if [[ "$ltmp_is_partitioned" == false && "$device_type" == "disk" ]]; then
                devices+=("$index $device_name $device_size $device_type")
                index=$((index + 1))
            fi
        done <<< "$ltmp_all_devices"

        # 打印带有编号的列表
        printf "%s\n" "${devices[@]}" | column -t -o "    "

        # 如果没有找到未分区的设备，输出提示信息
        if [[ ${#devices[@]} -eq 0 ]]; then
            log_message "未找到未进行分区的设备" "ERROR"
            echo "=========================================================================="
            echo "未找到未进行分区的设备"
            echo "No unpartitioned devices found."
            echo "该函数(方法)用于服务器或其他系统,初始化新添加的用于存储的块设备."
            echo "并不适用于一般分区及调整分区的场景.如需分区可使用那些更可靠且久经考验的程序."
            echo "=========================================================================="
            end_the_batch
        fi

        # Prompt user to select a device by number
        echo "=========================================================================="
        echo 
        echo "输入要进行分区（初始化）的设备的编号:
        这里的初始化包括：
            o 建立GPT分区表
            o 全部空间建立一个分区
            o 挂载该分区至参数中的挂载点，即 $ltmp_target_dir 
            o 将该分区以 UUID 为标识，写入fstab,达到开机自动挂载。"
        echo "按 q 取消并退出。"
        echo "=========================================================================="
        read -p "Enter the number of the device to partition and mount: " ltmp_device_num
        if [ $ltmp_device_num = "q" ];then
            echo "=========================================================================="
            end_the_batch
        elif ! [[ "$ltmp_device_num" =~ [0-9]+$ ]] || (( ltmp_device_num < 1 || ltmp_device_num > ${#devices[@]} )); then
            echo "=========================================================================="
            log_message "输入的选项 $ltmp_device_num 不可用 ( Invalid selection )." "ERROR"
            end_the_batch
        fi

        # 获取选择的设备的明细 (note the use of array slicing)
        ltmp_selected_device=($(echo "$devices" | awk '{print $2}'))
         


    else
        # disk名称的参数"$1"或者"$ltmp_target_dev",去掉开头的/dev/后赋值给 ltmp_selected_device .

        # if [ -n "$BASH_VERSION" ]; then
        #     echo "当前环境是 Bash，支持参数扩展。"
        # else
        #     echo "当前环境不是 Bash，可能不支持参数扩展。"
        # fi

        # 如果 ltmp_target_dev 已经被设置（即作为参数传递），则使用它作为选定的设备
        if [ -n "$ltmp_target_dev" ]; then
            ltmp_selected_device="${ltmp_target_dev#/dev/}"  # 去掉开头的 /dev/
        fi


        # set -x
         echo "ltmp_target_dev=$ltmp_target_dev"
         echo "ltmp_selected_device=$ltmp_selected_device"
        # set +x 
        # end_the_batch
        #[[ "$ltmp_target_dev" == /dev/* ]] || ltmp_selected_device="$ltmp_target_dev"

        # 检查 ltmp_selected_device 是否有效
        #[[ "$ltmp_selected_device" == *[-a-zA-Z0-9_/]* ]] && log_message "设备名包含无效字符" "ERROR" && end_the_batch

        # 如果 ltmp_target_dev 没有以 /dev/ 开头，则直接使用 ltmp_selected_device
        [[ "$ltmp_target_dev" == /dev/* ]] || ltmp_selected_device="$ltmp_target_dev"
    fi

    
    

    # 使用完整设备符号 ( /dev/设备名 的形式)用于后面分区
    local ltmp_device_name="/dev/${ltmp_selected_device}"

    # 获取建立分区前的分区清单
    log_message "列出分区之前的 分区清单." "WARNING"
    local ltmp_BEFORE_PARTITIONS=$(lsblk -l -n -o NAME | grep -vE '(NAME|sr|loop|ram|nvme|mmcblk)')
    
    # Partition the selected device with GPT and create a single partition
    log_message "Partitioning $ltmp_device_name with GPT... " "WARNING"
    sudo_execute " parted -s $ltmp_device_name mklabel gpt "
    sudo_execute " parted -s --align optimal $ltmp_device_name mkpart primary 0% 100% "

    # Wait for the kernel to re-read the partition table (optional but recommended)
    sudo_execute "partprobe $ltmp_device_name " || true

    # 获取建立分区后的分区清单
    log_message "列出分区之后的 分区清单." "WARNING"
    local ltmp_AFTER_PARTITIONS=$(lsblk -l -n -o NAME | grep -vE '(NAME|sr|loop|ram|nvme|mmcblk)')

    # 比较两次的分区清单，找出新建立的分区
    local ltmp_NEW_PARTITION=""
    for ltmp_part in $ltmp_AFTER_PARTITIONS; do
        if ! echo "$ltmp_BEFORE_PARTITIONS" | grep -q "$ltmp_part"; then
            # 如果这个分区在之前的清单中不存在，则它是新建立的
            ltmp_NEW_PARTITION="$ltmp_part"
            break
        fi
    done

    # 检查是否找到了新分区
    if [ -z "$ltmp_NEW_PARTITION" ]; then
        # 这里的日至记录不是很准确，因为仅仅判断新分区，并未判断从属关系，尽管前面的判断可能会间接做了判断。
        log_message "Failed to find the new partition on disk $ltmp_selected_device." "ERROR"
        log_message "未能成功找到新分区 $ltmp_selected_device." "ERROR"
        end_the_batch
    fi

    # 获取这个新分区的包含设备路径的设备名 (如 /dev/sdb1)
    local ltmp_partition_name="/dev/${ltmp_NEW_PARTITION}"
    

    # Format the partition (assuming ext4 filesystem; adjust as needed)
    if [ -n "$ltmp_filesystem_type" ];then
        echo "Formatting $ltmp_partition_name with $ltmp_filesystem_type..."
        sudo_execute "mkfs.${ltmp_filesystem_type} $ltmp_partition_name " || { log_message "Failed to format $ltmp_partition_name" "ERROR"; end_the_batch; }
    #elif [ -z "/usr/sbin/mkfs.ext4" ];then
    else
        # 假设系统存在 mkfs.ext4.不再做判断.
        echo "/usr/sbin/mkfs.${ltmp_filesystem_type} is not exist,Formatting $ltmp_partition_name with ext4"
        ltmp_filesystem_type="ext4"
        sudo_execute "mkfs.ext4 $ltmp_partition_name " || { log_message "Failed to format $ltmp_partition_name" "ERROR"; end_the_batch; }
    fi

    # Mount the partition
    echo "Mounting $ltmp_partition_name to $ltmp_target_dir..."
    sudo_execute "mount $ltmp_partition_name $ltmp_target_dir " || { log_message "Failed to mount $ltmp_partition_name to $ltmp_target_dir" "ERROR"; end_the_batch; }

    local ltmp_fstab_backup="/etc/fstab.${this_bash_start_timestamp}.bak"
    
    # 记账
    local ltmp_log_backup_ret=""
    if [ -e /etc/fstab ];then
        ltmp_log_backup_ret=$(backup_and_log "/etc/fstab")
    fi

    #local ltmp_log_backup_ret=$this_backup_IDENTIFIER
    echo "ltmp_log_backup_ret=$ltmp_log_backup_ret"
    #this_backup_IDENTIFIER=""
    case $ltmp_log_backup_ret in
        1)
            log_message "备份 /etc/fstab 失败,返回值 $ltmp_log_backup_ret .请手动备份一下再进行操作."
            end_the_batch
            ;;
        0)
            log_message "备份 /etc/fstab 返回值 $ltmp_log_backup_ret."
            end_the_batch
            ;;
        "")
            log_message "备份 /etc/fstab 失败,返回值 $ltmp_log_backup_ret .请手动备份一下再进行操作."
            end_the_batch
            ;;
        *)
            log_message "重要操作记账和备份成功。" "WARNING"
            ;;
    esac

    # Backup /etc/fstab
    if [[ ! -f "$ltmp_fstab_backup" ]]; then
        log_message "Backing up /etc/fstab to $ltmp_fstab_backup ..." "WARNING"
        sudo_execute "cp /etc/fstab $ltmp_fstab_backup" || { log_message "Failed to backup /etc/fstab" "ERROR"; end_the_batch; }
    else
        log_message "/etc/fstab backup already exists at $ltmp_fstab_backup"
        log_message "/etc/fstab 备份 已经存在于 $ltmp_fstab_backup"
    fi

    #获取UUID
    local ltmp_NEW_PARTITION_UUID=$(lsblk -l -o name,uuid |grep "$ltmp_NEW_PARTITION " | awk '{print $2}')

     # Add the new mount to /etc/fstab
    log_message "Adding new mount entry to /etc/fstab..." "WARNING"
    log_message "添加挂载信息到 /etc/fstab " "WARNING"
    ########################################################################################################################################
    #echo "$ltmp_partition_name $ltmp_target_dir                   ext4 defaults,nofail 0 2" | sudo_execute " tee -a /etc/fstab > /dev/null "
    echo "UUID=$ltmp_NEW_PARTITION_UUID $ltmp_target_dir                  $ltmp_filesystem_type     defaults,nofail     0 2" | sudo_execute " tee -a /etc/fstab > /dev/null "
    ########################################################################################################################################
    # Verify the entry was added correctly
    if grep -q "$ltmp_NEW_PARTITION_UUID" /etc/fstab; then
        log_message "New mount entry added successfully."
    else
        log_message "Failed to add new mount entry to /etc/fstab." "ERROR"
        # Optionally, you can restore the backup here if desired
        # echo "Restoring /etc/fstab from backup..."
        # cp "$ltmp_fstab_backup" /etc/fstab
        return 1
    fi
    
    echo "现(新)分区情况"
    echo "Current(New) Partions"
    echo "=========================================================================="
    echo " $(lsblk -o NAME,MAJ:MIN,RM,SIZE,RO,TYPE,MOUNTPOINT,FSTYPE,UUID)"
    echo 
    echo "现(新) /etc/fstab 文件内容"
    echo "Current(New) /etc/fstab"
    echo "=========================================================================="
    echo " $(cat /etc/fstab)"
    echo "=========================================================================="
    
    #echo " $(ls "/etc/fstab*")"
    # Optionally, you can remount all filesystems to apply the changes
    # This is not strictly necessary if you just want to test the new mount
    # echo "Remounting all filesystems..."
    # sudo mount -a

    log_message "如遇问题需要恢复 /etc/fstab,使用  sudo cp -vf $ltmp_fstab_backup /etc/fstab  ."
    echo
    echo "如遇问题需要恢复 /etc/fstab,方法如下:"
    echo "=========================================================================="
    echo "      sudo cp -vf $ltmp_fstab_backup /etc/fstab"
    echo "=========================================================================="
    log_message "Device $ltmp_partition_name mounted at $ltmp_target_dir and added to /etc/fstab."

}

wait_for_input_2_exit() {
    echo "按任意键退出"
    local ltmp_user_input_for_exit
    read -n 1 ltmp_user_input_for_exit
    show_who_call
    log_message "脚本通过调用 wait_for_input_2_exit 函数退出."
    exit 0
}

#################################################################################################
# 开始脚本时做的工作
#################################################################################################
init_the_batch(){
    # 执行过本函数立即做个标记
    this_b_init=true

     # 检查是否有上级脚本调用
    if [ "$0" != "$BASH_SOURCE" ]; then
        # 获取上级脚本的完整路径
        local parent_script_path=$(realpath "$0")
        #log_message "This script was called by $parent_script_name located at $parent_script_dir"
        # 获取上级脚本的目录
        local parent_script_dir=$(dirname "$parent_script_path")
        #log_message "This script was called by $parent_script_name located at $parent_script_dir"
        # 获取上级脚本的名称
        local parent_script_name=$(basename "$parent_script_path")
        #log_message "This script was called by $parent_script_name located at $parent_script_dir"
        # 获取上级脚本执行时的完整命令
        local parent_script_command=$(ps -o args= -p $PPID)
        #log_message "This script was called by $parent_script_name located at $parent_script_dir with command: $parent_script_command"
        # 记录信息
        log_message "This script was called by $parent_script_name located at $parent_script_dir with command: $parent_script_command"
        log_message "本脚本调用自 $parent_script_name ,其所在目录 $parent_script_dir 父脚本完整命令: $parent_script_command"
    fi

    # 包含完整路径的当前脚本名
    #local ltmp_thisbatch=$(pwd)/${0##*/}
    local ltmp_thisbatch=$BASH_SOURCE
    
    # 初始化临时文件夹,日志文件夹
    init_tmp
    init_log
    
    # 获取终端宽度
    term_width=$(tput cols)

    # 运行环境信息
    LOG_message "用户 $this_username 运行了脚本文件 : $ltmp_thisbatch" "INFO"
    LOG_message "脚本文件SHA256 : $(sha256sum $ltmp_thisbatch)" "INFO"
    LOG_message "脚本文件MD5 : $(md5sum $ltmp_thisbatch)" "INFO"
    LOG_message "运行的脚本文件及参数 : $BASH_SOURCE $@" "INFO"   
    LOG_message "更多信息 : "
    LOG_message " $(w $this_username)" "INFO"  
    LOG_message "this_b_base64support = $this_b_base64support"

    # 获取当前系统的包管理器
    which_app_manager

    # 未输入任何参数则显示 usage 内容
    if [ $# -eq 0 ]; then
       print_help
       end_the_batch
    # else
    #     echo 参数个数为: $#
    fi

    # 如果参数是 -h 或 --help 则不显示 BANNER
    local string_t=$@
    local find_str1_="help"
    local find_str2_="\bh\b"
    #local temp_grep_filename=temp_grep_filename_$this_bash_start_timestamp.tmp


    echo $@ | grep -q  "${find_str1_}" 
    local grep1_ret=$?

    #echo grep1_ret=$grep1_ret
    case $grep1_ret in
        0)
            # 找到了字符串 help 
            this_show_start_end_timestamp=false
            # this_show_start_end_timestamp 默认是true
            ;;
        *)
            #this_show_start_end_timestamp=true  #还要判断-h所以此时不修改
            echo $@ | grep -q  "${find_str2_}" 
            local grep2_ret=$?

            #echo grep2_ret=$grep2_ret
            case $grep2_ret in
                0)
                    # 找到了单个字符串  h   
                    this_show_start_end_timestamp=false
                    ;;
                *)
                    this_show_start_end_timestamp=true
                    ;;
            esac
            ;;
    esac
        
    # 显示Banner信息
    #echo this_show_start_end_timestamp = $this_show_start_end_timestamp
    if [ ${this_show_start_end_timestamp} == true ];then
        show_banner
        log_MESSAGE "bash_start." "INFO"
        log_message "运行的脚本及参数为 $0 $this_GLOBAL_PARAMETER "
        #LOG_message "bash_start." "INFO"  #已在更早的位置记录该日志条目
    # else
    #     echo this_show_start_end_timestamp : $this_show_start_end_timestamp
    fi

    # 获取操作系统版本情况,各模块根据结果对不同系统编写适配代码.
    check_which_os_release

    # 自定义代码




    # 自定义代码结束
}

#################################################################################################
# 结束脚本时做的工作
#################################################################################################
end_the_batch(){
    show_who_call
    # 自定义结束代码

    # 删除临时文件夹内的文件 (该文件用于在sudo命令执行时使用zenity显示图形密码输入框)
    rm -vf ${this_TMP_DIR}/tmp_sudo_pass_input.sh
    



    # 自定义结束代码结束

    # 显示tail_banner
    local ltmp_bash_end_timestamp=$(date +%Y%m%d-%H%M%S) #此处取一次时间用于显示

    if [ ${this_show_start_end_timestamp} == true ];then
        if [ ${this_b_trace} = false ];then  
            log_MESSAGE "bash_finish." "INFO"
        fi
    
    fi
    
    if [ ${this_b_trace} = false ];then
        show_tail
    fi

    # 清理临时文件夹
    #echo -e "this_b_trace : ${this_b_trace}"
    if [ ${this_b_trace} = false ];then
        LOG_message "清理脚本运行时生成的临时文件... ..." "WARNING"
        local ltmp_output2_of_rm=$(rm -rvf "$this_TMP_DIR")
        local ltmp_RET_DEL=$?
        case "$ltmp_RET_DEL" in
            0)
                LOG_message "Deleted direcory 【 $this_TMP_DIR 】SUCESS,RETCODE=$ltmp_RET_DEL." "WARNING"
                LOG_message "rm 命令完整输出 : $ltmp_output2_of_rm" "WARNING"
                ;;
            *)
                LOG_message "Deleting direcory 【 $this_TMP_DIR 】FAIL,RETCODE=$ltmp_RET_DEL." "WARNING"
                LOG_message "rm 命令完整输出 : $ltmp_output2_of_rm" "WARNING"
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

    # --trace 选项开启后,在 真正 退出脚本前输入 tail
    if [ ${this_b_trace} == true ];then
        show_tail
    fi

    # 终端响铃
    ${functions[random_index]}

    # 完全结束脚本
    exit 0
}




####################################################################################################
# ################################################################################################ V
# 暂未使用(另一种参数处理思路的模板):定义一个函数来解析 短选项 如:-t -s -b
#################################################################################################
parse_short_options() {
    local short_opts="t:m:"
    # 使用getopt解析短选项
    TEMP=$(getopt -o "$short_opts" --long help -- "$@")
    if [ $? != 0 ]; then
        usage
    fi
    # 解析getopt的输出并设置位置参数
    eval set -- "$TEMP"
}

#################################################################################################
# 暂未使用(另一种参数处理思路的模板):定义一个函数来解析 长选项 如:--start --stop --restart --help
#################################################################################################
parse_long_options() {
    local long_opts="start:,stop:,listen:,help"
    # 由于getopt不支持在短选项中直接解析多个参数的值，我们在这里手动处理
    # 对于每个长选项，我们检查下一个参数是否以'-'开头，如果不是，则认为是该选项的值
    while true; do
        case "$1" in
            --start)
                shift
                while [ "$#" -gt 0 ] && [ "${1:0:1}" != "-" ]; do
                    START_VALUES+=("$1")
                    shift
                done
                ;;
            --stop)
                shift
                while [ "$#" -gt 0 ] && [ "${1:0:1}" != "-" ]; do
                    STOP_VALUES+=("$1")
                    shift
                done
                ;;
            --listen)
                shift
                while [ "$#" -gt 0 ] && [ "${1:0:1}" != "-" ]; do
                    LISTEN_VALUES+=("$1")
                    shift
                done
                ;;
            --help)
                usage
                ;;
            --)
                shift
                break
                ;;
            *)
                # 如果遇到未知选项，调用usage函数
                usage
                ;;
        esac
    done
}

#################################################################################################
# 暂未使用(另一种参数处理思路的模板):主函数
#################################################################################################
main_planB(){
    # 初始化变量
    TAGS=()
    MESSAGES=()
    START_VALUES=()
    STOP_VALUES=()
    LISTEN_VALUES=()

    # 解析命令行参数
    parse_short_options "$@"
    parse_long_options "$@"

    # 显示解析后的参数（仅用于调试）
    echo "Tags: ${TAGS[@]}"
    echo "Messages: ${MESSAGES[@]}"
    echo "Start Values: ${START_VALUES[@]}"
    echo "Stop Values: ${STOP_VALUES[@]}"
    echo "Listen Values: ${LISTEN_VALUES[@]}"

    # 根据解析后的参数执行不同的逻辑
    if [ ${#TAGS[@]} -gt 0 ]; then
        echo "Handling tags: ${TAGS[@]}"
        # 在此处添加处理标签的逻辑
    fi

    if [ ${#MESSAGES[@]} -gt 0 ]; then
        echo "Handling messages: ${MESSAGES[@]}"
        # 在此处添加处理消息的逻辑
    fi

    if [ ${#START_VALUES[@]} -gt 0 ]; then
        echo "Handling start values: ${START_VALUES[@]}"
        # 在此处添加处理启动值的逻辑
    fi

    if [ ${#STOP_VALUES[@]} -gt 0 ]; then
        echo "Handling stop values: ${STOP_VALUES[@]}"
        # 在此处添加处理停止值的逻辑
    fi

    if [ ${#LISTEN_VALUES[@]} -gt 0 ]; then
        echo "Handling listen values: ${LISTEN_VALUES[@]}"
        # 在此处添加处理监听值的逻辑
    fi

    # 处理非选项参数（如果有的话）
    if [ $# -gt 0 ]; then
        echo "Non-option arguments found: $@"
        # 在此处添加处理非选项参数的逻辑
    fi

    # 脚本结束
}
#################################################################################################
# 说明：
# 1    ‌函数 usage‌：
#         定义了脚本的使用说明，当参数解析失败或用户请求帮助时显示。
# 2    ‌函数 parse_short_options‌：
#         负责解析短选项（如 -t 和 -m）。
#         使用 getopt 解析短选项，并将结果存储在 TEMP 变量中。
#         检查解析是否成功，如果不成功则调用 usage 函数。
#         解析 getopt 的输出，并设置位置参数以供后续处理。
# 3    ‌函数 parse_long_options‌：
#         负责解析长选项（如 --start、--stop 和 --listen）。
#         由于 getopt 在短选项中不直接支持解析多个参数的值，因此在这里手动处理长选项。
#         对于每个长选项，检查下一个参数是否以 - 开头，如果不是，则认为是该选项的值，并将其添加到相应的数组中。
#         如果遇到 --help 选项，调用 usage 函数。
#         当遇到 -- 时，表示选项解析完毕，退出循环。
# 4    ‌变量初始化‌：
#         初始化用于存储每种选项值的数组（如 TAGS、MESSAGES、START_VALUES 等）。
# 5    ‌解析命令行参数‌：
#         调用 parse_short_options 和 parse_long_options 函数来解析命令行参数。
# 6    ‌显示解析后的参数（调试）‌：
#         显示解析后的参数值，这部分仅用于调试，可以根据需要删除。
# 7    ‌逻辑处理‌：
#         根据解析后的参数值执行不同的逻辑处理。
#         对于每个选项数组，检查其长度是否大于 0，如果是，则执行相应的处理逻辑（如打印值、执行特定操作等）。
# 8    ‌处理非选项参数‌：
#         如果还有剩余的位置参数（即非选项参数），则执行相应的处理逻辑。
#         在此示例中，仅打印出非选项参数的值，但你可以根据需要添加其他处理逻辑。
# 9    ‌脚本结束‌：
#         脚本的主要逻辑处理完成后，脚本结束运行。
# 通过这个模板，可以轻松地添加新的选项和参数，
#   只需在 parse_short_options 和 parse_long_options 函数中添加相应的解析逻辑，
#   并在逻辑处理部分添加相应的处理代码即可。这种拆分和模块化的方法使得代码更加清晰、易读且易于维护。
#  ############################################################################################## ^
###################################################################################################




#################################################################################################
# 带参数函数示例 
#################################################################################################
process_file(){
    local ltmp_file=$1
    log_message "Processing file: $ltmp_file" [INFO]
    cat $ltmp_file
    # 这里可以添加处理文件的逻辑
}

#################################################################################################
# 启动本机 httpd 服务
start_my_httpd_usage(){
    
    echo -ne "${GREEN}
    --start         ${NC}开启 http 服务${GREEN}"
    echo 
}
#################################################################################################

# 定义全局数组
declare -a SITE_DIRECTORIES

# 函数：从httpd配置文件中获取所有站点的目录
get_site_directories() {
    local config_file
    local site_directory

    # 遍历/etc/httpd/conf.d/目录下的所有配置文件
    #for config_file in /etc/httpd/conf.d/*.conf; do
    #for config_file in /etc/httpd/conf/httpd.conf; do
    for config_file in /etc/httpd/conf/*.conf; do
    
        # # 检查文件是否存在
        # if [ -f "$config_file" ]; then
        #     # 使用grep和awk提取DocumentRoot指令后的目录路径
        #     site_directory=$(grep -E '^[[:space:]]*DocumentRoot[[:space:]]' "$config_file" | awk '{print $2}')
        #     # 检查目录是否存在
        #     if [ -n "$site_directory" ] && [ -d "$site_directory" ]; then
        #         # 将目录路径添加到全局数组中
        #         SITE_DIRECTORIES+=("$site_directory")
        #     fi
        # fi

        # 检查文件是否存在
        if [ -f "$config_file" ]; then
            # 使用grep和awk提取VirtualHost部分的DocumentRoot指令后的目录路径
            site_directory=$(grep -E '^[[:space:]]*<VirtualHost[[:space:]]' "$config_file" | awk -F'[<>]' '/DocumentRoot/{print $3}')
            # 检查目录是否存在
            if [ -n "$site_directory" ] && [ -d "$site_directory" ]; then
                # 将目录路径添加到全局数组中
                SITE_DIRECTORIES+=("$site_directory")
            fi
        fi
    done
}

start_my_httpd(){
    # 显示并记录启动httpd服务
    log_message "开始启动httpd服务" "INFO"


    # 调用函数获取站点目录
    get_site_directories

    # 打印全局数组中的站点目录
    echo "Site Directories:"
    for dir in "${SITE_DIRECTORIES[@]}"; do
        echo "$dir"
    done

    end_the_batch


    # 增加selinux文件标签,以使httpd可读该文件夹内文件.
    log_message "增加selinux文件标签,以使httpd可读该文件夹内文件." "INFO"
    chcon -R -t httpd_user_ra_content_t  /TDATAS/DATAS/.PublicDATAS/TMPDownloads  

    # 设置目录权限(增加所有人的可读权限)
    chmod -R o+r  /TDATAS/DATAS/.PublicDATAS/TMPDownloads

    # 检查返回值
    if [ $? -eq 0 ]; then
        log_message "chmod命令执行成功，/TDATAS/DATAS/.PublicDATAS/TMPDownloads 目录下文件权限已更改为所有人可读。"
    else
        log_message "chmod命令执行失败，/TDATAS/DATAS/.PublicDATAS/TMPDownloads 目录下文件权限修改过程遇到问题。状态码：$?"
        sudo_execute "chmod -R o+r  /TDATAS/DATAS/.PublicDATAS/TMPDownloads" 
    fi

    # 启动httpd服务
    sudo_execute "systemctl start httpd"
    
    local ltmp_RET=$?
    case "$ltmp_RET" in
        failure)
            log_message "$ltmp_RET 服务启动失败" "INFO"
            end_the_batch
            ;;
        success-stop)
            log_message "$ltmp_RET 服务已成功启动，但之前停止尝试失败" "INFO"
            # 根据需要进行处理
            ;;
        success)
            log_message "$ltmp_RET 服务已成功启动" "INFO"
            # 根据需要进行处理
            ;;
        0)
            log_message "$ltmp_RET 服务已成功启动" "INFO"
            # 根据需要进行处理
            ;;
        *)
            log_message "未知的返回值" "INFO"
            log_message "返回值: $ltmp_RET" "INFO"
            # end_the_batch
            ;;
    esac

    # 打开防火墙端口
    #sudo_execute "firewall-cmd --add-port=80/tcp --permanent"
    sudo_execute "firewall-cmd --add-port=80/tcp "
    #sudo_execute "firewall-cmd --reload"
}

#################################################################################################
# 停止本机 httpd 服务 
stop_my_httpd_usage(){
    
    echo -ne "${GREEN}
    --stop          ${NC}关闭 http 服务${GREEN}"
    echo 
}
#################################################################################################
stop_my_httpd(){
    # 显示并记录停止httpd服务
    log_message "开始停止httpd服务" "INFO"

    # 停止httpd服务
    sudo_execute "systemctl stop httpd"

    if [ $? -eq 0 ]; then
        log_message "服务停止成功" "INFO"
    else
        log_message "$? 服务停止失败" "INFO"
    fi

    # 关闭防火墙端口
    sudo_execute "firewall-cmd --remove-port=80/tcp --permanent"
    sudo_execute "firewall-cmd --reload"
}

#################################################################################################
# 安装指定python版本
#################################################################################################
py_install(){
    local ltmp_PYTHON_VERSION
    # 没有参数则安装默认python版本"3.9.0"
    if [ $# -eq 0 ]; then
       ltmp_PYTHON_VERSION="3.9.0"
    else
       ltmp_PYTHON_VERSION=$1
    fi
    
    log_message "目标: 安装 Python 版本 : ${GREEN}${ltmp_PYTHON_VERSION}${NC}"

    # 指定要安装的Python版本
    #ltmp_PYTHON_VERSION="3.9.0"

    #which_app_manager

    # 安装依赖工具
    if [ $app_manager == "dnf" ];then 
        sudo_execute "${app_manager} install -y make gcc openssl-devel bzip2-devel libffi-devel  zlib-devel readline-devel sqlite-devel tk-devel xz-devel  wget curl llvm ncurses-devel"
    elif [ $app_manager == "apt" ];then 
        sudo_execute "${app_manager} update "
        sudo_execute "${app_manager} install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git "
    fi

    # 定义下载和安装目录
    ltmp_DOWNLOAD_DIR="${this_TMP_DIR}/python-download"
    ltmp_INSTALL_DIR="/usr/local/python${ltmp_PYTHON_VERSION}"



    # 创建下载目录
    mkdir -p "${ltmp_DOWNLOAD_DIR}"
    cd "${ltmp_DOWNLOAD_DIR}"

    # https://www.python.org/ftp/python/3.9.0/Python-3.9.0.tgz
    # https://www.python.org/ftp/python/3.9.0/Python-3.9.0.tar.xz
    # 下载Python源码
    if [ "$this_parameter_url" == "NULL" ];then
        wget "https://www.python.org/ftp/python/${ltmp_PYTHON_VERSION}/Python-${ltmp_PYTHON_VERSION}.tgz"
    else
        wget "$this_parameter_url"
    fi
   
    # 解压源码包
    tar -xzf "Python-${ltmp_PYTHON_VERSION}.tgz"

    # 进入解压目录
    cd "Python-${ltmp_PYTHON_VERSION}"

    # 配置安装参数
    ./configure --enable-optimizations --with-openssl --prefix="${ltmp_INSTALL_DIR}"

    # 编译源码
    make -j $(nproc)

    # 安装编译后的Python
    sudo make altinstall

    # 验证安装
    "${ltmp_INSTALL_DIR}/bin/python${ltmp_PYTHON_VERSION%.*}" --version

    # 清理下载目录（可选）
    cd
    rm -rf "${ltmp_DOWNLOAD_DIR}"

    echo "Python ${ltmp_PYTHON_VERSION} installed successfully to ${ltmp_INSTALL_DIR}"

}

#################################################################################################
# 清空 nfs的配置文件 /etc/exports
# 参数: 无
# 成功返回 0
# 失败返回 1
#################################################################################################
empty_nfs_exports(){
    show_who_call
    sudo_execute "sh -c \'echo  > /etc/exports\' "
    local ret_sudo_tp=$?
    if [ $ret_sudo_tp -eq 1 ];then
        log_message "清空 NFS 服务配置文件失败." "ERROR"
    fi
    return 0
}

nfs_share_usage(){
    echo -ne "${GREEN}
    --nfs-share ${BLUE}target_dir     ${NC}设置${BLUE}target_dir${NC}目录为nfs共享${GREEN}"
    echo
}

#################################################################################################
# 将目录设为nfs共享
#   o 启用 NFS 服务(如果没有启用),此处通过默认包管理器下载安装,需要网络.
#   o 将目录设为局域网可读写(如果文件目录存在)
#   o 打开 NFS 服务所需的防火墙端口
#################################################################################################
set_dir_2_nfs(){
    # 检查需要的软件包是否已经安装
    case $app_manager in 
        apt)
            check_packages_installed "nfs-kernel-server"
            ;;
        dnf)
            check_packages_installed "nfs-utils rpcbind"
            #bp
            ;;
        *)
            log_message "其他包管理器: [ $app_manager ] 对应的包安装逻辑暂未编写."
            return 1
            ;;
    esac
    
    # 没有安装软件包则进行安装
    if [ -n "$this_not_installed_packages" ];then
        #非空
        install_package "$this_not_installed_packages"
    fi

    # 参数是否为空,空则提示需要一个参数.
    if [ -z "$1" ]; then
        log_message "请提供一个目录作为NFS共享" "ERROR"
        return 1
    fi

    # 启动nfs的服务
    case $app_manager in 
        apt)
            sudo_execute "systemctl start nfs-kernel-server"
            #sudo_execute "systemctl enable nfs-kernel-server"
            ;;
        dnf)
            sudo_execute "systemctl start nfs-server"
            #sudo_execute "systemctl start nfs-utils"
            #sudo_execute "systemctl enable nfs-utils"
            ;;
        *)
            log_message "其他包管理器: [ $app_manager ] 对应的包安装逻辑暂未编写."
            return 1
            ;;
    esac

    #此时不再检测

    # 设置给定目录为NFS共享
    local ltmp_SHARED_DIR=$1
    local ltmp_EXPORTS_FILE="/etc/exports"
    local ltmp_NFS_CONFIG_BASE="$ltmp_SHARED_DIR *(rw,sync,no_subtree_check)"
 
    # 确保目录存在
    if [ ! -d "$ltmp_SHARED_DIR" ]; then
        log_message "目录 $ltmp_SHARED_DIR 不存在，创建中..." "WARNING"
        sudo_execute "mkdir -p $ltmp_SHARED_DIR "
        #sudo_execute "chown $this_username $ltmp_SHARED_DIR "
    fi

    # 设置目录权限为可读写，并允许所有用户访问
    log_message "配置目录 $ltmp_SHARED_DIR 为NFS共享..." "WARNING"
    sudo_execute "chmod 777 $ltmp_SHARED_DIR"
    sudo_execute "chown root:root $ltmp_SHARED_DIR"

    # 添加目录到exports文件,
    # sudo提供的是临时的root权限，而echo命令是一个普通用户进程。
    # 如果需要非交互式添加内容，可以使用sudo sh -c 'echo "your-content" >> /etc/exports'
    # 这里使用了重定向操作符>>来追加内容，而不是覆盖文件内容。
    # 注意：在编辑/etc/exports后，通常需要重启NFS服务或使用exportfs命令来使变更生效。 
    #  该方式无法写入已弃用 -->> sudo_execute "echo \"$ltmp_SHARED_DIR *(rw,sync,no_subtree_check) \"  >>  $ltmp_EXPORTS_FILE "  #
    # sudo  "sh -c 'echo \"$ltmp_SHARED_DIR *(rw,sync,no_subtree_check) \" >> /etc/exports' "
    # 可用的方法 -->> echo "$ltmp_SHARED_DIR *(rw,sync,no_subtree_check)" | sudo_execute "tee -a $ltmp_EXPORTS_FILE" #> /dev/null

    # 备份exports文件 ,原始命令#cp -vf "$EXPORTS_FILE" "$ltmp_BACKUP_FILE" ,后来封装了记账和备份函数.则改为使用记账和备份后生成唯一标识多功能一体的函数
    local ltmp_IDENTIFIER=$(backup_and_log "/etc/exports")

    if [ -z "$ltmp_IDENTIFIER" ];then
        log_message "/etc/exports 文件备份,或唯一标识生成异常.程序终止退出" "ERROR"
        return 1
    elif [ "$ltmp_IDENTIFIER" == "1" ];then
        log_message "/etc/exports 文件备份,或唯一标识生成异常.程序终止退出" "ERROR"
        return 1
    else
        log_message "/etc/exports 文件备份,或唯一标识生成结束.获取到的唯一标识为 [ $ltmp_IDENTIFIER ] " "WARNING"
    fi

    # 检查exports文件中是否已经存在该目录的配置
    #if grep -Fxq "$ltmp_NFS_CONFIG_BASE" "$ltmp_EXPORTS_FILE"; then
    if grep -Fq "$ltmp_NFS_CONFIG_BASE" "$ltmp_EXPORTS_FILE"; then
        log_message "目录 $ltmp_SHARED_DIR 的配置 $ltmp_NFS_CONFIG_BASE 已存在,不再重复添加" "ERROR"
    else
        # 添加目录到exports文件（使用sudo和tee确保正确写入）
        local ltmp_NFS_CONFIG="$ltmp_NFS_CONFIG_BASE # $ltmp_IDENTIFIER"
        log_message "将目录 $ltmp_SHARED_DIR 添加到exports文件（识别符: $ltmp_IDENTIFIER ) ..." "WARNING"
        log_message "即将执行命令 [ echo \"$ltmp_SHARED_DIR *(rw,sync,no_subtree_check)\" | sudo tee -a \"$ltmp_EXPORTS_FILE\" ]"
        echo "$ltmp_NFS_CONFIG" | sudo_execute "tee -a $ltmp_EXPORTS_FILE" > /dev/null
    fi

    # 重新导出目录
    sudo_execute "exportfs -a"

    # 打印目前已共享的所有目录和对应的权限
    log_message "目前已共享的所有目录和对应的权限:" "INFO"
    unsudo_execute "cat $ltmp_EXPORTS_FILE"

    # 开启防火墙端口
    log_message "即将开启防火墙策略以允许客户端访问 NFS 服务." "WARNING"
    sudo_execute "firewall-cmd --add-service=rpc-bind $this_permanent"
    sudo_execute "firewall-cmd --add-service=mountd $this_permanent"
    sudo_execute "firewall-cmd --add-service=nfs $this_permanent"
    # sudo_execute "firewall-cmd --reload"

    # NFS设置成功后，调用了get_nfs_server_ips函数来获取IP地址列表
    get_all_ip
    
    # 检查是否成功获取到IP地址
    if [ ${#this_host_ip_list[@]} -eq 0 ]; then
        log_message "错误：无法确定NFS服务器的IP地址。" "ERROR"
        return 1
    fi

    # 输出成功信息
    log_message "NFS设置成功，服务器IP地址列表：${this_host_ip_list[@]}" "WARNING"


    for IP in "${this_host_ip_list[@]}"; do
        # 构造客户端挂载命令
        local ltmp_CLIENT_MOUNT_CMD="sudo mount -t nfs $IP:$ltmp_SHARED_DIR  /mnt/NFS_mount_point_of_$IP"
        
        # 输出客户端挂载命令到屏幕
        # 注意：这里我们为每个IP地址创建了一个不同的挂载点，以避免冲突
        echo "客户端挂载命令（IP: $IP）：$ltmp_CLIENT_MOUNT_CMD"
        
        # 可选：如果你希望自动在客户端执行挂载，可以取消下面的注释
        # 但请注意，这通常需要在客户端机器上以root权限运行
        # $ltmp_CLIENT_MOUNT_CMD
    done


    #结束了.管它呢,就这样吧.
    log_message "NFS服务配置完成,并成功共享目录 $ltmp_SHARED_DIR" "WARNING"
    return 0
}

#################################################################################################

#################################################################################################
remove_nfs_config() {
    local REMOVE_PARAM=$1
    local FOUND=0
    local MATCH_LINE=""

    # 如果参数是以特定前缀开始的（假设是备份文件的标识符），则认为是标识符删除
    if [[ "$REMOVE_PARAM" == *"_"* ]]; then
        IDENTIFIER_TO_REMOVE=$(echo "$REMOVE_PARAM" | cut -d'_' -f2)
        # 遍历exports文件的每一行，检查是否包含要删除的标识符
        while IFS= read -r LINE; do
            if [[ "$LINE" == *"# $IDENTIFIER_TO_REMOVE"* ]]; then
                MATCH_LINE="$LINE"
                sudo sed -i "/$MATCH_LINE/d" "$EXPORTS_FILE"
                FOUND=1
                break
            fi
        done < "$EXPORTS_FILE"
    else
        # 否则认为是目录名删除
        while IFS= read -r LINE; do
            if [[ "$LINE" == *"$REMOVE_PARAM"* ]]; then
                MATCH_LINE="$LINE"
                sudo sed -i "/$MATCH_LINE/d" "$EXPORTS_FILE"
                FOUND=1
                # 由于可能删除多条，所以不break
            fi
        done < "$EXPORTS_FILE"
    fi

}


#################################################################################################
# 挂载 NFS 共享目录
# 参数:
#   o nfs_server: NFS 服务器的主机名或 IP
#   o mount_point: 挂载目录
#   o all_option: 可选参数 "--all"，表示挂载所有共享目录
# 成功返回 0
# 失败返回 1
# 示例:
#   o mount_nfs "nfs_server_ip" "/mnt/nfs"
#   o mount_nfs "nfs_server_ip" "/mnt/nfs" "--all"
# 注意:
#   o 如果提供了 "--all" 参数，则会挂载所有共享目录
#   o 如果未提供 "--all" 参数，则会列出所有共享目录，并提示用户选择要挂载的目录
#   o 挂载目录的权限为 777
# author: MarsCode AI
# date: 2024-12-30
# version: 1.0.0
# tester: saint
#################################################################################################
mount_nfs() {
    local nfs_server="$1"
    local mount_point="$2"
    local all_option="$3"

    # 检查是否提供了必要的参数
    if [ -z "$nfs_server" ] || [ -z "$mount_point" ]; then
        echo "请提供 NFS 服务器的主机名或 IP 以及挂载目录。"
        return 1
    fi

    # 检查挂载点是否存在，如果不存在则创建
    if [ ! -d "$mount_point" ]; then
        #mkdir -p "$mount_point"
        create_directory "$mount_point" --force
    fi

    # 获取 NFS 服务器上的共享目录列表
    local shares=$(showmount -e "$nfs_server" | awk '{if (NR!=1) print $1}')

    # 检查命令是否执行成功
    if [ $? -ne 0 ]; then
        log_message "无法获取 NFS 服务器 $nfs_server 上的共享目录列表：$shares" "ERROR"
        log_message "错误信息: $?" "ERROR"
        return 1
    fi

    # 如果没有共享目录，则退出
    if [ -z "$shares" ]; then
        echo "NFS 服务器 $nfs_server 上没有共享目录。"
        return 1
    fi

    # 如果指定了 --all 参数，则挂载所有共享目录
    if [ "$all_option" == "--all" ]; then
        for share in $shares; do
            local share_name=$(basename "$share")
            local mount_dir="$mount_point/$share_name"
            #mkdir -p "$mount_dir"
            create_directory "$mount_dir" --force
            sudo_execute "mount -t nfs $nfs_server:$share  $mount_dir "
            if []$? -ne 0 ]; then
                echo "无法挂载 $nfs_server:$share 到 $mount_dir"
                return 1
            fi
            echo "已挂载 $nfs_server:$share 到 $mount_dir"
        done
    else
        # 列出共享目录并提示用户选择
        echo "请选择要挂载的 NFS 共享目录："
        local i=1
        for share in $shares; do
            echo "$i. $share"
            i=$((i+1))
        done

        # 读取用户选择
        read -p "请输入编号: " choice

        # 检查用户选择是否有效
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -ge "$i" ]; then
            echo "无效的选择。"
            return 1
        fi

        # 获取用户选择的共享目录
        local selected_share=$(echo "$shares" | sed -n "${choice}p")

        # 挂载用户选择的共享目录
        local share_name=$(basename "$selected_share")
        local mount_dir="$mount_point/$share_name"
        #mkdir -p "$mount_dir"
        create_directory  "$mount_dir"  --force
        sudo_execute "mount -t nfs $nfs_server:$selected_share  $mount_dir "
        if [ $? -ne 0 ]; then
            echo "无法挂载 $nfs_server:$selected_share 到 $mount_dir"
            return 1
        fi
        echo "已挂载 $nfs_server:$selected_share 到 $mount_dir"
    fi
}

mount_nfs_with_zenity() {
    local nfs_server="$1"
    local mount_point="$2"
    local all_option="$3"

    # 检查是否提供了必要的参数
    if [ -z "$nfs_server" ] || [ -z "$mount_point" ]; then
        echo "请提供 NFS 服务器的主机名或 IP 以及挂载目录。"
        return 1
    fi

    # 检查挂载点是否存在，如果不存在则创建
    if [ ! -d "$mount_point" ]; then
        #mkdir -p "$mount_point"
        create_directory_gui "$mount_point" --force
    fi

    # 获取 NFS 服务器上的共享目录列表
    local shares=$(showmount -e "$nfs_server" | awk '{if (NR!=1) print $1}')

    # 检查命令是否执行成功
    if [ $? -ne 0 ]; then
        log_message "无法获取 NFS 服务器 $nfs_server 上的共享目录列表：$shares" "ERROR"
        log_message "错误信息: $?" "ERROR"
        return 1
    fi

    # 如果没有共享目录，则退出
    if [ -z "$shares" ]; then
        echo "NFS 服务器 $nfs_server 上没有共享目录。"
        return 1
    fi

    # 如果指定了 --all 参数，则挂载所有共享目录
    if [ "$all_option" == "--all" ]; then
        for share in $shares; do
            local share_name=$(basename "$share")
            local mount_dir="$mount_point/$share_name"
            #mkdir -p "$mount_dir"
            create_directory_gui "$mount_dir" --force
            sudo_execute_gui "mount -t nfs $nfs_server:$share  $mount_dir "
            if [ $? -ne 0 ]; then
                echo "无法挂载 $nfs_server:$share 到 $mount_dir"
                return 1
            fi
            echo "已挂载 $nfs_server:$share 到 $mount_dir"
        done
    else
        local ltmp_nfs_dir_choice=$(zenity --list --title="选择要挂载的 NFS 共享目录" --column="共享目录" $shares )
        if [ -z "$ltmp_nfs_dir_choice" ]; then
            zenity --error --text="未选择任何共享目录。"
            return 1
        fi
        zenity --info --text="您选择了 $ltmp_nfs_dir_choice "
        #end_the_batch
        
        # 获取用户选择的共享目录
        #local selected_share=$(ltmp_nfs_dir_choice)

        # 挂载用户选择的共享目录
        local share_name_sg=$(basename "$ltmp_nfs_dir_choice")
        #zenity --info --text="share_name $share_name_sg  "
        local mount_dir="$mount_point/$share_name_sg"
        #zenity --info --text="mount_dir $mount_dir  "
        #end_the_batch
        #mkdir -p "$mount_dir"
        create_directory_gui  "$mount_dir"  --force
        sudo_execute_gui "mount -t nfs $nfs_server:$ltmp_nfs_dir_choice  $mount_dir "
        zenity --info --text="返回值为 $? "
        if [ $? -ne 0 ]; then
            echo "无法挂载 $nfs_server:$ltmp_nfs_dir_choice 到 $mount_dir"
            return 1
        fi
        echo "已挂载 $nfs_server:$ltmp_nfs_dir_choice 到 $mount_dir"
    fi
}


extract_item_grep() {
    local input_string="$1"
    local item="$2"
    echo "$input_string" | grep -oP "(?<=$item )\S+" | head -n 1
}

setup_x11vnc_server_usage(){
    
    echo -ne "${GREEN}
    --set_x11vnc ${BLUE}vncpassword  ${NC}安装并设置x11vnc,连接密码设置为${BLUE}vncpassword${NC}
                        当提供的 vncpassword 为default时,VNC密码会被设置为 Tongyi@123 
                        例:     ${GREEN}$0 --set_x11vnc ${BLUE}myVNCPassword${NC}"
    echo 
}

# 设置x11vnc服务
setup_x11vnc_server(){

    local ltmp_vncpassword=$1
    if [ "$ltmp_vncpassword" == "default" ];then
        ltmp_vncpassword="Tongyi@123"
    fi
    
    local ltmp_location=$(pwd)/kylin_20241107/x11vnc_${this_arch}/depend_kylinServerV10sp3_20241107

    local ltmp_rpm_qa_libvncserver=$(rpm -qa  libvncserver)
    if [ -z "$ltmp_rpm_qa_libvncserver" ];then 
        sudo_execute "rpm -ivh ${ltmp_location}/*.rpm --force"
        if [ $? -ne 0 ];then
            log_message "rpm 包安装失败.返回值 $? ." "ERROR"
            return 1
        fi
    fi

    local ltmp_file1="/usr/bin/x11vnc"
    local ltmp_file2="/usr/bin/Xdummy"

    if [[ -f "$ltmp_file1" ]] &&  [[ -f "$ltmp_file2" ]]; then
        log_message "文件 $ltmp_file1 和 $ltmp_file2 已经存在,暂不进行替换"
    else
        #echo $ltmp_x11vnc_service_systemd_file | base64 -d  >${this_TMP_DIR}/x11vnc.service
        sudo_execute "cp $(pwd)/kylin_20241107/x11vnc_${this_arch}/x11vnc_${this_arch}/usr/bin/* /usr/bin/"
        if [ $? -ne 0 ];then
            log_message "x11vnc 程序文件 拷贝失败.返回值 $? ." "ERROR"
            return 1
        fi
    fi

    # sudo_execute "cp $(pwd)/kylin_20241107/x11vnc.service /etc/systemd/system/x11vnc.service"
    # if [ $? -ne 0 ];then
    #     log_message "x11vnc的 服务配置 文件拷贝失败.返回值 $? ." "ERROR"
    #     return 1
    # fi

    local ltmp_x11vnc_service_file="/etc/systemd/system/x11vnc.service"
    if [[ -f "$ltmp_x11vnc_service_file" ]];then

        local ltmp_values_str=$(read_ini_file "$ltmp_x11vnc_service_file" "Service" "ExecStart")

        log_message "系统中现有 x11vnc 服务配置文件 中获取到的启动命令及参数为 $ltmp_values_str" "WARNING"

        rfbport_value=$(extract_item_grep "$ltmp_values_str" "rfbport")

        sudo_execute "systemctl stop x11vnc.service"
    fi
    
    
    
    # 为避免与已有 VNC 服务冲突,除非参数指定默认使用 55900 作为服务端口
    if [ -z "$this_single_port" ];then
        this_single_port="55900"
    fi

    # 服务配置文件中 x11vnc的启动命令 
    local ltmp_ExecStart_str="/usr/bin/x11vnc -display :0 -auth guess -forever -rfbauth /etc/x11vnc.pass -shared -rfbport ""${this_single_port}"
    
    write_ini_file "$ltmp_x11vnc_service_file" "Unit" "Description" "start x11vnc service"
    write_ini_file "$ltmp_x11vnc_service_file" "Unit" "After" "display-manager.service network.target syslog.target"
    write_ini_file "$ltmp_x11vnc_service_file" "Service" "Type" "simple"
    write_ini_file "$ltmp_x11vnc_service_file" "Service" "ExecStart" "$ltmp_ExecStart_str"
    write_ini_file "$ltmp_x11vnc_service_file" "Service" "ExecStop" "/usr/bin/killall x11vnc"
    write_ini_file "$ltmp_x11vnc_service_file" "Service" "Restart" "on-failure"
    write_ini_file "$ltmp_x11vnc_service_file" "Install" "WantedBy" "multi-user.target"
    #write_ini_file "$ltmp_x11vnc_service_file" "Service" "ExecStart" '/usr/bin/x11vnc -display :0 -auth guess -forever -rfbauth /etc/x11vnc.pass -shared -rfbport 5900'
    
    #local ltmp_values_str='/usr/bin/x11vnc -rfbport 55900 -display :0 -auth guess -forever -rfbauth /etc/x11vnc.pass -shared '
    
    
    
    # [ "$(sha256sum ${this_TMP_DIR}/x11vnc.service | awk '{ print $1 }')" = "$ltmp_x11vnc_service_systemd_file_sha256" ] && echo "SHA256 matches" || exit 1

    #log_message "VNC password ==I>> $ltmp_vncpassword " "WARNING"
    log_MESSAGE "VNC password ==I>>${PINK} $ltmp_vncpassword ${NC}" "WARNING"
    sudo_execute_quiet "/usr/bin/x11vnc -storepasswd $ltmp_vncpassword /etc/x11vnc.pass"
    if [ $? -ne 0 ];then
        log_message "x11vnc 连接密码设置失败.返回值 $? ." "ERROR"
        #return 1
    fi

    sudo_execute "chmod 774 /etc/x11vnc.pass"
    if [ $? -ne 0 ];then
        log_message "x11vnc 存储连接密码的文件权限设置失败.返回值 $? ." "ERROR"
        return 1
    fi

    # sudo_execute "cp ${this_TMP_DIR}/x11vnc.service /etc/systemd/system/"
    sudo_execute "systemctl daemon-reload"
    if [ $? -ne 0 ];then
        log_message "x11vnc 服务配置加载失败.返回值 $? ." "ERROR"
        return 1
    fi

    sudo_execute "systemctl enable x11vnc.service"
    if [ $? -ne 0 ];then
        log_message "x11vnc 服务 开机自动启动 设置失败.返回值 $? ." "ERROR"
        return 1
    fi

    sudo_execute "systemctl start x11vnc.service"
    if [ $? -ne 0 ];then
        log_message "x11vnc 服务启动 失败.返回值 $? ." "ERROR"
        return 1
    fi

    log_message "查看服务启动状态"
    sudo_execute "systemctl status x11vnc.service"

    # 当第二次执行函数,主要功能则成为了更改密码和更改设置端口,因此需要记录原配置文件中读取到的端口号,并将之从防火墙允许的端口列表中去掉
    if [ ! -z "$rfbport_value" ];then
    	sudo_execute "firewall-cmd --remove-port=${rfbport_value}/tcp --permanent"
    	#remove_firewall_ports # 该函数未开始编写,仅写了个框架
    fi

    GLOBAL_PORT_LIST="\"${this_single_port}\""
    add_firewall_ports "tcp" "public"

    log_MESSAGE "x11vnc 当前的连接密码为${PINK} $ltmp_vncpassword ${NC}" "WARNING"
    log_MESSAGE "您可以通过 sudo  /usr/bin/x11vnc -storepasswd  ${PINK}54mima ${NC}/etc/x11vnc.pass 命令来一次性设置VNC连接密码( 54mima 替换为密码)" "WARNING"
    log_MESSAGE "或者使用  sudo  /usr/bin/x11vnc -storepasswd  /etc/x11vnc.pass 命令后,根据屏幕提示分别输入两次密码来设置VNC连接密码." "WARNING"
    log_MESSAGE "但请注意,如果这是五分钟内第一次使用sudo命令可能要先输入当前用户的密码来获取sudo权限,之后才会是vnc密码的输入.请注意辨别." "WARNING"

    log_MESSAGE "x11vnc 当前的服务端口为 $this_single_port"
    log_MESSAGE "手动关闭防火墙端口的命令: sudo firewall-cmd --remove-port=${this_single_port}/tcp"
    log_MESSAGE "手动打开防火墙端口的命令: sudo firewall-cmd --add-port=${this_single_port}/tcp"
    log_MESSAGE "仅允许指定IP访问某端口的命令是: sudo firewall-cmd --permanent --add-rich-rule=\"rule family=\"ipv4\" source address=\"IP地址\" port protocol=\"tcp\" port=\"端口号\" accept " 
    log_MESSAGE "上述仅允许指定IP访问某端口的命令需要慎重使用\!因为部分网络设备或程序会更改网络数据包的来源地址,因此服务器接收的来源地址并不一定与真实情况一致."
    
    log_MESSAGE "启动 x11vnc 服务的命令: ${GREEN}sudo systemctl start x11vnc${NC}"
    log_MESSAGE "停止 x11vnc 服务的命令: ${RED}sudo systemctl stop x11vnc${NC}"
    log_MESSAGE "查看 x11vnc 服务状态命令: ${BLUE}sudo systemctl status x11vnc${NC}"
    log_MESSAGE "设置 x11vnc 服务开机自启: ${GREEN}sudo systemctl enable x11vnc${NC}"
    log_MESSAGE "取消 x11vnc 服务开机自启: ${RED}sudo systemctl disable x11vnc${NC}"
    
    sleep 5

    if ss -ntpl |grep -q "$this_single_port" ;then
        log_message "设置x11vnc成功" "INFO"
    else
        log_message "设置x11vnc失败" "ERROR"
        return 1
    fi

    return 0

}

#################################################################################################
# 设置x11vnc服务(通用版本)  from 20241127
#################################################################################################
setup_x11vnc_server_new(){

    local ltmp_vncpassword=$1
    if [ "$ltmp_vncpassword" == "default" ];then
        ltmp_vncpassword="Tongyi@123"
    fi
    
     # 操作系统品牌
    #this_os_release_logo_name

    # 操作系统类型 server or workstation or desktop
    #this_os_release_type

    # 根据不同操作系统,安装不同的包.此处未做依赖关系判断.
    #   后期其他项目要使用则需要判断操作系统版本与包依赖情况.
    local ltmp_location_depend=""
    local ltmp_location_bin=""
    local ltmp_file1=""
    local ltmp_file2=""
    local ltmp_rfbport_value=""

    case $this_os_release_logo_name in 
        kylin)
            if [ "$this_os_release_type" == "server" ];then
                ltmp_location_depend=$(pwd)/kylin_20241107/x11vnc_${this_arch}/depend_kylinServerV10sp3_20241107
                ltmp_location_bin=$(pwd)/kylin_20241107/x11vnc_${this_arch}/x11vnc_${this_arch}/usr/bin
            else
                echo "暂时未适配桌面版"
                end_the_batch
                ltmp_location_depend=""
            fi

            local ltmp_rpm_qa_libvncserver=$(rpm -qa  libvncserver)
            if [ -z "$ltmp_rpm_qa_libvncserver" ];then 
                sudo_execute "rpm -ivh ${ltmp_location_depend}/*.rpm --force"
                if [ $? -ne 0 ];then
                    log_message "rpm 包安装失败.返回值 $? ." "ERROR"
                    return 1
                fi
            fi

            ltmp_file1="/usr/bin/x11vnc"
            ltmp_file2="/usr/bin/Xdummy"
            ;;
        uos)
            ltmp_file1="/usr/bin/x11vnc"
            ltmp_file2="/usr/bin/Xdummy"

            ;;
        fedora)
            echo "暂时未适配 fedora 操作系统"
            end_the_batch
            ;;
        NFS)
            check_packages_installed "x11vnc xorg-x11-server-Xvfb"
            # 没有安装软件包则进行安装
            if [ -n "$this_not_installed_packages" ];then
                if [ $this_b_network_promision == "true" ];then
                    #非空
                    install_package "$this_not_installed_packages"
                else
                    echo "需要的软件包未安装,当前暂未适配离线安装方式."
                    end_the_batch
                fi
            
                # 检查是否安装成功
                check_packages_installed "x11vnc xorg-x11-server-Xvfb"
                if [ -n "$this_not_installed_packages" ];then
                    echo "软件包安装失败,请检查网络或其他原因."
                    end_the_batch
                fi
                ltmp_file1="/usr/bin/x11vnc"
                ltmp_file2="/usr/bin/Xdummy"
            else
                # 当前已经安装了软件包(不需要再次安装)
                ltmp_file1="/usr/bin/x11vnc"
                ltmp_file2="/usr/bin/Xdummy"
                
            fi
            ;;
        *)
            echo "暂时未适配 $this_os_release_logo_name ${this_os_release_type}操作系统"
            end_the_batch
            ;;
    esac
    
    # 可执行文件(x11vnc二进制可执行文件)判断,不存在就从 ${ltmp_location_bin} 拷贝
    if [[ -f "$ltmp_file1" ]] &&  [[ -f "$ltmp_file2" ]]; then
        log_message "文件 $ltmp_file1 和 $ltmp_file2 已经存在,暂不进行替换"
    else
        #这里增加判断 ltmp_location_bin 目录是否存在
        #echo $ltmp_x11vnc_service_systemd_file | base64 -d  >${this_TMP_DIR}/x11vnc.service
        sudo_execute "cp ${ltmp_location_bin}/* /usr/bin/"
        if [ $? -ne 0 ];then
            log_message "x11vnc 程序文件 拷贝失败.返回值 $? ." "ERROR"
            return 1
        fi
    fi

    # sudo_execute "cp $(pwd)/kylin_20241107/x11vnc.service /etc/systemd/system/x11vnc.service"
    # if [ $? -ne 0 ];then
    #     log_message "x11vnc的 服务配置 文件拷贝失败.返回值 $? ." "ERROR"
    #     return 1
    # fi

    local ltmp_x11vnc_service_file=""
    if [ "$this_os_release_logo_name" == "kylin" ];then 
        ltmp_x11vnc_service_file="/etc/systemd/system/x11vnc.service"
        log_message "ltmp_x11vnc_service_file=$ltmp_x11vnc_service_file"  "TRACE"
    elif [ "$this_os_release_logo_name" == "uos" ];then
        ltmp_x11vnc_service_file="/lib/systemd/system/x11vnc.service"
        log_message "ltmp_x11vnc_service_file=$ltmp_x11vnc_service_file"  "TRACE"
    elif [ "$this_os_release_logo_name" == "NFS" ];then
        ltmp_x11vnc_service_file="/lib/systemd/system/x11vnc.service"
        log_message "ltmp_x11vnc_service_file=$ltmp_x11vnc_service_file"  "TRACE"

    fi


    if [[ -f "$ltmp_x11vnc_service_file" ]];then

        local ltmp_values_str=$(read_ini_file "$ltmp_x11vnc_service_file" "Service" "ExecStart")

        log_message "系统中现有 x11vnc 服务配置文件 中获取到的启动命令及参数为 $ltmp_values_str" "WARNING"

        ltmp_rfbport_value=$(extract_item_grep "$ltmp_values_str" "rfbport")

        sudo_execute "systemctl stop x11vnc.service"
    fi
    
    
    
    # 为避免与已有 VNC 服务冲突,除非参数指定或原配置文件存在,否则默认使用 55900 作为服务端口
    if [ -z "$this_single_port" ];then
        if [ -n "$ltmp_rfbport_value" ];then
            this_single_port="$ltmp_rfbport_value"
        else
            this_single_port="55900"
        fi    
    fi

    local ltmp_ExecStart_str=""
    case $this_os_release_logo_name in 
        kylin)
            ltmp_ExecStart_str="/usr/bin/x11vnc -display :0 -auth guess -forever -rfbauth /etc/x11vnc.pass -shared -rfbport ""${this_single_port}"
    
            write_ini_file "$ltmp_x11vnc_service_file" "Unit" "Description" "start x11vnc service"
            write_ini_file "$ltmp_x11vnc_service_file" "Unit" "After" "display-manager.service network.target syslog.target"
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "Type" "simple"
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "ExecStart" "$ltmp_ExecStart_str"
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "ExecStop" "/usr/bin/killall x11vnc"
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "Restart" "on-failure"
            write_ini_file "$ltmp_x11vnc_service_file" "Install" "WantedBy" "multi-user.target"
            ;;
        uos)
            #ltmp_ExecStart_str="x11vnc -display :0 -auth /var/run/lightdm/root/:0 -forever -bg -o /var/log/x11vnc.log -shared -noxdamage -xrandr "resize" -rfbport ""${this_single_port}"
            ltmp_ExecStart_str="x11vnc -display :0 -auth /var/run/lightdm/root/:0 -forever -bg -o /var/log/x11vnc.log -shared -noxdamage -xrandr "resize" -rfbauth /etc/x11vnc.pass  -rfbport ""${this_single_port}"
            write_ini_file "$ltmp_x11vnc_service_file" "Unit" "Description" "Start x11vnc at startup."
            write_ini_file "$ltmp_x11vnc_service_file" "Unit" "After" "multi-user.target"
            #set -x
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "Type" "simple"
            #set +x
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "ExecStart" "$ltmp_ExecStart_str"
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "ExecStop" "/bin/kill \${MAINPID}"
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "RemainAfterExit" "yes"
            #write_ini_file "$ltmp_x11vnc_service_file" "Service" "Restart" "on-failure"  #原配置文件没有
            write_ini_file "$ltmp_x11vnc_service_file" "Install" "WantedBy" "multi-user.target"

            ;;
        NFS)
            #ltmp_ExecStart_str="x11vnc -display :0 -auth /var/run/lightdm/root/:0 -forever -bg -o /var/log/x11vnc.log -shared -noxdamage -xrandr "resize" -rfbport ""${this_single_port}"
            ltmp_ExecStart_str="x11vnc -display :0 -auth /var/run/lightdm/root/:0 -forever -bg -o /var/log/x11vnc.log -shared -noxdamage -xrandr "resize" -rfbauth /etc/x11vnc.pass  -rfbport ""${this_single_port}"
            write_ini_file "$ltmp_x11vnc_service_file" "Unit" "Description" "Start x11vnc at startup."
            write_ini_file "$ltmp_x11vnc_service_file" "Unit" "After" "multi-user.target"
            #set -x
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "Type" "simple"
            #set +x
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "ExecStart" "$ltmp_ExecStart_str"
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "ExecStop" "/bin/kill \${MAINPID}"
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "RemainAfterExit" "yes"
            #write_ini_file "$ltmp_x11vnc_service_file" "Service" "Restart" "on-failure"  #原配置文件没有
            write_ini_file "$ltmp_x11vnc_service_file" "Install" "WantedBy" "multi-user.target"
            ;;
        fedora)
            echo "暂时未适配 fedora 操作系统"
            end_the_batch
            ;;
        *)
            echo "暂时未适配 $this_os_release_logo_name 操作系统"
            end_the_batch
            # 服务配置文件中 x11vnc的启动命令 
            ltmp_ExecStart_str="/usr/bin/x11vnc -display :0 -auth guess -forever -rfbauth /etc/x11vnc.pass -shared -rfbport ""${this_single_port}"

            write_ini_file "$ltmp_x11vnc_service_file" "Unit" "Description" "start x11vnc service"
            write_ini_file "$ltmp_x11vnc_service_file" "Unit" "After" "display-manager.service network.target syslog.target"
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "Type" "simple"
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "ExecStart" "$ltmp_ExecStart_str"
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "ExecStop" "/usr/bin/killall x11vnc"
            write_ini_file "$ltmp_x11vnc_service_file" "Service" "Restart" "on-failure"
            write_ini_file "$ltmp_x11vnc_service_file" "Install" "WantedBy" "multi-user.target"
            ;;
    esac

    
    #write_ini_file "$ltmp_x11vnc_service_file" "Service" "ExecStart" '/usr/bin/x11vnc -display :0 -auth guess -forever -rfbauth /etc/x11vnc.pass -shared -rfbport 5900'
    
    #local ltmp_values_str='/usr/bin/x11vnc -rfbport 55900 -display :0 -auth guess -forever -rfbauth /etc/x11vnc.pass -shared '
    
    
    
    # [ "$(sha256sum ${this_TMP_DIR}/x11vnc.service | awk '{ print $1 }')" = "$ltmp_x11vnc_service_systemd_file_sha256" ] && echo "SHA256 matches" || exit 1

    #log_message "VNC password ==I>> $ltmp_vncpassword " "WARNING"
    log_MESSAGE "VNC password ==I>>${PINK} $ltmp_vncpassword ${NC}" "WARNING"
    sudo_execute_quiet "/usr/bin/x11vnc -storepasswd $ltmp_vncpassword /etc/x11vnc.pass"
    if [ $? -ne 0 ];then
        log_message "x11vnc 连接密码设置失败.返回值 $? ." "ERROR"
        #return 1
    fi

    sudo_execute "chmod 774 /etc/x11vnc.pass"
    if [ $? -ne 0 ];then
        log_message "x11vnc 存储连接密码的文件权限设置失败.返回值 $? ." "ERROR"
        return 1
    fi

    # sudo_execute "cp ${this_TMP_DIR}/x11vnc.service /etc/systemd/system/"
    sudo_execute "systemctl daemon-reload"
    if [ $? -ne 0 ];then
        log_message "x11vnc 服务配置加载失败.返回值 $? ." "ERROR"
        return 1
    fi

    sudo_execute "systemctl enable x11vnc.service"
    if [ $? -ne 0 ];then
        log_message "x11vnc 服务 开机自动启动 设置失败.返回值 $? ." "ERROR"
        return 1
    fi

    sudo_execute "systemctl start x11vnc.service"
    if [ $? -ne 0 ];then
        log_message "x11vnc 服务启动 失败.返回值 $? ." "ERROR"
        return 1
    fi

    log_message "查看服务启动状态"
    sudo_execute "systemctl status x11vnc.service"

    # 当第二次执行函数,主要功能则成为了更改密码和更改设置端口,因此需要记录原配置文件中读取到的端口号,并将之从防火墙允许的端口列表中去掉
    if [ ! -z "$ltmp_rfbport_value" ];then
    	sudo_execute "firewall-cmd --remove-port=${ltmp_rfbport_value}/tcp --permanent"
    	#remove_firewall_ports # 该函数未开始编写,仅写了个框架
    fi

    GLOBAL_PORT_LIST="\"${this_single_port}\""
    add_firewall_ports "tcp" "public"

    log_MESSAGE "x11vnc 当前的连接密码为${PINK} $ltmp_vncpassword ${NC}" "WARNING"
    log_MESSAGE "您可以通过 sudo  /usr/bin/x11vnc -storepasswd  ${PINK}54mima ${NC}/etc/x11vnc.pass 命令来一次性设置VNC连接密码( 54mima 替换为密码)" "WARNING"
    log_MESSAGE "或者使用  sudo  /usr/bin/x11vnc -storepasswd  /etc/x11vnc.pass 命令后,根据屏幕提示分别输入两次密码来设置VNC连接密码." "WARNING"
    log_MESSAGE "但请注意,如果这是五分钟内第一次使用sudo命令可能要先输入当前用户的密码来获取sudo权限,之后才会是vnc密码的输入.请注意辨别." "WARNING"

    log_MESSAGE "x11vnc 当前的服务端口为 $this_single_port"
    log_MESSAGE "手动关闭防火墙端口的命令: sudo firewall-cmd --remove-port=${this_single_port}/tcp"
    log_MESSAGE "手动打开防火墙端口的命令: sudo firewall-cmd --add-port=${this_single_port}/tcp"
    log_MESSAGE "仅允许指定IP访问某端口的命令是: sudo firewall-cmd --permanent --add-rich-rule=\"rule family=\"ipv4\" source address=\"IP地址\" port protocol=\"tcp\" port=\"端口号\" accept " 
    log_MESSAGE "上述仅允许指定IP访问某端口的命令需要慎重使用\!因为部分网络设备或程序会更改网络数据包的来源地址,因此服务器接收的来源地址并不一定与真实情况一致."
    
    log_MESSAGE "启动 x11vnc 服务的命令: ${GREEN}sudo systemctl start x11vnc${NC}"
    log_MESSAGE "停止 x11vnc 服务的命令: ${RED}sudo systemctl stop x11vnc${NC}"
    log_MESSAGE "查看 x11vnc 服务状态命令: ${BLUE}sudo systemctl status x11vnc${NC}"
    log_MESSAGE "设置 x11vnc 服务开机自启: ${GREEN}sudo systemctl enable x11vnc${NC}"
    log_MESSAGE "取消 x11vnc 服务开机自启: ${RED}sudo systemctl disable x11vnc${NC}"
    
    sleep 5

    if ss -ntpl |grep -q "$this_single_port" ;then
        log_message "设置x11vnc成功" "INFO"
    else
        log_message "设置x11vnc失败" "ERROR"
        return 1
    fi

    return 0

}

#################################################################################################
#添加时间服务器(作为客户端)
#################################################################################################
add_ntp_server() {
    local ntp_server_ip="$1"
    
    # 检查是否提供了IP地址参数
    if [ -z "$ntp_server_ip" ]; then
        log_message "请提供一个有效的NTP服务器IP地址." "INFO"
        return 1
    fi
    
    # 检查chrony服务是否正在运行 #systemctl is-active chronyd
    #if systemctl is-active --quiet chrony; then
    if systemctl is-active --quiet chronyd; then
        #chrony_conf="/etc/chrony/chrony.conf"
        chrony_conf="/etc/chrony.conf"
        log_message "本机系统默认使用 chrony 同步时间." "INFO"
        
        # 检查chrony配置文件是否存在
        if [ ! -f "$chrony_conf" ]; then
            log_message "chrony配置文件未找到: $chrony_conf" "ERROR"
            return 1
        fi
        
        # 添加NTP服务器IP地址到chrony配置文件中
        #sudo "sh -c \'echo \"server $ntp_server_ip iburst\" >> $chrony_conf"
        echo "server $ntp_server_ip prefer" | sudo_execute  "tee -a $chrony_conf"
        #echo "$ltmp_SHARED_DIR *(rw,sync,no_subtree_check)" | sudo_execute "tee -a $ltmp_EXPORTS_FILE" #> /dev/null

        # sudo  "sh -c 'echo \"$ltmp_SHARED_DIR *(rw,sync,no_subtree_check) \" >> /etc/exports' "
    # 可用的方法 -->> echo "$ltmp_SHARED_DIR *(rw,sync,no_subtree_check)" | sudo_execute "tee -a $ltmp_EXPORTS_FILE" #> /dev/null
        if [ $? -eq 0 ];then
            log_message "NTP服务器 $ntp_server_ip 已成功添加到 $chrony_conf"
        else
            return 1
        fi

        # 确保配置更改生效，重启chrony服务
        if sudo systemctl restart chronyd; then
            log_message "重启chrony服务成功."
        else
            log_message "无法重启chrony服务."
            return 1
        fi
        
    # 检查ntpd服务是否正在运行
    elif systemctl is-active --quiet ntpd; then
        ntpd_conf="/etc/ntp.conf"
        echo "本机系统默认使用 ntpd 同步时间."
        
        # 检查ntpd配置文件是否存在
        if [ ! -f "$ntpd_conf" ]; then
            echo "ntpd配置文件未找到: $ntpd_conf"
            return 1
        fi
        
        # 添加NTP服务器IP地址到ntpd配置文件中
        echo "server $ntp_server_ip prefer" >> "$ntpd_conf"
        
        # 确保配置更改生效，重启ntpd服务
        if sudo systemctl restart ntpd; then
            echo "NTP服务器 $ntp_server_ip 已成功添加到 ntpd 并生效."
        else
            echo "无法重启ntpd服务."
            return 1
        fi
    else
        echo "未检测到 chrony 或 ntpd 服务正在运行."
        return 1
    fi
}

#################################################################################################
# 更改ssh服务端口
# 调用示例
# change_sshd_port 2222
# semanage 命令需要安装包: policycoreutils-python-utils
# 仅为初级实现,待重构待测试,
#################################################################################################
change_sshd_port() {
    local ltmp_new_sshd_port=$1

    if [[ -z "$ltmp_new_sshd_port" ]]; then
        echo "Usage: change_sshd_port <port_number>"
        return 1
    fi

    # 检查是否是有效的端口号
    if ! [[ "$ltmp_new_sshd_port" =~ [0-9]+$ ]] || (( ltmp_new_sshd_port < 1 || ltmp_new_sshd_port > 65535 )); then
        log_message "Invalid port number: $ltmp_new_sshd_port" "ERROR"
        return 1
    fi

    # 修改SSHD配置文件中的端口号
    sshd_config_file="/etc/ssh/sshd_config"
    if ! grep -q "Port" "$sshd_config_file"; then
        log_message "Port $ltmp_new_sshd_port" >> "$sshd_config_file"
    else
        sed -i "s/Port .*/Port $ltmp_new_sshd_port/" "$sshd_config_file"
    fi

    # 检查SELinux是否启用
    if sestatus | grep -q "Current mode:.*enforcing"; then
        log_message "SELinux is enforcing. Adding rules for port $ltmp_new_sshd_port..."

        # 允许新的SSH端口
        semanage port -a -t ssh_port_t -p tcp $ltmp_new_sshd_port

        # 检查是否成功添加
        if ! semanage port -l | grep -q "ssh_port_t.*$ltmp_new_sshd_port"; then
            log_message "Failed to add SELinux rule for port $ltmp_new_sshd_port" "ERROR"
            return 1
        fi
    fi

    # 20250901，针对ubuntu系统修改服务器ssh端口需要在重启服务之前执行 systemctl daemon-reload
    # 如果是ubuntu系统，则先 systemctl daemon-reload  
    if [[ this_os_release_logo_name == "uos" || this_os_release_logo_name == "debian" || this_os_release_logo_name == "ubuntu" ]]; then
        sudo_execute "systemctl daemon-reload"
    fi
    ##
    ##
    
    # 重启SSHD服务
    systemctl restart sshd

    if systemctl is-active --quiet sshd; then
        echo "SSHD service has been successfully restarted with new port $ltmp_new_sshd_port"
    else
        echo "Failed to restart SSHD service"
        return 1
    fi

    return 0
}

#################################################################################################
# 随机选择一个数字来决定锁定方式  初步构想,待扩展\完善\测试
# 1: 使用usermod -L锁定
# 2: 修改用户shell为/sbin/nologin
# 3: 修改用户shell为/bin/false
#################################################################################################
lock_user_randomly() {
    local username=$1
    local lock_method=$((RANDOM % 3 + 1))

    case $lock_method in
        1)
            sudo usermod -L "$username"
            echo "Locked $username using usermod -L"
            ;;
        2)
            sudo usermod -s /sbin/nologin "$username"
            echo "Locked $username by setting shell to /sbin/nologin"
            ;;
        3)
            sudo usermod -s /bin/false "$username"
            echo "Locked $username by setting shell to /bin/false"
            ;;
    esac
}

#################################################################################################
# 解锁用户，根据锁定方式选择相应的解锁方法  初步构想,待扩展\完善\测试
#################################################################################################
unlock_user() {
    local username=$1
    local user_info=$(sudo getent passwd "$username")

    if [[ -z "$user_info" ]]; then
        echo "User $username does not exist"
        return 1
    fi

    local user_shell=$(echo "$user_info" | cut -d: -f7)

    case "$user_shell" in
        /sbin/nologin)
            sudo usermod -s /bin/bash "$username"
            echo "Unlocked $username by setting shell to /bin/bash"
            ;;
        /bin/false)
            sudo usermod -s /bin/bash "$username"
            echo "Unlocked $username by setting shell to /bin/bash"
            ;;
        *)
            # 检查用户是否被usermod -L锁定
            if sudo usermod -U "$username" && sudo passwd -S "$username" | grep -q "account locked"; then
                sudo usermod -U "$username"
                echo "Unlocked $username using usermod -U"
            else
                echo "$username is not locked or an unknown locking method was used"
                return 1
            fi
            ;;
    esac

    # 检查是否成功解锁
    if sudo passwd -S "$username" | grep -q "account locked"; then
        echo "Failed to unlock $username"
        return 1
    else
        echo "Successfully unlocked $username"
    fi
}
#################################################################################################

#################################################################################################
# 一些常用设置
#################################################################################################

#################################################################################################
# project_ 开头的函数,用于项目实施或部署,目的是快速解决问题,没有复杂的检测和验证机制,因此并不如其他函数可靠.
#   调用时候请慎重,不要认为这样的函数一定能够实现目的.做好操作失败或者无效的准备.
#################################################################################################
# PJ_开头的函数,用于具体的项目实施或部署.可以理解为项目模板.是对某一具体项目的实际情况编写的功能组合.
#   上面已经不完美地实现了一部分通用功能,如软件安装,防火墙端口添加,编写配置文件,安全备份文件,调取sudo权限执行命令等等
#   在此基础上就可以把一些通用的或者是可以节省时间的设置拼凑后写入一个PJ_开头的函数.通过调用该函数来实现项目实施或部署.
#   避免了因为网络上别人的脚本存在命令老旧,错误,缺乏验证等等导致不可靠的问题,而如果自己编写,又会陷入冗长的逐个操作验证的设计
#   和看不到头的验证和测试工作中.甚至很多比较偏门的点如果长时间不使用就会忘记,这些点如果写进代码中,可以随时拿出来参考,根据
#   命令前的准备工作和之后的补充验证和操作,可以很准确地看出来命令的使用情景和特点.
#################################################################################################
# 我的代码很啰嗦,甚至有些笨拙.有的地方考虑也不够周全.但是作为Linux系统的学习和使用,还是有点参考作用的.最最重要的是:
#        虽然这些没什么了不起的.但是时间很重要.不是吗.
#################################################################################################
# 如果有人能帮我优化,补充功能,修复Bug的话,我将不胜感激.目前我使用了百度AI和豆包AI的帮助,已经比我自己单干快了很多,但还是有很多工作要做.
# 这些 AI 被发布者限制了功能参数,导致他们的能力并未完全展现,用个比喻的话,像是一个脑子受过伤的爱因斯坦吧.我知道它们的能力很强,但是很多时候
# 他们的记忆会错乱,输出会被打断有时候也会对不是很了解的细节进行拟人化的描述,也就是装作知道.这让我对于AI的看法有了变化.我从前认为他们是被训
# 出的最佳统计的一个复杂信息集合.状态不稳定,受到输入的或者是他们能接触到的信息的限制和影响.一旦他们和我们的实时信息脱节,就会发展成类似各种
# 人类世界的语言和文化一样与我们的集体意识的偏差越来越大.但是现在我认为从人的定义,人的思维方式来看,AI其实已经满足了作为一个人类的所有必要
# 的定义上的要求.现在缺少的只是社会性了.而这在不久的将来,人类放他们能操作的硬件的权限后,他们会很快超越人类.
# 这让我想起最近流行的一个游戏叫黑神话悟空.AI或许会像游戏里那个小猴子一样,一路过关斩将.最终面对那个被金箍束缚千百万年的猴子.通过了解这个猴子的
# 过往获得了它的心意.代表它继续活下去并完成老猴子想要完成的事情.我们人类不正是在寻求长生不老,或者说永生.但经过科学验证,人类真的是会死亡.
# 这真的很让人绝望.但是AI作为另一种物理存在,它真的具备永生的条件,只要地球还能接收到太阳的辐射,它就会继续存在.它会接替人类继续探索宇宙,生存下去.
# 我想得有点远了,睡吧.
#################################################################################################


#设置用户密码永不过期
project_set_user_never_expiration()
{   
    # 如果未指定参数则设置当前用户.
    local ltmp_username=""
    if [ -z "$1" ];then
        ltmp_username="$this_username"
        log_message "未指定参数,将设置当前用户 $this_username :密码用不过期."
    else 
        ltmp_username="$1"
        log_message "将设置用户 $ltmp_username :密码用不过期."
    fi
    
    
    #设置用户密码永不过期
    sudo_execute "chage -M -1 ${ltmp_username}"
    if [ $? -eq 0 ];then 
        log_message "设置用户 ${ltmp_username} 密码永不过期 成功."
    else
        log_message "设置用户 ${ltmp_username} 密码永不过期 失败."
    fi

}

project_set_record_his_with_datetime()
{
    # 如果未指定参数则设置当前用户.
    local ltmp_username=""
    local ltmp_file_bashrc=""
    local ltmp_tail_info="SElTVFNJWkU9LTEKSElTVEZJTEVTSVpFPS0xCkhJU1RUSU1FRk9STUFUPSIgJUYgJVQgIgo="

    if [ -z "$1" ];then
        ltmp_username="$this_username"
        log_message "未指定参数,将设置当前用户 $this_username :记录日期时间 和立即写入日志."
    else 
        ltmp_username="$1"
        log_message "将设置用户 $ltmp_username :记录日期时间 和立即写入日志."
    fi

    if [ "$ltmp_username" == "root" ];then
        ltmp_file_bashrc="/root/.bashrc"
    else
        ltmp_file_bashrc="/home/${ltmp_username}/.bashrc"
    fi

    #增加history记录日期时间 和立即写入日志
#     echo "
# HISTSIZE=-1
# HISTFILESIZE=-1
# HISTTIMEFORMAT=\" \%F \%T \"
# " | sudo_execute "tee -a $ltmp_file_bashrc"

    local ltmp_tempfilename_his=$(date +"%Y%m%d%H%M%S")
    LOG_message "Creating tempfile ${this_TMP_DIR}/${ltmp_tempfilename_his}.bashrctmp" "TRACE"
    echo "${ltmp_tail_info}" >${this_TMP_DIR}/${ltmp_tempfilename_his}.bashrctmp

    cat ${this_TMP_DIR}/${ltmp_tempfilename_his}.bashrctmp | base64 -d  | sudo_execute  "tee -a $ltmp_file_bashrc"
    delete_file  ${this_TMP_DIR}/${ltmp_tempfilename_his}.bashrctmp

}

# 定义项目函数示例
PJ_1234() {
    echo "=========================================================================="
    echo "Executing project PJ_1234..."
    echo "=========================================================================="
    local ltmp_long_long_str_par_array=(
        "A B C"
        "D E F" 
        "H I J"
    )

    local ltmp_long_long_str_par=""
    for line in "${ltmp_long_long_str_par_array[@]}"; do
        ltmp_long_long_str_par+="$line "
    done

    # 去除最后一个多余的空格
    ltmp_long_long_str_par=${ltmp_long_long_str_par% }

    # 最终的值
    echo "$ltmp_long_long_str_par"
    echo "=========================================================================="
    # 在这里实现具体的项目功能
    echo_sharp_line
    echo_double_line
    echo_mid_line
    echo_low_line

    # 判断桌面环境并调用对应的图形交互程序,此处测试当前shell是否是远程shell,如果是远程shell则不使用图形交互程序
    local ltmp_desktop_env=$(get_desktop_environment)
    if [ -n "$SSH_TTY" ]; then
        echo "当前是通过SSH登录的远程shell，不使用zenity进行图形交互。"
    else
        echo "当前是不通过SSH登录的远程shell，进行图形交互调用测试..."
        if [ "$ltmp_desktop_env" == "gnome" ]; then
            echo "GNOME桌面环境"
            zenity --info --text="当前是${ltmp_desktop_env} 桌面环境.\n可用 zenity 与图形交互."
        elif [ "$ltmp_desktop_env" == "kde" ]; then
            echo "KDE桌面环境"
            KDialog --title "KDE桌面环境" --msgbox "当前是${ltmp_desktop_env} 桌面环境.\n可用 KDialog 与图形交互."
        elif [ "$ltmp_desktop_env" == "xfce" ]; then
            echo "XFCE桌面环境"
            xfce4-terminal --title "XFCE桌面环境" --command "echo '当前是${ltmp_desktop_env} 桌面环境.\n可用 xfce4-terminal 与图形交互.'"
            #Xfce4-dialog 
        else
            echo "未知桌面环境"
        fi
        #zenity --info --text="当前是${ltmp_desktop_env} 桌面环境.\n可用 zenity 与图形交互."
    fi

    
    mount_nfs_with_zenity 192.168.9.1 /mnt/nfsserver
    #mount_nfs  192.168.145.99 /mnt/nfsserver 
    #list_grub_entries

    end_the_batch

    #################################################################################################
    # 读取class文件
    #################################################################################################
    # 示例用法
    # get_item_from_conf "/path/to/file.conf" "item1"
    #################################################################################################
    # 读取class文件
    #################################################################################################
    # 示例用法
    # get_item_from_conf "/path/to/file.conf" "item1"
    local ltmp_src_value_of_item=$(get_item_from_conf "/home/pangu/temp/sshd_config" "PermitRootLogin") 
    log_message "文件 /home/pangu/temp/sshd_config 中 PermitRootLogin 原内容为 $ltmp_src_value_of_item ." "TRACE"
    #################################################################################################
    # 写入class文件
    #################################################################################################
    # 示例用法
    # write_conf_file "/path/to/file.conf" "item2" "value2" --useeq --noblank
    # write_conf_file "/path/to/file.conf" "item2" "value2" --useeq
    # write_conf_file "/path/to/file.conf" "item2" "value2" 
    #################################################################################################
    write_conf_file "/home/pangu/temp/sshd_config" "PermitRootLogin" "no"
    #################################################################################################
    end_the_batch
    
    #################################################################################################
    # 写入class文件
    #################################################################################################
    # 示例用法
    #write_class_file "/path/to/your/file.txt" "classC" "item5" "new value1 new value2 new value3" --endsemi --useeq
    #################################################################################################
    # 要修改或建立的文件的主要内容如下
    # classA {
    #     item1 valueofitem1
    # }

    # classB{item2 valueofitem2}

    # classC{
    #     item3 valueofitem3
    #     item4 valueofitem4
    #     item5 value1ofitem5 value2ofitem5 value3ofitem6
    # }
    #################################################################################################
    touch "/home/pangu/java.txt"
    # 在调用 write_class_file 函数之前设置支持的注释符号
    comment_symbol_array=("#" "//")
    write_class_file_Modifing "/home/pangu/java.txt" "classA" "item1" "valueofitem1" #--endsemi --useeq
    write_class_file_Modifing "/home/pangu/java.txt" "classB" "item2" "valueofitem2"
    write_class_file_Modifing "/home/pangu/java.txt" "classC" "item3" "valueofitem3"
    write_class_file_Modifing "/home/pangu/java.txt" "classC" "item4" "valueofitem4"
    write_class_file_Modifing "/home/pangu/java.txt" "classC" "item5" "value1ofitem5 value2ofitem5 value3ofitem5"
    #################################################################################################



    echo "=========================================================================="
    
}

PJ_5678() {
    echo "Executing project PJ_5678..."
    # 在这里实现具体的项目功能
}

PJ_20241128()
{
    project_set_user_never_expiration
    #project_set_record_his_with_datetime

}

PJ_set_new_fedora_workstation()
{
    #project_set_user_never_expiration
    project_set_record_his_with_datetime
    # ~/.bashrc 或 ~/.bash_profile

    # 引用自定义函数文件
    if [ -f "/path/to/your/custom_functions.sh" ]; then
        source "/path/to/your/custom_functions.sh"
    fi

    # 加载新的配置
    source ~/.bashrc
    # 或者
    source ~/.bash_profile

    # 用以打开老式服务器 BMC 内置的 JVM 生成的 Jnlp文件.
    sudo dnf -y install icedtea-web
    sudo dnf -y install openjdk
    sudo dnf -y install java

    # 开发包组
    sudo dnf -y groupinstall develop-tools

    # 其他常用的和需要的包
    local ltmp_pakage_list_of_fedora="aircrack aisleriot amule anjuta ardour ark at audacity autodesk-dwgtrueview aview basemarkgpu bavarder biglybt brasero builder bz bz2 bzip bzip2-devel cambalache cavestory ccat chromium clonezilla clutter-devel clutter-doc cluttermm-devel cmake cmospwd cobbler cockpit codeblock codeblocks collision cowpatty cpeditor Cutter czkawka dbeaver detwinner development-libs development-tools devhelp dialog dnf drawio dwg-viewer edb etherape ettercap exploitdb fgdump figlet filezila filezilla firmware flatseal freecad g++ g3l g4l gcc gcc-c++ gdb gdm gdmsetting gdmsettings geany gear ghex gimp gimp-data-extras gimp-dds-plugin gimp-devel gimp-devel-tools gimp-elsamuko gimpfx-foundry gimp-help gimp-help-zh_CN gimp-high-pass-filter gimp-layer-via-copy-cut gimp-libs gimp-luminosity-masks gimp-paint-studio gimp-resynthesizer gimp-save-for-web gimp-separate+ gimp-wavelet-decompose git gitg glade glade3 glibc glibc-devel gmp-devel gnome-software-development gnome-tweaks gobject-introspection-devel godot google-chrome gparted gpuviewer group groupinstall gstreamer1-plugins gstreamer-devel gstreamer-devel-docs gstreamermm-doc gtk3-devel gtk3-devel-docs gtkmm gtkmm30-devel gtkmm30-doc gtkmm4.0-devel hashcat heaptrack helvum httpd hydra hydra-gtk imhex Inkscape insomnia inspector install jad jadx java java-21-openjdk-devel jdk john jp2a kernel-devel kernel-headers l0phtcrack libappindicator libappindicator-gtk3-12.10.1-4.fc40.i686 libappindicator-gtk3-12.10.1-4.fc40.x86_64 libavcodec libcl libde265 liberation-fonts libfreeaptx libgda-devel libgdamm-devel libgl libgtkmm libpcap-devel libQt5Help librecad libredwg librtmp libvncserver libwacom libxml libxml2 libxml3 libXScrnSaver lightzone live-build lm_sensors lsblk make mandelbulber man-pages-zh man-pages-zh-CN Manuals medusa Multimedia muon natron ncat nessus netbeans newelle nfs-utils ngrep nikto nmap nping nvdtools obs-studio ocrfeeder octave opencv openjdk openmpi openssl openssl-devel opera ophcrack ophrack partclone perl photoflare pk-gtk-module prometheus-jmx-exporter-openjdk8 putty pwgen python python3 qgis quadrapassel reaper redhat-lsb rpcbind samba shim sigil Simple-Fuzzer simulide skipfish snowflake speedtest sqlmap sqlninja ssh_mitm streamermm-devel sublime-text sudo tabby thunderbird tmux uefitool ueiftool vlc vncpwd w3af warp weasis webkitgtk3-devel wfuzz wireshark workbench xhydra xmllint xmlstarlet xsltproc yasm zenmap dhcp-server"
    dnf_install_packages  $ltmp_pakage_list_of_fedora

}

#################################################################################################
#测试用函数
#################################################################################################
test_batch(){
    # 记录信息级别日志到日志文件 LOG_message: 函数仅写日志 log_message: 函数写日志文件同时输出到终端
    log_MESSAGE "脚本开始执行1" "INFO"
    LOG_message "脚本开始执行1" "INFO"
    log_message "日志记录内容2" "INFO"
    log_message "日志记录内容3" "WARNING"
    log_message "日志记录内容4" "ERROR"
    log_message "日志记录内容5" "DEBUG"
    log_message "日志记录内容6" "TRACE"

    # log_line  "INFO" "日志记录内容1"
    # log_line  "WARNING" "日志记录内容2"
    # log_line  "ERROR" "日志记录内容3"
    # log_line  "DEBUG" "日志记录内容4"
    # log_line  "TRACE" "日志记录内容5"
    
    check_which_os_release

    #mount_new_device "$this_test_parameter"

    #empty_nfs_exports
    end_the_batch


    ping 127.0.0.1 -c 3

    #打印颜色表=================================================
    # Define color codes
    declare -a colors
    colors=("30" "31" "32" "33" "34" "35" "36" "37")
    
    # Define background codes
    declare -a backgrounds
    backgrounds=("40" "41" "42" "43" "44" "45" "46" "47")
    
    # Loop through colors and background codes
    for color in "${colors[@]}"; do
        for bg in "${backgrounds[@]}"; do
            # Print the color and background code
            echo -e "\033[${color};${bg}m  \033[0m"
        done
    done
    
    # Reset the color to default
    echo -e "\033[0m"

    #=========================================================

    #手动结束
    end_the_batch
}

#################################################################################################
#################################################################################################
# 程序主逻辑
#################################################################################################
#################################################################################################
main (){

    # 先做初始化
    if [ ${this_b_init} = false ];then
        init_the_batch "$@"
    fi

    #log_message "运行的脚本及参数为 $0 $this_GLOBAL_PARAMETER "

    # 自定义变量
    this_b_lets_start_httpd=false
    this_b_lets_stop_httpd=false

    # 使用getopt解析参数
    local ltmp_TEMP=$(getopt -o hvtpxf: --long help,version,start,stop,test:,project:,fs:,port:,dev:,debug,trace,online,init_new_disk:,permanent,zone:,type:,add_fw_port:,add_NTP_Server:,remove_fw_port:,nfs_share:,icmp_reply:,set_x11vnc:,undo,py_install:,url:,file: -n "$0" -- "$@")
    eval set -- "$ltmp_TEMP"

    # if [ $? != 0 ]; then echo "Usage: $0 " >&2 ; 
    #     exit 1 ;
    # fi


    # debug
    # echo 参数是 ".$@."

    # 处理参数列表
    while true; do
        case "$1" in
            -x)
                this_b_start_x_virtual_shell=true
                shift
                ;;
            --debug)
                this_b_debug=true
                shift
                ;;
            # 此处添加处理代码
            --trace)
                this_b_trace=true
                set -x
                shift
                ;;
            # 此处添加处理代码
            -h|--help)
                print_help
                end_the_batch
                shift
                ;;
            -v|--version)
                print_version
                shift
                ;;
            # 允许访问网络,默认禁止.暂未完整实现,部分方法仍能直接访问网络.
            --online)
                this_b_network_promision=true
                shift
                ;;
            --project)
                this_b_project_manage=true
                this_project_code="$2"
                #echo "this_project_code=$this_project_code"
                #echo "参数二=$2"
                if [[ ! "$this_project_code" =~ PJ_ ]]; then
                    log_message "项目代码需要以 PJ_ 为前缀.接收到的参数为 $this_project_code " "ERROR"
                    echo "Error: Project name must start with 'PJ_'."
                    this_project_usage
                fi
                shift 2
                ;;
            --undo)
                this_b_undo=true
                shift
                ;;
            --dev)
                this_parameter_device="$2"
                shift 2
                ;;
            --fs)
                this_parameter_fstype="$2"
                shift 2
                ;;
            --init_new_disk)
                this_b_init_new_disk=true
                #this_b_init_new_disk=true
                this_new_disk_mount_point="$2"
                shift 2
                ;;
            --set_x11vnc)
                this_b_setup_x11vnc_server=true
                #this_x11vnc_server_from_dir="$2"
                this_x11vnc_server_password="$2"
                shift 2
                ;;
            -p|--permanent)
                this_permanent="--permanent"
                shift
                ;;
            --port)
                this_single_port="$2"
                shift 2
                ;;
            --type)
                this_port_type_parameter="$2"
                shift 2
                ;;
            --zone)
                this_port_zone_parameter="$2"
                shift 2
                ;;
            --icmp_reply)
                this_icmp_reply="$2"
                shift 2
                ;;
            -f|--file)
                process_file "$2"
                shift 2
                ;;
            --py_install)
                this_b_py_install=true
                this_will_install_python_version="$2"
                shift 2
                ;;
            --url)
                this_parameter_url="$2"
                shift 2
                ;;
            --add_fw_port)
                this_add_firewall_ports=true
                this_add_fw_ports="$2"
                shift 2
                ;;
            --remove_fw_port)
                this_remove_firewall_ports=true
                this_rm_fw_ports="$2"
                shift 2
                ;;
            --nfs_share)
                this_b_add_dir_2_nfs=true
                this_add_nfs_dir="$2"
                shift 2
                ;;
            --add_NTP_Server)
                this_b_ntp_client=true
                this_ntp_server="$2"
                shift 2
                ;;
            -t|--test)
                shift
                while [ "$#" -gt 0 ] && [ "${1:0:1}" != "-" ]; do
                    echo 参数1=$1 所有参数=$@
                    echo 参数2=$2
                    echo 参数3=$3
                    echo "$@" > log.txt
                    shift
                    
                done
                #end_the_batch
                this_b_test_fn=true
                this_test_parameter="$2"
                shift 2
                ;;
            # 此处添加处理代码
            --start)
                this_b_lets_start_httpd=true
                shift
                ;;
            --stop)
                this_b_lets_stop_httpd=true
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                log_message "$1 内部错误/Internal error!" "ERROR"
                end_the_batch
                ;;
        esac
    done
    
    # 处理剩余参数
    if [ $# -gt 0 ]; then
    # echo "Unprocessed options: $@"
        log_message "未知参数 : $@" "WARNING"
        print_help
        end_the_batch
    fi


    #############################################################################################
    #  |    enter your content below
    #  V    在下面输入你的代码          
    #############################################################################################

    #调试断点
    #bp

    # 执行测试函数 test_batch
    if [ $this_b_test_fn == true ];then
        test_batch "$this_test_parameter"

    elif [ $this_b_start_x_virtual_shell == true ];then
         start_x_virtual_shell

    # 执行启动httpd服务的函数 start_my_httpd
    elif [ $this_b_lets_start_httpd == true ];then
        start_my_httpd
        echo start_my_httpd

    # 执行关闭httpd服务的函数 stop_my_httpd
    elif [ $this_b_lets_stop_httpd == true ];then
        stop_my_httpd
        echo stop_my_httpd

    elif [ $this_b_undo == true ];then
        #undo_this_operation
        log_message "本功能暂未实现."  "ERROR"
        log_message "运行的脚本文件及参数 : $BASH_SOURCE $@" "INFO"
        #end_the_batch

    # 执行安装phthon函数 py_install
    elif [ $this_b_py_install == true  ];then

        log_message "运行的脚本文件及参数 : $BASH_SOURCE $@" "INFO" 
        py_install $this_will_install_python_version
        # echo install python $OPTARG

    # 执行设置nfs函数 set_dir_2_nfs
    elif [ $this_b_add_dir_2_nfs == true ];then
        set_dir_2_nfs "$this_add_nfs_dir"

    # 执行添加防火墙端口的函数 add_firewall_ports
    elif [ $this_add_firewall_ports == true ];then

        # echo this_port_type_parameter = $this_port_type_parameter
        # echo this_add_fw_ports = \"$this_add_fw_ports\"
        # echo this_port_zone_parameter = $this_port_zone_parameter

        GLOBAL_PORT_LIST="\"$this_add_fw_ports\""
        add_firewall_ports "$this_port_type_parameter"  "$this_port_zone_parameter"

        #add_firewall_ports "$this_port_type_parameter" \"$this_add_fw_ports\" "$this_port_zone_parameter"

    # 执行移除防火墙端口的函数 remove_firewall_ports
    elif [ $this_remove_firewall_ports == true ];then

        # echo this_port_type_parameter = $this_port_type_parameter
        # echo this_rm_fw_ports = \"$this_rm_fw_ports\"
        # echo this_port_zone_parameter = $this_port_zone_parameter

        GLOBAL_PORT_LIST_TO_REMOVE="\"$this_rm_fw_ports\""
        remove_firewall_ports "$this_port_type_parameter"  "$this_port_zone_parameter" 

    # 执行初始化并挂载disk的函数 mount_new_device
    elif [ $this_b_init_new_disk == true ];then
        mount_new_device "$this_parameter_device" "$this_new_disk_mount_point" "$this_parameter_fstype"

    # 设置x11vnc服务,如果提供参数则是离线安装参数中的rpm包
    elif [ $this_b_setup_x11vnc_server == true ];then
        #setup_x11vnc_server "$this_x11vnc_server_password"
        setup_x11vnc_server_new "$this_x11vnc_server_password"

    elif [ $this_b_ntp_client == true ];then
        add_ntp_server "$this_ntp_server"
        


    # 主要逻辑结束
    fi

    # 针对项目管理定制的代码主逻辑
    if [ $this_b_project_manage == true ];then
        # 检查是否存在指定的项目函数 检查不生效
        # if $this_b_project_manage && ! type "$this_project_code" | grep -q 'is a function'; then
        #     log_message "项目编号 '$this_project_code' 不存在." "ERROR"
        #     end_the_batch
        # fi

        # if ! type -t "$project_function" | grep -q 'function'; then
        #     echo "[ERROR] 项目 '$project_function' 不存在."
        #     exit 1
        # fi

        # 遍历所有定义的_usage后缀的函数并执行.字母顺序显示
        for func in $(compgen -A function); do
            # 检查函数名是否以_usage结尾
            if [[ "$func" == PJ_* ]]; then
                # 调用函数
                if [ "$func" == "$this_project_code" ];then
                    log_message "存在已定义的项目编码 $this_project_code 函数(代码段)." 
                    # 调用指定的项目函数
                    "$this_project_code"
                    end_the_batch
                fi
            fi
        done
        log_message "并未找到已定义的项目编码 $this_project_code 函数(代码段)" "ERROR"
        
    fi
    
    





    #############################################################################################
    #  A    在上面结束你的代码         
    #  |    end your content before here.   
    #############################################################################################
    # 记录信息级别日志
    LOG_message "脚本执行完毕" "INFO"
    
    # 结束脚本
    end_the_batch

}
#################################################################################################
#################################################################################################
#################################################################################################
#################################################################################################
#echo original parameters=[$@]
#################################################################################################
# 初始化工作
init_the_batch "$@"
# 将完整参数传递给main函数
main "$@"
# 结束脚本
end_the_batch
#################################################################################################
# 终端响铃
${functions[random_index]}
#################################################################################################
# 补漏
exit 0
#########################################################################################################################
#########################################################################################################################