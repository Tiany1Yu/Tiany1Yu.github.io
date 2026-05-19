# Uke's Blog

这是一个基于 Jekyll / GitHub Pages 的个人静态博客，主题来源于 Adam Blog 2.0，并在此基础上加入了文章与笔记花园的组织方式。

## 个人简介修改位置

个人简介的主要内容在 `_config.yml` 里修改：

- `author`: 作者名
- `author-pic`: 头像文件名，图片通常放在 `assets/img/`
- `about-author`: 简介正文
- `email`、`github`、`website`、`phone` 等：联系方式与社交链接

相关页面和组件：

- `_pages/about.html`: About / 个人介绍页面的结构
- `_includes/author-box.html`: 文章页面底部的作者信息卡片

如果只是改文字、头像、邮箱或 GitHub 链接，优先改 `_config.yml`。

## 项目结构

```text
.
├── _config.yml                 # Jekyll 站点配置、作者信息、插件与 collections 配置
├── index.html                  # 首页入口，主要展示正式文章
├── _posts/                     # 正式文章，文件名通常为 YYYY-MM-DD-slug.md
├── _notes/                     # 笔记花园 collection，生成到 /notes/
├── _pages/                     # 独立页面：about、archive、tags、笔记页等
├── _layouts/                   # 页面布局模板，例如 default、post、page
├── _includes/                  # 可复用 Liquid 组件，例如 header、footer、作者卡片、标签云
├── assets/
│   ├── css/                    # 样式文件
│   ├── img/                    # 图片资源
│   │   ├── posts/              # 正式文章图片
│   │   ├── notes/              # 笔记图片
│   │   └── stock/              # 通用图片
│   └── js/                     # 前端脚本
├── scripts/
│   └── publish-from-staging.ps1 # 从 to_be_posted 发布文章/笔记的 PowerShell 脚本
├── publish-from-staging.bat    # Windows 发布入口，负责定位仓库并调用 PowerShell 脚本
├── to_be_posted/               # 草稿暂存区；note- 前缀目录会发布到 _notes
├── all-posts.json              # 给前端使用的文章/笔记索引
├── search.json                 # 搜索索引
├── posts-by-tag.json           # 标签索引
├── sitemap.xml                 # 站点地图
├── feed.xml                    # RSS / Atom feed
├── Gemfile                     # Ruby / Jekyll 依赖
├── .github/workflows/          # GitHub Pages 自动构建与部署流程
└── _site/                      # Jekyll 构建后的静态产物；当前仓库中被跟踪
```

## 内容组织

正式文章放在 `_posts/`，适合完整、较正式、希望出现在首页分页里的内容。

笔记放在 `_notes/`，适合短笔记、概念整理、学习摘录、持续更新的 code garden 内容。笔记会生成到 `/notes/` 路径下，并合并展示在首页推荐和全部文章中。

常见 front matter 示例：

```yaml
---
layout: post
title: "文章标题"
date: 2026-05-19
tags: [note, ai]
---
```

## 发布流程

手动新增内容时：

1. 正式文章放入 `_posts/YYYY-MM-DD-slug.md`。
2. 笔记放入 `_notes/slug.md`，并在 front matter 中写好 `date`。
3. 图片放入 `assets/img/posts/` 或 `assets/img/notes/` 下对应目录。
4. 运行 `bundle exec jekyll build` 重新生成 `_site/`。

使用暂存区发布时：

1. 在 `to_be_posted/` 下创建一个文章文件夹。
2. 文件夹名以 `note-` 开头时发布到 `_notes/`，否则发布到 `_posts/`。
3. 运行 `publish-from-staging.bat`。
4. 发布完成后，原暂存目录会移动到 `to_be_posted/_processed/`。

更详细的暂存区规则见 `to_be_posted/README.md`。

## 本地预览与构建

```powershell
bundle exec jekyll serve
```

或使用仓库中的：

```powershell
.\start-local.bat
```

仅构建静态产物：

```powershell
bundle exec jekyll build
```

## 删除文章时要注意

如果想从网站中彻底删除一篇文章，通常需要同时处理：

1. 删除 `_posts/` 或 `_notes/` 中的源 Markdown。
2. 删除对应的图片资源目录，如果这些图片不再使用。
3. 重新运行 `bundle exec jekyll build`，让 `_site/` 中的静态页面和索引同步更新。
4. 检查 `to_be_posted/` 和 `to_be_posted/_processed/` 中是否还保留原始草稿副本。

因为当前仓库跟踪了 `_site/`，只删源文件但不重新构建时，旧 HTML 产物仍可能留在 `_site/` 里。
