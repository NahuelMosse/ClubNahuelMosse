import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'api/api_client.dart';
import 'app.dart';
import 'common/appearance.dart';
import 'common/config.dart';
import 'common/error_dialog.dart';
import 'common/loading_screen.dart';
import 'features/notifications/data/notifications_repository.dart';
import 'features/notifications/data/simulated_notification_system.dart';
import 'features/notifications/domain/notification_system.dart';
import 'features/notifications/presentation/fcm_notification_system.dart';
import 'features/notifications/presentation/notification_center.dart';
import 'features/session/data/credentials.dart';
import 'features/session/data/firebase.dart';
import 'features/session/data/session_repository.dart';
import 'features/session/domain/profile.dart';
import 'features/session/presentation/session.dart';
import 'theme/theme.dart';

void main() => bootstrap(AppConfig.fromEnvironment());

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  final auth = await initFirebase(config);
  final api = ApiClient(config.apiUrl);
  final session = Session(
    repository: SessionRepository(
      credentials: FirebaseCredentials(auth),
      api: api,
    ),
  );
  final NotificationSystem system = switch (config.push) {
    Push.fcm => FcmNotificationSystem(FirebaseMessaging.instance),
    Push.simulated => SimulatedNotificationSystem(),
  };
  final notificationCenter = NotificationCenter(
    notifications: NotificationsRepository(api: api, session: session),
    session: session,
    system: system,
    every: config.notificationPollInterval,
  );
  // The session stays open on the device: if it is still valid, the user goes straight in.
  final appearance = await Appearance.load();
  final profile = await resumeWithRetry(session);
  // A new key per start: the app is built from scratch even if runApp is called again.
  runApp(
    App(
      key: UniqueKey(),
      api: api,
      session: session,
      appearance: appearance,
      notificationCenter: notificationCenter,
      initialLocation: profile?.home ?? '/',
    ),
  );
}

/// Resumes the saved session. If it cannot be known whether the session is valid (no
/// connection or the API does not respond), it shows the error dialog with «Reintentar»
/// instead of sending the user to the login.
Future<Profile?> resumeWithRetry(Session session) async {
  final navigator = GlobalKey<NavigatorState>();
  runApp(_Waiting(navigator: navigator));
  while (true) {
    try {
      return await session.resume();
    } on FalloDeRed catch (e) {
      await WidgetsBinding.instance.endOfFrame;
      final context = navigator.currentState?.overlay?.context;
      if (context == null || !context.mounted) rethrow;
      await handleNetworkError(context, e);
    }
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.navigator});

  final GlobalKey<NavigatorState> navigator;

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigator,
    debugShowCheckedModeBanner: false,
    theme: lightTheme,
    darkTheme: darkTheme,
    home: const LoadingScreen(),
  );
}
