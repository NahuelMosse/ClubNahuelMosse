import 'dart:convert';

import 'package:clubnahuelmosse/notificaciones/sistema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notificaciones_test.dart'
    show ApiFalsa, SistemaFalso, centroDe, cuerpoDe;
import 'soporte/admin.dart';
import 'soporte/usuario.dart';

/// Un sistema que arranca sin haber preguntado y contesta lo que se le fije al preguntar.
class SistemaSinPreguntar extends SistemaFalso {
  SistemaSinPreguntar({this.respuesta = true}) : super(concedido: false);

  final bool respuesta;
  bool yaPreguntado = false;

  @override
  Future<bool> preguntado() async => yaPreguntado;

  @override
  Future<bool> solicitarPermiso() async {
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
      final pedido = cuerpoDe(api.de('PUT', '/dispositivos').last);
      expect(pedido['permiso'], isTrue);
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

    await centro.activar();

    expect(sistema.solicitudes, 1);
  });

  testWidgets(
    'si al entrar niega el permiso, el teléfono se registra sin permiso y no se vuelve a preguntar @NOT-01-S1 @NOT-01-S2',
    (tester) async {
      final api = ApiFalsa();
      final sistema = SistemaSinPreguntar(respuesta: false);
      final sesion = SesionFalsa(perfilUsuario);
      centroDe(api, sesion, sistema: sistema);
      await tester.pumpAndSettle();

      expect(sistema.solicitudes, 1);
      final pedido = cuerpoDe(api.de('PUT', '/dispositivos').last);
      expect(pedido['permiso'], isFalse);

      centroDe(api, sesion, sistema: sistema);
      await tester.pumpAndSettle();
      expect(sistema.solicitudes, 1);
      expect(jsonEncode(pedido), contains('token-del-telefono'));
    },
  );

  test(
    'el sistema simulado sin respuesta guardada dice que todavía no preguntó y pedirle el permiso concedido o negado lo guarda @assumption:NOT-01-ASM-03',
    () async {
      SharedPreferences.setMockInitialValues({});
      var sistema = SistemaSimulado();
      expect(await sistema.preguntado(), isFalse);
      expect(await sistema.solicitarPermiso(), isTrue);
      expect(await sistema.preguntado(), isTrue);
      expect(await sistema.permitido(), isTrue);

      SharedPreferences.setMockInitialValues({
        'permiso_notificaciones_simulado': 'denegado',
      });
      sistema = SistemaSimulado();
      expect(await sistema.preguntado(), isTrue);
      expect(await sistema.permitido(), isFalse);
      expect(await sistema.solicitarPermiso(), isFalse);
      expect(await sistema.preguntado(), isTrue);
    },
  );
}
