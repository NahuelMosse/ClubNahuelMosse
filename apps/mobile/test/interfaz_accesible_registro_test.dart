import 'package:clubnahuelmosse/features/users/data/registration_service.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'soporte/montar.dart';

void main() {
  setUpAll(cargarFuentes);

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'con un dato completado sólo se marca lo que falta, y escribirlo borra su error '
    '@REV-04-S1 @assumption:REV-04-ASM-01',
    (tester) async {
      final pedidos = <http.Request>[];
      await montar(
        tester,
        RegistrationScreen(
          // Un 422 evita la navegación de un alta exitosa, que pide un GoRouter.
          registration: RegistrationService(
            apiRutas({
              'POST /registro': (422, '{"errores": {"dni": "DNI repetido"}}'),
            }, pedidos: pedidos),
          ),
        ),
        tema: darkTheme,
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

      await tocar(tester, find.text('CREAR CUENTA'));

      expect(find.text('El correo es obligatorio'), findsOneWidget);
      expect(find.text('El nombre es obligatorio'), findsNothing);
      expect(pedidos, isEmpty);
      await tester.enterText(
        find.bySemanticsLabel('Correo electrónico'),
        'ana@correo.com',
      );
      await tester.pumpAndSettle();
      expect(find.text('El correo es obligatorio'), findsNothing);
      await tocar(tester, find.text('CREAR CUENTA'));
      expect(pedidos.where((p) => p.url.path == '/registro'), hasLength(1));
    },
  );
}
