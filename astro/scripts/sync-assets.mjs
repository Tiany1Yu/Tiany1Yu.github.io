import { cpSync, existsSync, mkdirSync, readdirSync, statSync } from 'node:fs';
import { resolve, join } from 'node:path';

const source = resolve('../assets/img');
const dest = resolve('public/assets/img');
if (!existsSync(source)) throw new Error('找不到 Jekyll 旧图片资源：' + source);
mkdirSync(dest, { recursive: true });
let copied = 0;
function sync(from, to) {
  for (const file of readdirSync(from, { withFileTypes: true })) {
    const src = join(from, file.name), dst = join(to, file.name);
    if (file.isDirectory()) {
      mkdirSync(dst, { recursive: true }); sync(src, dst);
    } else if (file.isFile()) {
      const s = statSync(src);
      if (!existsSync(dst) || statSync(dst).size !== s.size) {
        cpSync(src, dst); copied++;
      }
    }
  }
}
sync(source, dest);
console.log(`Synced ${copied} images/media assets from legacy Jekyll (local only).`);
