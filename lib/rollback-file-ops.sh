#!/bin/bash

# 配置（可由外部覆盖）
: ${ROLLBACK_VERIFY_CHECKSUM:=true}
: ${ROLLBACK_DIR_VERIFY_CHECKSUM:=${ROLLBACK_VERIFY_CHECKSUM}}
: ${ROLLBACK_LARGE_FILE_THRESHOLD_BYTES:=52428800} # 50MB
: ${ROLLBACK_ROLLBACK_CONFLICT_MODE:=skip} # overwrite|merge|skip

# helper: 生成 sha256 校验
compute_checksum() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo ""
        return 1
    fi
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum --binary "$file" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | awk '{print $1}'
    else
        # fallback: use md5sum if available (less ideal)
        if command -v md5sum >/dev/null 2>&1; then
            md5sum "$file" | awk '{print $1}'
        else
            echo ""
            return 1
        fi
    fi
}

# 强制分别计算 sha256 与 md5（尽可能使用系统可用工具）
compute_sha256() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo ""
        return 1
    fi
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum --binary "$file" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | awk '{print $1}'
    else
        echo ""
        return 1
    fi
}

compute_md5() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo ""
        return 1
    fi
    if command -v md5sum >/dev/null 2>&1; then
        md5sum "$file" | awk '{print $1}'
    elif command -v md5 >/dev/null 2>&1; then
        md5 -q "$file" 2>/dev/null || echo ""
    else
        echo ""
        return 1
    fi
}

# helper: 判断文件是否大于阈值
is_large_file() {
    local file="$1"
    local size
    size=$(stat -c %s -- "$file" 2>/dev/null || echo 0)
    if (( size > ROLLBACK_LARGE_FILE_THRESHOLD_BYTES )); then
        return 0
    fi
    return 1
}

# 生成目录 manifest（TSV: relpath\tsize\tmtime\tchecksum）
generate_manifest() {
    local srcdir="$1"
    local manifest_out="$2"
    local base_len=${#srcdir}
    : >"$manifest_out"
    find "$srcdir" -type f -print0 | while IFS= read -r -d '' f; do
        local rel="${f:$((base_len + 1))}"
        local size mtime checksum
        size=$(stat -c %s -- "$f" 2>/dev/null || echo 0)
        mtime=$(stat -c %Y -- "$f" 2>/dev/null || echo 0)
        checksum=""
        if [[ "$ROLLBACK_DIR_VERIFY_CHECKSUM" == "true" ]]; then
            if ! is_large_file "$f"; then
                checksum=$(compute_checksum "$f" 2>/dev/null || echo "")
            fi
        fi
        printf "%s\t%s\t%s\t%s\n" "$rel" "$size" "$mtime" "$checksum" >>"$manifest_out"
    done
}

# verify manifest against target dir; writes mismatches to second arg (optional)
# optional 4th arg: src_dir (used when merge handling to create .ours)
verify_manifest() {
    local manifest="$1"
    local target_dir="$2"
    local mismatches_file="$3"
    local src_dir="$4"
    : >"${mismatches_file:-/dev/null}"
    local ok=0
    while IFS=$'\t' read -r rel size mtime checksum; do
        local tgt="$target_dir/$rel"
        if [[ ! -e "$tgt" ]]; then
            echo "MISSING: $rel" >>"${mismatches_file:-/dev/null}"; ok=1; continue
        fi
        local tgt_size tgt_mtime
        tgt_size=$(stat -c %s -- "$tgt" 2>/dev/null || echo 0)
        tgt_mtime=$(stat -c %Y -- "$tgt" 2>/dev/null || echo 0)
        if [[ "$tgt_size" != "$size" ]]; then
            echo "SIZE_MISMATCH: $rel (expected $size got $tgt_size)" >>"${mismatches_file:-/dev/null}"; ok=1; continue
        fi
        if [[ -n "$checksum" ]]; then
            local tgt_checksum
            tgt_checksum=$(compute_checksum "$tgt" 2>/dev/null || echo "")
            if [[ "$tgt_checksum" != "$checksum" ]]; then
                echo "CHECKSUM_MISMATCH: $rel" >>"${mismatches_file:-/dev/null}"; ok=1; continue
            fi
        fi
    done <"$manifest"
    return $ok
}

# 判断是否同一文件系统（device）
is_same_filesystem() {
    local a="$1" b="$2"
    local da db
    da=$(df -P "$a" 2>/dev/null | tail -1 | awk '{print $1}')
    db=$(df -P "$b" 2>/dev/null | tail -1 | awk '{print $1}')
    if [[ "$da" == "$db" ]]; then
        return 0
    fi
    return 1
}

# 获取路径所在文件系统可用字节数
available_space_on_fs() {
    local path="$1"
    df -P -B1 "$path" 2>/dev/null | tail -1 | awk '{print $4}'
}

# 估算目录或文件大小（字节）
estimate_size_bytes() {
    local path="$1"
    if [[ -d "$path" ]]; then
        if command -v du >/dev/null 2>&1; then
            du -sb "$path" 2>/dev/null | awk '{print $1}'
        else
            echo 0
        fi
    elif [[ -f "$path" ]]; then
        stat -c %s -- "$path" 2>/dev/null || echo 0
    else
        echo 0
    fi
}

# 评估是否有足够空间把数据备份到 target_backup_root
# 返回 0=足够, 1=不够
check_space_for_operation() {
    local src="$1" backup_root_path="$2"
    local required
    required=$(estimate_size_bytes "$src")
    # 预留 10% 余量
    required=$((required + required / 10))
    local avail
    avail=$(available_space_on_fs "$backup_root_path" 2>/dev/null || echo 0)
    if [[ -z "$avail" ]]; then
        return 1
    fi
    if (( avail >= required )); then
        return 0
    fi
    return 1
}

# internal helper: ensure transaction dirs
_ensure_tx_dirs() {
    mkdir -p "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending" "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/committed" "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/backups"
}

# 安全的复制，支持文件与目录（-r）
safe_cp() {
    local recursive=0
    local OPTIND=1
    while getopts ":r" opt; do
        case "$opt" in
            r) recursive=1 ;;
            *) break ;;
        esac
    done
    shift $((OPTIND -1))
    local src="$1" dst="$2"
    if [[ -z "$src" || -z "$dst" ]]; then
        log_error "safe_cp 用法: safe_cp [-r] <src> <dst>"
        return 1
    fi
    if [[ ! -e "$src" ]]; then
        log_error "源不存在: $src"
        return 1
    fi
    _ensure_tx_dirs

    # 目录处理
    if [[ -d "$src" ]] || [[ $recursive -eq 1 ]]; then
        # 强制为目录操作
        if [[ -f "$src" && $recursive -eq 1 ]]; then
            log_warn "源是文件但使用 -r，继续按目录处理"
        fi
        local opid backupdir manifest tmpmismatch
        backupdir="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/backups/backup_$(basename "$dst")_${RANDOM}"
        mkdir -p "$backupdir"

        # 评估备份空间
        local do_full_backup=1
        if ! check_space_for_operation "$src" "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/backups"; then
            do_full_backup=0
            log_warn "备份空间不足，将以 manifest-only 模式处理（不复制完整目标）: $dst"
        fi

        # 如果目标存在且允许全备份，尝试原子移动到备份（快速）；如果失败，复制后删除
        if [[ -e "$dst" ]]; then
            if [[ $do_full_backup -eq 1 ]]; then
                if mv "$dst" "$backupdir" 2>/dev/null; then
                    log_info "目标移动到备份: $dst -> $backupdir"
                else
                    if cp -a "$dst" "$backupdir"; then
                        rm -rf "$dst"
                        log_info "目标复制到备份: $dst -> $backupdir"
                    else
                        log_error "无法备份目标目录: $dst"
                        rmdir "$backupdir" 2>/dev/null || true
                        return 1
                    fi
                fi
            else
                log_info "跳过对目标的完整备份（空间受限）: $dst"
            fi
        fi

        # 预写 rollback（记录如何恢复备份）
        local rollback_cmd
        rollback_cmd="rm -rf '$dst'"
        if [[ -e "$backupdir" && $(ls -A "$backupdir" 2>/dev/null | wc -l) -gt 0 ]]; then
            rollback_cmd+=" && mv '$backupdir' '$dst'"
        fi
        opid=$(op_prewrite "" "$rollback_cmd" "restore directory $dst from backup")

        # 复制操作
        if cp -a "$src" "$dst"; then
            # 生成 manifest 并校验
            tmpmismatch=$(mktemp)
            local manifest_file="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/${opid}.manifest"
            generate_manifest "$src" "$manifest_file"
            if verify_manifest "$manifest_file" "$dst" "$tmpmismatch" "$src"; then
                op_commit "$opid" || log_warn "op_commit 失败: $opid"
                rm -f "$tmpmismatch"
                echo "$opid"
                return 0
            else
                # 校验失败 -> 根据冲突策略处理
                if [[ "$ROLLBACK_ROLLBACK_CONFLICT_MODE" == "merge" ]]; then
                    # 生成合并报告和 .ours/.theirs 副本（存在于 pending 下）
                    local merge_dir="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/${opid}.merge"
                    mkdir -p "$merge_dir"
                    local report_file="$merge_dir/merge-report.txt"
                    echo "Merge report for op $opid" >"$report_file"
                    while IFS= read -r line; do
                        # 行格式可能是 TYPE: rel ...，提取相对路径
                        rel=$(echo "$line" | awk '{print $2}')
                        # create dirs
                        mkdir -p "$merge_dir/$(dirname "$rel")"
                        mkdir -p "$(dirname "$merge_dir/$rel.theirs")"
                        # copy theirs (current target)
                        if [[ -e "$dst/$rel" ]]; then
                            cp -p "$dst/$rel" "$merge_dir/$rel.theirs" 2>/dev/null || true
                        fi
                        # copy ours (source)
                        if [[ -e "$src/$rel" ]]; then
                            cp -p "$src/$rel" "$merge_dir/$rel.ours" 2>/dev/null || true
                        fi
                        echo "$line" >>"$report_file"
                    done <"$tmpmismatch"
                    log_warn "目录校验发现冲突，生成合并报告: $report_file"
                    rm -f "$tmpmismatch"
                    echo "$opid"
                    return 2
                else
                    log_error "目录校验失败，见 $tmpmismatch"
                    # 尝试恢复（调用预写命令）
                    rollback_operation "$opid"
                    cat "$tmpmismatch" >&2
                    rm -f "$tmpmismatch"
                    return 1
                fi
            fi
        else
            log_error "复制目录失败: $src -> $dst"
            rollback_operation "$opid"
            return 1
        fi
    fi

    # 普通文件处理
    local backup_file=""
    if [[ -e "$dst" ]]; then
        backup_file="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/backups/backup_$(basename "$dst")_${RANDOM}"
        if ! cp -p "$dst" "$backup_file"; then
            log_error "无法备份目标文件: $dst"
            return 1
        fi
    fi

    # 预写 rollback
    local op_id
    local restore_cmd
    if [[ -n "$backup_file" ]]; then
        restore_cmd="mv '$backup_file' '$dst'"
    else
        restore_cmd="rm -f '$dst'"
    fi
    op_id=$(op_prewrite "" "$restore_cmd" "restore backup for $dst")

    if cp -p "$src" "$dst"; then
        # 单文件强制双哈希校验（sha256 + md5）
        local s_sha s_md d_sha d_md
        s_sha=$(compute_sha256 "$src" 2>/dev/null || echo "")
        s_md=$(compute_md5 "$src" 2>/dev/null || echo "")
        d_sha=$(compute_sha256 "$dst" 2>/dev/null || echo "")
        d_md=$(compute_md5 "$dst" 2>/dev/null || echo "")
        if [[ -z "$s_sha" || -z "$s_md" || -z "$d_sha" || -z "$d_md" ]]; then
            log_error "无法计算必要的哈希值（需要 sha256 与 md5 工具），取消操作: $src -> $dst"
            rollback_operation "$op_id"
            return 1
        fi
        if [[ "$s_sha" != "$d_sha" || "$s_md" != "$d_md" ]]; then
            log_error "复制后双哈希校验失败: $src -> $dst"
            rollback_operation "$op_id"
            return 1
        fi
        op_commit "$op_id" || log_warn "op_commit 失败: $op_id"
        echo "$op_id"
        return 0
    else
        log_error "复制失败: $src -> $dst"
        [[ -n "$backup_file" ]] && mv "$backup_file" "$dst" 2>/dev/null || rm -f "$backup_file"
        rollback_operation "$op_id" 2>/dev/null || true
        return 1
    fi
}

# 安全的移动，支持目录递归（-r）
safe_mv() {
    local recursive=0
    local OPTIND=1
    while getopts ":r" opt; do
        case "$opt" in
            r) recursive=1 ;;
            *) break ;;
        esac
    done
    shift $((OPTIND -1))
    local src="$1" dst="$2"
    if [[ -z "$src" || -z "$dst" ]]; then
        log_error "safe_mv 用法: safe_mv [-r] <src> <dst>"
        return 1
    fi
    if [[ ! -e "$src" ]]; then
        log_error "源不存在: $src"
        return 1
    fi
    _ensure_tx_dirs

    # 目录移动
    if [[ -d "$src" ]] || [[ $recursive -eq 1 ]]; then
        local opid backupdir manifest tmpmismatch
        backupdir="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/backups/backup_mv_$(basename "$src")_${RANDOM}"
        mkdir -p "$backupdir"

        # 如果目标存在，备份目标
        if [[ -e "$dst" ]]; then
            if mv "$dst" "$backupdir" 2>/dev/null; then
                log_info "目标移动到备份: $dst -> $backupdir"
            else
                if cp -a "$dst" "$backupdir"; then
                    rm -rf "$dst"
                    log_info "目标复制到备份: $dst -> $backupdir"
                else
                    log_error "无法备份目标目录: $dst"
                    rmdir "$backupdir" 2>/dev/null || true
                    return 1
                fi
            fi
        fi

        # 对于 src，如果是同一文件系统，使用 mv（快速且无需复制备份）；否则先复制 src 到备份以便回滚
        local need_src_backup=1
        if is_same_filesystem "$src" "$dst"; then
            need_src_backup=0
        fi
        # 评估是否有足够空间备份源（仅在需要时）
        if [[ $need_src_backup -eq 1 ]]; then
            if check_space_for_operation "$src" "${ROLLBACK_PREFIX}/${TRANSACTION_ID}/backups"; then
                if ! cp -a "$src" "$backupdir/src_backup"; then
                    log_error "无法为跨设备移动备份源: $src"
                    return 1
                fi
            else
                log_warn "备份空间不足，跨设备移动不会创建完整源备份（风险提示）"
                need_src_backup=0
            fi
        fi

        # 预写 rollback：若需要恢复则还原备份
        local rollback_cmd
        rollback_cmd="rm -rf '$dst'"
        if [[ -d "$backupdir/src_backup" ]]; then
            rollback_cmd+=" && mv '$backupdir/src_backup' '$src'"
        fi
        if [[ -e "$backupdir" && $(ls -A "$backupdir" 2>/dev/null | wc -l) -gt 0 ]]; then
            rollback_cmd+=" && mv '$backupdir' '$dst' || true"
        fi
        opid=$(op_prewrite "" "$rollback_cmd" "restore move $src <- $dst")

        # 执行移动（尝试 mv，否则 cp+rm）
        if mv "$src" "$dst" 2>/dev/null; then
            # mv 成功
            op_commit "$opid" || log_warn "op_commit 失败: $opid"
            echo "$opid"
            return 0
        else
            # 跨设备：用 cp -a 然后删除源
            # 在执行复制前生成 manifest 并在复制后校验
            manifest_file="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/${opid}.manifest"
            generate_manifest "$src" "$manifest_file"
            tmpmismatch=$(mktemp)
            if cp -a "$src" "$dst"; then
                if verify_manifest "$manifest_file" "$dst" "$tmpmismatch" "$src"; then
                    if rm -rf "$src"; then
                        op_commit "$opid" || log_warn "op_commit 失败: $opid"
                        rm -f "$tmpmismatch"
                        echo "$opid"
                        return 0
                    else
                        log_error "移动后删除源失败: $src"
                        rollback_operation "$opid"
                        rm -f "$tmpmismatch"
                        return 1
                    fi
                else
                    if [[ "$ROLLBACK_ROLLBACK_CONFLICT_MODE" == "merge" ]]; then
                        local merge_dir="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/pending/${opid}.merge"
                        mkdir -p "$merge_dir"
                        local report_file="$merge_dir/merge-report.txt"
                        echo "Merge report for op $opid" >"$report_file"
                        while IFS= read -r line; do
                            rel=$(echo "$line" | awk '{print $2}')
                            mkdir -p "$merge_dir/$(dirname "$rel")"
                            if [[ -e "$dst/$rel" ]]; then
                                cp -p "$dst/$rel" "$merge_dir/$rel.theirs" 2>/dev/null || true
                            fi
                            if [[ -e "$src/$rel" ]]; then
                                cp -p "$src/$rel" "$merge_dir/$rel.ours" 2>/dev/null || true
                            fi
                            echo "$line" >>"$report_file"
                        done <"$tmpmismatch"
                        log_warn "目录移动校验发现冲突，生成合并报告: $report_file"
                        rm -f "$tmpmismatch"
                        echo "$opid"
                        return 2
                    else
                        log_error "目录移动校验失败，见 $tmpmismatch"
                        rollback_operation "$opid"
                        cat "$tmpmismatch" >&2
                        rm -f "$tmpmismatch"
                        return 1
                    fi
                fi
            else
                log_error "移动失败: $src -> $dst"
                rollback_operation "$opid"
                rm -f "$tmpmismatch"
                return 1
            fi
        fi
    fi

    # 文件移动（非目录）
    local backup_file dst_backup op_id
    if [[ -f "$src" ]]; then
        if [[ -e "$dst" ]]; then
            dst_backup="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/backups/dst_backup_$(basename "$dst")_${RANDOM}"
            if ! cp -p "$dst" "$dst_backup"; then
                log_warn "无法备份目标文件（非致命）: $dst"
                dst_backup=""
            fi
        fi

        # 备份源以便回滚（跨设备时可用）
        backup_file="${ROLLBACK_PREFIX}/${TRANSACTION_ID}/backups/src_backup_$(basename "$src")_${RANDOM}"
        if ! cp -p "$src" "$backup_file"; then
            log_error "无法备份源文件: $src"
            return 1
        fi

        # 预写 rollback
        local restore_cmd
        restore_cmd="mv '$backup_file' '$src'"
        if [[ -n "$dst_backup" ]]; then
            restore_cmd+=" && mv '$dst_backup' '$dst'"
        else
            restore_cmd+=" && rm -f '$dst'"
        fi

        # 在执行移动前计算源文件哈希，以便在移动后对比（单文件强制双哈希校验）
        local s_sha s_md d_sha d_md
        s_sha=$(compute_sha256 "$src" 2>/dev/null || echo "")
        s_md=$(compute_md5 "$src" 2>/dev/null || echo "")

        op_id=$(op_prewrite "" "$restore_cmd" "restore mv for $src <- $dst")

        if mv "$src" "$dst"; then
            # 移动后校验目标文件哈希
            d_sha=$(compute_sha256 "$dst" 2>/dev/null || echo "")
            d_md=$(compute_md5 "$dst" 2>/dev/null || echo "")
            if [[ -z "$s_sha" || -z "$s_md" || -z "$d_sha" || -z "$d_md" ]]; then
                log_error "无法计算必要的哈希值（需要 sha256 与 md5 工具），取消操作: $src -> $dst"
                rollback_operation "$op_id"
                return 1
            fi
            if [[ "$s_sha" != "$d_sha" || "$s_md" != "$d_md" ]]; then
                log_error "移动后双哈希校验失败: $src -> $dst"
                rollback_operation "$op_id"
                return 1
            fi
            op_commit "$op_id" || log_warn "op_commit 失败: $op_id"
            echo "$op_id"
            return 0
        else
            log_error "移动失败: $src -> $dst"
            rollback_operation "$op_id"
            return 1
        fi
    fi

    log_error "safe_mv: 未知情况: $src -> $dst"
    return 1
}