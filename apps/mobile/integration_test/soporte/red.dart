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

  /// La API responde como si la sesión ya no fuera válida (401), sin llegar a tocar la
  /// API real: simula una sesión vencida sin depender de que Firebase la venza de verdad.
  sesionVencida,
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
      case EstadoApi.sesionVencida:
        pedido.response.statusCode = HttpStatus.unauthorized;
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

/// El sistema queda sin ninguna reserva (ni los avisos que las mencionan).
Future<void> vaciarReservas() async {
  final r = await http.post(_pruebas('reservas/vaciar'));
  if (r.statusCode != 204) throw StateError('vaciar: ${r.statusCode}');
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

/// El barrido de recordatorios de la API corre como si en el club fueran las [hora]:[minuto]
/// del [dia], sólo para las reservas de la cuenta [correo], y devuelve cuántos avisos
/// registró.
Future<int> despacharRecordatorios({
  required String correo,
  required DateTime dia,
  required int hora,
  int minuto = 0,
}) async {
  String dos(int n) => n.toString().padLeft(2, '0');
  final ahora =
      '${dia.year}-${dos(dia.month)}-${dos(dia.day)}T${dos(hora)}:${dos(minuto)}:00-03:00';
  final r = await http.post(
    _pruebas('recordatorios'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({'correo': correo, 'ahora': ahora}),
  );
  if (r.statusCode != 200) throw StateError('recordatorios: ${r.statusCode}');
  if (jsonDecode(utf8.decode(r.bodyBytes)) case {'registrados': final int n}) {
    return n;
  }
  throw StateError('recordatorios: respuesta sin conteo');
}

/// Si el permiso de cada dispositivo activo de la cuenta [correo] está concedido, según la
/// API y no según la app.
Future<List<bool>> dispositivosDe(String correo) async {
  final r = await http.get(
    _pruebas('dispositivos?correo=${Uri.encodeQueryComponent(correo)}'),
  );
  if (r.statusCode != 200) throw StateError('dispositivos: ${r.statusCode}');
  return [
    if (jsonDecode(utf8.decode(r.bodyBytes)) case {
      'dispositivos': final List<Object?> dispositivos,
    })
      for (final d in dispositivos)
        if (d case {'permiso': final bool permiso}) permiso,
  ];
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

/// Otro administrador da de baja la sede [nombre] mientras la app la sigue mostrando.
Future<void> darDeBajaSedeDesdeOtraSesion(String nombre) async {
  final r = await http.post(
    _pruebas('sedes/baja'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({'nombre': nombre}),
  );
  if (r.statusCode != 204) throw StateError('baja de sede: ${r.statusCode}');
}

/// La sesión de una cuenta de usuario nueva, como la de otra persona que mira la app.
Future<String> _tokenDeOtraPersona() async {
  final correo = 'otra.${DateTime.now().microsecondsSinceEpoch}@correo.com';
  const contrasena = 'ClubNahuel1';
  final alta = await http.post(
    Uri.parse('${Configuracion.desdeEntorno().apiUrl}/registro'),
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
  return token;
}

Future<Object?> _leer(String ruta, String token) async {
  final r = await http.get(
    Uri.parse('${Configuracion.desdeEntorno().apiUrl}$ruta'),
    headers: {'authorization': 'Bearer $token'},
  );
  if (r.statusCode != 200) throw StateError('$ruta: ${r.statusCode}');
  return jsonDecode(utf8.decode(r.bodyBytes));
}

/// La sede activa [nombre] como la ve un usuario (dirección, apertura, cierre, días), o
/// `null` si no la ve.
Future<Map<String, Object?>?> sedeQueVeUnUsuario(String nombre) async {
  final datos = await _leer('/sedes', await _tokenDeOtraPersona());
  if (datos case {'sedes': final List<Object?> sedes}) {
    for (final sede in sedes) {
      if (sede case final Map<String, Object?> s when s['nombre'] == nombre) {
        return s;
      }
    }
  }
  return null;
}

/// Las horas de inicio (`HH:MM`) que un usuario puede elegir el [dia] en [nombreEspacio].
Future<List<String>> iniciosLibres(String nombreEspacio, DateTime dia) async {
  final token = await _tokenDeOtraPersona();
  final espacios = await _leer('/espacios', token);
  final id = switch (espacios) {
    {'espacios': final List<Object?> lista} => [
      for (final e in lista)
        if (e case {'id': final int id, 'nombre': final String n})
          if (n == nombreEspacio) id,
    ].firstOrNull,
    _ => null,
  };
  if (id == null) throw StateError('no está el espacio $nombreEspacio');
  final fecha =
      '${dia.year}-${dia.month.toString().padLeft(2, '0')}-'
      '${dia.day.toString().padLeft(2, '0')}';
  final grilla = await _leer('/espacios/$id/horarios?fecha=$fecha', token);
  return [
    if (grilla case {'franjas': final List<Object?> franjas})
      for (final f in franjas)
        if (f case {'inicio': final String inicio, 'disponible': true}) inicio,
  ];
}

/// Otro administrador da de baja el espacio [nombre] mientras la app lo sigue mostrando.
Future<void> darDeBajaEspacioDesdeOtraSesion(String nombre) async {
  final r = await http.post(
    _pruebas('espacios/baja'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({'espacio': nombre}),
  );
  if (r.statusCode != 204) throw StateError('baja de espacio: ${r.statusCode}');
}

/// El espacio activo [nombre] como lo ve un usuario (precio, condición, iluminación), o
/// `null` si no lo ve.
Future<Map<String, Object?>?> espacioQueVeUnUsuario(String nombre) async {
  final datos = await _leer('/espacios', await _tokenDeOtraPersona());
  if (datos case {'espacios': final List<Object?> espacios}) {
    for (final espacio in espacios) {
      if (espacio case final Map<String, Object?> e
          when e['nombre'] == nombre) {
        return e;
      }
    }
  }
  return null;
}

/// La cuenta [correo] reserva por la API una hora de [nombreEspacio] el [dia] a la [hora]
/// en punto, y devuelve el total que quedó guardado.
Future<int> reservarPorLaApi(
  String correo,
  String nombreEspacio,
  DateTime dia,
  int hora, {
  String contrasena = 'ClubNahuel1',
}) async {
  final token = await _token(correo, contrasena);
  if (token == null) throw StateError('la cuenta $correo no entra');
  final espacios = await _leer('/espacios', token);
  final id = switch (espacios) {
    {'espacios': final List<Object?> lista} => [
      for (final e in lista)
        if (e case {'id': final int id, 'nombre': final String n})
          if (n == nombreEspacio) id,
    ].firstOrNull,
    _ => null,
  };
  if (id == null) throw StateError('no está el espacio $nombreEspacio');
  final r = await http.post(
    Uri.parse('${Configuracion.desdeEntorno().apiUrl}/reservas'),
    headers: {
      'content-type': 'application/json',
      'authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'espacio_id': id,
      'fecha':
          '${dia.year}-${dia.month.toString().padLeft(2, '0')}-'
          '${dia.day.toString().padLeft(2, '0')}',
      'desde': '${hora.toString().padLeft(2, '0')}:00',
      'horas': 1,
    }),
  );
  if (r.statusCode != 201) throw StateError('reservar: ${r.statusCode}');
  return switch (jsonDecode(utf8.decode(r.bodyBytes))) {
    {'total': final int total} => total,
    _ => throw StateError('la reserva no trae el total'),
  };
}

/// Los totales de las próximas reservas de la cuenta [correo], por hora de inicio
/// (`HH:MM`, en la hora del club).
Future<Map<String, int>> totalesDeReservas(
  String correo, {
  String contrasena = 'ClubNahuel1',
}) async {
  final token = await _token(correo, contrasena);
  if (token == null) throw StateError('la cuenta $correo no entra');
  final datos = await _leer('/reservas?cuando=proximas', token);
  return {
    if (datos case {'reservas': final List<Object?> reservas})
      for (final reserva in reservas)
        if (reserva case {
          'inicio': final String inicio,
          'total': final int total,
        })
          DateTime.parse(inicio)
                  .toUtc()
                  .subtract(const Duration(hours: 3))
                  .toIso8601String()
                  .substring(11, 16):
              total,
  };
}

/// La cuenta [correo] cancela por la API todas sus próximas reservas, como si lo hiciera desde
/// otro teléfono mientras el administrador mira la confirmación.
Future<void> cancelarProximasDe(
  String correo, {
  String contrasena = 'ClubNahuel1',
}) async {
  final token = await _token(correo, contrasena);
  if (token == null) throw StateError('la cuenta $correo no entra');
  for (final id in await numerosDeReservas(correo, contrasena: contrasena)) {
    final r = await http.post(
      Uri.parse('${Configuracion.desdeEntorno().apiUrl}/reservas/$id/cancelar'),
      headers: {'authorization': 'Bearer $token'},
    );
    if (r.statusCode != 200) throw StateError('cancelar: ${r.statusCode}');
  }
}

/// La reserva de [nombreEspacio] como la ve el administrador en la API (estado, motivo,
/// quién y cuándo la anuló), o `null` si el espacio no tiene ninguna.
Future<Map<String, Object?>?> reservaQueVeElAdmin(String nombreEspacio) async {
  final datos = await _leer(
    '/reservas/todas?q=${Uri.encodeQueryComponent(nombreEspacio)}',
    await _tokenAdmin(),
  );
  if (datos case {'reservas': final List<Object?> reservas}) {
    for (final reserva in reservas) {
      if (reserva is Map<String, Object?> &&
          reserva['espacio'] == nombreEspacio) {
        return reserva;
      }
    }
  }
  return null;
}

/// Las reservas del historial de la cuenta [correo] según la API: el espacio, el estado y el
/// motivo de cada una.
Future<List<(String, String, String?)>> historialDe(
  String correo, {
  String contrasena = 'ClubNahuel1',
}) async {
  final token = await _token(correo, contrasena);
  if (token == null) throw StateError('la cuenta $correo no entra');
  final datos = await _leer('/reservas?cuando=historial', token);
  return [
    if (datos case {'reservas': final List<Object?> reservas})
      for (final reserva in reservas)
        if (reserva case {
          'espacio': final String espacio,
          'estado': final String estado,
          'motivo': final Object? motivo,
        })
          (espacio, estado, motivo is String ? motivo : null),
  ];
}

/// La cuenta [correo] cancela por la API su única reserva próxima, como si lo hiciera desde
/// otro teléfono.
Future<void> cancelarDesdeOtroTelefono(
  String correo, {
  String contrasena = 'ClubNahuel1',
}) async {
  final token = await _token(correo, contrasena);
  if (token == null) throw StateError('la cuenta $correo no entra');
  final numeros = await numerosDeReservas(correo, contrasena: contrasena);
  if (numeros.length != 1) throw StateError('cancelar: hay ${numeros.length}');
  final r = await http.post(
    Uri.parse(
      '${Configuracion.desdeEntorno().apiUrl}/reservas/${numeros.single}/cancelar',
    ),
    headers: {'authorization': 'Bearer $token'},
  );
  if (r.statusCode != 200) throw StateError('cancelar: ${r.statusCode}');
}

/// Una reserva próxima como la ve quien la hizo: lo que el administrador necesita para anularla.
typedef ReservaAnulable = ({int id, int espacioId, String inicio});

/// Las próximas reservas de la cuenta [correo], según la API, de la más cercana a la más lejana.
Future<List<ReservaAnulable>> proximasDe(
  String correo, {
  String contrasena = 'ClubNahuel1',
}) async {
  final token = await _token(correo, contrasena);
  if (token == null) throw StateError('la cuenta $correo no entra');
  final datos = await _leer('/reservas?cuando=proximas', token);
  return [
    if (datos case {'reservas': final List<Object?> reservas})
      for (final reserva in reservas)
        if (reserva case {
          'id': final int id,
          'espacio_id': final int espacioId,
          'inicio': final String inicio,
        })
          (id: id, espacioId: espacioId, inicio: inicio),
  ];
}

/// El administrador anula [reserva] con [motivo] desde otro teléfono, por la API, y devuelve el
/// estado de la respuesta.
Future<int> anularDesdeElAdmin(
  ReservaAnulable reserva, {
  String motivo = 'mantenimiento de la cancha',
}) async {
  final r = await http.post(
    Uri.parse(
      '${Configuracion.desdeEntorno().apiUrl}/reservas/${reserva.id}/anular',
    ),
    headers: {
      'content-type': 'application/json',
      'authorization': 'Bearer ${await _tokenAdmin()}',
    },
    body: jsonEncode({
      'motivo': motivo,
      'espacio_id': reserva.espacioId,
      'inicio': reserva.inicio,
    }),
  );
  return r.statusCode;
}

/// Espera a que la API registre el envío del aviso de la reserva de [nombreEspacio], que sale
/// después de responder la anulación, y devuelve cómo salió.
Future<String> esperarElEnvioDelAviso(String nombreEspacio) async {
  for (var i = 0; i < 40; i++) {
    final reserva = await reservaQueVeElAdmin(nombreEspacio);
    if (reserva?['aviso_envio'] case final String envio) return envio;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  throw StateError('el aviso de $nombreEspacio no salió a despacho');
}
