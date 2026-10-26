/// Los errores por campo (`campo: mensaje`) que manda el servidor en el cuerpo de una
/// respuesta rechazada; vacío si no vienen o no son de texto.
Map<String, String> erroresDeCampo(Object? cuerpo) {
  if (cuerpo is! Map<String, Object?>) return const {};
  return switch (cuerpo['errores']) {
    final Map<String, Object?> mapa => {
      for (final MapEntry(:key, :value) in mapa.entries)
        if (value is String) key: value,
    },
    _ => const {},
  };
}
