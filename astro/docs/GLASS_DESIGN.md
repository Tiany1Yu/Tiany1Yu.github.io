# Moonlit Quartz — glass theme (V4 optical finish)

This is the V4 glass theme for the Fuwari-based blog. It was developed through four local iterations and released as **one squashed commit** on `master`. The earlier iteration commits are preserved on the local `design/prismatic-glass-local` branch; CMS and content files are unchanged.

## Why V3

V1 and V2 used four artificial radial light pools over the wallpaper and multiple cyan, pink, purple and orange bands **inside every panel**. Increasing transparency did not solve the competing colors. In V3 the provided night-desk artwork supplies the color; the UI becomes a quiet optical material that belongs to that illustration.

The new material is not an imported component library. It adopts principles from publicly available open-source demos:

- [glass-ui](https://github.com/ViShEsHK2412/glass-ui) — separate tint, rim highlight, ambient depth and shadow instead of piling up colored fills.
- [react-glass-rim](https://github.com/royroki/react-glass-rim) — a directional specular edge to imply surface curvature.
- [acrylic-mica-css](https://github.com/yell0wsuit/acrylic-mica-css) — restrained translucent acrylic materials with clear dark/light states.
- [LiquidGlassUI](https://github.com/hungduong-projects/LiquidGlassUI) — avoid blurred nested controls. Use the light rim and keep large reading surfaces stable.

No code or assets were copied from these projects; no library, WebGL, animation loop, runtime or network dependency was added.

## Current design

- **Light / Moonlit Pearl**: neutral warm-silver surface, about 23–33% tint, peak 15% directional reflection.
- **Dark / Smoked Quartz**: transparent graphite, about 23–30% tint, peak 8.5% reflection.
- **Edge**: one-pixel neutral directional rim, with the upper-left catching light and a subtle warm highlight from the illustrated lamp.
- **Accent**: the existing Fuwari accent for icons, focus and links, not a multicolor backdrop.
- **Blur**: desktop 12px light / 14px dark; mobile 8px; no nested blur on buttons.
- **Legibility**: opaque theme-aware text, a slight light-text reflection on small metadata, and high-contrast white free-standing collection headings.
- **Accessibility**: keyboard focus outlines, reduced-transparency solid fallback and reduced-motion handling.
- **Unchanged**: content, original wallpaper, projects and paper figure, original media, math, navigation, CMS and unboxed footer.

The standalone `public/styles/prismatic-glass.css` still loads after `local-glass.css` through `src/layouts/Layout.astro`. Remove just its link to disable this theme. The filename stays stable to avoid unnecessary code churn.

The local design branch preserves earlier looks (these are not individual commits on remote `master`):

- V1 `6496278` — vivid, heavily frosted rainbow glass.
- V2 `c303edb` — more transparent but still colorful.
- V3 `d6f5b15` — neutral Moonlit Quartz baseline.
- V4 `565ccec` — optical finishing: subtle interactive elevation, neutral badges/tags/metadata, readable transient popovers and scientific figure framing, with **unchanged persistent-panel transparency**.

## Local QA and screenshots

From the `astro/` directory:

```powershell
npm run build:stable
.\node_modules\node\bin\node.exe node_modules/astro/astro.js preview --host 127.0.0.1 --port 4322
```

In another terminal:

```powershell
node scripts/glass-visual-local.mjs
$env:E2E_ORIGIN='http://127.0.0.1:4322'
npm run test:e2e
```

The screenshot script saves 12 ignored screenshots to `.astro/e2e/glass/` across notes, projects and a math-heavy article, in both themes at 1440px/390px.

For V4 interaction checks, run `node scripts/glass-details-local.mjs`. It verifies real computed tag/count styles, scoped story hover lift (using independent CSS `translate` to coexist with upstream Fuwari entry animations), readable search and mobile menu popovers, and no horizontal overflow. It writes another eight ignored screenshots (`v4-search-*`, `v4-menu-*`, `v4-notes-*`). Transient panels have a slightly denser tint than the persistent reading surfaces for text contrast, but still use the same neutral optical rim and no rainbow colors. The survey diagram remains on clean white paper with a quiet surrounding well. It verifies surface/transmission alpha bounds, subdued neutral rim colors, absence of synthetic color-pool overlays, backdrop blur, legible collection titles and no horizontal overflow.

The published `master` history contains one consolidated glass-theme commit, not four incremental design commits. Future Pages CMS content edits should use normal commits instead of force-pushing rewritten history.
