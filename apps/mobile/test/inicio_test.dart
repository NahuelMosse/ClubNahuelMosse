import 'package:clubnahuelmosse/comun/zona_club.dart';
import 'package:clubnahuelmosse/inicio/saludo_de_inicio.dart';
import 'package:clubnahuelmosse/comun/marcador.dart';
import 'package:clubnahuelmosse/espacios/espacios.dart';
import 'package:clubnahuelmosse/inicio/pantalla_inicio.dart';
import 'package:clubnahuelmosse/reservas/reservas.dart';
import 'package:clubnahuelmosse/sedes/sedes.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

Finder _enElMarcador(String texto) =>
    find.descendant(of: find.byType(Marcador), matching: find.text(texto));

void main() {
  setUpAll(cargarFuentes);

  testWidgets('el Home muestra el saludo, el conteo y la próxima reserva', (
    tester,
  ) async {
    await montar(
      tester,
      inicioFalso(SesionFalsa(perfilUsuario)),
      tema: temaOscuro,
    );

    expect(
      find.text(SaludoDeInicio.paraLaHora(ahoraEnElClub())),
      findsOneWidget,
    );
    expect(find.text('Nahuel'), findsOneWidget);
    expect(_enElMarcador('04'), findsOneWidget);
    expect(_enElMarcador('SEDES'), findsOneWidget);
    expect(_enElMarcador('17'), findsOneWidget);
    expect(_enElMarcador('CANCHAS'), findsOneWidget);
    expect(_enElMarcador('PRÓXIMAS'), findsOneWidget);
    expect(find.text('TU PRÓXIMA RESERVA'), findsOneWidget);
    expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsOneWidget);
    expect(find.text('MODIFICAR'), findsOneWidget);
    expect(find.text('CANCELAR'), findsOneWidget);
    expect(find.text('Fútbol'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Buscar cancha'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Buscar cancha'), findsOneWidget);
  });

  testWidgets('sin reservas próximas no aparece el bloque de la próxima', (
    tester,
  ) async {
    await montar(
      tester,
      inicioFalso(SesionFalsa(perfilUsuario), conReserva: false),
      tema: temaOscuro,
    );

    expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
    expect(find.text('TU PRÓXIMA RESERVA'), findsNothing);
    expect(find.text('VER TODAS →'), findsNothing);
  });

  testWidgets('con una sola sede y una cancha el marcador cuenta 01 y 01', (
    tester,
  ) async {
    await montar(
      tester,
      inicioFalso(SesionFalsa(perfilUsuario), unaSede: true),
      tema: temaOscuro,
    );

    expect(_enElMarcador('01'), findsNWidgets(3));
    expect(_enElMarcador('SEDES'), findsOneWidget);
    expect(_enElMarcador('CANCHAS'), findsOneWidget);
  });

  testWidgets(
    'con el texto al 200 % en 360 px nada se desborda al recorrerlo',
    (tester) async {
      for (final tema in [temaOscuro, temaClaro]) {
        await montar(
          tester,
          inicioFalso(SesionFalsa(perfilUsuario)),
          tema: tema,
          tamano: const Size(360, 800),
          escalaTexto: 2,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('TU PRÓXIMA RESERVA'), findsOneWidget);

        final lista = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.text('Ver sedes'),
          300,
          scrollable: lista,
        );
        await tester.drag(lista, const Offset(0, -2000));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Horarios y canchas de cada una'), findsOneWidget);
      }
    },
  );

  testWidgets('si la lectura falla avisa y deja reintentar', (tester) async {
    final sesion = SesionFalsa(perfilUsuario);
    final api = apiRutas({});
    await montar(
      tester,
      PantallaInicio(
        sesion: sesion,
        reservas: Reservas(api: api, sesion: sesion),
        espacios: Espacios(api: api, sesion: sesion),
        sedes: Sedes(api: api, sesion: sesion),
      ),
      tema: temaOscuro,
    );

    expect(find.text('Error del servidor'), findsOneWidget);
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();

    expect(find.text('REINTENTAR'), findsOneWidget);
    expect(find.text('TU PRÓXIMA RESERVA'), findsNothing);
    expect(find.textContaining('disponibilidad en tiempo real'), findsNothing);
  });
}
