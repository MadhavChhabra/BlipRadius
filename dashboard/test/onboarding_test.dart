import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apiguard_dashboard/main.dart';
import 'package:apiguard_dashboard/pins.dart';
import 'package:apiguard_dashboard/screens/graph_screen.dart';
import 'package:apiguard_dashboard/theme.dart';

import 'support/fake_api.dart';

/// A first-time user should never have to work out what the product is for. The canvas states the
/// one question it answers, and every step hands off to the next.
void main() {
  setUp(() => FocusState.instance.set(null));

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: HomeShell(api: fakeApi()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the estate opens by asking the question the product answers', (tester) async {
    await pumpShell(tester);

    expect(find.text('Which API are you changing?'), findsOneWidget);
    expect(find.textContaining('who breaks, who to tell'), findsOneWidget);
    expect(find.text('Find my API'), findsOneWidget);
    // And it is never a trap: the map is one click away.
    expect(find.text('or explore the estate map'), findsOneWidget);
  });

  testWidgets('the opening question steps aside for the map', (tester) async {
    await pumpShell(tester);
    await dismissOpeningAsk(tester);

    expect(find.text('Which API are you changing?'), findsNothing);
    expect(find.text('orders-exp-api'), findsWidgets);
  });

  testWidgets('a shared blast-radius link is never interrupted by onboarding',
      (tester) async {
    // Opening straight onto someone else's link means the question is already answered.
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: Scaffold(
        body: GraphScreen(
            api: fakeApi(), open: noopOpen, initialFocus: 'orders-exp-api', openingAsk: true),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Which API are you changing?'), findsNothing);
    expect(find.text('WHO YOU HAVE TO TELL'), findsOneWidget);
  });

  testWidgets('focus mode names the next step rather than a destination', (tester) async {
    await pumpShell(tester);
    await dismissOpeningAsk(tester);

    await tester.tap(find.text('orders-exp-api').hitTestable());
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    // "Open API hub" named a screen. The developer's next question is whether the change breaks.
    expect(find.text('Check a change'), findsWidgets);
    expect(find.text('Open API hub'), findsNothing);
  });

  testWidgets('the map hands the user to the hub, on the question they were asking',
      (tester) async {
    await pumpShell(tester);
    await dismissOpeningAsk(tester);

    // The whole intuitive path: pick the API, see who breaks, go check the change.
    await tester.tap(find.text('orders-exp-api').hitTestable());
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    await tester.tap(find.text('Check a change').hitTestable());
    await tester.pump(const Duration(milliseconds: 500));

    // Landed on the API that was focused, already on the spec comparison — not on a picker.
    expect(find.text('BEFORE  →  AFTER'), findsOneWidget);
    expect(find.text('What breaks'), findsWidgets);
    expect(find.text('Who calls this'), findsWidgets);
    expect(find.text('Past changes'), findsWidgets);
    expect(find.text('Relationships'), findsNothing);
    expect(find.text('Change impact'), findsNothing);
  });
}
