import { chromium } from "playwright-core";
import { mkdirSync } from "node:fs";
const browser = await chromium.launch({ executablePath: "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe", headless: true });
const root = "http://127.0.0.1:4322";
mkdirSync(".astro/e2e/glass", { recursive: true });
const routes = [
  {url:"/notes/",slug:"notes"},
  {url:"/projects/",slug:"projects"},
  {url:"/posts/notes/mdp/",slug:"article"}
];
for (const mode of ["light","dark"]) {
  for(const vp of [{width:1440,height:900,slug:"desktop"},{width:390,height:844,slug:"mobile"}]){
    const page=await browser.newPage({ viewport:vp, deviceScaleFactor:1 });
    await page.addInitScript(m=>{localStorage.setItem("theme",m)},mode);
    for (const route of routes) {
      await page.goto(root+route.url,{waitUntil:"networkidle",timeout:30000});
      await page.screenshot({path:`.astro/e2e/glass/${route.slug}-${mode}-${vp.slug}.png`,fullPage:route.slug!=="article"});
      const diag=await page.evaluate(()=>{
        const card=document.querySelector("#content-wrapper .card-base");
        const style=card?getComputedStyle(card):null;
        const title=document.querySelector("#content-wrapper h1") || document.querySelector("#content-wrapper .font-bold");
        const s=title?getComputedStyle(title):null;
        const nav=document.querySelector("#navbar .card-base");
        return {
          overflow:document.documentElement.scrollWidth-innerWidth,
          cssLoaded:[...document.styleSheets].some(x=>x.href?.includes("prismatic-glass.css")),
          cardBackground:style?.backgroundImage?.slice(0,150),
          backdrop:style?.backdropFilter,
          titleColor:s?.color,
          titleFont:s?.fontSize,
          navBackdrop:getComputedStyle(nav).backdropFilter,
          glassSurface:getComputedStyle(document.documentElement).getPropertyValue("--glass-surface").trim(),
          glassReflection:getComputedStyle(document.documentElement).getPropertyValue("--glass-reflection").trim(),
          glassRim:getComputedStyle(document.documentElement).getPropertyValue("--glass-spectrum").trim(),
          ambientOverlay:getComputedStyle(document.body,"::after").display
        };
      });
      console.log(mode,vp.slug,route.slug,JSON.stringify(diag));
      if(diag.overflow>4||!diag.cssLoaded||!diag.backdrop?.includes("blur"))throw new Error("Glass diagnostic failed");
      const alphaValues = css => [...css.matchAll(/rgba\([^)]*,\s*([0-9.]+)\)/g)].map(m => Number(m[1]));
      const fillAlphas = alphaValues(diag.glassSurface), reflectionAlphas = alphaValues(diag.glassReflection);
      if(!fillAlphas.length || !reflectionAlphas.length ||
         Math.max(...fillAlphas) > (mode==="light"?0.36:0.31) ||
         Math.max(...reflectionAlphas) > (mode==="light"?0.16:0.1))
        throw new Error("Glass material exceeded the agreed V2 transparency envelope: "+JSON.stringify({mode,fillAlphas,reflectionAlphas}));
      // V3 keeps the low-transmission chromatic edge treatment out: all rim
      // components must be nearly neutral rather than pink/blue/orange stripes.
      const rimColors = [...diag.glassRim.matchAll(/rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,/g)]
        .map(m => [Number(m[1]),Number(m[2]),Number(m[3])]);
      if(rimColors.length<3 || rimColors.some(rgb => Math.max(...rgb)-Math.min(...rgb)>32) || diag.ambientOverlay!=="none")
        throw new Error("Moonlit Quartz rim must be neutral with no artificial ambient color pools: "+JSON.stringify({rimColors,ambientOverlay:diag.ambientOverlay}));
      if(route.slug!=="article") {
        const rgb=(diag.titleColor.match(/\d+/g)||[]).slice(0,3).map(Number);
        if(rgb.length!==3||Math.min(...rgb)<220)throw new Error("Collection heading contrast on wallpaper is insufficient: "+JSON.stringify(diag));
      }
    }
    await page.close();
  }
}
await browser.close();
console.log("GLASS_VISUAL_CAPTURE_OK");
