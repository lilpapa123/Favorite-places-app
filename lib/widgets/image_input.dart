import 'dart:io';

import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/ascii_label.dart';
import 'package:favorite_places/widgets/ascii_photo.dart';
import 'package:favorite_places/widgets/blinking_cursor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ImageInput extends StatefulWidget {
  const ImageInput({super.key, this.onImagePicked});

  final ValueChanged<File?>? onImagePicked;

  @override
  State<ImageInput> createState() {
    return _ImageInputState();
  }
}

class _ImageInputState extends State<ImageInput> {
  static const int _maxImageWidth = 1200;
  static const int _imageQuality = 85;
  static const double _emptyHeight = 148;
  static const double _photoAspectRatio = 4 / 3;

  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isPickingImage = false;

  Future<void> _takePicture() async {
    if (_isPickingImage) {
      return;
    }

    setState(() => _isPickingImage = true);

    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: _maxImageWidth.toDouble(),
        imageQuality: _imageQuality,
      );

      if (!mounted || pickedImage == null) {
        return;
      }

      final imageFile = File(pickedImage.path);
      setState(() => _selectedImage = imageFile);
      widget.onImagePicked?.call(imageFile);
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_messageForError(error));
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  String _messageForError(PlatformException error) {
    switch (error.code) {
      case 'no_available_camera':
        return 'This device reports no camera. Simulators have no camera - '
            'run the app on a real iPhone or Android phone.';
      case 'camera_access_denied':
        return 'Camera access was denied. If you are on the iOS Simulator, '
            'it has no camera - run on a real iPhone. Otherwise allow the '
            'camera in Settings > Favorite Places.';
      case 'camera_access_restricted':
        return 'Camera access is restricted on this device (Screen Time or '
            'an MDM profile is blocking it).';
      case 'multiple_request':
        return 'The camera is already open. Close it and try again.';
      default:
        return 'Could not open the camera: ${error.message ?? error.code}';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AsciiLabel('photo'),
        const SizedBox(height: AsciiSpace.sm),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isPickingImage ? null : _takePicture,
          child: _buildField(),
        ),
      ],
    );
  }

  Widget _buildField() {
    if (_isPickingImage) {
      return Container(
        height: _emptyHeight,
        decoration: _fieldDecoration(),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '// capturing',
                style: AsciiType.meta(color: AsciiPalette.accent),
              ),
              const SizedBox(width: AsciiSpace.xs),
              const BlinkingCursor(width: 6, height: 12),
            ],
          ),
        ),
      );
    }

    if (_selectedImage != null) {
      return AspectRatio(
        aspectRatio: _photoAspectRatio,
        child: AsciiPhoto(image: _selectedImage!, caption: '// tap to retake'),
      );
    }

    return Container(
      height: _emptyHeight,
      decoration: _fieldDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_camera_outlined,
            size: 26,
            color: AsciiPalette.accent,
          ),
          const SizedBox(height: AsciiSpace.sm),
          Text('[ take picture ]', style: AsciiType.body()),
        ],
      ),
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: AsciiPalette.surface,
      border: Border.all(
        color: AsciiPalette.line,
        width: AsciiShape.borderWidth,
      ),
    );
  }
}
