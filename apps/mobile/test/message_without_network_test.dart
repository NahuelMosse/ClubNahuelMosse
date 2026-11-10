import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/mount.dart';
import 'support/user.dart';

void main() {
  setUpAll(loadFonts);

  testWidgets(
    'offline says «Revisá tu conexión a internet», not that the server does not respond @SIM-01-S4',
    (tester) async {
      final api = ApiClient(
        'http://api.falsa',
        client: MockClient((_) async => throw http.ClientException('sin red')),
      );
      await mountUser(tester, api: api);

      expect(
        find.textContaining('Revisá tu conexión a internet'),
        findsOneWidget,
      );
      expect(find.textContaining('no responde'), findsNothing);
    },
  );
}
