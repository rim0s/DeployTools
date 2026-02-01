#!/bin/bash
#################################################################################################
# 系统监控功能使用示例
# 用于监控CentOS 7服务器的CPU和内存使用情况
# 作者 : cursor
# 日期 : 2025-12-10
# 版本 : 1.0.0
# 说明 : 用于监控CentOS 7服务器的CPU和内存使用情况
#################################################################################################

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# 加载模块（推荐通过 loader 加载所有模块）
source "${LIB_DIR}/loader.sh" || {
    echo "错误: 无法加载模块" >&2
    exit 1
}
# 可选：逐一加载特定模块（如需更细粒度控制，可取消下面注释并修改）：
# source "${LIB_DIR}/logger.sh"
# source "${LIB_DIR}/utils.sh"
# source "${LIB_DIR}/monitor.sh"

#################################################################################################
# 主函数
#################################################################################################
main() {
    echo ""
    echo "=========================================================================="
    echo "系统监控工具使用示例"
    echo "=========================================================================="
    echo ""
    echo "请选择要执行的操作:"
    echo "1) 显示当前系统资源使用情况（单次快照）"
    echo "2) 持续监控系统资源（指定次数和间隔）"
    echo "3) 使用vmstat进行详细监控"
    echo "4) 生成灾备系统采购参考报告（推荐）"
    echo "5) 检查监控工具是否已安装"
    echo "0) 退出"
    echo ""
    read -p "请输入选项 [0-5]: " choice
    
    case $choice in
        1)
            echo ""
            show_system_resources
            ;;
        2)
            echo ""
            read -p "请输入监控次数 [默认: 10]: " count
            count=${count:-10}
            read -p "请输入监控间隔（秒） [默认: 5]: " interval
            interval=${interval:-5}
            echo ""
            monitor_system_resources "$count" "$interval"
            ;;
        3)
            echo ""
            read -p "请输入监控次数 [默认: 10]: " count
            count=${count:-10}
            read -p "请输入监控间隔（秒） [默认: 5]: " interval
            interval=${interval:-5}
            echo ""
            monitor_with_vmstat "$count" "$interval"
            ;;
        4)
            echo ""
            echo "此功能将监控系统资源并生成灾备系统采购参考报告"
            read -p "请输入监控次数 [默认: 30，约5分钟]: " count
            count=${count:-30}
            read -p "请输入监控间隔（秒） [默认: 10]: " interval
            interval=${interval:-10}
            echo ""
            generate_backup_report "$count" "$interval"
            ;;
        5)
            echo ""
            check_monitor_tools
            ;;
        0)
            echo "退出"
            exit 0
            ;;
        *)
            echo "无效选项"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
