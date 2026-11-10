// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/bottom_bar.dart';
import '../../../common/dates.dart';
import '../../../common/empty_state.dart';
import '../../../common/list_loading.dart';
import '../../../common/price_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/spaces.dart';
import '../data/api_errors.dart';
import '../domain/booking.dart';
import 'booking_card.dart';
import 'booking_card_skeleton.dart';
import 'bookings.dart';
import 'bookings_tab_bar.dart';
import 'cancel_confirmation.dart';
import 'cancellation.dart';
import 'my_bookings_header.dart';

export 'booking_card.dart' show BookingCard;

/// «Mis reservas»: the upcoming ones and the history of whoever signed in.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({
    super.key,
    required this.bookings,
    required this.spaces,
    required this.session,
    this.bookingId,
    this.inHistory = false,
  });

  final Bookings bookings;
  final Spaces spaces;
  final Session session;

  /// The booking that is highlighted and brought into view, if it was reached from a
  /// notice.
  final String? bookingId;

  /// Opens on the history: for the notices of a booking that is no longer among the
  /// upcoming ones.
  final bool inHistory;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late bool _history = widget.inHistory;
  (List<Booking>, Catalog)? _data;
  bool _failure = false;

  /// Goes up with each read: the response of a tab that is no longer looked at is
  /// discarded.
  int _request = 0;

  /// The highlighted card, to bring it into view.
  final _highlighted = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MyBookingsScreen previous) {
    super.didUpdateWidget(previous);
    if (widget.bookingId == previous.bookingId &&
        widget.inHistory == previous.inHistory) {
      return;
    }
    // A new notice with the screen already open: goes to the notice's tab and reads
    // again.
    if (_history != widget.inHistory) {
      setState(() => _history = widget.inHistory);
      _load();
    } else {
      _load(fromScratch: false);
    }
  }

  void _scrollIntoView() {
    if (widget.bookingId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final card = _highlighted.currentContext;
      if (mounted && card != null) {
        Scrollable.ensureVisible(card, alignment: 0.1);
      }
    });
  }

  /// With [fromScratch] (another tab) the list is emptied while the new one arrives; on
  /// refresh the existing one stays until the new one arrives, and is removed if the read
  /// fails.
  Future<void> _load({bool fromScratch = true}) async {
    final request = ++_request;
    setState(() {
      if (fromScratch) _data = null;
      _failure = false;
    });
    Object? failure;
    var expired = false;
    try {
      final catalog = await widget.spaces.repository.catalog();
      final items = await widget.bookings.mine(history: _history);
      if (mounted && request == _request) {
        setState(() => _data = (items, catalog));
        _scrollIntoView();
      }
      return;
    } on SessionExpired {
      expired = true;
    } on NetworkFailure catch (e) {
      failure = e;
    }
    if (!mounted || request != _request) return;
    setState(() {
      _data = null;
      _failure = true;
    });
    await notifyLoadFailure(
      context,
      session: widget.session,
      expired: expired,
      error: failure,
      retry: _load,
    );
  }

  /// The booking being cancelled: its button shows that it waits and the others are
  /// disabled.
  String? _cancelling;

  /// Asks for confirmation and cancels [r]. When done, well or because the booking had
  /// already changed, the list is read again.
  Future<void> _cancel(Booking r, Catalog catalog) async {
    if (_cancelling != null) return;
    final confirmed = await confirmCancellation(
      context,
      cancellationText(AppLocalizations.of(context), r, catalog),
    );
    if (!confirmed || !mounted) return;
    await cancelWithNotices(
      context,
      session: widget.session,
      bookings: widget.bookings,
      booking: r,
      toleratesOutage: true,
      mark: (id) => setState(() => _cancelling = id),
      // Leaves «Próximas» at once, so it cannot be touched again while the list arrives.
      onCancel: () => setState(() {
        if (_data case (final items, final catalog)) {
          _data = ([...items.where((x) => x.id != r.id)], catalog);
        }
        _cancelling = null;
      }),
      reload: () => _load(fromScratch: false),
      reread: _reloadQuietly,
    );
  }

  /// Opens the grid to change the time of [r] and, on returning, reads the list again.
  Future<void> _modify(Booking r) async {
    if (await openModify(context, r)) await _reloadQuietly();
  }

  /// Reads the list again without notices: if it cannot, the existing one stays.
  Future<void> _reloadQuietly() async {
    final request = ++_request;
    try {
      final items = await widget.bookings.mine(history: _history);
      final catalog = await widget.spaces.repository.catalog();
      if (mounted && request == _request) {
        setState(() => _data = (items, catalog));
      }
    } on Exception {
      // Without network or with the server down, the old list is still the best there is.
    }
  }

  void _select(bool history) {
    if (history == _history) return;
    setState(() => _history = history);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final data = _data;
    return PopScope(
      canPop: _cancelling == null,
      child: Scaffold(
        backgroundColor: p.bgBase,
        bottomNavigationBar: IgnorePointer(
          ignoring: _cancelling != null,
          child: const BottomBar(current: Section.bookings),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _load(fromScratch: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: Spacing.listPagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MyBookingsHeader(session: widget.session),
                  const SizedBox(height: Spacing.s16),
                  BookingsTabBar(history: _history, onSelect: _select),
                  const SizedBox(height: Spacing.s16),
                  ListSwitcher(
                    child: Column(
                      key: ValueKey((data == null, _failure, _history)),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (data == null && !_failure)
                          const BookingCardSkeletons(),
                        if (data == null && _failure) ListRetry(onTap: _load),
                        if (data != null && data.$1.isEmpty)
                          EmptyState(
                            title: _history
                                ? l.bookingNoPastTitle
                                : l.bookingNoUpcomingTitle,
                            text: _history
                                ? l.bookingNoPastText
                                : l.bookingNoUpcomingText,
                          ),
                        if (data != null)
                          for (final r in data.$1) ...[
                            BookingCard(
                              booking: r,
                              catalog: data.$2,
                              key: r.id == widget.bookingId
                                  ? _highlighted
                                  : null,
                              highlighted: r.id == widget.bookingId,
                              cancelable: !_history && r.cancelable,
                              cancelling: _cancelling == r.id,
                              onCancel: _cancelling == null
                                  ? () => _cancel(r, data.$2)
                                  : null,
                              onModify: _cancelling == null
                                  ? () => _modify(r)
                                  : null,
                            ),
                            const SizedBox(height: Spacing.s12),
                          ],
                      ],
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

/// What is asked to be confirmed from whoever is going to cancel [r].
String cancellationText(AppLocalizations l, Booking r, Catalog catalog) =>
    l.bookingCancelNotice(
      shortDay(r.startsAt),
      catalog.shortKind(r.sport, r.kind),
      formatPesos(r.total),
      scheduleOf(r),
      r.venue,
    );
