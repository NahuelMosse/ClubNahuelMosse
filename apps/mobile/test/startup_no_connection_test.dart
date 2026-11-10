import 'dart:async';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/mount.dart';

void main() {
  setUpAll(loadFonts);

  testWidgets(
    'al arrancar sin conexión la app muestra el diálogo de error con Reintentar @SIM-01-S4 @assumption:SIM-01-ASM-08 (widget)',
    (tester) async {
      final api = ApiClient(
        'http://api.falsa',
        cliente: MockClient((_) async => throw http.ClientException('sin red')),
      );
      final sesion = Session(
        repository: SessionRepository(
          credentials: FakeCredentials(conCuenta: true),
          api: api,
        ),
      );

      unawaited(resumeWithRetry(sesion));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.textContaining('Revisá tu conexión a internet'),
        findsOneWidget,
      );
      expect(find.text('REINTENTAR'), findsOneWidget);
      expect(find.textContaining('no responde'), findsNothing);
    },
  );
}
