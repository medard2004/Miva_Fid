import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      final mediaSize = MediaQuery.sizeOf(context);
      final isCompact = mediaSize.width < 600 || mediaSize.height < 640;
      final cropperW =
          (isCompact ? mediaSize.width - 24 : (mediaSize.width * 0.6).clamp(320, 500))
              .clamp(220, 500)
              .toInt();
      final cropperH =
          (isCompact ? mediaSize.height - 230 : (mediaSize.height * 0.52).clamp(240, 440))
              .clamp(220, 460)
              .toInt();

      try {
        final cropped = await ImageCropper().cropImage(
          sourcePath: picked.path,
          aspectRatio: aspectRatio,
          maxWidth: maxWidth.toInt(),
          maxHeight: maxHeight.toInt(),
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
              presentStyle: WebPresentStyle.dialog,
              barrierColor: Colors.black87,
              size: CropperSize(width: cropperW, height: cropperH),
              viewwMode: WebViewMode.mode_1,
              dragMode: WebDragMode.move,
              minContainerWidth: 200,
              minContainerHeight: 200,
              rotatable: true,
              scalable: true,
              zoomable: true,
              zoomOnTouch: true,
              zoomOnWheel: true,
              translations: const WebTranslations(
                title: 'Recadrer l\'image',
                rotateLeftTooltip: 'Pivoter à gauche (90°)',
                rotateRightTooltip: 'Pivoter à droite (90°)',
                cancelButton: 'Annuler',
                cropButton: 'Valider',
              ),
              customDialogBuilder: (cropper, initCropper, crop, rotate, scale) =>
                  ResponsiveWebCropperDialog(
                cropper: cropper,
                initCropper: initCropper,
                crop: crop,
                rotate: rotate,
                scale: scale,
              ),
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

class ResponsiveWebCropperDialog extends StatefulWidget {
  final Widget cropper;
  final void Function() initCropper;
  final Future<String?> Function() crop;
  final void Function(RotationAngle) rotate;
  final void Function(num) scale;

  const ResponsiveWebCropperDialog({
    super.key,
    required this.cropper,
    required this.initCropper,
    required this.crop,
    required this.rotate,
    required this.scale,
  });

  @override
  State<ResponsiveWebCropperDialog> createState() =>
      _ResponsiveWebCropperDialogState();
}

class _ResponsiveWebCropperDialogState
    extends State<ResponsiveWebCropperDialog> {
  bool _processing = false;
  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    widget.initCropper();
  }

  Future<void> _submitCrop() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final result = await widget.crop();
      if (mounted) {
        Navigator.of(context).pop(result);
      }
      return;
    } catch (e) {
      debugPrint('[ResponsiveWebCropperDialog] Erreur recadrage: $e');
    }
    if (mounted) {
      setState(() => _processing = false);
    }
  }

  void _safeRotate(RotationAngle angle) {
    try {
      widget.rotate(angle);
    } catch (e) {
      debugPrint('[ResponsiveWebCropperDialog] Rotation ignoree: $e');
    }
  }

  void _safeScale(double value) {
    setState(() => _zoom = value);
    try {
      widget.scale(value);
    } catch (e) {
      debugPrint('[ResponsiveWebCropperDialog] Zoom ignore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isCompact = screen.width < 600 || screen.height < 640;
    final desktopW = (screen.width - 80).clamp(280.0, 500.0);
    final desktopH = (screen.height * 0.50).clamp(220.0, 420.0);

    final body = SafeArea(
      child: Column(
        mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // En-tête
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 10, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recadrer l\'image',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Annuler',
                  onPressed: _processing
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, size: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Zone de recadrage responsive avec contraintes explicites pour HtmlElementView
          if (isCompact)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (ctx, constraints) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.black12,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: widget.cropper,
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: desktopW,
                  height: desktopH,
                  color: Colors.black12,
                  child: widget.cropper,
                ),
              ),
            ),

          // Barre d'outils (rotation + zoom)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Pivoter à gauche',
                  onPressed: _processing
                      ? null
                      : () => _safeRotate(RotationAngle.counterClockwise90),
                  icon: const Icon(LucideIcons.rotateCcw, size: 20),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.zoomIn, size: 16),
                Expanded(
                  child: Slider(
                    value: _zoom,
                    min: 1.0,
                    max: 3.0,
                    divisions: 20,
                    activeColor: AppColors.primary,
                    onChanged: _processing ? null : _safeScale,
                  ),
                ),
                IconButton(
                  tooltip: 'Pivoter à droite',
                  onPressed: _processing
                      ? null
                      : () => _safeRotate(RotationAngle.clockwise90),
                  icon: const Icon(LucideIcons.rotateCw, size: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Actions Annuler / Valider toujours visibles
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _processing
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _processing ? null : _submitCrop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _processing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.check, size: 18),
                    label: Text(_processing ? 'Traitement...' : 'Valider'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isCompact) {
      return Dialog.fullscreen(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: body,
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: desktopW + 40,
        child: body,
      ),
    );
  }
}
