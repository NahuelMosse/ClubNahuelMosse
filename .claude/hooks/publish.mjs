#!/usr/bin/env node
// PreToolUse on Bash, PowerShell and the Jira comment tool: what the close publishes, and nothing else.
// Allowed: `git push -u <remote> <card branch>`, `gh pr create` (ready for review, against the default
// branch), `gh pr comment|edit`, one comment with the questions of the card, one comment that closes it.
// Blocked: a push of main or the default branch, any force, delete, mirror or tag push, a draft PR, a
// merge, a second comment of questions, a closing comment without closing.md.
// A regex over a shell line is incomplete by nature: a wrapper (`sh -c`, `eval`) around a push is refused
// instead of parsed, and the branch protection of the remote is the layer that no command dodges.
// Contract: exit 0 lets it through, exit 2 blocks and Claude reads stderr. On its own error it blocks.
import { appendFileSync, existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';

const block = (reason) => {
  process.stderr.write(reason + '\n');
  process.exit(2);
};

const escape = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const read = (path) => (existsSync(path) ? readFileSync(path, 'utf8') : '');
const today = () => new Date().toISOString().slice(0, 10);

try {
  const raw = readFileSync(0, 'utf8');
  const input = JSON.parse(raw);
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
  const card = () => {
    if (cached) return cached;
    const found = cardMod.hookCard(cwd, process.env, input);
    if (!found) {
      block('Publishing belongs to the close of a card, and there is no card in progress here (specs/.current). ' +
            'Nothing is pushed, opened or commented on outside a card.');
    }
    const snapshot = read(join(found.card, 'card.snapshot.md'));
    const id = snapshot.match(/^card:\s*(\S+)/m)?.[1] ?? found.card.split(/[\\/]/).pop().match(/^[A-Za-z]\w*-\d+/)?.[0];
    if (!id) block('The card in progress has no `card:` in its snapshot: the branch and the Jira key cannot be checked.');
    cached = { root: found.root, dir: found.card, id, ambiguitiesPath: join(found.card, 'ambiguities.md') };
    return cached;
  };

  const closingReady = () => {
    const text = read(join(card().dir, 'closing.md'));
    return ['Passed', 'Failed', 'Could not run'].every((s) => new RegExp(`^## ${s}\\b`, 'mi').test(text));
  };
  const NEEDS_CLOSING = 'There is no specs/<card>/closing.md with its three sections (## Passed, ## Failed, ## Could not run): ' +
    'the PR and the closing comment come from the validations of /close, so it is written first.';

  const git = (...args) => spawnSync('git', args, { cwd: card().root, encoding: 'utf8' });
  const currentBranch = () => git('rev-parse', '--abbrev-ref', 'HEAD').stdout.trim();
  const defaultBranches = () => {
    const names = new Set(['main', 'master', 'trunk']);
    const head = git('symbolic-ref', '--short', 'refs/remotes/origin/HEAD').stdout.trim();
    if (head) names.add(head.replace(/^origin\//, ''));
    const init = git('config', 'init.defaultBranch').stdout.trim();
    if (init) names.add(init);
    return names;
  };
  // The card's branch starts with the card's key, is the one checked out, and is not a default branch.
  const checkBranch = (branch) => {
    const here = currentBranch();
    if (defaultBranches().has(branch)) {
      block(`\`${branch}\` is the default branch: it is never pushed from a card. The card's work goes on its own branch ` +
            '(`git switch -c <folder name of specs/<card>>`) and the PR is the review.');
    }
    if (!new RegExp(`^${escape(card().id)}-`).test(branch)) {
      block(`Only the card's branch is pushed: its name starts with \`${card().id}-\` (the folder name of the card). \`${branch}\` does not.`);
    }
    if (branch !== here) block(`Only the branch that is checked out is pushed: \`${here}\` is, not \`${branch}\`.`);
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
  const NO_REMOTE = 'This repo has no remote (git lists none): there is nowhere to push or open a PR, and neither is attempted. ' +
    'Publishing is *could not run*: write in closing.md, under `## Could not run`, the line ' +
    '`publish: could not run, no remote configured (git remote is empty)`, and finish the close without a PR.';
  const hasRemote = () => git('remote').stdout.trim() !== '';
  const checkPush = (rawArgs) => {
    const args = withoutRedirections(rawArgs);
    if (!hasRemote()) block(NO_REMOTE);
    const bad = args.filter((a) => a.startsWith('-')).find((f) => !PUSH_FLAGS.has(f));
    if (bad) {
      block(`The option ${bad} is not allowed on a push: force, delete, mirror, all and tags push more than the card's branch. ` +
            'The form is `git push -u origin <card branch>` (-u, -q, -v and --dry-run are accepted).');
    }
    const [remote, ...refspecs] = args.filter((a) => !a.startsWith('-'));
    if (!remote || refspecs.length !== 1) {
      block('Name the remote and the one branch: `git push -u origin <card branch>`. A push without them sends what ' +
            'the upstream setting says, which may be main.');
    }
    if (!/^[\w.-]+$/.test(remote)) block(`${remote} is not a remote name: a URL is not pushed to.`);
    const spec = refspecs[0];
    if (spec.startsWith('+') || spec.startsWith(':')) {
      block(`The refspec ${spec} forces or deletes: only a plain push of the card's branch goes through.`);
    }
    const here = currentBranch();
    const name = (r) => r.replace(/^refs\/heads\//, '').replace(/^HEAD$/, here);
    const [src, dst = src] = spec.split(':');
    if (name(src) !== name(dst)) block(`The refspec ${spec} pushes one branch onto another: the card's branch goes onto its own name.`);
    checkBranch(name(dst));
  };

  const GH_READ = new Set(['view', 'list', 'status', 'diff', 'checks']);
  const GH_WRITE = new Set(['create', 'comment', 'edit']);
  const checkGh = (args) => {
    const [sub, verb] = args.filter((a) => !a.startsWith('-'));
    if (sub === 'api') {
      const method = (flagValue(args, ['-X', '--method']) ?? 'GET').toUpperCase();
      const writes = method !== 'GET' || args.some((a) => /^(-f|-F|--field|--raw-field|--input)$/.test(a));
      if (writes) block('An api call that writes is not allowed: the PR is opened and commented with the pr subcommands (create, comment).');
      return;
    }
    if (sub !== 'pr' || GH_READ.has(verb)) return;
    if (verb === 'merge') block('The PR is not merged: the human review is the PR, and the merge is the reviewer\'s.');
    if (!GH_WRITE.has(verb)) {
      block(`The pr subcommand ${verb ?? ''} is not allowed. Open (create), comment, edit and read (view, checks, list, status, diff) are.`);
    }
    if (!closingReady()) block(NEEDS_CLOSING);
    if (verb === 'create') {
      if (!hasRemote()) block(NO_REMOTE);
      if (args.some((a) => a === '--draft' || a === '-d')) block('The PR is ready for review, not a draft: drop --draft.');
      const base = flagValue(args, ['--base', '-B']);
      if (base !== null && !defaultBranches().has(base)) block(`The PR goes against the default branch, not ${base}.`);
      const head = flagValue(args, ['--head', '-H']);
      if (head !== null && head.split(':').pop() !== currentBranch()) block('The PR is opened from the branch that is checked out.');
      checkBranch(currentBranch());
    }
    if (verb === 'edit' && flagValue(args, ['--base', '-B']) !== null) block('The base of the PR is not changed.');
  };

  if (isShell) {
    // A heredoc body is text (a commit message), not commands.
    const body = cmd.replace(/<<-?\s*['"]?(\w+)['"]?[^\n]*\n[\s\S]*?\n\s*\1\b/g, ' ');
    for (const segment of cardMod.splitShell(body)) {
      const tokens = words(segment.replace(/^\s*\(+/, ''));
      while (tokens.length && /^\w+=/.test(tokens[0])) tokens.shift();
      const [program = '', ...rest] = tokens;
      if (/^(sh|bash|zsh|pwsh|powershell|cmd|eval|xargs|env|nohup|start)(\.exe)?$/i.test(program) &&
          /\bgit\b[\s\S]*\bpush\b|\bgh\s+(pr|api)\b/.test(segment)) {
        block('A push or a gh call inside a wrapper (sh -c, eval, xargs) cannot be checked: run it directly.');
      }
      if (/^git(\.exe)?$/i.test(program)) {
        let i = 0;
        while (i < rest.length && rest[i].startsWith('-')) i += ['-C', '-c', '--git-dir', '--work-tree'].includes(rest[i]) ? 2 : 1;
        if (rest[i] === 'push') checkPush(rest.slice(i + 1));
      } else if (/^gh(\.exe)?$/i.test(program)) {
        checkGh(rest);
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
