import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/common/dates.dart';
import 'package:clubnahuelmosse/common/pending_booking.dart';
import 'package:clubnahuelmosse/common/price_format.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

const _english = [Locale('en', 'US')];
const _spanish = [Locale('es', 'AR')];

Map<String, Object?> _catalog(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, Object?>;

void main() {
  setUpAll(cargarFuentes);

  Future<void> mountLogin(
    WidgetTester tester,
    List<Locale> device, {
    CredencialesFalsas? credentials,
    ApiClient? api,
  }) async {
    tester.platformDispatcher.localesTestValue = device;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final session = Session(
      repository: SessionRepository(
        credentials: credentials ?? CredencialesFalsas(),
        api: api ?? apiFalsa(codigo: 200, cuerpo: perfilJson()),
      ),
    );
    await montar(
      tester,
      LoginScreen(session: session, pending: PendingBooking()),
      tema: darkTheme,
    );
  }

  group('login', () {
    testWidgets('an English device sees the login in English @ENG-19-S1', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountLogin(tester, _english);

      expect(find.text('WELCOME TO'), findsOneWidget);
      expect(find.text('Sports facility management'), findsOneWidget);
      expect(find.bySemanticsLabel('Email'), findsOneWidget);
      expect(find.bySemanticsLabel('Password'), findsOneWidget);
      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('GET STARTED'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsNothing);

      await tester.tap(find.text('SIGN IN'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets(
      'a Spanish device sees the login in Spanish, as before @ENG-19-S2',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await mountLogin(tester, _spanish);

        expect(find.text('BIENVENIDO A'), findsOneWidget);
        expect(find.text('Gestión de espacios deportivos'), findsOneWidget);
        expect(find.bySemanticsLabel('Correo'), findsOneWidget);
        expect(find.bySemanticsLabel('Contraseña'), findsOneWidget);
        expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
        expect(find.text('¿No tenés cuenta?'), findsOneWidget);
        expect(find.text('COMENZAR'), findsOneWidget);
        expect(find.text('INICIAR SESIÓN'), findsOneWidget);

        await tester.tap(find.text('INICIAR SESIÓN'));
        await tester.pumpAndSettle();
        expect(find.text('Completá tu correo electrónico'), findsOneWidget);
        expect(find.text('Completá tu contraseña'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets(
      'a device with French first and Spanish second sees English @ENG-19-ASM-01',
      (tester) async {
        await mountLogin(tester, const [
          Locale('fr', 'FR'),
          Locale('es', 'AR'),
        ]);

        expect(find.text('SIGN IN'), findsOneWidget);
        expect(find.text('INICIAR SESIÓN'), findsNothing);
      },
    );

    testWidgets(
      'a message the API sends is shown as it arrives, in both languages @ENG-19-ASM-04',
      (tester) async {
        const message = 'Demasiados intentos. Esperá un minuto.';
        for (final (device, signIn, email, password) in [
          (_english, 'SIGN IN', 'Email', 'Password'),
          (_spanish, 'INICIAR SESIÓN', 'Correo', 'Contraseña'),
        ]) {
          final semantics = tester.ensureSemantics();
          await mountLogin(
            tester,
            device,
            api: apiFalsa(codigo: 429, cuerpo: '{"mensaje": "$message"}'),
          );
          await tester.enterText(find.bySemanticsLabel(email), 'a@b.com');
          await tester.enterText(find.bySemanticsLabel(password), 'Clave1234');
          await tester.tap(find.text(signIn));
          await tester.pumpAndSettle();

          expect(find.text(message), findsOneWidget);
          semantics.dispose();
        }
      },
    );

    testWidgets(
      'tooltips and semantics labels show English on an English device @ENG-19-S1',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await mountLogin(
          tester,
          _english,
          credentials: CredencialesFalsas(
            alIngresar: (_, _) async => throw const InvalidCredentials(),
          ),
        );
        expect(find.bySemanticsLabel('Email'), findsOneWidget);
        expect(find.bySemanticsLabel('Password'), findsOneWidget);
        expect(find.bySemanticsLabel('Club Nahuel Mosse'), findsOneWidget);
        expect(find.byTooltip('Show password'), findsOneWidget);

        await tester.enterText(find.bySemanticsLabel('Email'), 'a@b.com');
        await tester.enterText(find.bySemanticsLabel('Password'), 'Mala1234');
        await tester.tap(find.text('SIGN IN'));
        await tester.pumpAndSettle();

        expect(
          find.text('Could not sign in. Check your details and try again.'),
          findsOneWidget,
        );
        expect(find.byTooltip('Close notice'), findsOneWidget);
        expect(find.byTooltip('Cerrar aviso'), findsNothing);
        semantics.dispose();
      },
    );
  });

  group('catalogs', () {
    test(
      'every key of app_en.arb has its Spanish translation in app_es.arb @ENG-19-S2',
      () {
        final en = _catalog('app_en.arb');
        final es = _catalog('app_es.arb');
        final keys = en.keys.where((k) => !k.startsWith('@'));
        expect(keys, isNotEmpty);
        for (final key in keys) {
          expect(es.containsKey(key), isTrue, reason: 'missing in es: $key');
          expect(es[key], isNot('""'), reason: 'empty in es: $key');
          final placeholders = RegExp(r'\{(\w+)[,}]');
          final inEn = placeholders
              .allMatches(en[key]! as String)
              .map((m) => m.group(1))
              .toSet();
          final inEs = placeholders
              .allMatches(es[key]! as String)
              .map((m) => m.group(1))
              .toSet();
          expect(inEs, inEn, reason: 'placeholders differ in $key');
        }
        final extra = es.keys.where(
          (k) => !k.startsWith('@') && !en.containsKey(k),
        );
        expect(extra, isEmpty);
      },
    );
  });

  group('language resolution', () {
    test('es-AR, es-ES and es-MX resolve to Spanish @ENG-19-ASM-01', () {
      for (final region in ['AR', 'ES', 'MX']) {
        expect(
          resolveLanguage([Locale('es', region)], supportedLanguages),
          const Locale('es'),
          reason: region,
        );
      }
      expect(
        resolveLanguage(const [Locale('es')], supportedLanguages),
        const Locale('es'),
      );
    });

    test(
      'a device in another language sees the app in English @ENG-19-ASM-01',
      () {
        for (final device in [
          [const Locale('fr', 'FR')],
          [const Locale('en', 'GB')],
          [const Locale('pt', 'BR'), const Locale('es', 'AR')],
          <Locale>[],
          null,
        ]) {
          expect(
            resolveLanguage(device, supportedLanguages),
            const Locale('en'),
            reason: '$device',
          );
        }
        expect(resolveLanguage(null, const [Locale('es')]), const Locale('es'));
      },
    );
  });

  group('formats', () {
    final thursday = DateTime(2026, 11, 12, 9, 5);

    tearDown(() => useLanguage(const Locale('es')));

    test(
      'day and month names follow the language: Thursday and Thu 12 Nov in English, Jueves and Jue 12 nov in Spanish @ENG-19-ASM-02',
      () {
        useLanguage(const Locale('en'));
        expect(currentLanguage(), 'en');
        expect(weekdayName(thursday), 'Thursday');
        expect(shortDate(thursday), 'Thu 12 Nov');
        expect(shortDay(thursday), 'Thu 12');
        expect(weekdayAbbreviation(thursday), 'THU');
        expect(shortWeekdayName(4), 'Thu');
        expect(longDate(thursday), 'Thu 12 November');

        useLanguage(const Locale('es', 'AR'));
        expect(currentLanguage(), 'es');
        expect(weekdayName(thursday), 'Jueves');
        expect(shortDate(thursday), 'Jue 12 nov');
        expect(shortDay(thursday), 'Jue 12');
        expect(weekdayAbbreviation(thursday), 'JUE');
        expect(shortWeekdayName(4), 'Jue');
        expect(longDate(thursday), 'Jue 12 de noviembre');
        expect(shortDate(DateTime(2026, 9, 3)), 'Jue 3 sep');
      },
    );

    test(
      'times, numeric dates and the ISO date do not change with the language',
      () {
        for (final language in const [Locale('en'), Locale('es')]) {
          useLanguage(language);
          expect(shortTime(thursday), '09:05');
          expect(isoDate(thursday), '2026-11-12');
          expect(readableDate(thursday), '12/11/2026');
          expect(formatDate(thursday), '12 / 11 / 2026');
          expect(dayAndMonth(thursday), '12/11');
          expect(readableDni('42118507'), '42.118.507');
        }
      },
    );

    test(
      'the price keeps the pesos format in both languages @ENG-19-ASM-03',
      () {
        for (final language in const [Locale('en'), Locale('es')]) {
          useLanguage(language);
          expect(formatPesos(38000), r'$ 38.000');
          expect(formatPesos(1500000), r'$ 1.500.000');
        }
      },
    );
  });

  group('no hard-coded interface text', () {
    test(
      'no user-facing string literal is left in lib outside lib/l10n @ENG-19-S1',
      () {
        final hits = <String>[];
        final files =
            Directory('lib')
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))
                .where(
                  (f) => !f.path.replaceAll(r'\', '/').startsWith('lib/l10n/'),
                )
                .toList()
              ..sort((a, b) => a.path.compareTo(b.path));
        for (final file in files) {
          final source = file.readAsStringSync();
          for (final literal in _literalsOf(source)) {
            if (!_isInterfaceText(literal)) continue;
            if (_exclusionFor(literal) != null) continue;
            final line =
                '\n'.allMatches(source.substring(0, literal.offset)).length + 1;
            hits.add(
              '${file.path.replaceAll(r'\', '/')}:$line  ${literal.text}',
            );
          }
        }
        expect(
          hits,
          isEmpty,
          reason: '${hits.length} literals:\n${hits.join('\n')}',
        );
      },
    );
  });
}

// ---- the scan of lib for interface text -------------------------------------------------

class _Literal {
  _Literal(this.text, this.offset, this.before, this.after, this.line);

  /// One literal piece: the interpolations split a string into its literal parts.
  final String text;
  final int offset;

  /// The source just before the string opens and just after it closes.
  final String before;
  final String after;

  /// The whole source line the string opens on.
  final String line;
}

final _accented = RegExp('[áéíóúüñÁÉÍÓÚÜÑ¿¡]');
final _twoWords = RegExp(r'\p{L}+\s+\p{L}+', unicode: true);
final _hasLetter = RegExp(r'\p{L}', unicode: true);
final _interfaceArgument = RegExp(
  r'(?<![A-Za-z])(?:Text\(|(?:label|labelText|hintText|helperText|errorText|tooltip|'
  r'semanticLabel|semanticsLabel|title|message|placeholder):)\s*(?:const\s+)?$',
);

bool _isInterfaceText(_Literal l) {
  if (!_hasLetter.hasMatch(l.text)) return false;
  return _accented.hasMatch(l.text) ||
      _twoWords.hasMatch(l.text) ||
      _interfaceArgument.hasMatch(l.before);
}

/// The reason a literal is not interface text, or null when it is.
String? _exclusionFor(_Literal l) {
  final trimmedLine = l.line.trimLeft();
  if (RegExp(r'^(import|export|part)\s').hasMatch(trimmedLine)) {
    return 'a directive: a library path';
  }
  if (l.text.startsWith('/') || l.text.startsWith('package:')) {
    return 'an API route or a library path';
  }
  if (l.before.trimRight().endsWith('[') &&
      l.after.trimLeft().startsWith(']')) {
    return 'a key of the API JSON';
  }
  if (l.text.startsWith('assets/') || _fontFamilies.contains(l.text)) {
    return 'the name of a font or an asset';
  }
  if (RegExp(r'DateFormat\(\s*$').hasMatch(l.before)) {
    return 'a date pattern of intl, not text';
  }
  if (RegExp(
    r'(assert\(|debugPrint\(|print\(|log\(|Exception\(|Error\(|FlutterError\()[^;]*$',
  ).hasMatch(l.before)) {
    return 'a log, assert or developer error message';
  }
  return null;
}

const _fontFamilies = {'Inter', 'Archivo', 'Archivo Black', 'JetBrains Mono'};

List<_Literal> _literalsOf(String source) {
  final out = <_Literal>[];
  _scanCode(source, 0, out, inInterpolation: false);
  return out;
}

bool _isIdentifierChar(String c) => RegExp(r'[A-Za-z0-9_$]').hasMatch(c);

/// Walks code from [start]; returns where it stopped (the `}` that closes an
/// interpolation, or the end).
int _scanCode(
  String s,
  int start,
  List<_Literal> out, {
  required bool inInterpolation,
}) {
  var i = start;
  var depth = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == '/' && i + 1 < s.length && s[i + 1] == '/') {
      while (i < s.length && s[i] != '\n') {
        i++;
      }
    } else if (c == '/' && i + 1 < s.length && s[i + 1] == '*') {
      final end = s.indexOf('*/', i + 2);
      i = end < 0 ? s.length : end + 2;
    } else if (c == "'" || c == '"') {
      final raw =
          i > 0 && s[i - 1] == 'r' && (i < 2 || !_isIdentifierChar(s[i - 2]));
      i = _scanString(s, i, out, raw: raw);
    } else if (inInterpolation && c == '{') {
      depth++;
      i++;
    } else if (inInterpolation && c == '}') {
      if (depth == 0) return i;
      depth--;
      i++;
    } else {
      i++;
    }
  }
  return i;
}

int _scanString(String s, int open, List<_Literal> out, {required bool raw}) {
  final quote = s[open];
  final triple = s.startsWith(quote * 3, open);
  final closer = triple ? quote * 3 : quote;
  final lineStart = s.lastIndexOf('\n', open) + 1;
  var lineEnd = s.indexOf('\n', open);
  if (lineEnd < 0) lineEnd = s.length;
  final lineText = s.substring(lineStart, lineEnd);
  final before = s.substring(open - 120 < 0 ? 0 : open - 120, open);
  final pending = <(String, int)>[];
  var i = open + closer.length;
  final buffer = StringBuffer();
  var partStart = i;
  void flush() {
    if (buffer.isNotEmpty) pending.add((buffer.toString(), partStart));
    buffer.clear();
  }

  while (i < s.length && !s.startsWith(closer, i)) {
    final c = s[i];
    if (!raw && c == r'\') {
      buffer.write(i + 1 < s.length ? s[i + 1] : '');
      i += 2;
    } else if (!raw && c == r'$' && i + 1 < s.length && s[i + 1] == '{') {
      flush();
      i = _scanCode(s, i + 2, out, inInterpolation: true) + 1;
      partStart = i;
    } else if (!raw &&
        c == r'$' &&
        i + 1 < s.length &&
        RegExp(r'[A-Za-z_]').hasMatch(s[i + 1])) {
      flush();
      i += 2;
      while (i < s.length && RegExp(r'[A-Za-z0-9_]').hasMatch(s[i])) {
        i++;
      }
      partStart = i;
    } else {
      if (buffer.isEmpty) partStart = i;
      buffer.write(c);
      i++;
    }
  }
  flush();
  final end = i + closer.length;
  final after = s.substring(
    end > s.length ? s.length : end,
    end + 40 > s.length ? s.length : end + 40,
  );
  for (final (text, offset) in pending) {
    out.add(_Literal(text, offset, before, after, lineText));
  }
  return end;
}
