import 'package:flutter/material.dart';

/// El ícono de cada deporte del catálogo, en las tarjetas y en los filtros.
IconData sportIcon(String sport) => switch (sport) {
  'Futbol' => Icons.sports_soccer_rounded,
  'Tenis' || 'Padel' => Icons.sports_tennis_rounded,
  'Voley' => Icons.sports_volleyball_rounded,
  'Basquet' => Icons.sports_basketball_rounded,
  'Hockey' => Icons.sports_hockey_rounded,
  'Golf' => Icons.golf_course_rounded,
  _ => Icons.sports_rounded,
};
