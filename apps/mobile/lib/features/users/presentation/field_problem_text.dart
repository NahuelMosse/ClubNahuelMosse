import '../../../l10n/app_localizations.dart';
import '../domain/registration_rules.dart';

/// The text of what a rule found wrong, in the language of [l10n]. [nameRequired] words the
/// missing-name problem of the field being checked (first name or last name).
String fieldProblemText(
  AppLocalizations l10n,
  FieldProblem problem, {
  String? nameRequired,
}) => switch (problem) {
  FieldProblem.nameRequired => nameRequired ?? l10n.ruleFirstNameRequired,
  FieldProblem.nameTooLong => l10n.ruleNameTooLong(maxNameLength),
  FieldProblem.dniRequired => l10n.ruleDniRequired,
  FieldProblem.dniFormat => l10n.ruleDniFormat,
  FieldProblem.birthRequired => l10n.ruleBirthRequired,
  FieldProblem.birthInvalid => l10n.ruleBirthInvalid,
  FieldProblem.birthNotPast => l10n.ruleBirthNotPast,
  FieldProblem.emailRequired => l10n.ruleEmailRequired,
  FieldProblem.emailFormat => l10n.ruleEmailFormat,
  FieldProblem.passwordRequired => l10n.rulePasswordRequired,
  FieldProblem.passwordLength => l10n.rulePasswordLength,
  FieldProblem.passwordUppercase => l10n.rulePasswordUppercase,
  FieldProblem.passwordNumber => l10n.rulePasswordNumber,
};
