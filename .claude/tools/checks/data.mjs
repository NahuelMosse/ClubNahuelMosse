// Module `data`: what a card that changes the schema leaves written. Loaded by required.mjs only when
// the module is on; it imports nothing from the other modules.
import { declaredUnchanged, IS_SCHEMA, keyOf } from '../card.mjs';
import { editedFromBase, IS_MIGRATION, migrationsOutlook } from '../migrations.mjs';
import { records } from '../once.mjs';

const SYSTEM_DESIGN = 'docs/technical/system-design.md';

// A schema change lands in the system design: entities, owner module, volume, queries, migrations (P14).
const schemaInSystemDesign = ({ touched, plan, inDiff }) =>
  touched.some((f) => IS_SCHEMA.test(f)) && !inDiff(SYSTEM_DESIGN) && !declaredUnchanged(plan, 'System design')
    ? [`${SYSTEM_DESIGN} in the diff — the schema changes: entities, owner module, volume, queries with their index, migrations (P14) — or declare \`- System design: unchanged — <why>\``]
    : [];

const CHANGE = { M: 'modifies', D: 'deletes', R: 'renames', T: 'changes the type of' };

// DB-MIG-12: what exists in main is not touched; the diff against the base is empty for those files.
const appliedUntouched = ({ root }) => editedFromBase(root).map(({ status, file, label }) =>
  `P16 · DB-MIG-12 · the branch ${CHANGE[status[0]] ?? 'changes'} ${file}, which exists in ${label}: restore it from the base and put the correction in a new migration`);

// DB-MIG-14: the new migrations come after main's last one, with one head and no repeated sequence.
const newOnesAfterMain = ({ root }) => migrationsOutlook(root).problems.map((p) => `P16 · DB-MIG-14 · ${p}`);

// DB-MIG-15: the new migrations ran on top of main's last state with seeded data; the log is the record
// of `once.mjs migrate-upgrade -- <the stack's command>`, on the code as it is now.
const upgradeFromMain = ({ root, touched }) => {
  if (!migrationsOutlook(root).fresh.length && !touched.some((f) => IS_MIGRATION.test(f))) return [];
  const ran = records(root).some((r) => /^migrate-upgrade\b/.test(r.name ?? '') && r.exit === 0 && r.key === keyOf(root, r.command));
  return ran ? [] : ['P5 · DB-MIG-15 · the upgrade from main with seeded data, run on this code: `migrate-upgrade: <the stack\'s command>` in the plan\'s Verification (item Q19), which leaves its log through once.mjs'];
};

export const structure = [schemaInSystemDesign, appliedUntouched, newOnesAfterMain, upgradeFromMain];
