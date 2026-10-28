// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../session/domain/profile.dart';
import '../domain/registration_rules.dart';
import 'profile_data_row.dart';

/// Los datos personales en modo lectura. El correo no se puede cambiar (RF 2) y se ve y se
/// anuncia así.
class ProfileData extends StatelessWidget {
  const ProfileData({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileDataRow(label: 'Nombre', value: profile.firstName),
        ProfileDataRow(label: 'Apellido', value: profile.lastName),
        ProfileDataRow(label: 'DNI', value: readableDni(profile.dni)),
        ProfileDataRow(
          label: 'Nacimiento',
          value: readableDate(profile.birthDate),
        ),
        ProfileDataRow(label: 'Correo', value: profile.email, fixed: true),
      ],
    );
  }
}
