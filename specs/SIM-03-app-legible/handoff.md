# Handoff SIM-03

Hecho: RED, T1, T2, T3 (commits previos) y el arreglo de la regresión de navegación (las rutas leen api, sesión, apariencia y centro del widget en cada uso; `tarjeta_cuenta_test` pasa 11/11).

T4 en curso, SIN COMMIT (el worktree tiene cambios de lib sin commitear de cuatro agentes grunt):
- Terminados (sin commit, sin verificar con el scanner): sedes/sesion/usuarios (7 funciones), comun/inicio/notificaciones (8 + selector.elegirOpcion), admin parcial (dialogo_anular_reserva, tarjeta_sede_admin, tarjeta_reserva_admin, pantalla_detalle_reserva, pantalla_filtros_reservas, pantalla_panel_admin, pantalla_editar_espacio).
- Corriendo al escribir esto: agente de reservas (pantalla_buscar_cancha x2, pantalla_horarios, pantalla_mis_reservas, pantalla_reserva_confirmada, tarjeta_reserva) y agente de admin restante (pantalla_alta_espacio build 143 y _guardar 88, pantalla_formulario_sede build 134, pantalla_panel_admin 299 líneas debe bajar de 250, verificar pantalla_editar_espacio).
- Al terminar: `flutter analyze --no-pub`, `dart format lib`, `flutter test test/codigo_legible_test.dart` (el test «piezas de un build largo» exige <=2 clases y <250 líneas en tarjeta_reserva, pantalla_filtros_reservas, pantalla_panel_admin, pantalla_reserva_confirmada, sesion/tarjeta_cuenta, pantalla_alta_espacio), capturas (`test/capturas/*_capturas.dart`, sin regenerar), commits por grupo, líneas de Log, y listar los archivos de lib creados/cambiados para la línea T4 de la card.
- Fallas a cruzar contra D:/Temp/w/main (no confirmadas como previas): rediseno/pantallas_test (tiles, «20+», «No hay horarios»), piezas_de_pantalla_test (sistema.dart), paleta_rediseno_test, sobre_foto_test, limpieza_test, limpieza_plan_test, interfaz_accesible_test, y dos fallas de navegacion_documentada_test.
- Lista de funciones largas: correr el test con una copia temporal que escriba el mapa completo (el mensaje del test lo trunca).
