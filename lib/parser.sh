#!/bin/bash
#################################################################################################
# 参数解析模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"

#################################################################################################
# 解析短选项
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
# 解析长选项 如:--start --stop --restart --help
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
# 另一种参数处理思路的主函数模板
#################################################################################################
main_planB(){
    # 初始化变量
    TAGS=()
    MESSAGES=()
    START_VALUES=()
    STOP_VALUES=()
    LISTEN_VALUES=()

    # 调用解析长选项的函数
    parse_long_options "$@"

    # 输出解析结果（示例）
    echo "Start values: ${START_VALUES[@]}"
    echo "Stop values: ${STOP_VALUES[@]}"
    echo "Listen values: ${LISTEN_VALUES[@]}"
}
