import 'package:clubnahuelmosse/common/bib.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues_screen.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';
import '../soporte/usuario.dart';

void main() {
  testWidgets(
    'el contador de la tarjeta de sede es el dorsal sobre la foto, en el color del texto sobre foto @RED-01-ASM-04 @RED-03-ASM-14',
    (tester) async {
      await montarUsuario(
        tester,
        api: apiRutas(rutasDeSedes(sedes: '[$sedeMoronConDeportes]')),
      );

      final dorsal = find.descendant(
        of: find.byType(VenueCard),
        matching: find.byType(GiantBib),
      );
      final contador = tester.widget<GiantBib>(dorsal);
      expect(contador.text, '02');
      expect(contador.color, Palette.dark.textOnMedia);
    },
  );
}
