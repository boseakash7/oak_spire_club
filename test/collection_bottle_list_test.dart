import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oakspire_club/app/data/models/collection_item_model.dart';
import 'package:oakspire_club/app/modules/collection/widgets/collection_bottle_list.dart';
import 'package:oakspire_club/app/modules/collection/widgets/hold_to_toggle_button.dart';

/// Holds the pointer down for [total], a frame at a time like a real finger.
Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('HoldToToggleButton', () {
    testWidgets('completes only after a two second hold', (tester) async {
      var done = 0;
      await tester.pumpWidget(
        _host(HoldToToggleButton(opening: true, onComplete: () => done++)),
      );

      final hold = await tester.startGesture(
        tester.getCenter(find.byType(HoldToToggleButton)),
      );
      await _pumpFor(tester, const Duration(milliseconds: 1500));
      expect(done, 0);
      await _pumpFor(tester, const Duration(milliseconds: 800));
      expect(done, 1);
      await hold.up();
      await tester.pump(const Duration(milliseconds: 400));
      expect(done, 1);
    });

    testWidgets('letting go early does nothing', (tester) async {
      var done = 0;
      await tester.pumpWidget(
        _host(HoldToToggleButton(opening: false, onComplete: () => done++)),
      );

      final hold = await tester.startGesture(
        tester.getCenter(find.byType(HoldToToggleButton)),
      );
      await _pumpFor(tester, const Duration(milliseconds: 1500));
      await hold.up();
      await _pumpFor(tester, const Duration(seconds: 3));

      expect(done, 0);
      expect(find.text('Hold 2s to seal'), findsOneWidget);
    });

    test('the rumble grows with the hold and fits inside it', () {
      final (pattern, strengths) = HoldToToggleButton.rumblePattern();
      expect(pattern.length, strengths.length);
      final total = pattern.fold<int>(0, (a, b) => a + b);
      expect(
        total,
        lessThanOrEqualTo(HoldToToggleButton.holdDuration.inMilliseconds),
      );
      final buzzes = [
        for (var i = 1; i < strengths.length; i += 2) strengths[i],
      ];
      expect(buzzes.first, lessThan(buzzes.last));
      expect(buzzes.last, lessThanOrEqualTo(255));
      expect(
        HoldToToggleButton.shakeAmplitude(0.9),
        greaterThan(HoldToToggleButton.shakeAmplitude(0.1)),
      );
    });
  });

  group('OwnedBottle.purchasedOn', () {
    test('is the purchase date when set, else the day it was added', () {
      const dated = OwnedBottle(
        id: '1',
        fill: 100,
        createdAt: 1760000000,
        dateAcquired: '2024-03-09',
      );
      expect(dated.purchasedOn, DateTime(2024, 3, 9));

      const undated = OwnedBottle(id: '2', fill: 100, createdAt: 1760000000);
      final added = DateTime.fromMillisecondsSinceEpoch(1760000000 * 1000);
      expect(undated.purchasedOn, DateTime(added.year, added.month, added.day));

      expect(
        undated.copyWith(purchasedOn: DateTime(2023, 12, 1)).dateAcquired,
        '2023-12-01',
      );
    });
  });

  group('CollectionBottleList', () {
    final bottles = [
      const OwnedBottle(
        id: '1',
        fill: 100,
        pricePaid: 460,
        createdAt: 1760000000,
      ),
      const OwnedBottle(
        id: '2',
        fill: 60,
        pricePaid: 370,
        createdAt: 1758000000,
      ),
      const OwnedBottle(
        id: '3',
        fill: 45,
        pricePaid: 370,
        createdAt: 1758000000,
      ),
    ];

    Widget list({
      void Function(OwnedBottle, int)? onChanged,
      Future<void> Function(OwnedBottle, {required bool opening})? onToggle,
    }) => _host(
      CollectionBottleList(
        bottles: bottles,
        onFillChanged: onChanged ?? (_, _) {},
        onFillCommitted: (_, _) {},
        onToggle: onToggle ?? (b, {required opening}) async {},
      ),
    );

    testWidgets('groups by when they were added, newest first', (tester) async {
      await tester.pumpWidget(list());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('YOUR BOTTLES · 3'), findsOneWidget);
      expect(find.text('1 bottle'), findsOneWidget);
      expect(find.text('2 bottles'), findsOneWidget);
      expect(find.text(r'$460'), findsOneWidget);
      expect(find.text(r'$370'), findsNWidgets(2));
      expect(find.text('Sealed'), findsOneWidget);
      expect(find.text('Opened'), findsNWidgets(2));

      final newer = tester.getTopLeft(find.text(r'$460')).dy;
      final older = tester.getTopLeft(find.text(r'$370').first).dy;
      expect(newer, lessThan(older));
    });

    testWidgets('a sealed bottle offers only the hold to open', (tester) async {
      await tester.pumpWidget(list());
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text(r'$460'));
      await tester.pumpAndSettle();

      expect(find.text('Hold 2s to open'), findsOneWidget);
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('an expanded row offers Edit for that bottle', (tester) async {
      OwnedBottle? edited;
      int? editedNumber;
      await tester.pumpWidget(
        _host(
          CollectionBottleList(
            bottles: bottles,
            onFillChanged: (_, _) {},
            onFillCommitted: (_, _) {},
            onToggle: (b, {required opening}) async {},
            onEdit: (b, n) {
              edited = b;
              editedNumber = n;
            },
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text(r'$460'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Bought '), findsOneWidget);
      await tester.tap(find.text('Edit'));
      await tester.pump();

      expect(edited?.id, '1');
      // The newest of the three, so the third added.
      expect(editedNumber, 3);
    });

    testWidgets('an opened bottle has a slider and a hold to seal', (
      tester,
    ) async {
      await tester.pumpWidget(list());
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text(r'$370').first);
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Hold 2s to seal'), findsOneWidget);
      expect(find.text('Half'), findsOneWidget);
    });

    testWidgets('holding the open button reports the bottle as opening', (
      tester,
    ) async {
      OwnedBottle? toggled;
      bool? wasOpening;
      await tester.pumpWidget(
        list(
          onToggle: (b, {required opening}) async {
            toggled = b;
            wasOpening = opening;
          },
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text(r'$460'));
      await tester.pumpAndSettle();

      final hold = await tester.startGesture(
        tester.getCenter(find.byType(HoldToToggleButton)),
      );
      await _pumpFor(tester, const Duration(milliseconds: 2400));
      await hold.up();
      await tester.pump(const Duration(seconds: 1));

      expect(toggled?.id, '1');
      expect(wasOpening, true);
    });
  });
}
