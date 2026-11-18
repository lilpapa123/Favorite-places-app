import 'package:favorite_places/screens/palces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildTestApp() {
  return const ProviderScope(child: MaterialApp(home: PalcesScreen()));
}

void main() {
  testWidgets('shows the empty state when no places exist', (tester) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.text('Your Places'), findsOneWidget);
    expect(find.text('No Places added yet.'), findsOneWidget);
  });

  testWidgets('adds a place and shows it in the list', (tester) async {
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add a New Place'), findsOneWidget);
    expect(find.text('Take Picture'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Florence');
    await tester.tap(find.text('Add Place'));
    await tester.pumpAndSettle();

    expect(find.text('Florence'), findsOneWidget);
    expect(find.text('No Places added yet.'), findsNothing);
  });

  testWidgets('does not add a place without a title', (tester) async {
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Place'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a title first.'), findsOneWidget);
    expect(find.text('Add a New Place'), findsOneWidget);
  });
}
