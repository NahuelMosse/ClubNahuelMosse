/// The per-field errors (`field: message`) the server sends in the body of a rejected
/// response; empty if they are missing or are not text.
Map<String, String> fieldErrors(Object? body) {
  if (body is! Map<String, Object?>) return const {};
  return switch (body['errores']) {
    final Map<String, Object?> errors => {
      for (final MapEntry(:key, :value) in errors.entries)
        if (value is String) key: value,
    },
    _ => const {},
  };
}
