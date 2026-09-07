---
title: "VSCode Remote-SSH 报错修复记录"
date: 2026-09-07T22:24:23+08:00
author: farmer3-c
tags:
- VS code
mathjax: true
draft: false
---

# VSCode Remote-SSH 报错修复记录

## 现象

重装云服务器系统后，VSCode 远程连接失败，报错内容类似：

```
@ WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
Host key for 124.222.53.248 has changed and you have requested strict checking.
Host key verification failed.
Offending ECDSA key in C:\Users\hp/.ssh/known_hosts:11
```

## 原因

重装服务器系统后，服务器的 **SSH host key（主机密钥）发生了改变**，但本地的
`~/.ssh/known_hosts` 文件里仍保留着重装前旧系统的指纹记录。

SSH 出于防止中间人攻击的安全考虑（strict checking），当发现同一 IP 的主机指纹
与本地记录不一致时，会**拒绝连接**，而 VSCode 的 Remote-SSH 插件无法处理这种
交互式确认，因此直接失败。

## 解决步骤

### 1. 删除本地旧 host key

在**本地电脑**执行（Windows 下可用 Git Bash / PowerShell / CMD 均可）：

```bash
ssh-keygen -R 124.222.53.248
```

> 将 `124.222.53.248` 替换为你的服务器 IP。

执行成功后输出类似：

```
Host 124.222.53.248 found: line 9
/c/Users/hp/.ssh/known_hosts updated.
Original contents retained as /c/Users/hp/.ssh/known_hosts.old
```

### 2. 重新验证连接并记录新指纹

```bash
ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 124.222.53.248
```

看到 `Permanently added '124.222.53.248' (ED25519) to the list of known hosts.`
即表示新指纹已记录，服务器可达。

### 3. 回到 VSCode 重新连接

重新点击 Remote-SSH 连接，输入登录密码即可。

## 重装系统后容易连带出现的问题

### 登录账号 / 密码变了

重装系统后，登录账号会变成你在云控制台选择的镜像默认用户
（如腾讯云/阿里云多为 `root` 或 `ubuntu`），密码也要用云控制台里重置后的初始密码。

### SSH 密钥失效（如果用密钥登录）

重装后服务器上原来的 `~/.ssh/authorized_keys` 已不存在。需要重新写入公钥：

```bash
# 先用密码登录服务器后执行
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo "你的公钥内容" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

## 常用相关命令备忘

| 命令 | 作用 |
| --- | --- |
| `ssh-keygen -R <IP>` | 从 known_hosts 删除指定主机的旧指纹 |
| `ssh-keygen -R <IP> -f <known_hosts路径>` | 删除指定文件中该主机的指纹 |
| `ssh-keygen -F <IP>` | 查询 known_hosts 中是否已有该主机指纹 |
| `ssh -o StrictHostKeyChecking=accept-new <IP>` | 连接时自动接受新指纹（仅用于首次） |
| `cat ~/.ssh/known_hosts` | 查看已记录的指纹 |

> ⚠️ 安全提示：删除 host key 会让服务器失去指纹校验。请只在**确认目标服务器确实是你自己的、
> 且因重装系统导致指纹变更**时操作，警惕中间人攻击风险。
