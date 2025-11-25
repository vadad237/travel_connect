import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery or camera
  Future<XFile?> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Upload profile image to Firebase Storage
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      print('🔵 [StorageService] Uploading image for user: $userId');
      
      final String fileName = 'profile_$userId${path.extension(imageFile.path)}';
      final Reference ref = _storage.ref().child('profile_images').child(fileName);

      print('🔵 [StorageService] Uploading to: profile_images/$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('✅ [StorageService] Upload successful: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('🔴 [StorageService] Error uploading image: $e');
      return null;
    }
  }

  // Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('✅ [StorageService] Image deleted successfully');
    } catch (e) {
      print('🔴 [StorageService] Error deleting image: $e');
    }
  }
}