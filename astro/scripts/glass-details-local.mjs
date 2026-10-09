import { chromium } from "playwright-core";
import { mkdirSync } from "node:fs";

const browser = await chromium.launch({
  executablePath: "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  headless: true
});
const root = process.env.E2E_ORIGIN || "http://127.0.0.1:4322";
mkdirSync(".astro/e2e/glass", { recursive: true });
const results = [];
async function check(label, value, ok, detail = "") {
  const yes = ok(value);
  results.push({label, passed:yes, value, detail});
  if (!yes) throw new Error(`FAIL ${label}: ${JSON.stringify(value)} ${detail}`);
  console.log("PASS", label, JSON.stringify(value));
}
for (const mode of ["light", "dark"]) {
  for (const screen of [
    {width:1440,height:900,label:"desktop"},
    {width:390,height:844,label:"mobile"}
  ]) {
    const page = await browser.newPage({viewport:{width:screen.width,height:screen.height}});
    await page.addInitScript(theme => {localStorage.setItem("theme",theme)},mode);
    await page.goto(root + "/notes/",{waitUntil:"networkidle"});
    const detail = await page.evaluate(() => {
      const st = sel => {
        const el = document.querySelector(sel);
        if(!el) return null;
        const cs = getComputedStyle(el);
        return { background:cs.backgroundColor, color:cs.color,
          border:cs.borderColor, backdrop:cs.backdropFilter,
          opacity:cs.opacity, outline:cs.outlineWidth};
      };
      return {
        story:st(".glass-story"),
        badge:st('#sidebar widget-layout[data-id="categories"] button .flex.items-center.justify-between > div:last-child'),
        chip:st('#sidebar widget-layout[data-id="tags"] .btn-regular'),
        meta:st(".glass-story .meta-icon"),
        overflow:document.documentElement.scrollWidth-innerWidth,
        ambient:getComputedStyle(document.body,"::after").display
      };
    });
    await check(`${mode}/${screen.label} story`,detail.story,x=>x!==null&&x.backdrop.includes("blur"));
    await check(`${mode}/${screen.label} no overflow`,detail.overflow,x=>x<=4);
    await check(`${mode}/${screen.label} ambient`,detail.ambient,x=>x==="none");
    await page.screenshot({path:`.astro/e2e/glass/v4-notes-${mode}-${screen.label}.png`,fullPage:false});

    if(screen.label==="desktop"){
      await check(`${mode} muted category badge`,detail.badge, x=>!!x&&!(/rgb\(0, 255, 255\)/.test(x.background)));
      await page.locator(".glass-story").first().hover();
      await page.waitForTimeout(1150);
      const shift = await page.locator(".glass-story").first().evaluate(el=>({transform:getComputedStyle(el).transform,translate:getComputedStyle(el).translate,hover:el.matches(":hover"),animation:getComputedStyle(el).animationName}));
      console.log("HOVER_DIAGNOSTIC", JSON.stringify(shift));
      await check(`${mode} story subtle hover`,shift, x=>x.hover && x.translate.includes("-2"));
      const input=page.locator("#search-bar input");
      await input.fill("MDP");
      await page.waitForTimeout(450);
      const panel=page.locator("#search-panel");
      await check(`${mode} search popover readable`,
        await panel.evaluate(el=>({opacity:getComputedStyle(el).opacity, background:getComputedStyle(el).backgroundImage,
          backdrop:getComputedStyle(el).backdropFilter})),
        x=>Number(x.opacity)>0.8&&x.backdrop.includes("blur")&&x.background.includes("linear-gradient"));
      await page.screenshot({path:`.astro/e2e/glass/v4-search-${mode}.png`,fullPage:false});
    } else {
      await page.locator("#nav-menu-switch").click();
      await page.waitForTimeout(360);
      const panel=page.locator("#nav-menu-panel");
      await check(`${mode} mobile menu readable`,
        await panel.evaluate(el=>({opacity:getComputedStyle(el).opacity,
          backdrop:getComputedStyle(el).backdropFilter, background:getComputedStyle(el).backgroundImage})),
        x=>Number(x.opacity)>0.8&&x.backdrop.includes("blur")&&x.background.includes("linear-gradient"));
      await page.screenshot({path:`.astro/e2e/glass/v4-menu-${mode}.png`,fullPage:false});
    }
    await page.close();
  }
}
await browser.close();
console.log(`GLASS_V4_DETAIL_PASS ${results.length} checks`);
