import 'dart:async';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/mount.dart';

/// An API that never answers: the screen stays loading.
ApiClient _hungApi() => ApiClient(
  'http://api.falsa',
  client: MockClient((_) => Completer<http.Response>().future),
);

/// Mounts the app with the hung API and, when done, unmounts it and lets the
/// wait limit pass so the client's Timer is not left pending.
Future<void> _loading(
  WidgetTester tester, {
  required String start,
  required bool admin,
}) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    App(
      api: _hungApi(),
      session: FakeSession(admin ? adminProfile : userProfile),
      appearance: Appearance.inMemory(dark: true),
      initialLocation: start,
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('loading skeletons with a hung API', () {
    for (final (route, admin) in [
      ('/venues', false),
      ('/bookings', false),
      ('/home', false),
      ('/admin/venues', true),
    ]) {
      testWidgets(
        'every loading screen shows skeletons shaped like its content, not a spinner @VIS-02-S1 @assumption:VIS-02-ASM-02 $route',
        (tester) async {
          await _loading(tester, start: route, admin: admin);
          expect(find.byType(Skeleton), findsWidgets);
          expect(find.byType(CircularProgressIndicator), findsNothing);

          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(minutes: 2));
        },
      );
    }
  });
}
