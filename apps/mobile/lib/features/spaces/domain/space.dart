// kit-shape: a screen or error family kept with its private parts.
import '../../../common/price_format.dart';

class SpaceKind {
  const SpaceKind(this.key, this.name);
  final String key;
  final String name;
}

class Sport {
  const Sport(this.key, this.name, this.kinds);
  final String key;
  final String name;
  final List<SpaceKind> kinds;
}

/// Los deportes y sus tipos de cancha, como los define la API.
class Catalog {
  const Catalog(this.sports);
  final List<Sport> sports;

  Sport? sport(String key) => sports.where((d) => d.key == key).firstOrNull;

  /// «Fútbol 5», o «Tenis · Polvo de ladrillo» si el tipo no nombra al deporte.
  String readableKind(String sport, String kind) {
    final d = this.sport(sport);
    final t = d?.kinds.where((t) => t.key == kind).firstOrNull;
    if (d == null || t == null) return '$sport $kind';
    return t.name.startsWith(d.name) ? t.name : '${d.name} · ${t.name}';
  }

  /// La etiqueta de la cancha: «Fútbol 5», o sólo «Tenis» si el tipo no nombra al
  /// deporte («Polvo de ladrillo»).
  String shortKind(String sport, String kind) {
    final d = this.sport(sport);
    final t = d?.kinds.where((t) => t.key == kind).firstOrNull;
    if (d == null || t == null) return sport;
    return t.name.startsWith(d.name) ? t.name : d.name;
  }

  static Catalog? fromJson(Object? json) {
    if (json case {'sports': final List<Object?> sports}) {
      final parsed = [
        for (final d in sports)
          if (d case {
            'key': final String key,
            'name': final String name,
            'kinds': final List<Object?> kinds,
          })
            Sport(key, name, [
              for (final t in kinds)
                if (t case {'key': final String c, 'name': final String n})
                  SpaceKind(c, n),
            ]),
      ];
      if (parsed.length == sports.length) return Catalog(parsed);
    }
    return null;
  }
}

/// Un espacio deportivo activo, como lo devuelve la API.
class Space {
  const Space({
    required this.id,
    required this.name,
    required this.venueId,
    required this.venue,
    required this.sport,
    required this.kind,
    required this.number,
    required this.covered,
    required this.lit,
    required this.pricePerHour,
  });

  final String id;

  /// El nombre compuesto del enunciado, por ejemplo `Moron_Rivadavia_19850_Futbol_F5_1`.
  final String name;
  final String venueId;
  final String venue;
  final String sport;
  final String kind;

  /// El número correlativo de ese tipo en esa sede: «Cancha 2».
  final int number;
  final bool covered;
  final bool lit;
  final int pricePerHour;

  String get condition => covered ? 'Techada' : 'Al aire libre';

  String get lighting => lit ? 'Iluminada' : 'Sin iluminación';

  /// «Fútbol 5 · Al aire libre · $ 38.000 por hora».
  String description(Catalog catalog) =>
      '${catalog.readableKind(sport, kind)} · $condition · '
      '${formatPesos(pricePerHour)} por hora';

  static Space? fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'venue_id': final String venueId,
      'venue': final String venue,
      'sport': final String sport,
      'kind': final String kind,
      'number': final int number,
      'covered': final bool covered,
      'lit': final bool lit,
      'price_per_hour': final int price,
    }) {
      return Space(
        id: id,
        name: name,
        venueId: venueId,
        venue: venue,
        sport: sport,
        kind: kind,
        number: number,
        covered: covered,
        lit: lit,
        pricePerHour: price,
      );
    }
    return null;
  }

  /// Los espacios de un cuerpo `{'spaces': [...]}`, o `null` si alguno no se puede leer.
  static List<Space>? listFromBody(Map<String, Object?> cuerpo) {
    if (cuerpo case {'spaces': final List<Object?> items}) {
      final parsed = [for (final e in items) Space.fromJson(e)];
      if (!parsed.contains(null)) return [...parsed.nonNulls];
    }
    return null;
  }
}
