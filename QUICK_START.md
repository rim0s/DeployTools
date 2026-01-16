# 快速开始指南

## 模块化脚本使用指南

### 1. 基本使用

在其他脚本中引用模块化功能：

```bash
#!/bin/bash

# 加载所有模块
source "./lib/loader.sh"

# 初始化
init_the_batch "$@"

# 使用日志功能
log_message "脚本开始执行" "INFO"

# 使用sudo功能
sudo_execute "systemctl status firewalld"

# 使用防火墙功能
GLOBAL_PORT_LIST='"8080 8443"'
add_firewall_ports "tcp" "public"

# 清理和结束
end_the_batch
```

### 2. 按需加载模块

如果只需要部分功能，可以按需加载：

```bash
#!/bin/bash

# 只加载需要的模块
source "./lib/constants.sh"
source "./lib/config.sh"
source "./lib/logger.sh"

# 使用日志功能
log_message "这是一条日志" "INFO"
```

### 3. 常用功能示例

#### 日志记录
```bash
source "./lib/loader.sh"

log_message "普通信息" "INFO"
log_message "警告信息" "WARNING"
log_message "错误信息" "ERROR"
LOG_message "仅写入日志文件" "INFO"
log_MESSAGE "仅输出到屏幕" "INFO"
```

#### sudo执行
```bash
source "./lib/loader.sh"

# 标准sudo执行
sudo_execute "yum install -y package_name"

# GUI环境下的sudo执行
sudo_execute_gui "systemctl restart service_name"

# 获取命令输出
sudo_execute_ "firewall-cmd --list-ports"
echo "端口列表: $SUDO_EXECUTE__OUTPUT"
```

#### 防火墙操作
```bash
source "./lib/loader.sh"

# 检查防火墙类型
firewall_type=$(get_active_firewall)
echo "当前防火墙: $firewall_type"

# 添加端口
GLOBAL_PORT_LIST='"8080 8443 3306"'
add_firewall_ports "tcp" "public"

# 删除端口
GLOBAL_PORT_LIST_TO_REMOVE='"8080"'
remove_firewall_ports "tcp" "public"
```

### 4. 模块说明

- **constants.sh** - 常量定义，无需单独加载，会被其他模块自动加载
- **config.sh** - 全局变量配置，通常需要首先加载
- **logger.sh** - 日志功能，提供多种日志输出函数
- **sudo.sh** - sudo执行功能，提供多种sudo执行方式
- **firewall.sh** - 防火墙功能，支持firewalld和iptables
- **banner.sh** - Banner显示功能
- **init.sh** - 初始化功能，提供初始化和清理函数
- **utils.sh** - 工具函数，提供常用工具函数

### 5. 注意事项

1. **模块加载顺序**：确保按照依赖关系加载模块
2. **变量作用域**：全局变量使用 `this_` 前缀
3. **错误处理**：重要操作应检查返回值
4. **日志记录**：重要操作应记录日志

### 6. 故障排除

如果遇到模块加载问题：

1. 检查文件路径是否正确
2. 检查文件权限是否可执行
3. 检查模块依赖是否正确加载
4. 查看日志文件了解详细错误信息

日志文件位置：`~/.LOG/${脚本名}_LOG/`
