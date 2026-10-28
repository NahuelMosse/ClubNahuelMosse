// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import '../../spaces/domain/space.dart';
import 'venue.dart';

/// Los nombres de los deportes de la sede, en el orden del catálogo.
List<String> sportsOf(Venue venue, Catalog catalog) => [
  for (final d in catalog.sports)
    if (venue.sports.contains(d.key)) d.name,
];

String spaceCountLabel(int n) => n == 1 ? '1 cancha' : '$n canchas';
