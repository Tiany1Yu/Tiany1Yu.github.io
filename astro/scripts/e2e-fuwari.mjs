import assert from "node:assert/strict";
import { mkdirSync } from "node:fs";
import { chromium } from "playwright-core";
const base=process.env.E2E_ORIGIN || "http://127.0.0.1:4321";
const browser=await chromium.launch({executablePath:process.env.CHROME_PATH || "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",headless:true,args:["--no-first-run"]});
mkdirSync(".astro/e2e",{recursive:true});
let passed=0; const failed=[];
async function test(name,fn){try{await fn();console.log("PASS "+name);passed++}catch(err){console.log("FAIL "+name+": "+err.message);failed.push(name+": "+err.message)}}
try{
 const page=await browser.newPage({viewport:{width:1440,height:900},deviceScaleFactor:1});
 const errors=[];
 page.on("pageerror",e=>errors.push(e.message));
 await test("Fuwari desktop homepage and upstream cards",async()=>{
   const res=await page.goto(base+"/",{waitUntil:"networkidle",timeout:30000});
   assert.equal(res.status(),200);
   assert.ok(await page.locator("a[href*='/posts/']").count()>=5,"Missing upstream post cards");
   assert.ok((await page.title()).includes("Uke"),"Incorrect blog title");
   await page.screenshot({path:".astro/e2e/fuwari-desktop.png",fullPage:true});
 });
 await test("Fuwari notes and writing content pages",async()=>{
   await page.goto(base+"/notes/",{waitUntil:"networkidle"});
   assert.ok(await page.locator("a[href*='/posts/notes/']").count()>=6,"Expected six notes");
   await page.goto(base+"/writing/",{waitUntil:"networkidle"});
   assert.ok(await page.locator("a[href*='/posts/writing/']").count()>=5,"Expected five posts");
 });
 await test("Projects index and medical survey main figure",async()=>{
   const index=await page.goto(base+"/projects/",{waitUntil:"networkidle"});
   assert.equal(index.status(),200);
   assert.equal((await page.locator("main h1").first().textContent()).trim(),"项目");
   const entry=page.locator('main a[href="/projects/medical-multi-agent-survey/"]').first();
   assert.ok(await entry.count()>0,"Survey project missing from index");
   await entry.click();
   await page.waitForURL("**/projects/medical-multi-agent-survey/",{timeout:10000});
   assert.match(await page.locator("main").innerText(),/2026 年/);
   assert.match(await page.locator("main").innerText(),/Findings of EMNLP/);
   const figure=page.locator('main img[src="/assets/img/uploads/medical-multi-agent-survey.png"]').first();
   await figure.waitFor();
   const dims=await figure.evaluate(e=>e.complete&&e.naturalWidth===1502&&e.naturalHeight===624);
   assert.equal(dims,true,"Survey GitHub main_fig.png missing or damaged");
   const source=page.locator('main a[href="https://github.com/Tiany1Yu/Medical_Multi_Agent_Systems_Survey_Papers"]');
   await source.waitFor({timeout:10000});
   assert.ok(await source.count()>0,"Missing official GitHub repository link");
 });
 await test("Native theme switch changes state",async()=>{
   await page.goto(base+"/",{waitUntil:"networkidle"});
   const button=page.locator("#scheme-switch");
   await button.waitFor({timeout:10000});
   const before=await page.evaluate(()=>localStorage.getItem("theme"));
   await button.click();
   await page.waitForTimeout(300);
   const after=await page.evaluate(()=>localStorage.getItem("theme"));
   assert.notEqual(before,after,"Theme selection did not change");
 });
 await test("Real development full-text search",async()=>{
   const input=page.locator("#search-bar input");
   await input.fill("DQN");
   await page.locator("#search-panel a[href*='/posts/notes/dqn/']").first().waitFor({timeout:10000});
   await page.locator("#search-panel a[href*='/posts/notes/dqn/']").first().click();
   await page.waitForURL("**/posts/notes/dqn/",{timeout:10000});
 });
 await test("Math article and WikiLinks",async()=>{
   await page.goto(base+"/posts/notes/mdp/",{waitUntil:"networkidle"});
   assert.ok(await page.locator(".katex").count()>0,"Math not rendered");
   assert.ok(await page.locator("a[href='/notes/mab/']").count()>0,"WikiLinks not rendered");
 });
 await test("Historical Jekyll URLs resolve",async()=>{
   await page.goto(base+"/notes/2026-05-27-mdp.html",{waitUntil:"domcontentloaded"});
   await page.waitForURL("**/posts/notes/mdp/",{timeout:10000});
 });
 await test("CMS entry route",async()=>{
   const r=await page.goto(base+"/admin/",{waitUntil:"domcontentloaded"});
   assert.equal(r.status(),200);
   if(base.includes("127.0.0.1:4321")) {
     assert.equal(await page.locator('script[src*="decap-cms"]').count(),1);
   } else {
     assert.ok(await page.locator('a[href="https://app.pagescms.org/"]').count()>0,"Missing hosted Pages CMS link");
     assert.equal(await page.locator('script[src*="decap-cms"]').count(),0);
   }
 });
 await test("No uncaught page exceptions",async()=>assert.deepEqual(errors,[]));
 await page.close();
 const mobile=await browser.newPage({viewport:{width:390,height:844},deviceScaleFactor:1});
 await test("Fuwari mobile menu and layout",async()=>{
   await mobile.goto(base+"/",{waitUntil:"networkidle"});
   const excess=await mobile.evaluate(()=>document.documentElement.scrollWidth-innerWidth);
   assert.ok(excess<=3,"Horizontal overflow "+excess+"px");
   await mobile.locator("#nav-menu-switch").click();
   await mobile.locator("#nav-menu-panel a[href='/notes/']").click();
   await mobile.waitForURL("**/notes/",{timeout:10000});
   await mobile.screenshot({path:".astro/e2e/fuwari-mobile.png",fullPage:true});
 });
 await mobile.close();
}finally{await browser.close()}
console.log(JSON.stringify({passed,failed},null,2));
if(failed.length)process.exitCode=1;
