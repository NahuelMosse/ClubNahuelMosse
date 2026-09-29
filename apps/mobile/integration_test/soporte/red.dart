import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/configuracion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

enum EstadoApi {
  normal,
  sinRed,
  falla,

  /// Reenvía igual que [normal], pero tres segundos más tarde: deja ver lo que la app
  /// muestra mientras espera.
  lenta,
}

/// Una API intermedia en el mismo dispositivo que la app: reenvía a la API de la corrida
/// hasta que el escenario la corta o la hace fallar. Sirve para simular que la red o el
/// servidor se caen después de iniciar sesión.
class ApiIntermedia {
  ApiIntermedia._(this._servidor, this._destino) {
    _servidor.listen(_atender);
  }

  static Future<ApiIntermedia> abrir() async {
    final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final api = ApiIntermedia._(
      servidor,
      Uri.parse(Configuracion.desdeEntorno().apiUrl),
    );
    addTearDown(() => servidor.close(force: true));
    return api;
  }

  final HttpServer _servidor;
  final Uri _destino;
  // Una conexión que queda quieta se suelta antes de que la API la cierre por su cuenta
  // (su keep-alive es de cinco segundos): así no se reusa una que ya está cerrada.
  final _cliente = HttpClient()..idleTimeout = const Duration(seconds: 1);
  EstadoApi estado = EstadoApi.normal;

  String get url => 'http://127.0.0.1:${_servidor.port}';

  /// Un reenvío que se corta a mitad de camino (la API cierra la conexión) llega a la app
  /// como una red que se cayó, y no como un error del escenario que esté corriendo.
  Future<void> _atender(HttpRequest pedido) async {
    try {
      await _reenviar(pedido);
    } on Object {
      try {
        (await pedido.response.detachSocket(writeHeaders: false)).destroy();
      } on Object {
        // La respuesta ya había empezado a salir: la conexión se cierra con ella.
      }
    }
  }

  Future<void> _reenviar(HttpRequest pedido) async {
    switch (estado) {
      case EstadoApi.sinRed:
        // La conexión se corta sin respuesta, como cuando se va la señal.
        final socket = await pedido.response.detachSocket(writeHeaders: false);
        socket.destroy();
      case EstadoApi.falla:
        pedido.response.statusCode = HttpStatus.internalServerError;
        await pedido.response.close();
      case EstadoApi.normal:
      case EstadoApi.lenta:
        if (estado == EstadoApi.lenta) {
          await Future<void>.delayed(const Duration(seconds: 3));
        }
        final cuerpo = await pedido.fold<List<int>>(
          [],
          (bytes, parte) => bytes..addAll(parte),
        );
        final (codigo, encabezados, respuesta) = await _pedirALaApi(
          pedido,
          cuerpo,
        );
        pedido.response.statusCode = codigo;
        encabezados.forEach((nombre, valores) {
          // El largo y la conexión son de este tramo, no del de la API.
          if (nombre != HttpHeaders.transferEncodingHeader &&
              nombre != HttpHeaders.connectionHeader &&
              nombre != HttpHeaders.contentLengthHeader) {
            for (final valor in valores) {
              pedido.response.headers.add(nombre, valor);
            }
          }
        });
        pedido.response.contentLength = respuesta.length;
        pedido.response.add(respuesta);
        await pedido.response.close();
    }
  }

  /// Reenvía el pedido entero a la API y trae la respuesta entera. Si la conexión llega
  /// cerrada, lo intenta una vez más con otra.
  Future<(int, HttpHeaders, List<int>)> _pedirALaApi(
    HttpRequest pedido,
    List<int> cuerpo,
  ) async {
    for (var intento = 1; ; intento++) {
      try {
        final reenvio = await _cliente.openUrl(
          pedido.method,
          _destino.replace(
            path: pedido.uri.path,
            query: pedido.uri.hasQuery ? pedido.uri.query : null,
          ),
        );
        pedido.headers.forEach((nombre, valores) {
          if (nombre != HttpHeaders.hostHeader &&
              nombre != HttpHeaders.connectionHeader &&
              nombre != HttpHeaders.contentLengthHeader) {
            for (final valor in valores) {
              reenvio.headers.add(nombre, valor);
            }
          }
        });
        reenvio.contentLength = cuerpo.length;
        reenvio.add(cuerpo);
        final respuesta = await reenvio.close();
        final bytes = await respuesta.fold<List<int>>(
          [],
          (todo, parte) => todo..addAll(parte),
        );
        return (respuesta.statusCode, respuesta.headers, bytes);
      } on HttpException {
        if (intento == 2) rethrow;
      }
    }
  }
}

Uri _identidad(String metodo) {
  const emulador = String.fromEnvironment('AUTH_EMULADOR');
  return Uri.parse(
    'http://$emulador/identitytoolkit.googleapis.com/v1/accounts:$metodo'
    '?key=clave-del-emulador',
  );
}

Future<String?> _token(String correo, String contrasena) async {
  final r = await http.post(
    _identidad('signInWithPassword'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'email': correo,
      'password': contrasena,
      'returnSecureToken': true,
    }),
  );
  if (r.statusCode != 200) return null;
  if (jsonDecode(r.body) case {'idToken': final String token}) return token;
  return null;
}

/// Si esa contraseña sirve hoy para entrar, preguntado a Firebase y no a la app.
Future<bool> puedeEntrar(String correo, String contrasena) async =>
    await _token(correo, contrasena) != null;

/// Cambia la contraseña desde otro dispositivo: Firebase invalida las sesiones abiertas.
Future<void> cambiarDesdeOtroDispositivo(
  String correo,
  String actual,
  String nueva,
) async {
  // Firebase cuenta la revocación por segundos: el token de la app tiene que ser de un
  // segundo anterior al cambio para que quede vencido.
  await Future<void>.delayed(const Duration(milliseconds: 1100));
  final token = await _token(correo, actual);
  if (token == null) throw StateError('la contraseña actual no sirve');
  final r = await http.post(
    _identidad('update'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'idToken': token,
      'password': nueva,
      'returnSecureToken': true,
    }),
  );
  if (r.statusCode != 200) {
    throw StateError('no se pudo cambiar la contraseña: ${r.statusCode}');
  }
}

/// Las sedes que ve hoy una persona con cuenta de usuario, preguntado a la API de la
/// corrida y no a la app: nombre y cantidad de canchas de cada una.
Future<Map<String, int>> sedesQueVeUnUsuario() async {
  final correo = 'mirada.${DateTime.now().microsecondsSinceEpoch}@correo.com';
  const contrasena = 'ClubNahuel1';
  final api = Configuracion.desdeEntorno().apiUrl;
  final alta = await http.post(
    Uri.parse('$api/registro'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'nombre': 'Mirada',
      'apellido': 'Externa',
      'dni': (10000000 + DateTime.now().microsecondsSinceEpoch % 89999999)
          .toString(),
      'fecha_nacimiento': '1995-05-20',
      'correo': correo,
      'contrasena': contrasena,
    }),
  );
  if (alta.statusCode != 201) throw StateError('registro: ${alta.statusCode}');
  final token = await _token(correo, contrasena);
  if (token == null) throw StateError('la cuenta nueva no entra');
  final r = await http.get(
    Uri.parse('$api/sedes'),
    headers: {'authorization': 'Bearer $token'},
  );
  if (r.statusCode != 200) throw StateError('sedes: ${r.statusCode}');
  return {
    if (jsonDecode(utf8.decode(r.bodyBytes)) case {
      'sedes': final List<Object?> sedes,
    })
      for (final sede in sedes)
        if (sede case {'nombre': final String nombre, 'canchas': final int n})
          nombre: n,
  };
}

/// Los nombres de los espacios activos que ve hoy una persona con cuenta de usuario.
Future<List<String>> espaciosQueVeUnUsuario() async {
  final correo = 'mira.${DateTime.now().microsecondsSinceEpoch}@correo.com';
  const contrasena = 'ClubNahuel1';
  final api = Configuracion.desdeEntorno().apiUrl;
  final alta = await http.post(
    Uri.parse('$api/registro'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'nombre': 'Mirada',
      'apellido': 'Externa',
      'dni': (10000000 + DateTime.now().microsecondsSinceEpoch % 89999999)
          .toString(),
      'fecha_nacimiento': '1995-05-20',
      'correo': correo,
      'contrasena': contrasena,
    }),
  );
  if (alta.statusCode != 201) throw StateError('registro: ${alta.statusCode}');
  final token = await _token(correo, contrasena);
  if (token == null) throw StateError('la cuenta nueva no entra');
  final r = await http.get(
    Uri.parse('$api/espacios'),
    headers: {'authorization': 'Bearer $token'},
  );
  if (r.statusCode != 200) throw StateError('espacios: ${r.statusCode}');
  return [
    if (jsonDecode(utf8.decode(r.bodyBytes)) case {
      'espacios': final List<Object?> espacios,
    })
      for (final espacio in espacios)
        if (espacio case {'nombre': final String nombre}) nombre,
  ];
}

/// La sesión del administrador que siembra `scripts/e2e.sh`, como la de otro teléfono.
Future<String> _tokenAdmin() async {
  final token = await _token(
    const String.fromEnvironment('ADMIN_CORREO'),
    const String.fromEnvironment('ADMIN_CONTRASENA'),
  );
  if (token == null) throw StateError('el administrador no entra');
  return token;
}

/// Un alta en la API de la corrida hecha por el administrador desde otro teléfono.
Future<Map<String, Object?>> _comoAdmin(
  String ruta,
  Map<String, Object?> cuerpo,
) async {
  final token = await _tokenAdmin();
  final r = await http.post(
    Uri.parse('${Configuracion.desdeEntorno().apiUrl}$ruta'),
    headers: {
      'content-type': 'application/json',
      'authorization': 'Bearer $token',
    },
    body: jsonEncode(cuerpo),
  );
  if (r.statusCode != 201) throw StateError('$ruta: ${r.statusCode}');
  final datos = jsonDecode(utf8.decode(r.bodyBytes));
  if (datos is! Map<String, Object?>) throw StateError('$ruta: respuesta rara');
  return datos;
}

/// Da de alta una sede por la API, abierta de 08:00 a 23:00 los [dias] de la semana (1 es
/// lunes): por defecto, todos.
Future<void> crearSede(
  String nombre,
  String direccion, {
  List<int> dias = const [1, 2, 3, 4, 5, 6, 7],
}) async {
  await _comoAdmin('/sedes', {
    'nombre': nombre,
    'direccion': direccion,
    'apertura': '08:00',
    'cierre': '23:00',
    'dias': dias,
  });
}

/// El día de hoy en el club, que está en la hora de Argentina (UTC−3, sin horario de
/// verano), sea cual sea la zona del teléfono de prueba.
DateTime hoyEnElClub() {
  final ahora = DateTime.now().toUtc().subtract(const Duration(hours: 3));
  return DateTime.utc(ahora.year, ahora.month, ahora.day);
}

/// La hora en punto que está corriendo ahora en el club.
int horaEnElClub() =>
    DateTime.now().toUtc().subtract(const Duration(hours: 3)).hour;

/// Una reserva del espacio [nombreEspacio] el [dia] a la [hora] en punto, por [horas]
/// horas, cargada por fuera de la app: de la cuenta [correo] o, si no viene, de otra
/// persona. [estado] es `activa`, `cancelada` o `anulada` (con [motivo]).
Future<void> ocupar(
  String nombreEspacio,
  DateTime dia,
  int hora, {
  int horas = 1,
  String? correo,
  String estado = 'activa',
  String? motivo,
}) async {
  final fecha =
      '${dia.year}-${dia.month.toString().padLeft(2, '0')}-'
      '${dia.day.toString().padLeft(2, '0')}';
  final r = await http.post(
    _pruebas('reservas'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'espacio': nombreEspacio,
      'fecha': fecha,
      'hora': hora,
      'horas': horas,
      'correo': ?correo,
      'estado': estado,
      'motivo': ?motivo,
    }),
  );
  if (r.statusCode != 204) throw StateError('ocupar: ${r.statusCode}');
}

/// Da de alta por la API el próximo espacio de [deporte] y [tipo] en la sede [nombreSede],
/// y devuelve su nombre compuesto.
Future<String> crearEspacio(
  String nombreSede, {
  String deporte = 'Futbol',
  String tipo = 'F5',
}) async {
  final api = Configuracion.desdeEntorno().apiUrl;
  final r = await http.get(
    Uri.parse('$api/sedes'),
    headers: {'authorization': 'Bearer ${await _tokenAdmin()}'},
  );
  final sedes = jsonDecode(utf8.decode(r.bodyBytes));
  final id = switch (sedes) {
    {'sedes': final List<Object?> lista} => [
      for (final s in lista)
        if (s case {'id': final int id, 'nombre': final String n})
          if (n == nombreSede) id,
    ].firstOrNull,
    _ => null,
  };
  if (id == null) throw StateError('no está la sede $nombreSede');
  final espacio = await _comoAdmin('/espacios', {
    'sede_id': id,
    'deporte': deporte,
    'tipo': tipo,
    // Otra cancha que la que carga el escenario en la pantalla: con los mismos datos y la
    // misma cuenta, la API la tomaría por el mismo pedido repetido después de un corte.
    'techada': true,
    'iluminada': true,
    'precio_por_hora': 43000,
  });
  final nombre = espacio['nombre'];
  if (nombre is! String) throw StateError('el alta no devolvió el nombre');
  return nombre;
}

Uri _pruebas(String ruta) =>
    Uri.parse('${Configuracion.desdeEntorno().apiUrl}/_pruebas/$ruta');

/// Los correos que la API de la corrida dejó en su buzón para [para], del más viejo al
/// más nuevo. En la corrida los correos no salen: quedan en el buzón.
Future<List<String>> correosPara(String para) async {
  final r = await http.get(
    _pruebas('correos?para=${Uri.encodeQueryComponent(para)}'),
  );
  if (r.statusCode != 200) throw StateError('buzón: ${r.statusCode}');
  final datos = jsonDecode(utf8.decode(r.bodyBytes));
  return [
    if (datos case {'correos': final List<Object?> correos})
      for (final correo in correos)
        if (correo case {'cuerpo': final String cuerpo}) cuerpo,
  ];
}

/// El código del enlace de recuperación del último correo que recibió [correo].
Future<String> ultimoCodigo(String correo) async {
  final correos = await correosPara(correo);
  if (correos.isEmpty) throw StateError('no llegó ningún correo a $correo');
  final enlace = RegExp(r'codigo=([A-Za-z0-9_-]+)').firstMatch(correos.last);
  final codigo = enlace?.group(1);
  if (codigo == null) throw StateError('el correo no trae un enlace');
  return codigo;
}

/// Hace vencer el enlace ya, sin esperar los 30 minutos.
Future<void> vencerEnlace(String codigo) async {
  final r = await http.post(_pruebas('recuperacion/$codigo/vencer'));
  if (r.statusCode != 204) throw StateError('vencer: ${r.statusCode}');
}

/// Las próximas reservas de la cuenta [correo], preguntadas a la API y no a la app: el
/// espacio y la hora de inicio (`HH:MM`, en la hora del club) de cada una.
Future<List<(String, String)>> reservasDe(
  String correo, {
  String contrasena = 'ClubNahuel1',
}) async {
  final token = await _token(correo, contrasena);
  if (token == null) throw StateError('la cuenta $correo no entra');
  final r = await http.get(
    Uri.parse(
      '${Configuracion.desdeEntorno().apiUrl}/reservas?cuando=proximas',
    ),
    headers: {'authorization': 'Bearer $token'},
  );
  if (r.statusCode != 200) throw StateError('reservas: ${r.statusCode}');
  return [
    if (jsonDecode(utf8.decode(r.bodyBytes)) case {
      'reservas': final List<Object?> reservas,
    })
      for (final reserva in reservas)
        if (reserva case {
          'espacio': final String espacio,
          'inicio': final String inicio,
        })
          (
            espacio,
            DateTime.parse(inicio)
                .toUtc()
                .subtract(const Duration(hours: 3))
                .toIso8601String()
                .substring(11, 16),
          ),
  ];
}

/// Las reservas activas de [nombreEspacio] pasan a haber empezado en la hora en curso del
/// club, como si el tiempo corriera mientras la app está abierta.
Future<void> empezarReservasDe(String nombreEspacio) async {
  final r = await http.post(
    _pruebas('reservas/empezar'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({'espacio': nombreEspacio}),
  );
  if (r.statusCode != 204) throw StateError('empezar: ${r.statusCode}');
}

/// El club anula las reservas activas de [nombreEspacio], como lo haría un administrador.
Future<void> anularReservasDe(String nombreEspacio) async {
  final r = await http.post(
    _pruebas('reservas/anular'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({'espacio': nombreEspacio}),
  );
  if (r.statusCode != 204) throw StateError('anular: ${r.statusCode}');
}

/// Los números de las próximas reservas de la cuenta [correo], según la API.
Future<List<int>> numerosDeReservas(
  String correo, {
  String contrasena = 'ClubNahuel1',
}) async {
  final token = await _token(correo, contrasena);
  if (token == null) throw StateError('la cuenta $correo no entra');
  final r = await http.get(
    Uri.parse(
      '${Configuracion.desdeEntorno().apiUrl}/reservas?cuando=proximas',
    ),
    headers: {'authorization': 'Bearer $token'},
  );
  if (r.statusCode != 200) throw StateError('reservas: ${r.statusCode}');
  return [
    if (jsonDecode(utf8.decode(r.bodyBytes)) case {
      'reservas': final List<Object?> reservas,
    })
      for (final reserva in reservas)
        if (reserva case {'id': final int id}) id,
  ];
}
