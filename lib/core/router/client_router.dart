import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/client/core/router/app_route_observer.dart' as client_router_observer;
import '../../features/client/core/router/tab_transition_direction.dart';
import '../../features/client/core/theme/app_motion.dart' as client_motion;
import '../../features/client/auth/auth_screen.dart';
import '../../features/client/auth/create_password_screen.dart';
import '../../features/client/auth/forgot_password_screen.dart' as client_forgot;
import '../../features/client/auth/reset_password_screen.dart';
import '../../features/client/providers/app_providers.dart';
import '../../features/client/auth/otp_screen.dart';
import '../../features/client/auth/signup_screen.dart';
import '../../features/client/auth/complete_social_profile_screen.dart';
import '../../features/client/onboarding/onboarding_screen.dart';
import '../../features/client/onboarding/qr_scan_screen.dart';
import '../../features/client/onboarding/join_restaurant_screen.dart';
import '../../features/client/wallet/wallet_dashboard_screen.dart';
import '../../features/client/wallet/wallet_search_screen.dart';
import '../../features/client/card_detail/card_detail_screen.dart';
import '../../features/client/card_detail/card_unlocked_rewards_screen.dart';
import '../../features/client/card_detail/merchant_map_screen.dart';
import '../../features/client/rewards/rewards_screen.dart';
import '../../features/client/campaign/campaign_detail_screen.dart';
import '../../features/client/campaign/review_screen.dart';
import '../../features/client/referral/referral_screen.dart';
import '../../features/client/rewards/welcome_reward_surprise_screen.dart';
import '../../features/client/profile/profile_screen.dart';
import '../../features/client/profile/edit_profile_screen.dart';
import '../../features/client/profile/edit_field_screen.dart';
import '../../features/client/profile/edit_birthdate_screen.dart';
import '../../features/client/profile/verify_current_password_screen.dart';
import '../../features/client/profile/set_new_password_screen.dart';
import '../../features/client/settings/settings_screen.dart' as client_settings;
import '../../features/client/settings/notifications_settings_screen.dart';
import '../../features/client/settings/language_settings_screen.dart';
import '../../features/client/settings/appearance_settings_screen.dart';
import '../../features/client/settings/help_center_screen.dart';
import '../../features/client/settings/about_screen.dart';
import '../../features/client/support/contact_screen.dart';
import '../../features/client/support/report_bug_screen.dart';
import '../../features/client/legal/legal_screen.dart';
import '../../features/client/notifications/notifications_screen.dart';
import '../../features/client/widgets/shared/app_shell.dart';

final GlobalKey<NavigatorState> clientNavigatorKey = GlobalKey<NavigatorState>();

class _ClientAuthRefreshNotifier extends ChangeNotifier {
  _ClientAuthRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        if (previous?.isAuthenticated != next.isAuthenticated) {
          notifyListeners();
        }
      },
    );
  }
}

/// Transition fluide entre onglets client
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

OtpScreen _buildClientOtpScreen(GoRouterState state) {
  final extra = state.extra;
  final phone = switch (extra) {
    {'phone': final String p} => p,
    final String p => p,
    _ => '',
  };
  return OtpScreen(phoneNumber: phone);
}

Widget _buildClientResetPasswordScreen(GoRouterState state) {
  final extra = state.extra;
  if (extra is Map &&
      extra['identifier'] is String &&
      extra['reset_token'] is String) {
    return ResetPasswordScreen(
      identifier: extra['identifier'] as String,
      resetToken: extra['reset_token'] as String,
    );
  }
  return const client_forgot.ForgotPasswordScreen();
}

const _clientPublicRoutes = {
  '/join',
  '/client/auth',
  '/client/login',
  '/client/signup',
  '/client/create-password',
  '/client/otp',
  '/client/forgot-password',
  '/client/reset-password',
  '/client/onboarding',
  '/client/onboarding/scan',
  '/client/onboarding/join',
  '/client/complete-social-profile',
  '/client/legal/terms',
  '/client/legal/privacy',
};

final clientRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: clientNavigatorKey,
    initialLocation: '/client/wallet',
    observers: [client_router_observer.routeObserver],
    refreshListenable: _ClientAuthRefreshNotifier(ref),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthenticated = ref.read(authProvider).isAuthenticated;

      // 1. Accès racine web
      if (location == '/') {
        return isAuthenticated ? '/client/wallet' : '/client/onboarding';
      }

      // 2. Gestion de l'accès public
      final isPublicRoute = _clientPublicRoutes.contains(location) ||
          location.startsWith('/client/onboarding') ||
          location.startsWith('/client/legal') ||
          location == '/join';

      if (!isAuthenticated) {
        return isPublicRoute ? null : '/client/auth';
      }

      // 3. Client déjà connecté accédant aux écrans de connexion
      final isAuthOnlyScreen = (location == '/client/auth' ||
              location == '/client/login' ||
              location == '/client/signup' ||
              location == '/client/create-password') &&
          location != '/client/reset-password' &&
          location != '/client/otp' &&
          location != '/client/forgot-password';

      if (isAuthOnlyScreen) {
        return '/client/wallet';
      }

      return null;
    },
    routes: [
      // ── Point d'entrée direct par QR code / Lien Web (ex: /join?code=RESTO123) ──
      GoRoute(
        path: '/join',
        redirect: (context, state) {
          final code = state.uri.queryParameters['code'] ?? '';
          if (code.isNotEmpty) {
            return '/client/onboarding/join?code=$code';
          }
          return '/client/onboarding';
        },
      ),

      // ── Client: Onboarding (Scan ou saisie de code) ─────────────────────────
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
          // Support direct des paramètres d'URL (Web & deep linking)
          code ??= state.uri.queryParameters['code'];
          return JoinRestaurantScreen(scannedCode: code);
        },
      ),

      // ── Client: Authentification ──────────────────────────────────────────
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
        path: '/client/create-password',
        builder: (_, __) => const CreatePasswordScreen(),
      ),
      GoRoute(
        path: '/client/forgot-password',
        builder: (_, __) => const client_forgot.ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/client/reset-password',
        builder: (_, state) => _buildClientResetPasswordScreen(state),
      ),
      GoRoute(
        path: '/client/complete-social-profile',
        builder: (_, __) => const CompleteSocialProfileScreen(),
      ),
      GoRoute(
        path: '/client/legal/terms',
        builder: (_, __) => const LegalScreen(document: LegalDocument.terms),
      ),
      GoRoute(
        path: '/client/legal/privacy',
        builder: (_, __) => const LegalScreen(document: LegalDocument.privacy),
      ),

      // ── Client: Coquille principale (Bottom tab bar) ──────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/client/wallet',
            pageBuilder: (_, state) => _clientTabFadePage(state, const WalletDashboardScreen()),
          ),
          GoRoute(
            path: '/client/rewards',
            pageBuilder: (_, state) => _clientTabFadePage(
              state,
              RewardsScreen(openRewardId: state.uri.queryParameters['openReward']),
            ),
          ),
          GoRoute(
            path: '/client/referral',
            pageBuilder: (_, state) => _clientTabFadePage(
              state,
              ReferralScreen(initialCardId: state.uri.queryParameters['cardId']),
            ),
          ),
          GoRoute(
            path: '/client/profile',
            pageBuilder: (_, state) => _clientTabFadePage(state, const ProfileScreen()),
          ),
          GoRoute(
            path: '/client/settings',
            pageBuilder: (_, state) =>
                _clientTabFadePage(state, const client_settings.SettingsScreen()),
          ),
        ],
      ),

      // ── Détail de carte & sous-écrans ──────────────────────────────────────
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
        path: '/client/card/:id/rewards',
        pageBuilder: (_, state) {
          final id = state.pathParameters['id']!;
          return _slide(CardUnlockedRewardsScreen(cardId: id));
        },
      ),
      GoRoute(
        path: '/client/card/:id/map',
        builder: (_, state) {
          final extra = state.extra;
          final args = extra is MerchantMapArguments ? extra : null;
          return MerchantMapScreen(
            merchantName: args?.merchantName ?? 'Établissement',
            address: args?.address ?? '',
            latitude: args?.latitude,
            longitude: args?.longitude,
          );
        },
      ),
      GoRoute(
        path: '/client/campaign/:id',
        pageBuilder: (_, state) {
          final extra = state.extra as Map?;
          return _slide(CampaignDetailScreen(
            campaignId: state.pathParameters['id'] ?? '',
            title: extra?['title'] as String? ?? 'Offre',
            body: extra?['body'] as String? ?? '',
            imageUrl: extra?['image_url'] as String?,
            rewardId: extra?['reward_id'] as String?,
            campaignType: extra?['campaign_type'] as String?,
            cardId: extra?['card_id'] as String?,
          ));
        },
      ),
      GoRoute(
        path: '/client/welcome-reward/:cardId',
        pageBuilder: (_, state) {
          final extra = state.extra as Map?;
          return _slide(WelcomeRewardSurpriseScreen(
            cardId: state.pathParameters['cardId'] ?? '',
            referredBy: extra?['referred_by'] as String?,
          ));
        },
      ),
      GoRoute(
        path: '/client/review/:cardId',
        pageBuilder: (_, state) {
          return _slide(ReviewScreen(
            cardId: state.pathParameters['cardId'] ?? '',
          ));
        },
      ),
      GoRoute(
        path: '/client/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/client/profile/edit/name',
        builder: (_, __) =>
            const EditFieldScreen(field: ProfileEditableField.fullName),
      ),
      GoRoute(
        path: '/client/profile/edit/email',
        builder: (_, __) =>
            const EditFieldScreen(field: ProfileEditableField.email),
      ),
      GoRoute(
        path: '/client/profile/edit/city',
        builder: (_, __) =>
            const EditFieldScreen(field: ProfileEditableField.city),
      ),
      GoRoute(
        path: '/client/profile/edit/country',
        builder: (_, __) =>
            const EditFieldScreen(field: ProfileEditableField.country),
      ),
      GoRoute(
        path: '/client/profile/edit/birthdate',
        builder: (_, __) => const EditBirthDateScreen(),
      ),
      GoRoute(
        path: '/client/profile/verify-password',
        builder: (_, __) => const VerifyCurrentPasswordScreen(),
      ),
      GoRoute(
        path: '/client/profile/set-new-password',
        builder: (_, state) => SetNewPasswordScreen(
          currentPassword: state.extra is String ? state.extra as String : '',
        ),
      ),
      GoRoute(
        path: '/client/settings/notifications',
        builder: (_, __) => const NotificationsSettingsScreen(),
      ),
      GoRoute(
        path: '/client/settings/language',
        builder: (_, __) => const LanguageSettingsScreen(),
      ),
      GoRoute(
        path: '/client/settings/appearance',
        builder: (_, __) => const AppearanceSettingsScreen(),
      ),
      GoRoute(
        path: '/client/settings/help',
        builder: (_, __) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/client/settings/about',
        builder: (_, __) => const AboutScreen(),
      ),
      GoRoute(
        path: '/client/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/client/support/contact',
        builder: (_, __) => const ContactScreen(),
      ),
      GoRoute(
        path: '/client/support/report-bug',
        builder: (_, __) => const ReportBugScreen(),
      ),
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
    ],
  );
});

CustomTransitionPage<void> _slide(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.08),
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

