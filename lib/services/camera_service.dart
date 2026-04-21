import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) return null;

      return await _compressAndSave(image);
    } catch (e) {
      return null;
    }
  }

  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) return null;

      return await _compressAndSave(image);
    } catch (e) {
      return null;
    }
  }

  Future<File?> _compressAndSave(XFile image) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'menu_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetPath = '${appDir.path}/$fileName';

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      image.path,
      targetPath,
      quality: 70,
      minWidth: 800,
      minHeight: 800,
    );

    if (compressedFile == null) return null;

    return File(compressedFile.path);
  }

  Future<File?> captureMenuImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null) return null;

      return await _compressAndSave(image);
    } catch (e) {
      return null;
    }
  }
}
