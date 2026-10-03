import 'dart:convert';

import 'package:clubnahuelmosse/admin/historial_reservas.dart';
import 'package:clubnahuelmosse/admin/pantalla_detalle_reserva.dart';
import 'package:clubnahuelmosse/espacios/espacios.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

String reservaJson({
  String estado = 'anulada',
  String? envio,
  String? envioEn,
}) =>
    '{"id": 1, "espacio_id": 9, "sede_id": 1, "espacio":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", "tipo": "F5", "sede":'
    ' "Sede Morón", "direccion": "Av. Rivadavia 19850", "inicio":'
    ' "2026-11-12T21:00:00-03:00", "fin": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "estado": "$estado", "motivo": "mantenimiento de la cancha",'
    ' "usuario_id": 1, "usuario": "Nahuel Mosse",'
    ' "creado_en": "2026-11-02T18:42:00-03:00",'
    ' "cancelada_en": "2026-11-03T10:00:00-03:00",'
    ' "cancelada_por_nombre": "Ana Díaz", "espacio_de_baja": false,'
    ' "anulable": false, "aviso_envio": ${envio == null ? 'null' : '"$envio"'},'
    ' "aviso_en": ${envioEn == null ? 'null' : '"$envioEn"'}}';

void main() {
  Future<void> abrir(
    WidgetTester tester,
    String json, {
    Size tamano = const Size(360, 800),
    double escala = 1,
  }) async {
    final reserva = ReservaHistorial.desdeJson(jsonDecode(json));
    if (reserva == null) fail('la reserva de prueba no se lee');
    final sesion = SesionFalsa(perfilAdmin);
    final api = apiRutas({});
    await montar(
      tester,
      PantallaDetalleReserva(
        reserva: reserva,
        historial: HistorialDeReservas(api: api, sesion: sesion),
        sesion: sesion,
        espacios: Espacios(api: api, sesion: sesion),
        filtros: const FiltrosDeHistorial(),
        pendientes: FiltrosDePanelPendientes(),
      ),
      tema: temaOscuro,
      tamano: tamano,
      escalaTexto: escala,
    );
  }

  group('la trazabilidad del detalle muestra cómo salió el aviso', () {
    testWidgets('enviado: dice que se envió y cuándo', (tester) async {
      await abrir(
        tester,
        reservaJson(envio: 'enviada', envioEn: '2026-11-03T10:00:05-03:00'),
      );

      expect(find.text('Notificación enviada al usuario'), findsOneWidget);
      expect(find.text('03/11/2026 10:00'), findsWidgets);
    });

    for (final envio in ['sin_permiso', 'sin_canal', 'fallida']) {
      testWidgets('$envio: queda en el centro y el push no salió', (
        tester,
      ) async {
        await abrir(
          tester,
          reservaJson(envio: envio, envioEn: '2026-11-03T10:00:05-03:00'),
        );

        expect(find.text('Aviso en el centro del usuario'), findsOneWidget);
        expect(find.text('El push no salió'), findsOneWidget);
        expect(find.text('Notificación enviada al usuario'), findsNothing);
      });
    }

    testWidgets('pendiente o sin aviso: no figura', (tester) async {
      await abrir(tester, reservaJson());

      expect(find.text('Anulada por el administrador'), findsOneWidget);
      expect(find.text('Notificación enviada al usuario'), findsNothing);
      expect(find.text('Aviso en el centro del usuario'), findsNothing);
    });

    for (final (ancho, alto) in [(360.0, 800.0), (430.0, 932.0)]) {
      testWidgets('al 200 % en $ancho de ancho no se corta', (tester) async {
        await abrir(
          tester,
          reservaJson(envio: 'sin_canal', envioEn: '2026-11-03T10:00:05-03:00'),
          tamano: Size(ancho, alto),
          escala: 2,
        );
        await tester.ensureVisible(find.text('Aviso en el centro del usuario'));

        expect(find.text('El push no salió'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
