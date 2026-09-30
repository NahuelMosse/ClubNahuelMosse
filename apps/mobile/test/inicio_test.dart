import 'package:clubnahuelmosse/espacios/espacios.dart';
import 'package:clubnahuelmosse/inicio/pantalla_inicio.dart';
import 'package:clubnahuelmosse/reservas/reservas.dart';
import 'package:clubnahuelmosse/sedes/sedes.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

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

    expect(find.text('BUENOS DÍAS,'), findsOneWidget);
    expect(find.text('Nahuel'), findsOneWidget);
    expect(
      find.text('4 sedes · 17 canchas · disponibilidad en tiempo real'),
      findsOneWidget,
    );
    expect(find.text('TU PRÓXIMA RESERVA'), findsOneWidget);
    expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsOneWidget);
    expect(find.text('MODIFICAR'), findsOneWidget);
    expect(find.text('CANCELAR'), findsOneWidget);
    expect(find.text('Fútbol'), findsOneWidget);
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

  testWidgets('con el texto al 200 % en 360 px nada se desborda', (
    tester,
  ) async {
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
    }
  });

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
