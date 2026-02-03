---
layout: post
title: "System.IO.FileLoadException: 未能加载文件或程序集“WindowsDebugLauncher……"
subtitle: " "
date: 2026-02-03 00:18:48 +0800
author: "farmer3-c"
header-img: "img/post-bg-2015.jpg"
tags: [VS code报错]
mathjax: true
---


## 问题

在使用VS code编写C++程序时，运行程序时出现了以下错误：

 
`未经处理的异常:  System.IO.FileLoadException: 未能加载文件或程序集“WindowsDebugLauncher, Version=14.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a”或它的某一个依赖项。强名称验证失败。 (异常来自 HRESULT:0x8013141A) ---> System.Security.SecurityException: 强名称验证失败。 (异常来自 HRESULT:0x8013141A)
   --- 内部异常堆栈跟踪的结尾 ---`

![1](/img/in-post/vscode_wrn/屏幕截图%202026-02-03%20002612.png)

![2](/img/in-post/vscode_wrn/屏幕截图%202026-02-03%20002821.png)



## 解决方法

异常信息的重点在：强名称验证失败。

这个问题主要出现在c#开发，在c#中，程序集的强名称是由程序集的公钥和版本号组成的。如果程序集的强名称验证失败，就会出现这个错误。

所以我想先尝试临时禁用强名称验证（仅用于调试环境），以查看是否能解决问题。

因为没有安装 sn.exe 工具，所以通过安装 .NET SDK 来获取 sn.exe 工具。

安装好后，我灵机一动，是不是可以删除VS code “PORTS”面板的进程，然后再重新运行程序，看看是否能解决问题。

![3](/img/in-post/vscode_wrn/屏幕截图%202026-02-03%20013105.png)

于是我在“PORTS”面板中 结束了所有进程 ，然后再重新打开VS code,运行程序，问题解决了。


####  猜测原因

> 首先要明确：这个错误表面是 C++ 运行报错，实际是 VS Code 的 C/C++ 调试插件依赖的.NET 程序集出了问题，不是 C++ 代码本身有逻辑错误。

> WindowsDebugLauncher是 VS Code 的 C/C++ 调试插件（ms-vscode.cpptools）在 Windows 平台上依赖的调试启动程序集（基于.NET Framework 开发），它带有强名称签名（公钥令牌正是b03f5f7f11d50a3a）。强名称验证失败的核心是：系统在加载这个程序集时，验证它的签名完整性、版本一致性、公钥合法性时出了问题，导致拒绝加载，最终调试器无法启动，抛出FileLoadException。

**调试进程残留**

* 之前多次启动 C++ 程序调试，部分调试进程（hello.exe、use4set.exe）没有正常退出，而是在后台残留，对应的cppdbg调试器也没有释放。
 
* 这些残留进程会占用WindowsDebugLauncher程序集的资源，或者导致程序集被锁定在 “已加载但未释放” 的状态，后续再次启动调试时，系统无法重新验证该程序集的强名称（相当于 “资源被占用，验证流程无法正常执行”），从而抛出验证失败错误。
 
* 结束 PORTS 面板所有进程、重启 VS Code 后，残留进程被清理，程序集资源被释放，后续调试时验证流程正常执行，问题解决。
 
 