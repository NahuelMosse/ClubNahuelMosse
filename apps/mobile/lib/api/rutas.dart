/// Una ruta de la API que la app pide: método y plantilla (`/reservas/{reserva_id}`; `/reservas` queda en castellano porque es el contrato de la API),
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
  ApiRoute('POST', '/registro'),
  ApiRoute('GET', '/yo'),
  ApiRoute('PUT', '/yo'),
  ApiRoute('DELETE', '/yo'),
  ApiRoute('PUT', '/yo/contrasena'),
  ApiRoute('POST', '/recuperacion'),
  ApiRoute('POST', '/recuperacion/consulta'),
  ApiRoute('PUT', '/recuperacion'),
  ApiRoute('GET', '/sedes'),
  ApiRoute('POST', '/sedes'),
  ApiRoute('PUT', '/sedes/{sede_id}'),
  ApiRoute('DELETE', '/sedes/{sede_id}'),
  ApiRoute('GET', '/espacios/catalogo'),
  ApiRoute('GET', '/espacios'),
  ApiRoute('POST', '/espacios'),
  ApiRoute('GET', '/espacios/nombre'),
  ApiRoute('PUT', '/espacios/{espacio_id}'),
  ApiRoute('DELETE', '/espacios/{espacio_id}'),
  ApiRoute('GET', '/espacios/{espacio_id}/horarios'),
  ApiRoute('GET', '/espacios/disponibles'),
  ApiRoute('GET', '/reservas'),
  ApiRoute('POST', '/reservas'),
  ApiRoute('POST', '/reservas/{reserva_id}/cancelar'),
  ApiRoute('POST', '/reservas/{reserva_id}/modificar'),
  ApiRoute('GET', '/reservas/todas'),
  ApiRoute('GET', '/reservas/todas/{reserva_id}'),
  ApiRoute('POST', '/reservas/{reserva_id}/anular'),
  ApiRoute('PUT', '/dispositivos'),
  ApiRoute('POST', '/dispositivos/baja'),
  ApiRoute('GET', '/notificaciones'),
  ApiRoute('POST', '/notificaciones/leer-todas'),
  ApiRoute('POST', '/notificaciones/{notificacion_id}/leer'),
];

/// Si la app declara pedir [metodo] [pedido] (la consulta `?a=b` no cuenta).
bool rutaDeclarada(String metodo, String pedido) {
  final camino = Uri.parse(pedido).path;
  final segmentos = camino.split('/');
  return rutasDeLaApi.any((r) => r.coincideCon(metodo, segmentos));
}
