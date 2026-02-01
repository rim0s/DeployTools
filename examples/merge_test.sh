#!/bin/bash
set -euo pipefail

# 简单演示 merge 模式流程（用于本地测试）
root=$(mktemp -d)
echo "Using workspace: $root"

export ROLLBACK_PREFIX="$root/rollback_data"
mkdir -p "$ROLLBACK_PREFIX"

source "$(dirname "$0")/../lib/rollback-manager.sh"
source "$(dirname "$0")/../lib/rollback-file-ops.sh"
init_rollback_system "$ROLLBACK_PREFIX"

export ROLLBACK_ROLLBACK_CONFLICT_MODE=merge

# prepare source and target
mkdir -p "$root/src_dir/sub"
mkdir -p "$root/target_dir/sub"
echo "source content" > "$root/src_dir/sub/foo.txt"
echo "target different" > "$root/target_dir/sub/foo.txt"

echo "Running safe_cp -r (expect merge conflict)..."
opid=$(safe_cp -r "$root/src_dir" "$root/target_dir" 2>/dev/null || true)
rc=$?
echo "safe_cp rc=$rc opid=$opid"

merge_dir="$ROLLBACK_PREFIX/$TRANSACTION_ID/pending/${opid}.merge"
echo "Merge dir: $merge_dir"

echo "Listing conflicts:" 
$(dirname "$0")/../tools/merge-helper.sh --merge-dir "$merge_dir" list || true

echo "Diff for sub/foo.txt:" 
$(dirname "$0")/../tools/merge-helper.sh --merge-dir "$merge_dir" diff "sub/foo.txt" || true

echo "Applying ours for sub/foo.txt"
$(dirname "$0")/../tools/merge-helper.sh --merge-dir "$merge_dir" accept-ours "sub/foo.txt" "$root/target_dir"

echo "Now commit op"
op_commit "$opid"

echo "Verify target content:"
cat "$root/target_dir/sub/foo.txt"

echo "Test workspace retained at: $root"
