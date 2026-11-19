import 'package:favorite_places/screens/palces.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildTestApp() {
  return ProviderScope(
    child: MaterialApp(
      theme: AsciiTheme.data,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: const PalcesScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows the empty state when no places exist', (tester) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.text('favorite_places'), findsOneWidget);
    expect(find.text('no places yet'), findsOneWidget);
  });

  testWidgets('adds a place and shows it in the feed', (tester) async {
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.text('add place'));
    await tester.pumpAndSettle();

    expect(find.text('new place'), findsOneWidget);
    expect(find.textContaining('take picture'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Florence');
    await tester.tap(find.text('save place'));
    await tester.pumpAndSettle();

    expect(find.text('Florence'), findsOneWidget);
    expect(find.text('no places yet'), findsNothing);
  });

  testWidgets('refuses to save without a title', (tester) async {
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.text('add place'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('save place'));
    await tester.pumpAndSettle();

    expect(find.text('title required'), findsOneWidget);
    expect(find.text('new place'), findsOneWidget);
  });
}
