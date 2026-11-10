// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
// kit-shape: the widget and its State are a single Flutter piece
import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/dates.dart';
import '../../../common/in_progress.dart';
import '../../../common/unhandled_errors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../session/presentation/session.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/spaces.dart';
import '../data/booking_history_api.dart';
import '../domain/booking_history_entry.dart';
import '../domain/history_filters.dart';
import '../domain/pending_panel_filters.dart';
import 'booking_data_card.dart';
import 'booking_detail_header.dart';
import 'deactivation_notice.dart';
import 'traceability.dart';
import 'void_booking.dart';

/// The detail of a booking of the global history (CU-14): data and traceability, and if
/// the booking can be voided (CU-15), the action to void it. It shows what the server
/// says when it is opened, not what the list had. While the voiding is on its way it
/// cannot be left. On returning it reports with `true` that the booking changed.
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({
    super.key,
    required this.booking,
    required this.history,
    required this.session,
    required this.spaces,
    required this.filters,
    required this.pending,
  });

  /// The booking as the list showed it, until the current one arrives.
  final BookingHistoryEntry booking;
  final BookingHistory history;
  final Session session;
  final Spaces spaces;

  /// The filters of the list it came from and where they are kept if the session expires.
  final HistoryFilters filters;
  final PendingPanelFilters pending;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _voiding = false;
  late BookingHistoryEntry _current = widget.booking;
  Catalog? _catalog;

  BookingHistoryEntry get booking => _current;

  @override
  void initState() {
    super.initState();
    widget.history.detail(widget.booking.id).then((b) {
      if (mounted && b != null) setState(() => _current = b);
    }, onError: logError);
    widget.spaces.repository.catalog().then((c) {
      if (mounted) setState(() => _catalog = c);
    }, onError: logError);
  }

  Future<void> _void() async {
    if (_voiding) return;
    final result = await voidBooking(
      context,
      booking: booking,
      history: widget.history,
      session: widget.session,
      filters: widget.filters,
      pending: widget.pending,
      submitting: (v) {
        if (mounted) setState(() => _voiding = v);
      },
    );
    if (result != VoidResult.nothing && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  String get _schedule => timeRange(booking.startsAt, booking.endsAt);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final b = booking;
    return PopScope(
      canPop: !_voiding,
      child: Scaffold(
        backgroundColor: p.bgBase,
        body: SafeArea(
          child: Column(
            children: [
              BookingDetailHeader(
                onBack: _voiding ? null : () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.s24,
                    0,
                    Spacing.s24,
                    Spacing.s24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BookingDataCard(
                        booking: b,
                        schedule: _schedule,
                        sportName: _catalog?.sport(b.sport)?.name ?? b.sport,
                      ),
                      if (b.spaceDeactivated) ...[
                        const SizedBox(height: Spacing.s12),
                        DeactivationNotice(),
                      ],
                      const SizedBox(height: Spacing.s16),
                      Traceability(booking: b),
                      const SizedBox(height: Spacing.s24),
                      if (b.voidable) ...[
                        _voiding
                            ? InProgress(l10n.adminVoidingBooking)
                            : OutlineButton(
                                label: l10n.adminVoidBooking,
                                danger: true,
                                semanticLabel: l10n.adminVoidBookingFor(b.user),
                                onTap: _void,
                              ),
                        const SizedBox(height: Spacing.s12),
                      ],
                      OutlineButton(
                        label: l10n.adminBackToList,
                        onTap: _voiding
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
