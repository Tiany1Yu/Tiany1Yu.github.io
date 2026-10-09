import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
const root=resolve(dirname(fileURLToPath(import.meta.url)),"..");
const node=resolve(root,process.platform==="win32"?"node_modules/node/bin/node.exe":"node_modules/node/bin/node");
if(!existsSync(node)){
  console.error("Pinned Node 22 missing. Run: corepack pnpm install");
  process.exit(1);
}
const run=(name,args)=>{
  console.log("\n=== "+name+" [Node 22] ===");
  const result=spawnSync(node,args,{cwd:root,env:process.env,stdio:"inherit",windowsHide:false});
  if(result.error){console.error(result.error);process.exit(1);}
  if(result.status!==0){console.error("Failed: "+name+" (exit "+result.status+")");process.exit(result.status||1);}
};
run("Sync original media",["scripts/sync-assets.mjs"]);
run("Astro check",["node_modules/astro/astro.js","check"]);
run("Astro build",["node_modules/astro/astro.js","build"]);
run("Pagefind search",["node_modules/pagefind/lib/runner/bin.cjs","--site","dist"]);
run("Old URLs",["scripts/generate-legacy.mjs"]);
run("Regression verification",["scripts/verify-fuwari.mjs"]);
console.log("\nFuwari build:stable PASS (pinned Node 22).");
