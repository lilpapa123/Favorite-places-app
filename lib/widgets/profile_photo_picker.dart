import 'dart:io';

import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/services/profile_photo.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/image_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Take, choose or remove the profile photo. It is saved straight away.
Future<void> changeProfilePhoto(
  BuildContext context, {
  required String uid,
  required bool hasPhoto,
}) async {
  // Read before any await: the calling screen can close while the picker is up.
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final store = container.read(profilePhotoStoreProvider);
  final choice = await askPhotoSource(
    context,
    title: l10n.profilePhoto,
    hasPhoto: hasPhoto,
  );
  if (choice == null) {
    return;
  }
  try {
    if (choice == 'remove') {
      await store.remove(uid);
    } else {
      final picked = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 600,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked == null) {
        return;
      }
      await store.save(uid, File(picked.path));
    }
    container.invalidate(profilePhotoProvider(uid));
  } on PlatformException catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text(photoErrorMessage(l10n, error))),
    );
  }
}

/// 'camera', 'gallery' or 'remove' (only offered with [hasPhoto]); null when
/// dismissed.
Future<String?> askPhotoSource(
  BuildContext context, {
  required String title,
  required bool hasPhoto,
}) {
  final l10n = context.l10n;
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
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
            Text(title, style: AppText.title()),
            const SizedBox(height: AppSpace.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.photo_camera_outlined,
                color: AppColors.accent,
              ),
              title: Text(l10n.takePhoto, style: AppText.row()),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.photo_library_outlined,
                color: AppColors.accent,
              ),
              title: Text(l10n.chooseFromLibrary, style: AppText.row()),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            if (hasPhoto)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline, color: AppColors.accent),
                title: Text(
                  l10n.removePhoto,
                  style: AppText.row(color: AppColors.accent),
                ),
                onTap: () => Navigator.of(ctx).pop('remove'),
              ),
          ],
        ),
      ),
    ),
  );
}
