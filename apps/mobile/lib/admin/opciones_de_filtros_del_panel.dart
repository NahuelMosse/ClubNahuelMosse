import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';

/// Las sedes y el catálogo para los filtros: los que ya se tenían, o los que se piden ahora.
/// Si el servidor falla, queda lo que ya había y el panel abre sin esas opciones.
Future<(List<Sede>?, Catalogo?)> opcionesDeFiltrosDelPanel(
  Sedes sedes,
  Espacios espacios, {
  required List<Sede>? sedesActivas,
  required Catalogo? catalogo,
}) async {
  var activas = sedesActivas;
  var elCatalogo = catalogo;
  try {
    activas ??= await sedes.activas();
    elCatalogo ??= await espacios.catalogo();
  } on Exception {
    // Sin la lista, el panel abre sin esas opciones; el resto de los filtros sigue.
  }
  return (activas, elCatalogo);
}
