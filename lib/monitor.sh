#!/bin/bash
#################################################################################################
# 系统监控模块
# 用于监控CPU和内存使用情况，特别适用于灾备系统采购参考
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"
source "$(dirname "$0")/utils.sh" 2>/dev/null || source "./lib/utils.sh"
source "$(dirname "$0")/sudo.sh" 2>/dev/null || source "./lib/sudo.sh"

#################################################################################################
# 获取当前CPU使用率(百分比)
# 返回: CPU使用率(0-100)
#################################################################################################
get_cpu_usage() {
    local ltmp_cpu_usage
    
    # 方法1: 使用top命令(最准确)
    if command -v top >/dev/null 2>&1; then
        ltmp_cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        if [ -n "$ltmp_cpu_usage" ] && [ "$ltmp_cpu_usage" != "100" ]; then
            echo "$ltmp_cpu_usage"
            return 0
        fi
    fi
    
    # 方法2: 使用vmstat(适用于CentOS 7)
    if command -v vmstat >/dev/null 2>&1; then
        ltmp_cpu_usage=$(vmstat 1 2 | tail -1 | awk '{print 100 - $15}')
        if [ -n "$ltmp_cpu_usage" ]; then
            echo "$ltmp_cpu_usage"
            return 0
        fi
    fi
    
    # 方法3: 使用/proc/stat计算
    local ltmp_cpu1=$(cat /proc/stat | grep '^cpu ' | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8}')
    sleep 1
    local ltmp_cpu2=$(cat /proc/stat | grep '^cpu ' | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8}')
    
    local ltmp_idle1=$(echo $ltmp_cpu1 | awk '{print $4}')
    local ltmp_idle2=$(echo $ltmp_cpu2 | awk '{print $4}')
    
    local ltmp_total1=0
    local ltmp_total2=0
    
    for i in $ltmp_cpu1; do
        ltmp_total1=$((ltmp_total1 + i))
    done
    
    for i in $ltmp_cpu2; do
        ltmp_total2=$((ltmp_total2 + i))
    done
    
    local ltmp_idle_diff=$((ltmp_idle2 - ltmp_idle1))
    local ltmp_total_diff=$((ltmp_total2 - ltmp_total1))
    
    if [ $ltmp_total_diff -gt 0 ]; then
        ltmp_cpu_usage=$(echo "scale=2; (($ltmp_total_diff - $ltmp_idle_diff) * 100) / $ltmp_total_diff" | bc)
        echo "$ltmp_cpu_usage"
        return 0
    fi
    
    echo "0"
    return 1
}

#################################################################################################
# 获取当前内存使用情况
# 返回: 总内存(MB) 已用内存(MB) 可用内存(MB) 使用率(%)
#################################################################################################
get_memory_usage() {
    local ltmp_mem_info
    
    # 使用free命令(最直接)
    if command -v free >/dev/null 2>&1; then
        # CentOS 7的free命令输出格式
        ltmp_mem_info=$(free -m | grep '^Mem:')
        local ltmp_total=$(echo $ltmp_mem_info | awk '{print $2}')
        local ltmp_used=$(echo $ltmp_mem_info | awk '{print $3}')
        local ltmp_available=$(echo $ltmp_mem_info | awk '{print $7}')
        
        # 如果available字段不存在(旧版本)，使用free字段计算
        if [ -z "$ltmp_available" ] || [ "$ltmp_available" = "0" ]; then
            local ltmp_free=$(echo $ltmp_mem_info | awk '{print $4}')
            local ltmp_buffers=$(echo $ltmp_mem_info | awk '{print $6}')
            ltmp_available=$((ltmp_free + ltmp_buffers))
        fi
        
        local ltmp_usage_percent=$(echo "scale=2; ($ltmp_used * 100) / $ltmp_total" | bc 2>/dev/null || echo "0")
        
        echo "$ltmp_total $ltmp_used $ltmp_available $ltmp_usage_percent"
        return 0
    fi
    
    # 备用方法: 从/proc/meminfo读取
    local ltmp_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    ltmp_total=$((ltmp_total / 1024))
    local ltmp_free=$(grep MemFree /proc/meminfo | awk '{print $2}')
    ltmp_free=$((ltmp_free / 1024))
    local ltmp_buffers=$(grep Buffers /proc/meminfo | awk '{print $2}')
    ltmp_buffers=$((ltmp_buffers / 1024))
    local ltmp_cached=$(grep -w Cached /proc/meminfo | awk '{print $2}')
    ltmp_cached=$((ltmp_cached / 1024))
    
    local ltmp_used=$((ltmp_total - ltmp_free - ltmp_buffers - ltmp_cached))
    local ltmp_available=$((ltmp_free + ltmp_buffers + ltmp_cached))
    local ltmp_usage_percent=$(echo "scale=2; ($ltmp_used * 100) / $ltmp_total" | bc 2>/dev/null || echo "0")
    
    echo "$ltmp_total $ltmp_used $ltmp_available $ltmp_usage_percent"
    return 0
}

#################################################################################################
# 显示当前系统资源使用情况(单次快照)
#################################################################################################
show_system_resources() {
    echo_sharp_line
    echo "系统资源使用情况 - $(date '+%Y-%m-%d %H:%M:%S')"
    echo_sharp_line
    
    # CPU信息
    local ltmp_cpu_usage=$(get_cpu_usage)
    local ltmp_cpu_cores=$(nproc 2>/dev/null || grep -c processor /proc/cpuinfo)
    local ltmp_cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[[:space:]]*//')
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "CPU 信息"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "CPU型号: ${ltmp_cpu_model:-未知}"
    echo "CPU核心数: $ltmp_cpu_cores"
    printf "CPU使用率: %.2f%%\n" "$ltmp_cpu_usage"
    echo ""
    
    # 内存信息
    local ltmp_mem_info=$(get_memory_usage)
    local ltmp_mem_total=$(echo $ltmp_mem_info | awk '{print $1}')
    local ltmp_mem_used=$(echo $ltmp_mem_info | awk '{print $2}')
    local ltmp_mem_available=$(echo $ltmp_mem_info | awk '{print $3}')
    local ltmp_mem_usage_percent=$(echo $ltmp_mem_info | awk '{print $4}')
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "内存信息"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "总内存: %d MB (%.2f GB)\n" "$ltmp_mem_total" "$(echo "scale=2; $ltmp_mem_total / 1024" | bc)"
    printf "已用内存: %d MB (%.2f GB)\n" "$ltmp_mem_used" "$(echo "scale=2; $ltmp_mem_used / 1024" | bc)"
    printf "可用内存: %d MB (%.2f GB)\n" "$ltmp_mem_available" "$(echo "scale=2; $ltmp_mem_available / 1024" | bc)"
    printf "内存使用率: %.2f%%\n" "$ltmp_mem_usage_percent"
    echo ""
    
    # 负载信息
    local ltmp_load_avg=$(uptime | awk -F'load average:' '{print $2}')
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "系统负载"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "负载平均值: $ltmp_load_avg"
    echo ""
    
    echo_sharp_line
    
    LOG_message "已显示系统资源使用情况 - CPU: ${ltmp_cpu_usage}%, 内存: ${ltmp_mem_usage_percent}%" "INFO"
}

#################################################################################################
# 持续监控系统资源(指定次数和间隔)
# 参数: $1=监控次数, $2=间隔秒数(默认5秒)
#################################################################################################
monitor_system_resources() {
    local ltmp_count=${1:-10}
    local ltmp_interval=${2:-5}
    local ltmp_report_file="${this_LOG_DIR}/system_monitor_$(date +%Y%m%d_%H%M%S).txt"
    
    echo_sharp_line
    echo "开始持续监控系统资源"
    echo "监控次数: $ltmp_count 次"
    echo "监控间隔: $ltmp_interval 秒"
    echo "报告文件: $ltmp_report_file"
    echo_sharp_line
    echo ""
    
    # 创建报告文件头部
    {
        echo "##########################################################################"
        echo "# 系统资源监控报告"
        echo "# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# 主机名: $(hostname)"
        echo "# 操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
        echo "# 监控次数: $ltmp_count"
        echo "# 监控间隔: $ltmp_interval 秒"
        echo "##########################################################################"
        echo ""
        printf "%-20s %-12s %-12s %-12s %-12s %-12s\n" "时间" "CPU使用率%" "总内存(MB)" "已用内存(MB)" "可用内存(MB)" "内存使用率%"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    } > "$ltmp_report_file"
    
    local ltmp_cpu_sum=0
    local ltmp_mem_sum=0
    local ltmp_cpu_max=0
    local ltmp_cpu_min=100
    local ltmp_mem_max=0
    local ltmp_mem_min=100
    
    for ((i=1; i<=ltmp_count; i++)); do
        local ltmp_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local ltmp_cpu_usage=$(get_cpu_usage)
        local ltmp_mem_info=$(get_memory_usage)
        local ltmp_mem_total=$(echo $ltmp_mem_info | awk '{print $1}')
        local ltmp_mem_used=$(echo $ltmp_mem_info | awk '{print $2}')
        local ltmp_mem_available=$(echo $ltmp_mem_info | awk '{print $3}')
        local ltmp_mem_usage_percent=$(echo $ltmp_mem_info | awk '{print $4}')
        
        # 累计统计
        ltmp_cpu_sum=$(echo "$ltmp_cpu_sum + $ltmp_cpu_usage" | bc)
        ltmp_mem_sum=$(echo "$ltmp_mem_sum + $ltmp_mem_usage_percent" | bc)
        
        # 最大值和最小值
        if (( $(echo "$ltmp_cpu_usage > $ltmp_cpu_max" | bc -l) )); then
            ltmp_cpu_max=$ltmp_cpu_usage
        fi
        if (( $(echo "$ltmp_cpu_usage < $ltmp_cpu_min" | bc -l) )); then
            ltmp_cpu_min=$ltmp_cpu_usage
        fi
        if (( $(echo "$ltmp_mem_usage_percent > $ltmp_mem_max" | bc -l) )); then
            ltmp_mem_max=$ltmp_mem_usage_percent
        fi
        if (( $(echo "$ltmp_mem_usage_percent < $ltmp_mem_min" | bc -l) )); then
            ltmp_mem_min=$ltmp_mem_usage_percent
        fi
        
        # 输出到屏幕
        printf "[%d/%d] %s - CPU: %.2f%%, 内存: %.2f%%\n" "$i" "$ltmp_count" "$ltmp_timestamp" "$ltmp_cpu_usage" "$ltmp_mem_usage_percent"
        
        # 写入报告文件
        printf "%-20s %-12.2f %-12d %-12d %-12d %-12.2f\n" \
            "$ltmp_timestamp" "$ltmp_cpu_usage" "$ltmp_mem_total" "$ltmp_mem_used" "$ltmp_mem_available" "$ltmp_mem_usage_percent" \
            >> "$ltmp_report_file"
        
        # 如果不是最后一次，等待指定间隔
        if [ $i -lt $ltmp_count ]; then
            sleep $ltmp_interval
        fi
    done
    
    # 计算平均值
    local ltmp_cpu_avg=$(echo "scale=2; $ltmp_cpu_sum / $ltmp_count" | bc)
    local ltmp_mem_avg=$(echo "scale=2; $ltmp_mem_sum / $ltmp_count" | bc)
    
    # 添加统计摘要到报告文件
    {
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "统计摘要"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "CPU使用率:"
        printf "  平均值: %.2f%%\n" "$ltmp_cpu_avg"
        printf "  最大值: %.2f%%\n" "$ltmp_cpu_max"
        printf "  最小值: %.2f%%\n" "$ltmp_cpu_min"
        echo ""
        echo "内存使用率:"
        printf "  平均值: %.2f%%\n" "$ltmp_mem_avg"
        printf "  最大值: %.2f%%\n" "$ltmp_mem_max"
        printf "  最小值: %.2f%%\n" "$ltmp_mem_min"
        echo ""
        echo "##########################################################################"
        echo "# 报告结束"
        echo "##########################################################################"
    } >> "$ltmp_report_file"
    
    echo ""
    echo_sharp_line
    echo "监控完成！"
    echo_sharp_line
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "统计摘要"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "CPU使用率:"
    printf "  平均值: %.2f%%\n" "$ltmp_cpu_avg"
    printf "  最大值: %.2f%%\n" "$ltmp_cpu_max"
    printf "  最小值: %.2f%%\n" "$ltmp_cpu_min"
    echo ""
    echo "内存使用率:"
    printf "  平均值: %.2f%%\n" "$ltmp_mem_avg"
    printf "  最大值: %.2f%%\n" "$ltmp_mem_max"
    printf "  最小值: %.2f%%\n" "$ltmp_mem_min"
    echo ""
    echo "详细报告已保存至: $ltmp_report_file"
    echo ""
    
    LOG_message "系统资源监控完成 - CPU平均: ${ltmp_cpu_avg}%, 内存平均: ${ltmp_mem_avg}%" "INFO"
}

#################################################################################################
# 使用vmstat进行监控(适用于CentOS 7，更详细的信息)
# 参数: $1=监控次数, $2=间隔秒数(默认5秒)
#################################################################################################
monitor_with_vmstat() {
    local ltmp_count=${1:-10}
    local ltmp_interval=${2:-5}
    local ltmp_report_file="${this_LOG_DIR}/vmstat_monitor_$(date +%Y%m%d_%H%M%S).txt"
    
    if ! command -v vmstat >/dev/null 2>&1; then
        echo "错误: vmstat 命令未找到，请安装 sysstat 包"
        echo "安装命令: yum install -y sysstat"
        return 1
    fi
    
    echo_sharp_line
    echo "使用 vmstat 监控系统资源"
    echo "监控次数: $ltmp_count 次"
    echo "监控间隔: $ltmp_interval 秒"
    echo "报告文件: $ltmp_report_file"
    echo_sharp_line
    echo ""
    
    # 执行vmstat并保存结果
    {
        echo "##########################################################################"
        echo "# vmstat 系统资源监控报告"
        echo "# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# 主机名: $(hostname)"
        echo "##########################################################################"
        echo ""
        vmstat $ltmp_interval $ltmp_count
        echo ""
        echo "##########################################################################"
        echo "# 报告说明"
        echo "# - r: 运行队列中的进程数"
        echo "# - b: 等待I/O的进程数"
        echo "# - swpd: 使用的虚拟内存量(KB)"
        echo "# - free: 空闲内存量(KB)"
        echo "# - buff: 用作缓冲区的内存量(KB)"
        echo "# - cache: 用作缓存的内存量(KB)"
        echo "# - si: 从磁盘交换到内存的速率(KB/s)"
        echo "# - so: 从内存交换到磁盘的速率(KB/s)"
        echo "# - bi: 从块设备接收的块数(blocks/s)"
        echo "# - bo: 发送到块设备的块数(blocks/s)"
        echo "# - in: 每秒中断数"
        echo "# - cs: 每秒上下文切换数"
        echo "# - us: 用户空间占用CPU百分比"
        echo "# - sy: 内核空间占用CPU百分比"
        echo "# - id: 空闲CPU百分比"
        echo "# - wa: 等待I/O的CPU百分比"
        echo "# - st: 虚拟机占用的CPU百分比"
        echo "##########################################################################"
    } | tee "$ltmp_report_file"
    
    echo ""
    echo "详细报告已保存至: $ltmp_report_file"
    echo ""
    
    LOG_message "vmstat监控完成" "INFO"
}

#################################################################################################
# 生成灾备系统采购参考报告
# 参数: $1=监控次数(默认30次，约5分钟), $2=间隔秒数(默认10秒)
#################################################################################################
generate_backup_report() {
    local ltmp_count=${1:-30}
    local ltmp_interval=${2:-10}
    local ltmp_report_file="${this_LOG_DIR}/backup_system_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo_sharp_line
    echo "生成灾备系统采购参考报告"
    echo "正在监控系统资源，请稍候..."
    echo_sharp_line
    echo ""
    
    # 收集系统基础信息
    local ltmp_hostname=$(hostname)
    local ltmp_os_info=$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
    local ltmp_cpu_cores=$(nproc 2>/dev/null || grep -c processor /proc/cpuinfo)
    local ltmp_cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[[:space:]]*//')
    local ltmp_mem_info=$(get_memory_usage)
    local ltmp_mem_total=$(echo $ltmp_mem_info | awk '{print $1}')
    
    # 开始监控
    local ltmp_cpu_sum=0
    local ltmp_mem_sum=0
    local ltmp_cpu_max=0
    local ltmp_cpu_min=100
    local ltmp_mem_max=0
    local ltmp_mem_min=100
    
    for ((i=1; i<=ltmp_count; i++)); do
        local ltmp_cpu_usage=$(get_cpu_usage)
        local ltmp_mem_info=$(get_memory_usage)
        local ltmp_mem_usage_percent=$(echo $ltmp_mem_info | awk '{print $4}')
        
        ltmp_cpu_sum=$(echo "$ltmp_cpu_sum + $ltmp_cpu_usage" | bc)
        ltmp_mem_sum=$(echo "$ltmp_mem_sum + $ltmp_mem_usage_percent" | bc)
        
        if (( $(echo "$ltmp_cpu_usage > $ltmp_cpu_max" | bc -l) )); then
            ltmp_cpu_max=$ltmp_cpu_usage
        fi
        if (( $(echo "$ltmp_cpu_usage < $ltmp_cpu_min" | bc -l) )); then
            ltmp_cpu_min=$ltmp_cpu_usage
        fi
        if (( $(echo "$ltmp_mem_usage_percent > $ltmp_mem_max" | bc -l) )); then
            ltmp_mem_max=$ltmp_mem_usage_percent
        fi
        if (( $(echo "$ltmp_mem_usage_percent < $ltmp_mem_min" | bc -l) )); then
            ltmp_mem_min=$ltmp_mem_usage_percent
        fi
        
        printf "\r[%d/%d] 监控中... CPU: %.2f%%, 内存: %.2f%%" "$i" "$ltmp_count" "$ltmp_cpu_usage" "$ltmp_mem_usage_percent"
        sleep $ltmp_interval
    done
    echo ""
    
    # 计算平均值
    local ltmp_cpu_avg=$(echo "scale=2; $ltmp_cpu_sum / $ltmp_count" | bc)
    local ltmp_mem_avg=$(echo "scale=2; $ltmp_mem_sum / $ltmp_count" | bc)
    
    # 生成报告
    {
        echo "##########################################################################"
        echo "# 灾备系统采购参考报告"
        echo "# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "##########################################################################"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "一、系统基本信息"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "主机名: $ltmp_hostname"
        echo "操作系统: $ltmp_os_info"
        echo "CPU型号: ${ltmp_cpu_model:-未知}"
        echo "CPU核心数: $ltmp_cpu_cores"
        printf "总内存: %d MB (%.2f GB)\n" "$ltmp_mem_total" "$(echo "scale=2; $ltmp_mem_total / 1024" | bc)"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "二、系统资源使用情况(空闲时监控)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "监控时长: $((ltmp_count * ltmp_interval)) 秒 ($(echo "scale=1; $ltmp_count * $ltmp_interval / 60" | bc) 分钟)"
        echo "监控次数: $ltmp_count 次"
        echo "监控间隔: $ltmp_interval 秒"
        echo ""
        echo "CPU使用情况:"
        printf "  平均使用率: %.2f%%\n" "$ltmp_cpu_avg"
        printf "  最大使用率: %.2f%%\n" "$ltmp_cpu_max"
        printf "  最小使用率: %.2f%%\n" "$ltmp_cpu_min"
        echo ""
        echo "内存使用情况:"
        printf "  平均使用率: %.2f%%\n" "$ltmp_mem_avg"
        printf "  最大使用率: %.2f%%\n" "$ltmp_mem_max"
        printf "  最小使用率: %.2f%%\n" "$ltmp_mem_min"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "三、灾备系统配置建议"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "基于当前系统空闲时的资源使用情况，建议灾备系统配置如下："
        echo ""
        
        # CPU建议(考虑20%的冗余)
        local ltmp_cpu_recommend=$(echo "scale=0; ($ltmp_cpu_avg * 1.2 + 0.5) / 1" | bc)
        if [ $ltmp_cpu_recommend -lt 1 ]; then
            ltmp_cpu_recommend=1
        fi
        echo "1. CPU配置建议:"
        echo "   当前系统空闲时CPU平均使用率: ${ltmp_cpu_avg}%"
        echo "   建议灾备系统CPU核心数: $ltmp_cpu_cores 核(与主系统相同)"
        echo "   说明: 灾备系统通常需要与主系统相同的CPU配置以确保性能一致性"
        echo ""
        
        # 内存建议(考虑30%的冗余和峰值)
        local ltmp_mem_recommend=$(echo "scale=0; ($ltmp_mem_total * $ltmp_mem_max / 100 * 1.3 + 0.5) / 1" | bc)
        local ltmp_mem_recommend_gb=$(echo "scale=2; $ltmp_mem_recommend / 1024" | bc)
        echo "2. 内存配置建议:"
        echo "   当前系统总内存: ${ltmp_mem_total} MB ($(echo "scale=2; $ltmp_mem_total / 1024" | bc) GB)"
        echo "   空闲时内存平均使用率: ${ltmp_mem_avg}%"
        echo "   空闲时内存峰值使用率: ${ltmp_mem_max}%"
        printf "   建议灾备系统内存: %d MB (%.2f GB)\n" "$ltmp_mem_recommend" "$ltmp_mem_recommend_gb"
        echo "   说明: 基于峰值使用率并考虑30%冗余，确保灾备系统有足够资源"
        echo ""
        
        echo "3. 其他建议:"
        echo "   - 建议灾备系统与主系统使用相同的操作系统版本"
        echo "   - 建议定期(如每月)重新评估资源使用情况"
        echo "   - 建议在业务高峰期也进行监控，以获得更全面的数据"
        echo "   - 建议考虑未来业务增长，预留20-30%的资源余量"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "四、备注"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "本报告基于系统空闲时的资源使用情况生成。"
        echo "实际采购时，建议结合业务高峰期监控数据进行综合评估。"
        echo ""
        echo "##########################################################################"
    } > "$ltmp_report_file"
    
    # 同时输出到屏幕
    cat "$ltmp_report_file"
    
    echo ""
    echo "报告已保存至: $ltmp_report_file"
    echo ""
    
    LOG_message "灾备系统采购参考报告已生成: $ltmp_report_file" "INFO"
}

#################################################################################################
# 检查并安装监控工具(如果需要)
#################################################################################################
check_monitor_tools() {
    local ltmp_missing_tools=()
    
    # 检查基本工具
    if ! command -v bc >/dev/null 2>&1; then
        ltmp_missing_tools+=("bc")
    fi
    
    if ! command -v vmstat >/dev/null 2>&1; then
        ltmp_missing_tools+=("sysstat")
    fi
    
    if [ ${#ltmp_missing_tools[@]} -gt 0 ]; then
        echo "检测到缺少以下监控工具: ${ltmp_missing_tools[*]}"
        echo "建议安装命令: yum install -y ${ltmp_missing_tools[*]}"
        return 1
    fi
    
    echo "所有监控工具已就绪"
    return 0
}
