import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/bottom_bar.dart';
import '../../../common/button.dart';
import '../../../common/skeleton.dart';
import '../../../theme/tokens.dart';
import '../../session/presentation/session.dart';
import 'admin_header.dart';

/// The skeleton of «Gestionar espacios» and «Gestionar sedes»: header, create button and
/// the [items] list (empty while there is no data), with the wait and the REINTENTAR.
class AdminListingTemplate extends StatelessWidget {
  const AdminListingTemplate({
    super.key,
    required this.section,
    required this.title,
    required this.session,
    required this.createText,
    required this.createRoute,
    required this.onRefresh,
    required this.absorbing,
    required this.hasData,
    required this.failed,
    required this.items,
  });

  final AdminSection section;
  final String title;
  final Session session;
  final String createText;
  final String createRoute;
  final Future<void> Function() onRefresh;

  /// While a deactivation is on its way the list is not left: the result would be lost.
  final bool absorbing;
  final bool hasData;
  final bool failed;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AbsorbPointer(
      absorbing: absorbing,
      child: Scaffold(
        backgroundColor: p.bgBase,
        bottomNavigationBar: AdminBar(current: section),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: Spacing.listPagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminHeader(title: title, session: session),
                  const SizedBox(height: Spacing.s16),
                  PrimaryButton(
                    label: createText,
                    icon: Icons.add_rounded,
                    onTap: () => context.go(createRoute),
                  ),
                  const SizedBox(height: Spacing.s16),
                  ...items,
                  if (!hasData && !failed)
                    const SkeletonList(shape: SkeletonShape.venue),
                  if (!hasData && failed)
                    Center(
                      child: TextActionButton(
                        label: 'REINTENTAR',
                        onTap: onRefresh,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
