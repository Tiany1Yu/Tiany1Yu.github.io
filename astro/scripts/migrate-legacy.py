"""Lossless Jekyll -> Fuwari post migration. Requires PyYAML.
Original _posts, _notes and their Markdown bodies are never modified.
"""
from pathlib import Path
from datetime import date, datetime
from hashlib import sha256
import subprocess
import json
import re
import unicodedata
import yaml

ROOT = Path(__file__).resolve().parents[2]
TARGET = ROOT / "astro/src/content/posts"
ALIASES = ROOT / "astro/src/data/legacy-aliases.json"

def slugify(text):
    s = unicodedata.normalize("NFKC", text).lower().strip()
    s = re.sub(r"\.(md|markdown)$", "", s)
    s = s.replace("&", "-").replace("_", "-")
    s = re.sub(r"\s+", "-", s)
    s = re.sub(r"[^\w\-\u3400-\u9fff]", "", s, flags=re.UNICODE)
    return re.sub(r"-+", "-", s).strip("-")

def import_entry(path, kind, aliases):
    raw = path.read_bytes().removeprefix(b"\xef\xbb\xbf")
    m = re.match(rb"\A---[ \t]*\r?\n(.*?)\r?\n---[ \t]*\r?\n", raw, re.S)
    if not m: raise ValueError(f"Missing frontmatter: {path}")
    old = yaml.safe_load(m.group(1).decode("utf-8")) or {}
    body = raw[m.end():]
    dt = old.get("date") or old.get("published")
    if not dt: raise ValueError(f"Missing date: {path}")
    pub = dt.strftime("%Y-%m-%d") if isinstance(dt,(datetime,date)) else str(dt)[:10]
    updated = old.get("last_modified_at")
    if updated:
        updated = updated.strftime("%Y-%m-%d") if isinstance(updated,(datetime,date)) else str(updated)[:10]
    img = str(old.get("cover") or old.get("img") or "").strip()
    if img and not re.match(r"^(https?://|/)",img):
        img = "/assets/img/" + img.removeprefix("assets/img/")
    tags = old.get("tags") or []
    if isinstance(tags, str): tags = [tags]
    tags = [str(t) for t in tags]
    category = ("笔记花园" if kind == "notes" else
                "随想" if any("自我思索" in t or "随想" in t for t in tags) else
                "课程与实践" if any("作业" in t for t in tags) else
                "AI · 技术")
    stem = path.stem
    if kind == "writing":
        stem = re.sub(r"^\d{4}-\d{2}-\d{2}-", "", stem)
    slug = slugify(stem)
    canonical = f"/posts/{kind}/{slug}/"
    meta = {"title": str(old["title"]), "slug": f"{kind}/{slug}",
            "published": pub, "description": str(old.get("description") or ""),
            "tags": tags, "category": category, "draft": False, "lang": "zh_CN"}
    if updated: meta["updated"] = updated
    if img: meta["image"] = img
    dest = TARGET / kind / (stem + ".md")
    dest.parent.mkdir(parents=True, exist_ok=True)
    preamble = "---\n"+yaml.safe_dump(meta,allow_unicode=True,sort_keys=False)+"---\n"
    dest.write_bytes(preamble.encode("utf-8") + body)
    assert sha256(body).digest() == sha256(dest.read_bytes()[len(preamble.encode("utf-8")):]).digest()
    aliases[f"/{kind}/{slug}/"] = canonical
    if kind=="notes":
        aliases[f"/notes/{pub}-{slug}.html"] = canonical
    else:
        aliases[f"/{slug}.html"] = canonical
    print(f"{kind}: {path.name} => {slug} ({len(body)} body bytes preserved)")

aliases = {
    "/archive.html": "/archive/", "/tag.html": "/archive/",
    "/tags.html": "/archive/", "/notes.html": "/notes/",
    "/about.html": "/about/", "/subscribe.html": "/rss.xml",
}
for kind, source in [("writing",ROOT/"_posts"), ("notes",ROOT/"_notes")]:
    for f in sorted(source.glob("*.md")):
        import_entry(f,kind,aliases)
aliases["/notes/reinforceactor-critic/"] = "/posts/notes/reinforce-actor-critic/"
ALIASES.parent.mkdir(parents=True,exist_ok=True)
ALIASES.write_text(json.dumps(aliases,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(f"Generated {len(aliases)} historical aliases.")
subprocess.run(["node", str(ROOT / "astro/scripts/normalize-legacy-math.mjs")], cwd=ROOT / "astro", check=True)
