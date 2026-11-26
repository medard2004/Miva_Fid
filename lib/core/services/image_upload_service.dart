import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';

class PickedImageData {
  final Uint8List bytes;
  final String filename;
  final String path;

  const PickedImageData({
    required this.bytes,
    required this.filename,
    required this.path,
  });

  MultipartFile toMultipartFile() =>
      MultipartFile.fromBytes(bytes, filename: filename);
}

class ImageValidationException implements Exception {
  final String message;
  const ImageValidationException(this.message);

  @override
  String toString() => message;
}

/// Service centralisé de sélection, recadrage, validation et conversion
/// d'image compatible Web (`XFile.readAsBytes()`, sans `dart:io File`) et Mobile.
class ImageUploadService {
  ImageUploadService._();

  static const int maxBytes = 5 * 1024 * 1024; // 5 Mo
  static const Set<String> allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  /// Sélectionne une image depuis la galerie (ou caméra), la recadre
  /// optionnellement avec `image_cropper`, puis valide son format et sa taille.
  static Future<PickedImageData?> pickAndCropImage(
    BuildContext context, {
    ImageSource source = ImageSource.gallery,
    bool enableCrop = true,
    CropAspectRatio? aspectRatio,
    double maxWidth = 1200,
    double maxHeight = 1200,
    int imageQuality = 85,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
    if (picked == null) return null;

    var finalPath = picked.path;
    var finalName = picked.name.isNotEmpty ? picked.name : 'image.jpg';
    Uint8List bytes;

    if (enableCrop && context.mounted) {
      try {
        final cropped = await ImageCropper().cropImage(
          sourcePath: picked.path,
          aspectRatio: aspectRatio,
          compressQuality: imageQuality,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Recadrer l\'image',
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: aspectRatio != null,
            ),
            IOSUiSettings(
              title: 'Recadrer l\'image',
              aspectRatioLockEnabled: aspectRatio != null,
            ),
            WebUiSettings(
              context: context,
            ),
          ],
        );

        if (cropped == null) return null;
        finalPath = cropped.path;
        bytes = await cropped.readAsBytes();
        if (!finalName.contains('.')) {
          finalName = 'image.jpg';
        }
      } catch (e) {
        debugPrint('[ImageUploadService] Recadrage indisponible, repli image brute: $e');
        bytes = await picked.readAsBytes();
      }
    } else {
      bytes = await picked.readAsBytes();
    }

    _validate(finalName, bytes);

    return PickedImageData(
      bytes: bytes,
      filename: finalName,
      path: finalPath,
    );
  }

  static void _validate(String filename, Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const ImageValidationException('Le fichier image est vide.');
    }
    if (bytes.length > maxBytes) {
      throw const ImageValidationException(
        'L\'image dépasse la taille maximale autorisée (5 Mo).',
      );
    }
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex != -1) {
      final ext = filename.substring(dotIndex + 1).toLowerCase();
      if (!allowedExtensions.contains(ext) && !filename.startsWith('blob:')) {
        throw const ImageValidationException(
          'Format non supporté. Utilisez JPG, PNG ou WebP.',
        );
      }
    }
  }
}
