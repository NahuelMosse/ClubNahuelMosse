import 'dart:io';

import 'package:clubnahuelmosse/features/admin/presentation/admin_panel_screen.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/features/session/presentation/access_denied_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mount.dart';

const _accessDenied = '/admin/access-denied';

/// Each row of the page's route table: the route with example values and who may enter.
List<(String, String)> _rows() {
  final text = File(
    '../../docs/technical/app-navigation.md',
  ).readAsStringSync();
  final table = text.split('## Routes').last.split('\n## ').first;
  final row = RegExp(
    r'^\| `([^`]+)` \|.*\| ([^|]+) \| [^|]+ \|$',
    multiLine: true,
  );
  return [
    for (final m in row.allMatches(table))
      (
        m
            .group(1)!
            .replaceAllMapped(RegExp(r':\w+'), (_) => '1')
            .replaceAll(RegExp(r'=(?=&|$)'), '=1'),
        m.group(2)!.trim(),
      ),
  ];
}

void main() {
  testWidgets(
    'who may enter each route is what the navigation page says @DOC-01-S2',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final rows = _rows();
      expect(rows.length, greaterThanOrEqualTo(30));

      for (final (route, who) in rows) {
        for (final session in ['none', 'user', 'admin']) {
          await tester.pumpWidget(
            App(
              key: UniqueKey(),
              api: apiRoutes({}),
              session: FakeSession(switch (session) {
                'user' => userProfile,
                'admin' => adminProfile,
                _ => null,
              }),
              appearance: Appearance.inMemory(),
              initialLocation: route,
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));

          final allowed = switch (who) {
            'No session' => true,
            'Anyone with a session' => session != 'none',
            'User' => session == 'user',
            'Admin' => session == 'admin',
            _ => throw StateError('undocumented role: $who'),
          };
          final toLogin =
              route != '/' &&
              find.byType(LoginScreen).hitTestable().evaluate().isNotEmpty;
          final denied =
              route != _accessDenied &&
              find
                  .byType(AccessDeniedScreen)
                  .hitTestable()
                  .evaluate()
                  .isNotEmpty;
          final toPanel =
              who != 'Admin' &&
              route != _accessDenied &&
              session == 'admin' &&
              who == 'User' &&
              find.byType(AdminPanelScreen).evaluate().isNotEmpty;

          expect(
            !(toLogin || denied || toPanel),
            allowed,
            reason: '$route with session «$session»: the page says «$who»',
          );
        }
      }
    },
  );
}
