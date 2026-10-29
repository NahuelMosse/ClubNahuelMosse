// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
// kit-shape: the widget and its State are a single Flutter piece
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../common/dates.dart';
import '../../../common/error_dialog.dart';
import '../../../common/missing_fields.dart';
import '../../../common/selector.dart';
import '../../../common/top_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../../venues/domain/venue.dart';
import '../../venues/presentation/venue_texts.dart';
import '../../venues/presentation/venues.dart';
import '../domain/outside_hours.dart';
import '../domain/venue_field.dart';
import 'outside_hours_message.dart';
import 'venue_deactivation.dart';
import 'venue_form.dart';
import 'venue_form_body.dart';
import 'venue_form_buttons.dart';

/// The form of a venue: name, address, opening, closing and open days. Without
/// [editing] it creates a new venue; with [editing], it fixes that one.
class VenueFormScreen extends StatefulWidget {
  const VenueFormScreen({
    super.key,
    required this.venues,
    required this.session,
    this.editing,
  });

  final Venues venues;
  final Session session;
  final Venue? editing;

  @override
  State<VenueFormScreen> createState() => _VenueFormScreenState();
}

class _VenueFormScreenState extends State<VenueFormScreen> {
  late final _form = VenueForm(venues: widget.venues, editing: widget.editing);

  @override
  void initState() {
    super.initState();
    _form.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _pickHour(VenueField field) async {
    final isClosing = field == VenueField.closesAt;
    // Closing at midnight goes last: it is the last hour of the day.
    final hours = isClosing
        ? [for (var h = 1; h < 24; h++) h, 0]
        : [for (var h = 0; h < 24; h++) h];
    final picked = await pickOption<int>(
      context,
      title: isClosing
          ? AppLocalizations.of(context).adminClosing
          : AppLocalizations.of(context).adminOpening,
      options: [for (final h in hours) (h, wholeHour(h))],
      columns: 4,
      selected: isClosing ? _form.closesAt : _form.opensAt,
    );
    if (!mounted) return;
    _form.pickHour(field, picked);
  }

  Future<void> _pickDays() async {
    final picked = await pickOption<OpenDays>(
      context,
      title: AppLocalizations.of(context).adminOpenDays,
      options: [
        for (final d in OpenDays.values)
          (d, openDaysText(AppLocalizations.of(context), d)),
      ],
      selected: OpenDays.values
          .where((d) => weekdaysLabel(d.days) == weekdaysLabel(_form.openDays))
          .firstOrNull,
    );
    if (picked == null || !mounted) return;
    _form.pickDays(picked);
  }

  void _done(Venue venue) {
    if (!mounted) return;
    if (!_form.isEditing) {
      context.go('/admin/sedes/creada', extra: venue);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).adminChangesSaved)),
    );
    context.go('/admin/sedes');
  }

  Future<void> _save({bool confirm = false}) async {
    final opensAt = _form.opensAt;
    final closesAt = _form.closesAt;
    if (_form.busy) return;
    if (!_form.isComplete || opensAt == null || closesAt == null) {
      _form.markSaveAttempt();
      focusFirstMissing(_form.missing(AppLocalizations.of(context)));
      return;
    }
    FocusScope.of(context).unfocus();
    final pending = await _form.submit(
      opensAt,
      closesAt,
      confirm: confirm,
      onSaved: _done,
    );
    if (pending == null || !mounted) return;
    if (pending.outside case final count?) {
      final saveAnyway = await confirmNewSchedule(
        context,
        outsideHoursMessage(
          AppLocalizations.of(context),
          OutsideHours.of(
            count,
            before: widget.editing,
            opensAt: opensAt,
            closesAt: closesAt,
            openDays: _form.openDays,
          ),
        ),
      );
      if (saveAnyway && mounted) await _save(confirm: true);
    } else if (pending.gone) {
      await showChangedMeanwhile(context);
      widget.venues.notifyChange();
      if (mounted) context.go('/admin/sedes');
    } else {
      await avisarFalloDeEnvio(
        context,
        session: widget.session,
        expired: pending.expired,
        error: pending.failure,
        reintentar: () => _save(confirm: confirm),
      );
    }
  }

  Future<void> _deactivate() async {
    final venue = widget.editing;
    if (venue == null) return;
    await deactivateVenue(
      context,
      venue: venue,
      venues: widget.venues,
      session: widget.session,
      returnToList: true,
      submitting: (inFlight) {
        if (mounted) _form.deactivating = inFlight;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // While saving one does not leave: the venue would be saved without showing success.
    return PopScope(
      canPop: !_form.busy,
      child: Scaffold(
        backgroundColor: context.palette.bgBase,
        appBar: TopBar(
          title: widget.editing == null
              ? AppLocalizations.of(context).adminAddVenueTitle
              : AppLocalizations.of(context).adminEditVenue,
        ),
        body: SafeArea(
          top: false,
          child: VenueFormBody(
            form: _form,
            onPickHour: _pickHour,
            onPickDays: _pickDays,
          ),
        ),
        bottomNavigationBar: ActionBar(
          child: VenueFormButtons(
            form: _form,
            onSave: _save,
            onDeactivate: _deactivate,
          ),
        ),
      ),
    );
  }
}
