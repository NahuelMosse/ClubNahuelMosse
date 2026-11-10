// ignore_for_file: unawaited_futures
import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'after 30 s without a response the app warns that the server is not responding @SIM-01-S4 @assumption:SIM-01-ASM-04',
    (tester) async {
      Object? error;
      ApiClient(
            'http://api.falsa',
            client: MockClient(
              (_) => Future.delayed(
                const Duration(seconds: 90),
                () => http.Response('{}', 200),
              ),
            ),
          )
          .get('/spaces')
          .then(
            (_) {},
            onError: (Object e) {
              error = e;
            },
          );

      await tester.pump(const Duration(milliseconds: 29500));
      expect(error, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(error, isA<ServerNotResponding>());
      expect((error! as ServerNotResponding).code, 0);
      await tester.pump(const Duration(seconds: 90));
    },
  );
}
