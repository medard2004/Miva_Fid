import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/client/core/router/app_route_observer.dart' as client_router;
import '../../features/client/core/router/tab_transition_direction.dart';
import '../../features/client/core/theme/app_motion.dart' as client_motion;
import '../../features/client/auth/auth_screen.dart';
import '../../features/client/auth/create_password_screen.dart';
import '../../features/client/auth/forgot_password_screen.dart' as client_forgot;
import '../../features/client/auth/reset_password_screen.dart';
import '../../features/client/splash/splash_screen.dart';
import '../../features/client/providers/app_providers.dart';
import '../../features/merchant/providers/merchant_auth_provider.dart';
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
import '../../features/client/profile/edit_profile_screen.dart';
import '../../features/client/profile/edit_field_screen.dart';
import '../../features/client/profile/edit_birthdate_screen.dart';
import '../../features/client/profile/verify_current_password_screen.dart';
import '../../features/client/profile/set_new_password_screen.dart';
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
import '../../features/onboarding/screens/forgot_password_screen.dart';
import '../../features/onboarding/screens/merchant_auth_screen.dart';
import '../../features/onboarding/screens/merchant_step1_screen.dart';
import '../../features/onboarding/screens/merchant_step2_screen.dart';
import '../../features/onboarding/screens/merchant_step3_screen.dart';
import '../../features/onboarding/screens/merchant_review_screen.dart';
import '../../features/onboarding/screens/merchant_verify_otp_screen.dart';
import '../../features/onboarding/screens/merchant_reset_password_screen.dart';
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

/// Construit l'écran OTP depuis les données `extra` du router.
///
/// L'OTP ne sert plus qu'à la réinitialisation du mot de passe : le seul
/// paramètre attendu est le numéro auquel le code a été envoyé.
OtpScreen _buildClientOtpScreen(GoRouterState state) {
  final extra = state.extra;
  final phone = switch (extra) {
    {'phone': final String p} => p,
    final String p => p,
    _ => '',
  };
  return OtpScreen(phoneNumber: phone);
}

/// Construit l'écran de nouveau mot de passe depuis les données `extra`.
///
/// `identifier` et `reset_token` viennent de l'écran OTP. Sans eux l'appel
/// serait refusé par le serveur : on renvoie alors vers le début du parcours.
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

/// Clé du navigateur racine.
///
/// Nécessaire à [ToastService] et [LoadingOverlayService], qui doivent insérer
/// une entrée d'overlay depuis en dehors de l'arbre de widgets (typiquement
/// depuis un provider, en réponse à une erreur réseau).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Passerelle entre Riverpod et `go_router` : traduit un changement de session
/// en notification que le routeur sait écouter.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(AppRouterRef ref) {
    ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        if (previous?.isAuthenticated != next.isAuthenticated) {
          notifyListeners();
        }
      },
    );
    ref.listen<MerchantAuthState>(
      merchantAuthProvider,
      (previous, next) {
        if (previous?.isAuthenticated != next.isAuthenticated) {
          notifyListeners();
        }
      },
    );
  }
}

/// Routes du module client accessibles sans session.
const _clientPublicRoutes = {
  '/client/auth',
  '/client/login',
  '/client/signup',
  '/client/create-password',
  '/client/otp',
  '/client/forgot-password',
  '/client/reset-password',
  '/client/onboarding',
};

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    observers: [client_router.routeObserver],
    // Réévalue les redirections dès que la session change : c'est ce qui fait
    // sortir l'utilisateur du wallet quand un 401 vide l'état.
    refreshListenable: _AuthRefreshNotifier(ref),
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Dashboard marchand : accès protégé par le token Sanctum obtenu à
      // l'inscription/connexion (voir `/auth/merchant/*`).
      if (location.startsWith('/merchant/') || location == '/merchant') {
        final isMerchantAuthenticated =
            ref.read(merchantAuthProvider).isAuthenticated;
        return isMerchantAuthenticated ? null : '/auth/merchant/auth';
      }

      if (!location.startsWith('/client/')) return null;

      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final isPublicRoute = _clientPublicRoutes.contains(location) ||
          location.startsWith('/client/onboarding');

      if (!isAuthenticated) {
        return isPublicRoute ? null : '/client/auth';
      }

      // Déjà connecté : les écrans d'entrée n'ont plus lieu d'être. On laisse
      // passer la réinitialisation de mot de passe, légitime en session.
      if (isPublicRoute &&
          location != '/client/reset-password' &&
          location != '/client/otp') {
        return '/client/wallet';
      }

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
        path: '/auth/merchant/verify-otp',
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _slide(MerchantVerifyOtpScreen(email: extra?['email'] as String? ?? ''));
        },
      ),
      GoRoute(
        path: '/auth/merchant/reset-password',
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _slide(MerchantResetPasswordScreen(
            email: extra?['email'] as String? ?? '',
            resetToken: extra?['reset_token'] as String? ?? '',
          ));
        },
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
