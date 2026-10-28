/// Una ruta de la API que la app pide: método y plantilla (`/reservas/{reserva_id}`; `/reservas` queda en castellano porque es el contrato de la API),
/// con los mismos nombres que el contrato que publica la API.
class RutaDeLaApi {
  const RutaDeLaApi(this.metodo, this.ruta);

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
const rutasDeLaApi = <RutaDeLaApi>[
  RutaDeLaApi('POST', '/registro'),
  RutaDeLaApi('GET', '/yo'),
  RutaDeLaApi('PUT', '/yo'),
  RutaDeLaApi('DELETE', '/yo'),
  RutaDeLaApi('PUT', '/yo/contrasena'),
  RutaDeLaApi('POST', '/recuperacion'),
  RutaDeLaApi('POST', '/recuperacion/consulta'),
  RutaDeLaApi('PUT', '/recuperacion'),
  RutaDeLaApi('GET', '/sedes'),
  RutaDeLaApi('POST', '/sedes'),
  RutaDeLaApi('PUT', '/sedes/{sede_id}'),
  RutaDeLaApi('DELETE', '/sedes/{sede_id}'),
  RutaDeLaApi('GET', '/espacios/catalogo'),
  RutaDeLaApi('GET', '/espacios'),
  RutaDeLaApi('POST', '/espacios'),
  RutaDeLaApi('GET', '/espacios/nombre'),
  RutaDeLaApi('PUT', '/espacios/{espacio_id}'),
  RutaDeLaApi('DELETE', '/espacios/{espacio_id}'),
  RutaDeLaApi('GET', '/espacios/{espacio_id}/horarios'),
  RutaDeLaApi('GET', '/espacios/disponibles'),
  RutaDeLaApi('GET', '/reservas'),
  RutaDeLaApi('POST', '/reservas'),
  RutaDeLaApi('POST', '/reservas/{reserva_id}/cancelar'),
  RutaDeLaApi('POST', '/reservas/{reserva_id}/modificar'),
  RutaDeLaApi('GET', '/reservas/todas'),
  RutaDeLaApi('GET', '/reservas/todas/{reserva_id}'),
  RutaDeLaApi('POST', '/reservas/{reserva_id}/anular'),
  RutaDeLaApi('PUT', '/dispositivos'),
  RutaDeLaApi('POST', '/dispositivos/baja'),
  RutaDeLaApi('GET', '/notificaciones'),
  RutaDeLaApi('POST', '/notificaciones/leer-todas'),
  RutaDeLaApi('POST', '/notificaciones/{notificacion_id}/leer'),
];

/// Si la app declara pedir [metodo] [pedido] (la consulta `?a=b` no cuenta).
bool rutaDeclarada(String metodo, String pedido) {
  final camino = Uri.parse(pedido).path;
  final segmentos = camino.split('/');
  return rutasDeLaApi.any((r) => r.coincideCon(metodo, segmentos));
}
