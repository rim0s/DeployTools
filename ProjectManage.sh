#!/bin/bash
############################################################
# ProjectManage - 模块化的Linux项目管理系统
# 这是一个重构后的模块化版本，便于维护和扩展
############################################################

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# 检查Bash解释器
if [ -z "$BASH_VERSION" ]; then
    echo "此脚本需要使用 Bash 解释器运行。"
    echo "正在尝试使用 Bash 重新启动脚本..."
    exec bash "$0" "$@"
    exit 1
fi

# 加载模块加载器（会自动加载所有模块）
source "${LIB_DIR}/loader.sh" || {
    echo "错误: 无法加载模块加载器" >&2
    exit 1
}

#################################################################################################
# 程序主逻辑
#################################################################################################
main (){
    # 先做初始化
    if [ ${this_b_init} = false ];then
        init_the_batch "$@"
    fi

    # 自定义变量
    this_b_lets_start_httpd=false
    this_b_lets_stop_httpd=false

    # 使用getopt解析参数
    local ltmp_TEMP=$(getopt -o hvtpxf: --long help,version,start,stop,test:,project:,fs:,port:,dev:,debug,trace,online,init_new_disk:,permanent,zone:,type:,add_fw_port:,add_NTP_Server:,remove_fw_port:,nfs_share:,icmp_reply:,set_x11vnc:,undo,py_install:,url:,file: -n "$0" -- "$@")
    eval set -- "$ltmp_TEMP"

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
            --trace)
                this_b_trace=true
                set -x
                shift
                ;;
            -h|--help)
                print_help
                end_the_batch
                shift
                ;;
            -v|--version)
                print_version
                shift
                ;;
            --online)
                this_b_network_promision=true
                shift
                ;;
            --project)
                this_b_project_manage=true
                this_project_code="$2"
                if [[ ! "$this_project_code" =~ PJ_ ]]; then
                    log_message "项目代码需要以 PJ_ 为前缀.接收到的参数为 $this_project_code " "ERROR"
                    echo "Error: Project name must start with 'PJ_'."
                    project_PJ_usage
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
                this_new_disk_mount_point="$2"
                shift 2
                ;;
            --set_x11vnc)
                this_b_setup_x11vnc_server=true
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
                if declare -f process_file > /dev/null; then
                    process_file "$2"
                else
                    log_message "process_file 函数未定义" "ERROR"
                fi
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
                this_b_test_fn=true
                this_test_parameter="$2"
                shift 2
                ;;
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
        log_message "未知参数 : $@" "WARNING"
        print_help
        end_the_batch
    fi

    #############################################################################################
    #  |    enter your content below
    #  V    在下面输入你的代码          
    #############################################################################################

    # 执行测试函数 test_batch
    if [ $this_b_test_fn == true ];then
        if declare -f test_batch > /dev/null; then
            test_batch "$this_test_parameter"
        else
            log_message "test_batch 函数未定义" "ERROR"
        fi

    elif [ $this_b_start_x_virtual_shell == true ];then
        if declare -f start_x_virtual_shell > /dev/null; then
            start_x_virtual_shell
        else
            log_message "start_x_virtual_shell 函数未定义" "ERROR"
        fi

    # 执行启动httpd服务的函数 start_my_httpd
    elif [ $this_b_lets_start_httpd == true ];then
        if declare -f start_my_httpd > /dev/null; then
            start_my_httpd
        else
            log_message "start_my_httpd 函数未定义" "ERROR"
        fi

    # 执行关闭httpd服务的函数 stop_my_httpd
    elif [ $this_b_lets_stop_httpd == true ];then
        if declare -f stop_my_httpd > /dev/null; then
            stop_my_httpd
        else
            log_message "stop_my_httpd 函数未定义" "ERROR"
        fi

    elif [ $this_b_undo == true ];then
        log_message "本功能暂未实现."  "ERROR"
        log_message "运行的脚本文件及参数 : $BASH_SOURCE $@" "INFO"

    # 执行安装phthon函数 py_install
    elif [ $this_b_py_install == true  ];then
        log_message "运行的脚本文件及参数 : $BASH_SOURCE $@" "INFO" 
        if declare -f py_install > /dev/null; then
            py_install $this_will_install_python_version
        else
            log_message "py_install 函数未定义" "ERROR"
        fi

    # 执行设置nfs函数 set_dir_2_nfs
    elif [ $this_b_add_dir_2_nfs == true ];then
        if declare -f set_dir_2_nfs > /dev/null; then
            set_dir_2_nfs "$this_add_nfs_dir"
        else
            log_message "set_dir_2_nfs 函数未定义" "ERROR"
        fi

    # 执行添加防火墙端口的函数 add_firewall_ports
    elif [ $this_add_firewall_ports == true ];then
        GLOBAL_PORT_LIST="\"$this_add_fw_ports\""
        if declare -f add_firewall_ports > /dev/null; then
            add_firewall_ports "$this_port_type_parameter"  "$this_port_zone_parameter"
        else
            log_message "add_firewall_ports 函数未定义" "ERROR"
        fi

    # 执行移除防火墙端口的函数 remove_firewall_ports
    elif [ $this_remove_firewall_ports == true ];then
        GLOBAL_PORT_LIST_TO_REMOVE="\"$this_rm_fw_ports\""
        if declare -f remove_firewall_ports > /dev/null; then
            remove_firewall_ports "$this_port_type_parameter"  "$this_port_zone_parameter" 
        else
            log_message "remove_firewall_ports 函数未定义" "ERROR"
        fi

    # 执行初始化并挂载disk的函数 mount_new_device
    elif [ $this_b_init_new_disk == true ];then
        if declare -f mount_new_device > /dev/null; then
            mount_new_device "$this_parameter_device" "$this_new_disk_mount_point" "$this_parameter_fstype"
        else
            log_message "mount_new_device 函数未定义" "ERROR"
        fi

    # 设置x11vnc服务,如果提供参数则是离线安装参数中的rpm包
    elif [ $this_b_setup_x11vnc_server == true ];then
        if declare -f setup_x11vnc_server_new > /dev/null; then
            setup_x11vnc_server_new "$this_x11vnc_server_password"
        elif declare -f setup_x11vnc_server > /dev/null; then
            setup_x11vnc_server "$this_x11vnc_server_password"
        else
            log_message "setup_x11vnc_server 函数未定义" "ERROR"
        fi

    elif [ $this_b_ntp_client == true ];then
        if declare -f add_ntp_server > /dev/null; then
            add_ntp_server "$this_ntp_server"
        else
            log_message "add_ntp_server 函数未定义" "ERROR"
        fi

    # 主要逻辑结束
    fi

    # 针对项目管理定制的代码主逻辑
    if [ $this_b_project_manage == true ];then
        # 遍历所有定义的PJ_开头的函数并执行
        for func in $(compgen -A function); do
            # 检查函数名是否以PJ_开头
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

