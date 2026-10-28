// kit_motion.dart — what a motion does over time, measured frame by frame in a widget test.
// kitTrace pumps 16 ms at a time after `action` and records, for the element the finder matches, its
// rect, its effective opacity (product of RenderOpacity and RenderAnimatedOpacity up the tree) and its
// transform (translation relative to the first sample, scale and rotation in degrees). The series go
// through the same analysis as motion-curves.mjs `analyzeSeries` (duration, overshoot, curve shape,
// jumps) and the result is written to build/kit/motion-<name>.json in the format that
// `motion-audit.mjs compare` reads: { source, name, frames, elements, roles, grammar }.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const double _frame = 1000 / 60;
const int _stepMs = 16;
const _cols = [
  'left',
  'top',
  'width',
  'height',
  'opacity',
  'tx',
  'ty',
  'sx',
  'sy',
  'rot',
];
const _propOf = {
  'left': 'left',
  'top': 'top',
  'width': 'width',
  'height': 'height',
  'opacity': 'opacity',
  'tx': 'translateX',
  'ty': 'translateY',
  'sx': 'scaleX',
  'sy': 'scaleY',
  'rot': 'rotate',
};
const _eps = {
  'left': 1.0,
  'top': 1.0,
  'width': 1.0,
  'height': 1.0,
  'translateX': 1.0,
  'translateY': 1.0,
  'scaleX': 0.01,
  'scaleY': 0.01,
  'rotate': 1.0,
  'opacity': 0.02,
};
const _preference = [
  'opacity',
  'translateY',
  'translateX',
  'scaleX',
  'scaleY',
  'rotate',
  'top',
  'left',
  'width',
  'height',
];

final List<MapEntry<String, double Function(double)>> _shapes = [
  MapEntry('linear', (u) => u),
  MapEntry('ease-out', (u) => 1 - math.pow(1 - u, 2).toDouble()),
  MapEntry('ease-out', (u) => 1 - math.pow(1 - u, 3).toDouble()),
  MapEntry('ease-out', (u) => 1 - math.pow(1 - u, 5).toDouble()),
  MapEntry('ease-in', (u) => math.pow(u, 2).toDouble()),
  MapEntry('ease-in', (u) => math.pow(u, 3).toDouble()),
  MapEntry(
    'ease-in-out',
    (u) => u < 0.5 ? 2 * u * u : 1 - 2 * math.pow(1 - u, 2).toDouble(),
  ),
  MapEntry(
    'ease-in-out',
    (u) => u < 0.5
        ? 4 * math.pow(u, 3).toDouble()
        : 1 - 4 * math.pow(1 - u, 3).toDouble(),
  ),
];

num _round(double x, [int d = 1]) {
  final p = math.pow(10, d).toDouble();
  final r = (x * p).round() / p;
  return d == 0 ? r.round() : r;
}

double _median(List<double> a) {
  if (a.isEmpty) return 0;
  final s = [...a]..sort();
  return s.length.isOdd
      ? s[(s.length - 1) ~/ 2]
      : (s[s.length ~/ 2 - 1] + s[s.length ~/ 2]) / 2;
}

/// One property over time: port of `analyzeSeries` (motion-curves.mjs). `t` in ms, `v` the values,
/// `eps` the smallest change that counts as movement. Null when nothing moves.
Map<String, dynamic>? analyzeSeries(
  List<double> t,
  List<double> v,
  double eps,
) {
  final n = v.length;
  if (n < 4) return null;
  final first = v.first;
  final fin = v.last;
  final range = v.reduce(math.max) - v.reduce(math.min);
  if (range < eps) return null;
  final net = fin - first;
  final returns = net.abs() < eps;
  final amp = returns ? range : net.abs();
  final dir = returns ? 1.0 : net.sign;
  final tol = amp * 0.005;
  final start = v.indexWhere((x) => (x - first).abs() > tol);
  if (start < 1) return null;
  final tail = v.sublist(n - 4);
  var settled = true;
  for (var i = 1; i < tail.length; i++) {
    if ((tail[i] - tail[i - 1]).abs() > tol) settled = false;
  }
  var settle = n - 1;
  if (settled) {
    while (settle > start && (v[settle - 1] - fin).abs() <= tol) {
      settle--;
    }
  }
  final t0 = t[start - 1];
  final durationMs = t[settle] - t0;
  var over = 0.0;
  if (!returns && settled) {
    for (var j = start; j < n; j++) {
      over = math.max(over, (v[j] - fin) * dir);
    }
  }
  final overshootPct = _round(over / amp * 100).toDouble();
  String shape;
  if (returns) {
    shape = 'round-trip';
  } else if (settle - start < 2) {
    shape = 'step';
  } else if (overshootPct > 3) {
    shape = 'spring';
  } else {
    final base = v[start - 1];
    final best = <String, double>{};
    for (final s in _shapes) {
      var err = 0.0;
      for (var j = start - 1; j <= settle; j++) {
        final u = (t[j] - t0) / (t[settle] - t0);
        final p = (v[j] - base) / (fin - base);
        err += math.pow(p - s.value(u), 2).toDouble();
      }
      best[s.key] = math.min(best[s.key] ?? double.infinity, err);
    }
    final ranked = best.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    shape = ranked.first.key;
  }
  final vel = <double>[];
  for (var k = start; k <= settle; k++) {
    vel.add((v[k] - v[k - 1]).abs() * _frame / math.max(1, t[k] - t[k - 1]));
  }
  final med = _median(vel.where((d) => d > tol / 4).toList());
  final jumps = <Map<String, num>>[];
  if (settle - start >= 4) {
    for (var k = 0; k < vel.length; k++) {
      final d = vel[k];
      final prev = k > 0 ? vel[k - 1] : 0.0;
      final next = k + 1 < vel.length ? vel[k + 1] : 0.0;
      if (d > 3 * med && d > 2 * math.max(prev, next) && d >= 0.1 * amp) {
        jumps.add({'atMs': _round(t[start + k] - t0, 0), 'size': _round(d, 2)});
      }
    }
  }
  return {
    'from': _round(v[start - 1], 2),
    'to': _round(fin, 2),
    'startT': t0,
    'durationMs': _round(durationMs, 0),
    'overshootPct': overshootPct,
    'shape': shape,
    'settled': settled,
    'jumps': jumps,
  };
}

double _effectiveOpacity(RenderObject start) {
  var o = 1.0;
  RenderObject? p = start;
  while (p != null) {
    if (p is RenderOpacity) o *= p.opacity;
    if (p is RenderAnimatedOpacity) o *= p.opacity.value;
    p = p.parent;
  }
  return o;
}

Map<String, dynamic> _entry(Map<String, dynamic> el) {
  final primary = el['primary'] as String;
  final m = (el['moves'] as List).cast<Map<String, dynamic>>().firstWhere(
    (x) => x['prop'] == primary,
  );
  return {
    'label': el['label'],
    'prop': primary,
    'startMs': el['startMs'],
    'durationMs': m['durationMs'],
    'shape': m['shape'],
    'overshootPct': m['overshootPct'],
    'jumps': (m['jumps'] as List).length,
  };
}

/// Runs `action`, then samples `finder` every 16 ms for `ms` and writes build/kit/motion-<name>.json.
/// `role` is one of cta.hover, cta.press, hero, cards, section, click. Returns the report.
Future<Map<String, dynamic>> kitTrace(
  WidgetTester tester,
  Finder finder, {
  required Future<void> Function() action,
  int ms = 1500,
  String name = 'trace',
  String role = 'click',
}) async {
  final series = <String, List<double>>{for (final c in _cols) c: <double>[]};
  final times = <double>[];
  double? tx0;
  double? ty0;
  String label = finder.description;
  String tag = 'unknown';

  void sample(double at) {
    if (finder.evaluate().isEmpty) return;
    final ro = tester.renderObject(finder.first);
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) return;
    final rect = tester.getRect(finder.first);
    final m = ro.getTransformTo(null).storage;
    tx0 ??= m[12];
    ty0 ??= m[13];
    tag = tester.widget(finder.first).runtimeType.toString();
    times.add(at);
    series['left']!.add(rect.left);
    series['top']!.add(rect.top);
    series['width']!.add(rect.width);
    series['height']!.add(rect.height);
    series['opacity']!.add(_effectiveOpacity(ro));
    series['tx']!.add(m[12] - tx0!);
    series['ty']!.add(m[13] - ty0!);
    series['sx']!.add(math.sqrt(m[0] * m[0] + m[1] * m[1]));
    series['sy']!.add(math.sqrt(m[4] * m[4] + m[5] * m[5]));
    series['rot']!.add(math.atan2(m[1], m[0]) * 180 / math.pi);
  }

  sample(0);
  await action();
  var elapsed = 0;
  while (elapsed < ms) {
    await tester.pump(const Duration(milliseconds: _stepMs));
    elapsed += _stepMs;
    sample(elapsed.toDouble());
  }

  final moves = <Map<String, dynamic>>[];
  for (final c in _cols) {
    final r = analyzeSeries(times, series[c]!, _eps[_propOf[c]]!);
    if (r == null) continue;
    final startT = r.remove('startT') as double;
    moves.add({'prop': _propOf[c], ...r, 'startMs': _round(startT, 0)});
  }

  final elements = <Map<String, dynamic>>[];
  Map<String, dynamic>? el;
  if (moves.isNotEmpty) {
    final primary = _preference
        .map((p) => moves.where((m) => m['prop'] == p))
        .firstWhere((x) => x.isNotEmpty)
        .first['prop'];
    el = {
      'id': 1,
      'label': label,
      'parent': 0,
      'tag': tag,
      'primary': primary,
      'moves': moves,
      'startMs': moves.map((m) => m['startMs'] as num).reduce(math.min),
      'endMs': moves
          .map((m) => (m['startMs'] as num) + (m['durationMs'] as num))
          .reduce(math.max),
      'series': {'t': times, for (final c in _cols) c: series[c]},
    };
    elements.add(el);
  }

  Map<String, dynamic>? entry = el == null ? null : _entry(el);
  if (entry != null && (role == 'click' || role == 'hero')) {
    entry = {
      ...entry,
      'stepMs': 0,
      'count': 1,
      'totalMs': (el!['endMs'] as num) - (el['startMs'] as num),
    };
  }
  final roles = <String, dynamic>{};
  if (role.startsWith('cta.')) {
    roles['cta'] = {'label': label, role.substring(4): entry};
  } else {
    roles[role] = entry;
  }

  final grammar = <String, dynamic>{
    'durationsMs': entry == null
        ? null
        : {
            'min': entry['durationMs'],
            'median': entry['durationMs'],
            'max': entry['durationMs'],
          },
    'shapes': entry == null ? <String, int>{} : {entry['shape'] as String: 1},
    'staggerMs': 0,
    'cursor': null,
  };

  final report = <String, dynamic>{
    'source': 'flutter',
    'name': name,
    'frames': times.length,
    'elements': elements,
    'roles': roles,
    'grammar': grammar,
  };
  final dir = Directory('build/kit')..createSync(recursive: true);
  File(
    '${dir.path}/motion-${name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  return report;
}
