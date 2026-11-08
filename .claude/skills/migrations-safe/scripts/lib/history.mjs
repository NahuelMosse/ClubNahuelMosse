// Git history checks: migrations that were applied (they exist in the base) and then edited, renamed or
// deleted; new migrations that sort before the base's newest; two migrations with one sequence.
//
// Edits are measured against the merge-base of HEAD and the base ref (what the branch started from), and
// ordering against the tip of the base ref (what the branch will land on), so a branch that is not rebased
// does not look like it deleted what the base added since.
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { parse } from './parse.mjs';
import { ERROR, WARN } from './rules.mjs';
import { detectRunner, profileOf, runnerFromMarkers, runnerFromName } from './runners.mjs';

const MIGRATION_DIR = /(^|\/)(migrations?|db\/migrate|alembic\/versions|db\/changelogs?|db\/changesets?|drizzle)\//i;
const FLYWAY_NAME = /^(?:V|U)\d+(?:[._]\d+)*__.+\.sql$|^R__.+\.sql$/i;
// Files that hold a migration; manifests such as _journal.json, atlas.sum, migration_lock.toml are not.
const MIGRATION_EXT = /\.(sql|py|js|ts|mjs|cjs|rb|xml|ya?ml|go|cs|java|kt)$/i;

export class HistoryError extends Error {}

const git = (cwd, args) => {
  const r = spawnSync('git', ['-c', 'core.quotepath=false', ...args], { cwd, encoding: 'utf8', maxBuffer: 1 << 28 });
  if (r.error) throw new HistoryError(`git could not run (${r.error.code})`);
  return r;
};

export const isMigrationFile = (file) => MIGRATION_EXT.test(file) && (MIGRATION_DIR.test(file) || FLYWAY_NAME.test(file.split('/').at(-1)));

const resolveBase = (repo, ref) => {
  if (git(repo, ['rev-parse', '--git-dir']).status !== 0) throw new HistoryError(`${repo} is not a git repository`);
  if (git(repo, ['rev-parse', '--is-shallow-repository']).stdout.trim() === 'true')
    throw new HistoryError('this is a shallow clone: the history checks need the full history — use `fetch-depth: 0` in actions/checkout, or run `git fetch --unshallow`');
  const candidates = ref ? [ref] : ['origin/main', 'origin/master', 'main', 'master'];
  for (const cand of candidates) {
    const tip = git(repo, ['rev-parse', '--verify', '-q', `${cand}^{commit}`]);
    if (tip.status !== 0) continue;
    const mb = git(repo, ['merge-base', 'HEAD', cand]);
    if (mb.status !== 0 || !mb.stdout.trim()) throw new HistoryError(`HEAD and ${cand} share no history`);
    return { tip: tip.stdout.trim(), mergeBase: mb.stdout.trim(), label: cand };
  }
  throw new HistoryError(ref ? `base ${ref} not found` : 'no base branch found (origin/main, origin/master, main, master): pass --base <ref>');
};

const seqOf = (n) => {
  const m = n.match(/^([VU]?)(\d+(?:[._]\d+)*)(?=__|_|-|\.|$)/);
  if (!m) return null;
  const parts = m[2].split(/[._]/).map(BigInt);
  while (parts.length > 1 && parts.at(-1) === 0n) parts.pop();
  return { parts, key: parts.join('.') };
};
const cmp = (a, b) => {
  for (let i = 0; i < Math.max(a.length, b.length); i++) { const d = (a[i] ?? 0n) - (b[i] ?? 0n); if (d) return d < 0n ? -1 : 1; }
  return 0;
};
const unitOf = (f) => {
  const parts = f.split('/');
  const leaf = parts.at(-1);
  if (/^(migration|up|down)\.\w+$/i.test(leaf) && parts.length > 2) return { group: parts.slice(0, -2).join('/'), name: parts.at(-2) };
  return { group: parts.slice(0, -1).join('/'), name: leaf.replace(/(\.(up|down))*\.\w+$/i, '').replace(/^U(?=\d)/, 'V') };
};

export const historyFindings = (repo, ref, { runner = null } = {}) => {
  const base = resolveBase(repo, ref);
  const readAny = (file) => {
    if (existsSync(join(repo, file))) return readFileSync(join(repo, file), 'utf8');
    const shown = git(repo, ['show', `${base.mergeBase}:${file}`]);
    return shown.status === 0 ? shown.stdout : '';
  };
  const tree = (sha) => git(repo, ['ls-tree', '-r', '--name-only', '-z', sha]).stdout.split('\0').filter((f) => f && isMigrationFile(f));
  const inMergeBase = new Set(tree(base.mergeBase));
  const settledFiles = new Set([...inMergeBase, ...tree(base.tip)]);
  const present = git(repo, ['ls-files', '-co', '--exclude-standard', '-z']).stdout.split('\0')
    .filter((f) => f && isMigrationFile(f) && existsSync(join(repo, f)));

  const filesByGroup = new Map();
  for (const f of new Set([...settledFiles, ...present])) {
    const g = unitOf(f).group;
    filesByGroup.set(g, [...(filesByGroup.get(g) ?? []), f]);
  }
  // The runner of a folder: its config files, then the names and contents of the migrations in it.
  const profiles = new Map();
  const profileOfGroup = (group) => {
    if (runner) return profileOf(runner);
    if (profiles.has(group)) return profiles.get(group);
    const files = filesByGroup.get(group) ?? [];
    let found = detectRunner(join(repo, group || '.'));
    if (found.id === 'raw') found = files.map((f) => runnerFromName(basename(f))).find(Boolean) ?? found;
    if (found.id === 'raw') {
      for (const f of files.filter((x) => /\.sql$/i.test(x) && existsSync(join(repo, x))).slice(0, 5)) {
        const hit = runnerFromMarkers(parse(readAny(f)).markers);
        if (hit) { found = hit; break; }
      }
    }
    if (found.id === 'raw' && files.some((f) => /(^|\/)db\/migrate\/[^/]+\.rb$/.test(f))) found = { id: 'rails' };
    if (found.id === 'raw' && files.some((f) => /\.(xml|ya?ml)$/i.test(f) && /databaseChangeLog/.test(readAny(f)))) found = { id: 'liquibase' };
    profiles.set(group, profileOf(found.id));
    return profiles.get(group);
  };
  const profileOfFile = (file) => profileOfGroup(unitOf(file).group);
  // Files that change with every migration and are not migrations: manifests, repeatable scripts, master changelogs.
  const mutable = (file) => {
    const profile = profileOfFile(file);
    if (profile.manifests.some((re) => re.test(file)) || /(^|\/)R__[^/]*$/.test(file)) return true;
    return profile.id === 'liquibase' && /\.(xml|ya?ml|json)$/i.test(file)
      && (/(^|\/)[^/]*master[^/]*\.(xml|ya?ml|json)$/i.test(file) || /<include\b|^\s*-?\s*include\s*:|"include"\s*:/m.test(readAny(file)));
  };
  const findings = [];

  const changed = git(repo, ['diff', '--name-status', '-M', '--diff-filter=MDRT', base.mergeBase]).stdout.split('\n').filter(Boolean);
  for (const l of changed) {
    const [status, file, to] = l.split('\t');
    if (!isMigrationFile(file) || mutable(file)) continue;
    const verb = { M: 'edits', D: 'deletes', R: 'renames', T: 'changes the type of' }[status[0]] ?? 'changes';
    findings.push({ level: ERROR, rule: 'applied-migration-changed', file, line: 1, message: `the branch ${verb} ${file}${to ? ` (to ${to})` : ''}, which exists in ${base.label} (merge-base ${base.mergeBase.slice(0, 8)}) and is assumed applied everywhere: restore it and write the correction as a new migration` });
  }

  const fresh = present.filter((f) => !inMergeBase.has(f) && !mutable(f));

  const freshSet = new Set(fresh);
  const groups = new Map();
  const put = (f, isFresh) => {
    const u = unitOf(f);
    if (!groups.has(u.group)) groups.set(u.group, new Map());
    const g = groups.get(u.group);
    if (!g.has(u.name)) g.set(u.name, { ...u, file: f, fresh: false, seq: seqOf(u.name) });
    if (isFresh) g.get(u.name).fresh = true;
  };
  [...settledFiles].filter((f) => !mutable(f) && !freshSet.has(f)).forEach((f) => put(f, false));
  fresh.forEach((f) => put(f, true));

  for (const [group, units] of groups) {
    const { order } = profileOfGroup(group);
    if (order === 'graph') continue;
    const level = order === 'strict' ? ERROR : WARN;
    const settled = [...units.values()].filter((u) => !u.fresh && u.seq);
    const last = settled.reduce((a, u) => (!a || cmp(u.seq.parts, a.seq.parts) > 0 ? u : a), null);
    for (const u of [...units.values()].filter((x) => x.fresh && x.seq))
      if (last && cmp(u.seq.parts, last.seq.parts) < 0)
        findings.push({ level, rule: 'out-of-order', file: u.file, line: 1, message: `${u.name} sorts before ${last.name}, the newest migration of ${base.label}: ${order === 'strict' ? 'runners skip or reject it on environments already past it' : 'it applies on environments already past it, but the order differs between environments'} — renumber it on top` });
    const bySeq = new Map();
    for (const u of [...units.values()].filter((x) => x.seq)) bySeq.set(u.seq.key, [...(bySeq.get(u.seq.key) ?? []), u]);
    for (const [key, same] of bySeq)
      if (same.length > 1 && same.some((u) => u.fresh))
        findings.push({ level: ERROR, rule: 'duplicate-sequence', file: same.find((u) => u.fresh).file, line: 1, message: `sequence ${key} is used by ${same.map((u) => u.name).join(' and ')} in ${group || '.'}: renumber the branch's one` });
  }
  return { findings, fresh, base };
};
