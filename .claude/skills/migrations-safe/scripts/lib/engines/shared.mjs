// What every rehearsal engine module shares: the docker CLI wrapper and a few constants.
import { spawn } from 'node:child_process';
import { RehearsalUsageError } from '../rehearse.mjs';

export const MIGRATION_APP = 'msafe-migration';
export const POLLER_APP = 'msafe-poller';
export const SEED_APP = 'msafe-seed';
export const PROBE_TABLE = 'msafe_probe';
export const POLL_END = '@@END';

export const docker = (args, { input, stream, timeoutMs = 600000 } = {}) => new Promise((resolve, reject) => {
  const child = spawn('docker', args, { stdio: ['pipe', 'pipe', 'pipe'], windowsHide: true });
  let out = '';
  let err = '';
  const timer = setTimeout(() => { child.kill(); reject(new RehearsalUsageError(`docker ${args[0]} timed out after ${Math.round(timeoutMs / 1000)} s`)); }, timeoutMs);
  child.stdout.setEncoding('utf8').on('data', (d) => { out += d; });
  child.stderr.setEncoding('utf8').on('data', (d) => { err += d; });
  child.on('error', (e) => { clearTimeout(timer); reject(e); });
  child.on('close', (code) => { clearTimeout(timer); resolve({ code, out, err }); });
  child.stdin.on('error', () => { /* the client exited before reading everything: its exit code says why */ });
  if (stream) {
    stream.on('error', (e) => { child.kill(); reject(e); });
    stream.pipe(child.stdin);
  } else child.stdin.end(input ?? '');
});

export const firstLines = (text, n = 3) => text.split(/\r?\n/).map((l) => l.trim()).filter(Boolean).slice(0, n).join(' | ');
export const lockList = (modes) => modes.map((m) => `'${m}'`).join(', ');
