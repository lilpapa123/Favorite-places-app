import 'package:favorite_places/l10n/app_localizations.dart';
import 'package:favorite_places/screens/home_shell.dart';
import 'package:favorite_places/screens/palces.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/glass_tab_bar.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Pretends to be the camera: returns a fake photo path for any source.
class _FakeCamera extends ImagePickerPlatform {
  ImageSource? lastSource;

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    lastSource = source;
    return XFile('/tmp/fake_photo.jpg');
  }
}

/// The app, or [home] alone (e.g. the user's own places screen).
Widget buildTestApp({Widget home = const HomeShell()}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.data(Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: home,
    ),
  );
}

/// A tall phone-shaped screen, so whole forms fit without scrolling.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> openAddForm(WidgetTester tester) async {
  useTallScreen(tester);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add a place'));
  await tester.pumpAndSettle();
}

Future<void> addPlace(
  WidgetTester tester,
  String name, {
  String? type,
  String? note,
}) async {
  await openAddForm(tester);
  await tester.enterText(
    find.widgetWithText(TextField, 'A little pause by the river'),
    name,
  );
  if (type != null) {
    await tester.tap(find.text(type));
    await tester.pump();
  }
  if (note != null) {
    await tester.enterText(
      find.widgetWithText(TextField, 'Why you love it, in a line or two'),
      note,
    );
  }
  await tapSave(tester);
}

Future<void> tapSave(WidgetTester tester) async {
  final save = find.text('Save place');
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows the empty state when no places exist', (tester) async {
    await tester.pumpWidget(buildTestApp(home: const PalcesScreen()));

    expect(find.text('My places'), findsOneWidget);
    expect(find.text('No favorite places yet'), findsOneWidget);
    expect(find.text('0 favorite places'), findsOneWidget);
  });

  testWidgets('adds a place and shows it in the feed', (tester) async {
    await tester.pumpWidget(buildTestApp(home: const PalcesScreen()));

    await openAddForm(tester);
    expect(find.text('Add place'), findsOneWidget);
    expect(find.text('Add a photo'), findsOneWidget);
    expect(find.text('Add a location'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'A little pause by the river'),
      'Moda seaside walk',
    );
    await tester.tap(find.text('Walk'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Why you love it, in a line or two'),
      'Best at sunset.',
    );
    await tester.pump();
    expect(find.text('15 / 200'), findsOneWidget);
    await tapSave(tester);

    expect(find.text('Moda seaside walk'), findsOneWidget);
    expect(find.text('Best at sunset.'), findsOneWidget);
    expect(find.text('1 favorite place'), findsOneWidget);
    expect(find.text('No favorite places yet'), findsNothing);
  });

  testWidgets('does not save without a name', (tester) async {
    await tester.pumpWidget(buildTestApp(home: const PalcesScreen()));

    await openAddForm(tester);
    await tapSave(tester);

    // Still on the form; closing it shows nothing was added.
    expect(find.text('Add a photo'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.text('No favorite places yet'), findsOneWidget);
  });

  testWidgets('filters places by type and search', (tester) async {
    await tester.pumpWidget(buildTestApp(home: const PalcesScreen()));

    await addPlace(tester, 'Corner café', type: 'Café');
    expect(find.text('Corner café'), findsOneWidget);

    await tester.tap(find.text('Views'));
    await tester.pumpAndSettle();
    expect(find.text('Corner café'), findsNothing);
    expect(find.text('No places match'), findsOneWidget);

    await tester.tap(find.text('Show all places'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Find a favorite place'),
      'corner',
    );
    await tester.pumpAndSettle();
    expect(find.text('Corner café'), findsOneWidget);
  });

  testWidgets('opens details, edits and removes with undo', (tester) async {
    await tester.pumpWidget(buildTestApp(home: const PalcesScreen()));

    await addPlace(tester, 'Galata Tower view', type: 'Viewpoint');
    await tester.tap(find.text('Galata Tower view'));
    await tester.pumpAndSettle();

    expect(find.text('Saved place'), findsOneWidget);

    await tester.tap(find.text('Edit place'));
    await tester.pumpAndSettle();
    // The first field on the edit form is the place name.
    await tester.enterText(find.byType(TextField).first, 'Galata at dusk');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Galata at dusk'), findsOneWidget);

    // Let "Changes saved" time out so the undo snackbar can show.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // The heart sits on the photo, whose list item merges its label.
    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w is CircleIconButton && w.semanticLabel == 'Remove from my places',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Galata at dusk'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Galata at dusk'), findsOneWidget);
  });

  testWidgets('shows the glass tab bar with the Add button', (tester) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.bySemanticsLabel('Discover'), findsOneWidget);
    expect(find.bySemanticsLabel('Map'), findsOneWidget);
    expect(find.bySemanticsLabel('Account'), findsOneWidget);
    expect(find.bySemanticsLabel('Add a place'), findsOneWidget);
  });

  testWidgets('Add asks camera or library, then opens the form with the '
      'photo', (tester) async {
    final camera = _FakeCamera();
    ImagePickerPlatform.instance = camera;
    useTallScreen(tester);

    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.bySemanticsLabel('Add a place'));
    await tester.pumpAndSettle();
    expect(find.text('Choose from library'), findsOneWidget);
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();

    expect(camera.lastSource, ImageSource.camera);
    expect(find.text('Add place'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove photo'), findsOneWidget);
    expect(find.bySemanticsLabel('Add more photos'), findsOneWidget);

    // Closing the form goes back to Discover without saving.
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(
      find.text('Sign in to see the places people share.'),
      findsOneWidget,
    );
  });

  testWidgets('tab bar shrinks while a page scrolls up or down', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    double scale() => tester
        .widget<AnimatedScale>(
          find.ancestor(
            of: find.byType(GlassTabBar),
            matching: find.byType(AnimatedScale),
          ),
        )
        .scale;
    final page = tester.element(find.text('Discover').first);
    ScrollMetrics metrics(Axis axis) => FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 500,
      pixels: 10,
      viewportDimension: 600,
      axisDirection: axis == Axis.vertical
          ? AxisDirection.down
          : AxisDirection.right,
      devicePixelRatio: 1,
    );

    ScrollStartNotification(
      metrics: metrics(Axis.horizontal),
      context: page,
    ).dispatch(page);
    await tester.pump();
    expect(scale(), 1);

    ScrollStartNotification(
      metrics: metrics(Axis.vertical),
      context: page,
    ).dispatch(page);
    await tester.pump();
    expect(scale(), 0.65);

    ScrollEndNotification(
      metrics: metrics(Axis.vertical),
      context: page,
    ).dispatch(page);
    await tester.pump();
    expect(scale(), 1);

    // Flutter reports "idle" right after the end; the bar stays full size.
    UserScrollNotification(
      metrics: metrics(Axis.vertical),
      context: page,
      direction: ScrollDirection.idle,
    ).dispatch(page);
    await tester.pump();
    expect(scale(), 1);
  });
}
