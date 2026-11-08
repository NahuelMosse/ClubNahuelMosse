// Request bodies: parsing, the per-run variation that keeps requests apart, and edits to one string field.

export const FORM = 'application/x-www-form-urlencoded';
export const JSON_TYPE = 'application/json';

const RUN = Date.now().toString(36).slice(-5);
let counter = 0;
export const nextCounter = () => ++counter;

// A value a format rule would reject if suffixed: no letters (a number, a date) or a UUID.
const FORMATTED = /^[^\p{L}]*$|^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/iu;
const isFree = (v) => typeof v === 'string' && !FORMATTED.test(v);

export const isJsonBody = (w) => /^\s*[{[]/.test(w.body) || /json/i.test(w.contentType ?? '');

// A form body (a=1&b=2) as the same fields in a JSON object, every value a string.
export const formToJson = (body) => JSON.stringify(Object.fromEntries(new URLSearchParams(body)));

// A form write with no declared media type answered 415: the API wants JSON and refused the form before looking at anything
// else, so the write is sent as JSON from then on. Returns true when the write was switched.
export function switchToJsonOn415(w, status, settings = {}) {
  if (status !== 415 || isJsonBody(w) || w.contentType || settings.contentType) return false;
  w.body = formToJson(w.body);
  return true;
}

const unescapePointer = (s) => s.replace(/~1/g, '/').replace(/~0/g, '~');
// "/item/email" or "item.email" or "email" => ['item','email']
export const pointerPath = (p) => (p.startsWith('/') ? p.slice(1).split('/').map(unescapePointer) : p.split('.'));

const getAt = (root, path) => path.reduce((o, k) => (o !== null && typeof o === 'object' ? o[k] : undefined), root);
const setAt = (root, path, value) => {
  const parent = getAt(root, path.slice(0, -1));
  parent[path.at(-1)] = value;
};

// Every string leaf of a JSON value, as a path.
const stringLeaves = (value, path = [], out = []) => {
  if (typeof value === 'string') out.push(path);
  else if (value && typeof value === 'object') for (const [k, v] of Object.entries(value)) stringLeaves(v, [...path, Array.isArray(value) ? Number(k) : k], out);
  return out;
};

// The field that keeps requests apart: the explicit one, else the first free string containing @, else the first free string.
const chooseVaryPath = (value, vary) => {
  if (vary) {
    const path = pointerPath(vary);
    return typeof getAt(value, path) === 'string' ? path : null;
  }
  const leaves = stringLeaves(value).filter((p) => isFree(getAt(value, p)));
  return leaves.find((p) => getAt(value, p).includes('@')) ?? leaves[0] ?? null;
};
const tagged = (v, tag) => (v.includes('@') ? v.replace('@', `${tag}@`) : `${v}${tag}`);

// The legitimate body of a write with its varying field suffixed (`-<run><n>`, before the @ of an email), so a uniqueness
// rule never answers in place of the defense under test, in this run or the next.
// Returns { text, type, path, varied, error }; `path` is the string field the probes edit.
export function wire(w, settings = {}, n = nextCounter()) {
  const tag = `-${RUN}${n}`;
  const type = w.contentType ?? settings.contentType ?? (isJsonBody(w) ? JSON_TYPE : FORM);
  if (!isJsonBody(w)) {
    const entries = [...new URLSearchParams(w.body)];
    const key = settings.vary ? entries.find(([k]) => k === settings.vary)?.[0] : (entries.find(([, v]) => isFree(v) && v.includes('@')) ?? entries.find(([, v]) => isFree(v)))?.[0];
    const out = entries.map(([k, v]) => [k, k === key ? tagged(v, tag) : v]);
    return { text: new URLSearchParams(out).toString(), type, form: true, path: key ? [key] : null, varied: key !== undefined };
  }
  let value;
  try { value = JSON.parse(w.body); } catch { return { text: w.body, type, path: null, varied: false, error: 'the body is not valid JSON' }; }
  const path = chooseVaryPath(value, settings.vary);
  if (path) setAt(value, path, tagged(getAt(value, path), tag));
  const fieldPath = path ?? stringLeaves(value)[0] ?? null;
  return { text: JSON.stringify(value), type, path: fieldPath, varied: path !== null, value,
    error: settings.vary && !path ? `--vary "${settings.vary}" does not point at a string in the body` : undefined };
}

// The same wire body with one string field replaced by `make(current)`. Returns null when the body has no string field.
export function withField(p, make) {
  if (!p.path) return null;
  if (p.form) {
    const entries = [...new URLSearchParams(p.text)];
    return new URLSearchParams(entries.map(([k, v]) => [k, k === p.path[0] ? make(v) : v])).toString();
  }
  const value = JSON.parse(p.text);
  setAt(value, p.path, make(getAt(value, p.path)));
  return JSON.stringify(value);
}

// Every string field of the wire body as a path (JSON only): wrong-type probes try them all.
export const stringFields = (p) => (p.value && !p.form ? stringLeaves(p.value) : []);

// The wire body with one string field replaced by a non-string value (JSON only).
export function withValueAt(p, path, replacement) {
  const value = JSON.parse(p.text);
  setAt(value, path, replacement);
  return JSON.stringify(value);
}

// The wire body with the field replaced by a non-string value (JSON only).
export function withValue(p, replacement) {
  if (!p.path || p.form) return null;
  const value = JSON.parse(p.text);
  setAt(value, p.path, replacement);
  return JSON.stringify(value);
}

// Bytes of the body with a MARKER inside a string field, so raw bytes can replace it.
export function splitAtField(p) {
  const text = withField(p, () => 'MARKER');
  return text === null ? null : text.split('MARKER');
}

export const caseVariant = (type) => `${type.split(';')[0].trim().replace(/(^|[/+.-])([a-z])/g, (m, sep, ch) => sep + ch.toUpperCase())}; charset=utf-8`;
