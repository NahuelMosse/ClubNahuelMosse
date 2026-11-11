import 'package:clubnahuelmosse/features/bookings/presentation/date_strip.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/selectable_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../my_bookings_test.dart' show bookingJson;
import '../support/admin.dart';
import '../support/held_api.dart';
import '../support/mount.dart';
import '../support/skeleton_capture.dart';
import '../support/user.dart';

const _moron = '00000000-0000-7000-8000-000000000001';
const _f5 = '00000000-0000-7000-8000-000000000009';

/// Asserts nothing: it produces each loading state of the bookings screens next to the same
/// screen loaded, dark, 393x852.
Future<void> _capture(WidgetTester tester, String file) async {
  await decodeImages(tester);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
}

void main() {
  Future<HeldApi> mount(
    WidgetTester tester,
    String route, {
    Map<String, (int, String)> extra = const {},
  }) async {
    final held = HeldApi({
      ...venueRoutes(spaces: '[$spaceF5Json, $f5CoveredJson]'),
      ...extra,
    });
    await mountApp(
      tester,
      api: held.client,
      session: FakeSession(userProfile),
      route: route,
    );
    return held;
  }

  testWidgets('availability loading and loaded', (tester) async {
    final held = await mount(tester, '/venues/$_moron/spaces/$_f5');
    await _capture(tester, 'skeletons/availability_loading.png');
    held.release();
    await tester.pumpAndSettle();
    await _capture(tester, 'skeletons/availability_loaded.png');
    await drainApp(tester);
  });

  testWidgets('availability changing the day and changed', (tester) async {
    final held = await mount(tester, '/venues/$_moron/spaces/$_f5');
    held.release();
    await tester.pumpAndSettle();
    held.holdAgain();
    await tester.tap(
      find
          .descendant(
            of: find.byType(DateStrip),
            matching: find.byType(SelectableFrame),
          )
          .at(1),
    );
    await tester.pump();
    await tester.pump();
    await _capture(tester, 'skeletons/availability_changing_day.png');
    held.release();
    await tester.pumpAndSettle();
    await _capture(tester, 'skeletons/availability_day_changed.png');
    await drainApp(tester);
  });

  testWidgets('search form loading and loaded', (tester) async {
    final held = await mount(tester, '/home/search');
    await _capture(tester, 'skeletons/search_form_loading.png');
    held.release();
    await tester.pumpAndSettle();
    await _capture(tester, 'skeletons/search_form_loaded.png');
    await drainApp(tester);
  });

  testWidgets('search results loading and loaded', (tester) async {
    final semantics = tester.ensureSemantics();
    final held = await mount(
      tester,
      '/home/search',
      extra: {
        'GET /spaces/available': (
          200,
          '{"spaces": [$spaceF5Json, $f5CoveredJson]}',
        ),
      },
    );
    await submitSearch(tester, held);
    await tester.ensureVisible(find.text('LIMPIAR'));
    await _capture(tester, 'skeletons/search_results_loading.png');
    held.release();
    await tester.pumpAndSettle();
    await _capture(tester, 'skeletons/search_results_loaded.png');
    await drainApp(tester);
    semantics.dispose();
  });

  testWidgets('my bookings loading and loaded', (tester) async {
    final second = bookingJson(id: '00000000-0000-7000-8000-000000000002');
    final held = await mount(
      tester,
      '/bookings',
      extra: {
        'GET /bookings': (200, '{"bookings": [${bookingJson()}, $second]}'),
      },
    );
    await _capture(tester, 'skeletons/bookings_loading.png');
    held.release();
    await tester.pumpAndSettle();
    await _capture(tester, 'skeletons/bookings_loaded.png');
    await drainApp(tester);
  });
}
