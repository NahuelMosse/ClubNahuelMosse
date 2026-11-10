// The tests of the apps are English: folders, files, titles, declared names and comments (ENG-22). The Spanish they keep is
// the app's Spanish text they check, quoted.
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { replacementsOf } from '../.claude/tools/verify.mjs';
import { wordsOf } from '../.claude/tools/code-language.mjs';

const repo = resolve(import.meta.dirname, '..');
const read = (path) => readFileSync(join(repo, path), 'utf8');
const walk = (dir, accept = () => true) =>
  existsSync(join(repo, dir))
    ? readdirSync(join(repo, dir), { withFileTypes: true }).flatMap((entry) => {
        const path = `${dir}/${entry.name}`;
        if (entry.isDirectory()) return ['node_modules', '.dart_tool', 'build', '__pycache__'].includes(entry.name) ? [] : walk(path, accept);
        return accept(path) ? [path] : [];
      })
    : [];

const TEST_ROOTS = ['apps/api/tests', 'apps/mobile/test', 'apps/mobile/integration_test'];
const testSources = (roots = TEST_ROOTS) => roots.flatMap((root) => walk(root, (path) => /\.(py|dart)$/.test(path)));

// Frequent Spanish words. `en` and `es` are left out: they are the app's locale codes.
const SPANISH_FREQUENT = 'de la el los las que y con para por una del se un al lo como sin'.split(' ');

// The Spanish words the names of the tests had on main, plus the kit's list of Spanish words of software. Words that are also
// English (`real`, `general`, `final`, `total`, `media`, `persona`…) are left out.
const SPANISH_WORDS = new Set([
  ...SPANISH_FREQUENT.filter((word) => word !== 'y'),
  ...`
semantica reserva reservas correo correos sesion sesiones espacio espacios abrir nombre nombres centro pedido pedidos aviso avisos baja
bajas usuario usuarios montar ruta rutas tocar escenarios canal datos dato texto textos cuenta cuentas cancha canchas socio socios alta
altas inicio cada falla fallan manana sistema codigo codigos otra otro otros dos capturas captura capturar rechaza perfil perfiles antes
contrasena credenciales credencial hora horas queda quedan cuerpo cuerpos integracion entrar contrato registro registros completar
anular horario horarios como reservar cancelar ingles hasta tiene tienen desde pantalla pantallas titulo titulos rediseno despues
notificaciones notificacion etiqueta tarjeta tarjetas deja dejan respuesta respuestas dia dias nueva nuevo nuevos errores resultado
resultados recordatorio recordatorios fila filas cancelacion fecha fechas vez servidor motivo recibe modificar uso enlace enlaces tamano
tipo tipos confirmacion editar pedir mensaje ahora envio envios solo llega llegan estado estados hoy pagina campo campos cliente
administrador cambia repositorio boton sus esquema esquemas modelo responde responden partes guarda guardan emulador cancelada seccion
secciones corrida franja franjas ancho catalogo argumentos primera primero primer igual operacion operaciones falso falsa columnas
columna consulta consultas proximas proxima proximo tabla tablas modulo modulos mis fuente fuentes castellano arbol arriba puede basquet
deporte deportes nada publicado publicados propia propio propios propias mismo misma mismas carpeta carpetas archivo archivos invalido
invalidos invalida hay corte glosario ingresar permiso permisos segunda segundo sola nombra recuperacion acepta libre libres rastro
confirmar identidad edicion esperar habilitado elegir elegido elegida arrancar mitad reconstruir reglas regla sigue siguen ningun ninguna
servicio servicios dispositivo dispositivos forma activo activa activas casos caso lista listado espera esperando modo modos importa
cumple entrada entradas campana escribir escribe telefono telefonos cinco detalle detalles migracion migraciones mas documentacion raiz
cierre dada dado funcionalidad funcionalidades guias movimiento pulso paso teclado anulacion anulaciones leer esta este estan estaba
publica publicas quien todas todos toda todo existe existentes conexion fuera creada creado sobre entre registrar crear devuelve foto
fotos clave claves soporte piezas paleta opacidad opacidades aparecer dar vigente vigentes despacho despachar despachados siguiente
prueba pruebas salud diseno registrados registrado registrada aunque compuesto termina terminar configuracion configurar configurado
cambio cambios libera cambiar repetido repetida repetidos repetir repite fallido fallida fallo intentos intento guardar guardado guardada
formato nodo principio desmontar escala hija hijo derecha rol futbol forzosa pasa pasar pendientes pendiente aceptadas bloqueo bloqueos
bloqueado corta recordatorios llamadas llamada llama llaman faltan falta accesibilidad accesible direccion sufijo barrido barrer
repositorios mundo dueno duenio imagen cuatro tres seis entorno reiniciar ajena ajeno minutos precio busqueda cerrar buzon grilla
marcador bloque enviados enviado enviar envia enviando comentarios prohibido problemas completo completa cuantas confirmada banderas
toques fondo reposo retrasos reducir esperado esperados anulada anulado anterior reemplazo reemplazos reemplaza reemplazar supuestos
supuesto lee leidas leida leyendo valido valida rango rangos funcion funciones futura barrera limpia limpio mover numero numeros
disponibles disponible mal verde esquema capas capa grafo diagrama proveedor duracion altura entra resaltada quieta quieto tema temas
contraste hacia reloj tiembla temblor recortador recorta recorte recortes ficha dedo vuelve vuelven vuelta movida agrupado agrupa
conserva indice indices lleva matriz requisitos ayer usa usan icono linea lineas salida limite roto empezo empezada empezar viejo vieja
viejos viejas mueve reciente vacio vaciar orden siembra sembrar entero entera mapa importes sobran memoria filtros filtro filtrar filtra
filtran navegacion posiciones grupos tenis oscuro elemento salir contador contadores pintor comprobante unico trae varios varias manda
mandan mande abre lectura lecturas saliendo largo largos largas cae protegidas correr hace alto enviando auditoria comunes comun apagado
secretos valor dependencias dependencia escrito encuentra encontrados proyecto lugar autenticado autentica alcanza modificada modificado
sobrevive origen menos confiable ausente unitario unitarios legible hecha inexistente borde bordes tope zona medianoche sobreingenieria
formado metodo metodos ultimo ultima muestra identificador arquitectura reintento reintenta saludo pares integraciones habil segmento
carga cargando cargar interfaz estilo abierta concedido autorizacion fundido anfitrion suelto sueltos visibilidad empujar transicion
iniciar ofrece cantidad pero salio simultaneas simultaneos lento resto abajo personales documentos documento rama nivel amenazas movil
atender pasado vive expone rechazadas ejecutarla cancela funcionales manifiesto seguridad exige certificado registra claro contra
distinto distintas donde semana sugerido desconocido insertar reenviar mayusculas puntos ocupado ocupar borra toca cabeceras tras
destino destinos opciones entidades prosa ventana medio firmas documentadas documentada documenta pila demora exentos duplicado
compartidos consultar dialogo jueves marca marcado controlador esqueletos celdas aparecedores cero objeto disparador troquel sirve sabe
trazabilidad mientras cola vistas remite subida trozos omitidas figura categorias dicen lector listan opera costos declaracion tarde
recien lejos interpolacion hallados puerto coincide contexto restricciones pocas muchas estampa cuando corresponde trabarse curso
equivocada destinatario piden dentro comodines anticipacion simultaneos guiones tambien contiene componentes dominio confirman ciclo
clases paquete plantilla palabras definidos supresion cubre aguja punto revalida ajustes informa llegar conciso reales alternativa
obligatorio blanco apertura caracteres parametros vinetas calle desaparezca meses mes reabrir fijar vencer alternar brillo luminancia
deshabilitado importacion cancha ingreso salida usuario repositorio regla pantalla vista datos dominio presentacion sede sedes horario
disponibilidad pago cliente producto configuracion contrasena nombre apellido fecha precio cuenta turno estado obtener actualizar
eliminar borrar guardar buscar listar validar calcular recuperar administradores reporte informe direccion formulario boton tarjeta
permiso acceso movimiento saldo
`.split(/\s+/).filter(Boolean),
]);

const ACCENT = /[áéíóúñ]/i;
const spanishWordsIn = (words) => words.filter((word) => ACCENT.test(word) || SPANISH_WORDS.has(word));

// The names a file declares: classes, functions, methods, fixtures, constants and variables. A Python assignment has spaces around
// its `=` (ruff formats it so), a keyword argument does not: `nombre=` in a call is the callee's name, not the test's.
const DECLARATIONS = [
  /\b(?:class|def|function|const|let|var|final|enum|mixin|extension|typedef)\s+([A-Za-z_À-ÿ][\wÀ-ÿ]*)/g,
  /^[ \t]*([A-Za-z_][\w]*)(?:[ \t]*:[ \t]*[^=\n]+)?[ \t]+=[ \t]/gm,
  /^[ \t]*(?:late\s+)?(?:static\s+)?[A-Z]\w*(?:<[^>\n]*>)?\??\s+([a-z_]\w*)\s*(?:[=;]|\()/gm,
  /^[ \t]*(?:static\s+)?(?:void|bool|int|double|num|dynamic)\s+([a-z_]\w*)\s*[(=;]/gm,
];
const declaredNames = (text) => [...new Set(DECLARATIONS.flatMap((rx) => [...text.matchAll(rx)].map((m) => m[1])))];

// The names production declares: a test that overrides, imports or calls one keeps it as it is (ENG-22-ASM-01).
const productionNames = (() => {
  let names;
  return () => {
    names ??= new Set(
      [...walk('apps/api/app', (p) => p.endsWith('.py')), ...walk('apps/mobile/lib', (p) => p.endsWith('.dart'))].flatMap((path) => {
        const text = read(path);
        const fields = [...text.matchAll(/^[ \t]+([a-z_]\w*)[ \t]*:[ \t]*[\w[]/gm), ...text.matchAll(/[({,][ \t\n]*(?:required\s+)?(?:this\.)?([a-z_]\w*)\s*[:,)]/g)].map((m) => m[1]);
        return [...declaredNames(text), ...fields];
      }),
    );
    return names;
  };
})();

// Prose without what may stay Spanish: «quoted UI text», string literals, inline code, tags, URLs and interpolations.
const prose = (text) =>
  String(text)
    .replace(/«[^»]*»/g, ' ')
    .replace(/"[^"\n]*"/g, ' ')
    .replace(/(^|[^\w])'[^'\n]*'/g, '$1 ')
    .replace(/`[^`\n]*`/g, ' ')
    .replace(/https?:\/\/\S+/g, ' ')
    .replace(/@\S+/g, ' ')
    .replace(/\$\{[^}]*\}|\$\w+/g, ' ');

export const spanishProse = (text) => {
  const words = prose(text).toLowerCase().match(/[a-záéíóúñü]+/g) ?? [];
  const hits = words.filter((word) => SPANISH_FREQUENT.includes(word) || ACCENT.test(word) || SPANISH_WORDS.has(word)).length;
  return hits >= 2 || (hits === 1 && words.length <= 8);
};

export const spanishName = (name) => {
  if (productionNames().has(name)) return false;
  return spanishWordsIn(wordsOf(name)).length > 0 || ACCENT.test(name);
};

// The prose of a test file: comments, docstrings and test titles.
const proseOf = (path, text) => {
  const out = [];
  const outsideStrings = (code) => (code.match(/["']/g) ?? []).length % 2 === 0;
  for (const line of text.split('\n')) {
    const marker = path.endsWith('.py') ? /^(.*?)(?:^|\s)#(?!!)(.*)$/ : /^(.*?)(?:^|\s)\/\/+(.*)$/;
    const m = line.match(marker);
    if (m && outsideStrings(m[1])) out.push(m[2]);
  }
  if (path.endsWith('.py')) {
    for (const m of text.matchAll(/(^|:[ \t]*\n)[ \t]*[rRuU]?("""|''')([\s\S]*?)\2/g)) out.push(m[3].replace(/\s+/g, ' '));
    for (const m of text.matchAll(/\b(?:assert\b[^\n]*?,|pytest\.(?:fail|exit|skip)\()\s*f?(["'])([^"'\n]*)\1/g)) out.push(m[2]);
  } else {
    for (const m of text.matchAll(/\b(?:test|testWidgets|group)\(\s*r?(['"])((?:\\.|(?!\1)[^\\\n])*)\1/g)) out.push(m[2]);
    for (const m of text.matchAll(/\/\*([\s\S]*?)\*\//g)) out.push(m[1].replace(/\s+/g, ' '));
  }
  return out;
};

const offendersIn = (roots) =>
  testSources(roots).flatMap((path) => {
    const text = read(path);
    const names = declaredNames(text).filter(spanishName).map((name) => `${path}: name ${name}`);
    const texts = proseOf(path, text).filter(spanishProse).map((chunk) => `${path}: «${chunk.trim().slice(0, 90)}»`);
    return [...names, ...texts];
  });

const report = (offenders) => `${offenders.length} Spanish:\n${offenders.slice(0, 60).join('\n')}`;

test('every test folder and file of the apps has an English name @ENG-22-S1 @assumption:ENG-22-ASM-05', () => {
  const offenders = TEST_ROOTS.flatMap((root) => walk(root))
    .flatMap((path) => path.split('/').slice(root(path).split('/').length))
    .filter((segment, i, all) => all.indexOf(segment) === i)
    .filter((segment) => spanishWordsIn(wordsOf(segment.replace(/\.(dart|py|png|yaml)$/, ''))).length > 0 || ACCENT.test(segment));
  assert.deepEqual(offenders, [], report(offenders));
  const folders = {
    'apps/api/tests/scenarios': 'apps/api/tests/escenarios',
    'apps/api/tests/integration': 'apps/api/tests/integracion',
    'apps/mobile/test/screenshots': 'apps/mobile/test/capturas',
    'apps/mobile/test/redesign': 'apps/mobile/test/rediseno',
    'apps/mobile/test/support': 'apps/mobile/test/soporte',
    'apps/mobile/integration_test/support': 'apps/mobile/integration_test/soporte',
    'apps/mobile/integration_test/bookings': 'apps/mobile/integration_test/reservas',
    'apps/mobile/integration_test/venues': 'apps/mobile/integration_test/sedes',
    'apps/mobile/integration_test/spaces': 'apps/mobile/integration_test/espacios',
    'apps/mobile/integration_test/session': 'apps/mobile/integration_test/sesion',
    'apps/mobile/integration_test/users': 'apps/mobile/integration_test/usuarios',
    'apps/mobile/integration_test/notifications': 'apps/mobile/integration_test/notificaciones',
    'apps/mobile/integration_test/registration': 'apps/mobile/integration_test/registro',
    'apps/mobile/integration_test/errors': 'apps/mobile/integration_test/errores',
    'apps/mobile/integration_test/home': 'apps/mobile/integration_test/inicio',
  };
  for (const [now, before] of Object.entries(folders)) {
    assert.ok(existsSync(join(repo, now)), `${now} exists`);
    assert.ok(!existsSync(join(repo, before)), `${before} is gone`);
  }
  assert.deepEqual(walk('apps/mobile/test/screenshots', (p) => /_capturas\.dart$/.test(p)), []);
});
const root = (path) => TEST_ROOTS.find((r) => path.startsWith(`${r}/`)) ?? '';

test('every title, declared name and comment of the API tests is English @ENG-22-S3 @assumption:ENG-22-ASM-04', () => {
  const offenders = offendersIn(['apps/api/tests']);
  assert.deepEqual(offenders, [], report(offenders));
});

test('every title, declared name and comment of the app tests is English @ENG-22-S3 @assumption:ENG-22-ASM-04', () => {
  const offenders = offendersIn(['apps/mobile/test', 'apps/mobile/integration_test']);
  assert.deepEqual(offenders, [], report(offenders));
});

test('no test carries the Spanish tag supuesto @ENG-22-S1', () => {
  const offenders = testSources().filter((path) => read(path).includes('@supuesto:'));
  assert.deepEqual(offenders, []);
});

test('the Spanish detector flags Spanish names and prose and passes English that quotes Spanish UI text @ENG-22-S2 @assumption:ENG-22-ASM-03', () => {
  for (const name of ['test_un_usuario_reserva_una_cancha', 'crearReserva', 'montarPantalla', 'sedeHaedoJson', 'año']) {
    assert.ok(spanishName(name), name);
  }
  for (const name of ['test_a_user_books_a_court', 'createBooking', 'mountScreen', 'haedoVenueJson', 'enLocale', 'dni']) {
    assert.ok(!spanishName(name), name);
  }
  for (const text of ['un usuario reserva una cancha', 'Verifica: la sede guarda nombre', 'si falla, revisar la grilla', 'está bien']) {
    assert.ok(spanishProse(text), text);
  }
  for (const text of [
    'the login screen shows «Ingresá tu correo» under the field @ENG-19-S2',
    "the venue 'Sede Haedo' keeps its address",
    'the es locale and the en locale',
    'shows `reservas` in the URL https://example.com/de/la/que',
    'a booking past its slot stays in the user history',
  ]) {
    assert.ok(!spanishProse(text), text);
  }
});

// A path to a test that a doc, a kit rule, a config or a script cites. The method's records in specs/ cite the old ones (ENG-22-ASM-02),
// and the glossary maps old names to new ones on purpose.
const CITING = () => [
  ...walk('docs', (p) => p.endsWith('.md') && !p.endsWith('glossary.md')),
  'README.md',
  'apps/api/README.md',
  'apps/mobile/README.md',
  '.claude/STACK.md',
  '.claude/rules/interfaz.md',
  'apps/api/pyproject.toml',
  'apps/mobile/analysis_options.yaml',
  ...walk('scripts', (p) => /\.(sh|mjs)$/.test(p)),
  ...walk('.github/workflows'),
];
const CITED = /(?<![\w./@-])(?:apps\/(?:api|mobile)\/)?(?:tests|test|integration_test)\/[A-Za-z0-9_./*{}-]*[A-Za-z0-9_*}]/g;
const existsFromSomeRoot = (cited) => {
  const plain = cited.replace(/[*{].*$/, '').replace(/\/[^/]*$/, (last) => (cited.includes('*') || cited.includes('{') ? '' : last));
  return ['', 'apps/api/', 'apps/mobile/'].some((base) => existsSync(join(repo, base + plain)));
};

test('every repo path to a test that a doc, a kit rule, a config or a script cites exists @ENG-22-S4 @assumption:ENG-22-ASM-01 @assumption:ENG-22-ASM-02', () => {
  const offenders = CITING()
    .filter((path) => existsSync(join(repo, path)) && statSync(join(repo, path)).isFile())
    .flatMap((path) => [...new Set(read(path).match(CITED) ?? [])].filter((cited) => !existsFromSomeRoot(cited)).map((cited) => `${path}: ${cited}`));
  assert.deepEqual(offenders, []);
});

test('every replacement this card declares names an existing test and a replacement that carries its tags @assumption:ENG-22-ASM-06', () => {
  const replacements = replacementsOf(read('specs/ENG-22-tests-en-ingles/card.md'));
  assert.ok(replacements.length > 0, 'the card declares the replacements of the moved tests that still fail');
  const flat = (s) => String(s).replace(/\s+/g, ' ');
  const offenders = replacements.filter((r) => {
    if (!existsSync(join(repo, r.file)) || !existsSync(join(repo, r.by))) return true;
    const by = flat(read(r.by));
    const tags = r.name.match(/@(?:assumption:)?[A-Z][A-Z0-9]*-\d+-(?:S\d+|ASM-\d+|SUP-\d+|H\d+(?:-\d+)?)(?![\w-])/g) ?? [];
    return !by.includes(flat(r.byName)) || !tags.every((tag) => by.includes(tag));
  });
  assert.deepEqual(offenders.map((r) => `${r.file} "${r.name}" → ${r.by} "${r.byName}"`), []);
});

test('every screenshot a screenshots file names exists under an English name @assumption:ENG-22-ASM-07', () => {
  const pngs = walk('apps/mobile/test/screenshots', (p) => p.endsWith('.png'));
  assert.ok(pngs.length > 0, 'the screenshots live in apps/mobile/test/screenshots');
  const missing = walk('apps/mobile/test/screenshots', (p) => p.endsWith('.dart')).flatMap((path) =>
    [...read(path).matchAll(/(['"])([^'"\n]*\.png)\1/g)]
      .map((m) => m[2])
      .filter((cited) => {
        const rx = new RegExp(`${cited.replace(/\$\{[^}]*\}|\$\w+/g, '\u0000').replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/\u0000/g, '[^/]+')}$`);
        return !pngs.some((png) => rx.test(png));
      })
      .map((cited) => `${path}: ${cited}`),
  );
  assert.deepEqual(missing, []);
});
