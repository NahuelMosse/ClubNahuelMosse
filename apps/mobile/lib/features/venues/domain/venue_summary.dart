// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import '../../spaces/domain/space.dart';
import 'venue.dart';

/// The names of the sports of the venue, in the order of the catalog.
List<String> sportsOf(Venue venue, Catalog catalog) => [
  for (final d in catalog.sports)
    if (venue.sports.contains(d.key)) d.name,
];
