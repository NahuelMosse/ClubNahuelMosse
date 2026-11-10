import 'package:clubnahuelmosse/features/users/data/registration_service.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/mount.dart';

void main() {
  setUpAll(loadFonts);

  Future<void> tapAndSettle(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'with one field filled only what is missing is marked, and typing it clears its error @REV-04-S1 @assumption:REV-04-ASM-01',
    (tester) async {
      final requests = <http.Request>[];
      await mountScreen(
        tester,
        RegistrationScreen(
          // A 422 avoids the navigation of a successful sign-up, which needs a GoRouter.
          registration: RegistrationService(
            apiRoutes({
              'POST /register': (422, '{"errors": {"dni": "DNI repetido"}}'),
            }, requests: requests),
          ),
        ),
        theme: darkTheme,
      );
      await tester.enterText(find.bySemanticsLabel('Nombre'), 'Ana');
      await tester.enterText(find.bySemanticsLabel('Apellido'), 'Pérez');
      await tester.enterText(find.bySemanticsLabel('DNI'), '12345678');
      await tester.enterText(
        find.bySemanticsLabel('Fecha de nacimiento'),
        '14032000',
      );
      await tester.enterText(
        find.bySemanticsLabel('Contraseña'),
        'ClubNahuel1',
      );

      await tapAndSettle(tester, find.text('CREAR CUENTA'));

      expect(find.text('El correo es obligatorio'), findsOneWidget);
      expect(find.text('El nombre es obligatorio'), findsNothing);
      expect(requests, isEmpty);
      await tester.enterText(
        find.bySemanticsLabel('Correo electrónico'),
        'ana@correo.com',
      );
      await tester.pumpAndSettle();
      expect(find.text('El correo es obligatorio'), findsNothing);
      await tapAndSettle(tester, find.text('CREAR CUENTA'));
      expect(requests.where((p) => p.url.path == '/register'), hasLength(1));
    },
  );
}
