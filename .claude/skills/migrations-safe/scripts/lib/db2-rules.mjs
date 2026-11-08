// The Db2 rules for one ALTER TABLE on an existing table. `add(rule, message, { level })` reports a finding.
import { reorgRecommended } from './db2.mjs';

// Returns the REORG-recommended operations of the statement (a list of names).
export const db2AlterRules = ({ add, table, actions }) => {
  for (const a of actions) {
    const constraint = a.match(/^add\s+(?:constraint\s+\S+\s+)?(foreign\s+key|check)\b/i);
    if (constraint && !/\bnot\s+enforced\b/i.test(a))
      add('db2-constraint-check', `adding a ${/foreign/i.test(constraint[1]) ? 'FOREIGN KEY' : 'CHECK'} constraint to ${table} evaluates every existing row at once (SQLSTATE 23512 if one violates it) while the statement holds its locks: check the rows with a query first, and add it NOT ENFORCED if the application guarantees it, or validate through SET INTEGRITY ... IMMEDIATE CHECKED in a window`);
  }
  return actions.map(reorgRecommended).filter(Boolean);
};
