# to_be_posted 使用说明

把每篇待发布内容放在本目录下的一个子文件夹中：

```text
to_be_posted/
  my-post/
    post.md
    cover.jpg
    imgs/
      fig 1.png

  note-my-note/
    note.md
    cover.png
    image.png
```

规则：
- 子文件夹名以 `note-`、`note_` 或 `note ` 开头时，发布到 `_notes/`；其他文件夹默认发布到 `_posts/`。
- 每个子文件夹至少包含一个 `.md` 文件；如果有多个，脚本使用按文件名排序后的第一个。
- 非 `.md` 文件会复制到 `assets/img/posts/<日期-slug>/` 或 `assets/img/notes/<日期-slug>/`。
- 文章和笔记都支持封面。优先使用 front matter 里的 `img`；没有 `img` 时，会优先选择文件名以 `cover`、`thumb`、`poster`、`banner` 或包含 `封面` 的图片作为封面。
- Markdown 图片和 HTML `<img src="">` 中的本地相对路径会自动改写为站点可访问路径；外链、根路径、锚点、data URI 和 Liquid 变量不会被改写。
- `_posts` 输出文件名格式为 `yyyy-mm-dd-safe-slug.md`；`_notes` 输出文件名格式为 `safe-slug.md`，页面 URL 会由日期生成 `/notes/yyyy-mm-dd-safe-slug.html`。
- 非法文件名字符、路径分隔符和连续空白会被清理，重名时自动追加 `-1`、`-2`。
- 处理完成后，原始文件夹会移动到 `to_be_posted/_processed/`，避免重复导入。

发布：
1. 双击仓库根目录的 `publish-from-staging.bat`。
2. 或在仓库根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\publish-from-staging.ps1
```
