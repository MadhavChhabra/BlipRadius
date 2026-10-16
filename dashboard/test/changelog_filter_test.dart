import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:apiguard_dashboard/api.dart';
import 'package:apiguard_dashboard/screens/changelog_screen.dart';
import 'package:apiguard_dashboard/theme.dart';

/// Every generated changelog carries a summary line of the form "_N changes, M breaking._", so a
/// substring test for "breaking" is true even when M is zero. Both the "Breaking only" filter and
/// the red accent bar on each card were doing exactly that.
void main() {
  /// Real generator output, verbatim in shape.
  String entry(int id, String api, String version, {required bool breaking}) {
    final md = breaking
        ? '# Changelog\n\n## $version\n\n_1 change, 1 breaking._\n\n'
            '### ⚠️ Breaking Changes\n\n- **`GET /orders`** — Response field removed\n'
        : '# Changelog\n\n## $version\n\n_1 change, 0 breaking._\n\n'
            '### Additions\n\n- **`GET /orders`** — Response field `note` added\n';
    return jsonEncode({
      'id': id,
      'api': api,
      'versionLabel': version,
      'markdown': md,
      'publishedAt': '2026-08-13T10:00:00Z',
    });
  }

  ApiClient api() => ApiClient(client: MockClient((req) async {
        if (req.url.path == '/api/changelog') {
          return http.Response(
              '[${entry(2, "safe-api", "v1.1.0", breaking: false)},'
              '${entry(1, "risky-api", "v2.0.0", breaking: true)}]',
              200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      }));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: Scaffold(body: ChangelogScreen(api: api())),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('Breaking only actually filters out the safe entry', (tester) async {
    await pump(tester);
    expect(find.text('risky-api'), findsOneWidget);
    expect(find.text('safe-api'), findsOneWidget);

    await tester.tap(find.text('Breaking only'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('risky-api'), findsOneWidget);
    expect(find.text('safe-api'), findsNothing,
        reason: 'an entry with "0 breaking" must not survive the Breaking-only filter');
  });

  testWidgets('a safe entry is not flagged with the breaking accent colour', (tester) async {
    await pump(tester);

    // The 2px accent bar is the card's at-a-glance risk signal.
    final bars = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) {
          final d = c.decoration;
          return c.constraints?.maxWidth == 2 ||
              (d is BoxDecoration &&
                  (d.color == AppColors.breaking || d.color == AppColors.additive));
        })
        .toList();
    final colours = bars
        .map((c) => (c.decoration as BoxDecoration?)?.color)
        .where((c) => c == AppColors.breaking || c == AppColors.additive)
        .toList();

    expect(colours.contains(AppColors.additive), isTrue,
        reason: 'the safe entry must read as safe, not as another breaking change');
  });
}
