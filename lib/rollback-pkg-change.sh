#!/bin/bash


# 安全的软件包安装（针对不同发行版）
safe_pkg_install() {
    local pkg="$1"
    local op_id="pkg_install_$(date +%s)_${RANDOM}"

    # 检测包管理器
    local pkg_manager=""
    if command -v apt-get &>/dev/null; then
        pkg_manager="apt"
        register_operation "$op_id" "apt-get remove -y '$pkg'" "pkg uninstall $pkg (apt)"
    elif command -v yum &>/dev/null; then
        pkg_manager="yum"
        register_operation "$op_id" "yum remove -y '$pkg'" "pkg uninstall $pkg (yum)"
    elif command -v dnf &>/dev/null; then
        pkg_manager="dnf"
        register_operation "$op_id" "dnf remove -y '$pkg'" "pkg uninstall $pkg (dnf)"
    else
        log_error "不支持的系统包管理器"
        return 1
    fi

    # 执行安装
    case "$pkg_manager" in
        apt)
            if apt-get install -y "$pkg"; then
                echo "$op_id: apt-get install '$pkg'" >> "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/operations.log"
                echo "$op_id"
                return 0
            fi
            ;;
        yum|dnf)
            if "$pkg_manager" install -y "$pkg"; then
                echo "$op_id: $pkg_manager install '$pkg'" >> "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/operations.log"
                echo "$op_id"
                return 0
            fi
            ;;
    esac

    log_error "安装软件包失败: $pkg"
    return 1
}