// The single registry of finding rules. SKILL.md's severity table is checked against it by the test suite.
// A finding id is `<rule>:<probe>:<target>`; the probe and the target never contain generated values (row ids, run tags).

export const SEVERITIES = ['critical', 'high', 'medium', 'low'];

export const RULES = {
  'process-died': { severity: 'critical', meaning: 'the app stopped answering during a probe' },
  'unauthenticated-access': { severity: 'critical', meaning: 'a write or read is granted (2xx) without credentials' },
  idor: { severity: 'critical', meaning: "another user's credentials reach this user's object (2xx)" },
  'sql-injection': { severity: 'critical', meaning: 'an injected OR returns rows that a no-match control does not' },
  'duplicates-stored': { severity: 'critical', meaning: 'concurrent identical creates stored more than one distinct item' },
  'file-served': { severity: 'critical', meaning: 'a repo, secret or OS file came back over HTTP' },
  csrf: { severity: 'critical', meaning: 'a cookie-authenticated write from a foreign Origin was accepted' },
  'not-durable': { severity: 'critical', meaning: 'a saved item is gone or different after a restart' },
  'foreign-origin-accepted': { severity: 'high', meaning: 'a request from a foreign Origin was accepted (`--origin-check always`)' },
  'ambient-credentials': { severity: 'high', meaning: 'with `--no-ambient`, a legitimate response sets Set-Cookie or asks WWW-Authenticate' },
  'connection-dropped': { severity: 'high', meaning: 'the connection was closed without a response while the app stayed up' },
  'server-error': { severity: 'high', meaning: 'a 5xx on client input (including path params, quotes and unique violations)' },
  'accepted-invalid': { severity: 'high', meaning: 'input that must be refused got a 2xx/3xx (bad JSON, invalid UTF-8, wrong type, other methods)' },
  'no-body-limit': { severity: 'high', meaning: 'a body over the limit is accepted, or a body that never ends is read forever' },
  'double-slash-mismatch': { severity: 'high', meaning: '`//x` answers 2xx with something other than `/x`' },
  'wildcard-unescaped': { severity: 'high', meaning: '`%` or `_` in a search reach LIKE as wildcards' },
  'parser-accepted': { severity: 'high', meaning: 'the HTTP parser let a malformed raw request through' },
  'fault-not-reported': { severity: 'high', meaning: 'a write during a database fault was not answered with a 5xx' },
  'limit-counts-characters': { severity: 'medium', meaning: 'the body limit counts characters, not bytes' },
  'read-before-reject': { severity: 'medium', meaning: 'a 50 MB body was read in full before the 415' },
  'media-type-strict': { severity: 'medium', meaning: 'a case or parameter variant of the media type is refused (RFC 9110 8.3.1)' },
  'stack-leak': { severity: 'medium', meaning: 'a 5xx body leaks a stack trace, driver error or SQLSTATE' },
  'parser-no-common-headers': { severity: 'medium', meaning: "a parser-level error lacks the app's common headers" },
  'headers-missing': { severity: 'medium', meaning: 'a response lacks a header every response must carry' },
  'foreign-host-accepted': { severity: 'medium', meaning: 'a request with a foreign Host was accepted (`--strict-host`; an info row without it)' },
  'undocumented-status': { severity: 'medium', meaning: 'with `--openapi`, the app answered a status the contract does not declare for that operation' },
  'missing-allow': { severity: 'low', meaning: '405 without an `Allow` header' },
  'head-unsupported': { severity: 'low', meaning: 'HEAD on a readable route answers 405 (RFC 9110 9.1)' },
  'not-run': { severity: null, meaning: 'a probe could not reach a verdict; never a pass' },
};

export const severityOf = (rule) => {
  if (!(rule in RULES)) throw new Error(`unknown rule ${rule}`);
  return RULES[rule].severity;
};

export const EXIT = { OK: 0, FINDINGS: 1, ERROR: 2 };
