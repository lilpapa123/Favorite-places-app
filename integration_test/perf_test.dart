// Scripted performance run. Measure in profile mode on a real device:
//   flutter drive --profile --no-dds --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf_test.dart -d <device-id>
// Results land in build/*.timeline_summary.json.
import 'package:favorite_places/main.dart' as app;
import 'package:favorite_places/widgets/glass_tab_bar.dart';
import 'package:favorite_places/widgets/palces_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scroll, tabs, map and settings', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Tab bar buttons in order: My places, Map, camera, Account.
    Finder tab(int i) => find
        .descendant(
          of: find.byType(GlassTabBar),
          matching: find.byType(GestureDetector),
        )
        .at(i);

    final list = find
        .descendant(
          of: find.byType(PalcesList),
          matching: find.byType(Scrollable),
        )
        .first;

    await binding.traceAction(() async {
      // Fling the 15-place feed down and back up.
      for (var i = 0; i < 3; i++) {
        await tester.fling(list, const Offset(0, -900), 2500);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 3; i++) {
        await tester.fling(list, const Offset(0, 900), 2500);
        await tester.pumpAndSettle();
      }
    }, reportKey: 'scroll_list');

    await binding.traceAction(() async {
      // Map tab: first open loads tiles, then pan around.
      await tester.tap(tab(1));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final map = find.byType(Scaffold).last;
      for (var i = 0; i < 4; i++) {
        await tester.drag(map, const Offset(-250, 120));
        await tester.pumpAndSettle();
      }
    }, reportKey: 'map_pan');

    await binding.traceAction(() async {
      // Hop between tabs a few times.
      for (final i in [3, 0, 1, 3, 0]) {
        await tester.tap(tab(i));
        await tester.pumpAndSettle();
      }
    }, reportKey: 'tab_switch');
  });
}
