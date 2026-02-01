#!/bin/bash

# 安全的配置行修改
safe_sed_replace() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    local op_id="sed_$(date +%s)_${RANDOM}"
    
    # 1. 备份原文件
    local backup_file="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/$(basename "$file").backup"
    if ! cp -p "$file" "$backup_file"; then
        log_error "无法备份文件: $file"
        return 1
    fi
    
    # 2. 生成恢复补丁
    local patch_file="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/$(basename "$file").patch"
    # 创建反向diff
    cp -p "$file" "${backup_file}.new"
    sed -i "s|$pattern|$replacement|" "${backup_file}.new"
    diff -u "$backup_file" "${backup_file}.new" > "$patch_file" 2>/dev/null || true
    
    # 3. 记录回滚命令：应用反向补丁
    register_operation "$op_id" "patch -R '$file' < '$patch_file' 2>/dev/null || cp -p '$backup_file' '$file'" "sed replace in $(basename "$file")"
    
    # 4. 执行修改
    if sed -i "s|$pattern|$replacement|" "$file"; then
        echo "$op_id: sed '$pattern' -> '$replacement' in $file" >> "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/operations.log"
        echo "$op_id"
        return 0
    else
        log_error "sed修改失败: $file"
        return 1
    fi
}