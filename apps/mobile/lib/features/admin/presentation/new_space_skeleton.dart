import 'package:flutter/material.dart';

import '../../../common/skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import 'space_form_fields.dart';

/// Height of a selector: its label, the gap and the control.
const _selectorHeight = 14 + Spacing.s8 + Spacing.controlHeight;

/// «Nuevo espacio deportivo» while its venues load: the heading and a block in the place of
/// each field and button.
class NewSpaceSkeleton extends StatelessWidget {
  const NewSpaceSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    padding: Spacing.formPagePadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...spaceFormHeading(
          context,
          AppLocalizations.of(context).adminNewSpaceHeading,
        ),
        const SkeletonZone(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Skeleton(height: _selectorHeight),
              SizedBox(height: Spacing.s12),
              Skeleton(height: _selectorHeight),
              SizedBox(height: Spacing.s12),
              Skeleton(height: _selectorHeight),
              SizedBox(height: Spacing.s12),
              Row(
                children: [
                  Expanded(child: Skeleton(height: _selectorHeight)),
                  SizedBox(width: Spacing.s12),
                  Expanded(child: Skeleton(height: _selectorHeight)),
                ],
              ),
              SizedBox(height: Spacing.s12),
              Skeleton(height: _selectorHeight),
              SizedBox(height: Spacing.s16),
              Skeleton(height: Spacing.controlHeight),
              SizedBox(height: Spacing.s16),
              Skeleton(height: Spacing.controlHeight),
              SizedBox(height: Spacing.s12),
              Skeleton(height: Spacing.controlHeight),
            ],
          ),
        ),
      ],
    ),
  );
}
