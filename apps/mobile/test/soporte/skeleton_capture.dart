import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/clock.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'held_api.dart';
import 'montar.dart';

/// The second covered space of the Morón venue, next to `espacioF5Json`.
const f5TechadaJson =
    '{"id": "00000000-0000-7000-8000-000000000011", "nombre": "Moron_Rivadavia_19850_Futbol_F5_2", "sede_id": "00000000-0000-7000-8000-000000000001", '
    '"sede": "Sede Morón", "deporte": "Futbol", "tipo": "F5", "numero": 2, '
    '"techada": true, "iluminada": true, "precio_por_hora": 43000}';

/// Mounts the app dark at 393x852 on [route] and pumps [pumps] frames.
Future<void> mountApp(
  WidgetTester tester, {
  required ApiClient api,
  required Session session,
  required String route,
  NotificationCenter? notificationCenter,
  int pumps = 2,
}) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await cargarFuentes();
  await tester.pumpWidget(
    App(
      api: api,
      session: session,
      appearance: Appearance.inMemory(dark: true),
      notificationCenter: notificationCenter,
      initialLocation: route,
    ),
  );
  for (var i = 0; i < pumps; i++) {
    await tester.pump();
  }
}

/// Compares the app with the golden [file] once its images are decoded.
Future<void> captureApp(WidgetTester tester, String file) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget;
      if (image is Image) await precacheImage(image.image, element);
    }
  });
  await tester.pump();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
}

/// Unmounts the app and lets the pending timers run out.
Future<void> drainApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 2));
}

/// Opens the selector [field] and picks [option] in its dialog.
Future<void> chooseOption(
  WidgetTester tester,
  String field,
  String option,
) async {
  await tester.ensureVisible(find.bySemanticsLabel(field));
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel(field));
  await tester.pumpAndSettle();
  final button = find.descendant(
    of: find.byType(Dialog),
    matching: find.text(option),
  );
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

/// Tomorrow, or the next day when that is a Sunday, as the date field shows it.
String nextWorkingDay() {
  var d = clubNow().add(const Duration(days: 1));
  while (d.weekday == DateTime.sunday) {
    d = d.add(const Duration(days: 1));
  }
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)} / ${two(d.month)} / ${d.year}';
}

/// Loads the search form, fills venue, sport and date, and sends the query held again.
Future<void> submitSearch(WidgetTester tester, HeldApi held) async {
  held.release();
  await tester.pumpAndSettle();
  await chooseOption(tester, 'Sede', 'Sede Morón');
  await chooseOption(tester, 'Deporte', 'Fútbol');
  await tester.enterText(
    find.descendant(
      of: find.bySemanticsLabel('Fecha'),
      matching: find.byType(EditableText),
    ),
    nextWorkingDay(),
  );
  await tester.pumpAndSettle();
  held.holdAgain();
  await tester.tap(find.text('CONSULTAR'));
  await tester.pump();
  await tester.pump();
}
