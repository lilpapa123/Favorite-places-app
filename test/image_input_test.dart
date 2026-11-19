import 'dart:io';

import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/image_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class _FakeImagePickerPlatform extends ImagePickerPlatform {
  _FakeImagePickerPlatform({this.onGetImage});

  final Future<XFile?> Function()? onGetImage;

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) {
    return onGetImage?.call() ?? Future<XFile?>.value();
  }
}

Widget _buildHarness({ValueChanged<File?>? onImagePicked}) {
  return MaterialApp(
    theme: AsciiTheme.data,
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

Future<void> _tapCamera(WidgetTester tester) async {
  await tester.tap(find.textContaining('take picture'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows a message when the device has no camera', (tester) async {
    ImagePickerPlatform.instance = _FakeImagePickerPlatform(
      onGetImage: () async => throw PlatformException(
        code: 'no_available_camera',
        message: 'No cameras available for taking pictures.',
      ),
    );

    await tester.pumpWidget(_buildHarness());
    await _tapCamera(tester);

    expect(find.textContaining('no camera'), findsOneWidget);
    expect(find.textContaining('take picture'), findsOneWidget);
  });

  testWidgets('shows a message when camera access is denied', (tester) async {
    ImagePickerPlatform.instance = _FakeImagePickerPlatform(
      onGetImage: () async =>
          throw PlatformException(code: 'camera_access_denied'),
    );

    await tester.pumpWidget(_buildHarness());
    await _tapCamera(tester);

    expect(find.textContaining('Camera access was denied'), findsOneWidget);
  });

  testWidgets('stays usable when the picker is cancelled', (tester) async {
    var notified = false;
    ImagePickerPlatform.instance = _FakeImagePickerPlatform(
      onGetImage: () async => null,
    );

    await tester.pumpWidget(
      _buildHarness(onImagePicked: (_) => notified = true),
    );
    await _tapCamera(tester);

    expect(find.textContaining('take picture'), findsOneWidget);
    expect(notified, isFalse);
  });
}
