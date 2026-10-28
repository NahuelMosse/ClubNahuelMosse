import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/appearance.dart';
import '../../../common/motion.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/profile.dart';
import '../../session/presentation/session.dart';
import 'account_actions.dart';
import 'dark_mode.dart';
import 'profile_card.dart';
import 'profile_data.dart';
import 'profile_editor.dart';
import 'profile_header.dart';
import 'profile_row.dart';
import 'small_button.dart';

/// Las tarjetas de Mi perfil: datos, seguridad, apariencia y las acciones de la cuenta.
class MyProfileContent extends StatelessWidget {
  const MyProfileContent({
    super.key,
    required this.profile,
    required this.session,
    required this.appearance,
    required this.editing,
    required this.deactivating,
    required this.onEdit,
    required this.onSave,
    required this.onConfirmDeactivation,
  });

  final Profile profile;
  final Session session;
  final Appearance appearance;
  final bool editing;
  final bool deactivating;
  final VoidCallback onEdit;
  final ValueChanged<Profile> onSave;
  final VoidCallback onConfirmDeactivation;

  @override
  Widget build(BuildContext context) {
    // Una pantalla corta y fija: todo queda armado aunque salga de la vista.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeader(profile: profile),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.s24,
              Spacing.s20,
              Spacing.s24,
              Spacing.s48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: ProfileCard(
                    title: 'DATOS PERSONALES',
                    action: editing
                        ? null
                        : SmallButton(
                            text: 'Editar',
                            icon: Icons.edit_outlined,
                            onTap: onEdit,
                          ),
                    child: editing
                        ? ProfileEditor(
                            profile: profile,
                            session: session,
                            onSave: onSave,
                          )
                        : ProfileData(profile: profile),
                  ),
                ),
                const SizedBox(height: Spacing.s16),
                FadeIn(
                  delay: const Duration(milliseconds: 180),
                  child: ProfileCard(
                    title: 'SEGURIDAD',
                    child: ProfileRow(
                      icon: Icons.lock_outline_rounded,
                      text: 'Cambiar contraseña',
                      onTap: () => context.push('/perfil/contrasena'),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.s16),
                FadeIn(
                  delay: const Duration(milliseconds: 260),
                  child: ProfileCard(
                    title: 'APARIENCIA',
                    child: DarkMode(appearance: appearance),
                  ),
                ),
                const SizedBox(height: Spacing.s20),
                FadeIn(
                  delay: const Duration(milliseconds: 340),
                  child: AccountActions(
                    session: session,
                    deactivating: deactivating,
                    onConfirmDeactivation: onConfirmDeactivation,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
