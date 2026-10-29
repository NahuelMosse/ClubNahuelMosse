import '../../../l10n/app_localizations.dart';
import '../domain/venue_problem.dart';

/// What is wrong with a field of the venue form, in words.
String venueProblemText(AppLocalizations l10n, VenueProblem problem) =>
    switch (problem) {
      VenueProblem.nameRequired => l10n.adminVenueNameRequired,
      VenueProblem.addressRequired => l10n.adminVenueAddressRequired,
      VenueProblem.addressStreetAndNumber => l10n.adminVenueAddressStreet,
      VenueProblem.opensAtRequired => l10n.adminOpensAtRequired,
      VenueProblem.closesAtRequired => l10n.adminClosesAtRequired,
      VenueProblem.closesBeforeOpens => l10n.adminClosesBeforeOpens,
    };
