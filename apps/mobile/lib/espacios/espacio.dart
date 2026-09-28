import '../comun/formato_precio.dart';

class TipoDeCancha {
  const TipoDeCancha(this.clave, this.nombre);
  final String clave;
  final String nombre;
}

class Deporte {
  const Deporte(this.clave, this.nombre, this.tipos);
  final String clave;
  final String nombre;
  final List<TipoDeCancha> tipos;
}

/// Los deportes y sus tipos de cancha, como los define la API.
class Catalogo {
  const Catalogo(this.deportes);
  final List<Deporte> deportes;

  Deporte? deporte(String clave) =>
      deportes.where((d) => d.clave == clave).firstOrNull;

  /// «Fútbol 5», o «Tenis · Polvo de ladrillo» si el tipo no nombra al deporte.
  String tipoLegible(String deporte, String tipo) {
    final d = this.deporte(deporte);
    final t = d?.tipos.where((t) => t.clave == tipo).firstOrNull;
    if (d == null || t == null) return '$deporte $tipo';
    return t.nombre.startsWith(d.nombre)
        ? t.nombre
        : '${d.nombre} · ${t.nombre}';
  }

  /// La etiqueta de la cancha: «Fútbol 5», o sólo «Tenis» si el tipo no nombra al
  /// deporte («Polvo de ladrillo»).
  String tipoCorto(String deporte, String tipo) {
    final d = this.deporte(deporte);
    final t = d?.tipos.where((t) => t.clave == tipo).firstOrNull;
    if (d == null || t == null) return deporte;
    return t.nombre.startsWith(d.nombre) ? t.nombre : d.nombre;
  }

  static Catalogo? desdeJson(Object? json) {
    if (json case {'deportes': final List<Object?> deportes}) {
      final leidos = [
        for (final d in deportes)
          if (d case {
            'clave': final String clave,
            'nombre': final String nombre,
            'tipos': final List<Object?> tipos,
          })
            Deporte(clave, nombre, [
              for (final t in tipos)
                if (t case {'clave': final String c, 'nombre': final String n})
                  TipoDeCancha(c, n),
            ]),
      ];
      if (leidos.length == deportes.length) return Catalogo(leidos);
    }
    return null;
  }
}

/// Un espacio deportivo activo, como lo devuelve la API.
class Espacio {
  const Espacio({
    required this.id,
    required this.nombre,
    required this.sedeId,
    required this.sede,
    required this.deporte,
    required this.tipo,
    required this.numero,
    required this.techada,
    required this.iluminada,
    required this.precioPorHora,
  });

  final int id;

  /// El nombre compuesto del enunciado, por ejemplo `Moron_Rivadavia_19850_Futbol_F5_1`.
  final String nombre;
  final int sedeId;
  final String sede;
  final String deporte;
  final String tipo;

  /// El número correlativo de ese tipo en esa sede: «Cancha 2».
  final int numero;
  final bool techada;
  final bool iluminada;
  final int precioPorHora;

  String get condicion => techada ? 'Techada' : 'Al aire libre';

  String get iluminacion => iluminada ? 'Iluminada' : 'Sin iluminación';

  /// «Fútbol 5 · Al aire libre · $ 38.000 por hora».
  String descripcion(Catalogo catalogo) =>
      '${catalogo.tipoLegible(deporte, tipo)} · $condicion · '
      '${pesos(precioPorHora)} por hora';

  static Espacio? desdeJson(Object? json) {
    if (json case {
      'id': final int id,
      'nombre': final String nombre,
      'sede_id': final int sedeId,
      'sede': final String sede,
      'deporte': final String deporte,
      'tipo': final String tipo,
      'numero': final int numero,
      'techada': final bool techada,
      'iluminada': final bool iluminada,
      'precio_por_hora': final int precio,
    }) {
      return Espacio(
        id: id,
        nombre: nombre,
        sedeId: sedeId,
        sede: sede,
        deporte: deporte,
        tipo: tipo,
        numero: numero,
        techada: techada,
        iluminada: iluminada,
        precioPorHora: precio,
      );
    }
    return null;
  }
}
