---
title: 本地文件目录推送到GitHub上同名空repository
date: '2026-06-12T10:37:24'
author: farmer3-c
tags:
- github
draft: false
---
在 GitHub 建**同名、完全空的仓库（不要勾选 README/.gitignore）**，本地目录用 `git init`→`git add .`→`git commit`→`git remote add origin`→`git push -u origin main` 即可一次性推上去。

下面是完整操作（Windows/Mac/Linux 通用）：

* * *

### 一、准备工作

1.  安装 Git：
    
    终端输入：

    ```bash
    git --version
    ```
    
    能显示版本就说明已安装；没有就先装 Git。
    
2.  在 GitHub 建**同名空仓库**
    
    -   右上角点 `+` → New repository
    -   Repository name：和你本地文件夹**同名**
    -   **不要勾选**：Add a README file、.gitignore、License
    -   点 Create repository
    -   复制仓库地址（HTTPS 或 SSH），例如：
        
        
        ```plaintext
        https://github.com/你的用户名/仓库名.git
        ```
        
    

* * *

### 二、本地操作

打开终端（Git Bash / Terminal / PowerShell），**进入你要上传的本地目录根目录**：


```bash
cd /path/to/你的本地文件夹   # Windows 示例：cd D:\my-project
```

#### 1\. 初始化为 Git 仓库


```bash
git init
```

#### 2\. 添加所有文件到暂存区



```bash
git add .
```

（想忽略某些文件，新建 `.gitignore` 写规则，比如 `node_modules/`、`*.log`）

#### 3\. 提交到本地仓库



```bash
git commit -m "Initial commit: 上传本地全部文件"
```

#### 4\. 关联远程 GitHub 仓库



```bash
git remote add origin https://github.com/你的用户名/仓库名.git
```

如果提示 `remote origin already exists`，先删旧关联：



```bash
git remote remove origin
```

再重新执行上面命令。

#### 5\. 重命名分支为 main（和 GitHub 默认一致）



```bash
git branch -M main
```

#### 6\. 推送到 GitHub



```bash
git push -u origin main
```

-   `-u`：以后直接 `git push` 即可，不用每次写 `origin main`
-   输入 GitHub 账号密码（或用个人访问令牌），完成。

* * *

### 三、常见报错解决

1.  **fatal: remote origin already exists**
    
    → `git remote remove origin` 后重新关联。
    
2.  **error: src refspec main does not match any**
    
    → 没 `add` 或 `commit` 成功，重新执行：
    
    
    ```bash
    git add .
    git commit -m "Initial commit"
    ```
    
3.  **合并冲突（远程有 README 等）**
    
    → 必须保证远程是空仓库；如果已有内容，用：
    
    
    ```bash
    git pull origin main --allow-unrelated-histories
    ```
    
    解决冲突后再 push。