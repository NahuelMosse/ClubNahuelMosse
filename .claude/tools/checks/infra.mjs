// Module `infra`: what a card that touches infrastructure leaves written. Loaded by required.mjs only
// when the module is on; it imports nothing from the other modules.
import { declaredUnchanged, IS_INFRA } from '../card.mjs';

const SYSTEM_DESIGN = 'docs/technical/system-design.md';
const INFRA_COST = 'docs/technical/infra-cost.md';

// The cost model, the system design and the decision record (O13, O14, D14).
const infrastructureDocs = ({ touched, plan, inDiff, newInfraPackage }) => {
  if (!touched.some((f) => IS_INFRA.test(f)) && !newInfraPackage) return [];
  const out = [];
  if (!inDiff(INFRA_COST) && !declaredUnchanged(plan, 'Infra cost'))
    out.push(`${INFRA_COST} in the diff: the card touches infrastructure; update the cost model, or declare \`- Infra cost: unchanged — <why>\` (O13)`);
  if (!inDiff(SYSTEM_DESIGN) && !declaredUnchanged(plan, 'System design'))
    out.push(`${SYSTEM_DESIGN} in the diff: the card touches infrastructure; describe it as it is now, or declare \`- System design: unchanged — <why>\` (O14)`);
  if (!touched.some((f) => /^docs\/adr\/.+\.md$/.test(f)) && !declaredUnchanged(plan, 'ADR'))
    out.push('a docs/adr/*.md added or modified: the card touches infrastructure and the decision and its alternatives are recorded, or declare `- ADR: unchanged — <why>` (D14)');
  return out;
};

export const structure = [infrastructureDocs];
