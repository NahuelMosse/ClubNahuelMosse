import '../../../l10n/app_localizations.dart';
import '../domain/search_rules.dart';

/// The text of a broken rule of the queried range, in the language of [l].
String rangeProblemText(AppLocalizations l, RangeProblem problem) =>
    switch (problem.kind) {
      RangeProblemKind.datePast => l.searchProblemPast,
      RangeProblemKind.dateTooFar => l.searchProblemFar('${problem.value}'),
      RangeProblemKind.venueClosedThatDay => l.searchProblemClosedDay,
      RangeProblemKind.tooShort => l.searchProblemMinHours,
      RangeProblemKind.tooLong => l.searchProblemMaxHours('${problem.value}'),
      RangeProblemKind.venueCloses => l.searchProblemCloses('${problem.value}'),
      RangeProblemKind.venueOpens => l.searchProblemOpens('${problem.value}'),
      RangeProblemKind.timePast => l.searchProblemNotFuture,
    };
