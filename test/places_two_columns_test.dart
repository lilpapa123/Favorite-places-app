import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/places_two_columns.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('alternates places between the columns, city only', (
    tester,
  ) async {
    final places = [
      for (final city in ['Rome', 'Lima', 'Oslo'])
        Place(
          title: '$city spot',
          location: PlaceLocation(latitude: 0, longitude: 0, city: city),
        ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data(Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(child: PlacesTwoColumns(places: places)),
        ),
      ),
    );

    final rome = tester.getTopLeft(find.text('Rome'));
    final lima = tester.getTopLeft(find.text('Lima'));
    final oslo = tester.getTopLeft(find.text('Oslo'));
    expect(lima.dx, greaterThan(rome.dx), reason: '2nd place on the right');
    expect(oslo.dx, rome.dx, reason: '3rd place back on the left');
    expect(oslo.dy, greaterThan(rome.dy));
    expect(find.text('Rome spot'), findsNothing, reason: 'no title shown');
    expect(find.bySemanticsLabel('Rome spot, Rome'), findsOneWidget);
  });
}
