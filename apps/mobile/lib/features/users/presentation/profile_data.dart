// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../session/domain/profile.dart';
import '../domain/registration_rules.dart';
import 'profile_data_row.dart';

/// The personal data in read mode. The email cannot be changed (RF 2) and is seen and
/// announced that way.
class ProfileData extends StatelessWidget {
  const ProfileData({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        ProfileDataRow(label: l10n.profileFirstName, value: profile.firstName),
        ProfileDataRow(label: l10n.profileLastName, value: profile.lastName),
        ProfileDataRow(label: l10n.profileDni, value: readableDni(profile.dni)),
        ProfileDataRow(
          label: l10n.profileBirthShort,
          value: readableDate(profile.birthDate),
        ),
        ProfileDataRow(
          label: l10n.profileEmailShort,
          value: profile.email,
          fixed: true,
        ),
      ],
    );
  }
}
