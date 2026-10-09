// Create a safe Markdown draft in one of the site's three content collections.
// Usage: npm run new-post -- writing my-article
//        npm run new-post -- notes my-note
//        npm run new-post -- projects my-project
import {mkdirSync,writeFileSync} from "node:fs";
import {join,resolve} from "node:path";

const destinations = {
  writing: {folder:"src/content/posts/writing", category:"文章"},
  notes: {folder:"src/content/posts/notes", category:"笔记花园"},
  projects: {folder:"src/content/projects", category:"项目"},
};
const [kind,slug] = process.argv.slice(2);
if(!destinations[kind] || !slug || !/^[a-z0-9][a-z0-9_-]*$/i.test(slug)){
  console.error("用法：npm run new-post -- <writing|notes|projects> <slug>\n示例：npm run new-post -- notes rl-basics\nslug 只能包含英文字母、数字、连字符和下划线。");
  process.exit(1);
}
const today = new Date().toISOString().slice(0,10);
const base = destinations[kind];
const folder = resolve(base.folder);
const filename = join(folder,slug+".md");
mkdirSync(folder,{recursive:true});
const frontmatter = kind==="projects"
  ? `---\ntitle: "请填写项目标题"\ndescription: ""\nvenue: ""\nyear: ${new Date().getFullYear()}\nimage: ""\ngithub: ""\ndraft: true\n---\n\n在这里写项目介绍。\n`
  : `---\ntitle: "请填写标题"\npublished: "${today}"\ndescription: ""\ntags: []\ncategory: "${base.category}"\ndraft: true\nlang: zh_CN\n---\n\n从这里开始写 Markdown。\n`;
try {
  // Exclusive creation: never silently replace a real article.
  writeFileSync(filename,frontmatter,{encoding:"utf8",flag:"wx"});
  console.log("已创建草稿："+filename+"\n发布时将 draft: true 改为 draft: false，再提交并推送 master。");
}catch(error){
  console.error(error.code==="EEXIST"?"文件已存在，不会覆盖："+filename:error.message);
  process.exitCode=1;
}
