import 'dart:io';
import 'dart:typed_data';

import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/pending_booking.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;
import 'package:intl/intl.dart';

import '../mis_reservas_test.dart' show reservaJson;
import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';
import '../soporte/usuario.dart';

/// Produces the four screenshots of the README, in English, light mode, 430 px wide.
/// It is not a `_test.dart` file, so the default run skips it; the gate runs it by name.
/// Before writing each PNG it asserts that the screen shows its English text.
void main() {
  setUpAll(cargarFuentes);

  const phone = Size(430, 932);
  const spaceId = '00000000-0000-7000-8000-000000000009';
  const venueId = '00000000-0000-7000-8000-000000000001';

  /// Writes the captured bytes into `docs/screenshots/` instead of comparing them.
  goldenFileComparator = _ScreenshotWriter();

  void useEnglishDevice(WidgetTester tester) {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    Intl.defaultLocale = 'en';
  }

  /// The screens are mounted by helpers that fix a 3x ratio; the README takes them at 1x.
  Future<void> capture(WidgetTester tester, String name) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = phone;
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget;
        if (image is Image) await precacheImage(image.image, element);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(name));
  }

  Future<void> openVenues(WidgetTester tester, String start) => montarUsuario(
    tester,
    oscuro: false,
    tamano: phone,
    inicio: start,
    api: apiRutas({
      ...rutasDeSedes(),
      'POST /bookings': (
        201,
        reservaJson(
          inicio: '2026-11-12T21:00:00+00:00',
          fin: '2026-11-12T22:00:00+00:00',
        ),
      ),
    }),
  );

  testWidgets('01-login', (tester) async {
    useEnglishDevice(tester);
    final login = LoginScreen(
      pending: PendingBooking(),
      session: Session(
        repository: SessionRepository(
          credentials: CredencialesFalsas(
            alIngresar: (_, _) async => throw const InvalidCredentials(),
          ),
          api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
        ),
      ),
    );
    await montar(tester, login, tema: lightTheme, tamano: phone);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('Forgot your password?'), findsOneWidget);
    await capture(tester, '01-login.png');
  });

  testWidgets('03-venues', (tester) async {
    useEnglishDevice(tester);
    await openVenues(tester, '/sedes');
    expect(find.text('Venues'), findsWidgets);
    await capture(tester, '03-venues.png');
  });

  testWidgets('05-availability', (tester) async {
    useEnglishDevice(tester);
    await openVenues(tester, '/sedes/$venueId/canchas/$spaceId');
    expect(find.text('AVAILABLE TIME'), findsOneWidget);
    await capture(tester, '05-availability.png');
  });

  testWidgets('07-done', (tester) async {
    useEnglishDevice(tester);
    final semantics = tester.ensureSemantics();
    await openVenues(tester, '/sedes/$venueId/canchas/$spaceId');
    final slot = find.bySemanticsLabel('18:00 – 19:00');
    await tester.ensureVisible(slot);
    await tester.pumpAndSettle();
    await tester.tap(slot);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONFIRM BOOKING'));
    await tester.pumpAndSettle();
    expect(find.text('Booking confirmed!'), findsOneWidget);
    await capture(tester, '07-done.png');
    semantics.dispose();
  });
}

class _ScreenshotWriter extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    await update(golden, imageBytes);
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final file = File('../../docs/screenshots/${golden.pathSegments.last}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(imageBytes);
  }
}
