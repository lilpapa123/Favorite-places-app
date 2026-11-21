import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Profile pictures are kept on this phone, in the app's private documents
/// folder, one per account: `profile_<uid>_<timestamp>.jpg`. The timestamp
/// makes each new photo a new file, so Flutter's image cache never shows the
/// old one.
class ProfilePhotoStore {
  const ProfilePhotoStore();

  Future<Directory> _folder() => getApplicationDocumentsDirectory();

  String _prefix(String uid) => 'profile_${uid}_';

  /// The current photo for [uid], or null if none was set.
  Future<File?> load(String uid) async {
    final folder = await _folder();
    final files = folder
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith(_prefix(uid)))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    return files.isEmpty ? null : files.first;
  }

  /// Copies [picked] in as the new photo and removes older ones.
  Future<File> save(String uid, File picked) async {
    await remove(uid);
    final folder = await _folder();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return picked.copy('${folder.path}/${_prefix(uid)}$stamp.jpg');
  }

  Future<void> remove(String uid) async {
    final folder = await _folder();
    for (final file in folder.listSync().whereType<File>()) {
      if (file.uri.pathSegments.last.startsWith(_prefix(uid))) {
        await file.delete();
      }
    }
  }
}

final profilePhotoStoreProvider = Provider<ProfilePhotoStore>(
  (ref) => const ProfilePhotoStore(),
);

/// The signed-in user's profile picture on this phone (null if none).
/// Invalidate it after saving or removing a photo.
final profilePhotoProvider = FutureProvider.family<File?, String>(
  (ref, uid) => ref.watch(profilePhotoStoreProvider).load(uid),
);
