// kit-shape: a screen or error family kept with its private parts.
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/registration_rules.dart';
import 'field_problem_text.dart';

/// The three password rules, each green if met and red if missing.
/// Shown while the typed password does not meet all of them.
class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key, required this.password});

  final String password;

  static const _all = [
    FieldProblem.passwordLength,
    FieldProblem.passwordUppercase,
    FieldProblem.passwordNumber,
  ];

  @override
  Widget build(BuildContext context) {
    final missing = passwordProblems(password);
    if (password.isEmpty || missing.isEmpty) return const SizedBox.shrink();
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.s16),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Container(
          padding: const EdgeInsets.all(Spacing.s16),
          decoration: BoxDecoration(
            color: p.bgSurface,
            borderRadius: BorderRadius.circular(Spacing.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, rule) in _all.indexed) ...[
                if (i > 0) const SizedBox(height: Spacing.s8),
                _Rule(
                  text: fieldProblemText(l10n, rule),
                  met: !missing.contains(rule),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.text, required this.met});

  final String text;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: met ? l10n.passwordRuleMet(text) : l10n.passwordRuleMissing(text),
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(
            met
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            size: 17,
            color: met ? p.stateSuccessInk : p.stateDangerInk,
          ),
          const SizedBox(width: Spacing.s8),
          Expanded(
            child: Text(
              text,
              style: Texts.caption.copyWith(
                color: met ? p.textSecondary : p.stateDangerInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
