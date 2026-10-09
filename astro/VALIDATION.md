# Uke's Blog：Fuwari 全量重构验收（2026-10-08）

## 版本与原则

- 本地 Git 分支：`refactor/fuwari-rebuild`（只在本地）。
- 上游模板：`saicaca/fuwari`，基线 commit `6d39b0d`，MIT 许可原文位于 `astro/LICENSE`。
- 完整替换了原先自制的 Astro 组件和视觉样式，不采用旧 glass UI；保留原 Jekyll 内容/媒体和 Git 历史回滚能力。

## 已通过的项目

| 项目 | 实际结果 |
| --- | --- |
| 内容迁移 | 原始 Jekyll 5 篇文章 + 6 篇笔记未改动；11 篇 Fuwari 正文与原文经幂等 MathJax→KaTeX 兼容转换后逐篇一致 |
| 旧网址兼容 | 29/29 历史 HTML URL 存在，17 个额外静态重定向由脚本生成 |
| 原始媒体 | 127 项已同步并打包 |
| Astro / Fuwari 构建 | 已生成 31 个页面（移除 Projects），含首页、文章、笔记、CMS、RSS 等 |
| 搜索 | Pagefind 已索引 12 个有效页面；开发模式改为真实索引，不用假结果 |
| Windows 本地测试 | 原 `start-local.bat` + `stop-local.bat` 继续可用，Node22 固定为项目本地依赖，4321/8081 均绑定 loopback |
| Chrome 开发端 | 功能 9/9 + 新增亮暗色/壁纸/LaTeX 10/10 测试通过 |
| Chrome 静态预览端 | 9/9 E2E 测试通过 |
| Decap CMS | 页面载入、登录、文章集合及既有文章 Markdown 编辑器只读打开成功 |

## 关键修复

- Fuwari 原生 Astro5/Svelte5 的组件类型边界（LightDarkSwitch 与 ArchivePanel）适配当前依赖。
- 保留 Fuwari 的原生布局/导航/卡片/搜索/过渡；只调整中文配置、内容分类与个人资料。
- Jekyll/旧 Astro URL 在开发模式用 middleware 重定向，正式构建通过生成物理 HTML 重定向。
- 避开本机全局 Node24 引发的 Astro build 随机退出，`npm run build:stable` 固定使用项目内 Node 22.23.3。
- 开发模式使用真正的 `/search-index.json`，且对搜索摘要进行 HTML 转义。

## 尚未声明验收的部分

- 生产环境 GitHub OAuth 和线上 CMS 保存/发布流程（当前仅本地后端）。
- 本地 CMS 新建、实际保存、撤销和图片上传的端到端写入测试。
- 人工审美偏好：需要在实际浏览器检查 Fuwari 主题，继续按反馈调整配置，不回退到自制 UI。
- Pagefind 对中文不做词干匹配；已能进行搜索，但中文复杂分词可以后续增强。

## 本地操作

- 根目录双击 `start-local.bat`，访问 `http://127.0.0.1:4321/`。
- CMS：`http://127.0.0.1:4321/admin/`；停止：`stop-local.bat`。
- 在 `astro/` 运行 `npm run build:stable`、`npm run test:e2e`、`npm run test:cms`。

## 2026-10-08：第二轮视觉与数学兼容修复

- 移除 Projects 页面和导航链接。
- 根据旧 Jekyll _config.yml 恢复原站名称、Myself.jpg 头像、原头像下文案及 MVM Logo / favicon。
- 主色固定于原 MVM 冷蓝灰色系，隐藏颜色调节器，禁用旧 localStorage.hue 覆盖。
- 实测亮色标题与作者颜色 rgb(25,49,68)，暗色 rgb(241,246,251)。透明玻璃表面保持可读性。
- 默认局部花朵横幅改为本地 2560×1440 雾山固定全视口背景；另存旧站 3456×2304 原背景。来源见 public/wallpapers/ATTRIBUTION.md。
- 使用 public/styles/local-glass.css 独立样式层，避免干扰 Fuwari Tailwind @apply。
- 原 _posts 和 _notes 不修改；6 篇 Fuwari 渲染副本通过幂等脚本 normalize-legacy-math.mjs 兼容 MathJax 括号、align、多行编号。11 篇正文可根据源文件重建，Chrome 未检出 KaTeX 错误。
- npm run build:stable 通过（31 页、29/29 历史 URL、11/11 内容一致性检查、127 项媒体）。Chrome 开发和生产预览各 19/19 回归测试通过，涵盖全部数学文章、亮暗色、桌面手机与长文壁纸。

**本轮仍仅限本地：未推送、未部署。**

**没有执行任何 Git push、远端部署或生产分支切换。**
