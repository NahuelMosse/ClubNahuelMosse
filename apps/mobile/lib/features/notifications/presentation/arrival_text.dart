import '../../../l10n/app_localizations.dart';
import '../domain/app_notification.dart';

/// El rótulo de cuándo llegó un aviso, en el idioma de la app.
String arrivalText(AppLocalizations l10n, Arrival arrival) =>
    switch (arrival.when) {
      ArrivalWhen.today => l10n.arrivalToday,
      ArrivalWhen.yesterday => l10n.arrivalYesterday,
      ArrivalWhen.date => arrival.date,
      ArrivalWhen.now => l10n.arrivalNow,
      ArrivalWhen.minutesAgo => l10n.arrivalMinutesAgo(arrival.amount),
      ArrivalWhen.hoursAgo => l10n.arrivalHoursAgo(arrival.amount),
    };
