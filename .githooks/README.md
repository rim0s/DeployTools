# .githooks/pre-push

本仓库提供一个可选的 pre-push 钩子，用于在推送到 GitHub（remote URL 中包含 `github.com`）时阻止包含敏感配置文件（例如 `*.conf`、`*.ini` 或特定文件 `etc/rollback_example.conf`）的提交。

使用说明：
- 在仓库根目录运行 `scripts/install-git-hooks.sh`，该脚本会把 `core.hooksPath` 指向本目录并设置 `pre-push` 为可执行。
- 钩子逻辑仅在本地生效（hooks 目录通常是本地配置），因此推荐把 `.githooks` 目录纳入版本控制，团队成员可通过运行安装脚本来启用相同的本地钩子。

如需放宽/修改限制规则，请编辑 `.githooks/pre-push` 中的 `forbidden_patterns` 数组。
