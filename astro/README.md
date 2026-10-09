# Uke's Blog — official Fuwari template adaptation

Upstream: https://github.com/saicaca/fuwari @ `6d39b0d`. Official MIT license retained at `LICENSE`. This is a real Fuwari Astro 5 + Svelte + Tailwind site, not a visual clone.

## Local development

Run `corepack pnpm install` once. Double-click `../start-local.bat` for the site and CMS at `http://127.0.0.1:4321/` and `/admin/`. Stop with `../stop-local.bat`. The CMS API is restricted to localhost on port 8081.

## Changes from upstream

- Native Fuwari components, cards, sidebar, transitions, archive, Pagefind and Markdown renderer, with the partial-height demo banner replaced by a full-viewport wallpaper and legible glass surfaces.
- 5 migrated articles and 6 notes. Original `_posts/` and `_notes/` files remain unchanged; six Fuwari rendering copies are deterministically normalized from MathJax syntax to KaTeX by `scripts/normalize-legacy-math.mjs`.
- Writing, Notes, Projects and About pages; projects are Markdown records in `src/content/projects/` with generated detail routes.
- Original Obsidian WikiLinks, KaTeX, 127 legacy media files plus locally tracked project imagery, archived legacy redirects and reference pages.
- Local CMS for Git-backed Markdown editing. Real local development search at `/search-index.json` (upstream uses mock data in dev).
- URL alias map: `src/data/legacy-aliases.json`; static aliases emitted by `scripts/generate-legacy.mjs`.

## Publishing content

See [`docs/PUBLISHING.md`](docs/PUBLISHING.md) for GitHub web editing, local Markdown drafts, media paths and Projects publication. Use `npm run new-post -- writing|notes|projects slug` to create a draft.

## Tests and safety

Run `npm run build:stable` (check + build + Pagefind + old URLs), `npm run test:e2e` (Chrome), and `npm run test:cms`. Migration can be repeated intentionally via `python scripts/migrate-legacy.py` with PyYAML; DO NOT re-import on top of CMS edits without backups.

Original Jekyll sources remain at repository root. The profile avatar (`Myself.jpg`), tagline and site name were restored from `_config.yml`; the accent palette derives from original MVM palette SVGs. Wallpaper sources and attribution are documented in `public/wallpapers/ATTRIBUTION.md`. Run `npm run test:e2e` to include 22 Chrome tests covering themes, mobile, original identity, full-length wallpapers and all 11 posts' math rendering.  Previous iterations remain in Git history where available. Production GitHub OAuth, image upload and publishing have not yet been verified. Deployment is triggered by GitHub Actions on pushes to the repository default branch `master` and publishes `astro/dist` to GitHub Pages.
