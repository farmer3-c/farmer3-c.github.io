---
title: "博客框架迁移：从 Jekyll 到 Hugo"
description: "告别 Jekyll，拥抱 Hugo 的简洁与速度"
date: "2026-06-28T22:00:00+08:00"
author: "farmer3-c"
tags:
  - Blog
  - Hugo
  - Jekyll
  - Tutorial
---

## 前言

之前的博客基于 **Jekyll + Hux Blog 主题**，用了快一年，总觉得不太顺手。Jekyll 是 Ruby 生态，本地构建慢，主题样式偏重（大图背景、多栏布局），对我这种只想简洁写文章的人来说有点臃肿。

于是决定迁移。目标是：

- 🚀 **更快的构建速度**
- 🎨 **极简的页面风格** —— 无背景图、干净利落
- 🔧 **少折腾** —— 配置简单，开箱即用
- 📝 **保留所有文章和资源**

最终选择了 **Hugo + PaperMod 主题**。

---

## 为什么选 Hugo？

| 特性 | Jekyll | Hugo |
|------|--------|------|
| 语言 | Ruby | Go |
| 构建速度 | ~5-10 秒 | **~250ms** |
| 安装 | 需 Ruby + Gem | **单二进制** |
| 配置 | `_config.yml` | `hugo.toml` |
| 主题生态 | 丰富 | 丰富 |

Hugo 最大的优势就是**快**——单二进制文件，没有任何依赖，构建 55 篇文章只要 250ms。PaperMod 主题默认就是白色极简风格，没有大图背景，几乎没有需要改动的地方。

---

## 迁移做了什么

### 1. 文章转换（55 篇）

原来的 Jekyll 文章格式：

```yaml
---
layout: post
title: "Introduction to Linear Programing"
date: 2025-09-14 23:54:39 +0800
author: "farmer3-c"
header-img: "img/post-bg-2015.jpg"
mathjax: true
tags: []
---
```

转换为 Hugo 格式：

```yaml
---
title: "Introduction to Linear Programing"
date: "2025-09-14T23:54:39+08:00"
author: "farmer3-c"
mathjax: true
tags: []
---
```

主要变化：删掉了 `layout`、`header-img` 等 Jekyll 特有字段，日期改为 ISO 8601 格式。

### 2. 资源迁移

- `img/` → `static/img/`（路径不变，文章中的图片引用不受影响）
- `pdf/` → `static/pdf/`
- 删除了所有背景大图（`*-bg-*.jpg`）

### 3. 功能集成

| 功能 | 实现 |
|------|------|
| 评论区 | Utterances（基于 GitHub Issues） |
| LaTeX | MathJax 3 支持 `$..$`、`$$..$$` |
| 搜索 | PaperMod 内置 Fuse.js |
| 标签 | 自动标签页 `/tags/` |
| RSS | 自动生成 `/index.xml` |
| 字体 | Times New Roman + 宋体 |
| 深色模式 | 自动跟随系统 |
| 代码复制 | 一键复制代码块 |

---

## 新博客使用指南

### 环境准备

```bash
# 安装 Hugo（Windows）
# 从 https://github.com/gohugoio/hugo/releases 下载 hugo_extended 版本
# 解压后添加到 PATH 即可

# 验证安装
hugo version
```

### 本地预览

```bash
# 在博客根目录启动服务器
hugo server

# 浏览器访问 http://localhost:1313/
# 修改文件后自动刷新
```

### 新建文章

```bash
hugo new content posts/my-new-post.md
```

然后在 `content/posts/my-new-post.md` 中编辑：

```yaml
---
title: "文章标题"
description: "文章摘要"
date: "2026-06-28T23:00:00+08:00"
author: "farmer3-c"
tags:
  - Tag1
  - Tag2
mathjax: true  # 如果用到 LaTeX 则启用
draft: false
---
```

### 添加图片

将图片放到 `static/img/` 目录下，在文章中引用：

```markdown
![描述](/img/your-image.png)
```

### 添加 PDF

将 PDF 放到 `static/pdf/` 目录下：

```markdown
[下载文档](/pdf/filename.pdf)
```

### 部署

推送到 GitHub 即可自动构建部署：

```bash
git add -A
git commit -m "更新"
git push origin main
```

GitHub Actions 会自动运行 Hugo 构建，将 `public/` 目录部署到 GitHub Pages。

---

## 文件结构

```
farmer3-c.github.io/
├── hugo.toml              # 主配置文件
├── content/
│   ├── posts/             # 所有文章
│   ├── about/             # 关于页面
│   └── search.md          # 搜索页
├── static/
│   ├── img/               # 图片资源
│   ├── pdf/               # PDF 文件
│   └── CNAME              # 自定义域名
├── layouts/
│   └── partials/
│       ├── comments.html  # Utterances 评论
│       └── extend_head.html  # MathJax 3
├── assets/
│   └── css/extended/
│       └── custom.css     # 自定义样式
└── .github/workflows/
    └── hugo.yml           # 自动部署
```

---

## 总结

这次迁移大概花了一晚上的时间，最耗时的是 55 篇文章的格式转换和内部链接检查。迁移之后，博客构建速度从秒级降到了毫秒级，主题干净了很多，写文章的体验也好了不少。

希望这篇记录对想从 Jekyll 迁移到 Hugo 的朋友有帮助 😄
