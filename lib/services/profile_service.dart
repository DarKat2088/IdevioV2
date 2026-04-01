import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  final ImagePicker _picker = ImagePicker();

  /// ВЫБОР ИЗОБРАЖЕНИЯ (локально)
  Future<File?> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return null;
    return File(picked.path);
  }

  /// ОБНОВЛЕНИЕ ИМЕНИ
  Future<void> updateNickname(User user, String nickname) async {
    await user.updateDisplayName(nickname.trim());
    await user.reload();
  }

  /// ЛОКАЛЬНОЕ ОБНОВЛЕНИЕ АВАТАРКИ (ТОЛЬКО В AUTH)
  Future<void> updateAvatar(User user, String localPath) async {


    await user.updatePhotoURL(localPath);
    await user.reload();
  }

  Future<User?> getCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }

  Stream<User?> authStream() {
    return FirebaseAuth.instance.authStateChanges();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}