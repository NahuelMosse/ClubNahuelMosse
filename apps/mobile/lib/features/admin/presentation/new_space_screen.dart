// kit-shape: the widget and its State are a single Flutter piece
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/error_dialog.dart';
import '../../../common/top_bar.dart';
import '../../../theme/tokens.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../../spaces/presentation/spaces.dart';
import '../../venues/presentation/venues.dart';
import '../domain/new_space_field.dart';
import 'new_space_body.dart';
import 'new_space_form.dart';
import 'new_space_options.dart';
import 'space_form_fields.dart';

/// Alta de espacio deportivo: sede, deporte, tipo, condición, iluminación y precio, con el
/// nombre compuesto que calcula la API a la vista.
class NewSpaceScreen extends StatefulWidget {
  const NewSpaceScreen({
    super.key,
    required this.spaces,
    required this.venues,
    required this.session,
  });

  final Spaces spaces;
  final Venues venues;
  final Session session;

  @override
  State<NewSpaceScreen> createState() => _NewSpaceScreenState();
}

class _NewSpaceScreenState extends State<NewSpaceScreen> {
  late final _form = NewSpaceForm(spaces: widget.spaces, venues: widget.venues);

  @override
  void initState() {
    super.initState();
    _form.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final failure = await _form.load();
    if (failure == null || !mounted) return;
    if (failure.expired) {
      await avisarSesionVencida(context, widget.session);
      return;
    }
    final error = failure.failure;
    if (error == null) return;
    final outcome = await handleNetworkError(context, error);
    if (!mounted) return;
    if (outcome == ErrorOutcome.retry) {
      await _load();
    } else if (outcome == ErrorOutcome.closed) {
      context.go('/admin/espacios');
    }
  }

  /// Avisa que la sesión venció si [expired] lo dice.
  Future<void> _notifyIfExpired(Future<bool> expired) async {
    if (await expired && mounted) {
      await avisarSesionVencida(context, widget.session);
    }
  }

  Future<void> _computeName() => _notifyIfExpired(_form.computeName());

  Future<void> _pickVenue() async {
    final chosen = await pickVenueForNewSpace(context, _form);
    if (chosen == null || !mounted || chosen == _form.venue) return;
    await _notifyIfExpired(_form.pickVenue(chosen));
  }

  Future<void> _pickSport() async {
    final chosen = await pickSportForNewSpace(context, _form);
    if (chosen == null || !mounted || chosen == _form.sport) return;
    await _notifyIfExpired(_form.pickSport(chosen));
  }

  Future<void> _pickType() async {
    final chosen = await pickTypeForNewSpace(context, _form);
    if (chosen == null || !mounted || chosen == _form.type) return;
    await _notifyIfExpired(_form.pickType(chosen));
  }

  Future<void> _pickYesNo(NewSpaceField field) async {
    final roofing = field == NewSpaceField.roofing;
    final chosen = await pickYesNo(
      context,
      roofing: roofing,
      selected: roofing ? _form.roofed : _form.lit,
    );
    if (chosen == null || !mounted) return;
    _form.pickYesNo(field, value: chosen);
  }

  /// Calcula el nombre si falta; devuelve si hay que cortar el guardado porque no se pudo.
  Future<bool> _nameFails() async {
    if (_form.suggested != null || !_form.canComputeName) return false;
    await _computeName();
    if (!mounted) return true;
    final failure = _form.nameFailure;
    if (failure == null) return false;
    await avisarFalloDeEnvio(
      context,
      session: widget.session,
      expired: false,
      error: failure,
      reintentar: _save,
    );
    return true;
  }

  Future<void> _save() async {
    if (_form.submitting || _form.computing) return;
    if (await _nameFails() || !mounted) return;
    // Lo que se manda es lo que se ve ahora, aunque haya cambiado mientras se calculaba.
    if (!_form.isComplete) return _form.markSaveAttempt();
    FocusScope.of(context).unfocus();
    final pending = await _form.submit(
      onCreated: (space) {
        if (mounted) context.go('/admin/espacios/creado', extra: space);
      },
    );
    if (pending == null || !mounted) return;
    await avisarFalloDeEnvio(
      context,
      session: widget.session,
      expired: pending.expired,
      error: pending.failure,
      reintentar: _save,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Mientras se guarda no se sale: el espacio se crearía sin que se viera el éxito.
      canPop: !_form.submitting,
      child: Scaffold(
        backgroundColor: context.palette.bgBase,
        appBar: const TopBar(title: 'Nuevo espacio'),
        body: SafeArea(
          top: false,
          child: _form.loading && _form.venueOptions == null
              ? const Center(child: CircularProgressIndicator())
              : NewSpaceBody(
                  form: _form,
                  onPickVenue: _pickVenue,
                  onPickSport: _pickSport,
                  onPickType: _pickType,
                  onPickYesNo: _pickYesNo,
                  onRetryName: _computeName,
                  onSave: _save,
                ),
        ),
      ),
    );
  }
}
