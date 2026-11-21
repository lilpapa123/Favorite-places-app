import 'dart:io';

import 'package:favorite_places/l10n/app_localizations.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/image_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class _FakeImagePickerPlatform extends ImagePickerPlatform {
  _FakeImagePickerPlatform({this.onGetImage});

  final Future<XFile?> Function(ImageSource source)? onGetImage;
  ImageSource? lastSource;

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) {
    lastSource = source;
    return onGetImage?.call(source) ?? Future<XFile?>.value();
  }
}

Widget _buildHarness({ValueChanged<File?>? onImagePicked}) {
  return MaterialApp(
    theme: AppTheme.data(Brightness.light),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ImageInput(onImagePicked: onImagePicked),
      ),
    ),
  );
}

/// Opens the "Add a photo" sheet and picks [option].
Future<void> _pick(WidgetTester tester, String option) async {
  await tester.tap(find.text('Add a photo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('offers camera and library', (tester) async {
    await tester.pumpWidget(_buildHarness());

    await tester.tap(find.text('Add a photo'));
    await tester.pumpAndSettle();

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from library'), findsOneWidget);
  });

  testWidgets('uses the library when chosen', (tester) async {
    final fake = _FakeImagePickerPlatform(onGetImage: (_) async => null);
    ImagePickerPlatform.instance = fake;

    await tester.pumpWidget(_buildHarness());
    await _pick(tester, 'Choose from library');

    expect(fake.lastSource, ImageSource.gallery);
  });

  testWidgets('shows a message when the device has no camera', (tester) async {
    ImagePickerPlatform.instance = _FakeImagePickerPlatform(
      onGetImage: (_) async => throw PlatformException(
        code: 'no_available_camera',
        message: 'No cameras available for taking pictures.',
      ),
    );

    await tester.pumpWidget(_buildHarness());
    await _pick(tester, 'Take photo');

    expect(find.textContaining('no camera'), findsOneWidget);
    expect(find.text('Add a photo'), findsOneWidget);
  });

  testWidgets('shows a message when camera access is denied', (tester) async {
    ImagePickerPlatform.instance = _FakeImagePickerPlatform(
      onGetImage: (_) async =>
          throw PlatformException(code: 'camera_access_denied'),
    );

    await tester.pumpWidget(_buildHarness());
    await _pick(tester, 'Take photo');

    expect(find.textContaining('Camera access was denied'), findsOneWidget);
  });

  testWidgets('stays usable when the picker is cancelled', (tester) async {
    var notified = false;
    ImagePickerPlatform.instance = _FakeImagePickerPlatform(
      onGetImage: (_) async => null,
    );

    await tester.pumpWidget(
      _buildHarness(onImagePicked: (_) => notified = true),
    );
    await _pick(tester, 'Take photo');

    expect(find.text('Add a photo'), findsOneWidget);
    expect(notified, isFalse);
  });
}
