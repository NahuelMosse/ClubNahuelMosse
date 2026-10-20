// Module `observability`: a new endpoint or integration leaves a metric or a trace. Loaded by
// required.mjs only when the module is on; it imports nothing from the other modules.
import { declaredUnchanged, ROUTE } from '../card.mjs';

const OBSERVABILITY = /opentelemetry|tracer\.|meter\.|startActiveSpan|histogram|counter/i;
const HTTP_CLIENT = /\b(?:from|require\()\s*['"](axios|node-fetch|got|undici|superagent|ky)['"]|\bfetch\s*\(|\brequests\.(get|post|put|delete)\(|\bnew\s+HttpClient\b|\bRestTemplate\b|\bhttpx\./;

// A new endpoint or integration leaves a metric or a trace (O19).
const observabilityMark = ({ plan, prodAdded, newInfraPackage }) => {
  const integration = newInfraPackage || prodAdded.some((l) => HTTP_CLIENT.test(l.text));
  return (prodAdded.some((l) => ROUTE.test(l.text)) || integration) && !prodAdded.some((l) => OBSERVABILITY.test(l.text)) && !declaredUnchanged(plan, 'Observability')
    ? ['a metric or a trace in the diff: the card adds an endpoint or an external integration (O19), or declare `- Observability: unchanged — <why>`']
    : [];
};

export const structure = [observabilityMark];
