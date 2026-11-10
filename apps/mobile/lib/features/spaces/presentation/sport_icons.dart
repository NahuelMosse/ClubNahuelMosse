import 'package:flutter/material.dart';

/// The icon of each sport of the catalog, on the cards and in the filters.
IconData sportIcon(String sport) => switch (sport) {
  'Futbol' => Icons.sports_soccer_rounded,
  'Tenis' || 'Padel' => Icons.sports_tennis_rounded,
  'Voley' => Icons.sports_volleyball_rounded,
  'Basquet' => Icons.sports_basketball_rounded,
  'Hockey' => Icons.sports_hockey_rounded,
  'Golf' => Icons.golf_course_rounded,
  _ => Icons.sports_rounded,
};
