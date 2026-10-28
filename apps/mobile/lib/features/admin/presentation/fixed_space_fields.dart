import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import 'read_only_field.dart';

/// The venue, sport and type of [space], shown but unchangeable; the sport and type by
/// name if there is a [catalog], otherwise by key.
List<Widget> fixedSpaceFields(Space space, Catalog? catalog) {
  final sport = catalog?.sport(space.sport)?.name ?? space.sport;
  final type = catalog?.shortKind(space.sport, space.kind) ?? space.kind;
  return [
    ReadOnlyField(label: 'SEDE', semanticLabel: 'Sede', value: space.venue),
    const SizedBox(height: Spacing.s12),
    ReadOnlyField(label: 'DEPORTE', semanticLabel: 'Deporte', value: sport),
    const SizedBox(height: Spacing.s12),
    ReadOnlyField(label: 'TIPO', semanticLabel: 'Tipo', value: type),
    const SizedBox(height: Spacing.s12),
  ];
}
