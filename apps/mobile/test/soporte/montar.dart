import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/data/credentials.dart';
import 'dart:convert';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/bookings.dart';
import 'package:clubnahuelmosse/features/bookings/data/bookings_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:clubnahuelmosse/features/session/domain/profile.dart';
import 'package:clubnahuelmosse/features/session/domain/role.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

/// Un cliente de la API que responde siempre [codigo] con [cuerpo], sin red.
ClienteApi apiFalsa({
  int codigo = 201,
  String cuerpo = '{"id": "00000000-0000-7000-8000-000000000001"}',
}) => ClienteApi(
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
    '{"clave": "Basquet", "nombre": "Básquet", "tipos": [{"clave": "B5", "nombre": "Básquet 5"}]}, '
    '{"clave": "Hockey", "nombre": "Hockey", "tipos": [{"clave": "H7", "nombre": "Hockey 7"}]}, '
    '{"clave": "Golf", "nombre": "Golf", "tipos": [{"clave": "DR", "nombre": "Driving range"}]}'
    ']}';

String _sedeJson(String id, String nombre, String direccion, int canchas) =>
    '{"id": "$id", "nombre": "$nombre", "direccion": "$direccion", '
    '"apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7], '
    '"canchas": $canchas, "deportes": ["Futbol", "Tenis"]}';

const _proximaJson =
    '{"id": "00000000-0000-7000-8000-000000000001", "espacio_id": "00000000-0000-7000-8000-000000000003", "sede_id": "00000000-0000-7000-8000-000000000002", '
    '"espacio": "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", '
    '"tipo": "F5", "sede": "Sede Morón", "direccion": "Av. Rivadavia 19850", '
    '"inicio": "2026-11-13T00:00:00Z", "fin": "2026-11-13T01:00:00Z", '
    '"total": 38000, "estado": "activa", "motivo": null, "cancelable": true}';

/// Una API con lo que lee el Home: 4 sedes con 17 canchas (o, con [unaSede], una sede con
/// una cancha), el catálogo de deportes y, con [conReserva], una próxima reserva.
ClienteApi apiInicio({
  bool conReserva = true,
  bool unaSede = false,
}) => apiRutas({
  'GET /reservas': (200, '{"reservas": [${conReserva ? _proximaJson : ''}]}'),
  'GET /espacios/catalogo': (200, _catalogoJson),
  'GET /sedes': (
    200,
    unaSede
        ? '{"sedes": [${_sedeJson('00000000-0000-7000-8000-000000000001', 'Sede Haedo', 'Av. Vergara 1850', 1)}]}'
        : '{"sedes": [${_sedeJson('00000000-0000-7000-8000-000000000001', 'Sede Haedo', 'Av. Vergara 1850', 6)}, '
              '${_sedeJson('00000000-0000-7000-8000-000000000002', 'Sede Morón', 'Av. Rivadavia 19850', 4)}, '
              '${_sedeJson('00000000-0000-7000-8000-000000000003', 'Sede Castelar', 'Av. Santa Rosa 1200', 4)}, '
              '${_sedeJson('00000000-0000-7000-8000-000000000004', 'Sede Ituzaingó', 'Blas Parera 300', 3)}]}',
  ),
});

/// El Home leyendo de [apiInicio].
Widget inicioFalso(
  Session sesion, {
  bool conReserva = true,
  bool unaSede = false,
}) {
  final api = apiInicio(conReserva: conReserva, unaSede: unaSede);
  return HomeScreen(
    sesion: sesion,
    reservas: Bookings(BookingsApi(api: api, sesion: sesion)),
    espacios: Spaces(
      repository: SpacesRepository(api: api, session: sesion),
    ),
    sedes: Venues(
      repository: VenuesRepository(api: api, session: sesion),
    ),
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
class CredencialesFalsas implements Credentials {
  CredencialesFalsas({this.alIngresar, this.conCuenta = false});

  final Future<void> Function(String correo, String contrasena)? alIngresar;
  bool conCuenta;
  final intentos = <(String, String)>[];
  int salidas = 0;

  @override
  bool get hasAccount => conCuenta;

  @override
  Future<void> signIn(String correo, String contrasena) async {
    intentos.add((correo, contrasena));
    await alIngresar?.call(correo, contrasena);
    conCuenta = true;
  }

  /// Como cuando Firebase ya no puede refrescar la sesión.
  bool tokenFalla = false;

  @override
  Future<String?> token() async {
    if (tokenFalla) throw const InvalidCredentials();
    return conCuenta ? 'token-falso' : null;
  }

  @override
  Future<void> signOut() async {
    salidas++;
    conCuenta = false;
  }
}

/// El perfil que devuelve `GET /yo` en los tests.
String perfilJson({String rol = 'usuario'}) =>
    '{"nombre": "Nahuel", "apellido": "Mosse", "correo": "nahuel@correo.com", '
    '"rol": "$rol", "dni": "42118507", "fecha_nacimiento": "2000-03-14"}';

final perfilUsuario = Profile(
  firstName: 'Nahuel',
  lastName: 'Mosse',
  email: 'nmosse@unimoron.edu.ar',
  role: Role.user,
  dni: '42118507',
  birthDate: DateTime(2000, 3, 14),
);

final perfilAdmin = Profile(
  firstName: 'Ana',
  lastName: 'Díaz',
  email: 'admin@clubnahuelmosse.com',
  role: Role.admin,
  dni: '20000001',
  birthDate: DateTime(1980, 1, 1),
);

/// Una sesión ya iniciada con [perfil], sin Firebase ni API.
class SesionFalsa extends Session {
  SesionFalsa(this._perfilFalso)
    : super(
        repository: SessionRepository(
          credentials: CredencialesFalsas(conCuenta: true),
          api: apiFalsa(),
        ),
      );

  Profile? _perfilFalso;
  int cierres = 0;

  @override
  Profile? get profile => _perfilFalso;

  @override
  Future<Profile> refresh() async {
    final perfil = _perfilFalso;
    if (perfil == null) throw const SessionExpired();
    return perfil;
  }

  @override
  Future<void> close() async {
    cierres++;
    _perfilFalso = null;
    notifyListeners();
  }
}
