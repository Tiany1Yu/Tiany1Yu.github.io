import assert from "node:assert/strict";
import { chromium } from "playwright-core";
import { readFileSync,mkdirSync } from "node:fs";
const browser=await chromium.launch({executablePath:"C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",headless:true});
const root=process.env.E2E_ORIGIN||"http://127.0.0.1:4321";
const urls=Object.values(JSON.parse(readFileSync("src/data/legacy-aliases.json","utf8")));
const posts=[...new Set(urls.filter(s=>s.startsWith("/posts/")))];
let tested=0;
mkdirSync(".astro/e2e",{recursive:true});
const failures=[];
async function test(name,fn){try{await fn();console.log("PASS",name);tested++}catch(e){failures.push({name,error:e.message});console.error("FAIL",name,e.message)}}
const cssColor=(s)=>{const n=(s.match(/[\d.]+/g)||[]).slice(0,3).map(Number);return n.length===3?n.reduce((a,c)=>a+c,0)/3:NaN};
for(const mode of ["light","dark"]){
 for(const viewport of [{width:1440,height:900},{width:390,height:844}]){
  const mobile=viewport.width<500;
  const page=await browser.newPage({viewport,deviceScaleFactor:1});
  await page.addInitScript(mode=>{localStorage.setItem("theme",mode);localStorage.removeItem("hue")},mode);
  const name=mode+"/"+(mobile?"mobile":"desktop");
  await test(name+" original title, portrait, bio, fixed palette and Projects menu",async()=>{
   const response=await page.goto(root+"/notes/",{waitUntil:"networkidle",timeout:30000});
   assert.equal(response.status(),200);
   const title=await page.title();
   assert.match(title,/羽落天青/);
   assert.ok(await page.locator('a[href="/projects/"]').count()>=1,"Projects navigation missing");
   assert.equal(await page.locator("#display-settings-switch").count(),0);
   const bio=await page.locator("#sidebar .text-75").first().textContent();
   assert.equal(bio.trim(),"南京大学 | 智能科学与技术");
   assert.equal((await page.locator("main h1").first().textContent()).trim(),"笔记花园");
   assert.equal(await page.locator("main").getByText("支持 Markdown、数学公式与内部链接").count(),0);
   const avatar=page.locator('img[src*="Myself.jpg"]');
   await avatar.first().waitFor({timeout:8000});
   assert.equal(await avatar.first().evaluate(e=>e.complete&&e.naturalWidth>0),true);
   const themeData=await page.evaluate(()=>{
    const h=document.querySelector("main h1");
    const person=document.querySelector("#sidebar .font-bold.text-xl");
    const bg=getComputedStyle(document.documentElement);
    const card=document.querySelector("main .card-base");
    return {h1:getComputedStyle(h).color,person:getComputedStyle(person).color,bg:bg.backgroundImage,attachment:bg.backgroundAttachment,card:getComputedStyle(card).backgroundColor,blur:getComputedStyle(card).backdropFilter,scroll:document.documentElement.scrollWidth-innerWidth};
   });
   assert.ok(mode==="light"?cssColor(themeData.h1)<125:cssColor(themeData.h1)>205,JSON.stringify(themeData));
   assert.ok(mode==="light"?cssColor(themeData.person)<125:cssColor(themeData.person)>205,JSON.stringify(themeData));
   assert.match(themeData.bg,/user-night-desk\.avif/);
   assert.match(themeData.blur,/blur/);
   assert.ok(themeData.scroll<=3,"horizontal overflow "+themeData.scroll);
   if(!mobile)assert.ok(themeData.attachment.split(",").every(s=>s.trim()==="fixed"),"background layer not fixed: "+themeData.attachment);
   await page.screenshot({path:".astro/e2e/refined-"+name.replace("/","-")+".png",fullPage:true});
  });
  await test(name+" long-page background stays full-height and formulas render",async()=>{
    await page.goto(root+"/posts/notes/mdp/",{waitUntil:"networkidle"});
    const details=await page.evaluate(()=>{
      const html=getComputedStyle(document.documentElement);
      return {bg:html.backgroundImage,attach:html.backgroundAttachment,fullHeight:document.documentElement.scrollHeight,viewport:innerHeight,math:document.querySelectorAll(".katex").length,errors:document.querySelectorAll(".katex-error").length,over:document.documentElement.scrollWidth-innerWidth};
    });
    assert.ok(details.fullHeight>details.viewport,"test requires a long article");
    assert.ok(details.math>=35,"MDP maths unexpectedly missing");
    assert.equal(details.errors,0);
    assert.ok(details.over<=3,"article overflow "+details.over);
    const footer=await page.evaluate(()=>{
      const copy=[...document.querySelectorAll(".site-footer-copy")].find(e=>e.getClientRects().length>0);
      if(!copy) return null;
      const link=copy.querySelector("a");
      const area=document.getElementById("site-footer");
      const content=document.getElementById("main-grid");
      return {copy:getComputedStyle(copy).color,link:getComputedStyle(link).color,surface:getComputedStyle(area).backgroundColor,
        position:getComputedStyle(area).position,footerTop:area.getBoundingClientRect().top,contentBottom:content.getBoundingClientRect().bottom};
    });
    assert.ok(footer,"missing visible footer");
    assert.ok(cssColor(footer.copy)>190,"footer white copy must contrast against illustration: "+JSON.stringify(footer));
    assert.ok(cssColor(footer.link)>190,"footer link must contrast against illustration: "+JSON.stringify(footer));
    assert.ok(footer.surface==="rgba(0, 0, 0, 0)"||footer.surface==="transparent","footer should have no card surface: "+JSON.stringify(footer));
    assert.ok(footer.footerTop>=footer.contentBottom-3,"footer must appear AFTER content, not inside grid: "+JSON.stringify(footer));
    assert.equal(footer.position,"static");
    await page.evaluate(()=>scrollTo(0,document.documentElement.scrollHeight));
    const image=await page.evaluate(()=>getComputedStyle(document.documentElement).backgroundImage);
    assert.match(image,/user-night-desk/);
    await page.screenshot({path:".astro/e2e/formula-"+name.replace("/","-")+".png",fullPage:true});
  });
  await page.close();
 }
}
const page=await browser.newPage({viewport:{width:1366,height:900}});
await test("all 11 migrated posts have zero KaTeX parse errors",async()=>{
 for(const path of posts){
  await page.goto(root+path,{waitUntil:"domcontentloaded"});
  const err=await page.locator(".katex-error").allTextContents();
  assert.deepEqual(err,[],"KaTeX error at "+path+": "+err.join(",").slice(0,180));
 }
});
await test("Browser home title omits stale tagline, and About retains sophomore biography",async()=>{
 await page.goto(root+"/",{waitUntil:"domcontentloaded"});
 assert.equal(await page.title(),"羽落天青 | Uke\u0027s Blog");
 await page.goto(root+"/about/",{waitUntil:"networkidle"});
 assert.match(await page.locator("main").innerText(),/南京大学智能科学与技术专业的大二学生/);
 assert.match(await page.locator("main").innerText(),/写点闲话给大家，也是给自己/);
 const photo=await page.evaluate(async()=>{const img=new Image();img.src="/wallpapers/user-night-desk.avif";await img.decode();return [img.naturalWidth,img.naturalHeight]});
 assert.deepEqual(photo,[2048,1153]);
});
await test("REINFORCE annotation renders tau and theta mathematically rather than as red literal commands",async()=>{
 await page.goto(root+"/posts/notes/reinforce-actor-critic/",{waitUntil:"networkidle"});
 const annotation=await page.locator(".katex-html").filter({hasText:"这是因为在"}).first().innerText();
 assert.match(annotation,/τ/);
 assert.match(annotation,/θ/);
 assert.ok(!annotation.includes("\\\\tau")&&!annotation.includes("\\\\theta"),"Unparsed TeX shown in formula: "+annotation);
});
await test("previously unsupported PCA display formulas are rendered",async()=>{
 await page.goto(root+"/posts/writing/2026-03-14-ai-note/",{waitUntil:"networkidle"});
 assert.ok(await page.locator(".katex").count()>=6,"PCA block formulas are missing");
});
await page.close();
await browser.close();
console.log(JSON.stringify({passed:tested,failed:failures.length,failures},null,2));
if(failures.length)process.exitCode=1;
