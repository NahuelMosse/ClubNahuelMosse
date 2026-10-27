import 'sesion/sesion.dart';

/// Las secciones de adentro del usuario, con todo lo que cuelga de cada una; las del
/// panel son las de `/admin`.
const _rolDe = {
  '/inicio': Rol.usuario,
  '/perfil': Rol.usuario,
  '/sedes': Rol.usuario,
  '/reservas': Rol.usuario,
  '/reservar': Rol.usuario,
  '/notificaciones': Rol.usuario,
};

/// El rol que exige [ruta]; `null` si es pública.
///
/// Todo lo que cuelga de /admin es del administrador: una ruta nueva del panel no queda
/// abierta por olvidarse de anotarla.
Rol? _rolQueExige(String ruta) {
  if (ruta == '/admin' || ruta.startsWith('/admin/')) return Rol.admin;
  return _rolDe.entries
      .where((e) => ruta == e.key || ruta.startsWith('${e.key}/'))
      .firstOrNull
      ?.value;
}

/// A dónde se desvía a quien pide [ruta] con el [perfil] de la sesión; `null` si pasa.
String? redirigirSegunRol(String ruta, Perfil? perfil) {
  // «Acceso denegado» es la única ruta bajo /admin que no exige el rol: es adonde va
  // quien pide una ruta de administrador sin el rol (CU-14-SUP-06, TP-07-SUP-03).
  if (ruta == '/admin/acceso-denegado') return perfil == null ? '/' : null;
  final rol = _rolQueExige(ruta);
  if (rol == null) return null;
  if (perfil == null) return '/';
  if (perfil.rol == rol) return null;
  // Un usuario en el panel no es un desvío: se le dice que no tiene acceso (CU-14 FA4).
  return rol == Rol.admin ? '/admin/acceso-denegado' : perfil.inicio;
}
