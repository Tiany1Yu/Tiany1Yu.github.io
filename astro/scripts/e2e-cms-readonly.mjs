import { chromium } from 'playwright-core';
const browser = await chromium.launch({ executablePath: process.env.CHROME_PATH || 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe', headless: true });
try {
 const p = await browser.newPage({ viewport: {width: 1300, height: 900}});
 const bad = [];
 p.on('pageerror', e=>bad.push(e.message));
 p.on('requestfailed',r=>bad.push(r.url() + ': '+r.failure()?.errorText));
 const res = await p.goto('http://127.0.0.1:4321/admin/', {waitUntil:'domcontentloaded', timeout:25000});
 await p.waitForTimeout(6500);
 const out = {status:res.status(),url:p.url(),title:await p.title(),body:(await p.locator('body').innerText()).slice(0,1300), script:await p.locator('script[src*="decap-cms"]').count(), cmsGlobal:await p.evaluate(()=>Boolean(window.CMS)), buttons:await p.locator('button').allTextContents(),failed:bad.slice(0,10)};
 if (process.env.CMS_TEST_LOGIN === '1') {
   await p.getByRole('button', {name: '登录', exact: true}).click();
   await p.waitForTimeout(3500);
   out.afterLogin = {url:p.url(),body:(await p.locator('body').innerText()).slice(0,1400)};
   const entry = p.getByText('写在前面', {exact:true}).first();
   if (await entry.count()) {
     await entry.click();
     await p.waitForTimeout(1800);
     out.editor = {url:p.url(),body:(await p.locator('body').innerText()).slice(0,900),inputCount:await p.locator('input,textarea').count()};
   }
 }
 await p.screenshot({path:'.astro/e2e/cms.png',fullPage:true});
 console.log(JSON.stringify(out,null,2));
 if (res.status() !== 200 || !out.cmsGlobal)process.exitCode=1;
 await p.close();
} finally{await browser.close();}
