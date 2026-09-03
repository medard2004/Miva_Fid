import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/storage/local_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../client/providers/settings_provider.dart';

/// Route de destination pour un rôle donné : le carrousel d'intro
/// correspondant s'il n'a jamais été vu, sinon directement l'écran d'auth du
/// rôle — l'intro ne doit apparaître qu'une seule fois, jamais à un retour
/// en arrière vers cet écran une fois déjà vue.
String _destinationFor(String role, bool hasSeenOnboarding) {
  return switch ((role, hasSeenOnboarding)) {
    ('client', true) => '/client/auth',
    ('client', false) => '/client/onboarding',
    ('merchant', true) => '/auth/merchant/auth',
    (_, false) => '/onboarding/merchant',
    _ => '/role-select',
  };
}

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _selectedRole;
  bool _navigating = false;

  void _handleRoleSelection(String role) {
    if (_navigating) return;
    setState(() {
      _selectedRole = role;
      _navigating = true;
    });
    unawaited(ref.read(localPreferencesProvider).setLastRole(role));
    final route = _destinationFor(role, ref.read(hasSeenOnboardingProvider));
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) {
        context.go(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Cet écran peint via les tokens statiques d'AppColors, invisibles pour
    // le système de dépendances de Flutter : observer la luminosité
    // effective est son seul déclencheur de rebuild sur une bascule
    // clair/sombre.
    ref.watch(appBrightnessProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final bool isClientSelected = _selectedRole == 'client';
    final bool isMerchantSelected = _selectedRole == 'merchant';
    final bool hasSelection = _selectedRole != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Soft ambient glow behind the content
          Positioned(
            top: -140,
            left: -60,
            right: -60,
            child: AnimatedOpacity(
              opacity: hasSelection ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.16),
                      AppColors.merchant.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(Sp.md, Sp.lg, Sp.md, bottomInset + Sp.sm),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header
                      AnimatedOpacity(
                        opacity: hasSelection ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 26),
                            )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
                            const SizedBox(height: Sp.md),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)],
                              ).createShader(bounds),
                              child: Text(
                                'Quel est votre profil ?',
                                style: AppTextStyles.h1().copyWith(
                                  color: Colors.white,
                                  fontSize: 24,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                                .animate(delay: 100.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
                          ],
                        ),
                      ),

                      // Cards
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedOpacity(
                            opacity: hasSelection && !isClientSelected ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 250),
                            child: _SelectionCard(
                              title: 'Je suis Client',
                              subtitle: 'Cumulez des points et gagnez des récompenses',
                              accent: const LinearGradient(
                                colors: [Color(0xFF2E2BF7), Color(0xFF4F46E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              icon: LucideIcons.gift,
                              isSelected: isClientSelected,
                              hasSelection: hasSelection,
                              onTap: () => _handleRoleSelection('client'),
                            ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(
                                  begin: 0.12,
                                  end: 0,
                                  duration: 400.ms,
                                  curve: Curves.easeOut,
                                ),
                          ),
                          const SizedBox(height: Sp.md),
                          AnimatedOpacity(
                            opacity: hasSelection && !isMerchantSelected ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 250),
                            child: _SelectionCard(
                              title: 'Je suis Commerçant',
                              subtitle: 'Fidélisez votre clientèle avec des tampons digitaux',
                              accent: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              icon: LucideIcons.store,
                              isSelected: isMerchantSelected,
                              hasSelection: hasSelection,
                              onTap: () => _handleRoleSelection('merchant'),
                            ).animate(delay: 220.ms).fadeIn(duration: 400.ms).slideY(
                                  begin: 0.12,
                                  end: 0,
                                  duration: 400.ms,
                                  curve: Curves.easeOut,
                                ),
                          ),
                        ],
                      ),

                      const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatefulWidget {
  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.hasSelection = false,
  });

  final String title;
  final String subtitle;
  final LinearGradient accent;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  final bool hasSelection;

  @override
  State<_SelectionCard> createState() => _SelectionCardState();
}

class _SelectionCardState extends State<_SelectionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool enableHoverScale = _isHovered && !widget.hasSelection;
    final Color accentColor = widget.accent.colors.last;

    return AnimatedScale(
      scale: widget.isSelected ? 1.02 : (enableHoverScale ? 1.012 : 1.0),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: widget.accent,
              border: Border.all(
                color: Colors.white.withValues(alpha: widget.isSelected ? 0.5 : 0.14),
                width: widget.isSelected ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: widget.isSelected ? 0.38 : (enableHoverScale ? 0.24 : 0.16)),
                  blurRadius: widget.isSelected ? 26 : (enableHoverScale ? 18 : 12),
                  offset: Offset(0, widget.isSelected ? 10 : 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Glossy sheen
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.10),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),
                  // Watermark icon
                  Positioned(
                    right: -18,
                    bottom: -18,
                    child: Opacity(
                      opacity: 0.10,
                      child: Icon(widget.icon, size: 100, color: Colors.white),
                    ),
                  ),

                  InkWell(
                    onTap: widget.hasSelection ? null : widget.onTap,
                    onHighlightChanged: (highlighted) {
                      if (!widget.hasSelection) {
                        setState(() => _isHovered = highlighted);
                      }
                    },
                    splashColor: Colors.white.withValues(alpha: 0.12),
                    highlightColor: Colors.white.withValues(alpha: 0.06),
                    child: Padding(
                      padding: const EdgeInsets.all(Sp.md),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.22),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
                            ),
                            child: Icon(widget.icon, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: Sp.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: AppTextStyles.h3().copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.subtitle,
                                  style: AppTextStyles.caption().copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: Sp.sm),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            child: const Icon(LucideIcons.arrowRight, color: Colors.white, size: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Selection badge
          if (widget.isSelected)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: accentColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 8),
                  ],
                ),
                child: Icon(LucideIcons.check, color: accentColor, size: 15),
              ).animate().scale(begin: const Offset(0.4, 0.4), curve: Curves.easeOutBack, duration: 250.ms),
            ),
        ],
      ),
    );
  }
}
