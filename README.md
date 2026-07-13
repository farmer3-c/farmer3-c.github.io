# farmer3-c Blog

[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Deployed-blue?logo=github)](https://farmer3-c.github.io/)
[![Hugo](https://img.shields.io/badge/Hugo-v0.145.0+-ff4088?logo=hugo)](https://gohugo.io/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](#许可证)

个人技术博客，托管于 GitHub Pages，使用 **Hugo** 静态站点生成器构建。

记录计算机科学学习过程中的笔记、课程复习与问题解决方案。内容涵盖算法、计算机网络、计算机组成原理、编译原理、机器学习、凸优化等多个领域。

🔗 **博客地址：** [https://farmer3-c.github.io/](https://farmer3-c.github.io/)

---

## 技术栈

| 组件 | 技术选型 |
|------|---------|
| **静态站点生成器** | [Hugo](https://gohugo.io/)（扩展版） |
| **主题** | [PaperMod](https://github.com/adityatelange/hugo-PaperMod) |
| **部署平台** | GitHub Pages |
| **CI/CD** | GitHub Actions |
| **数学渲染** | MathJax 3（行内 `$...$` / 块级 `$$...$$`） |
| **评论系统** | Utterances（基于 GitHub Issues） |
| **搜索** | PaperMod 内置 + Fuse.js 模糊搜索 |
| **RSS** | 支持全文 RSS |

## 功能特点

- ✍️ **技术笔记** — 涵盖算法、网络、组成原理、编译原理、机器学习等多门课程
- 📐 **LaTeX 数学公式** — 基于 MathJax 3 的行内与块级公式渲染
- 💬 **评论互动** — 通过 Utterances 实现基于 GitHub Issues 的评论系统
- 🔍 **全文搜索** — 基于 Fuse.js 的客户端模糊搜索
- 📡 **RSS 订阅** — 支持全文 RSS 订阅
- 📱 **响应式设计** — PaperMod 主题自带移动端适配
- ⚡ **快速构建** — Hugo 静态生成，秒级构建速度
- 🚀 **自动部署** — 推送即部署，GitHub Actions 自动构建并发布

## 本地开发

### 前置要求

- [Hugo 扩展版](https://gohugo.io/installation/) v0.145.0 或更新版本
- Git

### 克隆与运行

```bash
# 克隆仓库（包含子模块）
git clone --recurse-submodules https://github.com/farmer3-c/farmer3-c.github.io.git
cd farmer3-c.github.io

# 本地启动开发服务器
hugo server -D

# 构建静态文件
hugo --minify
```

本地启动后访问 `http://localhost:1313` 即可预览。

> **注意：** 本仓库使用 PaperMod 主题作为 Git 子模块。如果克隆时未使用 `--recurse-submodules`，请执行：
> ```bash
> git submodule update --init --recursive
> ```

### 新建文章

```bash
hugo new content posts/my-new-post/index.md
```

## 部署

本博客通过 GitHub Actions 自动部署到 GitHub Pages：

1. 向 `main` 分支推送代码
2. GitHub Actions 自动执行 `hugo --minify` 构建
3. 构建产物部署至 GitHub Pages

工作流配置文件：[`.github/workflows/hugo.yml`](.github/workflows/hugo.yml)

如需手动触发部署，可在 GitHub 仓库的 Actions 标签页中选择 **Hugo deploy** 工作流并点击 **Run workflow**。

## 内容结构

```
content/
├── about/                 # 关于页面
├── posts/                 # 博客文章
│   ├── Algorithm/         # 算法与编程题
│   ├── Computer-Networks/ # 计算机网络系列
│   ├── Principles-of-computer-composition/  # 计算机组成原理系列
│   ├── Compiler/          # 编译原理实践
│   ├── Convex-Optimization/  # 凸优化理论与方法
│   ├── Machine-Learning/  # 机器学习
│   ├── latex/             # LaTeX 教程
│   └── ...                # 其他主题
└── search.md              # 搜索页面
```

## 许可证

本项目采用 **MIT License** 进行许可。详情请参阅 [LICENSE](./LICENSE) 文件。

### 第三方资源

- **PaperMod 主题** — [MIT License](https://github.com/adityatelange/hugo-PaperMod/blob/master/LICENSE)
- **MathJax** — [Apache License 2.0](https://github.com/mathjax/MathJax/blob/master/LICENSE)
- **Utterances** — [MIT License](https://github.com/utterance/utterances/blob/master/LICENSE)
