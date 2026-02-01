#!/bin/bash
set -euo pipefail
# 使用批次管理的复杂操作（通过 loader 加载所需模块）
_libdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
source "${_libdir}/loader.sh" 2>/dev/null || source ./lib/loader.sh

init_rollback_system

# 创建批次
batch1=$(begin_batch)
batch2=$(begin_batch)

log_info "批次1 ID: $batch1"
log_info "批次2 ID: $batch2"

# 批次1：文件操作
log_info "=== 执行批次1：文件操作 ==="
file_ops=()
file_ops+=("$(safe_cp '/etc/hosts' '/etc/hosts.backup')")
file_ops+=("$(safe_mv '/tmp/old.log' '/var/log/archive/old.log')")
file_ops+=("$(safe_cp './new_config.yaml' '/etc/app/config.yaml')")

# 添加到批次
add_to_batch "$batch1" "${file_ops[@]}"

# 批次2：服务操作
log_info "=== 执行批次2：服务操作 ==="
service_ops=()
service_ops+=("$(safe_service_restart 'app-service')")
service_ops+=("$(safe_sed_replace '/etc/app/config.yaml' 'debug: true' 'debug: false')")

add_to_batch "$batch2" "${service_ops[@]}"

# 验证批次2是否成功
if [[ ${#service_ops[@]} -lt 2 ]]; then
    log_warn "批次2操作失败，回滚批次2..."
    rollback_batch "$batch2"
    read -p "批次2失败，是否回滚批次1？[y/N]: " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        rollback_batch "$batch1"
    fi
    exit 1
fi

log_info "=== 所有操作成功 ==="