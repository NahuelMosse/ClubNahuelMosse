import 'package:clubnahuelmosse/features/notifications/presentation/bell_button.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notifications_spanish_test.dart' show FakeApi, centerOf;
import 'support/mount.dart';

Future<void> _mountBell(
  WidgetTester tester, {
  required ThemeData theme,
  int unread = 0,
}) async {
  final api = FakeApi()
    ..notices = []
    ..unread = unread;
  final center = centerOf(api, FakeSession(userProfile));
  await mountScreen(
    tester,
    Material(child: NotificationsButton(center: center)),
    theme: theme,
  );
  await tester.pumpAndSettle();
}

Color _iconColor(WidgetTester tester) =>
    tester.widget<Icon>(find.byIcon(Icons.notifications_none_rounded)).color!;

void main() {
  testWidgets(
    'in light and dark mode the cover bell is painted with the on-photo color @NOT-04-S1',
    (tester) async {
      await _mountBell(tester, theme: lightTheme);
      expect(_iconColor(tester), Palette.light.textOnMedia);

      await _mountBell(tester, theme: darkTheme);
      expect(_iconColor(tester), Palette.dark.textOnMedia);
    },
  );

  testWidgets(
    'with unread notices the counter stays in the accent color @assumption:NOT-04-ASM-01',
    (tester) async {
      await _mountBell(tester, theme: lightTheme, unread: 2);

      final counter = tester.widget<Container>(
        find.ancestor(of: find.text('2'), matching: find.byType(Container)),
      );
      final decoration = counter.decoration! as BoxDecoration;
      expect(decoration.color, Palette.light.accentBase);
    },
  );
}
