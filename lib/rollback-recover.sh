#!/bin/bash
# rollback-recover.sh
# 扫描事务的 pending 条目并报告/处理

# 如果脚本被其他脚本以 source 方式加载，则不要执行下面的顶层逻辑。
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    return 0
fi

TXDIR="$1"
AUTO_COMMIT=0
if [[ "$1" == "--auto-commit" ]]; then
    AUTO_COMMIT=1
    TXDIR="$2"
fi

if [[ -z "$TXDIR" ]]; then
    echo "Usage: $0 [--auto-commit] /path/to/txdir"
    exit 2
fi

if [[ ! -d "$TXDIR" ]]; then
    echo "Transaction dir not found: $TXDIR"
    exit 1
fi

PENDING="$TXDIR/pending"
COMMITTED="$TXDIR/committed"

if [[ ! -d "$PENDING" ]]; then
    echo "No pending directory: $PENDING"
    exit 0
fi

echo "Scanning pending entries in: $PENDING"
shopt -s nullglob
for f in "$PENDING"/*; do
    name=$(basename "$f")
    echo "- Pending: $name"
    echo "  Content:"; sed -n '1,5p' "$f" | sed 's/^/    /'
    if [[ $AUTO_COMMIT -eq 1 ]]; then
        echo "  Auto-committing $name"
        mkdir -p "$COMMITTED"
        while IFS= read -r line; do
            printf '%s\n' "$line" >> "$TXDIR/operations.log"
        done < "$f"
        mv "$f" "$COMMITTED/"
    fi
done

if [[ $AUTO_COMMIT -eq 1 ]]; then
    echo "Auto-commit complete. See $TXDIR/operations.log"
fi

exit 0
