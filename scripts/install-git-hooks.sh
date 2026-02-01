#!/usr/bin/env bash
set -euo pipefail

# 安装仓库本地 Git 钩子：将 core.hooksPath 指向 .githooks，并确保 pre-push 可执行
repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$repo_root" ]]; then
    echo "请在一个 git 仓库内运行此脚本" >&2
    exit 2
fi

cd "$repo_root"

if [[ ! -d ".githooks" ]]; then
    echo "未找到 .githooks 目录，确保仓库已包含 .githooks/pre-push" >&2
    exit 2
fi

git config core.hooksPath .githooks
chmod +x .githooks/pre-push || true

echo "已设置 core.hooksPath=.githooks 并使 .githooks/pre-push 可执行。" 
echo "注意：hooks 为本地配置（未受版本控制生效），但 .githooks 目录可以被跟踪并由团队成员通过运行本脚本启用。"
