// The Spanish detector of the tests of the apps (ENG-22): names of folders and files, declared names, titles and comments.
// The Spanish they keep is the app's Spanish text they check, quoted.
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { wordsOf } from '../.claude/tools/code-language.mjs';

export const repo = resolve(import.meta.dirname, '..');
export const read = (path) => readFileSync(join(repo, path), 'utf8');
export const walk = (dir, accept = () => true) =>
  existsSync(join(repo, dir))
    ? readdirSync(join(repo, dir), { withFileTypes: true }).flatMap((entry) => {
        const path = `${dir}/${entry.name}`;
        if (entry.isDirectory()) return ['node_modules', '.dart_tool', 'build', '__pycache__'].includes(entry.name) ? [] : walk(path, accept);
        return accept(path) ? [path] : [];
      })
    : [];

export const TEST_ROOTS = ['apps/api/tests', 'apps/mobile/test', 'apps/mobile/integration_test'];
export const testSources = (roots = TEST_ROOTS) => roots.flatMap((root) => walk(root, (path) => /\.(py|dart)$/.test(path)));

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

export const ACCENT = /[áéíóúñ]/i;
export const spanishWordsIn = (words) => words.filter((word) => ACCENT.test(word) || SPANISH_WORDS.has(word));

// The names a file declares: classes, functions, methods, fixtures, constants and variables. A Python assignment has spaces around
// its `=` (ruff formats it so), a keyword argument does not: `nombre=` in a call is the callee's name, not the test's.
const DECLARATIONS = [
  // A `def name(` inside a string literal is a test checking that name is absent, not a declaration.
  /(?<!["'])\b(?:class|def|function|const|let|var|final|enum|mixin|extension|typedef)\s+([A-Za-z_À-ÿ][\wÀ-ÿ]*)/g,
  /^[ \t]*([A-Za-z_][\w]*)(?:[ \t]*:[ \t]*[^=\n]+)?[ \t]+=[ \t]/gm,
  /^[ \t]*(?:late\s+)?(?:static\s+)?[A-Z]\w*(?:<[^>\n]*>)?\??\s+([a-z_]\w*)\s*(?:[=;]|\()/gm,
  /^[ \t]*(?:static\s+)?(?:void|bool|int|double|num|dynamic)\s+([a-z_]\w*)\s*[(=;]/gm,
];
export const declaredNames = (text) => [...new Set(DECLARATIONS.flatMap((rx) => [...text.matchAll(rx)].map((m) => m[1])))];

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
  // A letter run inside a commit hash (`1ee70de`) is not a word.
  const words = prose(text).toLowerCase().match(/(?<![0-9])[a-záéíóúñü]+(?![0-9])/g) ?? [];
  const hits = words.filter((word) => SPANISH_FREQUENT.includes(word) || ACCENT.test(word) || SPANISH_WORDS.has(word)).length;
  return hits >= 2 || (hits === 1 && words.length <= 8);
};

export const spanishName = (name) => {
  if (productionNames().has(name)) return false;
  // A commit hash in a name (`main_at_1ee70de`) is not words.
  return spanishWordsIn(wordsOf(name.replace(/_[0-9a-f]*\d[0-9a-f]*(?=_|$)/g, ''))).length > 0 || ACCENT.test(name);
};

// The prose of a test file: comments, docstrings and test titles.
export const proseOf = (path, text) => {
  const out = [];
  const outsideStrings = (code) => (code.match(/["']/g) ?? []).length % 2 === 0;
  for (const line of text.split('\n')) {
    const marker = path.endsWith('.py') ? /^(.*?)(?:^|\s)#(?!!)(.*)$/ : /^(.*?)(?:^|\s)\/\/+(.*)$/;
    const m = line.match(marker);
    if (m && outsideStrings(m[1])) out.push(m[2]);
  }
  if (path.endsWith('.py')) {
    for (const m of text.matchAll(/(^|:[ \t]*\n)[ \t]*[rRuU]?("""|''')([\s\S]*?)\2/g)) out.push(m[3].replace(/\s+/g, ' '));
    // The message closes the line: a string followed by more code is a compared value (`== ["Futbol", "Tenis"]`).
    for (const m of text.matchAll(/\b(?:assert\b[^\n]*?,|pytest\.(?:fail|exit|skip)\()\s*f?(["'])([^"'\n]*)\1\)?[ \t]*$/gm)) out.push(m[2]);
  } else {
    for (const m of text.matchAll(/\b(?:test|testWidgets|group)\(\s*r?(['"])((?:\\.|(?!\1)[^\\\n])*)\1/g)) out.push(m[2]);
    for (const m of text.matchAll(/\/\*([\s\S]*?)\*\//g)) out.push(m[1].replace(/\s+/g, ' '));
  }
  return out;
};

export const offendersInFiles = (paths) =>
  paths.flatMap((path) => {
    const text = read(path);
    // A field named after the JSON key the test sends and compares (`cantidad: Identifier` for `{"cantidad": "1"}`) is data.
    const names = declaredNames(text).filter((name) => spanishName(name) && !text.includes(`"${name}"`) && !text.includes(`'${name}'`)).map((name) => `${path}: name ${name}`);
    const texts = proseOf(path, text).filter(spanishProse).map((chunk) => `${path}: «${chunk.trim().slice(0, 90)}»`);
    return [...names, ...texts];
  });

export const offendersIn = (roots) => offendersInFiles(testSources(roots));

// From the repo root: `node tests/spanish-detector.mjs <test file>...` prints the Spanish of those files, one line each.
if (process.argv[1] && resolve(process.argv[1]) === resolve(import.meta.filename)) {
  const offenders = offendersInFiles(process.argv.slice(2).map((path) => path.replace(/\\/g, '/')));
  for (const line of offenders) console.log(line);
  console.log(`${offenders.length} Spanish`);
  process.exitCode = offenders.length ? 1 : 0;
}

export const report = (offenders) => `${offenders.length} Spanish:\n${offenders.slice(0, 60).join('\n')}`;
