// Synchronize the Pages CMS searchable tag dropdown with cms/tags/*.yml.
// This uses no npm dependencies, so GitHub Actions can run it without installs.
// Usage: node astro/scripts/sync-pages-tags.mjs [--check]
import { readFileSync, readdirSync, writeFileSync } from "node:fs";
import { resolve, join } from "node:path";

const repo = resolve(import.meta.dirname, "../..");
const configPath = join(repo, ".pages.yml");
const tagsPath = join(repo, "cms", "tags");
const checkOnly = process.argv.includes("--check");
const entries = readdirSync(tagsPath, { withFileTypes: true })
  .filter((f) => f.isFile() && /\.ya?ml$/i.test(f.name));
if (entries.length === 0) throw new Error("Tag library is empty: " + tagsPath);

function getTagName(filename) {
  const contents = readFileSync(join(tagsPath, filename), "utf8").replace(/^\uFEFF/, "");
  const lines = [...contents.matchAll(/^name:\s*(.+?)\s*$/gm)];
  if (lines.length !== 1) throw new Error("Tag entry requires exactly one name field: " + filename);
  const raw = lines[0][1].trim();
  let name;
  if (raw.startsWith('"')) name = JSON.parse(raw);
  else if (raw.startsWith("'") && raw.endsWith("'")) name = raw.slice(1, -1).replace(/''/g, "'");
  else name = raw.split(/\s+#/)[0].trim();
  if (typeof name !== "string" || !name || /[\r\n]/.test(name)) throw new Error("Invalid tag: " + filename);
  return name;
}
const tags = [...new Set(entries.map((file) => getTagName(file.name)))]
  .sort((a, b) => a.localeCompare(b, "zh-CN"));
const original = readFileSync(configPath, "utf8");
const matcher = /^          # BEGIN SYNCED TAG OPTIONS\r?\n[\s\S]*?^          # END SYNCED TAG OPTIONS/gm;
const blocks = [...original.matchAll(matcher)];
if (blocks.length !== 2) throw new Error("Expected two tag option blocks (writing and notes), got " + blocks.length);
const eol = original.includes("\r\n") ? "\r\n" : "\n";
const options = [
  "          # BEGIN SYNCED TAG OPTIONS",
  "          values:",
  ...tags.map((tag) => "            - " + JSON.stringify(tag)),
  "          # END SYNCED TAG OPTIONS",
].join(eol);
const updated = original.replace(matcher, options);
if (checkOnly) {
  if (updated !== original) throw new Error("Pages CMS tag choices are out of sync. Run node astro/scripts/sync-pages-tags.mjs");
  console.log("PASS: both tag dropdowns contain " + tags.length + " searchable choices.");
} else {
  if (updated !== original) writeFileSync(configPath, updated, "utf8");
  console.log((updated === original ? "Already synchronized: " : "Updated: ") + tags.join(", "));
}
