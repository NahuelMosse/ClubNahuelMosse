// Rehearses migrations on a throwaway PostgreSQL, MySQL or MariaDB container. The database is reached only
// through `docker exec <container> psql|mysql`, so nothing but the docker CLI is needed on the host.
// It reports per migration the duration, the write-blocking locks it held (polled from a second session),
// and the same row and column diff as the SQLite rehearsal.
import { spawn, spawnSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { closeSync, createReadStream, existsSync, openSync, readSync, readFileSync, statSync } from 'node:fs';
import { hostname } from 'node:os';
import { createGunzip, gunzipSync } from 'node:zlib';
import { decodeSql, parse } from './parse.mjs';
import { RUNNER_IDS, detectRunner, profileOf, wrapsFile } from './runners.mjs';
import { RehearsalUsageError, diff, partFor } from './rehearse.mjs';
import { IMAGES, makeEngine, mysqlInput } from './engines/index.mjs';
import { MIGRATION_APP, PROBE_TABLE, SEED_APP, docker, firstLines } from './engines/shared.mjs';

export { makeEngine, mysqlInput };
export const ENGINE_KINDS = Object.keys(IMAGES);
export const DEFAULT_LOCK_BUDGET_MS = 2000;
export const SIGNAL_EXIT = { SIGHUP: 129, SIGINT: 130, SIGTERM: 143 };
const POLL_PAUSE_MS = 40;
const TMPFS_SEED_LIMIT = 256 * 1024 * 1024;

export const parseEngine = (spec) => {
  const [kind, ...rest] = String(spec).split(':');
  const tag = rest.join(':');
  if (!ENGINE_KINDS.includes(kind) || !tag) throw new RehearsalUsageError(`--engine takes sqlite, postgres:<tag>, mysql:<tag>, mariadb:<tag>, mssql:<tag>, oracle:<tag> or db2:<tag> (got "${String(spec).slice(0, 40)}")`);
  return { kind, tag, image: `${IMAGES[kind]}:${tag}` };
};

// "2" and "2s" are seconds, "500ms" milliseconds.
export const parseDuration = (text) => {
  const m = String(text).trim().match(/^(\d+(?:\.\d+)?)\s*(ms|s)?$/i);
  if (!m) throw new RehearsalUsageError(`--lock-budget takes a duration such as 2, 2s or 500ms (got "${String(text).slice(0, 20)}")`);
  return Number(m[1]) * (m[2]?.toLowerCase() === 'ms' ? 1 : 1000);
};

// Size the seed will have once read: a .gz file by the length recorded in its last four bytes.
export const seedBytes = (file) => {
  const size = statSync(file).size;
  if (!/\.gz$/i.test(file) || size < 4) return size;
  const fd = openSync(file, 'r');
  try {
    const tail = Buffer.alloc(4);
    readSync(fd, tail, 0, 4, size - 4);
    return Math.max(size, tail.readUInt32LE(0));
  } finally { closeSync(fd); }
};

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Containers of this tool are named msafe-rehearse-<pid>-<id>. A run that is killed without a chance to clean
// up (TerminateProcess, a CI cancel) leaves its container; the next run removes the ones whose pid is gone.
// A pid only means something on the system that started the run, and one docker daemon can serve several
// (Windows and its WSL distros share Docker Desktop and the hostname): each container and network is labelled
// with its owner, and a run sweeps only its own system's. The owner ends with an id of the current boot of the
// kernel. It covers reboots of the same host: a pid from before a reboot is never taken for a live one. It does
// not separate systems that share a kernel (WSL2 distros, containers on the host network have the same boot id),
// which is what WSL_DISTRO_NAME in the label is for.
export const bootIdOf = (platform, { readText = (p) => readFileSync(p, 'utf8'), run = (cmd, args) => spawnSync(cmd, args, { encoding: 'utf8', timeout: 5000, windowsHide: true }).stdout } = {}) => {
  try {
    if (platform === 'linux') return readText('/proc/sys/kernel/random/boot_id').trim();
    if (platform === 'darwin') return String(run('sysctl', ['-n', 'kern.boottime'])).match(/sec\s*=\s*(\d+)/)?.[1] ?? '';
    if (platform === 'win32') return String(run('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command', '(Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToUniversalTime().ToString(\'yyyyMMddHHmmss\')'])).trim().match(/^\d{14}$/)?.[0] ?? '';
  } catch { /* no id: the owner is then hostname, platform and distro, as before */ }
  return '';
};
export const ownerOf = (host, platform, distro, boot) => [host, platform, distro, boot && `boot-${boot}`].filter(Boolean).join('/');
export const OWNER = ownerOf(hostname(), process.platform, process.env.WSL_DISTRO_NAME, bootIdOf(process.platform));
const pidAlive = (pid) => {
  try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
};
const sweepAbandoned = async (print) => {
  const listed = await docker(['ps', '-a', '--filter', 'label=msafe-rehearse=1', '--format', '{{.Names}}\t{{.Label "msafe-owner"}}'], { timeoutMs: 60000 });
  if (listed.code !== 0) return;
  const dead = listed.out.split(/\r?\n/).map((l) => l.trim().split('\t')).filter(([n, owner]) => {
    const pid = Number(n.match(/^msafe-rehearse-(\d+)-/)?.[1]);
    return owner === OWNER && pid && pid !== process.pid && !pidAlive(pid);
  }).map(([n]) => n);
  for (const n of dead) await docker(['rm', '-f', '-v', n], { timeoutMs: 120000 });
  if (dead.length) print(`removed ${dead.length} rehearsal container(s) left behind by runs that were killed`);
  // the internal networks of engines that need an interface (Oracle) are named like their container
  const nets = await docker(['network', 'ls', '--filter', 'label=msafe-rehearse=1', '--format', '{{.Name}}\t{{.Label "msafe-owner"}}'], { timeoutMs: 60000 });
  for (const [n, owner] of nets.code === 0 ? nets.out.split(/\r?\n/).map((l) => l.trim().split('\t')) : []) {
    const pid = Number(n.match(/^msafe-rehearse-(\d+)-/)?.[1]);
    if (owner === OWNER && pid && pid !== process.pid && !pidAlive(pid)) await docker(['network', 'rm', n], { timeoutMs: 60000 });
  }
};

const live = new Set();
const liveNets = new Set();
let hooked = false;
const removeSync = (name) => spawnSync('docker', ['rm', '-f', '-v', name], { stdio: 'ignore', windowsHide: true });
const removeNetSync = (name) => spawnSync('docker', ['network', 'rm', name], { stdio: 'ignore', windowsHide: true });
const hookExit = () => {
  if (hooked) return;
  hooked = true;
  const cleanUp = () => { for (const n of live) removeSync(n); live.clear(); for (const n of liveNets) removeNetSync(n); liveNets.clear(); };
  process.on('exit', cleanUp);
  for (const [sig, code] of Object.entries(SIGNAL_EXIT)) process.on(sig, () => { cleanUp(); process.exit(code); });
};

const ensureDocker = async () => {
  let r;
  try {
    r = await docker(['version', '--format', '{{.Server.Version}}'], { timeoutMs: 30000 });
  } catch (e) {
    throw new RehearsalUsageError(e.code === 'ENOENT' ? 'docker is not available: the `docker` command was not found in PATH' : `docker is not available: ${e.message}`);
  }
  if (r.code !== 0) throw new RehearsalUsageError(`docker is not available: the daemon did not answer (${firstLines(r.err, 2) || `exit ${r.code}`})`);
};

const ensureImage = async (image, print) => {
  const have = await docker(['image', 'inspect', image], { timeoutMs: 60000 });
  if (have.code === 0) return;
  print(`pulling ${image} ...`);
  const pulled = await docker(['pull', image], { timeoutMs: 1800000 });
  if (pulled.code !== 0) throw new RehearsalUsageError(`cannot pull ${image}: ${firstLines(pulled.err, 2) || `exit ${pulled.code}`}`);
};

// ── a second session that polls the lock tables while a migration runs ───────────────────────────────────

const startPoller = (eng, c) => {
  const child = spawn('docker', eng.pollerArgs(c), { stdio: ['pipe', 'pipe', 'pipe'], windowsHide: true });
  const samples = [];
  let rows = [];
  let buf = '';
  let errText = '';
  const state = { stopped: false, died: false, error: null, tail: '' };
  child.stdin.on('error', () => {});
  child.stderr.setEncoding('utf8').on('data', (d) => { errText += d; state.error = firstLines(errText, 2) || null; });
  child.stdout.setEncoding('utf8').on('data', (d) => {
    state.tail = `${state.tail}${d}`.slice(-400);
    buf += d;
    let i;
    while ((i = buf.indexOf('\n')) !== -1) {
      const line = (eng.cleanLine ?? ((l) => l))(buf.slice(0, i).replace(/\r$/, '')).trimEnd();
      buf = buf.slice(i + 1);
      if (line === '@@END') {
        samples.push({ t: performance.now(), rows });
        rows = [];
        setTimeout(send, POLL_PAUSE_MS);
      } else if (line.includes('\t')) rows.push(line.split('\t').map((f) => f.trimEnd()));
    }
  });
  child.on('close', () => { if (!state.stopped) state.died = true; });
  function send() { if (!state.stopped && child.stdin.writable) child.stdin.write(eng.pollInput()); }
  send();
  return {
    samples, state,
    stop: () => { state.stopped = true; child.stdin.end(); setTimeout(() => child.kill(), 500).unref(); },
  };
};

// Median gap between polls in a window, in ms.
const pollGap = (window) => {
  const gaps = window.slice(1).map((s, i) => s.t - window[i].t).sort((a, b) => a - b);
  return gaps.length ? gaps[Math.floor(gaps.length / 2)] : POLL_PAUSE_MS;
};

// Locks seen in [t0, t1]: one entry per table (its modes merged) with how long it was held, to the resolution of the polls.
export const locksIn = (samples, t0, t1, tables, normalize = (t) => t) => {
  const window = samples.filter((s) => s.t >= t0 && s.t <= t1 + 200);
  const gap = pollGap(window);
  const seen = new Map();
  for (const s of window) {
    for (const [mode, raw] of s.rows) {
      const table = normalize(raw);
      if (!tables.has(table)) continue;
      const e = seen.get(table) ?? { table, modes: new Set(), first: s.t, last: s.t, polls: 0 };
      e.modes.add(mode);
      e.last = s.t;
      e.polls = Math.max(e.polls, window.filter((w) => w.rows.some(([m, t]) => normalize(t) === table)).length);
      seen.set(table, e);
    }
  }
  return [...seen.values()].map((e) => ({ table: e.table, modes: [...e.modes].sort(), polls: e.polls, ms: e.last - e.first + gap })).sort((a, b) => b.ms - a.ms);
};

// ── what the database holds ──────────────────────────────────────────────────────────────────────

const rows = (text) => text.split(/\r?\n/).filter(Boolean);

// Runs a client command, returning stdout; a failure is a rehearsal that could not run.
const run = async (args, input, what) => {
  const r = await docker(args, { input });
  if (r.code !== 0) throw new RehearsalUsageError(`${what} failed in the container: ${firstLines(r.err || r.out, 3)}`);
  return r.out;
};

const snapshotOf = async (eng, c) => {
  const meta = await run(eng.queryArgs(c), eng.metaSql, 'reading the schema');
  const tables = new Map();
  // a client can print more than the rows (notices, warnings): only a line with all four fields is a column
  for (const [schema, table, name, type] of rows(meta).map((l) => l.split('\t').map((f) => f.trimEnd())).filter((f) => f.length === 4)) {
    const key = eng.tableKey(schema, table);
    if (!tables.has(key)) tables.set(key, { schema, name: table, cols: [] });
    tables.get(key).cols.push({ name, type });
  }
  const stats = new Map();
  if (tables.size) {
    const out = await run(eng.queryArgs(c), (eng.q ?? ((s) => s))([...tables].map(([key, t]) => eng.statsSql(key, t, t.cols)).join('\n')), 'counting rows');
    for (const line of rows(out)) { try { const o = JSON.parse(line); stats.set(o.t, o); } catch { /* not a result row */ } }
  }
  const snap = new Map();
  for (const [key, t] of tables) {
    const s = stats.get(key) ?? { n: 0 };
    snap.set(key, {
      rows: Number(s.n),
      columns: new Map(t.cols.map((col, i) => [eng.fold ? eng.fold(col.name) : col.name, {
        type: col.type, notnull: false, nonNull: Number(s[`c${i}`] ?? 0),
        fingerprint: [s[`d${i}`], s[`l${i}`], s[`lo${i}`], s[`hi${i}`]].join('|'),
      }])),
    });
  }
  return snap;
};

const waitReady = async (eng, name, timeoutMs) => {
  const t0 = Date.now();
  for (;;) {
    const state = await docker(['inspect', '-f', '{{.State.Running}}', name], { timeoutMs: 30000 });
    if (state.code === 0 && state.out.trim() === 'false') {
      const logs = await docker(['logs', '--tail', '15', name], { timeoutMs: 30000 });
      throw new RehearsalUsageError(`the ${eng.label} container exited while starting: ${firstLines(`${logs.err}\n${logs.out}`.split(/\r?\n/).slice(-8).join('\n'), 6)}`);
    }
    await eng.detect?.(name);
    const r = await docker(eng.readyArgs(name), { timeoutMs: 30000 });
    if (r.code === 0 && /\b1\b/.test(r.out)) return;
    if (Date.now() - t0 > timeoutMs) {
      const logs = await docker(['logs', '--tail', '6', name], { timeoutMs: 30000 });
      throw new RehearsalUsageError(`${eng.label} did not accept connections within ${Math.round(timeoutMs / 1000)} s (${firstLines(r.err || r.out, 2)}; the container's last log lines: ${firstLines(`${logs.out}\n${logs.err}`.split(/\r?\n/).slice(-8).join('\n'), 6)})`);
    }
    await sleep(500);
  }
};

const isPgCustomDump = (file) => {
  const fd = openSync(file, 'r');
  try {
    const buf = Buffer.alloc(5);
    readSync(fd, buf, 0, 5, 0);
    return buf.toString('latin1') === 'PGDMP';
  } finally { closeSync(fd); }
};

// Loads the seed. A `.sql` seed (`.gz` too) must load without errors; a dump (pg_dump, mysqldump, optionally
// .gz) loads with errors tolerated and counted (ownership and extension statements often fail in a scratch
// server). Only the statement position and error code are printed: an error text can quote row data.
const loadSeed = async (eng, name, file, dump, print) => {
  const gz = /\.gz$/i.test(file);
  if (dump && eng.kind === 'postgres' && !gz && isPgCustomDump(file)) {
    const r = await docker(eng.restoreArgs(name), { stream: createReadStream(file), timeoutMs: 3600000 });
    const errors = r.err.split(/\r?\n/).filter((l) => /error/i.test(l));
    if (r.code !== 0 || errors.length) print(`seed: pg_restore exited ${r.code} with ${errors.length} error line(s)`);
    return;
  }
  const args = eng.scriptArgs(name, { app: SEED_APP, stopOnError: !dump, wrap: false, dump });
  let r;
  if (dump) r = await docker(args, { stream: gz ? createReadStream(file).pipe(createGunzip()) : createReadStream(file), timeoutMs: 3600000 });
  else {
    const text = decodeSql(gz ? gunzipSync(readFileSync(file)) : readFileSync(file));
    r = await docker(args, { input: eng.seedInput ? eng.seedInput(text) : text });
  }
  if (!dump && r.code !== 0) throw new RehearsalUsageError(`the seed ${file} did not load: ${failText(eng, r)}`);
  const errors = eng.errorLines(eng.errorsOnStdout ? `${r.err}\n${r.out}` : r.err);
  if (dump && errors.length) print(`seed: the dump loaded with ${errors.length} error line(s), first ${eng.describeError(errors[0])}`);
};

// Why a client run failed: the engine knows where its client writes errors.
const failText = (eng, r) => (eng.failText ? eng.failText(r) : firstLines(r.err || r.out, 3));

const statementCount = (file, kind, dialect) => parse(partFor(file, kind, dialect).sql, { dialect }).statements.length;

// ── the rehearsal ────────────────────────────────────────────────────────────────────────────────

// opts: { engine, source, dump (boolean), ups, downs, runner, allowLoss, lockBudgetMs, keep, disk, startupTimeoutMs }
export const rehearseDocker = async (opts, print) => {
  const spec = parseEngine(opts.engine);
  const { source, ups, downs = null } = opts;
  if (!source || !ups.length) throw new RehearsalUsageError('a seed (or --dump file) and at least one migration are needed');
  if (opts.runner && !RUNNER_IDS.includes(opts.runner)) throw new RehearsalUsageError(`unknown runner ${opts.runner}`);
  for (const f of [source, ...ups, ...(Array.isArray(downs) ? downs : [])]) if (!existsSync(f)) throw new RehearsalUsageError(`${f} does not exist`);
  const eng = makeEngine(spec, { edition: opts.edition });
  eng.checkSeed?.(seedBytes(source));
  const downFiles = downs === 'sections' ? ups : downs;
  if (downs === 'sections') for (const f of ups) if (!partFor(f, 'down', eng.dialect).hasDown) throw new RehearsalUsageError(`${f} has no down section: pass the down files after --down`);
  for (const f of ups) if (statementCount(f, 'up', eng.dialect) === 0) throw new RehearsalUsageError(`${f} has no SQL statements, so there is nothing to rehearse`);
  for (const f of downFiles ?? []) if (statementCount(f, 'down', eng.dialect) === 0) throw new RehearsalUsageError(`the down of ${f} has no SQL statements`);
  const detected = opts.runner ? { id: opts.runner, evidence: '--runner' } : detectRunner(ups[0], { markers: partFor(ups[0], 'up', eng.dialect).markers, fileName: ups[0].split(/[\\/]/).at(-1) });
  const profile = profileOf(detected.id);
  const allowLoss = new Set(opts.allowLoss ?? []);
  const budget = opts.lockBudgetMs ?? DEFAULT_LOCK_BUDGET_MS;
  const seconds = (ms) => (ms / 1000).toFixed(2).replace(/\.?0+$/, '');

  await ensureDocker();
  await sweepAbandoned(print);
  await ensureImage(spec.image, print);

  const name = `msafe-rehearse-${process.pid}-${randomBytes(3).toString('hex')}`;
  hookExit();
  live.add(name);
  let poller = null;
  let finished = false;
  try {
    // Data lives in memory (much faster to initialise and load) unless the seed is too big for that or --disk is given.
    // No network (or, for the engines that need an interface, an internal one): the database is reached with docker exec only, so a --keep'd copy of production data is not reachable from other containers.
    const tmpfs = opts.disk !== true && seedBytes(source) <= TMPFS_SEED_LIMIT;
    // Oracle's instance fails (ORA-00600 ksipc) without a non-loopback interface: it gets a private network with no
    // outside access that nothing else is attached to, which keeps the data as unreachable as --network none does.
    if (eng.needsNetwork) {
      const net = await docker(['network', 'create', '--internal', '--label', 'msafe-rehearse=1', '--label', `msafe-owner=${OWNER}`, name], { timeoutMs: 60000 });
      if (net.code !== 0) throw new RehearsalUsageError(`could not create the private network for ${spec.image}: ${firstLines(net.err, 2)}`);
      liveNets.add(name);
    }
    const started = await docker(['run', '-d', '--name', name, '--label', 'msafe-rehearse=1', '--label', `msafe-owner=${OWNER}`, '--network', eng.needsNetwork ? name : 'none', ...eng.runArgs({ tmpfs })], { timeoutMs: 120000 });
    if (started.code !== 0) throw new RehearsalUsageError(`could not start ${spec.image}: ${firstLines(started.err, 2)}`);
    print(`runner: ${profile.label} (${detected.evidence}) · engine ${spec.image} in container ${name}`);
    await waitReady(eng, name, opts.startupTimeoutMs ?? eng.startupMs ?? 240000);
    const setupError = await eng.setup(name);
    const verified = await eng.verify?.(name);
    if (verified?.error) throw new RehearsalUsageError(verified.error);
    if (verified?.note) print(verified.note);
    if (eng.editionNote) print(eng.editionNote);
    const t0 = performance.now();
    await loadSeed(eng, name, source, opts.dump === true, print);
    let current = await snapshotOf(eng, name);
    if (current.size === 0) throw new RehearsalUsageError(`the seed ${source} left the database with no tables: nothing to rehearse on`);
    const seeded = [...current.values()].reduce((n, t) => n + t.rows, 0);
    print(`seed: ${source} loaded in ${((performance.now() - t0) / 1000).toFixed(1)} s (${current.size} table(s), ${seeded} row(s))`);
    const start = current;

    // the cost of one docker exec round trip, used only when a migration cannot be timed inside the server
    const trips = [];
    for (let i = 0; i < 3; i++) { const a = performance.now(); await docker(eng.readyArgs(name)); trips.push(performance.now() - a); }
    const overhead = trips.sort((a, b) => a - b)[0];

    // Lock measurement is proven before any migration runs: another session holds a lock on a probe table
    // and the poller must see it. A measurement that cannot be shown to work is not reported as "no lock".
    poller = startPoller(eng, name);
    await run(eng.queryArgs(name), eng.probe.create, 'creating the lock probe table');
    const probeStart = performance.now();
    const holder = docker(eng.scriptArgs(name, { app: MIGRATION_APP, stopOnError: true, wrap: false }), { input: eng.probe.hold });
    let seen = false;
    while (!seen && !poller.state.died && !poller.state.error && performance.now() - probeStart < 20000) {
      seen = poller.samples.some((s) => s.t > probeStart && s.rows.some(([, t]) => eng.normalizeLockTable(t) === PROBE_TABLE));
      if (!seen) await sleep(100);
    }
    await holder;
    // a second proof for engines that report a state after the migration (Db2 REORG-pending): provoke it on the probe table
    let pendingSeen = true;
    if (eng.pendingProbe) {
      await docker(eng.scriptArgs(name, { app: SEED_APP, stopOnError: true, wrap: false }), { input: eng.pendingProbe.sql });
      pendingSeen = (await eng.pending(name)).includes(eng.pendingProbe.table);
    }
    await docker(eng.scriptArgs(name, { app: SEED_APP, stopOnError: true, wrap: false }), { input: eng.probe.drop });
    if (!seen) throw new RehearsalUsageError(`lock measurement failed its self-test: a lock held on a probe table was not seen by the polling session (${poller.state.error ?? setupError ?? (poller.state.died ? 'the polling session ended' : `no row returned in ${poller.samples.length} poll(s); the session's last output: ${poller.state.tail.replace(/\s+/g, ' ').trim().slice(-160) || 'none'}`)}); nothing was measured, so nothing is reported`);
    if (!pendingSeen) throw new RehearsalUsageError('REORG-pending detection failed its self-test: a DROP COLUMN on a probe table was not reported as REORG pending; migrations that leave a table unusable would pass unnoticed, so nothing is reported');
    let pendingNow = new Set();

    let failed = 0;
    let unmeasured = 0;
    const apply = async (file, kind) => {
      const part = partFor(file, kind, eng.dialect);
      const wrap = wrapsFile(profile, { noTransaction: part.markers.noTransaction, statements: part.statements, dialect: eng.dialect });
      const { input, marked, error } = eng.scriptInput(part.sql, { wrap, marks: true });
      if (error) {
        failed++;
        print(`FAILED  ${kind.padEnd(4)} ${file}: ${error}`);
        return false;
      }
      const before = current;
      const a = performance.now();
      const r = await docker(eng.scriptArgs(name, { app: MIGRATION_APP, stopOnError: true, wrap }), { input, timeoutMs: 3600000 });
      const b = performance.now();
      if (r.code !== 0) {
        failed++;
        print(`FAILED  ${kind.padEnd(4)} ${file}: ${failText(eng, r)}`);
        if (eng.implicitCommit && !wrap) print(`          statements before the failing one stay applied: ${eng.label} DDL commits implicitly`);
        return false;
      }
      // duration measured inside the server, between two marks of the same session
      const t = (tag) => Number(r.out.match(new RegExp(`^@@${tag} ([\\d.]+)`, 'm'))?.[1]);
      const ms = marked && t('T1') >= t('T0') ? (t('T1') - t('T0')) * 1000 : Math.max(0, b - a - overhead);
      current = await snapshotOf(eng, name);
      const pendingAll = eng.pending ? await eng.pending(name) : [];
      const fresh = pendingAll.filter((tbl) => !pendingNow.has(tbl));
      pendingNow = new Set(pendingAll);
      const { lines, lost } = diff(before, current, kind, allowLoss);
      await sleep(POLL_PAUSE_MS * 2);
      const window = poller.samples.filter((s) => s.t >= a && s.t <= b + 200);
      const held = locksIn(poller.samples, a, b, new Set(before.keys()), eng.normalizeLockTable);
      const over = held.filter((l) => l.ms > budget);
      let notMeasured = null;
      if (poller.state.error) notMeasured = `the polling session reported: ${poller.state.error.slice(0, 120)}`;
      else if (poller.state.died) notMeasured = 'the polling session ended';
      else if (b - a >= 300 && window.length < 2) notMeasured = `${window.length} poll(s) during a ${Math.round(b - a)} ms migration`;
      if (notMeasured) unmeasured++;
      const bad = lost.length || over.length || notMeasured || fresh.length;
      if (bad) failed++;
      print(`${lost.length ? 'LOST   ' : over.length ? 'LOCKED ' : fresh.length ? 'PENDING' : notMeasured ? 'UNMEAS.' : 'ran    '} ${kind.padEnd(4)} ${file} in ${ms.toFixed(0)} ms`);
      lines.forEach((l) => print(`          ${l}`));
      lost.forEach((l) => print(`          lost: ${l}`));
      fresh.forEach((tbl) => print(`          REORG PENDING: ${tbl} is unusable until a classic REORG TABLE completes (SQLSTATE 57007): the migration needs CALL SYSPROC.ADMIN_CMD('REORG TABLE ${tbl}')`));
      held.forEach((l) => print(`          lock: ${l.modes.join(' + ')} on ${l.table} held ~${(l.ms / 1000).toFixed(2)} s (${l.polls} poll(s))${l.ms > budget ? `, over the ${seconds(budget)} s budget` : ''}`));
      if (notMeasured) print(`          lock: NOT MEASURED (${notMeasured}): this migration's locks are unknown`);
      else if (!held.length) print(`          lock: no write-blocking lock seen on tables that existed before (polled every ~${Math.round(pollGap(window))} ms)`);
      return true;
    };

    let stopped = null;
    for (const f of ups) if (!await apply(f, 'up')) { stopped = f; break; }
    if (stopped) {
      ups.slice(ups.indexOf(stopped) + 1).forEach((f) => print(`SKIPPED up   ${f}: an earlier migration failed`));
    } else if (downFiles) {
      for (const f of [...downFiles].reverse()) if (!await apply(f, 'down')) { stopped = f; break; }
      if (!stopped) {
        const restored = diff(start, current, 'down', allowLoss).lines.filter((l) => / new, |dropped|columns:/.test(l));
        print(restored.length ? `after the down(s) the schema differs from the seed: ${restored[0].replace(/\s+/g, ' ')}` : 'after the down(s) the tables and columns match the seed');
        for (const f of ups) if (!await apply(f, 'up')) { stopped = f; break; }
      }
    }
    const nDown = downFiles ? downFiles.length : 0;
    const verdict = failed
      ? `${failed} problem(s)${unmeasured ? `, locks not measured for ${unmeasured} migration(s)` : ''}${stopped ? `, stopped at ${stopped}` : ''}`
      : `all ran, no rows or values lost, no write lock over ${seconds(budget)} s`;
    print(`${ups.length} up(s)${nDown ? `, ${nDown} down(s)` : ''} on ${spec.image} seeded from ${source}: ${verdict}`);
    finished = true;
    return failed ? 1 : 0;
  } finally {
    poller?.stop();
    if (opts.keep && finished) {
      live.delete(name);
      liveNets.delete(name);
      print(`container ${name} kept for inspection (password ${eng.password}, ${eng.needsNetwork ? 'a private internal network with no outside access' : 'no network'}: use docker exec).\n  connect: ${eng.shell(name)}\n  remove:  docker rm -f -v ${name}${eng.needsNetwork ? ` && docker network rm ${name}` : ''}`);
    } else {
      await docker(['rm', '-f', '-v', name], { timeoutMs: 120000 }).catch(() => {});
      live.delete(name);
      if (liveNets.has(name)) { await docker(['network', 'rm', name], { timeoutMs: 60000 }).catch(() => {}); liveNets.delete(name); }
      if (opts.keep) print(`the run did not finish, so container ${name} was removed`);
    }
  }
};
