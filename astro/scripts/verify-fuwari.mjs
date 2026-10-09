import assert from "node:assert/strict";
import {existsSync,readFileSync,readdirSync} from "node:fs";
import {join,resolve} from "node:path";
import {normalizeLegacyMath} from "./normalize-legacy-math.mjs";
const root=resolve("..");
const migrated=resolve("src/content/posts");
const dist=resolve("dist");
const aliases=JSON.parse(readFileSync("src/data/legacy-aliases.json","utf8"));
const legacyUrls=JSON.parse(readFileSync("scripts/legacy-urls.json","utf8"));
function normalizedNewlines(text){
  // Git autocrlf may check out the same Markdown as CRLF on Windows and LF on CI.
  // Compare semantic Markdown bytes after canonicalizing line endings only.
  return text.replace(/\r\n?/g,"\n");
}
function markdownBody(raw){
  const noBOM=raw.subarray(raw.subarray(0,3).equals(Buffer.from([0xef,0xbb,0xbf]))?3:0);
  const m=/^---[ \t]*\r?\n[\s\S]*?\r?\n---[ \t]*\r?\n/.exec(noBOM.toString("utf8"));
  assert.ok(m,"Invalid frontmatter");
  return noBOM.subarray(Buffer.byteLength(m[0],"utf8"));
}
let count=0;
for(const type of ["writing","notes"]){
  const dir=type==="notes"?"_notes":"_posts";
  for(const file of readdirSync(join(root,dir)).filter(x=>x.endsWith(".md"))){
    const out=type==="writing"?file.replace(/^\d{4}-\d{2}-\d{2}-/,""):file;
    // Jekyll originals remain byte-identical. Copied Fuwari bodies receive only
    // deterministic MathJax -> KaTeX delimiter normalization for rendering.
    const original=markdownBody(readFileSync(join(root,dir,file))).toString("utf8");
    const rendered=markdownBody(readFileSync(join(migrated,type,out))).toString("utf8");
    assert.equal(normalizeLegacyMath(normalizedNewlines(original)),normalizedNewlines(rendered),"Body mismatch outside math adaptation: "+file);
    count++;
  }
}
assert.equal(count,11,"Expected 5 posts and 6 notes");
assert.ok(existsSync(join(dist,"pagefind","pagefind.js")),"Pagefind search output missing");
for(const file of ["index.html","archive/index.html","about/index.html","notes/index.html","writing/index.html","projects/index.html","projects/medical-multi-agent-survey/index.html","admin/index.html","rss.xml"]){
  assert.ok(existsSync(join(dist,file)),"Missing generated route "+file);
}
for(const old of legacyUrls){
  assert.ok(existsSync(join(dist,old)),"Historical URL missing: "+old);
}
let canonicalCount=0;
for(const canonical of new Set(Object.values(aliases))){
  if(!canonical.startsWith("/posts/")) continue;
  const dest=join(dist,decodeURIComponent(canonical).replace(/^\/+/,""),"index.html");
  assert.ok(existsSync(dest),"Missing canonical URL: "+canonical);
  canonicalCount++;
}
function files(dir){
  let n=0;
  for(const item of readdirSync(dir,{withFileTypes:true})){
    if(item.isDirectory()) n+=files(join(dir,item.name));
    else if(item.isFile()) n++;
  }
  return n;
}
const surveyFigure=join(dist,"assets","img","projects","medical-multi-agent-survey.png");
assert.ok(existsSync(surveyFigure),"Original survey main_fig.png missing from site");
assert.equal(readFileSync(surveyFigure).length,588984,"Survey image differs in size from the original GitHub main figure");
const mediaCount=files(join(dist,"assets","img"));
const originalMediaCount=files(join(root,"assets","img"));
assert.equal(mediaCount,originalMediaCount,"Build media is out of sync with canonical assets/img (stale or missing files)");
// Check actual rendered HTML links, not only asset counts. Covers, article figures,
// project images, site icons and embedded videos must continue resolving after cleanup.
let checkedMediaUrls = new Set();
function checkMediaLinks(dir){
  for(const item of readdirSync(dir,{withFileTypes:true})){
    const file=join(dir,item.name);
    if(item.isDirectory()){checkMediaLinks(file);continue;}
    if(!item.isFile() || !item.name.endsWith(".html"))continue;
    const html=readFileSync(file,"utf8");
    for(const match of html.matchAll(/(?:src|href|poster|content|data-src)\s*=\s*["'](\/assets\/img\/[^"']+)["']/gi)){
      const url=decodeURIComponent(match[1].split(/[?#]/)[0]);
      checkedMediaUrls.add(url);
      assert.ok(existsSync(join(dist,url.replace(/^\/+/, ""))),"Missing asset in generated HTML: "+url+" ("+file+")");
    }
  }
}
checkMediaLinks(dist);
assert.ok(checkedMediaUrls.size>=40,"Media usage unexpectedly missing from generated site");
console.log("PASS: "+count+"/11 source-faithful markdown bodies (MathJax compatibility only); "+legacyUrls.length+"/"+legacyUrls.length+" legacy URLs; "+canonicalCount+" canonical posts; "+mediaCount+" media assets; Fuwari + Pagefind + CMS.");
