import 'package:clubnahuelmosse/features/session/domain/profile.dart';
import 'package:clubnahuelmosse/features/session/domain/role.dart';
import 'package:clubnahuelmosse/redirect.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile(Role role) => Profile(
  firstName: 'Ana',
  lastName: 'Diaz',
  email: 'ana@example.com',
  role: role,
  dni: '30111222',
  birthDate: DateTime(1990, 1, 1),
);

void main() {
  test('redirectByRole sends each person where their role allows @ENG-23-S1', () {
    final user = _profile(Role.user);
    final admin = _profile(Role.admin);
    final cases =<(String, Profile?, String?)>[
      ('/login', null, null),
      ('/home', null, '/'),
      ('/home/search', null, '/'),
      ('/admin/venues', null, '/'),
      ('/home', user, null),
      ('/venues/1/spaces/2', user, null),
      ('/admin', user, '/admin/access-denied'),
      ('/admin/venues', user, '/admin/access-denied'),
      ('/admin/access-denied', user, null),
      ('/admin/access-denied', null, '/'),
      ('/admin', admin, null),
      ('/home', admin, '/admin'),
      ('/bookings', admin, '/admin'),
    ];
    for (final (path, profile, expected) in cases) {
      expect(redirectByRole(path, profile), expected, reason: '$path $profile');
    }
  });
}
