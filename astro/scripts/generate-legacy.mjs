import {readFileSync,existsSync,mkdirSync,writeFileSync} from "node:fs";
import {dirname,join} from "node:path";
const aliases=JSON.parse(readFileSync(new URL("../src/data/legacy-aliases.json",import.meta.url),"utf8"));
let count=0;
for(const [oldPath,target] of Object.entries(aliases)){
  if(!oldPath.endsWith(".html")) continue;
  const filename=join("dist",decodeURIComponent(oldPath).replace(/^\/+/,""));
  if(existsSync(filename)) continue;
  mkdirSync(dirname(filename),{recursive:true});
  const to=target.replace(/&/g,"&amp;").replace(/"/g,"&quot;").replace(/</g,"&lt;");
  const html='<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="robots" content="noindex,follow"><meta http-equiv="refresh" content="0;url='+to+'"><link rel="canonical" href="'+to+'"><title>页面已移动</title></head><body><a href="'+to+'">前往新页面</a></body></html>';
  writeFileSync(filename,html,"utf8");
  count++;
}
console.log("Created "+count+" historical static HTML redirects.");
