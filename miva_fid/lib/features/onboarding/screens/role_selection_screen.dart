import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(child: _ClientPanel()),
              Container(
                width: 1,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.38),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              Expanded(child: _MerchantPanel()),
            ],
          )
              .animate()
              .slideY(
                begin: 0.3,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 400.ms),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton(
                onPressed: () => context.go('/auth/login'),
                child: Text(
                  'Déjà un compte ? Se connecter',
                  style: AppTextStyles.caption().copyWith(
                    color: Colors.white60,
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

class _ClientPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A4E), Color(0xFF2D2D7A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: Sp.md),
              Text(
                'Je suis\nClient',
                style: AppTextStyles.h1().copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Sp.sm),
              Text(
                'Cumulez des tampons et débloquez des récompenses',
                style: AppTextStyles.caption().copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Sp.xl),
              AppButton.primary(
                'Commencer',
                onPressed: () => context.go('/auth/client-signup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MerchantPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A1A6E), Color(0xFF7C3AED)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.store_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: Sp.md),
              Text(
                'Je suis\nCommerçant',
                style: AppTextStyles.h1().copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Sp.sm),
              Text(
                'Fidélisez vos clients avec un programme simple et efficace',
                style: AppTextStyles.caption().copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Sp.xl),
              AppButton.merchant(
                'Commencer',
                onPressed: () => context.go('/auth/merchant/step1'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
