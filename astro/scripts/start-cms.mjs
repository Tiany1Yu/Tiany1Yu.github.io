import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

// Restrict the local editing API to loopback; never expose it on public interfaces.
const astroRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const repoRoot = resolve(astroRoot, '..');
const child = spawn(process.execPath, [resolve(astroRoot, 'node_modules/decap-server/dist/index.js')], {
  cwd: astroRoot,
  env: { ...process.env, BIND_HOST: '127.0.0.1', GIT_REPO_DIRECTORY: repoRoot },
  stdio: 'inherit',
});
child.once('error', (err) => { console.error('Unable to launch Decap:', err); process.exitCode = 1; });
child.once('exit', (code, signal) => { if (signal) process.kill(process.pid, signal); else process.exitCode = code ?? 1; });
