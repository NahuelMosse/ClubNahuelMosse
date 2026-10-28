import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/montar.dart';
import 'soporte/usuario.dart';

void main() {
  setUpAll(cargarFuentes);

  testWidgets(
    'sin red dice Revisá tu conexión a internet y no que el servidor no responde @SIM-01-S4',
    (tester) async {
      final api = ClienteApi(
        'http://api.falsa',
        cliente: MockClient((_) async => throw http.ClientException('sin red')),
      );
      await montarUsuario(tester, api: api);

      expect(
        find.textContaining('Revisá tu conexión a internet'),
        findsOneWidget,
      );
      expect(find.textContaining('no responde'), findsNothing);
    },
  );
}
