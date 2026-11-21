import 'dart:io';
import 'dart:ui' as ui;

import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/place_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Photo field for the add form: a dashed drop zone that asks "camera or
/// library?", then shows the photo with a "Change photo" pill.
class ImageInput extends StatefulWidget {
  const ImageInput({super.key, this.onImagePicked, this.initialImage});

  final ValueChanged<File?>? onImagePicked;

  /// A photo already taken (e.g. from the tab bar's camera button).
  final File? initialImage;

  @override
  State<ImageInput> createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  static const int _maxImageWidth = 1200;
  static const int _imageQuality = 85;
  static const double _emptyHeight = 124;
  static const double _photoHeight = 200;

  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
  }

  Future<void> _chooseSource() async {
    if (_isPickingImage) {
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            0,
            AppSpace.page,
            AppSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Choose a photo', style: AppText.title()),
              const SizedBox(height: AppSpace.md),
              _SourceTile(
                icon: Icons.photo_camera_outlined,
                label: 'Take photo',
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              const SizedBox(height: AppSpace.sm),
              _SourceTile(
                icon: Icons.photo_library_outlined,
                label: 'Choose from library',
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!mounted || _isPickingImage) {
      return;
    }
    setState(() => _isPickingImage = true);
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: source,
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
      _showMessage(photoErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final image = _selectedImage;

    return Semantics(
      button: true,
      label: image == null ? 'Add a photo' : 'Change photo',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isPickingImage ? null : _chooseSource,
        child: image == null ? _buildEmpty() : _buildPhoto(image),
      ),
    );
  }

  /// Dashed card: pink camera circle, "Add a photo", two quiet lines.
  Widget _buildEmpty() {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(),
      child: Container(
        height: _emptyHeight,
        padding: const EdgeInsets.symmetric(horizontal: 19),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardAll,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: _isPickingImage
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.accent,
                      ),
                    )
                  : const AppIcon('camera_accent'),
            ),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add a photo',
                    style: AppText.title(color: AppColors.accent)
                        .copyWith(height: 1.4),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'Take one or choose from library',
                    style: AppText.meta().copyWith(height: 1.4),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'Optional, but full of memories.',
                    style: AppText.meta(color: AppColors.faint)
                        .copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(File image) {
    return SizedBox(
      height: _photoHeight,
      child: ClipRRect(
        borderRadius: AppRadius.cardAll,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PlacePhoto(image: image, tint: AppColors.tints.first),
            Positioned(
              right: AppSpace.md,
              bottom: AppSpace.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: AppSpace.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Change photo',
                  style: AppText.button(color: Colors.white, size: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: AppRadius.fieldAll,
      child: InkWell(
        borderRadius: AppRadius.fieldAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: 14,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accent),
              const SizedBox(width: AppSpace.md),
              Text(label, style: AppText.bodyStrong()),
            ],
          ),
        ),
      ),
    );
  }
}

/// 1 px dashed rounded border, like the design's photo drop zone.
class _DashedBorderPainter extends CustomPainter {
  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      const Radius.circular(AppRadius.card),
    );
    final paint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()..addRRect(rrect);
    for (final ui.PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + _dash),
          paint,
        );
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}

/// A friendly message for an image_picker failure, shared by the add form
/// and the tab bar's camera button.
String photoErrorMessage(PlatformException error) {
  switch (error.code) {
    case 'no_available_camera':
      return 'This device has no camera. Simulators have no camera - '
          'choose a photo from the library, or use a real phone.';
    case 'camera_access_denied':
      return 'Camera access was denied. Allow it in '
          'Settings > Favorite Places.';
    case 'photo_access_denied':
      return 'Photo library access was denied. Allow it in '
          'Settings > Favorite Places.';
    case 'camera_access_restricted':
      return 'Camera access is restricted on this device (Screen Time or '
          'an MDM profile is blocking it).';
    case 'multiple_request':
      return 'The picker is already open. Close it and try again.';
    default:
      return 'Could not get a photo: ${error.message ?? error.code}';
  }
}
