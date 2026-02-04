#!/bin/bash

# ============================================
# iSCSI 服务器配置向导脚本
# ============================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否以 root 运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 sudo 运行此脚本"
        exit 1
    fi
}

# 显示菜单
show_menu() {
    clear
    echo "==========================================="
    echo "     iSCSI 服务器配置向导"
    echo "==========================================="
    echo "1. 创建新的 iSCSI 目标"
    echo "2. 查看现有配置"
    echo "3. 删除 iSCSI 目标"
    echo "4. 启动/停止服务"
    echo "5. 查看连接状态"
    echo "6. 配置防火墙"
    echo "7. 退出"
    echo "==========================================="
    echo -n "请选择操作 [1-7]: "
}

# 创建 iSCSI 目标
create_iscsi_target() {
    echo ""
    echo "=== 创建新的 iSCSI 目标 ==="
    
    # 获取存储配置
    read -p "存储文件路径 [/var/lib/target/]: " STORAGE_PATH
    STORAGE_PATH=${STORAGE_PATH:-/var/lib/target}
    
    read -p "存储文件名 [disk1.img]: " STORAGE_FILE
    STORAGE_FILE=${STORAGE_FILE:-disk1.img}
    
    read -p "存储大小 (如 10G, 100G) [10G]: " STORAGE_SIZE
    STORAGE_SIZE=${STORAGE_SIZE:-10G}
    
    read -p "iSCSI 目标名称 [iqn.$(date +%Y-%m).com.$(hostname):server]: " TARGET_NAME
    if [ -z "$TARGET_NAME" ]; then
        TARGET_NAME="iqn.$(date +%Y-%m).com.$(hostname -s):server"
    fi
    
    read -p "是否启用 CHAP 认证? (y/n) [y]: " USE_CHAP
    USE_CHAP=${USE_CHAP:-y}
    
    if [ "$USE_CHAP" = "y" ]; then
        read -p "CHAP 用户名 [iscsiuser]: " CHAP_USER
        CHAP_USER=${CHAP_USER:-iscsiuser}
        
        read -p "CHAP 密码: " CHAP_PASS
        if [ -z "$CHAP_PASS" ]; then
            CHAP_PASS=$(openssl rand -base64 12)
            print_info "已生成随机密码: $CHAP_PASS"
        fi
    fi
    
    # 显示配置摘要
    echo ""
    echo "=== 配置摘要 ==="
    echo "存储路径: $STORAGE_PATH/$STORAGE_FILE"
    echo "存储大小: $STORAGE_SIZE"
    echo "目标名称: $TARGET_NAME"
    echo "CHAP 认证: $USE_CHAP"
    if [ "$USE_CHAP" = "y" ]; then
        echo "用户名: $CHAP_USER"
        echo "密码: $CHAP_PASS"
    fi
    echo ""
    
    read -p "确认创建? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        print_warn "已取消"
        return
    fi
    
    # 开始创建
    print_info "正在创建 iSCSI 目标..."
    
    # 1. 创建存储目录
    mkdir -p "$STORAGE_PATH"
    chmod 755 "$STORAGE_PATH"
    
    # 2. 创建存储文件
    FULL_PATH="$STORAGE_PATH/$STORAGE_FILE"
    print_info "创建存储文件: $FULL_PATH ($STORAGE_SIZE)"
    dd if=/dev/zero of="$FULL_PATH" bs=1 count=0 seek=$STORAGE_SIZE 2>/dev/null
    
    # 3. 使用 targetcli 配置
    print_info "配置 iSCSI 目标..."
    
    # 创建临时配置文件
    TMP_FILE=$(mktemp)
    cat > "$TMP_FILE" << EOF
# 创建后端存储
cd /backstores/fileio
create $STORAGE_FILE $FULL_PATH

# 创建 iSCSI 目标
cd /iscsi
create $TARGET_NAME

# 创建 LUN
cd /iscsi/$TARGET_NAME/tpg1/luns
create /backstores/fileio/$STORAGE_FILE

# 设置 ACL（允许所有客户端）
cd /iscsi/$TARGET_NAME/tpg1/acls
create iqn.1991-05.com.microsoft:*

# 设置认证
cd /iscsi/$TARGET_NAME/tpg1
set attribute authentication=1
set attribute generate_node_acls=1
EOF

    # 添加 CHAP 配置
    if [ "$USE_CHAP" = "y" ]; then
        cat >> "$TMP_FILE" << EOF
set auth userid=$CHAP_USER
set auth password=$CHAP_PASS
EOF
    fi
    
    # 保存配置
    cat >> "$TMP_FILE" << EOF
# 保存配置
saveconfig
EOF
    
    # 执行配置
    targetcli < "$TMP_FILE"
    rm -f "$TMP_FILE"
    
    # 4. 重启服务
    systemctl restart target
    
    # 5. 显示连接信息
    echo ""
    print_info "=== iSCSI 目标创建成功 ==="
    echo "目标名称: $TARGET_NAME"
    echo "服务器 IP: $(hostname -I | awk '{print $1}')"
    echo "端口: 3260"
    if [ "$USE_CHAP" = "y" ]; then
        echo "用户名: $CHAP_USER"
        echo "密码: $CHAP_PASS"
    fi
    echo ""
    echo "Windows 客户端连接命令 (PowerShell):"
    echo "New-IscsiTargetPortal -TargetPortalAddress $(hostname -I | awk '{print $1}')"
    echo "Connect-IscsiTarget -NodeAddress \"$TARGET_NAME\" -AuthenticationType ONEWAYCHAP -ChapUsername \"$CHAP_USER\" -ChapSecret \"$CHAP_PASS\""
    
    read -p "按 Enter 键继续..."
}

# 查看现有配置
view_config() {
    echo ""
    echo "=== 当前 iSCSI 配置 ==="
    targetcli ls
    echo ""
    
    echo "=== 活动会话 ==="
    targetcli sessions
    echo ""
    
    echo "=== 存储文件 ==="
    find /var/lib/target -name "*.img" -type f 2>/dev/null | while read file; do
        echo "$file - $(ls -lh "$file" | awk '{print $5}')"
    done
    
    read -p "按 Enter 键继续..."
}

# 删除 iSCSI 目标
delete_iscsi_target() {
    echo ""
    echo "=== 删除 iSCSI 目标 ==="
    
    # 显示现有目标
    echo "现有 iSCSI 目标:"
    targetcli ls /iscsi 2>/dev/null | grep "iqn.*" || echo "未找到目标"
    echo ""
    
    read -p "输入要删除的目标名称 (输入 'all' 删除所有): " TARGET_TO_DELETE
    
    if [ -z "$TARGET_TO_DELETE" ]; then
        print_warn "未输入目标名称"
        return
    fi
    
    if [ "$TARGET_TO_DELETE" = "all" ]; then
        read -p "确认删除所有 iSCSI 目标? (y/n): " CONFIRM
        if [ "$CONFIRM" = "y" ]; then
            print_info "正在删除所有配置..."
            targetcli clearconfig confirm=true
            systemctl restart target
            print_info "所有配置已删除"
        fi
    else
        read -p "确认删除目标 '$TARGET_TO_DELETE'? (y/n): " CONFIRM
        if [ "$CONFIRM" = "y" ]; then
            print_info "正在删除目标..."
            
            # 创建临时删除脚本
            TMP_FILE=$(mktemp)
            cat > "$TMP_FILE" << EOF
cd /iscsi
delete $TARGET_TO_DELETE
saveconfig
EOF
            targetcli < "$TMP_FILE"
            rm -f "$TMP_FILE"
            
            systemctl restart target
            print_info "目标已删除"
        fi
    fi
    
    read -p "按 Enter 键继续..."
}

# 服务管理
manage_service() {
    echo ""
    echo "=== iSCSI 服务管理 ==="
    echo "1. 启动服务"
    echo "2. 停止服务"
    echo "3. 重启服务"
    echo "4. 查看状态"
    echo "5. 设置开机自启"
    echo "6. 禁用开机自启"
    echo -n "请选择 [1-6]: "
    
    read SERVICE_CHOICE
    case $SERVICE_CHOICE in
        1)
            systemctl start target
            print_info "服务已启动"
            ;;
        2)
            systemctl stop target
            print_info "服务已停止"
            ;;
        3)
            systemctl restart target
            print_info "服务已重启"
            ;;
        4)
            systemctl status target
            ;;
        5)
            systemctl enable target
            print_info "已设置开机自启"
            ;;
        6)
            systemctl disable target
            print_info "已禁用开机自启"
            ;;
        *)
            print_error "无效选择"
            ;;
    esac
    
    read -p "按 Enter 键继续..."
}

# 查看连接状态
view_connections() {
    echo ""
    echo "=== iSCSI 连接状态 ==="
    
    echo "1. 活动会话:"
    targetcli sessions
    
    echo ""
    echo "2. 网络连接:"
    netstat -tlnp | grep 3260
    
    echo ""
    echo "3. 服务日志 (最后 10 行):"
    journalctl -u target -n 10 --no-pager
    
    echo ""
    echo "4. 存储使用情况:"
    df -h /var/lib/target 2>/dev/null || echo "存储目录未找到"
    
    read -p "按 Enter 键继续..."
}

# 配置防火墙
configure_firewall() {
    echo ""
    echo "=== 防火墙配置 ==="
    echo "1. 开放 iSCSI 端口 (3260)"
    echo "2. 关闭防火墙 (测试用)"
    echo "3. 查看防火墙状态"
    echo -n "请选择 [1-3]: "
    
    read FW_CHOICE
    case $FW_CHOICE in
        1)
            firewall-cmd --permanent --add-port=3260/tcp
            firewall-cmd --reload
            print_info "已开放端口 3260"
            ;;
        2)
            systemctl stop firewalld
            systemctl disable firewalld
            print_warn "防火墙已关闭 (不推荐生产环境)"
            ;;
        3)
            firewall-cmd --list-all
            ;;
        *)
            print_error "无效选择"
            ;;
    esac
    
    read -p "按 Enter 键继续..."
}

# 快速设置函数
quick_setup() {
    echo ""
    echo "=== 快速设置 iSCSI 服务器 ==="
    read -p "存储大小 (如 10G, 50G) [10G]: " SIZE
    SIZE=${SIZE:-10G}
    
    # 自动配置
    STORAGE_PATH="/var/lib/target"
    STORAGE_FILE="disk_$(date +%Y%m%d_%H%M%S).img"
    TARGET_NAME="iqn.$(date +%Y-%m).com.$(hostname -s):disk"
    CHAP_USER="user_$(hostname -s)"
    CHAP_PASS=$(openssl rand -base64 8 | tr -d '=' | tr '+/' '_-')
    
    print_info "使用以下配置:"
    echo "存储文件: $STORAGE_PATH/$STORAGE_FILE"
    echo "大小: $SIZE"
    echo "目标: $TARGET_NAME"
    echo "用户名: $CHAP_USER"
    echo "密码: $CHAP_PASS"
    
    read -p "确认快速设置? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        return
    fi
    
    # 执行设置
    mkdir -p $STORAGE_PATH
    dd if=/dev/zero of="$STORAGE_PATH/$STORAGE_FILE" bs=1 count=0 seek=$SIZE 2>/dev/null
    
    TMP_FILE=$(mktemp)
    cat > "$TMP_FILE" << EOF
cd /backstores/fileio
create $STORAGE_FILE $STORAGE_PATH/$STORAGE_FILE
cd /iscsi
create $TARGET_NAME
cd /iscsi/$TARGET_NAME/tpg1/luns
create /backstores/fileio/$STORAGE_FILE
cd /iscsi/$TARGET_NAME/tpg1/acls
create iqn.1991-05.com.microsoft:*
cd /iscsi/$TARGET_NAME/tpg1
set attribute authentication=1
set auth userid=$CHAP_USER
set auth password=$CHAP_PASS
saveconfig
EOF
    
    targetcli < "$TMP_FILE"
    rm -f "$TMP_FILE"
    
    systemctl restart target
    firewall-cmd --permanent --add-port=3260/tcp
    firewall-cmd --reload
    
    echo ""
    print_info "=== 快速设置完成 ==="
    echo "服务器 IP: $(hostname -I | awk '{print $1}')"
    echo "目标名称: $TARGET_NAME"
    echo "用户名: $CHAP_USER"
    echo "密码: $CHAP_PASS"
    
    read -p "按 Enter 键继续..."
}

# 主循环
main() {
    check_root
    
    # 检查是否安装 targetcli
    if ! command -v targetcli &> /dev/null; then
        print_error "未找到 targetcli，请先安装 scsi-target-utils"
        read -p "是否要安装? (y/n): " INSTALL_CHOICE
        if [ "$INSTALL_CHOICE" = "y" ]; then
            dnf install -y scsi-target-utils targetcli
        else
            exit 1
        fi
    fi
    
    while true; do
        show_menu
        read CHOICE
        
        case $CHOICE in
            1)
                create_iscsi_target
                ;;
            2)
                view_config
                ;;
            3)
                delete_iscsi_target
                ;;
            4)
                manage_service
                ;;
            5)
                view_connections
                ;;
            6)
                configure_firewall
                ;;
            7)
                print_info "退出脚本"
                exit 0
                ;;
            q|Q)
                print_info "快速设置模式"
                quick_setup
                ;;
            *)
                print_error "无效选择，请重新输入"
                sleep 2
                ;;
        esac
    done
}

# 运行主函数
main
