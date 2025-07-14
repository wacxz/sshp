# SSHP - SSH 配置管理工具

SSHP 是一个简单而强大的 SSH 配置管理工具，它允许你通过 YAML 配置文件管理多个 SSH 连接，并提供简单的命令行界面来连接到这些主机。

## 功能特点

- 通过 YAML 文件管理多个 SSH 连接配置
- 支持按组织结构管理主机
- 自动使用保存的凭据连接到主机
- 支持默认配置和主机特定配置
- 简单直观的命令行界面

## 安装

1. 确保你已安装 `yq` 工具：
   ```
   # 使用 brew 安装（macOS）
   brew install yq
   
   # 使用 apt 安装（Debian/Ubuntu）
   apt install yq
   ```

2. 安装 `sshpass` 工具（用于自动输入密码）：
   ```
   # macOS
   brew install hudochenkov/sshpass/sshpass
   
   # Debian/Ubuntu
   apt-get install sshpass
   
   # CentOS/RHEL
   yum install sshpass
   ```

3. 下载 `sshp.sh` 脚本并添加执行权限：
   ```
   git clone https://github.com/wacxz/sshp.git
   cd sshp
   chmod +x sshp.sh
   ln -s $(pwd)/sshp.sh /usr/local/bin/sshp
   sshp
   ```

4. 可选：将脚本添加到你的 PATH 中，以便在任何位置使用它。

## 配置

SSHP 使用 `~/.sshp/sshp.yaml` 作为配置文件。配置文件的结构如下：

```yaml
group:
  default:
    port: 22
    user: root
    password: your_password
  list:
    主机名1:
      host: 主机地址
      port: 端口号
      user: 用户名
      password: 密码
    主机名2:
      host: 主机地址
    主机名3:
    主机名4:
      # 如果未指定，将使用默认配置
```

### 配置示例

```yaml
production:
  default:
    port: 22
    user: admin
    password: secure_password
  list:
    192.168.1.10:
      host: 192.168.1.10
    192.168.1.10:
      host: 192.168.1.11
      user: root  # 覆盖默认用户

development:
  default:
    port: 2222
    user: dev
    password: dev_password
  list:
    127.0.0.1:
      host: 127.0.0.1
      port: 22
```

## 使用方法

### 显示所有组

```
./sshp.sh group
```

### 显示组内的主机列表

```
./sshp.sh group production
```

### 连接到主机

```
./sshp.sh web1
```

### 编辑配置文件

```
./sshp.sh edit config
```

### 显示帮助信息

```
./sshp.sh -h
```

## 注意事项

- 密码以明文形式存储在配置文件中，请确保配置文件的权限设置正确
- 建议将配置文件的权限设置为仅当前用户可读写：`chmod 600 ~/.sshp/sshp.yaml`
- 对于生产环境，建议使用 SSH 密钥认证而不是密码

## 许可证

MIT
