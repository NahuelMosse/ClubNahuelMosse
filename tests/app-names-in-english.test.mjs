// The names of the app's code are English (ENG-23): screen routes, their path and query parameters, the recovery link, and every
// file and name apps/mobile/lib declares. The Spanish the app keeps is the text of app_es.arb.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { wordsOf } from '../.claude/tools/code-language.mjs';
import { read, report, spanishProse, spanishWordsIn, walk } from './spanish-detector.mjs';

// Spanish words the shared list does not have, found in the names of the app.
const MORE_SPANISH = new Set(
  `al atenuado avisar cambiar camino cancelando confirmo consultando continuar declarada desistida destacado eleccion encabezado entro
expandir fin grande hijos historial horas introduccion limpiar marcar momento parametro parte pestana peligro porque recargar rechazo
reintentar releer resumen segmentos subtitulo techada tinta volver ya registro recuperar inicio buscar contrasena exitoso nueva nuevo creada
creado editar acceso denegado modificando`.split(/\s+/),
);
const spanishParts = (name) => wordsOf(name).filter((word) => spanishWordsIn([word]).length > 0 || MORE_SPANISH.has(word));

const stripNonCode = (text) =>
  text
    .replace(/\/\*[\s\S]*?\*\//g, ' ')
    .replace(/\/\/.*$/gm, ' ')
    .replace(/r?'(?:\\.|[^'\\\n])*'|r?"(?:\\.|[^"\\\n])*"/g, "''");

const libFiles = () => walk('apps/mobile/lib', (path) => path.endsWith('.dart') && !path.includes('/l10n/'));

// A word the app shows to the person or the platform's own name, never an identifier of ours.
const identifiersOf = (text) => [...new Set(stripNonCode(text).match(/[A-Za-z_][A-Za-z0-9_]*/g) ?? [])];

test('every screen route, path parameter and query key of the app is English @ENG-23-S1 @assumption:ENG-23-ASM-01', () => {
  const router = read('apps/mobile/lib/router.dart');
  const routes = [...router.matchAll(/path:\s*'([^']*)'/g)].map((m) => m[1]);
  const pathParameters = [...router.matchAll(/pathParameters\['([^']*)'\]/g)].map((m) => m[1]);
  const queryKeys = [...router.matchAll(/queryParameters\['([^']*)'\]/g)].map((m) => m[1]);
  assert.ok(routes.length > 20 && queryKeys.length > 5, 'the router declares the routes and reads the query keys');
  const literals = libFiles().flatMap((path) =>
    [...read(path).matchAll(/'(\/(?:[a-z-]+|\$\{[^}]*\})*[^']*)'/g)].map((m) => `${path}: ${m[1]}`).filter((line) => /context\.(?:go|push)|'\/[a-z]/.test(line)),
  );
  const spanish = [...routes, ...pathParameters, ...queryKeys].flatMap((chunk) => spanishParts(chunk.replace(/[^A-Za-z]+/g, ' ').trim().split(' ').join('_')).map((word) => `${chunk}: ${word}`));
  const literalsInSpanish = literals.filter((line) => spanishParts(line.split(': ')[1].replace(/[^A-Za-z]+/g, '_')).length > 0);
  assert.deepEqual([...spanish, ...literalsInSpanish], [], report([...spanish, ...literalsInSpanish]));
  assert.deepEqual(
    ['register', 'register/success', 'password-recovery', '/recover', '/home', 'search', '/notifications', '/profile', 'password', '/venues', ':venue', 'spaces/:space', 'book', '/bookings', 'confirmed', ':booking/modify', 'confirm', '/admin/access-denied', 'booking/:id', '/admin/venues', 'new', ':venue/edit', 'created', '/admin/spaces', ':space/edit'].filter((route) => !routes.includes(route)),
    [],
  );
  assert.deepEqual(['code', 'sport', 'date', 'hours', 'start', 'booking', 'history', 'from'].filter((key) => !queryKeys.includes(key)), []);
  const redirect = read('apps/mobile/lib/redirect.dart');
  assert.ok(redirect.includes("'/admin/access-denied'") && redirect.includes("'/home'") && redirect.includes("'/bookings'"));
});

test('the recovery link opens the same English route in the app and from the API page @ENG-23-S1 @assumption:ENG-23-ASM-04', () => {
  const router = read('apps/mobile/lib/router.dart');
  assert.ok(router.includes("path: '/recover'") && router.includes("queryParameters['code']"));
  assert.ok(read('apps/mobile/android/app/src/main/AndroidManifest.xml').includes('clubnahuelmosse://app/recover?code='));
  const page = read('apps/api/app/modules/password_recovery/routes.py');
  assert.ok(page.includes('intent://app/recover?code='), 'the API page opens /recover with ?code=');
  assert.ok(!/recuperar|codigo=/.test(page));
});

test('every file and name declared in apps/mobile/lib is English @ENG-23-S3', () => {
  const offenders = libFiles().flatMap((path) => {
    const file = path.split('/').pop().replace('.dart', '');
    const names = identifiersOf(read(path)).filter((name) => spanishParts(name).length > 0);
    return [...(spanishParts(file).length > 0 ? [`${path}: file name`] : []), ...names.map((name) => `${path}: ${name}`)];
  });
  assert.deepEqual(offenders, [], report(offenders));
});

test('the keys and values the app stores on the device are English and no Spanish key is read @assumption:ENG-23-ASM-07', () => {
  const sources = [...libFiles(), ...walk('apps/mobile/integration_test', (path) => path.endsWith('.dart')), ...walk('apps/mobile/test', (path) => path.endsWith('.dart'))];
  const spanish = sources.flatMap((path) => ['modo_oscuro', 'permiso_notificaciones_simulado', 'token_notificaciones_simulado', "'concedido'", "'denegado'", "'simulado'"].filter((key) => read(path).includes(key)).map((key) => `${path}: ${key}`));
  assert.deepEqual(spanish, []);
  assert.ok(read('apps/mobile/lib/common/appearance.dart').includes("'dark_mode'"));
  const notifications = read('apps/mobile/lib/features/notifications/data/simulated_notification_system.dart');
  for (const english of ["'simulated_notification_permission'", "'simulated_notification_token'", "'granted'"]) assert.ok(notifications.includes(english), english);
});

// The text the person sees stays Spanish or English in the .arb; a comment or a message to the developer is English.
const commentsOf = (text) => [...text.matchAll(/(?:^|[^:'"\w])\/\/+[ \t]*([^\n]*)/g)].map((m) => m[1]).concat([...text.matchAll(/\/\*([\s\S]*?)\*\//g)].map((m) => m[1].replace(/\s+/g, ' ')));
const developerMessagesOf = (text) =>
  [...text.matchAll(/\b(?:AssertionError|StateError|ArgumentError|UnsupportedError|UnimplementedError|FormatException|debugPrint|assert)\(\s*(?:[^'"()]*,\s*)?((?:r?(?:'(?:\.|[^'\\n])*'|"(?:\.|[^"\\n])*")\s*)+)/g)].map((m) => m[1]);

test('every comment and developer message of apps/mobile/lib is English @ENG-23-S3', () => {
  const offenders = libFiles().flatMap((path) => {
    const text = read(path);
    return [...commentsOf(text), ...developerMessagesOf(text)].filter(spanishProse).map((chunk) => `${path}: «${chunk.trim().slice(0, 90)}»`);
  });
  assert.deepEqual(offenders, [], report(offenders));
});
