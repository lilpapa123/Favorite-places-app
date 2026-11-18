import 'dart:io';

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
  static const double _previewHeight = 160;

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
    Widget content = TextButton.icon(
      icon: const Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 40),
      label: const Text(
        'Take Picture',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
      onPressed: _isPickingImage ? null : _takePicture,
    );

    if (_isPickingImage) {
      content = const CircularProgressIndicator();
    } else if (_selectedImage != null) {
      content = GestureDetector(
        onTap: _takePicture,
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    return Container(
      height: _selectedImage != null ? _previewHeight : 100,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          width: 1,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.center,
      child: content,
    );
  }
}
