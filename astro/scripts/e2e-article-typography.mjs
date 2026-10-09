import assert from "node:assert/strict";
import { mkdirSync } from "node:fs";
import { chromium } from "playwright-core";

// Real-browser reading tests: inspect the CSS users actually see.
const origin = process.env.E2E_ORIGIN || "http://127.0.0.1:4322";
const browser = await chromium.launch({
  executablePath: "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  headless: true,
});
const rgb = (value) => (value.match(/[\d.]+/g) || []).slice(0, 3).map(Number);
const average = (value) => rgb(value).reduce((sum, value) => sum + value, 0) / 3;
let passed = 0;
mkdirSync(".astro/e2e", { recursive: true });

try {
  for (const theme of ["light", "dark"]) {
    for (const viewport of [{ width: 1440, height: 900 }, { width: 390, height: 844 }]) {
      const page = await browser.newPage({ viewport, deviceScaleFactor: 1 });
      await page.addInitScript((theme) => localStorage.setItem("theme", theme), theme);
      const response = await page.goto(origin + "/posts/notes/dqn/", {waitUntil:"networkidle", timeout:30000});
      assert.equal(response?.status(), 200);
      await page.waitForTimeout(350); // Fuwari applies 150ms text-color transitions on headings.
      const styles = await page.evaluate(() => {
        const body = document.querySelector("#post-container .custom-md");
        const p = body?.querySelector("p");
        const ol = body?.querySelector("ol");
        const li = ol?.querySelector("li");
        const heading = body?.querySelector("h2,h3,h4");
        const meta = document.querySelector("#post-container > .flex:first-child");
        return {
          theme: document.documentElement.classList.contains("dark") ? "dark" : "light",
          body: body && getComputedStyle(body).color,
          paragraph: p && getComputedStyle(p).color,
          heading: heading && getComputedStyle(heading).webkitTextFillColor,
          marker: li && getComputedStyle(li, "::marker").color,
          type: ol && getComputedStyle(ol).listStyleType,
          position: ol && getComputedStyle(ol).listStylePosition,
          padding: ol && parseFloat(getComputedStyle(ol).paddingInlineStart),
          gap: li && parseFloat(getComputedStyle(li).paddingInlineStart),
          meta: meta && getComputedStyle(meta).color,
          overflow: document.documentElement.scrollWidth - innerWidth,
          olCount: body?.querySelectorAll("ol").length,
        };
      });
      assert.equal(styles.theme, theme, JSON.stringify(styles));
      assert.ok(styles.olCount > 0, "Missing numbered Markdown lists " + JSON.stringify(styles));
      assert.equal(styles.type, "decimal", "Standard ordered-list numbering " + JSON.stringify(styles));
      assert.equal(styles.position, "outside", JSON.stringify(styles));
      assert.ok(styles.padding >= 20 && styles.padding <= 43, "List indent " + JSON.stringify(styles));
      assert.ok(styles.gap <= 8, "Item indentation " + JSON.stringify(styles));
      if (theme === "light") {
        for (const name of ["body", "paragraph", "heading", "marker"]) {
          if (styles[name]) {
            const channels = rgb(styles[name]);
            assert.ok(average(styles[name]) < 48 && Math.max(...channels) - Math.min(...channels) <= 5,
              "Light text is not opaque black/gray: " + name + " " + JSON.stringify(styles));
          }
        }
        assert.ok(average(styles.meta) < 105, "Light-mode word/time metadata faded: " + JSON.stringify(styles));
      } else {
        assert.ok(average(styles.body) > 170 && average(styles.paragraph) > 170, "Dark mode legibility regressed: " + JSON.stringify(styles));
      }
      assert.ok(styles.overflow <= 3, "Unexpected horizontal overflow: " + JSON.stringify(styles));
      const variant = theme + (viewport.width < 500 ? "-mobile" : "-desktop");
      await page.screenshot({path: ".astro/e2e/typography-" + variant + ".png", fullPage: false});
      console.log("PASS typography " + variant, JSON.stringify(styles));
      passed++;
      await page.close();
    }
  }
} finally {
  await browser.close();
}
console.log("Typography Chrome tests passed: " + passed + "/4");
