import 'dart:convert';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/espacios/espacios.dart';
import 'package:clubnahuelmosse/inicio/pantalla_inicio.dart';
import 'package:clubnahuelmosse/reservas/reservas.dart';
import 'package:clubnahuelmosse/sedes/sedes.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Un cliente de la API que responde siempre [codigo] con [cuerpo], sin red.
ClienteApi apiFalsa({int codigo = 201, String cuerpo = '{"id": 1}'}) =>
    ClienteApi(
      'http://api.falsa',
      cliente: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(cuerpo),
          codigo,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

/// Un cliente de la API que responde según `MÉTODO /ruta`; lo que no está es un 404.
/// Guarda cada pedido en [pedidos] para afirmar qué se mandó.
ClienteApi apiRutas(
  Map<String, (int, String)> respuestas, {
  List<http.Request>? pedidos,
}) => ClienteApi(
  'http://api.falsa',
  cliente: MockClient((pedido) async {
    pedidos?.add(pedido);
    final (codigo, cuerpo) =
        respuestas['${pedido.method} ${pedido.url.path}'] ?? (404, '{}');
    return http.Response.bytes(
      utf8.encode(cuerpo),
      codigo,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }),
);

const _catalogoJson =
    '{"deportes": ['
    '{"clave": "Futbol", "nombre": "Fútbol", "tipos": ['
    '{"clave": "F5", "nombre": "Fútbol 5"}, {"clave": "F7", "nombre": "Fútbol 7"}]}, '
    '{"clave": "Tenis", "nombre": "Tenis", "tipos": ['
    '{"clave": "PDL", "nombre": "Polvo de ladrillo"}]}, '
    '{"clave": "Padel", "nombre": "Pádel", "tipos": [{"clave": "PAD", "nombre": "Pádel"}]}, '
    '{"clave": "Voley", "nombre": "Vóley", "tipos": [{"clave": "IND", "nombre": "Indoor"}]}, '
    '{"clave": "Hockey", "nombre": "Hockey", "tipos": [{"clave": "H7", "nombre": "Hockey 7"}]}, '
    '{"clave": "Golf", "nombre": "Golf", "tipos": [{"clave": "DR", "nombre": "Driving range"}]}'
    ']}';

String _sedeJson(int id, String nombre, String direccion, int canchas) =>
    '{"id": $id, "nombre": "$nombre", "direccion": "$direccion", '
    '"apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7], '
    '"canchas": $canchas, "deportes": ["Futbol", "Tenis"]}';

const _proximaJson =
    '{"id": 1, "espacio_id": 3, "sede_id": 2, '
    '"espacio": "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", '
    '"tipo": "F5", "sede": "Sede Morón", "direccion": "Av. Rivadavia 19850", '
    '"inicio": "2026-11-13T00:00:00Z", "fin": "2026-11-13T01:00:00Z", '
    '"total": 38000, "estado": "activa", "motivo": null, "cancelable": true}';

/// Una API con lo que lee el Home: 4 sedes con 17 canchas, el catálogo de deportes y, con
/// [conReserva], una próxima reserva.
ClienteApi apiInicio({bool conReserva = true}) => apiRutas({
  'GET /reservas': (200, '{"reservas": [${conReserva ? _proximaJson : ''}]}'),
  'GET /espacios/catalogo': (200, _catalogoJson),
  'GET /sedes': (
    200,
    '{"sedes": [${_sedeJson(1, 'Sede Haedo', 'Av. Vergara 1850', 6)}, '
        '${_sedeJson(2, 'Sede Morón', 'Av. Rivadavia 19850', 4)}, '
        '${_sedeJson(3, 'Sede Castelar', 'Av. Santa Rosa 1200', 4)}, '
        '${_sedeJson(4, 'Sede Ituzaingó', 'Blas Parera 300', 3)}]}',
  ),
});

/// El Home leyendo de [apiInicio].
Widget inicioFalso(Sesion sesion, {bool conReserva = true}) {
  final api = apiInicio(conReserva: conReserva);
  return PantallaInicio(
    sesion: sesion,
    reservas: Reservas(api: api, sesion: sesion),
    espacios: Espacios(api: api, sesion: sesion),
    sedes: Sedes(api: api, sesion: sesion),
  );
}

/// Monta [pantalla] con el tema y el idioma de la app, en un teléfono de [tamano].
Future<void> montar(
  WidgetTester tester,
  Widget pantalla, {
  required ThemeData tema,
  Size tamano = const Size(393, 852),
  double escalaTexto = 1,
}) async {
  tester.view.physicalSize = tamano * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: tema,
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, hijo) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escalaTexto)),
        child: hijo ?? const SizedBox.shrink(),
      ),
      home: pantalla,
    ),
  );
  await tester.pumpAndSettle();
}

/// Carga las fuentes del prototipo y los íconos: en los tests de widgets no vienen solas.
Future<void> cargarFuentes() async {
  const familias = {
    'Inter': [
      'assets/fuentes/Inter-Regular.ttf',
      'assets/fuentes/Inter-Medium.ttf',
      'assets/fuentes/Inter-SemiBold.ttf',
      'assets/fuentes/Inter-Bold.ttf',
    ],
    'Archivo': ['assets/fuentes/Archivo-ExtraBold.ttf'],
    'Archivo Black': ['assets/fuentes/ArchivoBlack-Regular.ttf'],
    'JetBrains Mono': ['assets/fuentes/JetBrainsMono-Regular.ttf'],
    'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
  };
  for (final MapEntry(key: familia, value: archivos) in familias.entries) {
    final cargador = FontLoader(familia);
    for (final archivo in archivos) {
      cargador.addFont(rootBundle.load(archivo));
    }
    await cargador.load();
  }
}

/// Firebase sin red: [alIngresar] decide qué pasa con cada intento.
class CredencialesFalsas implements Credenciales {
  CredencialesFalsas({this.alIngresar, this.conCuenta = false});

  final Future<void> Function(String correo, String contrasena)? alIngresar;
  bool conCuenta;
  final intentos = <(String, String)>[];
  int salidas = 0;

  @override
  bool get hayCuenta => conCuenta;

  @override
  Future<void> ingresar(String correo, String contrasena) async {
    intentos.add((correo, contrasena));
    await alIngresar?.call(correo, contrasena);
    conCuenta = true;
  }

  /// Como cuando Firebase ya no puede refrescar la sesión.
  bool tokenFalla = false;

  @override
  Future<String?> token() async {
    if (tokenFalla) throw const CredencialesInvalidas();
    return conCuenta ? 'token-falso' : null;
  }

  @override
  Future<void> salir() async {
    salidas++;
    conCuenta = false;
  }
}

/// El perfil que devuelve `GET /yo` en los tests.
String perfilJson({String rol = 'usuario'}) =>
    '{"nombre": "Nahuel", "apellido": "Mosse", "correo": "nahuel@correo.com", '
    '"rol": "$rol", "dni": "42118507", "fecha_nacimiento": "2000-03-14"}';

final perfilUsuario = Perfil(
  nombre: 'Nahuel',
  apellido: 'Mosse',
  correo: 'nmosse@unimoron.edu.ar',
  rol: Rol.usuario,
  dni: '42118507',
  fechaNacimiento: DateTime(2000, 3, 14),
);

final perfilAdmin = Perfil(
  nombre: 'Ana',
  apellido: 'Díaz',
  correo: 'admin@clubnahuelmosse.com',
  rol: Rol.admin,
  dni: '20000001',
  fechaNacimiento: DateTime(1980, 1, 1),
);

/// Una sesión ya iniciada con [perfil], sin Firebase ni API.
class SesionFalsa extends Sesion {
  SesionFalsa(this._perfilFalso)
    : super(credenciales: CredencialesFalsas(conCuenta: true), api: apiFalsa());

  Perfil? _perfilFalso;
  int cierres = 0;

  @override
  Perfil? get perfil => _perfilFalso;

  @override
  Future<Perfil> refrescar() async {
    final perfil = _perfilFalso;
    if (perfil == null) throw const SesionVencida();
    return perfil;
  }

  @override
  Future<void> cerrar() async {
    cierres++;
    _perfilFalso = null;
    notifyListeners();
  }
}
