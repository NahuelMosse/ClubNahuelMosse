// The database engine a project uses, read from the files that sit next to its migrations: the migration tool's
// config (Flyway, Liquibase, an SSDT .sqlproj, Spring Boot's application.properties/yml), the build files
// (Maven, Gradle, .NET project, appsettings) and the compose file that starts the database. Nothing here runs or
// connects to anything.
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const read = (p) => { try { return readFileSync(p, 'utf8'); } catch { return ''; } };
const listDir = (dir) => { try { return readdirSync(dir); } catch { return []; } };

const JDBC = { sqlserver: 'mssql', oracle: 'oracle', db2: 'db2', postgresql: 'postgres', mysql: 'mysql', mariadb: 'mysql', sqlite: 'sqlite' };
const DBMS = { mssql: 'mssql', sqlserver: 'mssql', oracle: 'oracle', db2: 'db2', postgresql: 'postgres', postgres: 'postgres', mysql: 'mysql', mariadb: 'mysql', sqlite: 'sqlite' };
const uncommented = (text) => text.split(/\r?\n/).filter((l) => !/^\s*[#;]/.test(l)).join('\n');

// Most specific source first. Tier 1 is what the migration tool itself is configured with (and the data access
// layer that runs the migrations): it is trusted over what the SQL looks like. Tier 2 is what the application
// references, tier 3 what a compose file happens to start; those yield to engine-specific syntax.
const TIER_TOOL = 1;
const TIER_APP = 2;
const TIER_COMPOSE = 3;

const jdbcDialects = (text) => [...uncommented(text).matchAll(/jdbc:(\w+):/gi)].map((m) => JDBC[m[1].toLowerCase()]).filter(Boolean);

const DRIVER_CLASS = [
  ['oracle', /oracle\.jdbc\./i], ['mssql', /com\.microsoft\.sqlserver\./i], ['db2', /com\.ibm\.db2\./i],
  ['postgres', /org\.postgresql\./i], ['mysql', /com\.mysql\.|org\.mariadb\./i],
];

const COMPOSE = ['docker-compose.yml', 'docker-compose.yaml', 'compose.yml', 'compose.yaml', 'docker-compose.override.yml', 'docker-compose.override.yaml'];
const IMAGES = [
  ['mssql', /^(?:mcr\.microsoft\.com\/(?:mssql\/server|azure-sql-edge)|mssql\/server)\b/i],
  ['oracle', /^(?:(?:docker\.io\/)?gvenzl\/oracle-|container-registry\.oracle\.com\/database\/|oracle\/database\b|(?:docker\.io\/)?wnameless\/oracle)/i],
  ['db2', /^(?:icr\.io\/db2_community\/db2|(?:docker\.io\/)?ibmcom\/db2)\b/i],
  ['postgres', /^(?:docker\.io\/)?(?:library\/)?(?:postgres|postgis\/postgis|bitnami\/postgresql|supabase\/postgres|timescale\/timescaledb)\b/i],
  ['mysql', /^(?:docker\.io\/)?(?:library\/)?(?:mysql|mariadb|bitnami\/mysql|bitnami\/mariadb|percona)\b/i],
];
const imageDialect = (ref) => IMAGES.find(([, re]) => re.test(ref))?.[0];

// .NET: the provider of the data access layer that runs the migrations (tier 1) and the plain drivers (tier 2).
const DOTNET_PROVIDER = [
  ['mssql', /Microsoft\.EntityFrameworkCore\.SqlServer|dbup-sqlserver/i],
  ['oracle', /Oracle\.EntityFrameworkCore|dbup-oracle/i],
  ['db2', /IBM\.EntityFrameworkCore/i],
  ['postgres', /Npgsql\.EntityFrameworkCore\.PostgreSQL|dbup-postgresql/i],
  ['mysql', /Pomelo\.EntityFrameworkCore\.MySql|MySql\.EntityFrameworkCore|dbup-mysql/i],
  ['sqlite', /Microsoft\.EntityFrameworkCore\.Sqlite|dbup-sqlite/i],
];
const DOTNET_DRIVER = [
  ['mssql', /Microsoft\.Data\.SqlClient|System\.Data\.SqlClient/i],
  ['oracle', /Oracle\.ManagedDataAccess/i],
  ['db2', /IBM\.Data\.Db2|Net5\.IBM\.Data\.Db2/i],
  ['postgres', /Npgsql/i],
  ['mysql', /MySqlConnector/i],
  ['sqlite', /Microsoft\.Data\.Sqlite/i],
];

// JVM build files: Flyway's own database modules say which engine it migrates (tier 1); a JDBC driver only says
// the application talks to it (tier 2).
const JVM_FLYWAY = [
  ['mssql', 'flyway-sqlserver'], ['oracle', 'flyway-database-oracle|flyway-oracle'], ['db2', 'flyway-database-db2|flyway-db2'],
  ['mysql', 'flyway-mysql'], ['postgres', 'flyway-database-postgresql|flyway-postgresql'],
];
const JVM_DRIVER = [
  ['oracle', 'ojdbc\\d*|ojdbc[\\w.-]*'], ['mssql', 'mssql-jdbc'], ['db2', 'db2jcc\\d*|jcc'],
  ['postgres', 'postgresql'], ['mysql', 'mysql-connector-j|mysql-connector-java|mariadb-java-client'],
];
const artifact = (names) => new RegExp(String.raw`(?<![\w.-])(?:${names})(?![\w-])`, 'i');
// Test-only dependencies (Testcontainers, test scope) say nothing about the engine of the migrations.
const withoutTestDependencies = (file, text) => (file === 'pom.xml'
  ? text.replace(/<dependency>(?:(?!<\/dependency>)[\s\S])*<\/dependency>/gi, (d) => (/<scope>\s*test\s*<\/scope>|testcontainers/i.test(d) ? '' : d))
  : text.split(/\r?\n/).filter((l) => !/^\s*test\w*\s*[(\s'"]|testcontainers/i.test(l)).join('\n'));

// A .NET connection string says which engine through the keys it uses.
// Strings that are not a connection string at all (a RabbitMQ URL, a message) are ignored, and PostgreSQL is only
// read from a string that names a database or its port: `host=rabbit;port=5672;username=guest` is not evidence.
const connectionDialect = (cs) => {
  if (cs.split(';').filter((p) => /^\s*[\w .]+=/.test(p)).length < 2) return null;
  if (/\(\s*DESCRIPTION\s*=|Data Source\s*=[^;]*(?::1521\b|\/\/)|Data Source\s*=\s*[\w.-]+\/\w+\s*(?:;|$)/i.test(cs)) return 'oracle';
  if (/\bDB2\b|Server\s*=[^;]*:50000\b/i.test(cs)) return 'db2';
  if (/\bPort\s*=\s*5432\b/i.test(cs) || (/\bHost\s*=/i.test(cs) && /\bDatabase\s*=/i.test(cs))) return 'postgres';
  if (/\bUid\s*=|\bPort\s*=\s*3306\b/i.test(cs)) return 'mysql';
  if (/Initial Catalog|TrustServerCertificate|Trusted_Connection|Integrated Security|Server\s*=[^;]*;\s*Database\s*=|Data Source\s*=[^;]*(?:\\SQLEXPRESS|\(localdb\)|,1433\b)/i.test(cs)) return 'mssql';
  return null;
};

// Only the values under "ConnectionStrings" are database connections: "Host=rabbit;..." elsewhere is another service.
const connectionStrings = (json) => {
  const out = [];
  for (const block of json.matchAll(/"ConnectionStrings"\s*:\s*\{([^}]*)\}/gi))
    for (const m of block[1].matchAll(/"[^"\n]*"\s*:\s*"((?:[^"\\\n]|\\.)*)"/g)) out.push(m[1]);
  return out;
};

const SPRING_DIRS = ['', join('src', 'main', 'resources'), join('src', 'main', 'resources', 'config'), 'config'];

const hintsIn = (dir) => {
  const hints = [];
  const add = (dialect, tier, from) => { if (dialect) hints.push({ dialect, tier, from }); };
  const names = listDir(dir);

  for (const f of ['flyway.conf', 'flyway.toml', join('conf', 'flyway.conf'), 'liquibase.properties'])
    for (const d of jdbcDialects(read(join(dir, f)))) add(d, TIER_TOOL, f.replace('\\', '/'));
  for (const f of names.filter((n) => /^(?:db\.changelog.*|changelog.*)\.(?:xml|ya?ml|json|sql)$/i.test(n))) {
    const text = read(join(dir, f));
    const m = text.match(/dbms\s*[=:]\s*["']?(\w+)/i) ?? text.match(/^--\s*liquibase formatted sql[\s\S]*?\bdbms:(\w+)/im);
    if (m) add(DBMS[m[1].toLowerCase()], TIER_TOOL, f);
  }
  for (const f of names.filter((n) => /\.sqlproj$/i.test(n))) add('mssql', TIER_TOOL, f);

  // Spring Boot keeps its configuration in the module's resources, away from db/migration
  for (const sub of SPRING_DIRS) {
    const where = join(dir, sub);
    for (const f of listDir(where).filter((n) => /^(?:application|bootstrap)(?:-[\w.-]+)?\.(?:properties|ya?ml)$/i.test(n))) {
      const text = uncommented(read(join(where, f)));
      const from = join(sub, f).replaceAll('\\', '/');
      for (const d of jdbcDialects(text)) add(d, TIER_TOOL, from);
      for (const [d, re] of DRIVER_CLASS) if (re.test(text)) add(d, TIER_TOOL, from);
    }
  }
  for (const f of ['pom.xml', 'build.gradle', 'build.gradle.kts']) {
    const text = withoutTestDependencies(f, read(join(dir, f)));
    if (!text) continue;
    for (const [d, names] of JVM_FLYWAY) if (artifact(names).test(text)) add(d, TIER_TOOL, f);
    for (const [d, names] of JVM_DRIVER) if (artifact(names).test(text)) add(d, TIER_APP, f);
  }

  for (const f of names.filter((n) => /\.(?:cs|fs|vb)proj$/i.test(n))) {
    const text = read(join(dir, f));
    for (const [d, re] of DOTNET_PROVIDER) if (re.test(text)) add(d, TIER_TOOL, f);
    for (const [d, re] of DOTNET_DRIVER) if (re.test(text)) add(d, TIER_APP, f);
  }
  for (const f of names.filter((n) => /^appsettings(?:\.[\w-]+)?\.json$/i.test(n)))
    for (const cs of connectionStrings(read(join(dir, f)))) add(connectionDialect(cs), TIER_APP, f);

  for (const f of COMPOSE)
    for (const m of read(join(dir, f)).matchAll(/^\s*(?:-\s*)?image:\s*["']?([^\s"'#]+)/gim)) add(imageDialect(m[1]), TIER_COMPOSE, f);
  return hints;
};

// The engine declared in `dir`, or null when it holds no hint. { dialect, evidence, conflict, strong } where
// `conflict` lists what disagrees with the choice and `strong` says the choice comes from the migration tool's own
// configuration (so it outranks the syntax of a file). When the most specific sources disagree among themselves
// nothing is chosen (dialect null, `ambiguous` lists them): guessing between two engines is how a PostgreSQL rule
// set ends up applied to SQL Server.
export const hintedDialect = (dir) => {
  const hints = hintsIn(dir);
  if (!hints.length) return null;
  const label = (h) => `${h.dialect} from ${h.from}`;
  const uniq = (list) => [...new Set(list.map(label))];
  const topTier = Math.min(...hints.map((h) => h.tier));
  const top = hints.filter((h) => h.tier === topTier);
  const engines = [...new Set(top.map((h) => h.dialect))];
  const all = hints.map((h) => ({ ...h, dir }));
  if (engines.length > 1) return { dialect: null, evidence: null, ambiguous: uniq(hints), strong: topTier === TIER_TOOL, tier: topTier, hints: all, dir };
  const others = hints.filter((h) => h.dialect !== engines[0]);
  return { dialect: engines[0], evidence: `${top[0].from} in ${dir}`, conflict: others.length ? uniq(others) : null, strong: topTier === TIER_TOOL, tier: topTier, hints: all, dir };
};
