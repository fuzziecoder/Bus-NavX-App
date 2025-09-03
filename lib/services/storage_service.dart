import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(File imageFile, String folder) async {
    try {
      final String fileName = path.basename(imageFile.path);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '$folder/$timestamp-$fileName';

      final Reference storageRef = _storage.ref().child(filePath);
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot taskSnapshot = await uploadTask;

      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> uploadMultipleImages(
      List<File> imageFiles, String folder) async {
    try {
      final List<String> downloadUrls = [];

      for (final File imageFile in imageFiles) {
        final String url = await uploadImage(imageFile, folder);
        downloadUrls.add(url);
      }

      return downloadUrls;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
    } catch (e) {
      rethrow;
    }
  }
}