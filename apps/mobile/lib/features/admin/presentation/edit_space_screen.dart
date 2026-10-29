// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
// kit-shape: the widget and its State are a single Flutter piece
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../common/error_dialog.dart';
import '../../../common/price_format.dart';
import '../../../common/top_bar.dart';
import '../../../common/unhandled_errors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/domain/space_exceptions.dart';
import '../../spaces/presentation/spaces.dart';
import '../data/api_failures.dart';
import '../domain/space_price.dart';
import 'fixed_space_fields.dart';
import 'generated_name.dart';
import 'price_per_hour_field.dart';
import 'space_conditions_pair.dart';
import 'space_deactivation.dart';
import 'space_deactivation_button.dart';
import 'space_form_fields.dart';

/// «Editar espacio deportivo»: condición, iluminación y precio. La sede, el deporte, el
/// tipo y el nombre compuesto se ven pero no cambian.
class EditSpaceScreen extends StatefulWidget {
  const EditSpaceScreen({
    super.key,
    required this.space,
    required this.spaces,
    required this.session,
  });

  final Space space;
  final Spaces spaces;
  final Session session;

  @override
  State<EditSpaceScreen> createState() => _EditSpaceScreenState();
}

class _EditSpaceScreenState extends State<EditSpaceScreen> {
  late bool _roofed = widget.space.covered;
  late bool _lit = widget.space.lit;
  late final _price = TextEditingController(
    text: formatPesos(widget.space.pricePerHour),
  );
  Catalog? _catalog;
  String? _serverError;
  bool _submitting = false;
  bool _deactivating = false;

  /// Guardando o dando de baja: el formulario no se toca ni se sale.
  bool get _busy => _submitting || _deactivating;

  @override
  void initState() {
    super.initState();
    var previous = _price.text;
    _price.addListener(() {
      if (_price.text == previous) return;
      previous = _price.text;
      setState(() => _serverError = null);
    });
    _loadCatalog();
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  /// Sólo para mostrar el deporte y el tipo con su nombre: si no llega, se ven las claves.
  Future<void> _loadCatalog() async {
    try {
      final catalog = await widget.spaces.repository.catalog();
      if (mounted) setState(() => _catalog = catalog);
    } on Exception catch (e, stack) {
      logError(e, stack);
    }
  }

  bool get _changed {
    final s = widget.space;
    return _roofed != s.covered ||
        _lit != s.lit ||
        readPrice(_price.text) != s.pricePerHour;
  }

  bool get _canSave =>
      _changed &&
      validPricePerHour(readPrice(_price.text)) &&
      _serverError == null;

  Future<void> _pickYesNo({required bool roofing}) async {
    final chosen = await pickYesNo(
      context,
      roofing: roofing,
      selected: roofing ? _roofed : _lit,
    );
    if (chosen == null || !mounted) return;
    setState(() {
      if (roofing) {
        _roofed = chosen;
      } else {
        _lit = chosen;
      }
      _serverError = null;
    });
  }

  Future<void> _save() async {
    final price = readPrice(_price.text);
    if (_busy || !_canSave || price == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    Object? failure;
    var expired = false;
    var gone = false;
    try {
      final s = widget.space;
      await widget.spaces.update(
        s.id,
        covered: _roofed == s.covered ? null : _roofed,
        lit: _lit == s.lit ? null : _lit,
        pricePerHour: price == s.pricePerHour ? null : price,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adminChangesSaved)),
      );
      context.go('/admin/espacios');
      return;
    } on SpaceUnavailable {
      gone = true;
    } on SpaceRejected catch (e) {
      if (mounted) {
        setState(
          () => _serverError =
              e.errors['price_per_hour'] ?? e.errors.values.firstOrNull,
        );
      }
    } on SessionExpired {
      expired = true;
    } on FalloDeRed catch (e) {
      failure = e;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!mounted) return;
    if (gone) {
      await showChangedMeanwhile(context);
      widget.spaces.notifyChange();
      if (mounted) context.go('/admin/espacios');
    } else {
      await avisarFalloDeEnvio(
        context,
        session: widget.session,
        expired: expired,
        error: failure,
        reintentar: _save,
      );
    }
  }

  Future<void> _deactivate() async {
    await deactivateSpace(
      context,
      space: widget.space,
      spaces: widget.spaces,
      session: widget.session,
      returnToList: true,
      submitting: (inFlight) {
        if (mounted) setState(() => _deactivating = inFlight);
      },
    );
  }

  /// El precio cargado vale: el error se ve recién cuando se lo cambia.
  String? get _priceError =>
      _serverError ??
      (readPrice(_price.text) == widget.space.pricePerHour
          ? null
          : priceError(AppLocalizations.of(context), _price.text));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final s = widget.space;
    return PopScope(
      // Mientras se guarda no se sale: el cambio quedaría hecho sin que se viera.
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: p.bgBase,
        appBar: TopBar(title: l10n.adminEditSpaceTitle),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: Spacing.formPagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...spaceFormHeading(context, l10n.adminEditSpaceHeading),
                ...fixedSpaceFields(context, s, _catalog),
                SpaceConditionsPair(
                  roofed: _roofed,
                  lit: _lit,
                  onPickRoofing: _busy ? null : () => _pickYesNo(roofing: true),
                  onPickLighting: _busy
                      ? null
                      : () => _pickYesNo(roofing: false),
                ),
                const SizedBox(height: Spacing.s12),
                PricePerHourField(
                  controller: _price,
                  error: _priceError,
                  enabled: !_busy,
                ),
                const SizedBox(height: Spacing.s16),
                GeneratedName(name: s.name),
                const SizedBox(height: Spacing.s16),
                PrimaryButton(
                  label: l10n.adminSaveSpace,
                  loading: _submitting,
                  onTap: _canSave && !_deactivating ? _save : null,
                ),
                const SizedBox(height: Spacing.s12),
                OutlineButton(
                  label: l10n.adminCancel,
                  onTap: _busy ? null : () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: Spacing.s12),
                SpaceDeactivationButton(
                  deactivating: _deactivating,
                  onTap: _busy ? null : _deactivate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
