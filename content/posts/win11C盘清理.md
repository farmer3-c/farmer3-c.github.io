---
title: "win11C盘清理"
date: 2026-09-18T11:58:11+08:00
author: farmer3-c
tags:
- Windows
mathjax: true
draft: false
---

# Windows 11 磁盘清理实战：从 105 GB 到 117 GB

> 记录一次实际的 C 盘清理过程：先盘点空间，再按白名单保留开发环境和个人数据，最后处理可以安全删除的缓存。文中也记录了几个真正踩过的坑，以及后来整理出来的 PowerShell 脚本。

---

## 一、先把需求说清楚

这次清理最开始只有一个需求，内容很简单：

**清理磁盘空间**；VSCode 周边的 Git、Python、Go、JDK 等开发工具也算保留范围，Office、Zotero、Anki 等个人数据相关软件也不动。

### 环境基线

| 项目 | 初始状态 |
|---|---|
| 机器 | 笔记本（16 寸） |
| 系统 | Windows 11 家庭中文版 |
| C 盘 | 148 GB 已用 / **104.94 GB 可用** |
| D 盘 | 23.4 GB 已用 / 197.4 GB 可用 |
| 物理内存 | 15.7 GB，仅剩 3.9 GB 空闲 |
| 权限 | **非管理员**（`IsAdmin: False`） |

---

## 二、先侦察：到底是谁占了空间？

清理磁盘最怕的不是删得慢，而是删错。尤其是 Windows，很多目录名字看起来很像缓存，实际上可能放着配置、项目或者个人数据。

所以这次没有上来就删，而是先把 C 盘一层层测一遍，看看空间到底花在哪里。

### 2.1 逐层下钻测量

这里主要用 `Get-ChildItem -Recurse -File` 配合 `Measure-Object Length -Sum` 统计目录实际大小。`-Force` 也不能省，否则隐藏文件和系统文件容易被漏掉。

实际测下来，大致是这个分布：

```
C:\  148 GB 已用
├── Windows                58.02 GB
│   ├── WinSxS             25.88 GB   ← 组件库
│   ├── Installer           7.33 GB   ← MSI 缓存
│   └── SoftwareDistribution 0.89 GB
├── Users                  51.70 GB
│   ├── AppData            38.70 GB   ← 最大的单一目标
│   │   ├── Local\Microsoft 10.84 GB
│   │   │   ├── vscode-cpptools  5.98 GB  ← 保留(白名单)
│   │   │   └── Edge             3.64 GB
│   │   ├── Local\wsl       6.67 GB
│   │   ├── Local\JianyingPro 3.42 GB
│   │   ├── Local\pip       2.96 GB   ← 可再生缓存
│   │   └── Roaming\Code    2.24 GB   ← 保留(VSCode)
│   ├── .vscode             1.99 GB   ← 保留
│   └── .gradle             1.97 GB
├── Program Files          24.19 GB
└── $Recycle.Bin            2.68 GB   ← 314 项
```

### 2.2 顺便看看 RAM

虽然这次的主要目标是磁盘，但我也顺手看了一下当前 RAM 到底被哪些进程占着。用 `Get-Process` 按进程名把工作集加总：

```powershell
Get-Process | Group-Object ProcessName | ForEach-Object {
    [PSCustomObject]@{
        Name  = $_.Name
        MB    = [math]::Round(($_.Group | Measure-Object WorkingSet64 -Sum).Sum/1MB, 0)
        Procs = $_.Count
    }
} | Sort-Object MB -Descending | Select-Object -First 10
```

跑出来的结果也比较有代表性：

| 进程 | 内存 | 进程数 |
|---|---|---|
| msedge | 3286 MB | 30 |
| Code | 2800 MB | 16 |
| svchost | 1424 MB | 85 |
| Memory Compression | 987 MB | 1 |
| RazerAppEngine | 878 MB | 9 |
| msedgewebview2 | 776 MB | 13 |
| sqlservr | 273 MB | 2 |

这里能看出一个很直接的结果：占 RAM 最多的 Edge 和 VSCode 本身就是需要保留的软件。因此，这次没必要为了省一点 RAM 去动它们。相反，Razer 和 SQL Server 的进程确实占了一部分内存，如果后面确认不再使用，卸载它们也能顺带减少后台占用。

### 2.3 再盘点一下已安装软件

接着从注册表的三个卸载位置把软件清单拉出来。这里的 `WOW6432Node` 主要对应 32 位程序：

```powershell
$keys = @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
```

一共找到了 56 个条目。这里还顺便看了它们所在的 Hive：`HKCU` 一般是当前用户安装的程序，不一定需要管理员权限；`HKLM` 则属于系统级安装，通常需要提权才能卸载。

---

## 三、第一轮清理：先处理不用管理员权限的东西

第一轮我只做一件事：**删那些丢了还能重新生成的数据**。

主要就是缓存、临时文件和回收站。浏览器配置、书签、登录信息、项目文件以及各种依赖配置都不碰。这样即使哪里判断得不够准确，风险也比较小。

### 3.1 第一轮清理的结果

| 目标 | 释放 |
|---|---|
| 回收站（314 项） | 2.51 GB |
| 浏览器缓存（Edge 2.25 + Chrome 0.64） | 2.89 GB |
| pip 缓存 | 2.96 GB |
| Gradle 依赖缓存 | 1.83 GB |
| Go 构建缓存 | 0.52 GB |
| 临时文件 / 崩溃转储 | ~1.30 GB |
| **合计** | **12.02 GB** |

**C 盘：104.94 GB → 116.96 GB**

### 3.2 浏览器缓存：只清缓存，别动 Profile

浏览器的目录比较复杂，但缓存其实有比较明确的边界。这次只处理下面这些目录：

```
User Data\Default\Cache
User Data\Default\Code Cache
User Data\Default\GPUCache
User Data\ShaderCache
User Data\Default\Service Worker\CacheStorage
```

其中比较容易漏掉的是 `Service Worker\CacheStorage`，这次 Edge 单这一项就占了 **1.2 GB**。

反过来，`Login Data`、`Bookmarks`、`Preferences`、`History`、`Local Storage` 这些文件不要碰。简单一点的做法就是只清理名字明确带有 `Cache`、`Code Cache`、`GPUCache`、`ShaderCache` 的目录。

### 3.3 把重复操作封装起来

清理过程中反复遇到同一种操作：先统计目录大小，再删除里面的内容，最后重新统计一次，看看实际释放了多少。

所以把它简单封装成一个函数，后面处理不同目录时就不用重复写。

```powershell
param([string]$Targets)   # 用 | 分隔多个路径

foreach ($raw in ($Targets -split '\|')) {
    $t = $raw.Trim()
    if (-not (Test-Path -LiteralPath $t)) { "$t  MISSING"; continue }

    $before = (Get-ChildItem -LiteralPath $t -Recurse -File -Force -ErrorAction SilentlyContinue |
               Measure-Object Length -Sum).Sum

    Get-ChildItem -LiteralPath $t -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    $after = (Get-ChildItem -LiteralPath $t -Recurse -File -Force -ErrorAction SilentlyContinue |
              Measure-Object Length -Sum).Sum

    '{0,-58} freed {1,6} GB' -f $t, [math]::Round(($before - $after)/1GB, 2)
}
```

这里有两个小细节值得留意：

- 用 `-LiteralPath` 而不是 `-Path`。Windows 路径里可能出现 `[`、`]` 之类的字符，`-Path` 会把它们当成通配符。
- 删除时用 `-ErrorAction SilentlyContinue`。有些文件正在被占用，删不掉很正常，没必要因为一个文件失败就让整个清理过程停下来。

**保留项**：`.gradle\wrapper`（Gradle 发行版，重下要几百 MB 和大量时间）只删 `caches`，不删 `wrapper`。

---

## 四、几个真正踩过的坑

下面这些不是为了凑内容，而是这次清理过程中实际遇到的问题。Windows 的权限、编码和路径转义，有时候比真正的删除操作更麻烦。

### 坑 1：清空 `Temp`，顺手把正在运行的工具删了

执行清理 `C:\Users\<用户名>\AppData\Local\Temp` 后，工具返回：

```
bash output unavailable: output file
C:\Users\<用户名>\AppData\Local\Temp\claude\...\tasks\<会话ID>.output could not be read (ENOENT).
This usually means another Claude Code process in the same project deleted it during startup cleanup.
```

**原因**：当时 Claude Code 正好把命令输出暂存在 `%TEMP%\claude\` 下面。清空整个 Temp 的时候，连它自己的输出文件一起删掉了，于是工具后面找不到刚刚生成的结果。

**后来改法**：清理 Temp 时把这个目录排除掉：

```powershell
Get-ChildItem -LiteralPath $t -Force |
    Where-Object { $_.Name -ne 'claude' } |
    Remove-Item -Recurse -Force
```

这个问题其实不只针对 Claude Code。清理临时目录时，最好先想一下：**当前正在运行的程序是不是也把工作文件放在 Temp 里？**

### 坑 2：Git Bash 把 PowerShell 里的 `$` 当成变量了

在 Git Bash 里这样调用会出错：

```bash
# 错误：bash 先把 $Recycle.Bin 当成变量展开成空串
powershell -Command "Test-Path 'C:\$Recycle.Bin'"
```

结果路径变成了 `C:\.Bin` —— 因为 `$Recycle` 被 bash 当变量替换为空，只剩下 `C:\` + `.Bin`。同理 `$WinREAgent` 变成 `C:\`。

**后来改法**：不要在 Bash 里硬塞一长串 PowerShell 命令，直接写成 `.ps1` 脚本，再用 `-File` 传参数：

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "d:\Clean-C\scan.ps1" \
  -PathList 'C:\$Recycle.Bin|C:\$WinREAgent'
```

另外，`-File` 传参数时，`-Paths 'a','b'` 这种写法在实际调用里容易变成一个字符串，所以这里干脆用 `|` 分隔多个路径，处理起来更稳定。

### 坑 3：中文 Windows 下，PowerShell 5.1 的 UTF-8 编码问题

写了含中文提示的 `.ps1`，语法校验直接报一串错：

```
line 51: 表达式或语句中包含意外的标记")"
line 70: 参数列表中缺少参数
line 206: 字符串缺少终止符: '
```

**原因**：当时使用的是 PowerShell 5.1。中文 Windows 环境下，无 BOM 的 `.ps1` 在读取时可能按系统 ANSI 代码页（GBK/936）处理。脚本里的中文因此被错误解码，最后表现出来的却不是简单的乱码，而是一堆看起来莫名其妙的语法错误。

**解决办法**：给脚本保存成带 BOM 的 UTF-8：

```powershell
$c = [System.IO.File]::ReadAllText($p, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($p, $c, [System.Text.UTF8Encoding]::new($true))   # $true = 带 BOM
```

加完 BOM 后，脚本就能正常通过语法校验。

> 补充一点：文件加了 BOM 以后，如果在 Git Bash 里用 `Get-Content` 看起来还是乱码，也不代表脚本有问题。那可能只是终端管道的编码问题。先直接检查文件本身，不要因为终端显示乱码就反复修改脚本。

### 坑 4：`takeown` 也不一定能拿下 `$WinREAgent`

`C:\$WinREAgent`（1.36 GB，Windows 功能更新残留）尝试提权删除：

```powershell
takeown /F $t /R /D Y
icacls $t /grant 'Administrators:F' /T /C /Q
Remove-Item -LiteralPath $t -Recurse -Force
```

结果：`已成功处理 0 个文件; 处理 13 个文件时失败`，目录纹丝不动。

**原因**：这个目录和 Windows 更新机制有关，而当时的 PowerShell 会话又不是管理员权限。即使尝试 `takeown` 和 `icacls`，也没有真正拿到足够的控制权。

**最后的处理决定**：这类系统级残留就先不动。`$WinREAgent` 会由 Windows 后续处理；`SoftwareDistribution\Download` 也尝试过停掉 `wuauserv` 和 `bits`，但依然受到 TrustedInstaller 限制。

这时候继续折腾的意义已经不大。为了大约 2.2 GB 去修改系统目录权限，出了问题反而更麻烦，所以这部分直接放弃。

### 坑 5：不是管理员，就别硬做管理员才能做的事

```
User    : <主机名>\<用户名>
IsAdmin : False
```

这一点其实决定了后面的整个方案：

- DISM 清理 WinSxS 需要管理员权限
- 很多安装在 `HKLM` 下的软件也需要管理员权限才能卸载
- UAC 提权弹窗需要用户自己确认

所以没有继续绕权限，而是把需要管理员权限的部分整理成脚本，让用户自己以管理员身份运行。这样权限边界也比较清楚。

---

## 五、真正删除之前，再检查一遍重要数据

这一轮其实比写卸载脚本更重要。

白名单只能告诉我们「哪些东西要留下」，却不能保证剩下的目录里没有重要文件。所以在卸载 WSL、剪映、Trae 这类软件之前，又分别检查了一遍里面到底有没有用户数据。

在真正卸载前，重点检查了三个比较容易误删数据的地方：

### 5.1 WSL：Ubuntu 里有没有代码？

```bash
wsl -d Ubuntu-22.04 -- bash -lc "ls -la ~; du -sh ~ /root /opt /srv; find ~ -maxdepth 3 -name .git -type d"
```

结果：

```
/home/<用户名> 仅 76K，无 git 仓库
/root  4.0K     (空)
/opt   4.0K     (空)
/srv   4.0K     (空)
```

检查结果显示没有用户代码或项目数据。顺手查注册表时，还发现了一个容易误判的地方：

```
Ubuntu-22.04     C:\Users\<用户名>\AppData\Local\wsl\{<GUID>}
docker-desktop   \\?\D:\DockerData\DockerDesktopWSL\DockerDesktopWSL\main
```

也就是说，WSL 自己的 6.67 GB 在 C 盘，但 docker-desktop 的 6.29 GB 数据实际放在 D 盘。如果只看 C 盘目录，很容易把两者混在一起，以为「删掉 WSL 就能回收十几 GB」，同时也会忽略 D 盘上的 Docker 镜像和容器数据。

### 5.2 剪映：有没有视频工程？

```
JianyingPro\User Data
├── Cache              609.5 MB
├── ComponentStore    1693.7 MB   ← 组件，可重下
├── SupplysStore      1124.2 MB   ← 素材，可重下
└── Projects             0.0 MB   ← 关键：草稿为空
```

`Projects` 是 0，也就是说没有发现视频工程。这 3.42 GB 主要是缓存、组件和素材。如果这里有实际工程文件，结论就完全不同，卸载前必须先备份。

### 5.3 Trae：那些 worktrees 是什么？

初看 `.trae-cn\worktrees` 里有四个目录名很像真实项目：

```
my-blog
web-scraper
data-pipeline
api-server
```

进一步测量后发现 **全部是 0 文件、0 字节的空壳目录**，也没有 `.git` 文件。同时确认 `.trae-cn` 本身只是配置目录（含 `trae-jwt-token` 登录凭证），Trae 本体已不存在，剩余 872 MB 全是 `extensions` 缓存。

三个地方检查下来，都没有发现需要保留的项目数据。这个过程也再次说明了一点：**目录名字只能拿来做线索，真正决定能不能删的还是里面实际有什么。**

---

## 六、第二轮：把需要管理员权限的操作做成脚本

前面已经确认，当前账号不是管理员，所以这部分没有办法直接执行。最后的做法是准备一个可以自提权的脚本，用户运行时由 Windows 弹出 UAC，再由管理员 PowerShell 完成卸载。

### 6.1 一个简单的启动器

每次手动找「以管理员身份运行」比较麻烦，尤其是 Windows 11 的右键菜单有时还要再点一层。这里用一个 `.bat` 启动器直接请求管理员权限：

```bat
@echo off
REM 自提权后运行同目录下的 Remove-DevStack.ps1
REM 分组参数按需修改，删掉 -Apply 即为预演
set SCRIPT=%~dp0Remove-DevStack.ps1
powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-NoExit','-File','%SCRIPT%','-Group','Wsl,Docker','-WslDistro','Ubuntu-22.04'"
```

### 6.2 脚本里做了哪些保护

**① 先检查管理员权限**

脚本启动后的第一件事就是检查自己是不是管理员。如果不是，直接退出，不做任何修改：

```powershell
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host '请以管理员身份运行' -ForegroundColor Red
    exit 1
}
```

实际测试过，非管理员直接运行时会退出，退出码为 1，不会继续执行卸载。

**② 危险操作必须明确写出来**

最开始的版本是运行到危险操作时弹出 `Read-Host`，让用户输入「要不要删」。后来觉得这种方式还是不够稳，所以改成了参数控制：**不明确传入参数，就绝不执行对应的删除操作。**

```powershell
# 不写 -PurgeDataPath，D:\DockerData 绝不会被碰
.\Remove-DevStack.ps1 -Group Docker -Apply

# 写了才会删
.\Remove-DevStack.ps1 -Group Docker -PurgeDataPath 'D:\DockerData' -Apply
```

WSL 发行版同理：不指定 `-WslDistro` 就整组跳过。

这种设计比连续弹确认框更可靠。确认框很容易被一路回车带过去，而参数没有写就是没有写。对于可能删除数据的脚本，我更倾向于让默认状态保持「什么都不做」。

**③ 卸载命令直接从注册表读取**

不同软件的卸载方式差别很大，所以没有把某个版本的命令硬编码进脚本，而是先从注册表读取真实的 `UninstallString`：

```powershell
Get-ItemProperty $k | Where-Object { $_.DisplayName } |
    ForEach-Object { $_.DisplayName; $_.UninstallString; $_.QuietUninstallString }
```

实际看了一遍，确实五花八门：

| 软件 | 卸载方式 |
|---|---|
| Docker Desktop | `"...\Docker Desktop Installer.exe" uninstall` |
| SSMS 22 | 走 VS Installer：`setup.exe uninstall --installPath ...` |
| MongoDB Server | `MsiExec.exe /X{224A0A82-...}` |
| MongoDB Compass | `Update.exe --uninstall -s`（Squirrel 框架） |
| Razer Synapse | `RazerInstaller.exe /uninstall true` |
| WinSCP | `unins000.exe /SILENT`（Inno Setup） |
| SQL Server 本体 | **无静默参数**，必须走图形向导 |

另外也试了 `winget`。它能识别 Docker、MongoDB、MobaXterm、PuTTY 等软件，但 VMware Workstation、Razer Synapse、SSMS 在这里会显示成 `ARP\...` 条目，无法直接用 winget 卸载。所以这次没有把 winget 当成唯一入口，而是和注册表卸载信息配合使用。

这里还有一个很容易踩的坑：**MSI 的 `UninstallString` 经常是 `/I{GUID}`，但 `/I` 表示修改，不是卸载。** 如果原样执行，很可能打开维护/修改界面，所以脚本里统一把它改成 `/X`：

```powershell
$cmd = $cmd -replace 'MsiExec\.exe\s+/I', 'MsiExec.exe /X'
```

另外，脚本没有把产品 GUID 写死。因为软件升级后 GUID 可能变化，硬编码很容易过期。现在改成按 `DisplayName` 从注册表查找，对不同版本更友好。

**④ SQL Server 不强行做静默卸载**

SQL Server 本体没有找到可靠的静默卸载方式，所以脚本直接打开官方的 `SetupARP.exe`，剩下的步骤交给图形向导完成。这样比猜参数安全得多。

**⑤ 可以重复运行**

每个操作前先用 `Test-Path` 检查目标。已经卸载的软件直接 `SKIP`，不会因为某一项不存在就让整个脚本报错退出。

**⑥ 留日志**

每一步都会写进 `uninstall-log.txt`，最后再比较 C 盘前后的可用空间：

```powershell
Say ("  C:  {0} GB -> {1} GB    (释放 {2} GB)" -f $c0, $c1, [math]::Round($c1 - $c0, 2))
```

### 6.3 卸载清单

| 分组 | 内容 | 预计释放 |
|---|---|---|
| WSL | Ubuntu-22.04 | 6.67 GB |
| Docker | Docker Desktop + `D:\DockerData` | 6.29 GB (D 盘) |
| 剪映/Trae/Codex | 三者数据与缓存 | 5.53 GB |
| SQL Server | 2022 全家桶 + SSMS 22 | ~2.5 GB |
| MongoDB | Server 8.3.2 + Compass | ~2.8 GB |
| VMware/Razer/远程工具 | VMware + Razer + WinSCP/MobaXterm/PuTTY/RealVNC | ~2.2 GB |

按当时的目录大小估算，后续操作还有 **约 25 GB** 的空间可以处理；如果同时卸载 Razer 和 SQL Server，它们对应的后台进程理论上还会少占约 **1.2 GB RAM**。实际数值会随着软件版本和运行状态变化。

---

## 七、清理到这里，实际结果怎么样？

### 已经完成的部分

**C 盘可用空间：104.94 GB → 116.96 GB，一共释放了 12.02 GB。**

### 暂时没动的 3 项（约 2.2 GB）

| 项目 | 大小 | 原因 |
|---|---|---|
| `SoftwareDistribution\Download` | 0.84 GB | TrustedInstaller 权限 |
| `$WinREAgent` | 1.36 GB | `takeown` 失败，Windows 会自动清理 |
| `WinSxS` | 25.88 GB | 需管理员跑 DISM |

WinSxS 的进一步清理命令也放到了脚本最后，之后如果需要，可以在管理员终端里执行：

```
Dism.exe /Online /Cleanup-Image /StartComponentCleanup
```

### 还需要手动执行的部分

剩下的软件卸载都需要管理员权限，所以需要用户自己运行附录 B 的脚本。执行之前，最好先关掉浏览器、编辑器和 VPN，避免文件被占用。

第一次运行建议先用**预演模式**，确认脚本准备做什么，再加 `-Apply` 真正执行：

```powershell
# 第一步：预演，只打印计划，不做任何改动
.\Remove-DevStack.ps1 -Group Wsl,Docker,DevCache,SqlServer,MongoDB,Misc `
                      -WslDistro Ubuntu-22.04

# 第二步：确认无误后执行
.\Remove-DevStack.ps1 -Group Wsl,Docker,DevCache,SqlServer,MongoDB,Misc `
                      -WslDistro Ubuntu-22.04 `
                      -PurgeDataPath 'D:\DockerData' -Apply
```

---

## 八、这次清理留下的几个经验

1. **先测量，再删除。** 用 `Measure-Object Length -Sum` 一层层查，至少能知道空间到底花在哪里。这次最大的目标其实是 `AppData`，占了 38.7 GB。

2. **需求有歧义时先确认。** 「内存」到底指 RAM 还是磁盘，以及白名单到底包含哪些开发工具，这两个地方如果判断错了，后果可能就是误删个人数据。

3. **不要只看目录名。** `worktrees\my-blog` 看起来像项目，实际是空目录；`JianyingPro\Projects` 看起来像视频工程目录，实际也是 0 字节。真正删除前，最好进去看一眼、测一下大小。

4. **清理 Temp 时记得看看当前运行的程序。** 这次就是因为工具自己的文件也放在 Temp 里，差点把自己清掉。

5. **中文 Windows 上写 PowerShell 脚本，要留意编码。** 这次遇到的就是 UTF-8 和 PowerShell 5.1 的兼容问题。

6. **有些空间不值得硬抠。** `$WinREAgent` 和 `SoftwareDistribution` 加起来约 2.2 GB，但涉及系统权限。为了这点空间去强行修改权限，风险明显高于收益，所以这次选择不动。

7. **权限不够就交给管理员执行。** 非管理员做不了的事情没必要绕来绕去，整理成脚本让用户自己提权执行，反而更清楚。

---

## 附：整理好的可复用脚本

最后把这次实际用到的操作整理成两个脚本。已经尽量去掉机器相关的硬编码，方便以后在其他 Windows 机器上复用。

- **A. `Clean-DevCaches.ps1`** —— 缓存清理，无需管理员，默认预演
- **B. `Remove-DevStack.ps1`** —— 环境卸载，需管理员，默认什么都不做

> 两个脚本运行前都建议先通读一遍。尤其是 B，它涉及软件卸载以及递归删除目录。

---

### A. 缓存清理 `Clean-DevCaches.ps1`

这个脚本只处理可以重新生成的缓存。默认是「预演」模式，只告诉你准备清理什么、能释放多少；确认之后再加 `-Apply` 真正删除。

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    开发环境磁盘清理 —— 只删除可再生数据。
.DESCRIPTION
    三类目标：
      1. 系统临时文件（Temp / CrashDumps）
      2. 包管理器缓存（pip / npm / gradle / go / nuget）
      3. 浏览器缓存（仅 Cache 类目录，不触碰书签与登录态）
    默认预演，只打印不删除。加 -Apply 才执行。无需管理员权限。
.PARAMETER Apply
    真正执行删除。
.PARAMETER IncludePackageCaches
    一并清理包管理器缓存。
.PARAMETER IncludeRecycleBin
    一并清空回收站。默认不动 —— 回收站是最后的后悔药。
.PARAMETER ExcludeChild
    清理时跳过的子目录名。默认跳过 'claude'，避免删掉正在运行的
    CLI 工具自己的输出缓冲（见正文「坑 1」）。
.EXAMPLE
    .\Clean-DevCaches.ps1
    .\Clean-DevCaches.ps1 -Apply -IncludePackageCaches
#>
[CmdletBinding()]
param(
    [switch]$Apply,
    [switch]$IncludePackageCaches,
    [switch]$IncludeRecycleBin,
    [string[]]$ExcludeChild = @('claude')
)

$ErrorActionPreference = 'Continue'
$total = 0
$la = $env:LOCALAPPDATA
$up = $env:USERPROFILE

function Get-DirSize([string]$Path) {
    $s = (Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
          Measure-Object Length -Sum).Sum
    if ($s) { $s } else { 0 }
}

function Clear-Folder {
    param([string]$Path, [string]$Label, [string[]]$Exclude)

    if (-not (Test-Path -LiteralPath $Path)) { return }
    $before = Get-DirSize $Path
    if ($before -lt 1MB) { return }

    if ($Apply) {
        Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue |
            Where-Object { $Exclude -notcontains $_.Name } |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        $freed = $before - (Get-DirSize $Path)
        $script:total += $freed
        '  [已清] {0,-52} {1,7} MB' -f $Label, [math]::Round($freed / 1MB, 0)
    } else {
        $script:total += $before
        '  [预演] {0,-52} {1,7} MB' -f $Label, [math]::Round($before / 1MB, 0)
    }
}

''
'=== 1. 系统临时文件 ==='
Clear-Folder "$la\Temp"         '本地 Temp'    $ExcludeChild
Clear-Folder "$env:WINDIR\Temp" 'Windows Temp' $ExcludeChild
Clear-Folder "$la\CrashDumps"   '崩溃转储'

if ($IncludePackageCaches) {
    ''
    '=== 2. 包管理器缓存 ==='
    Clear-Folder "$la\pip"             'pip'
    Clear-Folder "$la\npm-cache"       'npm'
    Clear-Folder "$la\go-build"        'Go 构建'
    Clear-Folder "$up\.gradle\caches"  'Gradle 依赖'
    Clear-Folder "$up\.gradle\daemon"  'Gradle daemon'
    Clear-Folder "$up\.nuget\packages" 'NuGet'
    # 刻意不删 .gradle\wrapper —— 那是 Gradle 发行版，重下要几百 MB
}

''
'=== 3. 浏览器缓存 ==='
$cacheLeafs = @('Cache', 'Code Cache', 'GPUCache', 'ShaderCache',
                'Service Worker\CacheStorage')
$roots = @{
    'Edge'   = "$la\Microsoft\Edge\User Data"
    'Chrome' = "$la\Google\Chrome\User Data"
}
foreach ($name in $roots.Keys) {
    $root = $roots[$name]
    if (-not (Test-Path -LiteralPath $root)) { continue }
    Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq 'Default' -or $_.Name -like 'Profile *' } |
        ForEach-Object {
            $profile = $_
            foreach ($leaf in $cacheLeafs) {
                Clear-Folder (Join-Path $profile.FullName $leaf) "$name\$($profile.Name)\$leaf"
            }
        }
}

if ($IncludeRecycleBin) {
    ''
    '=== 4. 回收站 ==='
    if ($Apply) {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        '  [已清] 回收站'
    } else {
        '  [预演] 回收站'
    }
}

''
if ($Apply) {
    '总计释放 {0} GB' -f [math]::Round($total / 1GB, 2)
} else {
    '预计可释放 {0} GB —— 确认无误后加 -Apply 执行' -f [math]::Round($total / 1GB, 2)
}
```

---

### B. 环境卸载 `Remove-DevStack.ps1`

这个脚本主要负责需要管理员权限的软件卸载和残留清理，设计上有三个重点：

1. **路径全部走 `$env:USERPROFILE`** —— 不硬编码用户名，别人也能用
2. **默认什么都不做** —— 必须用 `-Group` 显式指定分组，高危路径必须用 `-PurgeDataPath` 显式传入
3. **按 `DisplayName` 反查卸载命令** —— 不硬编码 MSI 产品码（那些会随版本变化）

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    开发环境卸载脚本（通用版）—— 需管理员权限。
.DESCRIPTION
    按分组卸载，默认什么都不做，必须用 -Group 显式指定。
      Wsl        注销 WSL 发行版（需配合 -WslDistro）
      Docker     Docker Desktop
      DevCache   剪映 / Trae / Codex 等编辑器残留
      SqlServer  SQL Server + SSMS + 相关驱动
      MongoDB    MongoDB Server + Compass
      Misc       VMware / Razer / 远程工具
.PARAMETER WslDistro
    要注销的 WSL 发行版名。会永久删除该发行版内全部数据。
    先执行 wsl --list --verbose 确认名称。
.PARAMETER PurgeDataPath
    额外整目录删除的路径（如 D:\DockerData）。高危，必须显式传入。
.PARAMETER Apply
    真正执行。不加则只预演并列出计划。
.EXAMPLE
    .\Remove-DevStack.ps1 -Group Wsl,Docker -WslDistro Ubuntu-22.04
.EXAMPLE
    .\Remove-DevStack.ps1 -Group Wsl,Docker -WslDistro Ubuntu-22.04 -PurgeDataPath 'D:\DockerData' -Apply
.NOTES
    执行前请关闭浏览器、编辑器与 VPN，避免文件占用。
#>
[CmdletBinding()]
param(
    [ValidateSet('Wsl','Docker','DevCache','SqlServer','MongoDB','Misc')]
    [string[]]$Group = @(),

    [string[]]$WslDistro = @(),
    [string[]]$PurgeDataPath = @(),
    [switch]$Apply,
    [string]$LogPath = "$PSScriptRoot\uninstall-log.txt"
)

$ErrorActionPreference = 'Continue'

# ---- 管理员守卫：不满足就直接退出，不做任何事 ----------------------------
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host '需要管理员权限。请以管理员身份打开 PowerShell 后重试。' -ForegroundColor Red
    exit 1
}

if ($Group.Count -eq 0) {
    Write-Host '请用 -Group 指定分组，可选： Wsl Docker DevCache SqlServer MongoDB Misc'
    Write-Host "例如： .\Remove-DevStack.ps1 -Group Wsl,Docker -WslDistro Ubuntu-22.04"
    exit 0
}

$up = $env:USERPROFILE
$la = $env:LOCALAPPDATA

function Say($m)  { Write-Host $m; Add-Content -LiteralPath $LogPath -Value $m -Encoding UTF8 }
function Step($m) { Say ''; Say ('=== ' + $m + ' ===') }

function Run($exe, $arguments, $desc) {
    if (-not (Test-Path -LiteralPath $exe)) { Say "  SKIP  $desc（未找到 $exe）"; return }
    Say "  RUN   $desc"
    if (-not $Apply) { return }
    try   { Start-Process -FilePath $exe -ArgumentList $arguments -Wait -ErrorAction Stop
            Say "  DONE  $desc" }
    catch { Say "  FAIL  $desc -- $($_.Exception.Message)" }
}

function RemoveDir($path, $desc) {
    if (-not (Test-Path -LiteralPath $path)) { Say "  SKIP  $path"; return }
    $mb = [math]::Round((Get-ChildItem -LiteralPath $path -Recurse -File -Force `
          -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB, 0)
    Say "  DEL   $path  ($mb MB)  $desc"
    if (-not $Apply) { return }
    Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $path) { Say "  WARN  未能完全删除：$path" }
}

# 按显示名从注册表反查卸载命令，避免硬编码会随版本变化的产品码
function Uninstall-ByDisplayName($pattern, $desc) {
    $keys = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $hits = foreach ($k in $keys) {
        Get-ItemProperty $k -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like $pattern }
    }
    if (-not $hits) { Say "  SKIP  $desc（未安装）"; return }

    foreach ($h in $hits) {
        $cmd = if ($h.QuietUninstallString) { $h.QuietUninstallString } else { $h.UninstallString }
        if (-not $cmd) { Say "  SKIP  $($h.DisplayName)（无卸载命令，可能需图形向导）"; continue }

        # MSI 的 /I 是「修改」，必须改成 /X 才是卸载
        $cmd = $cmd -replace 'MsiExec\.exe\s+/I', 'MsiExec.exe /X'

        Say "  RUN   $($h.DisplayName)"
        if (-not $Apply) { continue }

        $parts = $cmd -split ' ', 2
        $exe   = $parts[0].Trim('"')
        $rest  = if ($parts.Count -gt 1) { $parts[1] } else { '' }
        try   { Start-Process -FilePath $exe -ArgumentList $rest -Wait -ErrorAction Stop
                Say "  DONE  $($h.DisplayName)" }
        catch { Say "  FAIL  $($h.DisplayName) -- $($_.Exception.Message)" }
    }
}

# ---- 开始 -----------------------------------------------------------------
Set-Content -LiteralPath $LogPath -Value "Remove-DevStack  $(Get-Date)" -Encoding UTF8
$c0 = [math]::Round((Get-PSDrive C).Free / 1GB, 2)

Say ''
Say "  模式： $(if ($Apply) { '实际执行' } else { '预演（未做任何改动）' })"
Say "  分组： $($Group -join ', ')"
Say "  起始 C: 可用 $c0 GB"

# --- WSL -------------------------------------------------------------------
if ($Group -contains 'Wsl') {
    Step 'WSL 发行版'
    if ($WslDistro.Count -eq 0) {
        Say '  未指定 -WslDistro，跳过。先执行 wsl --list --verbose 查看名称。'
    } else {
        Say '  当前发行版：'
        & wsl.exe --list --verbose 2>&1 | ForEach-Object { Say ('    ' + $_) }
        foreach ($d in $WslDistro) {
            Say "  注销 $d —— 该发行版内所有数据将被永久删除"
            if ($Apply) { & wsl.exe --unregister $d 2>&1 | ForEach-Object { Say ('    ' + $_) } }
        }
    }
}

# --- Docker ----------------------------------------------------------------
if ($Group -contains 'Docker') {
    Step 'Docker Desktop'
    Run "$env:ProgramFiles\Docker\Docker\Docker Desktop Installer.exe" @('uninstall') 'Docker Desktop'
}

# --- 编辑器残留 -------------------------------------------------------------
if ($Group -contains 'DevCache') {
    Step '编辑器残留（剪映 / Trae / Codex）'
    RemoveDir "$la\JianyingPro"           '剪映缓存与组件'
    RemoveDir "$up\.trae-cn"              'Trae 配置'
    RemoveDir "$up\.codex"                'Codex 配置'
    RemoveDir "$up\.cache\codex-runtimes" 'Codex 运行时'
    Say '  提示：若 codex 由 npm 安装，另需执行 npm uninstall -g @openai/codex'
}

# --- SQL Server ------------------------------------------------------------
if ($Group -contains 'SqlServer') {
    Step 'SQL Server'
    Get-Service -Name 'MSSQL*','SQLAgent*','SQLBrowser','SQLWriter' -ErrorAction SilentlyContinue |
        ForEach-Object {
            Say "  停止服务 $($_.Name)"
            if ($Apply) { Stop-Service $_.Name -Force -ErrorAction SilentlyContinue }
        }

    # SSMS 22 由 Visual Studio Installer 托管，不是普通 MSI
    $vs   = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\setup.exe"
    $ssms = "$env:ProgramFiles\Microsoft SQL Server Management Studio 22\Release"
    if ((Test-Path -LiteralPath $vs) -and (Test-Path -LiteralPath $ssms)) {
        Run $vs @('uninstall', '--installPath', $ssms) 'SSMS 22'
    }

    Uninstall-ByDisplayName 'Microsoft VSS Writer for SQL Server*'  'SQL Server VSS Writer'
    Uninstall-ByDisplayName 'Microsoft ODBC Driver*for SQL Server*' 'ODBC 驱动'
    Uninstall-ByDisplayName 'Microsoft OLE DB Driver*SQL Server*'   'OLE DB 驱动'

    # 本体无可靠静默参数，交给官方图形向导
    $arp = "$env:ProgramFiles\Microsoft SQL Server\160\Setup Bootstrap\SQL2022\x64\SetupARP.exe"
    if (Test-Path -LiteralPath $arp) {
        Say '  SQL Server 本体无可靠静默参数，需走图形向导'
        Say "  即将打开： $arp"
        if ($Apply) { Start-Process -FilePath $arp -Wait }
    }
}

# --- MongoDB ---------------------------------------------------------------
if ($Group -contains 'MongoDB') {
    Step 'MongoDB'
    Uninstall-ByDisplayName 'MongoDB [0-9]*' 'MongoDB Server'

    # Compass 是 Squirrel 框架打包，有自己的卸载器
    $compass = "$la\MongoDBCompass\Update.exe"
    if (Test-Path -LiteralPath $compass) {
        Run $compass @('--uninstall', '-s') 'MongoDB Compass'
    } else {
        RemoveDir "$la\MongoDBCompass" 'Compass 残留'
    }
}

# --- 其他 ------------------------------------------------------------------
if ($Group -contains 'Misc') {
    Step 'VMware / Razer / 远程工具'
    Get-Process -Name 'Razer*','GameManagerService*' -ErrorAction SilentlyContinue |
        ForEach-Object {
            Say "  结束进程 $($_.Name)"
            if ($Apply) { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
        }
    Start-Sleep -Seconds 2

    Uninstall-ByDisplayName 'VMware Workstation*' 'VMware Workstation'
    Uninstall-ByDisplayName 'Razer Synapse'       'Razer Synapse'
    Uninstall-ByDisplayName 'MobaXterm*'          'MobaXterm'
    Uninstall-ByDisplayName 'PuTTY*'              'PuTTY'
    Uninstall-ByDisplayName 'RealVNC*'            'RealVNC Viewer'
    Uninstall-ByDisplayName 'WinSCP*'             'WinSCP'

    RemoveDir "$la\Razer" 'Razer 残留'
}

# --- 显式指定的高危目录 -----------------------------------------------------
if ($PurgeDataPath.Count) {
    Step '显式指定的数据目录'
    foreach ($p in $PurgeDataPath) { RemoveDir $p '用户指定' }
}

# --- 汇总 ------------------------------------------------------------------
Step '完成'
$c1 = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
Say "  C: $c0 GB -> $c1 GB   (释放 $([math]::Round($c1 - $c0, 2)) GB)"
Say "  日志： $LogPath"
if ($Apply) {
    Say ''
    Say '  可选的进一步清理（仍需管理员）：'
    Say '    Dism.exe /Online /Cleanup-Image /StartComponentCleanup'
}
```

---

### 附：目录体积测量

上面两个脚本的共同前提都是先知道目标有多大。下面这个小脚本可以单独拿出来测几个目录：

```powershell
param([string]$PathList)   # 多个路径用 | 分隔

foreach ($p in ($PathList -split '\|')) {
    $p = $p.Trim()
    if (-not $p) { continue }
    if (Test-Path -LiteralPath $p) {
        $s = (Get-ChildItem -LiteralPath $p -Recurse -File -Force -ErrorAction SilentlyContinue |
              Measure-Object Length -Sum).Sum
        if (-not $s) { $s = 0 }
        '{0,-56} {1,8} GB' -f $p, [math]::Round($s / 1GB, 2)
    } else {
        '{0,-56} {1,8}' -f $p, 'GONE'
    }
}

$d = Get-PSDrive C
'{0,-56} {1,8} GB free' -f 'C:', [math]::Round($d.Free / 1GB, 2)
```

用 `-File` 参数时数组传参容易出问题（`-Paths 'a','b'` 会被当成单个字符串），所以这里用 `|` 分隔的单个字符串。注意必须带 `-Force`，否则隐藏文件和系统文件会被漏掉。
