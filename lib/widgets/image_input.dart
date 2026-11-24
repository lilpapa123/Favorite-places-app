import 'dart:ui' as ui;

import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/place_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Photo field for the add form: a dashed drop zone that asks "camera or
/// library?", then a row of the chosen photos that scrolls sideways, each
/// with a remove button, and a tile to add more (up to [maxPlacePhotos]).
class ImageInput extends StatefulWidget {
  const ImageInput({super.key, this.onChanged, this.initialPhotos = const []});

  final ValueChanged<List<String>>? onChanged;

  /// Photos already chosen (e.g. from the tab bar's camera button).
  final List<String> initialPhotos;

  @override
  State<ImageInput> createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  static const double _maxImageWidth = 1200;
  static const int _imageQuality = 85;
  static const double _emptyHeight = 124;
  static const double _tileSize = 120;

  final ImagePicker _imagePicker = ImagePicker();
  late List<String> _photos = [...widget.initialPhotos];
  bool _isPickingImage = false;

  int get _room => maxPlacePhotos - _photos.length;

  Future<void> _chooseSource() async {
    if (_isPickingImage || _room <= 0) {
      return;
    }
    final source = await chooseImageSource(context);
    if (source != null) {
      await _pickImages(source);
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    if (!mounted || _isPickingImage) {
      return;
    }
    setState(() => _isPickingImage = true);
    try {
      // The library allows several at once; image_picker needs a limit of 2+.
      final picked = source == ImageSource.gallery && _room > 1
          ? await _imagePicker.pickMultiImage(
              maxWidth: _maxImageWidth,
              imageQuality: _imageQuality,
              limit: _room,
            )
          : [
              ?await _imagePicker.pickImage(
                source: source,
                maxWidth: _maxImageWidth,
                imageQuality: _imageQuality,
              ),
            ];
      if (!mounted || picked.isEmpty) {
        return;
      }
      _setPhotos([..._photos, for (final x in picked.take(_room)) x.path]);
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(photoErrorMessage(context.l10n, error));
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _setPhotos(List<String> photos) {
    setState(() => _photos = photos);
    widget.onChanged?.call(photos);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) {
      return Semantics(
        button: true,
        label: context.l10n.addPhoto,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isPickingImage ? null : _chooseSource,
          child: _buildEmpty(),
        ),
      );
    }
    return SizedBox(
      height: _tileSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _photos.length + (_room > 0 ? 1 : 0),
        separatorBuilder: (context, i) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (context, i) =>
            i == _photos.length ? _buildAddTile() : _buildPhoto(i),
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
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardAll,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: _isPickingImage
                  ? _spinner()
                  : const AppIcon('camera_accent'),
            ),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.addPhoto,
                    style: AppText.title(color: AppColors.accent)
                        .copyWith(height: 1.4),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    context.l10n.addPhotoHint,
                    style: AppText.meta().copyWith(height: 1.4),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    context.l10n.addPhotoNote,
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

  Widget _spinner() => SizedBox(
    width: 22,
    height: 22,
    child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.accent),
  );

  /// Dashed square with a camera: adds more photos.
  Widget _buildAddTile() {
    return Semantics(
      container: true,
      button: true,
      label: context.l10n.addMorePhotos,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isPickingImage ? null : _chooseSource,
        child: CustomPaint(
          foregroundPainter: _DashedBorderPainter(),
          child: Container(
            width: _tileSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.cardAll,
            ),
            child: _isPickingImage
                ? _spinner()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon('camera_accent'),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        '${_photos.length} / $maxPlacePhotos',
                        style: AppText.meta().copyWith(fontSize: 11),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(int index) {
    return SizedBox(
      width: _tileSize,
      child: ClipRRect(
        borderRadius: AppRadius.cardAll,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PlacePhoto(photo: _photos[index], tint: AppColors.tints.first),
            Positioned(
              right: 0,
              top: 0,
              child: Semantics(
                container: true,
                button: true,
                label: context.l10n.removePhoto,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _setPhotos([..._photos]..removeAt(index)),
                  // 38 pt to tap, 26 pt to see.
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks "Take photo or choose from library?" on a floating frosted-glass
/// panel above the tab bar; null when dismissed by tapping outside. Used by
/// the photo field and the tab bar's Add button.
Future<ImageSource?> chooseImageSource(BuildContext context) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<ImageSource>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x99000000),
    transitionDuration: reduceMotion ? Duration.zero : AppMotion.medium,
    transitionBuilder: (ctx, animation, _, child) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: AppMotion.ease)),
        child: child,
      ),
    ),
    pageBuilder: (ctx, _, _) => const _GlassSourcePanel(),
  );
}

class _GlassSourcePanel extends StatelessWidget {
  const _GlassSourcePanel();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void pick(ImageSource s) => Navigator.of(context).pop(s);
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Tapping the dim area closes it.
          Positioned.fill(
            child: GestureDetector(onTap: () => Navigator.of(context).pop()),
          ),
          Positioned(
            left: AppSpace.lg,
            right: AppSpace.lg,
            bottom: MediaQuery.paddingOf(context).bottom + 96,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.choosePhoto,
                        style: AppText.bodyStrong(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Row(
                        children: [
                          _GlassOption(
                            icon: Icons.photo_camera_rounded,
                            label: l10n.takePhoto,
                            onTap: () => pick(ImageSource.camera),
                          ),
                          _GlassOption(
                            icon: Icons.photo_library_rounded,
                            label: l10n.chooseFromLibrary,
                            onTap: () => pick(ImageSource.gallery),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A glass circle with an icon and a label under it.
class _GlassOption extends StatelessWidget {
  const _GlassOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppText.label(color: Colors.white),
                ),
              ],
            ),
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
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}

/// A friendly message for an image_picker failure, shared by the add form
/// and the tab bar's camera button.
String photoErrorMessage(AppLocalizations l10n, PlatformException error) {
  switch (error.code) {
    case 'no_available_camera':
      return l10n.errNoCamera;
    case 'camera_access_denied':
      return l10n.errCameraDenied;
    case 'photo_access_denied':
      return l10n.errPhotosDenied;
    case 'camera_access_restricted':
      return l10n.errCameraRestricted;
    case 'multiple_request':
      return l10n.errPickerOpen;
    default:
      return l10n.errCouldNotGetPhoto(error.message ?? error.code);
  }
}
