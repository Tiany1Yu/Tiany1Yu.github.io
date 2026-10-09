# 发布文章、笔记与项目

本站是 **Astro/Fuwari 静态博客**，内容存储在 GitHub 仓库。**推荐使用 [Pages CMS](https://app.pagescms.org/) 在网页上发表或修改文章、笔记和项目**：保存时由后台自动提交到 `master`，GitHub Actions 自动重新发布。

初次使用需要 GitHub App 授权；详细操作、安全设置和图片上传说明见 **[Pages CMS 首次接入与日常使用](PAGES_CMS_SETUP.md)**。本文件以下内容是 GitHub 网页和 VS Code 手动发布的备用工作流。

## 路径对应关系

| 类型 | Markdown 保存路径 | 发布后的地址 |
| --- | --- | --- |
| 文章 | `astro/src/content/posts/writing/<slug>.md` | `/posts/writing/<slug>/`，入口 `/writing/` |
| 笔记 | `astro/src/content/posts/notes/<slug>.md` | `/posts/notes/<slug>/`，入口 `/notes/` |
| 项目 | `astro/src/content/projects/<slug>.md` | `/projects/<slug>/`，入口 `/projects/` |
| 图片 | `assets/img/projects/example.png` | `/assets/img/projects/example.png` |

`slug` 建议使用全英文小写、数字和短横线，例如 `gui-world-model`。

## 备用方式一：GitHub 网页直接发（不需要第三方 App）

1. 在 `Tiany1Yu/Tiany1Yu.github.io` 仓库打开相应内容文件夹。
2. 点击 **Add file → Create new file**，输入如 `gui-world-model.md`，以同类型旧文件的 frontmatter 为模板。
3. 贴上 Markdown 内容。先设 `draft: true` 可让内容不发布；确定发布时改为 `draft: false`。
4. 点击 **Commit changes**（可直接提交到 `master`，也可创建 Pull Request 预览）。
5. 打开仓库 **Actions → Deploy Astro blog to GitHub Pages**，等待 Build 和 Deploy 均变绿。通常几分钟后新页面可访问。

**注意：** GitHub 网页编辑器本身不会渲染本博客的 Astro 布局；若需要正式发布前浏览器预览，使用方式二。

## 备用方式二：Windows 本地写作（大规模修改、长篇公式）

1. 在仓库目录打开 PowerShell，进入 `astro`。
2. 使用脚手架新建草稿：
   ```powershell
   npm run new-post -- writing my-article
   npm run new-post -- notes rl-basics
   npm run new-post -- projects gui-world-model
   ```
   命令只需运行其中一条；默认 `draft: true`，并且拒绝覆盖已有文件。
3. 用 VS Code 编辑生成的 `.md`，设置文章标题、简介、日期，插入正文与公式。
4. 在仓库根目录双击 `start-local.bat` 预览 `http://127.0.0.1:4321/`；若是草稿，文章与笔记在本地开发模式可见，项目需先临时设为 `draft: false` 才会在项目页显示。
5. 确认无误后改 `draft: false`，在 `astro` 内执行 `npm run build:stable`。
6. 回到仓库根目录执行 `git add .`、`git commit -m "post: add rl basics"`、`git push origin master`。

**普通文章日常发布请用普通 `git commit`；不要每次都 `--amend` 或强推。** 这样才有完整的写作历史、可恢复旧版本。当前站点重构时要求的单提交 amend 是一次性的维护方式。

## frontmatter 模板

文章/笔记：
```yaml
---
title: "我的新笔记"
published: "2026-10-09"
description: "一句话摘要"
tags: ["强化学习"]
category: "笔记花园"
draft: false
lang: zh_CN
---

在这里写正文，支持 `$x^2$` 行内公式及单独成行的 `$$` 公式。
```

项目：
```yaml
---
title: "GUI World Model"
description: "项目的简短介绍"
venue: ""
date: "2026-05-18"
image: "/assets/img/projects/gui-overview.png"
github: "https://github.com/Tiany1Yu"
draft: false
---

项目简介与重点工作。
```

项目可选 `paper: "https://..."`，会显示论文按钮。将新图放在 `assets/img/projects/`（或用 Pages CMS「图片素材」上传），`image` 填写网站路径 `/assets/img/projects/文件名.png`。项目的 `date` 是记录日期（YYYY-MM-DD），不要将仓库创建日期误写成论文正式发表日期。

## 本地可视化编辑器

运行 `start-local.bat` 时，还可以打开 `http://127.0.0.1:4321/admin/` 访问 **Decap CMS**，目前已配置文章、笔记和项目三类编辑入口。但此前仅验证了本地界面/读取流程，**尚未验证真实保存和图片上传**。

公开站点的 `/admin/` **仅提供 [Pages CMS](https://app.pagescms.org/) 的跳转入口**，不是独立的身份认证服务；Pages CMS 完成 GitHub App 安装授权后可通过其网页编辑并自动提交。未经真实授权和保存测试之前，不声称已具备线上写入权限。

## 注意事项

- 不要在旧根目录的 `_posts/`、`_notes/` 下发表新内容；那是历史 Jekyll 源文件备份，线上文章来自 `astro/src/content/`。
- 只有 `draft: false` 才能进入正式构建；项目列表只展示非草稿。
- 请用 UTF-8 保存中文 Markdown。
- 图片路径以站点根目录的 `/` 开头，`public/` 这一段不要写入链接。
- 数学公式优先使用规范的 Markdown KaTeX 语法。单行 `$...$`，块公式 `$$` 单独成行，避免在 `\\text{中文}` 内再嵌套原始 `$...$`。
