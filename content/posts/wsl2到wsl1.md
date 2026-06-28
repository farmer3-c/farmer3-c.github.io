---
title: wsl2到wsl1
date: '2026-06-18T23:39:10'
author: farmer3-c
tags:
- WSL
draft: false
---
# 前因

之前想在Windows上使用Linux系统，wsl很方便（为Windows用户提供了Linux环境，不需要装系统什么的）。但是不知道为什么，启动wsl的时间越来越长，从一开始的十几秒到后来的几分钟，实在让我不能忍受。我原来使用的是WSL 2，发现WSL 1 不依赖 Hyper-V 虚拟化，它直接共享 Windows 主机的 IP，启动会很快，所以试试转为 WSL 1。

# 过程

在 PowerShell 中逐条执行以下命令：

```powershell
# 1. 备份当前环境 
wsl --export Ubuntu-22.04 D:\wsl-backup.tar

# 2. 转换为 WSL 1
wsl --set-version Ubuntu-22.04 1

# 3. 彻底重启 WSL
wsl --shutdown

# 4. 测试启动速度
Measure-Command { wsl -d Ubuntu-22.04 --exec true }

# 5. 测试网络
wsl -d Ubuntu-22.04
# 进入 WSL 后，运行：
ping baidu.com
```
结果：

![1](/img/wsl/1.png)

启动很快，网络也没有问题，暂时没发现其他问题。
