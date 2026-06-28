---
title: Windows磁盘合并
date: '2026-06-09T22:13:58'
author: farmer3-c
tags:
- Windows
draft: false
---
# 前因

C盘越来越满，D盘和E盘还有许多空间，磁盘合并理所当然的成为了一个缓解C盘压力的解决方案。

## 想法

我的想法是将D盘的文件都挪到E盘，然后腾出D盘的空间来分配到C盘和E盘。考虑到我习惯使用D盘存放应用，所以我打算之后将E盘的盘符改成D。

处于方便和迅捷考虑，我使用`robocopy "D:\" "E:\D盘备份" /E /J /MT:8 /R:3 /W:1`复制D盘文件到E盘的一个文件夹，效果还不错。于是在完成修改后我同样使用`robocopy D:\D盘备份 D:\ /E /MIR`来将配置带到新的D盘，殊不知这会带来怎么样的灾难😭

# 过程

我使用[MiniTool Partition Wizard](https://www.minitool.com/partition-manager/partition-wizard-home.html)进行磁盘操作。由于原来D盘删除后的内存与C盘之间存在恢复分区，C盘只能合并它右侧的空间，所以要move恢复分区，这就为C盘扩容了。

然后是将剩余空间合并到E盘，结果因为BitLocker而合并不了，解密之后顺利合并。

最后，灾难性的一幕发生了，使用`robocopy D:\D盘备份 D:\ /E /MIR`后，修改后D盘空了。

可能的原因是：带 /MIR 的 robocopy 命令在执行时，先清空了 D 盘根目录，再尝试复制备份文件，但中途因为 $RECYCLE.BIN 报错中断，导致备份文件也被系统误删了。

数据恢复工具需要的时间太长了，被删除的数据也没有很重要的，我就先配置了日常要用的工具草草了结了，剩下的日后再说。