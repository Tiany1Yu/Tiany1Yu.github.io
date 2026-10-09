# 网站背景图

当前背景：`user-night-desk.avif`，由站点作者于 2026-10-08 在聊天中直接提供的夜景插画（原附件 2048×1153）；为了减少页面加载体积，以 AVIF 进行有损压缩，并保留原图尺寸。图片仅作为本站背景使用。

备用壁纸：`original-brand-background.jpg`（原博客 3456×2304 品牌背景）及 `misty-blue-mountains.jpg`（Unsplash：https://unsplash.com/photos/misty-forest-landscape-over-dark-water-K9H1FxRLY5Q，适用 Unsplash License）。

如需替换，在 `astro/public/styles/local-glass.css` 修改所有 `url("/wallpapers/user-night-desk.avif")`，在 `astro/src/config.ts` 同步修改 `banner.src`。背景使用 `background-size: cover`，保证长篇文章下方不出现空白。
