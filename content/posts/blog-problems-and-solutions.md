---
title: 博客优化问题与解决方案总结
description: Jekyll 博客遇到的问题及修复方法
date: '2026-05-16T01:00:00+08:00'
author: farmer3-c
tags:
- Jekyll
- Blog
- Tutorial
mathjax: true
draft: false
---
# 博客优化问题与解决方案总结

最近对博客进行了多次优化，遇到了各种问题，现在总结一下遇到的问题及解决方案，供大家参考。

## 1. Service Worker 自动刷新问题

### 问题描述
博客添加了 Service Worker 后，每次检测到更新都会显示 "Content updated. REFRESH" 按钮，需要手动点击刷新。

### 解决方案
修改 `js/sw-registration.js`，移除手动刷新提示，直接使用 `location.reload()`。

```javascript
if(data.command == "UPDATE_FOUND"){
  console.log("UPDATE_FOUND_BY_SW", data);
  // 自动刷新页面，无需手动点击
  location.reload();
}
```

### 后续问题
启用自动刷新后，网站出现了**无限刷新循环**的问题，用户体验极差。

### 最终解决方案
移除 Service Worker 的自动刷新机制，改用 Stale-While-Revalidate 缓存策略：
- 优先显示缓存内容
- 后台更新缓存
- 用户下次访问时自然看到新内容

---

## 2. 导航栏显示文章标题问题

### 问题描述
导航栏突然显示了文章标题 "编译实践Lv1. main 函数"，而不是正常的页面链接。

### 根本原因
之前误将一篇博客文章放到了 `css/` 文件夹，Jekyll 将其当作页面处理，导致导航栏循环显示所有有 title 的页面。

### 解决方案
**彻底解决方案：** 硬编码导航栏，只显示固定页面。

修改 `_includes/nav.html`：

```html
<ul class="nav navbar-nav navbar-right">
  <li>
    <a href="{{ site.baseurl }}/">Home</a>
  </li>
  <li>
    <a href="{{ site.baseurl }}/about/">About</a>
  </li>
  <li>
    <a href="{{ site.baseurl }}/archive/">Archive</a>
  </li>
  <li class="search-icon">
    <a href="javascript:void(0)">
      <i class="fa fa-search"></i>
    </a>
  </li>
</ul>
```

同时从 git 历史中彻底移除误放的文章。

---

## 3. About 和 Archive 页面 404 问题

### 问题描述
点击导航栏的 About 和 Archive，跳转到 `/about.html` 和 `/archive.html`，显示 404 错误。

### 原因
博客使用了 `permalink: pretty` 配置，正确的 URL 应该是 `/about/` 和 `/archive/`（带斜杠），而不是 `.html` 结尾。

### 解决方案
修改导航栏链接格式：

```html
<!-- 修改前 -->
<a href="{{ site.baseurl }}/about.html">About</a>
<a href="{{ site.baseurl }}/archive.html">Archive</a>

<!-- 修改后 -->
<a href="{{ site.baseurl }}/about/">About</a>
<a href="{{ site.baseurl }}/archive/">Archive</a>
```

---

## 4. GitHub Pages 构建队列卡住问题

### 问题描述
推送代码后，GitHub Actions 一直显示 "Queued" 状态，超过 10 分钟甚至更久都没有构建。

### 原因分析
这是 **GitHub 服务本身的问题**，不是代码问题。根据 GitHub Status 页面显示，GitHub Actions 服务正在经历事故（Incident）。

### 解决方案

1. **等待 GitHub 修复**
   - 通常需要 30 分钟到几小时
   - 关注 https://www.githubstatus.com/ 获取最新状态

2. **检查 GitHub 服务状态**
   - GitHub Status: https://www.githubstatus.com/
   - Twitter: @githubstatus
   - Downdetector: downdetector.com/status/github

3. **本地验证代码正常**
   ```bash
   bundle exec jekyll build
   ```
   如果本地构建成功，说明代码没问题，只是 GitHub 服务问题。

### 预防措施
- 推送代码前先在本地预览
- 避免在 GitHub 服务不稳定时推送重要更新

---

## 5. 新文章推送后不显示问题

### 问题描述
新写的文章 `git push` 之后在博客网站没有显示。

### 常见原因

1. **文件名格式问题**
   - 要求：`YYYY-MM-DD-title.md`
   - 避免在文件名末尾使用特殊字符

2. **Front Matter 格式问题**
   ```yaml
   ---
   layout: post
   title: "文章标题"
   date: 2026-03-06
   tags: [Tag1, Tag2]  # 标签用逗号分隔，不要有空格
   ---
   ```

3. **标签格式问题**
   ```yaml
   # 错误：包含空格的标签
   tags: [Algorithm programming problem]

   # 正确：逗号分隔或加引号
   tags: [Algorithm, programming, problem]
   # 或
   tags: ["Algorithm programming problem"]
   ```

### 解决方案
- 确保文件名格式正确
- 检查 front matter 格式
- 修复后重新提交推送

---

## 6. LaTeX 数学公式渲染失败问题

### 问题描述
博客中的 LaTeX 代码显示为纯文本 `[Math Processing Error]`，无法正常渲染。

### 解决方案
更新 MathJax 配置到稳定版本。

修改 `_includes/mathjax_support.html`：

```html
<script type="text/x-mathjax-config">
  MathJax.Hub.Config({
    tex2jax: {
      inlineMath: [ ['$','$'], ['\\(','\\)'] ],
      displayMath: [ ['$$','$$'], ['\\[','\\]'] ],
      processEscapes: true
    },
    TeX: {
      equationNumbers: { autoNumber: "AMS" },
      extensions: ["AMSmath.js","AMSsymbols.js"]
    },
    "HTML-CSS": {
      scale: 100
    }
  });
</script>
<script src="https://cdn.jsdelivr.net/npm/mathjax@2/MathJax.js?config=TeX-AMS_HTML"></script>
```

### 使用方法

确保文章头部开启了 mathjax：

```yaml
---
mathjax: true
---
```

支持的语法：

| 类型 | 语法 | 示例 |
|------|------|------|
| 行内公式 | `$...$` | $E=mc^2$ |
| 行间公式 | `$$...$$` | $$\int_0^1 x^2 dx$$ |
| 括号公式 | `\[...\]` | \[a^2 + b^2 = c^2\] |

---

## 7. 添加相关文章侧边栏功能

### 功能描述
在文章页面左侧显示同标签的其他文章列表，方便读者浏览相关内容。

### 解决方案

1. 创建 `_includes/related-posts.html`

```html
{% if page.tags.size > 0 %}
<div class="related-posts">
    <hr class="hidden-sm hidden-xs" style="margin: 0 0 20px 0;">
    <h5 style="color: #333; margin-bottom: 15px; font-size: 14px; font-weight: bold;">相关文章</h5>
    <ul class="related-posts-list">
        {% assign current_url = page.url %}
        {% assign tag_posts = "" | split: "" %}

        {% for tag in page.tags %}
            {% for post in site.tags[tag] %}
                {% unless post.url == current_url %}
                    {% unless tag_posts contains post %}
                        {% assign tag_posts = tag_posts | push: post %}
                    {% endunless %}
                {% endunless %}
            {% endfor %}
        {% endfor %}

        {% for post in tag_posts limit: 10 %}
        <li>
            <a href="{{ post.url | prepend: site.baseurl }}">
                {{ post.title | truncate: 28 }}
            </a>
        </li>
        {% endfor %}
    </ul>
</div>
{% endif %}
```

2. 修改 `_layouts/post.html`，在左侧添加：

```html
<!-- Left Sidebar - Related Posts -->
<div class="col-lg-2 visible-lg-block sidebar-container">
    {% include related-posts.html %}
</div>
```

---

## 总结

| 问题 | 状态 | 解决方案 |
|------|------|----------|
| 自动刷新 | ✅ 已解决 | 移除自动刷新，改用自然更新 |
| 导航栏异常 | ✅ 已解决 | 硬编码导航栏 |
| 页面 404 | ✅ 已解决 | 修复链接格式 |
| GitHub 构建卡住 | ⏳ 等待恢复 | 等待 GitHub 服务修复 |
| 文章不显示 | ✅ 已解决 | 修复文件名和标签格式 |
| LaTeX 渲染失败 | ✅ 已解决 | 更新 MathJax 配置 |
| 相关文章功能 | ✅ 已实现 | 添加侧边栏组件 |

---

## 经验教训

1. **本地预览很重要** - 推送前先在本地测试
2. **GitHub 服务也会出问题** - 遇到问题先检查服务状态
3. **文件名和格式要规范** - 遵循 Jekyll 的命名规则
4. **做好备份** - 重要修改前先 commit

---

*本文持续更新中...*
