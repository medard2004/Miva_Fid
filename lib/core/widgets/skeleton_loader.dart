import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    this.height = 48,
    this.width,
    this.borderRadius,
  });

  final double height;
  final double? width;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.sm),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: borderRadius ?? Rd.card,
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 1200.ms,
            color: Colors.white.withValues(alpha: 0.6),
          ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: Sp.sm),
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Rd.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader(height: 40, width: 40, borderRadius: BorderRadius.circular(999)),
              const SizedBox(width: Sp.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(height: 14, width: 120),
                    SizedBox(height: Sp.xs),
                    SkeletonLoader(height: 10, width: 80),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.sm),
          const SkeletonLoader(height: 10),
          const SkeletonLoader(height: 10),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: Colors.white.withValues(alpha: 0.5),
        );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.sm),
      child: Row(
        children: [
          SkeletonLoader(height: 44, width: 44, borderRadius: BorderRadius.circular(999)),
          const SizedBox(width: Sp.sm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(height: 14, width: 140),
                SizedBox(height: Sp.xs),
                SkeletonLoader(height: 10, width: 100),
              ],
            ),
          ),
          const SkeletonLoader(height: 24, width: 60, borderRadius: Rd.pill),
        ],
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 1200.ms,
            color: Colors.white.withValues(alpha: 0.6),
          ),
    );
  }
}

/// Écran de chargement complet en squelettes animés (style YouTube),
/// utilisé pendant l'hydratation initiale côté Client et Marchand.
class BootSkeletonScreen extends StatelessWidget {
  const BootSkeletonScreen({super.key, this.isMerchant = false});

  final bool isMerchant;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barre supérieure (avatar + titre + pilule action)
                  Row(
                    children: [
                      SkeletonLoader(
                        height: 42,
                        width: 42,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLoader(height: 15, width: 150),
                            SkeletonLoader(height: 10, width: 96),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SkeletonLoader(
                        height: 32,
                        width: 78,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Grande carte héroïque (carte fidélité ou bandeau KPI)
                  SkeletonLoader(
                    height: isMerchant ? 124 : 164,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  const SizedBox(height: 6),

                  // 3 tuiles KPI / raccourcis côte à côte
                  const Row(
                    children: [
                      Expanded(child: SkeletonLoader(height: 68)),
                      SizedBox(width: 10),
                      Expanded(child: SkeletonLoader(height: 68)),
                      SizedBox(width: 10),
                      Expanded(child: SkeletonLoader(height: 68)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Titre de section
                  const SkeletonLoader(height: 14, width: 130),
                  const SizedBox(height: 4),

                  // Cartes de contenu (vignette + texte)
                  const SkeletonCard(height: 130),
                  const SkeletonCard(height: 130),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
