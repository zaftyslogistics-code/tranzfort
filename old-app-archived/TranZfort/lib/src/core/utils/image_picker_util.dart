import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImagePickerUtil {
  static final ImagePicker _picker = ImagePicker();
  static const int _maxDimension = 1920;

  /// Picks an image, optionally crops it, and compresses it.
  /// Returns the compressed `File` or null if cancelled.
  static Future<File?> pickAndCompressImage({
    required BuildContext context,
    required ImageSource source,
    bool crop = true,
    int quality = 80,
  }) async {
    try {
      // 1. Pick Image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100, // Handle compression later
      );

      if (pickedFile == null) return null;

      File imageFile = File(pickedFile.path);

      // 2. Crop Image (Optional)
      if (crop && context.mounted) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: imageFile.path,
          compressQuality: 100,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Document',
              toolbarColor: Theme.of(context).primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(title: 'Crop Document'),
          ],
        );

        if (croppedFile != null) {
          imageFile = File(croppedFile.path);
        } else {
          return null; // User cancelled cropping
        }
      }

      // 3. Compress Image
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressedXFile =
          await FlutterImageCompress.compressAndGetFile(
            imageFile.path,
            targetPath,
            quality: quality,
            minWidth: _maxDimension,
            minHeight: _maxDimension,
            format: CompressFormat.jpeg,
            keepExif: false,
          );

      if (compressedXFile != null) {
        return File(compressedXFile.path);
      }

      return imageFile; // Fallback to original if compression fails
    } catch (e) {
      debugPrint('Error picking/compressing image: $e');
      return null;
    }
  }
}
