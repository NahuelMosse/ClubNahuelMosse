// One engine per run; each module returns the docker exec prefix, the SQL its lock poller runs and the
// queries that read the schema back.
import { makeDb2 } from './db2.mjs';
import { makeMssql } from './mssql.mjs';
import { makeMysql } from './mysql.mjs';
import { makeOracle } from './oracle.mjs';
import { makePostgres } from './postgres.mjs';

export { mysqlInput } from './mysql.mjs';

export const IMAGES = {
  postgres: 'postgres', mysql: 'mysql', mariadb: 'mariadb',
  mssql: 'mcr.microsoft.com/mssql/server', oracle: 'gvenzl/oracle-free', db2: 'icr.io/db2_community/db2',
};

// opts: { edition } as given to --edition
export const makeEngine = (spec, opts = {}) => {
  if (spec.kind === 'postgres') return makePostgres(spec);
  if (spec.kind === 'mssql') return makeMssql(spec, opts);
  if (spec.kind === 'oracle') return makeOracle(spec, opts);
  if (spec.kind === 'db2') return makeDb2(spec);
  return makeMysql(spec);
};
