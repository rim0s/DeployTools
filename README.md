# ProjectManage - 模块化Linux项目管理脚本

## 概述

本项目是对原 `ProjectManage_V48.sh` 脚本的模块化重构。原脚本包含7542行代码，功能完整但难以维护。经过模块化拆分后，代码结构更清晰，便于开发、测试、维护和扩展。

## 目录结构

```
ProjectManage/
├── lib/                    # 功能模块目录
│   ├── constants.sh       # 常量定义（颜色、版本、Banner等）
│   ├── config.sh          # 全局变量配置
│   ├── utils.sh           # 工具函数
│   ├── logger.sh          # 日志功能模块
│   ├── sudo.sh            # sudo执行功能模块
│   ├── banner.sh          # Banner显示模块
│   ├── firewall.sh        # 防火墙功能模块
│   ├── init.sh            # 初始化模块
│   └── loader.sh          # 模块加载器
├── projects/              # 项目特定功能目录
├── main.sh                # 主程序入口（待创建）
└── README.md              # 本文件
```

## 模块说明

### 1. constants.sh - 常量定义模块
- 版本信息
- 颜色常量
- Banner base64编码内容
- 日志级别颜色映射

### 2. config.sh - 全局变量配置模块
- 脚本基础信息
- 路径配置
- 功能开关
- 系统信息
- 防火墙相关变量
- 服务配置变量

### 3. utils.sh - 工具函数模块
- 字符串处理函数（trim等）
- 随机字符串生成
- 终端响铃函数
- 中文支持检查

### 4. logger.sh - 日志功能模块
- 日志初始化
- 调用链追踪
- 多种日志输出函数：
  - `log_message` - 同时输出到屏幕和文件
  - `LOG_message` - 仅写入文件（trace模式下输出屏幕）
  - `LOG_line` - 仅写入文件
  - `log_MESSAGE` - 仅输出到屏幕

### 5. sudo.sh - sudo执行功能模块
- `sudo_execute` - 标准sudo执行
- `sudo_execute_gui` - GUI环境下的sudo执行
- `sudo_execute_` - 返回输出的sudo执行
- `sudo_execute_quiet` - 安静模式sudo执行
- `sudo_execute_once` - 执行后立即终止sudo认证
- `unsudo_execute` - 非sudo执行

### 6. banner.sh - Banner显示模块
- `show_banner` - 主Banner显示函数
- `show_banner_base64` - Base64编码Banner显示
- `show_banner_ascii` - ASCII艺术Banner显示
- `show_tail` - 结束Banner显示

### 7. firewall.sh - 防火墙功能模块
- `is_firewalld_active` - 检查firewalld是否激活
- `is_iptables_active` - 检查iptables是否激活
- `get_active_firewall` - 获取当前激活的防火墙类型
- `add_firewall_ports` - 添加防火墙端口
- `remove_firewall_ports` - 删除防火墙端口
- `add_icmp_reply_block_rule` - 添加ICMP屏蔽规则
- `remove_icmp_reply_block_rule` - 删除ICMP屏蔽规则

### 8. init.sh - 初始化模块
- `init_tmp` - 初始化临时目录
- `init_the_batch` - 初始化脚本环境
- `end_the_batch` - 清理和结束脚本

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
2025-11-09 15:30  由 Cursor 对 ProjectManage.sh的第48版进行了模块化拆分。
                  暂未测试。
                  下一步先阅读和比对，确保逻辑完整无遗漏。