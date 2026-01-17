#!/bin/bash
#################################################################################################
# 高级包管理模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/package.sh" 2>/dev/null || source "./lib/package.sh"
source "$(dirname "$0")/sudo.sh" 2>/dev/null || source "./lib/sudo.sh"

#################################################################################################
# 检查单个包是否安装
# 2024-10-27 saint:该方式仅支持单个包名作为参数 修改版的函数为 check_packages_installed
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
        # 使用 pkg 检查包是否安装
        if $app_manager info  2> /dev/null | grep -q "$package_name"; then
            log_message "包 '$package_name' 已经安装 (使用 pkg)。" "INFO"
        else
            log_message "包 '$package_name' 未安装 (使用 pkg)。" "ERROR"
            return 2
        fi
    # 检查是否存在 zypper 命令
    elif [ "$app_manager" == "zypper" ];then
        # 使用 zypper 检查包是否安装
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
# 检查包清单是否安装
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
# 安装包
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
        log_message "提供的软件包清单: $ltmp_package_name 安装异常失败,可能存在遗漏或其他未预见错误,请手动检查安装结果后手动安装." "WARNING"
        return 1
    fi

    return 0
}

#################################################################################################
# 使用DNF批量安装包(2024-11-28添加,目的为了新装或重装fedora时候能够快速重装需要的包)
#   o 已经安装  返回 0
#   o 未安装    返回 2
#   o 包管理器未在脚本定义  返回 1
# 示例调用函数:
# local ltmp_pakage_list_of_fedora="aircrack aisleriot amule anjuta ..."
# dnf_install_packages "$ltmp_pakage_list_of_fedora"
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
                if [[ $? -eq 124 ]]; then  # 124 通常是超时错误码
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
