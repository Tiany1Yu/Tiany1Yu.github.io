# Pages CMS：一次性授权与日常使用

本站已经在仓库根目录提供 [`.pages.yml`](../../.pages.yml)，无需你自己新建配置或填写 OAuth 密钥。编辑器为官方托管实例 [app.pagescms.org](https://app.pagescms.org/)，内容仍然保存在当前 GitHub 仓库中。

## 你只需要完成的一次性授权

1. 打开 <https://app.pagescms.org/>，点击 **Sign in with GitHub**，登录博客仓库的 GitHub 所有者账户。
2. 按 Pages CMS 的提示安装 GitHub App。**Repository access** 选择 **Only select repositories**，仅勾选 `Tiany1Yu/Tiany1Yu.github.io`。阅读申请的仓库权限后确认安装。不要选择所有仓库，亦不要把个人令牌、密码粘贴到博客。
3. 返回 Pages CMS。如果界面需要选仓库，选择 `Tiany1Yu/Tiany1Yu.github.io`；选择 **master** 分支。
4. Pages CMS 会读取仓库根目录现有的 `.pages.yml`，显示 **文章、笔记花园、项目、图片素材**。**不需要再次创建或覆盖 `.pages.yml`**。
5. 第一次建议创建一篇简短的**草稿**作为测试（保持「草稿」开启），保存后检查 GitHub 仓库自动出现一次提交；它不应出现在正式网站上。然后在编辑器里关闭草稿再保存，即触发线上发布，等待仓库 **Actions → Deploy Astro blog to GitHub Pages** 里的 Build / Deploy 成功。
6. 今后把 <https://app.pagescms.org/> 加入书签即可。正式站点的 `/admin/` 也提供 Pages CMS 跳转入口。

首次保存和图片上传是否正常，需要在你实际授权后做一次联调，目前无法假装已经验证了 GitHub App 写入权限。

## 日常工作流

- **新建文章**：选择「文章」→ **New** → 标题和日期、分类、标签 → 编辑 Markdown 正文 → 保存草稿或关闭草稿公开。
- **新建笔记**：选择「笔记花园」→ **New** → 填标题、日期 → Markdown 源码模式写数学公式、Obsidian 链接等 → 保存。
- **新建项目**：选择「项目」→ **New** → 填年份、标题、会议期刊、主图、GitHub / 论文链接 → 保存。
- **插入图片**：从「图片素材」上传，存储路径固定为 `astro/public/assets/img/uploads/`，发表时引用 `/assets/img/uploads/图片名.png`。主图使用图片选择控件，Markdown 源码中可复制素材的公开 URL。
- **更新现有内容**：打开条目修改并保存；有需要可修改「更新日期」。不会要求你手动执行 `git add / commit / push`。
- **查看发布状态**：前往 <https://github.com/Tiany1Yu/Tiany1Yu.github.io/actions>，等最新 `Deploy Astro blog to GitHub Pages` 完成，再访问 <https://tiany1yu.github.io/>。

**保存操作本质上依然会产生普通 Git 提交。** 这是预期设计，可以追踪修改和回滚，不是需要手动整理的无用提交。不要对 Pages CMS 的日常内容提交做长期 `git commit --amend` 或 `force push`，否则会让后台缓存与其他编辑者的版本历史发生冲突。

## 已做好的安全约束

- 每个新条目的 `draft` 默认是 `true`，需要手动关闭才会公开。
- Pages CMS 启用了 `settings.content.merge: true`，旧 Markdown 没展示的 `slug` 等字段会保留，不会因为 CMS 字段表较短就丢失。
- 为保护既有链接，编辑器禁止直接重命名或删除文章、笔记和项目文件。若确实需要删除，请通过 GitHub 仓库操作。
- 文章和笔记正文使用 Markdown **源码编辑器**，避免可视化富文本重排复杂 LaTeX、内链、HTML 与自定义指令；项目介绍提供可切换的富文本/源码编辑器。
- 在 GitHub App 授权时仅选择本仓库；不需要配置新服务器、数据库、永久访问令牌或自建 OAuth Proxy。

## 其他编辑方式

如暂时不想授予任何第三方应用仓库写权限，你仍可以在 GitHub 网页直接修改 Markdown，或通过 Windows 的 VS Code 编辑并正常 `git commit`、`git push`。当前本地 `start-local.bat` 仍提供只限本机的 Decap CMS 测试环境；它**不是**正式线上发布后台。
