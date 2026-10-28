#!/usr/bin/env node
// PreToolUse on Bash, PowerShell and the Jira comment tool: an agent publishes on its own, without rewriting history.
// Allowed: `git push -u <remote> <branch>` of any branch but the default one, `gh pr create|comment|edit`, and
// `gh pr merge` once the PR's checks pass and, inside a card, its closing.md has nothing failed and nothing for a person;
// one comment with the questions of the card, one comment that closes it.
// Blocked: a push of main or the default branch, any force, delete, mirror or tag push, a merge with --admin or with
// failing checks, a second comment of questions, a closing comment without closing.md. Inside a card, its PR is opened
// after closing.md, ready for review and against the default branch.
// A regex over a shell line is incomplete by nature: a wrapper (`sh -c`, `eval`) around a push is refused
// instead of parsed, and the branch protection of the remote is the layer that no command dodges.
// A refused call goes through only when the user's last message orders it: the refusals guard an agent acting alone, not a
// person. The order is read from the session transcript and has to be explicit: an imperative of the action ("mergealo",
// "push it", "autorizo"), no question and no negation, and it names what made the call risky (main, force, admin, delete).
// Contract: exit 0 lets it through, exit 2 blocks and Claude reads stderr. On its own error it blocks.
import { appendFileSync, existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';

// The user's last message in the session: a typed prompt or one sent while the agent worked; tool results,
// reminders and subagents are not theirs.
const lastUserText = (path) => {
  if (!path || !existsSync(path)) return '';
  let text = '';
  for (const line of readFileSync(path, 'utf8').split('\n')) {
    if (!line.includes('"user"') && !line.includes('queued_command')) continue;
    let e;
    try { e = JSON.parse(line); } catch { continue; }
    const own = e.type === 'user' && !e.isMeta && !e.isSidechain;
    if (own && typeof e.message?.content === 'string') text = e.message.content;
    else if (own && Array.isArray(e.message?.content) && e.message.content.length && e.message.content.every((c) => c.type === 'text')) {
      text = e.message.content.map((c) => c.text).filter((t) => !t.startsWith('<')).join('\n') || text;
    } else if (e.type === 'attachment' && e.attachment?.type === 'queued_command' && e.attachment.origin?.kind === 'human') {
      text = String(e.attachment.prompt ?? '');
    }
  }
  return text;
};
// The order of an action: an imperative, never an infinitive or a remark ("deberían poder mergear" orders nothing).
const AUTHORIZE = /\bautorizo\b|\bi authori[sz]e\b|\bgo ahead\b/i;
const ORDERS = {
  push: /\bpushe[aá](?:lo|la|los|las)?(?![\wáéíóúñ])|\bhac[eé]\s+(?:el\s+)?push\b|\bsub[ií](?:lo|la|los|las)\b|(?:^|[.,;!]\s*|\b(?:y|dale|ahora|and|now)\s+)push\b/im,
  merge: /\bmerge[aá](?:lo|la|los|las)?(?![\wáéíóúñ])|\bhac[eé]\s+(?:el\s+)?merge\b|(?:^|[.,;!]\s*|\b(?:y|dale|ahora|and|now)\s+)merge\b/im,
  gh: /\b(?:cre[aá]|abr[ií]|cerr[aá])(?:lo|la)?\s+(?:el\s+|un\s+|la\s+)?(?:pr|pull request)\b|\b(?:open|close|create)\s+(?:a|the|this)\s+(?:pr|pull request)\b|\bcorr[eé]\s+gh\b|\brun\s+gh\b/i,
};
ORDERS.gh = new RegExp(`${ORDERS.gh.source}|${ORDERS.push.source}|${ORDERS.merge.source}`, 'im');
const NEGATED = /\b(?:no|nunca|ni)\s+(?:\w+\s+){0,2}(?:merg|push|sub|publiq|abr|cre)|\b(?:don't|do not|never)\s+(?:\w+\s+){0,2}(?:merge|push|open)/i;
// What made a call risky has to be named by the order: the default branch, a force, --admin, a delete.
const RISKS = [
  [/--force|\s-f\b|\s\+\S/, /forc|forz/i],
  [/--admin/, /admin/i],
  [/--delete|\s:\S|--mirror|--all|--tags/, /delet|borr|elimin|mirror|all|tag/i],
];
const named = (command, text, branches) => RISKS.every(([inCall, inText]) => !inCall.test(command) || inText.test(text)) &&
  [...branches].every((b) => !new RegExp(`(?:^|[\\s:/])${escape(b)}(?:$|\\s)`).test(command) || new RegExp(`\\b${escape(b)}\\b`, 'i').test(text));
const userOrders = (text, what, command, branches) =>
  !!text && !text.includes('?') && !NEGATED.test(text) && (ORDERS[what].test(text) || AUTHORIZE.test(text)) && named(command, text, branches);

// While a git or gh call is checked, `asked` names it and `call` holds its line; a refusal of what the user ordered lets it through.
let asked = null;
let call = '';
let defaults = () => new Set();
let transcript = '';
let userText = null;
class UserAsked extends Error {}
const block = (reason) => {
  if (asked) {
    userText ??= lastUserText(transcript);
    if (userOrders(userText, asked, call, defaults())) throw new UserAsked(reason);
  }
  process.stderr.write(reason + (asked ? ' Only the user can lift this refusal: ask them, naming the exact command. It goes through ' +
    'when their next message orders it ("mergealo", "pusheá a main", "autorizo"), names what is risky in it (main, --force, ' +
    '--admin) and is not a question.' : '') + '\n');
  process.exit(2);
};

const escape = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const read = (path) => (existsSync(path) ? readFileSync(path, 'utf8') : '');
const today = () => new Date().toISOString().slice(0, 10);

try {
  const raw = readFileSync(0, 'utf8');
  const input = JSON.parse(raw);
  transcript = String(input.transcript_path ?? '');
  const cardMod = await import('../tools/card.mjs');
  await cardMod.delegateToRepo(import.meta.url, raw, input);

  const tool = String(input.tool_name ?? '');
  const isComment = /^mcp__.*addComment/i.test(tool);
  const isShell = tool === 'Bash' || tool === 'PowerShell';
  if (!isComment && !isShell) process.exit(0);

  const data = input.tool_input ?? {};
  const cmd = isShell ? String(data.command ?? '') : '';
  const cwd = input.cwd ?? process.cwd();

  // The card in progress, looked up only when something is about to be published: a shell line that does
  // not push or call gh needs no card.
  let cached = null;
  let looked = false;
  let inProgress = null;
  const openCard = () => {
    if (!looked) { looked = true; inProgress = cardMod.hookCard(cwd, process.env, input); }
    return inProgress;
  };
  const card = () => {
    if (cached) return cached;
    const found = openCard();
    if (!found) block('A Jira comment belongs to a card, and there is no card in progress here (specs/.current).');
    const title = read(join(found.card, 'card.md')).match(/^#\s+([A-Za-z]\w*-\d+[A-Za-z0-9]*)/m)?.[1];
    const id = title ?? found.card.split(/[\\/]/).pop().match(/^[A-Za-z]\w*-\d+[A-Za-z0-9]*/)?.[0];
    if (!id) block('The card in progress has no key in the title of its card.md nor in its folder name: the branch and the Jira key cannot be checked.');
    cached = { root: found.root, dir: found.card, id, ambiguitiesPath: join(found.card, 'ambiguities.md') };
    return cached;
  };

  const closingReady = () => {
    const text = read(join(card().dir, 'closing.md'));
    return ['Passed', 'Failed', 'Could not run'].every((s) => new RegExp(`^## ${s}\\b`, 'mi').test(text));
  };
  // Every block says what the agent may do and what is missing for this call: it is never told it cannot publish.
  const NEEDS_CLOSING = 'You can open, edit, comment and merge this card\'s PR; it comes after its close. Missing now: ' +
    'specs/<card>/closing.md with its three sections (## Passed, ## Failed, ## Could not run). Run /close, then publish.';

  const root = () => openCard()?.root ?? cwd;
  const git = (...args) => spawnSync('git', args, { cwd: root(), encoding: 'utf8' });
  const currentBranch = () => git('rev-parse', '--abbrev-ref', 'HEAD').stdout.trim();
  const defaultBranches = () => {
    const names = new Set(['main', 'master', 'trunk']);
    const head = git('symbolic-ref', '--short', 'refs/remotes/origin/HEAD').stdout.trim();
    if (head) names.add(head.replace(/^origin\//, ''));
    const init = git('config', 'init.defaultBranch').stdout.trim();
    if (init) names.add(init);
    return names;
  };
  // The default branch takes changes only through a merged PR, whose checks ran.
  const checkBranch = (branch) => {
    if (defaultBranches().has(branch)) {
      block(`You can push and merge, but not straight onto \`${branch}\`, the default branch. Push your own branch ` +
            '(`git switch -c <name>` and `git push -u origin <name>`), open its PR, and `gh pr merge` brings it in once the checks pass.');
    }
  };

  const words = (segment) => [...segment.matchAll(/"([^"]*)"|'([^']*)'|(\S+)/g)].map((m) => m[1] ?? m[2] ?? m[3]);
  const flagValue = (args, names) => {
    for (let i = 0; i < args.length; i++) {
      for (const n of names) {
        if (args[i] === n) return args[i + 1] ?? '';
        if (n.startsWith('--') && args[i].startsWith(`${n}=`)) return args[i].slice(n.length + 1);
      }
    }
    return null;
  };

  const PUSH_FLAGS = new Set(['-u', '--set-upstream', '-q', '--quiet', '-v', '--verbose', '-n', '--dry-run', '--porcelain', '--progress', '--atomic']);
  // `2>&1`, `> log`, `2>/dev/null`: where the output goes is not an argument of the push.
  const withoutRedirections = (args) => {
    const out = [];
    for (let i = 0; i < args.length; i++) {
      const m = /^(?:\d*|&)>{1,2}(.*)$/.exec(args[i]) ?? /^\d*<(.*)$/.exec(args[i]);
      if (!m) out.push(args[i]);
      else if (!m[1]) i++;
    }
    return out;
  };
  const NO_REMOTE = 'You can push and open PRs, but this repo has no remote (git lists none): there is nowhere to publish. ' +
    'Inside a card, publishing is *could not run*: write in closing.md, under `## Could not run`, the line ' +
    '`publish: could not run, no remote configured (git remote is empty)`, and finish the close without a PR.';
  const hasRemote = () => git('remote').stdout.trim() !== '';
  const checkPush = (rawArgs) => {
    const args = withoutRedirections(rawArgs);
    if (!hasRemote()) block(NO_REMOTE);
    const bad = args.filter((a) => a.startsWith('-')).find((f) => !PUSH_FLAGS.has(f));
    if (bad) {
      block(`You can push; ${bad} is the part that is refused, because force, delete, mirror, all and tags push more than one branch or rewrite it. ` +
            'Push as `git push -u origin <branch>` (-u, -q, -v and --dry-run are accepted).');
    }
    const [remote, ...refspecs] = args.filter((a) => !a.startsWith('-'));
    if (!remote || refspecs.length !== 1) {
      block('You can push; name the remote and the one branch: `git push -u origin <branch>`. A push without them sends what ' +
            'the upstream setting says, which may be main.');
    }
    if (!/^[\w.-]+$/.test(remote)) block(`You can push to a remote by its name; ${remote} is a URL, which is not pushed to. Add it with \`git remote add\` and push to that name.`);
    const spec = refspecs[0];
    if (spec.startsWith('+') || spec.startsWith(':')) {
      block(`You can push; the refspec ${spec} forces or deletes, which is refused. Push the branch plainly: \`git push -u origin <branch>\`.`);
    }
    const here = currentBranch();
    const name = (r) => r.replace(/^refs\/heads\//, '').replace(/^HEAD$/, here);
    const [src, dst = src] = spec.split(':');
    if (name(src) !== name(dst)) block(`You can push; ${spec} pushes one branch onto another, which is refused. Push each branch onto its own name.`);
    checkBranch(name(dst));
  };

  const GH_READ = new Set(['view', 'list', 'status', 'diff', 'checks']);
  const GH_WRITE = new Set(['create', 'comment', 'edit']);
  const checkGh = (args) => {
    const [sub, verb] = args.filter((a) => !a.startsWith('-'));
    if (sub === 'api') {
      const method = (flagValue(args, ['-X', '--method']) ?? 'GET').toUpperCase();
      const writes = method !== 'GET' || args.some((a) => /^(-f|-F|--field|--raw-field|--input)$/.test(a));
      if (writes) block('You can open, comment, edit and merge PRs with `gh pr`; a `gh api` call that writes is refused because it cannot be checked. Use the pr subcommand.');
      return;
    }
    if (sub !== 'pr' || GH_READ.has(verb)) return;
    if (verb === 'merge') return checkMerge(args);
    if (!GH_WRITE.has(verb)) {
      block(`You can create, comment, edit, merge and read PRs (view, checks, list, status, diff); \`gh pr ${verb ?? ''}\` is the one refused.`);
    }
    if (verb === 'create' && !hasRemote()) block(NO_REMOTE);
    // Outside a card the agent opens and edits its PRs as it sees fit; a card's PR comes from its close.
    if (!openCard()) return;
    if (!closingReady()) block(NEEDS_CLOSING);
    if (verb === 'create') {
      if (args.some((a) => a === '--draft' || a === '-d')) block('You can open this card\'s PR; it goes ready for review, not as a draft. Drop --draft.');
      const base = flagValue(args, ['--base', '-B']);
      if (base !== null && !defaultBranches().has(base)) block(`You can open this card\'s PR; it goes against the default branch, not ${base}. Drop --base or point it there.`);
      const head = flagValue(args, ['--head', '-H']);
      if (head !== null && head.split(':').pop() !== currentBranch()) block('You can open this card\'s PR; it is opened from the branch that is checked out. Switch to it, or drop --head.');
      checkBranch(currentBranch());
    }
    if (verb === 'edit' && flagValue(args, ['--base', '-B']) !== null) block('You can edit this card\'s PR; its base stays the default branch. Drop --base.');
  };

  // A merge goes in when the PR's checks pass (a repo without CI has none to wait for) and, inside a card, its closing.md
  // has nothing failed and nothing left for a person. --admin skips the branch protection, so it is never used.
  const section = (text, name) => text.split(/^## /m).find((p) => p.startsWith(name))?.slice(name.length) ?? null;
  const checkMerge = (args) => {
    if (args.includes('--admin')) block('You can merge this PR; --admin is the part that is refused, because it skips the branch protection. Run `gh pr merge` without it.');
    const pr = args.filter((a) => !a.startsWith('-')).slice(2, 3);
    // KIT_GH_CHECKS: a node script that stands in for `gh pr checks` in the kit's tests.
    const fake = process.env.KIT_GH_CHECKS;
    const checks = fake ? spawnSync(process.execPath, [fake, ...pr], { cwd: root(), encoding: 'utf8' })
      : spawnSync('gh', ['pr', 'checks', ...pr], { cwd: root(), encoding: 'utf8' });
    const out = `${checks.stdout ?? ''}${checks.stderr ?? ''}`;
    if (checks.status !== 0 && !/no checks reported/i.test(out)) {
      block(`You can merge this PR once its checks pass; they do not yet (\`gh pr checks\`: ${out.trim().split('\n').slice(0, 3).join(' · ') || `exit ${checks.status}`}). ` +
            'Wait for them (`gh pr checks --watch`) or fix what fails and push, then merge.');
    }
    if (!openCard()) return;
    if (!closingReady()) block(NEEDS_CLOSING);
    const closing = read(join(card().dir, 'closing.md'));
    const failed = (section(closing, 'Failed') ?? '').split('\n').filter((l) => /^\s*[-*]\s+\S/.test(l));
    if (failed.length) block(`You can merge this card's PR once nothing fails; closing.md lists ${failed.length} failed check${failed.length > 1 ? 's' : ''}. Fix them, rerun /close, then merge.`);
    if (section(closing, 'Needs a person') !== null) {
      block('You can merge PRs, but this one has `## Needs a person` in closing.md: those lines are a person\'s call, so a person merges it. ' +
            'Leave the PR open and say so in your report.');
    }
  };

  if (isShell) {
    // A heredoc body is text (a commit message), not commands.
    const body = cmd.replace(/<<-?\s*['"]?(\w+)['"]?[^\n]*\n[\s\S]*?\n\s*\1\b/g, ' ');
    for (const segment of cardMod.splitShell(body)) {
      const tokens = words(segment.replace(/^\s*\(+/, ''));
      while (tokens.length && /^\w+=/.test(tokens[0])) tokens.shift();
      const [program = '', ...rest] = tokens;
      call = ` ${segment.trim()} `;
      defaults = defaultBranches;
      try {
        if (/^(sh|bash|zsh|pwsh|powershell|cmd|eval|xargs|env|nohup|start)(\.exe)?$/i.test(program) &&
            /\bgit\b[\s\S]*\bpush\b|\bgh\s+(pr|api)\b/.test(segment)) {
          asked = 'gh';
          block('You can push and call gh; inside a wrapper (sh -c, eval, xargs) the call cannot be checked. Run it directly.');
        } else if (/^git(\.exe)?$/i.test(program)) {
          let i = 0;
          while (i < rest.length && rest[i].startsWith('-')) i += ['-C', '-c', '--git-dir', '--work-tree'].includes(rest[i]) ? 2 : 1;
          if (rest[i] === 'push') { asked = 'push'; checkPush(rest.slice(i + 1)); }
        } else if (/^gh(\.exe)?$/i.test(program)) {
          asked = rest.filter((a) => !a.startsWith('-'))[1] === 'merge' ? 'merge' : 'gh';
          checkGh(rest);
        }
      } catch (e) {
        if (!(e instanceof UserAsked)) throw e;
      } finally {
        asked = null;
      }
    }
    process.exit(0);
  }

  // The Jira comment: one with the questions, one that closes the card, nothing else, on the card's own issue.
  const { id, dir, ambiguitiesPath } = card();
  const ambiguities = read(ambiguitiesPath);
  const key = [data.issueIdOrKey, data.issueKey, data.issue_key, data.issueId, data.key].find((v) => typeof v === 'string' && v);
  const text = [data.commentBody, data.body, data.comment].find((v) => typeof v === 'string') ?? '';
  if (key?.toUpperCase() !== id.toUpperCase()) block(`The comment goes on the card in progress, ${id}, not on ${key ?? 'an unnamed issue'}.`);
  if (!text.trim()) block('An empty comment is not posted.');

  const last = (kind) => [...ambiguities.matchAll(new RegExp(`^${escape(id)}-${kind} · [^·\\n]*· (posted|failed)\\b`, 'gm'))].map((m) => m[1]).at(-1);
  const record = (line) => appendFileSync(ambiguitiesPath, `${!ambiguities || ambiguities.endsWith('\n') ? '' : '\n'}${line}\n`);

  if (existsSync(join(dir, 'closing.md'))) {
    if (!closingReady()) block(NEEDS_CLOSING);
    if (last('CLOSE') === 'posted') block('The closing comment is already on the card: there is one per card.');
    record(`${id}-CLOSE · ${today()} · posted · closing comment on the card`);
    process.exit(0);
  }

  const lastState = new Map();
  for (const m of ambiguities.matchAll(new RegExp(`^${escape(id)}-AMB-(\\d+) · [^·\\n]*· ([\\w ]+?)(?: ·|$)`, 'gm'))) lastState.set(m[1], m[2]);
  lastState.delete('00');
  const open = [...lastState.values()].filter((s) => s === 'open').length;
  if (last('ASK') === 'posted') {
    block('The questions of this card were already posted: there is one round of questions per card, and it is one comment. ' +
          'A doubt that appears now becomes an ASM-NN with its test and is listed in the PR. If the call failed, ' +
          `append ${id}-ASK · <date> · failed · <error> to ambiguities.md and post again once.`);
  }
  if (!open) {
    block('There is no open AMB-NN in ambiguities.md to ask about, and a closing comment needs closing.md first. ' +
          'Questions are posted once, at the end of step 2, with every open ambiguity in the same comment.');
  }
  record(`${id}-ASK · ${today()} · posted · ${open} open question${open > 1 ? 's' : ''} in one comment on the card`);
} catch (e) {
  block(`The publication guard could not evaluate the call (${e.message}). It blocks when in doubt: retry.`);
}
process.exit(0);
