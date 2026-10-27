import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../comun/formato_precio.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/sesion.dart';
import 'campo_de_alta_de_espacio.dart';
import 'formulario_espacio.dart';

/// Lo que quedó pendiente de avisar tras un pedido: la sesión venció, o falló la red.
typedef FalloDeAlta = ({bool vencida, Object? fallo});

/// Lo que se eligió y se escribió en el alta de un espacio, con el nombre compuesto que
/// calcula la API y los pedidos que lo cargan y lo guardan. Avisa cada cambio.
class FormularioDeAltaDeEspacio extends ChangeNotifier {
  FormularioDeAltaDeEspacio({required this.espacios, required this.sedes}) {
    var anterior = precio.text;
    precio.addListener(() {
      if (precio.text == anterior) return;
      anterior = precio.text;
      erroresDelServidor.remove(CampoDeAltaDeEspacio.precio);
      notifyListeners();
    });
  }

  final Espacios espacios;
  final Sedes sedes;

  List<Sede>? opcionesDeSede;
  Catalogo? catalogo;
  bool cargando = true;

  Sede? sede;
  Deporte? deporte;
  TipoDeCancha? tipo;
  bool? techada;
  bool? iluminada;
  final precio = TextEditingController();

  /// El nombre compuesto y el número que calculó la API para la sede, el deporte y el tipo
  /// elegidos.
  (String, int)? sugerido;
  bool calculando = false;
  int _pedidoDeNombre = 0;

  /// Por qué no se pudo calcular el nombre, para ofrecer reintentar.
  Object? falloDelNombre;

  final erroresDelServidor = <CampoDeAltaDeEspacio, String>{};
  String? aviso;
  bool intentoGuardar = false;
  bool enviando = false;
  final claveDelAviso = GlobalKey();
  bool _cerrado = false;

  @override
  void notifyListeners() {
    if (!_cerrado) super.notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    precio.dispose();
    super.dispose();
  }

  bool _vigente(int pedido) => !_cerrado && pedido == _pedidoDeNombre;

  bool get puedeCalcularElNombre =>
      sede != null && deporte != null && tipo != null;

  /// Carga el catálogo y las sedes; devuelve por qué falló, o `null` si salió bien.
  Future<FalloDeAlta?> cargar() async {
    cargando = true;
    notifyListeners();
    Object? fallo;
    var vencida = false;
    try {
      final catalogoCargado = await espacios.catalogo();
      final sedesCargadas = await sedes.activas();
      if (_cerrado) return null;
      catalogo = catalogoCargado;
      opcionesDeSede = sedesCargadas;
      cargando = false;
      notifyListeners();
      return null;
    } on SesionVencida {
      vencida = true;
    } on FalloDeRed catch (e) {
      fallo = e;
    }
    if (_cerrado) return null;
    cargando = false;
    notifyListeners();
    return (vencida: vencida, fallo: fallo);
  }

  /// Pide a la API el nombre del próximo espacio; si mientras tanto cambió la elección, la
  /// respuesta vieja se descarta. Devuelve si hay que avisar que la sesión venció.
  Future<bool> calcularNombre() async {
    final sedeElegida = sede;
    final deporteElegido = deporte;
    final tipoElegido = tipo;
    final pedido = ++_pedidoDeNombre;
    sugerido = null;
    falloDelNombre = null;
    calculando = puedeCalcularElNombre;
    notifyListeners();
    if (sedeElegida == null || deporteElegido == null || tipoElegido == null) {
      return false;
    }
    var vencida = false;
    try {
      final nombre = await espacios.nombreSugerido(
        sedeId: sedeElegida.id,
        deporte: deporteElegido.clave,
        tipo: tipoElegido.clave,
      );
      if (_vigente(pedido)) {
        sugerido = nombre;
        notifyListeners();
      }
    } on EspacioRechazado catch (e) {
      if (_vigente(pedido)) mostrarErrores(e.errores);
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      _fallarElNombre(pedido, e);
    } on ErrorDelServidor catch (e) {
      _fallarElNombre(pedido, e);
    } finally {
      if (_vigente(pedido)) {
        calculando = false;
        notifyListeners();
      }
    }
    return vencida && _vigente(pedido);
  }

  void _fallarElNombre(int pedido, Object error) {
    if (!_vigente(pedido)) return;
    falloDelNombre = error;
    notifyListeners();
  }

  void mostrarErrores(Map<String, String> errores) {
    for (final MapEntry(:key, :value) in errores.entries) {
      final campo = CampoDeAltaDeEspacio.values
          .where((c) => c.clave == key)
          .firstOrNull;
      if (campo != null) erroresDelServidor[campo] = value;
    }
    notifyListeners();
  }

  String? errorDeRegla(CampoDeAltaDeEspacio campo) {
    switch (campo) {
      case CampoDeAltaDeEspacio.sede:
        return sede == null ? obligatorio : null;
      case CampoDeAltaDeEspacio.deporte:
        return deporte == null ? obligatorio : null;
      case CampoDeAltaDeEspacio.tipo:
        return tipo == null ? obligatorio : null;
      case CampoDeAltaDeEspacio.condicion:
        return techada == null ? obligatorio : null;
      case CampoDeAltaDeEspacio.iluminacion:
        return iluminada == null ? obligatorio : null;
      case CampoDeAltaDeEspacio.precio:
        return errorDePrecio(precio.text);
    }
  }

  String? error(CampoDeAltaDeEspacio campo) =>
      erroresDelServidor[campo] ??
      (intentoGuardar ? errorDeRegla(campo) : null);

  bool get completo =>
      CampoDeAltaDeEspacio.values.every((c) => errorDeRegla(c) == null) &&
      erroresDelServidor.isEmpty &&
      sugerido != null;

  String get faltaParaElNombre {
    if (sede == null && deporte == null && tipo == null) {
      return 'Completá sede, deporte y tipo';
    }
    if (sede == null) return 'Falta la sede';
    if (deporte == null) return 'Falta el deporte';
    return 'Falta el tipo de cancha';
  }

  Future<bool> elegirSede(Sede elegida) {
    sede = elegida;
    erroresDelServidor.remove(CampoDeAltaDeEspacio.sede);
    notifyListeners();
    return calcularNombre();
  }

  Future<bool> elegirDeporte(Deporte elegido) {
    deporte = elegido;
    // Los tipos dependen del deporte: el que había elegido ya no corresponde.
    tipo = null;
    erroresDelServidor
      ..remove(CampoDeAltaDeEspacio.deporte)
      ..remove(CampoDeAltaDeEspacio.tipo);
    notifyListeners();
    return calcularNombre();
  }

  Future<bool> elegirTipo(TipoDeCancha elegido) {
    tipo = elegido;
    erroresDelServidor.remove(CampoDeAltaDeEspacio.tipo);
    notifyListeners();
    return calcularNombre();
  }

  void elegirSiNo(CampoDeAltaDeEspacio campo, {required bool valor}) {
    if (campo == CampoDeAltaDeEspacio.condicion) {
      techada = valor;
    } else {
      iluminada = valor;
    }
    erroresDelServidor.remove(campo);
    notifyListeners();
  }

  void marcarIntentoDeGuardar() {
    intentoGuardar = true;
    notifyListeners();
  }

  void cerrarAviso() {
    aviso = null;
    notifyListeners();
  }

  /// Da de alta el espacio con lo que se ve ahora, que tiene que estar [completo]. Si se
  /// crea, llama a [alCrear] y devuelve `null`; si no, devuelve qué falta avisar.
  Future<FalloDeAlta?> enviar({required void Function(Espacio) alCrear}) async {
    enviando = true;
    aviso = null;
    notifyListeners();
    Object? fallo;
    var vencida = false;
    try {
      alCrear(
        await espacios.darDeAlta(
          sedeId: sede!.id,
          deporte: deporte!.clave,
          tipo: tipo!.clave,
          techada: techada!,
          iluminada: iluminada!,
          precioPorHora: leerPrecio(precio.text)!,
          numero: sugerido!.$2,
        ),
      );
      return null;
    } on NombreOcupado catch (e) {
      if (!_cerrado) _avisarNombreOcupado(e);
    } on EspacioRechazado catch (e) {
      if (!_cerrado) mostrarErrores(e.errores);
    } on SesionVencida {
      vencida = true;
    } on FalloDeRed catch (e) {
      fallo = e;
    } finally {
      if (!_cerrado) {
        enviando = false;
        notifyListeners();
      }
    }
    if (_cerrado) return null;
    return (vencida: vencida, fallo: fallo);
  }

  void _avisarNombreOcupado(NombreOcupado e) {
    aviso = e.mensaje;
    sugerido = (e.nombre, e.numero);
    notifyListeners();
    // El aviso está arriba del formulario: se lo trae a la vista.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contexto = claveDelAviso.currentContext;
      if (contexto != null && contexto.mounted) {
        Scrollable.ensureVisible(contexto);
      }
    });
  }
}
