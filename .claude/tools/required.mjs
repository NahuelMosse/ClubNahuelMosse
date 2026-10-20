#!/usr/bin/env node
// required.mjs — run from the repo root, with a card in progress.
//
// Says what is missing, on the code being delivered, to be able to close:
// - the mutation of every production file the card touched;
// - the linter over every test file the card touched;
// - that no OUT points at something the card created or modified (out-of-scope.mjs);
// - that no action names a file outside the plan's File map;
// - the documents the diff makes necessary: infrastructure, schema, API contract, dependencies,
//   the data model, the secrets inventory and the threat model are written down where they live;
// - that a rule file's test was committed before the code, that no judgment finding is left
//   `suspect`, that nothing was disabled to make a check pass, and that a new endpoint or
//   integration leaves a metric or a trace.
// With `lane: fast` in the plan it asks for the fast lane's evidence instead (steps/fast-lane.md).
// What is required comes from the diff, not from what the agent decided to run: measured, the
// method mutated only the modules that had unit tests and ran the linters only on the scenarios, and
// the inspector, with the same list, found what was left out.
// It counts only what ran with once.mjs, passed, and ran on exactly the code as it is now:
// a later write invalidates it.
// The triggers are heuristics: a false positive is settled with the plan's
// `- <Doc>: unchanged — <why>` line under `## Changes to existing behavior`.
// Each check is a named function of one context object that returns the lines it finds missing. What
// every repo needs lives here; what belongs to a module of the kit (`.claude/kit.json`) lives in
// `tools/checks/<module>.mjs` and runs only while the module is on. A module that is on and whose
// file is missing is itself reported, with the command that restores it. A module that is off by a
// person's decision is not checked, but the close names it with its reason, and a signal that came
// after the decision is reported as missing (the late signal).
// The grade (`kit.mjs grade`) decides which checks run: a check is tied to the criterion it proves
// (CRITERION below) and does not run when the grade leaves that criterion out; mutation runs on no file
// at poc, on the domain at mvp and on every file at production (`levels.<grade>.mutation` of modules.json);
// the inspector's and the reviewer's reports are asked only where the grade launches them.
// verify.mjs asks `mutationRequired` the same question for each `mutate` line of the plan.
// Exits 0 if nothing is missing, 1 if something is missing, 2 if there is no card in progress.
import { appendFileSync, existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import {
  INFRA_DEPENDENCY, IS_CI, IS_CODE, IS_TEST, NOT_PRODUCTION, ROUTE, cardFiles, cardStart, copiedFromKit,
  currentCard, declaredUnchanged, existedAt, fileMapLines, git, keyOf, namedIn, pathTokens, relativeTo, resolveInMap, reviewKinds,
} from './card.mjs';
import { active, addedOf, lateSignals, LATE_ADVICE } from './kit.mjs';
import { runningAgents } from './agents-running.mjs';
import { laneOf, literalChanges, violations as laneViolations } from './lane.mjs';
import { outOfScopeThatBelongToTheCard } from './out-of-scope.mjs';
import { BROWSER_TEST, stableLine, stableShape } from './plan-check.mjs';
import { records } from './once.mjs';
import { cardIdOf, kitSectionMissing, refrozenSectionMissing } from './refreeze.mjs';

// The checks of every module present in tools/checks/, loaded once. Which of them run is decided
// per repo from its manifest, not from what was loaded.
const CHECKS_DIR = join(dirname(fileURLToPath(import.meta.url)), 'checks');
const loaded = {};
for (const file of existsSync(CHECKS_DIR) ? readdirSync(CHECKS_DIR).filter((f) => f.endsWith('.mjs')) : [])
  loaded[file.replace(/\.mjs$/, '')] = await import(pathToFileURL(join(CHECKS_DIR, file)).href);

const MUTATOR = /mutate\.mjs|stryker|mutmut|pitest|go-mutesting|cosmic-ray/i;
const LINTER = /eslint|ruff|golangci-lint|pylint|flake8|rubocop|ktlint|checkstyle|dotnet format/i;

// The criterion each check proves, by the name of its function: a grade that leaves the criterion out
// (modules.json, `byGrade` and the modules' `grades`) does not run the check. A check not listed here runs
// at every grade.
const CRITERION = {
  asvsAnswered: 'S15', sessionRecorded: 'V4', readmeReviewed: 'R4', readmeStatesAssumptions: 'R4',
  systemDesignSurface: 'S21', thirdPartyNotices: 'S19', ruleTestFirst: 'T13', secretsInventory: 'S22', noDisabledChecks: 'A9',
  schemaInSystemDesign: 'P14', appliedUntouched: 'P16', newOnesAfterMain: 'P16', upgradeFromMain: 'P5',
  apiContract: 'W8', hotPathLoadTest: 'O22', docsPage: 'W6', figures: 'W10', pipelineInvokesVerify: 'O23',
  infrastructureDocs: 'O14', observabilityMark: 'O6', catalogKeys: 'I31',
  screenEvidence: 'V5', accessibilityLines: 'V5', overflowRun: 'I13', stableRuns: 'T8', otherCardsCaptures: 'V5',
};
// A message ends with what fixes it: `write <where>: \`<the line>\`` or `run: \`<the command>\``, exact enough to be pasted.
const today = () => new Date().toISOString().slice(0, 10);
const planLine = (plan, name) => plan.match(new RegExp(`^\\s*${name}:\\s*(\\S.*)$`, 'm'))?.[1].trim();
const cardName = (cardDir) => cardDir.split(/[\\/]/).pop();

// The models a session's record names (`"model":"…"` of its messages), in the order they appear.
export const modelsOf = (record) => {
  try {
    const text = readFileSync(record, 'utf8');
    return [...new Set([...text.matchAll(/"model"\s*:\s*"([^"<]+)"/g)].map((m) => m[1]))];
  } catch { return []; }
};
// The records this card's sessions left in `.validation/sessions.log`, and the line of sessions.md each one needs.
export const sessionRecords = (root, cardDir) => {
  const log = join(root, '.validation', 'sessions.log');
  // Only the records the hook tagged with this card: another card's session is not this card's.
  return existsSync(log)
    ? readFileSync(log, 'utf8').split('\n').filter((l) => l.includes(` · card ${cardName(cardDir)} · `))
      .flatMap((l) => [...l.matchAll(/record: (\S+\.jsonl)/g)].map((m) => m[1]))
    : [];
};
export const sessionLine = (record) => `${today()} · ${modelsOf(record).join(', ') || '<model>'} · cost not available · ${record}`;
// Writes the line each of the card's records lacks in sessions.md; close.mjs and verify.mjs both call it, so the line is
// there before required.mjs asks for it. Returns one entry per line written.
export const writeSessionLines = (root, cardDir) => {
  const sessions = join(cardDir, 'sessions.md');
  const wrote = [];
  for (const record of sessionRecords(root, cardDir)) {
    if ((existsSync(sessions) ? readFileSync(sessions, 'utf8') : '').includes(record)) continue;
    appendFileSync(sessions, `${sessionLine(record)}\n`);
    wrote.push(sessions);
  }
  return wrote;
};

const runChecks = (context, checks) => checks.filter((check) => !context.exempt.has(CRITERION[check.name])).flatMap((check) => check(context));

const tokens = (command) => command.split(/\s+/)
  .map((t) => t.replace(/^['"]|['"]$/g, '').replaceAll('\\', '/').replace(/^\.\//, '').replace(/\/$/, ''))
  .filter(Boolean);

// A file is covered by the command if it names it, names a folder that contains it, or runs over
// the whole repo.
const covers = (command, file, { folders }) => tokens(command).some((t) =>
  t === file || (folders && (t === '.' || file.startsWith(`${t}/`))));

// Measured: mutating a view file with no logic needed a browser per mutant. A UI file whose File
// map line says `presentation` is not mutated; its logic lives in .ts/.js modules, which are.
const IS_UI = /\.(tsx|jsx|vue|svelte|html)$/;
// `root` is the repo of the card: a file name is unique among ITS files, not among those of the cwd.
const isPresentation = (lines, file, root) => IS_UI.test(file) && namedIn(lines, file, root).some((l) => /\bpresentation\b/i.test(l));

// The domain: a file under a `domain/` folder or one the File map marks as `rule` (rules or calculations).
const isDomain = (lines, file, root) => /(^|\/)domain\//.test(file) || namedIn(lines, file, root).some((l) => /\brule\b/i.test(l));

// Whether the grade asks for the mutation of a file: nothing when it leaves T3 out, the domain at mvp,
// everything otherwise; a presentation file is never mutated. `root` is the card's repo (the cwd by default).
export const mutationRequired = (exempt, map, file, root = process.cwd()) =>
  !isPresentation(map, file, root) && !exempt.criteria.has('T3') && (exempt.level?.mutation !== 'domain' || isDomain(map, file, root));

// An action is a defect in what the card created or changed. One that names a file outside the File
// map is about something the card did not touch: it is a known issue (`OUT`) or a question (`AMB`).
// Measured: a CSRF token for a form the card did not create became an action, introduced a new
// failure and cost another lap. A line moved out of the list says `moved`.
const NAMED_FILE = /[\w@.-]+(?:\/[\w@.-]+)*\.(?:m?[jt]sx?|cjs|cts|py|go|cs|java|kt|rb|php|html?|s?css|vue|svelte|sql)\b/g;
// The kit's own tools (verify.mjs, once.mjs…) named in a finding are what it ran, not the card's files.
const KIT_TOOLS = new Set(readdirSync(dirname(fileURLToPath(import.meta.url)), { withFileTypes: true }).filter((e) => e.isFile()).map((e) => e.name));
const actionsOutOfScope = (root, cardDir, map) => {
  const path = join(cardDir, 'actions.md');
  if (!map.length || !existsSync(path)) return [];
  return readFileSync(path, 'utf8').split('\n').flatMap((line) => {
    const id = line.match(/^\W*(ACT-\w+)\b/)?.[1];
    if (!id || /\bmoved\b/i.test(line)) return [];
    // What fails is the finding; the close condition may name the kit's tools.
    return [...new Set(line.split(/·\s*close:/)[0].match(NAMED_FILE) ?? [])]
      .filter((f) => !NOT_PRODUCTION.test(f) && !KIT_TOOLS.has(f) && !namedIn(map, f, root).length && !resolveInMap(map, f))
      .map((f) => `${id} names ${f}, outside the plan's File map: action out of the card's scope: move it to OUT or AMB · write in ambiguities.md \`${cardIdOf(cardDir)}-OUT-NN · ${today()} · <H|M|L> · ${f}:<line> · <defect> — from another feature, not touched\` and end the action line with \`moved · ${cardIdOf(cardDir)}-OUT-NN\``);
  });
};

// A judgment finding whose proof is not a failing command stays `suspect` until a second judge
// confirms or refutes it (steps/08-verify.md): left as it is, it neither closes nor reopens the card.
const suspectActions = (cardDir) => {
  const path = join(cardDir, 'actions.md');
  if (!existsSync(path)) return [];
  return readFileSync(path, 'utf8').split('\n').flatMap((line) => {
    const id = line.match(/^\W*(ACT-\w+)\b/)?.[1];
    return id && /·\s*suspect\s*$/.test(line.trim()) ? [`${id} is still \`suspect\`: confirm or refute it with a second judge (CONFIRM-SUSPECT, one call for all of them) · run: the \`reviewer\` agent with a prompt that starts \`CONFIRM-SUSPECT\` and lists ${id}; then end the line with \`open\` (confirmed) or \`closed · refuted: <why>\``] : [];
  });
};

// The lines of actions.md that are `closed` with the output of their close condition after it.
export const closedActionLines = (cardDir) => {
  const path = join(cardDir, 'actions.md');
  return existsSync(path)
    ? readFileSync(path, 'utf8').split('\n').filter((l) => /^\W*ACT-\w+\b/.test(l) && /·\s*closed\s*·\s*\S/.test(l))
    : [];
};

// `closing: false` leaves out what is about the text of closing.md: whoever is writing it cannot be
// asked for what it is about to say.
export const missing = (root, { closing = true } = {}) => {
  if (!existsSync(join(root, 'specs'))) return null;
  const cardDir = currentCard(root);
  if (!cardDir) return null;
  const base = cardStart(root, cardDir);
  const touched = cardFiles(root, base);
  const production = touched.filter((f) => IS_CODE.test(f) && !NOT_PRODUCTION.test(f));
  const map = fileMapLines(cardDir) ?? [];
  const tests = touched.filter((f) => IS_TEST.test(f));
  const plan = existsSync(join(cardDir, 'plan.md')) ? readFileSync(join(cardDir, 'plan.md'), 'utf8') : '';
  const fast = laneOf(plan) === 'fast';
  const { exempt } = active(root);

  // A record counts when it ran on the code as it is now. The key of each is computed only for the
  // records a check asks about, once per record: the 56 records of all the cards in a repo cost 8.5 s
  // when each was keyed whether or not anything looked at it.
  const recorded = records(root).filter((r) => r.command);
  const current = new Map();
  const runOnThisCode = (r) => {
    if (!current.has(r)) current.set(r, r.key === keyOf(root, r.command));
    return current.get(r);
  };
  const passed = (re, codes) => recorded.filter((r) => re.test(r.command) && codes.includes(r.exit) && runOnThisCode(r));

  const mutations = passed(MUTATOR, [0, 3]);
  const lints = passed(LINTER, [0]);
  const shared = [
    // Measured: 2 runs brought files the card did not ask for.
    ...(fileMapLines(cardDir) ? touched.filter((f) => !NOT_PRODUCTION.test(f) && !namedIn(map, f, root).length && !copiedFromKit(root, map, f))
      .map((f) => `${f} is not in the plan's File map: declare it there with its reason, or undo it · write under \`## File map\` of the plan: \`- ${f} — <what the card does to it and why>\``) : []),
    ...actionsOutOfScope(root, cardDir, map),
    ...outOfScopeThatBelongToTheCard(root, base, cardDir, touched),
  ];
  const context = buildContext(root, cardDir, base, touched, plan, map, passed, exempt);
  if (fast) return [...shared, ...fastEvidence(context, touched), ...commonEvidence(context), ...moduleState(root, cardDir, closing)];
  return [
    ...production.filter((f) => mutationRequired(exempt, map, f, root))
      .filter((f) => !mutations.some((r) => covers(r.command, f, { folders: false })))
      .map((f) => `mutation of ${f} · run: \`node .claude/tools/once.mjs mutate -- node .claude/tools/mutate.mjs ${f} --since ${base} -- ${planLine(plan, 'suite') ?? '<unit suite command>'}\``),
    ...(exempt.criteria.has('T6') ? [] : tests.filter((f) => !lints.some((r) => covers(r.command, f, { folders: true })))
      .map((f) => `linter on ${f} · run: \`node .claude/tools/once.mjs lint -- ${planLine(plan, 'lint') ?? `<linter command> ${f}`}\``)),
    ...shared,
    ...evidence(context),
    ...suspectActions(cardDir),
    ...structure(context),
    ...modulesMissing(root, context, 'structure'),
    ...moduleState(root, cardDir, closing),
  ];
};

export const lastWriteOf = (root, file) => {
  const dirty = git(root, ['status', '--porcelain', '--', file]).stdout?.trim();
  if (dirty || !git(root, ['log', '-1', '--format=%ct', '--', file]).stdout?.trim())
    return Math.floor(statSync(join(root, file)).mtimeMs / 1000);
  return Number(git(root, ['log', '-1', '--format=%ct', '--', file]).stdout.trim());
};

const MANIFEST = /(^|\/)(package(-lock)?\.json|npm-shrinkwrap\.json|pnpm-lock\.yaml|yarn\.lock|pyproject\.toml|poetry\.lock|requirements[^/]*\.txt|Pipfile(\.lock)?|go\.(mod|sum)|Gemfile(\.lock)?|composer\.(json|lock)|pom\.xml|build\.gradle[^/]*|[^/]+\.csproj|packages\.lock\.json)$/;

// Every report has an owner. A line for a report whose owner still runs starts with PENDING: it is not an
// action (verify.mjs prints it apart), and the close still waits for it.
export const PENDING = 'pending · ';
export const splitPending = (lines) => ({
  actions: lines.filter((l) => !l.startsWith(PENDING)),
  pending: lines.filter((l) => l.startsWith(PENDING)).map((l) => l.slice(PENDING.length)),
});
const OWNERS = {
  inspector: { who: 'the inspector', type: 'inspector' },
  verdict: { who: 'the verdict reviewer', type: 'reviewer' },
  judge: { who: 'the VISUAL-JUDGE reviewer', type: 'reviewer' },
  pairwise: { who: 'the PAIRWISE reviewer', type: 'reviewer' },
};
const ownership = () => {
  let running;
  return (owner, line) => {
    running ??= runningAgents().map((a) => a.type);
    const live = running.includes(OWNERS[owner].type);
    return `${live ? PENDING : ''}${line} (owner: ${OWNERS[owner].who}${live ? ', still running' : ''})`;
  };
};

// What every check receives: the card's files and plan, what the diff added, and what the grade leaves out.
const buildContext = (root, cardDir, base, touched, plan, map, passed, exempt) => {
  const manifests = touched.filter((f) => MANIFEST.test(f));
  const added = new Map(touched.filter((f) => !/^specs\/|\.md$/.test(f)).map((f) => [f, addedOf(root, base, f)]));
  const addedIn = (files) => files.flatMap((f) => (added.get(f) ?? []).map((l) => ({ ...l, f })));
  const code = touched.filter((f) => IS_CODE.test(f) && !NOT_PRODUCTION.test(f));
  const surface = touched.filter((f) => !NOT_PRODUCTION.test(f) && !IS_TEST.test(f));
  return {
    root, cardDir, base, touched, plan, map, passed, manifests, added, code, owned: ownership(),
    exempt: exempt.criteria, without: exempt.without, procedures: exempt.procedures,
    production: surface,
    inDiff: (f) => touched.includes(f),
    prodAdded: addedIn(surface),
    newInfraPackage: addedIn(manifests).some((l) => INFRA_DEPENDENCY.test(l.text)),
    ...reviewKinds(root, code),
  };
};

const asvsAnswered = ({ touched, plan, cardDir }) =>
  !touched.includes('specs/asvs.md') && !declaredUnchanged(plan, 'ASVS')
    ? [`specs/asvs.md answered for the chapters the card touches, or \`- ASVS: unchanged — <why>\` in the plan, under Changes to existing behavior (S15) · write in specs/${cardName(cardDir)}/plan.md under \`## Changes to existing behavior\`: \`- ASVS: unchanged — <why>\``]
    : [];

const sessionRecorded = ({ root, cardDir }) => {
  const card = cardName(cardDir);
  const sessions = join(cardDir, 'sessions.md');
  const records = sessionRecords(root, cardDir);
  return records.length && !(existsSync(sessions) && records.some((r) => readFileSync(sessions, 'utf8').includes(r)))
    ? [`specs/${card}/sessions.md with where the session's record is —the record: of .validation/sessions.log— (V4) · write in specs/${card}/sessions.md the line: \`${sessionLine(records.at(-1))}\``]
    : [];
};

const readmeReviewed = ({ root, touched, plan, cardDir }) =>
  existsSync(join(root, 'README.md')) && !touched.includes('README.md') && !declaredUnchanged(plan, 'README')
    ? [`README.md reviewed: update the sentences the change makes false, or declare \`- README: unchanged — <why>\` in the plan, under Changes to existing behavior · write in specs/${cardName(cardDir)}/plan.md under \`## Changes to existing behavior\`: \`- README: unchanged — <why>\` if no sentence changes`]
    : [];

// Measured: in 2 of 4 re-inspections the README lacked the assumptions the card took.
const readmeStatesAssumptions = ({ root, cardDir, plan }) => {
  if (!existsSync(join(root, 'README.md')) || declaredUnchanged(plan, 'README')) return [];
  const readme = readFileSync(join(root, 'README.md'), 'utf8');
  const text = ['ambiguities.md', 'plan.md'].map((f) => join(cardDir, f)).filter(existsSync).map((p) => readFileSync(p, 'utf8')).join('\n');
  const absent = [...new Set(text.match(/[A-Za-z][\w-]*-ASM-\d+/g) ?? [])].sort().filter((id) => !readme.includes(id));
  // The assumption as the plan states it: `- <ID>-ASM-NN · <the assumption> · any-answer: …`.
  const stated = (id) => text.match(new RegExp(`${id}\\s*·\\s*([^·\\n]+?)\\s*(?:·|$)`, 'm'))?.[1] ?? '<what is assumed>';
  return absent.length
    ? [`README.md does not state ${absent.join(', ')}: whoever uses or operates the product has to know the assumptions the card took · write in README.md: ${absent.map((id) => `\`- ${id}: ${stated(id)}\``).join(' ')}`]
    : [];
};

// The ASVS matrix, the session record and the README: what every card leaves, in either lane.
const commonEvidence = (context) =>
  runChecks(context, [asvsAnswered, sessionRecorded, readmeReviewed, readmeStatesAssumptions]);

// Which modules' checks run: those that are on. A repo without a modules.json has no manifest to
// consult and runs every check that is installed.
const moduleChecks = (root) => {
  const { on, known } = active(root);
  return known.length ? [...on] : Object.keys(loaded).filter((name) => !loaded[name].optIn);
};

const modulesMissing = (root, context, kind) => {
  const out = [];
  for (const name of moduleChecks(root)) {
    if (!loaded[name]) continue;
    const run = kind === 'evidence' ? loaded[name].evidence : kind === 'fast' ? loaded[name].fast : loaded[name].structure;
    out.push(...runChecks(context, run ?? []));
  }
  return out;
};

// The modules that are off by decision: the close names each one with its reason, and a signal that
// came after the decision is reported (the person turns it on, or confirms it stays off). A grade below
// production is named in the close too, with its reason.
const THREE_STATES = ['Passed', 'Failed', 'Could not run'];
const moduleState = (root, cardDir, withClosing = true) => {
  const { off, on, known, grade, manifest } = active(root);
  const out = known.filter((name) => on.has(name) && !loaded[name])
    .map((name) => `the checks of the module ${name}, which is on, are not installed: \`node .claude/tools/kit.mjs repair\``);
  const closing = join(cardDir, 'closing.md');
  // While closing.md is being written, nothing below can be asked of its text.
  const hasClosing = withClosing && existsSync(closing);
  if (grade !== 'production' && hasClosing && !new RegExp(`grade:\\s*${grade}\\b`, 'i').test(readFileSync(closing, 'utf8')))
    out.push(`closing.md names the grade with “grade: ${grade} — ${manifest?.grade?.reason ?? ''}”`);
  // The closing names the three states, each section present even when it is empty. Measured: a close
  // declared what passed and what failed and left out «could not run» because there was nothing to say.
  if (hasClosing) {
    const text = readFileSync(closing, 'utf8');
    const lacking = THREE_STATES.filter((state) => !new RegExp(`^#{2,3}\\s+${state}\\b`, 'im').test(text));
    if (lacking.length)
      out.push(`closing.md has the section${lacking.length > 1 ? 's' : ''} ${lacking.map((s) => `“## ${s}”`).join(', ')}: the three states —## Passed, ## Failed, ## Could not run— each present, saying it is empty when it is · write at the end of closing.md: ${lacking.map((s) => `\`## ${s}\``).join(' and ')}, each followed by its lines or by \`none\``);
  }
  if (hasClosing) {
    const refrozen = refrozenSectionMissing(cardDir, readFileSync(closing, 'utf8'));
    if (refrozen) out.push(refrozen);
    const kitUpdated = kitSectionMissing(cardDir, readFileSync(closing, 'utf8'));
    if (kitUpdated) out.push(kitUpdated);
  }
  if (!off.size) return out;
  for (const [mod, found] of Object.entries(lateSignals(root, cardDir, { diff: true })))
    out.push(`the module ${mod} is off (“${off.get(mod).reason}”) and the diff brings ${found.join('; ')}: ${LATE_ADVICE(mod, grade)}`);
  if (hasClosing) {
    const text = readFileSync(closing, 'utf8');
    for (const [mod, o] of off)
      if (!text.split('\n').some((l) => l.includes(mod) && /off by decision|apagado por decisión/i.test(l) && l.includes(o.reason)))
        out.push(`closing.md names the module ${mod} with “off by decision: ${o.reason}”`);
  }
  return out;
};

// Measured: the two light failures repeated across inspected cards were the review and inspection
// reports not saved in the repo, and a README sentence the change left false.
const evidence = (context) => {
  const { root, cardDir, code, without, owned } = context;
  if (!code.length) return [];
  const card = cardDir.split(/[\\/]/).pop();
  // Measured: the verdict reviewer and the inspector answered the same F1 (14 % and 12 % of the
  // cost of 8 runs). The clean-context review.md stays for a screen or a route that writes.
  const screen = context.screen && (!active(root).known.includes('ui') || active(root).on.has('ui'));
  // A grade without inspector or reviewer (poc) asks for neither report.
  const needed = (screen || context.writingRoute ? ['inspection.md', 'review.md'] : ['inspection.md'])
    .filter((f) => !without.has(f === 'inspection.md' ? 'inspector' : 'reviewer'));
  const lacking = needed
    .filter((f) => !existsSync(join(cardDir, f)))
    .map((f) => owned(f === 'inspection.md' ? 'inspector' : 'verdict', `the ${f.replace('.md', '')} report saved in specs/${card}/${f}`));
  const inspection = join(cardDir, 'inspection.md');
  if (!without.has('inspector') && existsSync(inspection) && !/^[\s#>*_-]*F1\b/m.test(readFileSync(inspection, 'utf8')))
    lacking.push(`specs/${card}/inspection.md has no F1 section: a heading or line starting with F1, answering each acceptance criterion against the running app · write at the top of it: \`## F1 — does the product do what the card asked\` and one line per acceptance criterion: \`<criterion> · met|not met · <evidence>\``);
  // Measured: in two cards the inspection stayed describing the state before the fixes.
  // A fix inside a file that a `closed` action names, with the output of its close condition, is what the
  // reports already asked for: only production changes outside those actions make them stale.
  // Only the reports this card needs: a review.md left by an earlier lap on a card with no screen and no
  // route that writes is not asked to be rewritten.
  const reports = needed.filter((f) => existsSync(join(cardDir, f)));
  if (reports.length) {
    const reportTimes = reports.map((f) => lastWriteOf(root, relativeTo(root, join(cardDir, f))));
    const changedAfter = code.filter((f) => reportTimes.some((t) => t < lastWriteOf(root, f)));
    const closed = closedActionLines(cardDir);
    const unexplained = changedAfter.filter((f) => !namedIn(closed, f, root).length);
    if (unexplained.length)
      lacking.push(`${reports.join('/')} older than the last production change: update ${reports.length > 1 ? 'them' : 'it'} with the state after the actions (changed after them, outside any closed action of actions.md: ${unexplained.join(', ')}) · write in actions.md for each file: ${unexplained.map((f) => `\`ACT-<NN> · <criterion> · <H|M|L> · <what changed> in ${f} · close: <command> · closed · <its output>\``).join(' ')} (a judge is not resumed for this), or save the report again with the state after the actions`);
  }
  return [...lacking, ...modulesMissing(root, context, 'evidence'), ...commonEvidence(context)];
};

const SYSTEM_DESIGN = 'docs/technical/system-design.md';
const UPLOAD = /\bmultipart\b|\bupload/i;
const ROLE = /\broles?\s*[:=]|enum\s+\w*Role\b|\bhasRole\s*\(/i;
const SENSITIVE_NAME = /KEY|SECRET|TOKEN|PASSWORD|DSN|(DATABASE|DB|REDIS|MONGO)\w*URL|URL\w*(DATABASE|DB)/;
const ENV_READ = [
  /process\.env\.([A-Z][A-Z0-9_]*)/g, /process\.env\[\s*['"]([A-Z][A-Z0-9_]*)['"]\s*\]/g,
  /os\.environ(?:\.get)?\s*[([]\s*['"]([A-Z][A-Z0-9_]*)['"]/g, /Environment\.GetEnvironmentVariable\(\s*"([A-Z][A-Z0-9_]*)"/g,
  /System\.getenv\(\s*"([A-Z][A-Z0-9_]*)"/g,
];
// What disables a check so that the pipeline passes (A9): never done by the agent.
const CHEATS = [
  [/\.(skip|only)\(/, '.skip( or .only('], [/\bx(it|describe)\(/, 'xit( or xdescribe('], [/@Disabled\b|@Ignore\b/, '@Disabled or @Ignore'],
  [/pytest\.mark\.skip/, 'pytest.mark.skip'], [/\[Fact\(Skip/, '[Fact(Skip'], [/continue-on-error:\s*true/, 'continue-on-error: true'],
  [/allow_failure:\s*true/, 'allow_failure: true'], [/--no-verify\b/, '--no-verify'], [/\bHUSKY=0\b/, 'HUSKY=0'], [/\bSKIP=/, 'SKIP='],
  [/\bretries\s*:|--retries\b/, 'retries'],
];

const firstCommit = (root, f) => git(root, ['log', '--diff-filter=A', '--format=%H', '--', f]).stdout?.trim().split('\n').filter(Boolean).at(-1) ?? null;

const textOf = (root, f) => (existsSync(join(root, f)) ? readFileSync(join(root, f), 'utf8') : '');

// A new surface lands in the system design (S21); a schema change is the module `data`'s.
const systemDesignSurface = ({ plan, inDiff, prodAdded, newInfraPackage, cardDir }) => {
  const surface = [];
  if (prodAdded.some((l) => ROUTE.test(l.text))) surface.push('a new route: threat model of the surface (S21)');
  if (prodAdded.some((l) => UPLOAD.test(l.text))) surface.push('an upload: threat model of the surface (S21)');
  if (prodAdded.some((l) => ROLE.test(l.text))) surface.push('a new role: threat model of the surface (S21)');
  if (newInfraPackage) surface.push('a new integration: threat model of the surface (S21)');
  return surface.length && !inDiff(SYSTEM_DESIGN) && !declaredUnchanged(plan, 'System design')
    ? [`${SYSTEM_DESIGN} in the diff — ${surface.join('; ')} — or declare \`- System design: unchanged — <why>\` · write in ${SYSTEM_DESIGN} under \`## Threat model\` a row for each surface, or in specs/${cardName(cardDir)}/plan.md under \`## Changes to existing behavior\`: \`- System design: unchanged — <why>\``]
    : [];
};

// A manifest or a lockfile regenerates the notices (S19)
const thirdPartyNotices = ({ plan, manifests, inDiff, cardDir }) =>
  manifests.length && !inDiff('THIRD_PARTY_NOTICES.md') && !declaredUnchanged(plan, 'Notices')
    ? [`THIRD_PARTY_NOTICES.md regenerated in the diff: a manifest or a lockfile changed (S19), or declare \`- Notices: unchanged — <why>\` · write in THIRD_PARTY_NOTICES.md a row \`<package> <version> · <license> · <source>\` for each new dependency, or in specs/${cardName(cardDir)}/plan.md under \`## Changes to existing behavior\`: \`- Notices: unchanged — <why>\``]
    : [];

// The first commit of the card that touches a file: for a file the card creates, the commit that
// creates it; for one that already existed, its first change since the card started (the creator is the
// base's commit and would never close). 'base' marks a file that existed before the card and has no
// commit of the card; null, one that does not exist yet. A card with no base commit (HEAD) looks at all history.
const firstCardCommit = (root, base, f) => {
  if (base === 'HEAD') return firstCommit(root, f);
  const sha = git(root, ['log', '--format=%H', `${base}..HEAD`, '--', f]).stdout?.trim().split('\n').filter(Boolean).at(-1);
  return sha ?? (existedAt(root, base, f) ? 'base' : null);
};

// Rule files: the test is committed before the code (T13)
const ruleTestFirst = ({ root, base, touched, map }) => {
  const out = [];
  for (const line of map.filter((l) => /\brule\b/i.test(l) && /test:\s*\S+/i.test(l))) {
    const test = line.match(/test:\s*`?([^\s`,;)]+)/i)[1].replace(/[.:]+$/, '');
    const file = pathTokens(line).find((t) => /\.\w+$/.test(t) && t !== test && !/^test:/i.test(t));
    if (!file || !touched.includes(file)) continue;
    const t = firstCardCommit(root, base, test);
    const c = firstCardCommit(root, base, file);
    // A test that predates the card, or code the card has not committed yet, cannot come out of order.
    const ordered = t && (!c || c === 'base' || t === 'base' || (t !== c && git(root, ['merge-base', '--is-ancestor', t, c]).status === 0));
    if (!ordered) out.push(`T13 · the unit test ${test} of the rule file ${file} is not committed before the code: commit the test in red first, then the code`);
  }
  return out;
};

// A new secret or sensitive variable is inventoried, without its value (S22)
const secretsInventory = ({ root, base, touched, added, prodAdded, inDiff }) => {
  const names = new Set();
  for (const l of prodAdded) for (const re of ENV_READ) for (const m of l.text.matchAll(re)) if (SENSITIVE_NAME.test(m[1])) names.add(m[1]);
  for (const f of touched.filter((x) => /(^|\/)\.env\.example$/.test(x)))
    for (const l of added.get(f) ?? addedOf(root, base, f)) { const m = l.text.match(/^\s*([A-Z][A-Z0-9_]*)\s*=/); if (m && SENSITIVE_NAME.test(m[1])) names.add(m[1]); }
  const out = [];
  for (const name of names) {
    const where = [[SYSTEM_DESIGN, 'the secrets inventory'], ['.env.example', 'the example of variables']]
      .filter(([f]) => !new RegExp(`\\b${name}\\b`).test(textOf(root, f)) || !inDiff(f));
    const lineFor = (f) => (f === SYSTEM_DESIGN
      ? `in ${SYSTEM_DESIGN} under \`## Secrets inventory\`: \`| ${name} | <purpose> | <consumer> | <owner> | <where it lives per environment> | <privileges> | <created> | <rotation> | <last rotation> |\``
      : `in ${f}: \`${name}=\``);
    if (where.length) out.push(`${name} is a new secret or sensitive variable: name it, without its value, in ${where.map(([f, what]) => `${f} (${what})`).join(' and ')}, both in the diff (S22) · write ${where.map(([f]) => lineFor(f)).join(' and ')}`);
  }
  return out;
};

// Nothing is disabled to make a check pass (A9); a legitimate skip is an AMB that names the file and the cheat
const noDisabledChecks = ({ root, cardDir, touched, added }) => {
  const ambiguities = textOf(root, relativeTo(root, join(cardDir, 'ambiguities.md')));
  const hasAmb = (f, label) => ambiguities.split('\n').some((l) => /AMB-\d+/.test(l) && l.includes(f) && l.includes(label));
  const out = [];
  for (const f of touched.filter((x) => !/^specs\/|\.md$/.test(x))) {
    for (const l of added.get(f) ?? []) {
      const hit = CHEATS.find(([re]) => re.test(l.text)) ?? (IS_CI.test(f) && /\|\|\s*true\b/.test(l.text) ? [null, '|| true'] : null);
      if (hit && !hasAmb(f, hit[1])) out.push(`A9 · ${f}:${l.n} adds \`${hit[1]}\`: the agent does not disable a check to make the pipeline pass; a legitimate skip needs an AMB-NN that names the file and \`${hit[1]}\` · write in ambiguities.md: \`${cardIdOf(cardDir)}-AMB-NN · ${today()} · open · ${f}: ${hit[1]} — <why it cannot be avoided>\``);
    }
  }
  return out;
};

// A card that adds scenarios driven through a browser stabilizes them before they are frozen: the plan's `stable:`
// line runs them 3 times, and it ran and passed (T8). Measured: a card with 30 browser scenarios left it out.
const stableRuns = ({ root, cardDir, touched, added, plan, passed }) => {
  const id = cardIdOf(cardDir);
  const scenario = new RegExp(`@${id}-H\\d+-\\d+`);
  const browser = id && touched.some((f) => IS_TEST.test(f) && (added.get(f) ?? []).some((l) => scenario.test(l.text)) && BROWSER_TEST.test(textOf(root, f)));
  if (!browser) return [];
  const line = stableLine(plan);
  if (!line) return ['a `stable:` line in the plan\'s ## Verification that runs this card\'s browser scenarios 3 times (`npx playwright test --grep "@<ID>" --repeat-each=3`; with `node --test`, `node .claude/tools/repeat.mjs 3 -- node --test <files>`): the card adds browser scenarios (T8)'];
  const command = line.slice(line.indexOf(':') + 1).trim();
  const problem = stableShape(command);
  if (problem) return [problem];
  return passed(/./, [0]).some((r) => r.command === command || r.command.includes(command))
    ? []
    : [`the stable run passed through once.mjs: \`${command}\` (T8) · run: \`node .claude/tools/once.mjs stable -- ${command}\``];
};

const STRUCTURE_CHECKS = [systemDesignSurface, thirdPartyNotices, ruleTestFirst, secretsInventory, noDisabledChecks, stableRuns];

// The documents and the checks the diff of a normal-lane card makes necessary.
const structure = (context) => runChecks(context, STRUCTURE_CHECKS);

// The fast lane: the diff stays inside what the lane allows.
const laneDiff = ({ root, cardDir }) => laneViolations(root, cardDir).map((v) => `outside the fast lane: ${v}`);

// The fast lane: each literal a test replaced leaves its event in ambiguities.md.
const literalEvents = ({ root, cardDir }) => {
  const ambiguities = textOf(root, relativeTo(root, join(cardDir, 'ambiguities.md')));
  return literalChanges(root, cardDir)
    .filter((c) => !ambiguities.split('\n').some((l) => /-TESTS · /.test(l) && /literal updated/.test(l) && l.includes(c.file) && l.includes(`"${c.old}" → "${c.next}"`)))
    .map((c) => `ambiguities.md event \`<ID>-TESTS · <date> · literal updated · ${c.file} · "${c.old}" → "${c.next}"\``);
};

// The fast lane: the lane is measured, one line per card (LANE-09).
const laneRecorded = ({ root, cardDir }) => {
  const card = cardDir.split(/[\\/]/).pop();
  const lane = join(root, 'specs', 'lane.md');
  return !existsSync(lane) || !readFileSync(lane, 'utf8').includes(card)
    ? [`a line for ${card} in specs/lane.md: \`<date> · ${card} · lane: fast · reopened: no\` (the lane is measured, LANE-09)`]
    : [];
};

// What a fast card with production changes must show besides the lane's diff check: the literal
// events and the lane's record; the captures, the accessibility lines and the overflow run are the
// module `ui`'s (checks/ui.mjs), which the lane requires.
const FAST_CHECKS = [literalEvents, laneRecorded];

// The fast lane's evidence: what the diff may contain, plus, if there is production change, its record.
const fastEvidence = (context, touched) => {
  const production = touched.filter((f) => !/^specs\/|\.md$/.test(f) && !IS_TEST.test(f));
  return [...laneDiff(context), ...(production.length
    ? [...modulesMissing(context.root, context, 'fast'), ...runChecks(context, FAST_CHECKS)]
    : [])];
};

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const lacking = missing(process.cwd());
  if (lacking === null) {
    console.error('No card in progress: nothing to require.');
    process.exit(2);
  }
  if (lacking.length === 0) {
    console.log('Everything required ran and passed on the code being delivered.');
    process.exit(0);
  }
  console.log(`Missing, on the code as it is now (${lacking.length}) — what gets run goes through once.mjs:`);
  for (const f of lacking) console.log(`  - ${f}`);
  process.exit(1);
}
