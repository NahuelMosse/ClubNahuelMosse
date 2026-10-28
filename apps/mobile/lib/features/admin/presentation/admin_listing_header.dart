import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// Header of the list: the count and, if there is nothing, [emptyText].
List<Widget> adminListingHeader(
  Palette p, {
  required String count,
  required bool empty,
  required String emptyText,
}) => [
  Text(count, style: Texts.overline.copyWith(color: p.textMuted)),
  const SizedBox(height: Spacing.s16),
  if (empty)
    Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s40),
      child: Text(
        emptyText,
        textAlign: TextAlign.center,
        style: Texts.body.copyWith(color: p.textSecondary),
      ),
    ),
];
