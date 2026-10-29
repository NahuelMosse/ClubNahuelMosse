import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/features/admin/data/booking_history_api.dart';
import 'package:clubnahuelmosse/features/admin/domain/pending_panel_filters.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_panel_screen.dart';
import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'anular_reserva_test.dart' as anular show listado, reservaJson;
import 'mis_reservas_test.dart' show reservaJson;
import 'soporte/admin.dart';
import 'soporte/montar.dart';
import 'soporte/usuario.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

/// Contesta [respuestas] en orden a cada POST a [ruta] (la última se repite); un `null` es
/// un corte de red. Lo que no es ese POST lo contesta [resto].
MockClient _conCorte(
  String ruta,
  List<(int, String)?> respuestas,
  (int, String) Function(http.Request) resto, {
  void Function()? alLlegar,
}) {
  var n = 0;
  return MockClient((pedido) async {
    final (int, String) respuesta;
    if (pedido.url.path == ruta && pedido.method == 'POST') {
      final siguiente =
          respuestas[n < respuestas.length ? n : respuestas.length - 1];
      n++;
      // El servidor recibió el pedido aunque la respuesta no haya vuelto.
      alLlegar?.call();
      if (siguiente == null) throw const SocketException('sin red');
      respuesta = siguiente;
    } else {
      respuesta = resto(pedido);
    }
    return http.Response.bytes(
      utf8.encode(respuesta.$2),
      respuesta.$1,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

void main() {
  setUpAll(cargarFuentes);

  testWidgets('cancelar: un 409 después de un corte cuenta como cancelada', (
    tester,
  ) async {
    final futura = DateTime.now().toUtc().add(const Duration(days: 2));
    final inicio = DateTime.utc(futura.year, futura.month, futura.day, 21);
    final proxima = reservaJson(
      inicio: inicio.toIso8601String(),
      fin: inicio.add(const Duration(hours: 1)).toIso8601String(),
    );
    final rutas = rutasDeSedes();
    var cancelada = false;
    await montarUsuario(
      tester,
      inicio: '/reservas',
      api: ApiClient(
        'http://api.falsa',
        cliente: _conCorte(
          '/bookings/00000000-0000-7000-8000-000000000001/cancel',
          [
            null,
            (409, '{"errors": {"reserva": "Esto cambió mientras tanto"}}'),
          ],
          (pedido) {
            if (pedido.method == 'GET' && pedido.url.path == '/bookings') {
              return (200, '{"bookings": ${cancelada ? '[]' : '[$proxima]'}}');
            }
            return rutas['${pedido.method} ${pedido.url.path}'] ?? (404, '{}');
          },
          alLlegar: () => cancelada = true,
        ),
      ),
    );

    await tester.ensureVisible(find.text('CANCELAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCELAR RESERVA'));
    await tester.pumpAndSettle();
    expect(find.text('Error de conexión'), findsOneWidget);

    await tester.tap(find.text('REINTENTAR'));
    await tester.pumpAndSettle();

    expect(find.text('Reserva cancelada con éxito'), findsOneWidget);
    expect(find.text('Esto cambió mientras tanto'), findsNothing);
  });

  testWidgets('anular: un 409 después de un corte cuenta como anulada', (
    tester,
  ) async {
    final api = ApiClient(
      'http://api.falsa',
      cliente: _conCorte(
        '/bookings/00000000-0000-7000-8000-000000000001/void',
        [null, (409, '{"errors": {"reserva": "Esto cambió mientras tanto"}}')],
        (pedido) => switch (pedido.url.path) {
          '/bookings/all' => (200, anular.listado(anular.reservaJson())),
          '/spaces/catalog' => (200, catalogoJson),
          _ => (404, '{}'),
        },
      ),
    );
    final sesion = SesionFalsa(perfilAdmin);
    await montar(
      tester,
      AdminPanelScreen(
        history: BookingHistory(api: api, sesion: sesion),
        venues: Venues(
          repository: VenuesRepository(api: api, session: sesion),
        ),
        spaces: Spaces(
          repository: SpacesRepository(api: api, session: sesion),
        ),
        session: sesion,
        pending: PendingPanelFilters(),
      ),
      tema: darkTheme,
    );

    await tester.ensureVisible(find.text('ANULAR RESERVA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ANULAR RESERVA'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Lluvia');
    await tester.ensureVisible(find.text('CONFIRMAR ANULACIÓN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONFIRMAR ANULACIÓN'));
    await tester.pumpAndSettle();
    expect(find.text('Error de conexión'), findsOneWidget);

    await tester.tap(find.text('REINTENTAR'));
    await tester.pumpAndSettle();

    expect(find.text('Reserva anulada correctamente'), findsOneWidget);
    expect(find.text('Esto cambió mientras tanto'), findsNothing);
  });
}
