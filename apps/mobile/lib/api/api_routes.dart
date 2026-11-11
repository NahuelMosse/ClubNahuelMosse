/// A route of the API that the app asks for: method and template
/// (`/bookings/{booking_id}`), with the same names as the contract the API publishes.
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

/// Everything the app asks the API. A test compares it with the published contract and
/// the client fails in debug if it asks for something that is not here.
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

/// Whether the app declares asking for [method] [request] (the `?a=b` query does not
/// count).
bool isRouteDeclared(String method, String request) {
  final path = Uri.parse(request).path;
  final segments = path.split('/');
  return apiRoutes.any((r) => r.matches(method, segments));
}
