#!/bin/bash
set -euo pipefail

# 列出或显示 rollback 会话信息
# Usage: rollback_sessions.sh           # 列出最近会话及状态
#        rollback_sessions.sh --show ID  # 显示会话详细（operations.log + pending 列表）

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RDIR="${ROLLBACK_PREFIX:-${ROOT}/.rollback_data}"

if [[ ! -d "$RDIR" ]]; then
    echo "No rollback directory: $RDIR" >&2
    exit 0
fi

if [[ ${#@} -gt 0 && "$1" == "--show" ]]; then
    if [[ -z "${2:-}" ]]; then
        echo "Usage: $0 --show <sessionID>" >&2
        exit 2
    fi
    SID="$2"
    TX="$RDIR/$SID"
    if [[ ! -d "$TX" ]]; then
        echo "Session not found: $SID" >&2
        exit 1
    fi
    echo "Session: $SID"
    echo "Meta:"; sed -n '1,200p' "$TX/session.meta" 2>/dev/null || true
    echo
    echo "Operations log (tail 50):"
    sed -n '1,200p' "$TX/operations.log" 2>/dev/null | tail -n 50 || true
    echo
    echo "Pending entries:";
    if compgen -G "$TX/pending/*" >/dev/null; then
        for f in "$TX/pending"/*; do
            echo " - $(basename "$f") :"; sed -n '1,3p' "$f" | sed 's/^/    /';
        done
    else
        echo " (none)"
    fi
    exit 0
fi

echo "Available rollback sessions under: $RDIR"
for tx in "$RDIR"/*; do
    [[ -d "$tx" ]] || continue
    sid=$(basename "$tx")
    started="$(sed -n '1p' "$tx/session.meta" 2>/dev/null | sed -n 's/^started=//p' || true)"
    pending_count=0
    if compgen -G "$tx/pending/*" >/dev/null; then
        pending_count=$(ls -1 "$tx/pending" | wc -l)
    fi
    echo "$sid | started=${started:-unknown} | pending=${pending_count}"
done

echo
echo "Quick hint: show details -> $0 --show <sessionID>"
