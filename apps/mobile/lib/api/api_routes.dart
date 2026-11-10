/// Una ruta de la API que la app pide: método y plantilla (`/bookings/{booking_id}`),
/// con los mismos nombres que el contrato que publica la API.
class ApiRoute {
  const ApiRoute(this.method, this.route);

  final String method;
  final String route;

  bool matches(String requestedMethod, List<String> segments) {
    if (method != requestedMethod) return false;
    final template = route.split('/');
    if (template.length != segments.length) return false;
    for (var i = 0; i < template.length; i++) {
      final part = template[i];
      final isParameter = part.startsWith('{') && part.endsWith('}');
      if (isParameter ? segments[i].isEmpty : part != segments[i]) {
        return false;
      }
    }
    return true;
  }
}

/// Todo lo que la app le pide a la API. Un test lo compara con el contrato publicado y
/// el cliente falla en debug si pide algo que no está acá.
const apiRoutes = <ApiRoute>[
  ApiRoute('POST', '/register'),
  ApiRoute('GET', '/me'),
  ApiRoute('PUT', '/me'),
  ApiRoute('DELETE', '/me'),
  ApiRoute('PUT', '/me/password'),
  ApiRoute('POST', '/password-recovery'),
  ApiRoute('POST', '/password-recovery/check'),
  ApiRoute('PUT', '/password-recovery'),
  ApiRoute('GET', '/venues'),
  ApiRoute('POST', '/venues'),
  ApiRoute('PUT', '/venues/{venue_id}'),
  ApiRoute('DELETE', '/venues/{venue_id}'),
  ApiRoute('GET', '/spaces/catalog'),
  ApiRoute('GET', '/spaces'),
  ApiRoute('POST', '/spaces'),
  ApiRoute('GET', '/spaces/name'),
  ApiRoute('PUT', '/spaces/{space_id}'),
  ApiRoute('DELETE', '/spaces/{space_id}'),
  ApiRoute('GET', '/spaces/{space_id}/slots'),
  ApiRoute('GET', '/spaces/available'),
  ApiRoute('GET', '/bookings'),
  ApiRoute('POST', '/bookings'),
  ApiRoute('POST', '/bookings/{booking_id}/cancel'),
  ApiRoute('POST', '/bookings/{booking_id}/modify'),
  ApiRoute('GET', '/bookings/all'),
  ApiRoute('GET', '/bookings/all/{booking_id}'),
  ApiRoute('POST', '/bookings/{booking_id}/void'),
  ApiRoute('PUT', '/devices'),
  ApiRoute('POST', '/devices/unregister'),
  ApiRoute('GET', '/notifications'),
  ApiRoute('POST', '/notifications/read-all'),
  ApiRoute('POST', '/notifications/{notification_id}/read'),
];

/// Si la app declara pedir [method] [request] (la consulta `?a=b` no cuenta).
bool isRouteDeclared(String method, String request) {
  final path = Uri.parse(request).path;
  final segments = path.split('/');
  return apiRoutes.any((r) => r.matches(method, segments));
}
