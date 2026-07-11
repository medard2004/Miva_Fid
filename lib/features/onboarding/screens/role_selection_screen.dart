import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _navigating = false;

  void _handleRoleSelection(String role, String route) {
    if (_navigating) return;
    setState(() {
      _selectedRole = role;
      _navigating = true;
    });
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) {
        context.go(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 860;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final bool isClientSelected = _selectedRole == 'client';
    final bool isMerchantSelected = _selectedRole == 'merchant';
    final bool hasSelection = _selectedRole != null;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Stack(
        children: [
          // Background mesh glows (fade out on selection)
          Positioned(
            top: -100,
            left: -100,
            child: AnimatedOpacity(
              opacity: hasSelection ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 180,
                      spreadRadius: 80,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: AnimatedOpacity(
              opacity: hasSelection ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.merchant.withValues(alpha: 0.08),
                      blurRadius: 200,
                      spreadRadius: 90,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(Sp.md, Sp.md, Sp.md, bottomInset + Sp.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header Section (fade out on selection)
                  AnimatedOpacity(
                    opacity: hasSelection ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      children: [
                        const SizedBox(height: Sp.xs),
                        // Premium Glass Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.12), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Miva Fid',
                                style: AppTextStyles.caption().copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                        const SizedBox(height: Sp.sm),
                        Text(
                          'Quel est votre profil ?',
                          style: AppTextStyles.h2().copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            fontSize: 22,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate(delay: 100.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
                        const SizedBox(height: 6),
                        Text(
                          'Choisissez l’option qui vous correspond pour continuer.',
                          style: AppTextStyles.bodyMd().copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate(delay: 150.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
                      ],
                    ),
                  ),

                  const SizedBox(height: Sp.sm),

                  // Cards Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final clientCard = AnimatedOpacity(
                        opacity: hasSelection && !isClientSelected ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: AnimatedScale(
                          scale: isClientSelected ? 1.03 : (hasSelection ? 0.96 : 1.0),
                          duration: const Duration(milliseconds: 250),
                          child: _SelectionCard(
                            title: 'Je suis Client',
                            subtitle: 'Cumulez des points et débloquez des récompenses exclusives chez vos commerçants.',
                            accent: const LinearGradient(
                              colors: [Color(0xFF2E2BF7), Color(0xFF4F46E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            icon: Icons.card_giftcard_rounded,
                            buttonText: 'Commencer mon parcours',
                            isSelected: isClientSelected,
                            hasSelection: hasSelection,
                            onTap: () => _handleRoleSelection('client', '/onboarding/client'),
                          ),
                        ),
                      );

                      final merchantCard = AnimatedOpacity(
                        opacity: hasSelection && !isMerchantSelected ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: AnimatedScale(
                          scale: isMerchantSelected ? 1.03 : (hasSelection ? 0.96 : 1.0),
                          duration: const Duration(milliseconds: 250),
                          child: _SelectionCard(
                            title: 'Je suis Commerçant',
                            subtitle: 'Fidélisez votre clientèle locale et gérez vos campagnes de tampons digitalisés.',
                            accent: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            icon: Icons.storefront_rounded,
                            buttonText: 'Créer mon espace marchand',
                            isSelected: isMerchantSelected,
                            hasSelection: hasSelection,
                            onTap: () => _handleRoleSelection('merchant', '/onboarding/merchant'),
                          ),
                        ),
                      );

                      if (isWide || constraints.maxWidth >= 800) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: clientCard),
                            const SizedBox(width: Sp.md),
                            Expanded(child: merchantCard),
                          ],
                        );
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          clientCard,
                          const SizedBox(height: Sp.sm),
                          merchantCard,
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: Sp.sm),

                  // Footer (fade out on selection)
                  AnimatedOpacity(
                    opacity: hasSelection ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: TextButton(
                      onPressed: hasSelection ? null : () => context.go('/auth/login'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary, fontSize: 13),
                          children: const [
                            TextSpan(text: 'Déjà un compte ? '),
                            TextSpan(
                              text: 'Se connecter',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
    required this.buttonText,
    required this.onTap,
    this.isSelected = false,
    this.hasSelection = false,
  });

  final String title;
  final String subtitle;
  final LinearGradient accent;
  final IconData icon;
  final String buttonText;
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

    return AnimatedScale(
      scale: widget.isSelected ? 1.0 : (enableHoverScale ? 1.015 : 1.0),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: widget.accent,
          boxShadow: [
            BoxShadow(
              color: widget.accent.colors.last.withValues(alpha: widget.isSelected ? 0.40 : (enableHoverScale ? 0.25 : 0.15)),
              blurRadius: widget.isSelected ? 20 : (enableHoverScale ? 14 : 8),
              offset: Offset(0, widget.isSelected ? 6 : (enableHoverScale ? 4 : 3)),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Watermark Icon Background
              Positioned(
                right: -16,
                bottom: -16,
                child: Opacity(
                  opacity: 0.08,
                  child: Icon(
                    widget.icon,
                    size: 110,
                    color: Colors.white,
                  ),
                ),
              ),

              // Card Content
              InkWell(
                onTap: widget.hasSelection ? null : widget.onTap,
                onHighlightChanged: (highlighted) {
                  if (!widget.hasSelection) {
                    setState(() {
                      _isHovered = highlighted;
                    });
                  }
                },
                splashColor: Colors.white.withValues(alpha: 0.12),
                highlightColor: Colors.white.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row: Icon and Title inline
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: Sp.sm),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: AppTextStyles.h3().copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Sp.sm),

                      // Card Subtitle
                      Text(
                        widget.subtitle,
                        style: AppTextStyles.caption().copyWith(
                          color: Colors.white.withValues(alpha: 0.90),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: Sp.md),

                      // Button CTA
                      Container(
                        width: double.infinity,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.buttonText,
                                style: AppTextStyles.labelBold().copyWith(
                                  color: widget.accent.colors.last,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: Sp.xs),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: widget.accent.colors.last,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
