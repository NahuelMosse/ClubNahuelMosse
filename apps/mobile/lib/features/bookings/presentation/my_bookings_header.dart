// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../session/presentation/account_card.dart';
import '../../session/presentation/session.dart';

/// El título «Mis reservas» con el botón de la cuenta.
class MyBookingsHeader extends StatelessWidget {
  const MyBookingsHeader({super.key, required this.sesion});

  final Session sesion;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Mis reservas',
              style: Texts.h1.copyWith(color: p.textPrimary),
            ),
          ),
        ),
        AccountButton(session: sesion),
      ],
    );
  }
}
