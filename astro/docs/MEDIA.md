# 图片素材目录约定

本站图片的**唯一源目录**是仓库根目录 `assets/img/`，Pages CMS 的「图片素材」直接管理这个目录。

- `Myself.jpg`：博客作者头像。
- `branding/`：当前导航品牌图标、站点 favicon。
- `posts/`：已发表文章的封面、正文配图及演示视频；保留文章中的原有路径。
- `notes/`：笔记封面和正文图片；保留笔记中的原有路径。
- `projects/`：研究项目主图等素材，现有医疗多智能体综述为 `projects/medical-multi-agent-survey.png`。

旧模板截图、Stock 示例图、历史 404 图片和未使用的实验图版本已从当前素材库移除（Git 历史中仍能恢复）。不要批量重命名已在文章中引用的资源。

`astro/public/assets/img/` **只是本地构建镜像**，由 `astro/scripts/sync-assets.mjs` 每次从根目录重建；不要直接向这个忽略的目录保存图片。源码中的图片 URL 从 `/assets/img/` 开始，例如 `/assets/img/projects/medical-multi-agent-survey.png`。

如需新增项目图，优先在 Pages CMS「图片素材」的 `projects/` 文件夹里上传，并在项目 `image` 字段选中它；其他栏目放到对应的 `posts/` 或 `notes/` 文件夹。
