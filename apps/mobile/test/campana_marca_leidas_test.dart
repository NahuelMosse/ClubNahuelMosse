import 'dart:async';

import 'package:clubnahuelmosse/notificaciones/centro.dart';
import 'package:clubnahuelmosse/notificaciones/notificacion.dart';
import 'package:clubnahuelmosse/notificaciones/pantalla_notificaciones.dart';
import 'package:clubnahuelmosse/notificaciones/sistema.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notificaciones_test.dart'
    show ApiFalsa, SistemaFalso, centroDe, notif, recordatorio, ahoraClub;
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

const _reserva1 = '00000000-0000-7000-8000-000000000001';
const _reserva2 = '00000000-0000-7000-8000-000000000002';
const _idRecordatorio = '00000000-0000-7000-8000-000000000003';

/// Un sistema donde el test decide cuándo la persona toca un aviso de la bandeja.
class SistemaConToques extends SistemaFalso {
  final toques = StreamController<AvisoTocado>.broadcast();

  @override
  Stream<AvisoTocado> get alTocar => toques.stream;
}

Future<(ApiFalsa, CentroDeNotificaciones)> _abrirCentro(
  WidgetTester tester, {
  required List<String> avisos,
}) async {
  final api = ApiFalsa()
    ..avisos = avisos
    ..noLeidas = avisos.length;
  final sesion = SesionFalsa(perfilUsuario);
  final centro = centroDe(api, sesion);
  await montar(
    tester,
    PantallaNotificaciones(
      centro: centro,
      sesion: sesion,
      ahora: () => ahoraClub,
      alAbrir: (_, _) {},
    ),
    tema: temaOscuro,
  );
  return (api, centro);
}

Future<void> _salir(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(cargarFuentes);

  group('salir del centro de notificaciones', () {
    testWidgets(
      'abrir la campana y volver deja leídas las que se mostraron y la campana en cero @NOT-03-S1',
      (tester) async {
        final (api, centro) = await _abrirCentro(
          tester,
          avisos: [recordatorio],
        );
        expect(centro.noLeidas, 1);

        await _salir(tester);

        expect(api.de('POST', '/notificaciones/leer-todas'), hasLength(1));
        expect(centro.noLeidas, 0);
        expect(centro.lista.every((n) => n.leida), isTrue);
      },
    );

    testWidgets(
      'con el centro abierto las nuevas siguen marcadas sin leer @NOT-03-S1',
      (tester) async {
        final semantica = tester.ensureSemantics();
        final (api, centro) = await _abrirCentro(
          tester,
          avisos: [recordatorio],
        );

        expect(find.bySemanticsLabel(RegExp('sin leer')), findsOneWidget);
        expect(centro.noLeidas, 1);
        expect(api.de('POST', '/notificaciones/leer-todas'), isEmpty);
        semantica.dispose();
      },
    );

    testWidgets(
      'si la API no contesta al salir se ven leídas y la próxima lectura corrige @assumption:NOT-03-ASM-02',
      (tester) async {
        final (api, centro) = await _abrirCentro(
          tester,
          avisos: [recordatorio],
        );
        api.caida = true;

        await _salir(tester);

        expect(centro.noLeidas, 0);
        expect(centro.lista.every((n) => n.leida), isTrue);

        api.caida = false;
        await tester.runAsync(centro.cargar);
        expect(centro.noLeidas, 1);
      },
    );
  });

  group('tocar un push', () {
    testWidgets(
      'tocar un push marca leídas las de ese tipo y reserva y abre la reserva @NOT-03-S2',
      (tester) async {
        final otraReserva = notif(
          id: '00000000-0000-7000-8000-000000000005',
          club: DateTime.utc(2026, 11, 12, 19, 50),
          reservaId: _reserva2,
        );
        final otroTipo = notif(
          id: '00000000-0000-7000-8000-000000000006',
          club: DateTime.utc(2026, 11, 12, 19, 40),
          tipo: 'cancelacion_usuario',
          titulo: 'Reserva cancelada',
        );
        final api = ApiFalsa()
          ..avisos = [recordatorio, otraReserva, otroTipo]
          ..noLeidas = 3;
        final sistema = SistemaConToques();
        addTearDown(sistema.toques.close);
        late CentroDeNotificaciones centro;
        await montarUsuario(
          tester,
          inicio: '/inicio',
          api: api.cliente,
          centro: (sesion) =>
              centro = centroDe(api, sesion, sistema: sistema),
        );

        sistema.toques.add(
          AvisoTocado(
            tipo: TipoDeNotificacion.recordatorio,
            reservaId: _reserva1,
          ),
        );
        await tester.pumpAndSettle();

        final leidas = api
            .pedidos
            .where((p) => p.method == 'POST' && p.url.path.endsWith('/leer'))
            .map((p) => p.url.path)
            .toList();
        expect(leidas, ['/notificaciones/$_idRecordatorio/leer']);
        expect(centro.sinLeer, hasLength(2));
        expect(find.text('Mis reservas'), findsOneWidget);
      },
    );

    testWidgets(
      'un push que no se toca sigue sin leer @assumption:NOT-03-ASM-01',
      (tester) async {
        final api = ApiFalsa()
          ..avisos = [recordatorio]
          ..noLeidas = 1;
        final sistema = SistemaConToques();
        addTearDown(sistema.toques.close);
        late CentroDeNotificaciones centro;
        await montarUsuario(
          tester,
          inicio: '/inicio',
          api: api.cliente,
          centro: (sesion) =>
              centro = centroDe(api, sesion, sistema: sistema),
        );

        expect(centro.noLeidas, 1);
        expect(api.de('POST', '/notificaciones/$_idRecordatorio/leer'), isEmpty);
        expect(api.de('POST', '/notificaciones/leer-todas'), isEmpty);
      },
    );
  });
}
