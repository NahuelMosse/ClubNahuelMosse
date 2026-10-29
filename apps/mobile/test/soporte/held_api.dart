import 'dart:async';
import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/skeleton.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A fake API that answers by `METHOD /path` (a 404 for what is missing) and keeps every
/// request whose `METHOD /path` is in [held] waiting until [release]: the screen stays in its
/// loading state, then receives real data and lays out its real content.
class HeldApi {
  HeldApi(this.answers, {Set<String>? held}) : held = held ?? const {'*'};

  /// `METHOD /path` → (status, JSON body).
  final Map<String, (int, String)> answers;

  /// The keys that wait for [release]; `*` holds every request.
  final Set<String> held;

  Completer<void> _gate = Completer<void>();

  late final ApiClient client = ApiClient(
    'http://api.falsa',
    cliente: MockClient((request) async {
      final key = '${request.method} ${request.url.path}';
      if (held.contains('*') || held.contains(key)) await _gate.future;
      final (status, body) = answers[key] ?? (404, '{}');
      return http.Response.bytes(
        utf8.encode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );

  /// Lets the held requests through.
  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  /// Holds the next requests again (a filter or a second query after the first load).
  void holdAgain() {
    if (_gate.isCompleted) _gate = Completer<void>();
  }
}

/// The global rects of the [Skeleton] blocks on screen, top to bottom and left to right.
List<Rect> skeletonRects(WidgetTester tester, {Finder? within}) {
  final finder = within == null
      ? find.byType(Skeleton)
      : find.descendant(of: within, matching: find.byType(Skeleton));
  // By render box, not by widget: a const block is the same instance in every place.
  final rects = finder.evaluate().map((e) {
    final box = e.renderObject! as RenderBox;
    return box.localToGlobal(Offset.zero) & box.size;
  }).toList()
    ..sort((a, b) {
      final dy = a.top.compareTo(b.top);
      return dy != 0 ? dy : a.left.compareTo(b.left);
    });
  return rects;
}

/// The skeleton block stands where the real element will be: same left and right edges and
/// the same top within [edge] px, and a height within [height] px of the real one.
void expectSameBox(
  Rect skeleton,
  Rect real, {
  double edge = 1,
  double height = 8,
  String? reason,
}) {
  final what = reason == null ? '' : '$reason: ';
  expect(skeleton.left, moreOrLessEquals(real.left, epsilon: edge), reason: '${what}left edge');
  expect(skeleton.right, moreOrLessEquals(real.right, epsilon: edge), reason: '${what}right edge');
  expect(skeleton.top, moreOrLessEquals(real.top, epsilon: edge), reason: '${what}top edge');
  expect(skeleton.height, moreOrLessEquals(real.height, epsilon: height), reason: '${what}height');
}
