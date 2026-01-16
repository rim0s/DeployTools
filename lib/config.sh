#!/bin/bash
#################################################################################################
# 全局变量配置模块
# 全局变量用 this_ 前缀
# 局部变量用 ltmp_ 前缀,local 声明.
#################################################################################################

# 脚本基础信息
this_bash_start_timestamp=$(date +%Y%m%d-%H%M%S)
this_start_bash_time=$(date +%s)
this_script_name=$(basename "$0")
this_username=$USER
this_arch=$(arch)
this_version="48.0"

# 路径配置
this_BACKUP_DIR=~/.BACKUP/${this_script_name}_bak
this_LOG_DIR=~/.LOG/${this_script_name}_LOG
this_LOG_FILE=${this_LOG_DIR}/${this_script_name}_${this_bash_start_timestamp}.log
this_TMP_DIR=${this_LOG_DIR}/${this_script_name}_${this_bash_start_timestamp}_TEMP
this_ACCOUNT_FILE="${this_BACKUP_DIR}/account.log"

# 功能开关
this_b_debug=false
this_b_end_debug=false
this_b_trace=false
this_b_test_fn=false
this_b_undo=false
this_b_init=false
this_b_banner_shown=false
this_b_start_x_virtual_shell=false
this_b_project_manage=false
this_b_network_promision=false
this_b_base64support=false
this_show_start_end_timestamp=true

# 操作系统信息
this_os_release_logo_name=""
this_os_release_type=""

# 项目管理
this_project_code=""
this_GLOBAL_PARAMETER="$@"
this_test_parameter=""

# 系统信息
this_host_ip_list=""
app_manager=null
this_installed_packages=""
this_not_installed_packages=""

# 防火墙相关
this_permanent=""
this_single_port=""
this_add_firewall_ports=false
this_add_fw_ports=""
this_port_type_parameter=tcp
this_port_zone_parameter=""
this_remove_firewall_ports=false
this_rm_fw_ports=""
this_icmp_reply=""
GLOBAL_PORT_LIST=""
GLOBAL_PORT_LIST_TO_REMOVE=""

# 服务配置
this_b_setup_x11vnc_server=false
this_x11vnc_server_from_dir=""
this_x11vnc_server_password=""
this_b_py_install=false
this_will_install_python_version=3.9.0
this_b_install_nfs=false
this_b_add_dir_2_nfs=false
this_add_nfs_dir=""
this_b_unset_dir_2_nfs=false
this_b_lets_start_httpd=false
this_b_lets_stop_httpd=false

# 磁盘和文件系统
this_b_init_new_disk=false
this_new_disk_mount_point=""
this_parameter_device=""
this_parameter_fstype=""
this_parameter_url="NULL"

# NTP相关
this_ntp_server=""
this_b_ntp_client=false
this_b_ntp_server=false

# 备份相关
this_backup_IDENTIFIER=""

# sudo执行输出
SUDO_EXECUTE__OUTPUT=""

# 终端响铃函数数组
functions=("fn_run_bel1" "fn_run_bel2" "fn_run_bel3")
random_index=$((RANDOM % 3))

# 初始化目录
mkdir -p "$this_BACKUP_DIR"
