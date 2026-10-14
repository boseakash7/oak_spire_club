import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oakspire_club/app/modules/collection/collection_loading_view.dart';

void main() {
  // The skeleton's two layers (surfaces, placeholders) must lay out the same
  // at every phone width, with nothing overflowing.
  for (final size in const [Size(320, 640), Size(390, 844), Size(430, 932)]) {
    testWidgets('collection skeleton lays out at ${size.width}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MediaQuery(
          // No shimmer animation, so the test settles.
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(home: Scaffold(body: CollectionLoadingView())),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(CollectionLoadingView), findsOneWidget);
    });
  }
}
