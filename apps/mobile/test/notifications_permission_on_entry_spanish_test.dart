import 'dart:convert';

import 'package:clubnahuelmosse/features/notifications/data/simulated_notification_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notifications_spanish_test.dart'
    show ApiFalsa, SistemaFalso, centroDe, cuerpoDe;
import 'soporte/montar.dart';

/// Un sistema que arranca sin haber preguntado y contesta lo que se le fije al preguntar.
class SistemaSinPreguntar extends SistemaFalso {
  SistemaSinPreguntar({this.respuesta = true}) : super(concedido: false);

  final bool respuesta;
  bool yaPreguntado = false;

  @override
  Future<bool> wasAsked() async => yaPreguntado;

  @override
  Future<bool> requestPermission() async {
    solicitudes++;
    yaPreguntado = true;
    concedido = respuesta;
    return respuesta;
  }
}

void main() {
  testWidgets(
    'al entrar, si el sistema todavía no le preguntó, la app pide el permiso y registra el teléfono con la respuesta @NOT-01-S1 @assumption:NOT-01-ASM-02',
    (tester) async {
      final api = ApiFalsa();
      final sistema = SistemaSinPreguntar();
      centroDe(api, SesionFalsa(perfilUsuario), sistema: sistema);
      await tester.pumpAndSettle();

      expect(sistema.solicitudes, 1);
      final request = cuerpoDe(api.de('PUT', '/dispositivos').last);
      expect(request['permiso'], isTrue);
    },
  );

  testWidgets('si ya contestó, al entrar no vuelve a preguntar @NOT-01-S2', (
    tester,
  ) async {
    final sistema = SistemaSinPreguntar()..yaPreguntado = true;
    centroDe(ApiFalsa(), SesionFalsa(perfilUsuario), sistema: sistema);
    await tester.pumpAndSettle();

    expect(sistema.solicitudes, 0);
  });

  testWidgets(
    'un administrador no recibe la pregunta al entrar @assumption:NOT-01-ASM-01',
    (tester) async {
      final sistema = SistemaSinPreguntar();
      centroDe(ApiFalsa(), SesionFalsa(perfilAdmin), sistema: sistema);
      await tester.pumpAndSettle();

      expect(sistema.solicitudes, 0);
    },
  );

  testWidgets('Activar sigue pidiendo el permiso @NOT-01-S2', (tester) async {
    final sistema = SistemaSinPreguntar()..yaPreguntado = true;
    final centro = centroDe(
      ApiFalsa(),
      SesionFalsa(perfilUsuario),
      sistema: sistema,
    );
    await tester.pumpAndSettle();

    await centro.enable();

    expect(sistema.solicitudes, 1);
  });

  testWidgets(
    'si al entrar niega el permiso, el teléfono se registra sin permiso y no se vuelve a preguntar @NOT-01-S1 @NOT-01-S2',
    (tester) async {
      final api = ApiFalsa();
      final sistema = SistemaSinPreguntar(respuesta: false);
      final session = SesionFalsa(perfilUsuario);
      centroDe(api, session, sistema: sistema);
      await tester.pumpAndSettle();

      expect(sistema.solicitudes, 1);
      final request = cuerpoDe(api.de('PUT', '/dispositivos').last);
      expect(request['permiso'], isFalse);

      centroDe(api, session, sistema: sistema);
      await tester.pumpAndSettle();
      expect(sistema.solicitudes, 1);
      expect(jsonEncode(request), contains('token-del-telefono'));
    },
  );

  test(
    'el sistema simulado sin respuesta guardada dice que todavía no preguntó y pedirle el permiso concedido o negado lo guarda @assumption:NOT-01-ASM-03',
    () async {
      SharedPreferences.setMockInitialValues({});
      var sistema = SimulatedNotificationSystem();
      expect(await sistema.wasAsked(), isFalse);
      expect(await sistema.requestPermission(), isTrue);
      expect(await sistema.wasAsked(), isTrue);
      expect(await sistema.isAllowed(), isTrue);

      SharedPreferences.setMockInitialValues({
        'permiso_notificaciones_simulado': 'denegado',
      });
      sistema = SimulatedNotificationSystem();
      expect(await sistema.wasAsked(), isTrue);
      expect(await sistema.isAllowed(), isFalse);
      expect(await sistema.requestPermission(), isFalse);
      expect(await sistema.wasAsked(), isTrue);
    },
  );
}
