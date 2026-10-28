import 'dart:io';

import 'package:clubnahuelmosse/common/field_errors.dart';
import 'package:flutter_test/flutter_test.dart';

/// Old file name (in `lib/comun`, `lib/tema` or the root of `lib`) to its new path under `lib/`.
const _renamed = {
  'comun/acciones_de_resultado.dart': 'common/result_actions.dart',
  'comun/apariencia.dart': 'common/appearance.dart',
  'comun/avatar.dart': 'common/avatar.dart',
  'comun/barra_fija.dart': 'common/fixed_bar.dart',
  'comun/barra_inferior.dart': 'common/bottom_bar.dart',
  'comun/barra_superior.dart': 'common/top_bar.dart',
  'comun/boton.dart': 'common/button.dart',
  'comun/cabecera_de_ficha.dart': 'common/profile_header.dart',
  'comun/calendario.dart': 'common/calendar.dart',
  'comun/campo_texto.dart': 'common/text_field.dart',
  'comun/carga_de_lista.dart': 'common/list_loading.dart',
  'comun/chip_elegible.dart': 'common/selectable_chip.dart',
  'comun/configuracion.dart': 'common/config.dart',
  'comun/detalle_de_resultado.dart': 'common/result_detail.dart',
  'comun/dialogo_error.dart': 'common/error_dialog.dart',
  'comun/dorsal.dart': 'common/bib.dart',
  'comun/en_curso.dart': 'common/in_progress.dart',
  'comun/entrada_de_campo.dart': 'common/field_input.dart',
  'comun/errores_de_campo.dart': 'common/field_errors.dart',
  'comun/errores_no_manejados.dart': 'common/unhandled_errors.dart',
  'comun/estado_vacio.dart': 'common/empty_state.dart',
  'comun/etiqueta.dart': 'common/label.dart',
  'comun/faltantes.dart': 'common/missing_fields.dart',
  'comun/fechas.dart': 'common/dates.dart',
  'comun/ficha_socio.dart': 'common/member_profile.dart',
  'comun/formato_fecha.dart': 'common/date_format.dart',
  'comun/formato_precio.dart': 'common/price_format.dart',
  'comun/formulario_contrasena.dart': 'common/password_form.dart',
  'comun/foto_de_ficha.dart': 'common/profile_photo.dart',
  'comun/horas_de_la_linea.dart': 'common/timeline_hours.dart',
  'comun/identidad_de_ficha.dart': 'common/profile_identity.dart',
  'comun/insignia.dart': 'common/badge.dart',
  'comun/insignia_elegido.dart': 'common/selected_badge.dart',
  'comun/isotipo.dart': 'common/logo_mark.dart',
  'comun/linea_del_dia.dart': 'common/day_timeline.dart',
  'comun/marcador.dart': 'common/marker.dart',
  'comun/marco_de_tarjeta.dart': 'common/card_frame.dart',
  'comun/movimiento.dart': 'common/motion.dart',
  'comun/pie_de_tile.dart': 'common/tile_footer.dart',
  'comun/rejilla_de_opciones.dart': 'common/options_grid.dart',
  'comun/reloj.dart': 'common/clock.dart',
  'comun/reserva_pendiente.dart': 'common/pending_booking.dart',
  'comun/resultado.dart': 'common/result.dart',
  'comun/selector.dart': 'common/selector.dart',
  'comun/snackbar.dart': 'common/snackbar.dart',
  'comun/tarjeta_reserva.dart': 'common/booking_card.dart',
  'comun/tile_deporte.dart': 'common/sport_tile.dart',
  'comun/transiciones.dart': 'common/transitions.dart',
  'comun/troquel.dart': 'common/die_cut.dart',
  'comun/valor_del_selector.dart': 'common/selector_value.dart',
  'comun/zona_club.dart': 'common/club_timezone.dart',
  'tema/tema.dart': 'theme/theme.dart',
  'tema/tokens.dart': 'theme/tokens.dart',
  'redireccion.dart': 'redirect.dart',
};

/// Spanish words that must not survive as identifier parts or in comments of the base.
const _spanishWords = {
  'reserva',
  'reservas',
  'sede',
  'sedes',
  'espacio',
  'espacios',
  'fecha',
  'fechas',
  'precio',
  'tarjeta',
  'boton',
  'campo',
  'campos',
  'errores',
  'contrasena',
  'correo',
  'nombre',
  'apellido',
  'usuario',
  'deporte',
  'dia',
  'dias',
  'lista',
  'cargando',
  'vacio',
  'barra',
  'cabecera',
  'ficha',
  'socio',
  'tema',
  'rutas',
  'ruta',
  'valor',
  'resultado',
  'carga',
  'elegible',
  'elegido',
  'formato',
  'formulario',
  'inicio',
  'fin',
  'hoy',
  'cuerpo',
  'texto',
  'pantalla',
  'cancelar',
  'cancelada',
  'activa',
  'pendiente',
  'obligatorio',
  'faltantes',
  'identidad',
  'foto',
  'linea',
  'rejilla',
  'reloj',
  'zona',
  'movimiento',
  'transiciones',
  'apariencia',
  'configuracion',
  'mayor',
  'menor',
  'redireccion',
  'sesion',
  'invitado',
  'cuenta',
  'miembro',
  'legible',
  'leer',
  'normalizar',
  'validar',
  'mostrar',
  'elegir',
  'cargar',
  'guardar',
  'mismo',
  'misma',
  'cada',
  'para',
  'que',
  'los',
  'las',
  'del',
  'una',
  'con',
  'sin',
  'por',
  'como',
  'cuando',
  'desde',
  'hasta',
};

/// app, main and redirect call symbols of modules that are translated in their own cards.
Set<String> _notYetTranslated(String path) =>
    RegExp(r'lib[\\/](app|main|redirect)\.dart$').hasMatch(path)
    ? {
        'Sesion',
        'sesion',
        'Sedes',
        'sedes',
        'Espacios',
        'espacios',
        'Reservas',
        'reservas',
        'Rutas',
        'ruta',
        'apariencia',
        'pendiente',
        'inicio',
        'cada',
        'usuario',
        'reserva',
        'Desde', 'Del', 'Por', 'Las', 'Aviso', //
      }
    : path.endsWith('error_dialog.dart') ||
          path.endsWith('network_failure.dart')
    ? {
        'Del',
        'Sin',
      } // ErrorDelServidor, SinConexion: the api module's own symbols
    : {};

String _lib(String path) => 'lib/$path';

String _stripStrings(String line) => line.replaceAll(
  RegExp(r'''r?'(?:[^'\\]|\\.)*'|r?"(?:[^"\\]|\\.)*"'''),
  "''",
);

Set<String> _spanishIn(String text) {
  final found = <String>{};
  for (final line in text.split('\n')) {
    final commentAt = line.indexOf('//');
    final code = _stripStrings(
      commentAt < 0 ? line : line.substring(0, commentAt),
    );
    // The «quoted» texts of a comment are UI text, which stays in Spanish.
    final comment = commentAt < 0
        ? ''
        : line.substring(commentAt).replaceAll(RegExp('«[^»]*»'), '');
    final parts = RegExp(
      r'[A-Z]?[a-z]+|[A-Z]+(?![a-z])',
    ).allMatches(code).map((m) => m[0]!);
    for (final p in parts) {
      if (_spanishWords.contains(p.toLowerCase())) found.add(p);
    }
    for (final w in RegExp(
      r'[A-Za-zÁÉÍÓÚÑáéíóúñ]+',
    ).allMatches(comment).map((m) => m[0]!)) {
      if (_spanishWords.contains(w.toLowerCase()) ||
          RegExp(r'[áéíóúñÁÉÍÓÚÑ]').hasMatch(w)) {
        found.add(w);
      }
    }
  }
  return found;
}

List<File> _baseFiles() => [
  for (final dir in ['common', 'theme'])
    if (Directory(_lib(dir)).existsSync())
      ...Directory(_lib(dir)).listSync(recursive: true).whereType<File>(),
  for (final f in ['app.dart', 'main.dart', 'redirect.dart'])
    if (File(_lib(f)).existsSync()) File(_lib(f)),
].where((f) => f.path.endsWith('.dart')).toList();

void main() {
  test(
    'la base de la app se llama como dice el glosario @ENG-08-S1 @assumption:ENG-08-ASM-03',
    () {
      final missing = [
        for (final e in _renamed.entries)
          if (!File(_lib(e.value)).existsSync()) e.value,
      ];
      final leftovers = [
        for (final old in ['comun', 'tema'])
          if (Directory(_lib(old)).existsSync()) old,
        if (File(_lib('redireccion.dart')).existsSync()) 'redireccion.dart',
      ];
      expect(missing, isEmpty);
      expect(leftovers, isEmpty);
    },
  );

  test(
    'los nombres y comentarios de la base de la app están en inglés @ENG-08-S2',
    () {
      final files = _baseFiles();
      expect(files, isNotEmpty);
      final spanish = {
        for (final f in files)
          f.path: _spanishIn(
            f.readAsStringSync(),
          ).difference(_notYetTranslated(f.path)),
      }..removeWhere((_, v) => v.isEmpty);
      expect(spanish, isEmpty);
    },
  );

  test(
    'ningún test importa comun, tema o redireccion @assumption:ENG-08-ASM-04',
    () {
      final old = RegExp(r'''clubnahuelmosse/(comun|tema|redireccion)\b''');
      final offenders = [
        for (final f in Directory(
          'test',
        ).listSync(recursive: true).whereType<File>())
          if (f.path.endsWith('.dart') &&
              !f.path.endsWith('base_en_ingles_test.dart') &&
              old.hasMatch(f.readAsStringSync()))
            f.path,
      ];
      expect(offenders, isEmpty);
    },
  );

  test('la base de la app no toca apps/api @assumption:ENG-08-ASM-05', () {
    // The api cards of the integrated branch change apps/api in their own commits;
    // here only the working tree is checked.
    final dirty = Process.runSync('git', [
      'status',
      '--porcelain',
      '--',
      '../api',
    ]);
    expect('${dirty.stdout}'.trim(), isEmpty);
  });

  test(
    'los errores por campo que manda la API con la clave errores se siguen mostrando @assumption:ENG-08-ASM-06',
    () {
      expect(
        fieldErrors({
          'errores': {'dni': 'El DNI ya existe', 'edad': 3},
        }),
        {'dni': 'El DNI ya existe'},
      );
      expect(fieldErrors('texto'), isEmpty);
      expect(
        fieldErrors({
          'errors': {'dni': 'x'},
        }),
        isEmpty,
      );
    },
  );
}
