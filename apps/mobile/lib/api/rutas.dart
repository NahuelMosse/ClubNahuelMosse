/// Una ruta de la API que la app pide: método y plantilla (`/bookings/{booking_id}`),
/// con los mismos nombres que el contrato que publica la API.
class ApiRoute {
  const ApiRoute(this.metodo, this.ruta);

  final String metodo;
  final String ruta;

  bool coincideCon(String metodoPedido, List<String> segmentos) {
    if (metodo != metodoPedido) return false;
    final plantilla = ruta.split('/');
    if (plantilla.length != segmentos.length) return false;
    for (var i = 0; i < plantilla.length; i++) {
      final parte = plantilla[i];
      final esParametro = parte.startsWith('{') && parte.endsWith('}');
      if (esParametro ? segmentos[i].isEmpty : parte != segmentos[i]) {
        return false;
      }
    }
    return true;
  }
}

/// Todo lo que la app le pide a la API. Un test lo compara con el contrato publicado y
/// el cliente falla en debug si pide algo que no está acá.
const rutasDeLaApi = <ApiRoute>[
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

/// Si la app declara pedir [metodo] [pedido] (la consulta `?a=b` no cuenta).
bool rutaDeclarada(String metodo, String pedido) {
  final camino = Uri.parse(pedido).path;
  final segmentos = camino.split('/');
  return rutasDeLaApi.any((r) => r.coincideCon(metodo, segmentos));
}
