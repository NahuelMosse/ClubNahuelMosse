import 'features/session/domain/profile.dart';
import 'features/session/domain/role.dart';

/// The sections inside the user area, with everything that hangs from each one; the
/// panel ones are those under `/admin`.
const _roleOf = {
  '/home': Role.user,
  '/profile': Role.user,
  '/venues': Role.user,
  '/bookings': Role.user,
  '/book': Role.user,
  '/notifications': Role.user,
};

/// The role that [path] requires; `null` if it is public.
///
/// Everything under /admin belongs to the administrator: a new panel route is not left
/// open by forgetting to list it.
Role? _requiredRole(String path) {
  if (path == '/admin' || path.startsWith('/admin/')) return Role.admin;
  return _roleOf.entries
      .where((e) => path == e.key || path.startsWith('${e.key}/'))
      .firstOrNull
      ?.value;
}

/// Where whoever asks for [path] with the session [profile] is diverted to; `null` if they pass.
String? redirectByRole(String path, Profile? profile) {
  // «Access denied» is the only route under /admin that does not require the role: it is
  // where whoever asks for an admin route without the role goes (CU-14-SUP-06, TP-07-SUP-03).
  if (path == '/admin/access-denied') return profile == null ? '/' : null;
  final role = _requiredRole(path);
  if (role == null) return null;
  if (profile == null) return '/';
  if (profile.role == role) return null;
  // A user in the panel is not a diversion: they are told they have no access (CU-14 FA4).
  return role == Role.admin ? '/admin/access-denied' : profile.home;
}
