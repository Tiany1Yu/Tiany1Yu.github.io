/*
 * Deterministic, render-only compatibility adaptation for legacy MathJax Markdown.
 * The original Jekyll files remain untouched. This normalizes ONLY copied Fuwari
 * articles so remark-math/KaTeX can parse their old MathJax display conventions.
 */
import { readdirSync,readFileSync,writeFileSync } from "node:fs";
import {join,resolve} from "node:path";
import {fileURLToPath} from "node:url";
const root=resolve(fileURLToPath(new URL("../src/content/posts/",import.meta.url)));

export function normalizeLegacyMath(input){
 let text=input;
 // Old Kramdown / MathJax display boundaries are invisible to remark-math.
 text=text.replace(/^[ \t]*\\\[[ \t]*\r?\n([\s\S]*?)\r?\n[ \t]*\\\][ \t]*$/gm,(_,math)=>"$$\n"+math.trim()+"\n$$");
 // Old inline MathJax boundaries.
 text=text.replace(/\\\((.+?)\\\)/g,(_,math)=>"$"+math+"$");
 // KaTeX supports aligned inside display math; bare align around inline $$ is inconsistent.
 // Crucially: MathJax allowed $$\begin{align} on the same line; remark-math requires
 // the display opening and closing fences each on their own line for multiline blocks.
 text=text.replace(/\$\$([\s\S]*?)\$\$/g,(whole,source)=>{
   if(!source.includes("\n"))return whole;
   let math=source.trim();
   math=math.replace(/\\begin\{align\*?\}/g,"\\begin{aligned}")
            .replace(/\\end\{align\*?\}/g,"\\end{aligned}");
   // Older MathJax accepted $...$ inline formula segments inside a text label.
   // KaTeX text mode does not parse math commands: close text mode around each
   // inline expression, preserving the original mathematics and Chinese prose.
   math=math.replace(/\\text\{([^{}]*)\}/g,(whole,part)=>{
     if(!/\$[^$]+\$/.test(part))return whole;
     return part.split(/(\$[^$]+\$)/g).map(piece=>{
       if(!piece)return "";
       if(piece.startsWith("$")&&piece.endsWith("$"))return piece.slice(1,-1);
       return "\\text{"+piece+"}";
     }).join("");
   });
   // KaTeX allows one \\tag per equation; retain all row numbers as text labels.
   if((math.match(/\\tag\{[^{}]+\}/g)||[]).length>1){
     math=math.replace(/\\tag\{([^{}]+)\}/g,(_,num)=>"\\qquad\\text{("+num+")}");
   }
   return "$$\n"+math+"\n$$";
 });
 // Replace stray align environments embedded in single-line $$ as well.
 text=text.replace(/\\begin\{align\*?\}/g,"\\begin{aligned}")
          .replace(/\\end\{align\*?\}/g,"\\end{aligned}");
 return text;
}
export function transformMarkdownDoc(raw){
 const front=/^---[ \t]*\r?\n[\s\S]*?\r?\n---[ \t]*\r?\n/.exec(raw);
 if(!front) throw Error("Markdown frontmatter missing");
 return front[0]+normalizeLegacyMath(raw.slice(front[0].length));
}
if(process.argv[1] && resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 let changed=0;
 for(const dir of ["writing","notes"]){
  const folder=join(root,dir);
  for(const name of readdirSync(folder).filter(f=>f.endsWith(".md"))){
   const path=join(folder,name);
   const content=readFileSync(path,"utf8");
   const updated=transformMarkdownDoc(content);
   if(updated!==content){writeFileSync(path,updated,"utf8"); changed++;console.log("Normalized MathJax delimiters: "+dir+"/"+name);}
  }
 }
 console.log("Compatibility normalization: "+changed+" articles updated.");
}
