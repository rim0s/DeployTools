#!/bin/bash
#一个简单的 askpass 脚本，用于为 sudo 显示图形的密码输入框
ltmp_sudo_password_tp=""

# 使用 zenity 显示密码输入框
#ltmp_sudo_password_tp=$(zenity --forms --title="Sudo Password" \
#    --text="Enter your sudo password:" \
#    --add-entry="Password" \
    #--hide-text \
    #--separator=",")
ltmp_sudo_password_tp=$(zenity --password 2>/dev/null)
# 检查 zenity 的退出状态
if [ $? -ne 0 ]; then
	# 用户取消或关闭了对话框
	echo ""
	exit 1
fi


if [ -z "$ltmp_sudo_password_tp" ]; then
	exit 1
else
	
	echo "$ltmp_sudo_password_tp"
fi


