import { cpSync, existsSync, readdirSync, rmSync, statSync } from 'node:fs';
import { resolve, join } from 'node:path';

// The root assets/img directory is the ONLY canonical, Git-tracked media library.
// Pages CMS writes there. Astro's public/assets/img is a generated, ignored mirror.
// Rebuild from scratch: otherwise deleted/replaced pictures linger in local previews.
const source = resolve('../assets/img');
const dest = resolve('public/assets/img');
if (!existsSync(source) || !statSync(source).isDirectory()) {
  throw new Error('Missing canonical image/media library: ' + source);
}
rmSync(dest, { recursive: true, force: true });
cpSync(source, dest, { recursive: true });
function count(dir) {
  return readdirSync(dir, {withFileTypes:true}).reduce(
    (total,item) => total + (item.isDirectory() ? count(join(dir,item.name)) : item.isFile() ? 1 : 0), 0
  );
}
console.log(`Synced ${count(source)} canonical assets from assets/img (stale mirrored files removed).`);
