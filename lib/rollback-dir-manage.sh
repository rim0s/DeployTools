#!/bin/bash
# rollback-dir-manage.sh

# 安全的目录创建
safe_mkdir() {
    local dir="$1"
    local op_id="mkdir_$(date +%s)_${RANDOM}"

    if [[ -d "$dir" ]]; then
        # 目录已存在，回滚时什么也不做
        register_operation "$op_id" "echo '目录已存在，无需回滚'" "mkdir noop"
        echo "$op_id"
        return 0
    fi

    # 记录回滚命令：删除目录
    register_operation "$op_id" "rmdir '$dir' 2>/dev/null || rm -rf '$dir'" "mkdir rollback: remove $dir"

    if mkdir -p "$dir"; then
        echo "$op_id: mkdir -p '$dir'" >> "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/operations.log"
        echo "$op_id"
        return 0
    else
        log_error "创建目录失败: $dir"
        return 1
    fi
}

# 安全的目录删除
safe_rmdir() {
    local dir="$1"
    local op_id="rmdir_$(date +%s)_${RANDOM}"

    if [[ ! -d "$dir" ]]; then
        # 目录不存在，回滚时什么也不做
        register_operation "$op_id" "echo '目录不存在，无需回滚'" "rmdir noop"
        echo "$op_id"
        return 0
    fi

    # 备份整个目录
    local backup_dir="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/dirbackup_$(basename "$dir")_${RANDOM}"
    if cp -rp "$dir" "$backup_dir"; then
        # 记录回滚命令：恢复目录
        register_operation "$op_id" "cp -rp '$backup_dir' '$dir'" "rmdir backup for $dir"

        if rm -rf "$dir"; then
            echo "$op_id: rm -rf '$dir'" >> "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/operations.log"
            echo "$op_id"
            return 0
        else
            log_error "删除目录失败: $dir"
            rm -rf "$backup_dir"
            return 1
        fi
    else
        log_error "无法备份目录: $dir"
        return 1
    fi
}