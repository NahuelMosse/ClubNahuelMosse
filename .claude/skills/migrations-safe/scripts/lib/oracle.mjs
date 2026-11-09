// Oracle Database knowledge the rules need. Edition facts: ONLINE index builds and rebuilds, MOVE ONLINE and
// DBMS_REDEFINITION are Enterprise Edition features; Standard Edition 2 does not have them (Oracle Database 23
// Licensing Information, table 1-5 "High Availability": online index rebuild, online table organization and
// online table redefinition are N for SE2 and Y for Free and EE). Oracle Free behaves like EE, so SE2 cannot
// be rehearsed with it.
import { ident } from './parse.mjs';

export const isEE = (edition) => edition === 'ee';
export const ONLINE = /\bonline\b/i;
export const DDL_LOCK_TIMEOUT = /^alter\s+session\s+set\s+ddl_lock_timeout\s*=\s*[1-9]/i;
export const REDEFINITION = /\bdbms_redefinition\b/i;
export const CREATE_INDEX = new RegExp(String.raw`^create\s+(?:unique\s+|bitmap\s+)?index\s+(?:${ident})\s+on\s+(${ident})`, 'i');
export const ALTER_INDEX_REBUILD = /^alter\s+index\s+\S+\s+rebuild\b/i;
const DML = /^(?:insert|update|delete|merge)\b/i;
const DDL = /^(?:create|alter\s+(?!session\b|system\b)|drop|truncate|comment\s+on|grant|revoke|rename|purge|flashback)\b/i;
export const isDml = (t) => DML.test(t);
export const isDdl = (t) => DDL.test(t);
export const COMMITS = /^(?:commit|rollback)\b/i;
