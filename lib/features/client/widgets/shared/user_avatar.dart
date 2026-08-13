import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Avatar de profil : affiche la photo si définie, sinon les initiales.
/// Point d'entrée unique pour ce rendu — évite de dupliquer la logique si
/// l'avatar doit apparaître ailleurs que `profile_screen.dart` plus tard.
class UserAvatar extends StatelessWidget {
  final String fullName;
  final String? photoUrl;
  final File? localImage;
  final double radius;
  final bool isLoading;

  const UserAvatar({
    super.key,
    required this.fullName,
    this.photoUrl,
    this.localImage,
    this.radius = 32,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            border: Border.all(color: AppColors.surfaceCard, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: localImage != null
                ? Image.file(
                    localImage!,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    errorBuilder: (context, error, stackTrace) => _initials(),
                  )
                : (photoUrl != null && photoUrl!.isNotEmpty)
                    ? Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                        errorBuilder: (context, error, stackTrace) =>
                            _initials(),
                      )
                    : _initials(),
          ),
        ),
        if (isLoading)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ink.withValues(alpha: 0.35),
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.surfaceCard,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
        style: AppTextStyles.displayMedium(color: AppColors.surfaceCard)
            .copyWith(fontSize: radius * 0.8, fontWeight: FontWeight.w600),
      ),
    );
  }
}
