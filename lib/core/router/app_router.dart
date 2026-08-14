import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/client/core/router/app_route_observer.dart' as client_router;
import '../../features/client/core/router/tab_transition_direction.dart';
import '../../features/client/core/theme/app_motion.dart' as client_motion;
import '../../features/client/auth/auth_screen.dart';
import '../../features/client/auth/otp_screen.dart';
import '../../features/client/auth/signup_screen.dart';
import '../../features/client/auth/complete_profile_screen.dart';
import '../../features/client/auth/complete_social_profile_screen.dart';
import '../../features/client/onboarding/onboarding_screen.dart';
import '../../features/client/onboarding/qr_scan_screen.dart';
import '../../features/client/onboarding/join_restaurant_screen.dart';
import '../../features/client/wallet/wallet_dashboard_screen.dart';
import '../../features/client/wallet/wallet_search_screen.dart';
import '../../features/client/card_detail/card_detail_screen.dart';
import '../../features/client/rewards/rewards_screen.dart';
import '../../features/client/referral/referral_screen.dart';
import '../../features/client/profile/profile_screen.dart';
import '../../features/client/settings/settings_screen.dart' as client_settings;
import '../../features/client/notifications/notifications_screen.dart';
import '../../features/client/widgets/shared/app_shell.dart';

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
import '../../features/onboarding/screens/login_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/forgot_password_screen.dart';
import '../../features/onboarding/screens/merchant_auth_screen.dart';
import '../../features/onboarding/screens/merchant_step1_screen.dart';
import '../../features/onboarding/screens/merchant_step2_screen.dart';
import '../../features/onboarding/screens/merchant_step3_screen.dart';
import '../../features/onboarding/screens/merchant_review_screen.dart';
import '../../features/onboarding/screens/qr_success_screen.dart';
import '../../features/onboarding/screens/profile_onboarding_screen.dart';
import '../../features/onboarding/screens/role_selection_screen.dart';

part 'app_router.g.dart';

/// Transition des onglets de la coquille client — léger slide horizontal
/// orienté selon le sens du changement d'onglet, combiné à un fondu et un
/// scale discret.
CustomTransitionPage<void> _clientTabFadePage(GoRouterState state, Widget child) {
  final direction = tabSlideDirection;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: client_motion.AppMotion.pageDuration,
    reverseTransitionDuration: client_motion.AppMotion.pageReverseDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: client_motion.AppMotion.pageCurve);
      final slide = Tween<Offset>(
        begin: Offset(0.035 * direction, 0),
        end: Offset.zero,
      ).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: slide,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Construit un [OtpScreen] depuis les données `extra` du router.
OtpScreen _buildClientOtpScreen(GoRouterState state) {
  final extra = state.extra;
  String phone = '';
  OtpContext otpContext = OtpContext.login;

  if (extra is Map<String, dynamic>) {
    phone = extra['phone'] as String? ?? '';
    final ctx = extra['context'] as String? ?? 'login';
    otpContext = switch (ctx) {
      'signup' => OtpContext.signup,
      'social' => OtpContext.social,
      _ => OtpContext.login,
    };
  } else if (extra is String) {
    phone = extra;
  }

  return OtpScreen(phoneNumber: phone, otpContext: otpContext);
}

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/splash',
    observers: [client_router.routeObserver],
    redirect: (context, state) {
      // Auth redirect logic — simplified for now
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (_, __) => _fade(const SplashScreen()),
      ),
      GoRoute(
        path: '/role-select',
        pageBuilder: (_, __) => _slide(const RoleSelectionScreen()),
      ),
      GoRoute(
        path: '/auth/login',
        pageBuilder: (_, __) => _slide(const LoginScreen()),
      ),
      GoRoute(
        path: '/auth/merchant/auth',
        pageBuilder: (_, __) => _slide(const MerchantAuthScreen()),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        pageBuilder: (_, __) => _slide(const ForgotPasswordScreen()),
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
        path: '/auth/merchant/review',
        pageBuilder: (_, __) => _slide(const MerchantReviewScreen()),
      ),
      GoRoute(
        path: '/auth/merchant/success',
        pageBuilder: (_, __) => _slide(const QrSuccessScreen()),
      ),
      GoRoute(
        path: '/onboarding/merchant',
        pageBuilder: (_, __) => _slide(const ProfileOnboardingScreen()),
      ),

      // ── Client: onboarding (scan QR pour rejoindre un commerce) ─────────
      GoRoute(
        path: '/client/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/client/onboarding/scan',
        builder: (_, __) => const QrScanScreen(),
      ),
      GoRoute(
        path: '/client/onboarding/join',
        builder: (_, state) {
          final extra = state.extra;
          String? code;
          if (extra is Map<String, dynamic>) {
            code = extra['code'] as String?;
          } else if (extra is String) {
            code = extra;
          }
          return JoinRestaurantScreen(scannedCode: code);
        },
      ),

      // ── Client: auth ──────────────────────────────────────────────────
      GoRoute(
        path: '/client/auth',
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: '/client/login',
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: '/client/signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/client/otp',
        builder: (_, state) => _buildClientOtpScreen(state),
      ),
      GoRoute(
        path: '/client/complete-profile',
        builder: (_, __) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/client/complete-social-profile',
        builder: (_, __) => const CompleteSocialProfileScreen(),
      ),

      // ── Client: coquille principale (bottom tab bar) ─────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/client/wallet',
            pageBuilder: (_, state) => _clientTabFadePage(state, const WalletDashboardScreen()),
          ),
          GoRoute(
            path: '/client/rewards',
            pageBuilder: (_, state) => _clientTabFadePage(state, const RewardsScreen()),
          ),
          GoRoute(
            path: '/client/referral',
            pageBuilder: (_, state) => _clientTabFadePage(state, const ReferralScreen()),
          ),
          GoRoute(
            path: '/client/profile',
            pageBuilder: (_, state) => _clientTabFadePage(state, const ProfileScreen()),
          ),
        ],
      ),

      // Détail de carte — fondu + agrandissement depuis son point d'ancrage.
      GoRoute(
        path: '/client/card/:id',
        pageBuilder: (_, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: CardDetailScreen(cardId: id),
            transitionDuration: client_motion.AppMotion.pageDuration,
            reverseTransitionDuration: client_motion.AppMotion.pageReverseDuration,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: client_motion.AppMotion.pageCurve,
                reverseCurve: client_motion.AppMotion.pageReverseCurve,
              );
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.90, end: 1.0).animate(curved),
                  alignment: Alignment.center,
                  child: child,
                ),
              );
            },
          );
        },
      ),

      GoRoute(
        path: '/client/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/client/settings',
        builder: (_, __) => const client_settings.SettingsScreen(),
      ),

      // Recherche du Wallet — glisse depuis le bas.
      GoRoute(
        path: '/client/wallet/search',
        pageBuilder: (_, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const WalletSearchScreen(),
            transitionDuration: client_motion.AppMotion.pageDuration,
            reverseTransitionDuration: client_motion.AppMotion.pageReverseDuration,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final curved = CurvedAnimation(parent: animation, curve: client_motion.AppMotion.pageCurve);
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
          );
        },
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
