# ProjectManage - 模块化Linux项目管理脚本

## 概述

本项目对原 `ProjectManage_V48.sh`（7542 行）进行模块化重构，拆分为可维护的功能模块。项目主入口为项目根目录的 `ProjectManage.sh`（包含 main）。README 中提到的 `main.sh` 是留给使用者基于本框架自定义的示例入口文件。

## 目录结构

```
ProjectManage/
├── ProjectManage.sh        # 主函数入口（本项目实际运行入口）
├── lib/                    # 功能模块目录
│   ├── 基础与工具: constants.sh, config.sh, utils.sh, logger.sh, banner.sh, sudo.sh, firewall.sh, init.sh, loader.sh
│   ├── 网络与包管理: network.sh, package.sh, package_advanced.sh, path.sh
│   ├── 配置解析: config_file.sh, parser.sh
│   ├── 项目任务: project.sh
│   ├── 服务与系统: nfs.sh, vnc.sh, httpd.sh, security.sh, device.sh, system.sh
│   └── 其他: monitor.sh, help.sh, debug.sh, constants.sh 等
├── history_release/        # 历史版本
├── docs/                   # 文档
└── README.md               # 本文件
```

## 模块说明与函数清单（未测试标记仅针对今日新增模块）

### 基础与通用
- **constants.sh**: 颜色常量、版本信息、Banner 编码、日志级别映射
- **config.sh**: 全局变量、路径、开关、系统/防火墙/服务配置
- **utils.sh**: 字符串处理、随机串、终端响铃、中文检测
- **logger.sh**: `log_message`/`LOG_message`/`LOG_line`/`log_MESSAGE`、调用链追踪、日志初始化
- **sudo.sh**: `sudo_execute`/`sudo_execute_gui`/`sudo_execute_quiet`/`sudo_execute_once`/`unsudo_execute`
- **banner.sh**: `show_banner`/`show_banner_base64`/`show_banner_ascii`/`show_tail`
- **firewall.sh**: `is_firewalld_active`/`is_iptables_active`/`get_active_firewall`/`add_firewall_ports`/`remove_firewall_ports`/`add_icmp_reply_block_rule`/`remove_icmp_reply_block_rule`
- **init.sh**: `init_tmp`/`init_the_batch`/`end_the_batch`
- **loader.sh**: 模块加载器
- **debug.sh**: `bp`/`breakpoint`/`run_command`/`end_debug`（调试辅助）

### 网络与包管理
- **network.sh**: `check_internet`/`check_intranet_ip`/`check_connectivity`/`get_all_ip`
- **package.sh**: 基础包管理封装
- **package_advanced.sh**: `check_Package_installed`/`check_packages_installed`/`install_package`/`dnf_install_packages`
- **path.sh**: `check_path_available`/`make_s_ln`/`create_directory`/`create_directory_gui`

### 配置解析与参数处理
- **config_file.sh**: `extract_item_grep`/`extract_item_sed`/`extract_item_awk`/`read_ini_file`/`write_ini_file`
- **parser.sh**: `parse_short_options`/`parse_long_options`/`main_planB`

### 项目任务
- **project.sh**: `PJ_1234`/`PJ_5678`/`PJ_20241128`/`PJ_set_new_fedora_workstation`/`test_batch`

### 2026-01-17 新增系统管理模块（由AI拆分，状态：未测试）
- **nfs.sh**: NFS 共享管理
  - `empty_nfs_exports`/`nfs_share_usage`/`set_dir_2_nfs`/`remove_nfs_config`/`mount_nfs`/`mount_nfs_with_zenity`
- **vnc.sh**: X11VNC 远程桌面
  - `setup_x11vnc_server_usage`/`setup_x11vnc_server`/`setup_x11vnc_server_new`
- **httpd.sh**: Apache HTTP 服务
  - `start_my_httpd_usage`/`get_site_directories`/`start_my_httpd`/`stop_my_httpd_usage`/`stop_my_httpd`/`py_install`
- **security.sh**: 安全配置
  - `change_sshd_port`/`lock_user_randomly`/`unlock_user`/`project_set_user_never_expiration`/`project_set_record_his_with_datetime`/`add_ntp_server`
- **device.sh**: 设备挂载
  - `mount_new_device_usage`/`mount_new_device`/`wait_for_input_2_exit`

### 2026-01-17 新增V48遗留功能模块（由AI拆分，状态：未测试）
- **config_file_v48_legacy.sh**: 配置文件读写（V48旧版实现）
  - `write_conf_file_old`/`get_item_from_conf`/`write_conf_file`（legacy版）
- **class_file_v48_legacy.sh**: 类文件写入（V48旧版实现）
  - `write_class_file_`（未优化版）/`write_class_file_Modifing`（改进中版）/`write_class_file_error`（失败版保留）
- **media_tools_v48.sh**: 媒体与校验工具
  - `generate_verification_code`（验证码生成与校验）/`find_pic`（图片筛选与操作）
- **misc_legacy_v48.sh**: 杂项功能
  - `start_x_virtual_shell`（模拟交互shell）/`bash_description`（功能描述）/`process_file`（文件处理示例）
- **system_boot.sh**: 引导与虚拟化信息
  - `which_bootfirmware`（检测UEFI/BIOS）/`list_grub_entries`（列举GRUB条目）/`list_support_vmtech`（虚拟化技术支持）

### 其他现有模块
- **system.sh**: 系统信息/操作封装、`backup_and_log`备份功能
- **monitor.sh**: 系统资源监控
- **help.sh**: 使用说明与帮助信息

## 使用方法

### 在其他脚本中引用模块

```bash
#!/bin/bash

# 方式1：使用loader.sh加载所有模块
source "$(dirname "$0")/lib/loader.sh"

# 方式2：按需加载特定模块
source "$(dirname "$0")/lib/constants.sh"
source "$(dirname "$0")/lib/config.sh"
source "$(dirname "$0")/lib/logger.sh"
source "$(dirname "$0")/lib/sudo.sh"

# 使用模块功能
log_message "这是一条日志信息" "INFO"
sudo_execute "systemctl status firewalld"
```

### 添加防火墙端口示例

```bash
#!/bin/bash
source "./lib/loader.sh"

# 设置要添加的端口
GLOBAL_PORT_LIST='"8080 8443 3306"'

# 添加TCP端口到public区域
add_firewall_ports "tcp" "public"
```

### 使用日志功能示例

```bash
#!/bin/bash
source "./lib/loader.sh"

# 记录不同级别的日志
log_message "普通信息" "INFO"
log_message "警告信息" "WARNING"
log_message "错误信息" "ERROR"
log_message "调试信息" "DEBUG"

# 仅写入日志文件
LOG_message "仅写入日志" "INFO"

# 仅输出到屏幕
log_MESSAGE "仅输出屏幕" "INFO"
```

## 开发指南

### 添加新模块

1. 在 `lib/` 目录下创建新的 `.sh` 文件
2. 在文件开头添加模块说明和依赖加载
3. 在 `loader.sh` 中添加模块加载语句
4. 更新本README文档

### 模块依赖规则

- 基础模块（constants.sh, config.sh）不应依赖其他模块
- 工具模块（utils.sh, logger.sh）可以依赖基础模块
- 功能模块（firewall.sh, sudo.sh）可以依赖工具模块和基础模块
- 避免循环依赖

### 变量命名规范

- 全局变量：使用 `this_` 前缀
- 局部变量：使用 `ltmp_` 前缀，并使用 `local` 声明
- 常量：使用 `readonly` 声明，全大写

### 函数命名规范

- 使用小写字母和下划线
- 函数名应清晰描述功能
- 私有函数可以使用 `_` 前缀

## 测试

每个模块都可以独立测试。建议为每个模块编写测试脚本。

## 兼容性

- 支持 Bash 4.0+
- 支持 Fedora/CentOS/RHEL
- 支持 firewalld 和 iptables

## 许可证

本项目遵循原脚本的许可证。

## 贡献

欢迎提交Issue和Pull Request来改进本项目。

## 联系方式

- Mail: 
- 作者: rim0s-team ( Deepseek, copilot, Cursor, rim0s )  


##  History
2026-01-17        由 AI 完成剩余模块拆分（第二批）：
                  - 新增 V48 遗留功能模块5个：config_file_v48_legacy、class_file_v48_legacy、media_tools_v48、misc_legacy_v48、system_boot（状态：未测试）
                  - 更新 loader.sh 追加所有新模块加载，按时间和类型分组注释
                  - 更新 README 补充新增模块清单
2026-01-17        由 AI 拆分新增模块（第一批）：
                  - 核心模块7个：debug、network、package_advanced、path、config_file、parser、project
                  - 系统管理模块5个：nfs、vnc、httpd、security、device（状态：未测试）
                  - 同步更新 README，补充模块清单与函数说明
2025-11-09 15:30  由 Cursor 对 ProjectManage.sh 的第48版进行了模块化拆分。
                  暂未测试。
                  下一步先阅读和比对，确保逻辑完整无遗漏。