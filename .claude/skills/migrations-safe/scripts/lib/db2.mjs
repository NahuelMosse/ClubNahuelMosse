// Db2 for Linux, UNIX and Windows knowledge the rules need (IBM Docs, Db2 11.5, ALTER TABLE statement):
// DROP COLUMN, SET NOT NULL, DROP NOT NULL and SET DATA TYPE are REORG-recommended operations. After one,
// most operations on the table are restricted (SQLSTATE 57007) until a classic offline REORG TABLE completes,
// and at most three units of work with such operations are allowed before that REORG is required (SQLSTATE
// 55019). Increasing the length of a VARCHAR, VARGRAPHIC or VARBINARY column is not one of them. Adding a check
// or referential constraint evaluates the existing rows immediately (SQLSTATE 23512 on a violation). CREATE INDEX
// lets readers and writers in during the build and blocks writers only at its end. The default LOCKTIMEOUT is
// -1: wait for a lock without limit.
import { ident } from './parse.mjs';

export const REORG_UNIT_LIMIT = 3;
export const REORG_STATEMENT = new RegExp(String.raw`^(?:call\s+sysproc\.admin_cmd\s*\(\s*')?reorg\s+(?:table|indexes\s+all\s+for\s+table)\s+(${ident})`, 'i');
export const INPLACE = /\binplace\b/i;
export const LOCK_TIMEOUT = /^set\s+current\s+lock\s+timeout\s*(?:=\s*)?(?:\d+|nowait|wait\s+\d+)(?:\s|$)/i;
export const COMMIT = /^commit\b/i;

// The kind of REORG-recommended operation an ALTER TABLE action is, or null.
export const reorgRecommended = (action) => {
  const a = action.trim();
  if (/^drop\s+column\b/i.test(a)) return 'DROP COLUMN';
  if (/^alter\s+(?:column\s+)?\S+\s+set\s+not\s+null\b/i.test(a)) return 'SET NOT NULL';
  if (/^alter\s+(?:column\s+)?\S+\s+drop\s+not\s+null\b/i.test(a)) return 'DROP NOT NULL';
  const type = a.match(/^alter\s+(?:column\s+)?\S+\s+set\s+data\s+type\s+(.*)$/i)?.[1];
  if (type !== undefined && !/^(?:vargraphic|varbinary|varchar|character\s+varying|char\s+varying)\b/i.test(type)) return 'SET DATA TYPE';
  return null;
};
