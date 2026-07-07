import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/client/screens/card_detail_screen.dart';
import '../../features/client/screens/celebration_screen.dart';
import '../../features/client/screens/client_home_screen.dart';
import '../../features/client/screens/client_profile_screen.dart';
import '../../features/client/screens/client_shell.dart';
import '../../features/client/screens/my_cards_screen.dart';
import '../../features/client/screens/reward_qr_screen.dart';
import '../../features/client/screens/rewards_screen.dart';
import '../../features/client/screens/scanner_screen.dart';
import '../../features/merchant/screens/clients_screen.dart';
import '../../features/merchant/screens/client_detail_screen.dart';
import '../../features/merchant/screens/dashboard_screen.dart';
import '../../features/merchant/screens/merchant_shell.dart';
import '../../features/merchant/screens/more_screen.dart';
import '../../features/merchant/screens/programme_screen.dart';
import '../../features/merchant/screens/qr_code_screen.dart';
import '../../features/merchant/screens/settings_screen.dart';
import '../../features/merchant/screens/sms_campaign_screen.dart';
import '../../features/merchant/screens/validate_screen.dart';
import '../../features/merchant/screens/vitrine_screen.dart';
import '../../features/onboarding/screens/client_signup_screen.dart';
import '../../features/onboarding/screens/login_screen.dart';
import '../../features/onboarding/screens/merchant_step1_screen.dart';
import '../../features/onboarding/screens/merchant_step2_screen.dart';
import '../../features/onboarding/screens/merchant_step3_screen.dart';
import '../../features/onboarding/screens/merchant_step4_screen.dart';
import '../../features/onboarding/screens/qr_success_screen.dart';
import '../../features/onboarding/screens/profile_onboarding_screen.dart';
import '../../features/onboarding/screens/role_selection_screen.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/role-select',
    redirect: (context, state) {
      // Auth redirect logic — simplified for now
      return null;
    },
    routes: [
      GoRoute(
        path: '/role-select',
        pageBuilder: (_, __) => _slide(const RoleSelectionScreen()),
      ),
      GoRoute(
        path: '/auth/login',
        pageBuilder: (_, __) => _slide(const LoginScreen()),
      ),
      GoRoute(
        path: '/auth/client-signup',
        pageBuilder: (_, __) => _slide(const ClientSignupScreen()),
      ),
      GoRoute(
        path: '/auth/merchant/step1',
        pageBuilder: (_, __) => _slide(const MerchantStep1Screen()),
      ),
      GoRoute(
        path: '/auth/merchant/step2',
        pageBuilder: (_, __) => _slide(const MerchantStep2Screen()),
      ),
      GoRoute(
        path: '/auth/merchant/step3',
        pageBuilder: (_, __) => _slide(const MerchantStep3Screen()),
      ),
      GoRoute(
        path: '/auth/merchant/step4',
        pageBuilder: (_, __) => _slide(const MerchantStep4Screen()),
      ),
      GoRoute(
        path: '/auth/merchant/step5',
        redirect: (_, __) => '/auth/merchant/step4',
      ),
      GoRoute(
        path: '/auth/merchant/success',
        pageBuilder: (_, __) => _slide(const QrSuccessScreen()),
      ),
      GoRoute(
        path: '/onboarding/client',
        pageBuilder: (_, __) => _slide(const ProfileOnboardingScreen(role: 'client')),
      ),
      GoRoute(
        path: '/onboarding/merchant',
        pageBuilder: (_, __) => _slide(const ProfileOnboardingScreen(role: 'merchant')),
      ),

      // Merchant shell
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MerchantShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/merchant',
              pageBuilder: (_, __) => _fade(const DashboardScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/merchant/clients',
              pageBuilder: (_, __) => _fade(const ClientsScreen()),
            ),
            GoRoute(
              path: '/merchant/clients/:id',
              pageBuilder: (_, s) => _slide(
                ClientDetailScreen(clientId: s.pathParameters['id']!),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/merchant/validate',
              pageBuilder: (_, __) => _fade(const ValidateScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/merchant/sms',
              pageBuilder: (_, __) => _fade(const SmsCampaignScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/merchant/more',
              pageBuilder: (_, __) => _fade(const MoreScreen()),
              routes: [
                GoRoute(
                  path: 'programme',
                  pageBuilder: (_, __) => _slide(const ProgrammeScreen()),
                ),
                GoRoute(
                  path: 'qrcode',
                  pageBuilder: (_, __) => _slide(const QrCodeScreen()),
                ),
                GoRoute(
                  path: 'vitrine',
                  pageBuilder: (_, __) => _slide(const VitrineScreen()),
                ),
                GoRoute(
                  path: 'settings',
                  pageBuilder: (_, __) => _slide(const SettingsScreen()),
                ),
              ],
            ),
          ]),
        ],
      ),

      // Client shell
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ClientShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/client',
              pageBuilder: (_, __) => _fade(const ClientHomeScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/client/cards',
              pageBuilder: (_, __) => _fade(const MyCardsScreen()),
            ),
            GoRoute(
              path: '/client/cards/:id',
              pageBuilder: (_, s) => _slide(
                CardDetailScreen(cardId: s.pathParameters['id']!),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/client/scanner',
              pageBuilder: (_, __) => _fade(const ScannerScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/client/rewards',
              pageBuilder: (_, __) => _fade(const RewardsScreen()),
            ),
            GoRoute(
              path: '/client/rewards/:id/redeem',
              pageBuilder: (_, s) => _slide(
                RewardQrScreen(rewardId: s.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: '/client/celebration',
              pageBuilder: (_, __) => _slide(const CelebrationScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/client/profile',
              pageBuilder: (_, __) => _fade(const ClientProfileScreen()),
            ),
          ]),
        ],
      ),

    ],
  );
}

CustomTransitionPage<void> _slide(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.08), // Small bottom-to-top slide
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );
      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );
      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

CustomTransitionPage<void> _fade(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      );
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.03), // Subtle upward slide for tab screens
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      );
      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}
