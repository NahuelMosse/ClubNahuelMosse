// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../session/presentation/account_card.dart';
import '../../session/presentation/session.dart';

/// The title «Mis reservas» with the account button.
class MyBookingsHeader extends StatelessWidget {
  const MyBookingsHeader({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              AppLocalizations.of(context).bookingMyBookings,
              style: Texts.h1.copyWith(color: p.textPrimary),
            ),
          ),
        ),
        AccountButton(session: session),
      ],
    );
  }
}
