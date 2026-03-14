# to_be_posted 使用说明

把每篇待发布文章放在本目录的一个子文件夹中，结构示例：

```
to_be_posted/
  20260314-ai-note/
    post.md
    cover.jpg
    imgs/
      fig1.png
```

要求与规则：
- 每个文章子目录至少包含一个 `.md` 文件（若多个，默认使用按文件名排序后的第一个）。
- 目录中的非 `.md` 文件会被复制到 `assets/img/posts/<日期-目录名>/`。
- 脚本会自动补全 front matter：`layout/read_time/show_date/title/date/img/tags/author`。
- 不会写入 `description` 字段。
- 处理完成后，原目录会被移动到 `to_be_posted/_processed/`，避免重复导入。

如何发布：
1. 回到仓库根目录。
2. 双击 `publish-from-staging.bat`。
3. 新文章会生成到 `_posts/`。
