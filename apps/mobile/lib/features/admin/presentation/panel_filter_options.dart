// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/spaces.dart';
import '../../venues/domain/venue.dart';
import '../../venues/presentation/venues.dart';

/// The venues and the catalog for the filters: the ones already held, or the ones requested now.
/// If the server fails, what was already there stays and the panel opens without those options.
Future<(List<Venue>?, Catalog?)> panelFilterOptions(
  Venues venues,
  Spaces spaces, {
  required List<Venue>? activeVenues,
  required Catalog? catalog,
}) async {
  var active = activeVenues;
  var theCatalog = catalog;
  try {
    active ??= await venues.repository.active();
    theCatalog ??= await spaces.repository.catalog();
  } on Exception {
    // Without the list, the panel opens without those options; the other filters keep working.
  }
  return (active, theCatalog);
}
