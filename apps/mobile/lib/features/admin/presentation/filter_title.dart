import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

class FilterTitle extends StatelessWidget {
  const FilterTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Texts.overline.copyWith(color: context.palette.textMuted),
  );
}
