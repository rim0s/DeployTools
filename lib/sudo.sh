#!/bin/bash
#################################################################################################
# sudo执行模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"

#################################################################################################
# 使用sudo权限执行命令的函数(GUI版)
#################################################################################################
sudo_execute_gui() {
    local ltmp_command=$1
    local sudo_execute_gui_RET=0
    
    show_who_call
    
    # 检查是否有GUI环境
    if [ -z "$DISPLAY" ]; then
        log_message "无GUI环境，使用普通sudo执行" "WARNING"
        sudo_execute "$ltmp_command"
        return $?
    fi
    
    # 创建临时脚本用于zenity密码输入 (使用base64编码的完整脚本)
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
cF9zdWRvX3Bhc3N3b3JkX3RwIgpmaQoKCg=="
    
    # 检查文件是否存在，如果存在则比较内容，避免重复创建
    if [ ! -f "${this_TMP_DIR}/tmp_sudo_pass_input.sh" ]; then
        echo "${ltmp_sudo_pass_input_method}" | base64 -d > ${this_TMP_DIR}/tmp_sudo_pass_input.sh
        chmod +x ${this_TMP_DIR}/tmp_sudo_pass_input.sh
    else
        # 比较文件内容，如果不同则更新
        diff <(echo "${ltmp_sudo_pass_input_method}" | base64 -d) ${this_TMP_DIR}/tmp_sudo_pass_input.sh >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "${ltmp_sudo_pass_input_method}" | base64 -d > ${this_TMP_DIR}/tmp_sudo_pass_input.sh
            chmod +x ${this_TMP_DIR}/tmp_sudo_pass_input.sh
        fi
    fi
    export SUDO_ASKPASS="${this_TMP_DIR}/tmp_sudo_pass_input.sh"
    
    LOG_message "执行命令: sudo $ltmp_command | tee -a \"$this_LOG_FILE\" " "WARNING"
    LOG_message "sudo $ltmp_command 命令输出 : \n\r" "WARNING"
    sudo -A ${ltmp_command} | tee -a "$this_LOG_FILE"
    
    sudo_execute_gui_RET=("${PIPESTATUS[@]}")
    
    if [ ${sudo_execute_gui_RET} -eq 0 ]; then
        LOG_message "sudo $ltmp_command 命令执行成功.返回码: ${sudo_execute_gui_RET}" "INFO"    
        log_MESSAGE "sudo $ltmp_command ${GREEN}命令执行成功.返回码: ${sudo_execute_gui_RET}${NC}" "INFO"    
    else
        LOG_message "sudo $ltmp_command 命令执行失败，退出码: ${sudo_execute_gui_RET}" "ERROR"   
    fi
    
    SUDO_ASKPASS=""
    return ${sudo_execute_gui_RET}
}

#################################################################################################
# 使用sudo权限执行命令的函数
#################################################################################################
sudo_execute() {
    local ltmp_command=$1
    local sudo_execute_RET=0
    
    show_who_call
    
    LOG_message "执行命令: sudo $ltmp_command | tee -a \"$this_LOG_FILE\" " "WARNING"
    LOG_message "sudo $ltmp_command 命令输出 : \n\r" "WARNING"
    sudo ${ltmp_command} | tee -a "$this_LOG_FILE"
    sudo_execute_RET=("${PIPESTATUS[@]}")
    
    if [ ${sudo_execute_RET} -eq 0 ]; then
        LOG_message "sudo $ltmp_command 命令执行成功.返回码: ${sudo_execute_RET}" "INFO"    
        log_MESSAGE "sudo $ltmp_command ${GREEN}命令执行成功.返回码: ${sudo_execute_RET}${NC}" "INFO"    
    else
        LOG_message "sudo $ltmp_command 命令执行失败，退出码: ${sudo_execute_RET}" "ERROR"   
    fi
    
    return ${sudo_execute_RET}
}

#################################################################################################
# 使用sudo权限执行命令的函数(返回输出)
#################################################################################################
sudo_execute_() {
    local ltmp_command=$1
    local ltmp_output=""
    
    ltmp_output=$(sudo ${ltmp_command} 2>&1)
    local ltmp_exit_code=$?
    
    LOG_message "执行命令: sudo $ltmp_command" "WARNING"
    LOG_message "sudo $ltmp_command 命令输出:\n$ltmp_output" "WARNING"
    echo "$ltmp_output" | tee -a "$this_LOG_FILE"
    
    SUDO_EXECUTE__OUTPUT="$ltmp_output"
    
    if [ $ltmp_exit_code -eq 0 ]; then
        LOG_message "sudo $ltmp_command 命令执行成功. 返回码: $ltmp_exit_code" "INFO"
        log_MESSAGE "sudo $ltmp_command ${GREEN}命令执行成功. 返回码: $ltmp_exit_code${NC}" "INFO"
    else
        LOG_message "sudo $ltmp_command 命令执行失败，退出码: $ltmp_exit_code" "ERROR"
    fi
    
    return $ltmp_exit_code
}

#################################################################################################
# 使用sudo权限执行命令的函数 安静版
#################################################################################################
sudo_execute_quiet() {
    local ltmp_command=$1
    
    show_who_call
    
    sudo ${ltmp_command} 
    
    if [ ${PIPESTATUS} -eq 0 ]; then
        log_MESSAGE "sudo $ltmp_command ${GREEN}命令执行成功.返回码: ${PIPESTATUS}${NC}" "INFO"    
    else
        log_MESSAGE "sudo $ltmp_command 命令执行失败，退出码: ${PIPESTATUS}" "ERROR"   
    fi
    
    return ${PIPESTATUS}
}

#################################################################################################
# 使用sudo权限执行命令的函数,程序执行后会运行 sudo -k
#################################################################################################
sudo_execute_once() {
    local ltmp_command=$1
    local sudo_execute_once_RET=0
    local sudo_execute_once_RET2=0
    
    show_who_call
    
    LOG_message "执行命令: sudo $ltmp_command | tee -a \"$this_LOG_FILE\" " "WARNING"
    LOG_message "sudo $ltmp_command 命令输出 : \n\r" "WARNING"
    sudo ${ltmp_command} | tee -a "$this_LOG_FILE"
    sudo_execute_once_RET=("${PIPESTATUS[@]}")
    
    if [ ${sudo_execute_once_RET} -eq 0 ]; then
        LOG_message "sudo $ltmp_command 命令执行成功.返回码: ${sudo_execute_once_RET}" "INFO"    
        log_MESSAGE "sudo $ltmp_command ${GREEN}命令执行成功.返回码: ${sudo_execute_once_RET}${NC}" "INFO"    
    else
        LOG_message "sudo $ltmp_command 命令执行失败，退出码: ${sudo_execute_once_RET}" "ERROR"   
    fi
    
    local ltmp_command2="-k"
    LOG_message "执行:终止sudo认证状态 " "WARNING"
    sudo ${ltmp_command2} | tee -a "$this_LOG_FILE"
    sudo_execute_once_RET2=("${PIPESTATUS[@]}")
    
    if [ ${sudo_execute_once_RET2} -eq 0 ]; then
        LOG_message "sudo $ltmp_command 命令执行成功.返回码: ${sudo_execute_once_RET2}" "INFO"    
        log_MESSAGE "sudo $ltmp_command ${GREEN}命令执行成功.返回码: ${sudo_execute_once_RET2}${NC}" "INFO"    
    else
        LOG_message "sudo $ltmp_command 命令执行失败，退出码: ${sudo_execute_once_RET2}" "ERROR"   
    fi
    
    return ${sudo_execute_once_RET}
}

#################################################################################################
# sudo_execute_base64函数，接受base64编码后的脚本内容作为参数，并解码执行
#################################################################################################
sudo_execute_base64() {
    local encoded_script="$1"
    local decoded_script=$(echo "$encoded_script" | base64 --decode)
    
    local script_file=$(mktemp ${this_TMP_DIR}/edit_ini_sudo.XXXXXX.sh)
    echo "$decoded_script" > "$script_file"
    
    chmod +x "$script_file"
    
    sudo "$script_file"
    
    rm -f "$script_file"
}

#################################################################################################
# 取消sudo权限执行命令的函数
#################################################################################################
unsudo_execute() {
    local ltmp_command=$1
    
    show_who_call
    
    LOG_message "执行命令: $ltmp_command | tee -a \"$this_LOG_FILE\" " "WARNING"
    LOG_message "$ltmp_command 命令输出 : \n\r" "WARNING"
    ${ltmp_command} | tee -a "$this_LOG_FILE"
    
    if [ ${PIPESTATUS} -eq 0 ]; then
        LOG_message "$ltmp_command 命令执行成功.返回码: ${PIPESTATUS}" "INFO"    
        log_MESSAGE "$ltmp_command ${GREEN}命令执行成功.返回码: ${PIPESTATUS}${NC}" "INFO"    
    else
        LOG_message "$ltmp_command 命令执行失败，退出码: ${PIPESTATUS}" "ERROR"   
    fi
    
    return ${PIPESTATUS}
}
