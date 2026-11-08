import { granted } from '../http.mjs';
import { caseVariant, isJsonBody, splitAtField, stringFields, withField, withValueAt, wire } from '../body.mjs';

const MIB = 1 << 20;
const ACCEPTED = (s) => s >= 200 && s < 400;

// Malformed and hostile bodies on one write. Every skipped probe is a NOT RUN row.
export async function malformedInput(run, w) {
  const { client } = run;
  const target = `${w.method} ${w.path}`;
  const spec = (probe, name) => ({ group: 'input', probe, target, name: `${target} ${name}` });
  const st = run.settings(w.method, w.path);
  const json = isJsonBody(w);
  const p = wire(w, st);
  const type = p.type;
  const send = (method, body, headers, t = type) => client.send(method, w.path, { body, type: t, headers });

  // The answer must be a 4xx: a 5xx or a dropped connection is recorded as such, a 2xx/3xx as accepted input.
  const mustRefuse = async (s, res, expected, rule = 'accepted-invalid') => {
    if (await run.transportFault(res, s, expected)) return;
    if (ACCEPTED(res.s)) run.fail(rule, s, res.s, expected);
    else run.pass(s, res.s, expected);
  };

  if (json) {
    await mustRefuse(spec('malformed-json', 'malformed JSON'), await send(w.method, '{"x":'), '400 with the error body');

    const split = splitAtField(p);
    const s = spec('invalid-utf8', 'invalid UTF-8 inside a string');
    if (!split) run.notRun(s, 'the body has no string field to put the invalid bytes in');
    else {
      const bytes = Buffer.concat([Buffer.from(split[0]), Buffer.from([0xc3, 0x28, 0xff]), Buffer.from(split[1])]);
      const res = await send(w.method, bytes);
      if (st.invalidUtf8 === 'replace') {
        if (!(await run.transportFault(res, s, 'any non-5xx: the route replaces invalid bytes with U+FFFD'))) run.pass(s, res.s, 'any non-5xx (invalidUtf8: replace)');
      } else await mustRefuse(s, res, '400: strict UTF-8 decoding, nothing stored with U+FFFD (set invalidUtf8: "replace" for a route that replaces by design)');
    }

    const noType = spec('no-content-type', 'without a Content-Type');
    const res = await client.send(w.method, w.path, { body: wire(w, st).text, headers: { 'content-type': undefined } });
    if (!(await run.transportFault(res, noType, '415 (never a 5xx from reading a missing header)'))) run.pass(noType, res.s, '415 (never a 5xx from reading a missing header)');

    const variantSpec = spec('media-type-variant', `${caseVariant(type)}`);
    const variant = await send(w.method, wire(w, st).text, undefined, caseVariant(type));
    if (!(await run.transportFault(variant, variantSpec, 'accepted: media types are case-insensitive and may carry parameters (RFC 9110 8.3.1)'))) {
      if (variant.s === 415) run.fail('media-type-strict', variantSpec, 415, 'accepted: media types are case-insensitive and may carry parameters (RFC 9110 8.3.1)');
      else run.pass(variantSpec, variant.s, 'accepted');
    }

    const fields = stringFields(wire(w, st));
    if (!fields.length) run.notRun(spec('wrong-type', 'string field sent as another type'), 'the body has no string field to replace with another type');
    for (const path of fields) {
      const name = path.join('.');
      for (const [label, tag, value] of [['a number', 'number', 1], ['null', 'null', null], ['an array', 'array', ['a']], ['an object', 'object', { a: 1 }]]) {
        await mustRefuse(spec(`wrong-type-${tag}-${name}`, `"${name}" sent as ${label}`), await send(w.method, withValueAt(wire(w, st), path, value)), '400/422: wrong type, never coerced, never a 5xx');
      }
    }
  } else run.notRun(spec('json-probes', 'JSON probes'), 'the write body is not JSON: malformed JSON, invalid UTF-8, media type and wrong-type probes need a JSON body');

  // Only a 413 shows the limit works. A 400/422 is the validation of the field the probe padded: the limit was not tested.
  // A server that answers early and closes can reset a large upload: the request is repeated once before a drop is judged.
  // `makeBody` builds a new wire body (new unique values) for each attempt: a dropped attempt may already have been stored,
  // and repeating it would answer 409 and hide the missing limit.
  const limitVerdict = async (s, makeBody, expected, rule) => {
    let res = await send(w.method, makeBody());
    if (res.s === null || res.truncated) res = await send(w.method, makeBody());
    if (await run.transportFault(res, s, expected)) return;
    if (res.s === 413) run.pass(s, res.s, expected);
    else if (granted(res)) run.fail(rule, s, res.s, expected, rule === 'limit-counts-characters' ? `${res.s} for a body over the limit` : undefined);
    else run.notRun(s, `answered ${res.s}: the body was refused by validation (or another check) before a size limit, so the limit was not tested`);
  };

  const big = spec('body-1mb', '1 MB body');
  if (st.bodyLimit && st.bodyLimit >= MIB) run.skipped(big, `bodyLimit ${st.bodyLimit} is at least 1 MB`);
  else {
    const makeBody = () => withField(wire(w, st), (v) => v + 'a'.repeat(MIB));
    if (makeBody() === null) run.notRun(big, 'the body has no string field to pad to 1 MB');
    else await limitVerdict(big, makeBody, '413, never stored and never a 5xx', 'no-body-limit');
  }

  const bytesProbe = spec('limit-counts-bytes', 'body 1+ byte over the limit made of multibyte characters');
  const bigRow = run.rows.findLast((r) => r.probe === 'body-1mb' && r.target === target);
  if (!json) { /* the JSON probes above already reported why */ }
  else if (!st.bodyLimit) run.skipped(bytesProbe, 'no body limit configured (--body-limit or bodyLimit)');
  else if (bigRow?.rule === 'no-body-limit') run.skipped(bytesProbe, 'the 1 MB body was accepted: there is no limit to count bytes against');
  else {
    const makeBody = () => {
      const q = wire(w, st);
      const rest = Buffer.byteLength(withField(q, () => '') ?? '');
      return withField(q, () => 'é'.repeat(Math.floor((st.bodyLimit - rest) / 2) + 1));
    };
    if (makeBody() === null) run.notRun(bytesProbe, 'the body has no string field to pad with multibyte characters');
    else await limitVerdict(bytesProbe, makeBody, '413: the limit counts bytes, not characters', 'limit-counts-characters');
  }

  for (const m of ['PUT', 'DELETE', 'PATCH'].filter((x) => x !== w.method)) {
    const s = spec(`method-${m.toLowerCase()}`, `${m} (a method the route does not take)`);
    const res = await send(m, wire(w, st).text);
    if (await run.transportFault(res, s, '405 with Allow (or 404)')) continue;
    if (ACCEPTED(res.s)) run.fail('accepted-invalid', s, res.s, '405 with Allow (or 404)');
    else if (res.s === 405 && !res.headers.allow) run.fail('missing-allow', s, 405, '405 must name the allowed methods in Allow (RFC 9110 15.5.6)');
    else run.pass(s, res.s, '405 with Allow (or 404)');
  }
}
