// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../session/presentation/account_card.dart';
import '../../session/presentation/session.dart';

/// «PANEL ADMIN» and the section title, with the account button on the right.
class AdminHeader extends StatelessWidget {
  const AdminHeader({super.key, required this.title, required this.session});

  final String title;
  final Session session;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PANEL ADMIN',
                style: Texts.overline.copyWith(color: p.accentInk),
              ),
              const SizedBox(height: Spacing.s4),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Texts.h1.copyWith(color: p.textPrimary),
                ),
              ),
            ],
          ),
        ),
        AccountButton(session: session),
      ],
    );
  }
}
