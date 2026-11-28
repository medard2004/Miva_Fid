import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/client/providers/app_startup_provider.dart';
import '../../features/merchant/providers/merchant_auth_provider.dart';
import '../../features/merchant/widgets/validation_success_overlay.dart';
import '../../features/merchant/screens/clients_screen.dart';
import '../../features/merchant/screens/client_detail_screen.dart';
import '../../features/merchant/screens/dashboard_screen.dart';
import '../../features/merchant/screens/merchant_shell.dart';
import '../../features/merchant/screens/more_screen.dart';
import '../../features/merchant/screens/programme_screen.dart';
import '../../features/merchant/screens/programme_tiers_screen.dart';
import '../../features/merchant/screens/programme_rules_screen.dart';
import '../../features/merchant/screens/programme_design_screen.dart';
import '../../features/merchant/screens/qr_code_screen.dart';
import '../../features/merchant/screens/account_category_screen.dart';
import '../../features/merchant/screens/profile_screen.dart' as merchant_profile;
import '../../features/merchant/screens/subscription_screen.dart';
import '../../features/merchant/screens/team_screen.dart';
import '../../features/merchant/screens/notifications_screen.dart' as merchant_notifs;
import '../../features/merchant/screens/preferences_screen.dart';
import '../../features/merchant/screens/language_theme_screen.dart';
import '../../features/merchant/screens/sms_campaign_screen.dart';
import '../../features/merchant/screens/merchant_offline_screen.dart';
import '../../features/merchant/screens/sms_conversation_screen.dart';
import '../../features/merchant/screens/sms_campaign_detail_screen.dart';
import '../../features/merchant/screens/sms_campaign_compose_screen.dart';
import '../../features/merchant/screens/campaign_type_screen.dart';
import '../../features/merchant/screens/campaign_content_screen.dart';
import '../../features/merchant/screens/campaign_recipients_screen.dart';
import '../../features/merchant/screens/campaign_summary_screen.dart';
import '../../features/merchant/screens/validate_screen.dart';
import '../../features/merchant/screens/vitrine_screen.dart';
import '../../features/merchant/screens/opening_hours_screen.dart';
import '../../features/merchant/screens/socials_screen.dart';
import '../../features/merchant/screens/birthday_reward_screen.dart';
import '../../features/merchant/screens/referral_reward_screen.dart';
import '../../features/merchant/screens/referrals_screen.dart';
import '../../features/merchant/screens/welcome_reward_screen.dart';
import '../../features/merchant/screens/cashback_settings_screen.dart';
import '../../features/merchant/screens/change_password_screen.dart';
import '../../features/merchant/screens/merchant_legal_screen.dart';
import '../../features/merchant/screens/reviews_screen.dart';
import '../../features/merchant/screens/proximity_notification_screen.dart';
import '../../features/onboarding/screens/forgot_password_screen.dart';
import '../../features/onboarding/screens/merchant_auth_screen.dart';
import '../../features/onboarding/screens/merchant_location_map_screen.dart';
import '../../features/onboarding/screens/merchant_location_screen.dart';
import '../../features/onboarding/screens/merchant_step1_screen.dart';
import '../../features/onboarding/screens/merchant_step2_screen.dart';
import '../../features/onboarding/screens/merchant_step3_screen.dart';
import '../../features/onboarding/screens/merchant_review_screen.dart';
import '../../features/onboarding/screens/merchant_verify_otp_screen.dart';
import '../../features/onboarding/screens/merchant_reset_password_screen.dart';
import '../../features/onboarding/screens/qr_success_screen.dart';
import '../../features/onboarding/screens/profile_onboarding_screen.dart';
import '../../models/campaign_model.dart';

final GlobalKey<NavigatorState> merchantNavigatorKey = GlobalKey<NavigatorState>();

class _MerchantAuthRefreshNotifier extends ChangeNotifier {
  _MerchantAuthRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<AppStartupState>>(
      appStartupProvider,
      (_, __) => notifyListeners(),
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

const _merchantPublicRoutes = {
  '/auth/merchant/auth',
  '/auth/forgot-password',
  '/auth/merchant/verify-otp',
  '/auth/merchant/reset-password',
  '/onboarding/merchant',
  '/merchant/legal/terms',
  '/merchant/legal/privacy',
};

const _merchantOnboardingRoutes = {
  '/auth/merchant/step1',
  '/auth/merchant/location',
  '/auth/merchant/location/map',
  '/auth/merchant/step2',
  '/auth/merchant/step3',
  '/auth/merchant/review',
  '/auth/merchant/success',
};

final merchantRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: merchantNavigatorKey,
    initialLocation: '/merchant',
    refreshListenable: _MerchantAuthRefreshNotifier(ref),
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Attendre la fin de l'hydratation au démarrage (F5 / Reload) pour
      // préserver l'URL exacte sans renvoyer vers /auth/merchant/auth par erreur.
      if (ref.read(appStartupProvider).isLoading) {
        return null;
      }

      final merchantAuth = ref.read(merchantAuthProvider);
      final isAuthenticated = merchantAuth.isAuthenticated;

      // 1. Accès racine
      if (location == '/') {
        if (!isAuthenticated) return '/auth/merchant/auth';
        final restaurant = merchantAuth.restaurant;
        if (!(restaurant?.hasBusinessInfo ?? false)) return '/auth/merchant/step1';
        if (!(restaurant?.hasLocation ?? false)) return '/auth/merchant/location';
        if (!(restaurant?.hasLoyaltyProgram ?? false)) return '/auth/merchant/step2';
        return '/merchant';
      }

      // 2. Gestion des non-authentifiés
      if (!isAuthenticated) {
        if (_merchantPublicRoutes.contains(location)) return null;
        return '/auth/merchant/auth';
      }

      // 3. Marchand connecté accédant aux routes d'authentification publique
      if (_merchantPublicRoutes.contains(location)) {
        final restaurant = merchantAuth.restaurant;
        if (restaurant?.hasLoyaltyProgram ?? false) {
          return '/merchant';
        }
        return '/auth/merchant/step1';
      }

      // 4. Protection des étapes d'onboarding pour marchand déjà configuré
      if (_merchantOnboardingRoutes.contains(location)) {
        if ((merchantAuth.restaurant?.hasLoyaltyProgram ?? false) &&
            location != '/auth/merchant/success') {
          return '/merchant';
        }
        return null;
      }

      // 5. Dashboard marchand et sous-routes
      if (location.startsWith('/merchant')) {
        final restaurant = merchantAuth.restaurant;
        if (!(restaurant?.hasBusinessInfo ?? false)) return '/auth/merchant/step1';
        if (!(restaurant?.hasLocation ?? false)) return '/auth/merchant/location';
        if (!(restaurant?.hasLoyaltyProgram ?? false)) return '/auth/merchant/step2';

        // Filtrage rôle opérateur (non-admin)
        final isAdmin = ref.read(isAdminProvider);
        final isOperatorReachable = location == '/merchant' ||
            location == '/merchant/validate' ||
            location.startsWith('/merchant/validate') ||
            location == '/merchant/more/change-password' ||
            location == '/merchant/more/profile';

        if (!isAdmin && !isOperatorReachable) {
          return '/merchant';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/merchant/auth',
        pageBuilder: (_, __) => _slide(const MerchantAuthScreen()),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _slide(ForgotPasswordScreen(
            initialIdentifier: extra?['identifier'] as String? ??
                state.uri.queryParameters['identifier'],
          ));
        },
      ),
      GoRoute(
        path: '/auth/merchant/verify-otp',
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _slide(MerchantVerifyOtpScreen(
            identifier: extra?['identifier'] as String? ??
                state.uri.queryParameters['identifier'] ??
                '',
          ));
        },
      ),
      GoRoute(
        path: '/auth/merchant/reset-password',
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _slide(MerchantResetPasswordScreen(
            identifier: extra?['identifier'] as String? ??
                state.uri.queryParameters['identifier'] ??
                '',
            resetToken: extra?['reset_token'] as String? ??
                state.uri.queryParameters['token'] ??
                '',
          ));
        },
      ),
      GoRoute(
        path: '/auth/merchant/step1',
        pageBuilder: (_, __) => _slide(const MerchantStep1Screen()),
      ),
      GoRoute(
        path: '/auth/merchant/location',
        pageBuilder: (_, __) => _slide(const MerchantLocationScreen()),
      ),
      GoRoute(
        path: '/auth/merchant/location/map',
        pageBuilder: (_, state) {
          final extra = state.extra;
          double? lat;
          double? lng;
          if (extra is Map) {
            lat = (extra['latitude'] as num?)?.toDouble();
            lng = (extra['longitude'] as num?)?.toDouble();
          }
          return _slide(MerchantLocationMapScreen(
            initialLatitude: lat,
            initialLongitude: lng,
          ));
        },
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

      // Coquille principale marchand (Bottom Navigation Bar)
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MerchantShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/merchant/clients',
              pageBuilder: (_, __) => _fade(const ClientsScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/merchant/stats',
              pageBuilder: (_, __) => _fade(const DashboardScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/merchant',
              pageBuilder: (_, __) => _fade(const ValidateScreen()),
            ),
            GoRoute(
              path: '/merchant/validate',
              redirect: (_, __) => '/merchant',
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
            ),
          ]),
        ],
      ),

      // Routes hors coquille
      GoRoute(
        path: '/merchant/validate/success',
        pageBuilder: (_, state) {
          final q = state.uri.queryParameters;
          return _fade(ValidationSuccessOverlay(
            clientName: q['clientName'] ?? 'Client',
            mechanic: q['mechanic'] ?? 'stamps',
            stampCount: int.tryParse(q['stampCount'] ?? '') ?? 1,
            goal: int.tryParse(q['goal'] ?? '') ?? 10,
            pointsEarned: int.tryParse(q['pointsEarned'] ?? '') ?? 1,
            rewardUnlocked: q['rewardUnlocked'] == 'true',
            cashbackEarned: double.tryParse(q['cashbackEarned'] ?? ''),
            isOfflineSaved: q['isOfflineSaved'] == 'true',
          ));
        },
      ),
      GoRoute(
        path: '/merchant/offline',
        pageBuilder: (_, __) => _slide(const MerchantOfflineScreen()),
      ),
      GoRoute(
        path: '/merchant/clients/:id',
        pageBuilder: (_, s) => _slide(
          ClientDetailScreen(clientId: s.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/merchant/sms/conversation',
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final q = state.uri.queryParameters;
          return _slide(SmsConversationScreen(
            clientName:
                extra?['clientName'] as String? ?? q['name'] ?? 'Client',
            clientPhone: extra?['clientPhone'] as String? ?? q['phone'] ?? '',
            clientInitials:
                extra?['clientInitials'] as String? ?? q['initials'] ?? 'C',
          ));
        },
      ),
      GoRoute(
        path: '/merchant/sms/campaign/:id',
        pageBuilder: (_, state) => _slide(SmsCampaignDetailScreen(
          campaignId: state.pathParameters['id'] ?? '',
        )),
      ),
      GoRoute(
        path: '/merchant/campaigns/new',
        pageBuilder: (_, state) => _slide(CampaignTypeScreen(
          editingCampaign: state.extra as CampaignModel?,
        )),
        routes: [
          GoRoute(
            path: 'content',
            pageBuilder: (_, state) => _slide(CampaignContentScreen(
              editingCampaign: state.extra as CampaignModel?,
            )),
          ),
          GoRoute(
            path: 'recipients',
            pageBuilder: (_, state) => _slide(CampaignRecipientsScreen(
              editingCampaign: state.extra as CampaignModel?,
            )),
          ),
          GoRoute(
            path: 'summary',
            pageBuilder: (_, state) => _slide(CampaignSummaryScreen(
              editingCampaign: state.extra as CampaignModel?,
            )),
          ),
        ],
      ),
      GoRoute(
        path: '/merchant/sms/new',
        pageBuilder: (_, state) => _slide(CampaignTypeScreen(
          editingCampaign: state.extra as CampaignModel?,
        )),
        routes: [
          GoRoute(
            path: 'message',
            pageBuilder: (_, state) => _slide(SmsCampaignComposeScreen(
              editingCampaign: state.extra as CampaignModel?,
            )),
          ),
        ],
      ),
      GoRoute(
        path: '/merchant/more/programme',
        pageBuilder: (_, __) => _slide(const ProgrammeScreen()),
        routes: [
          GoRoute(
            path: 'tiers',
            pageBuilder: (_, __) => _slide(const ProgrammeTiersScreen()),
          ),
          GoRoute(
            path: 'rules',
            pageBuilder: (_, __) => _slide(const ProgrammeRulesScreen()),
          ),
          GoRoute(
            path: 'design',
            pageBuilder: (_, __) => _slide(const ProgrammeDesignScreen()),
          ),
          GoRoute(
            path: 'cashback',
            pageBuilder: (_, __) => _slide(const CashbackSettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/merchant/more/profile',
        pageBuilder: (_, __) => _slide(const merchant_profile.ProfileScreen()),
      ),
      GoRoute(
        path: '/merchant/more/notifications',
        pageBuilder: (_, __) => _slide(const merchant_notifs.NotificationsScreen()),
      ),
      GoRoute(
        path: '/merchant/more/preferences',
        pageBuilder: (_, __) => _slide(const PreferencesScreen()),
      ),
      GoRoute(
        path: '/merchant/more/team',
        pageBuilder: (_, __) => _slide(const TeamScreen()),
      ),
      GoRoute(
        path: '/merchant/more/language',
        pageBuilder: (_, __) => _slide(const LanguageThemeScreen()),
      ),
      GoRoute(
        path: '/merchant/more/hours',
        pageBuilder: (_, __) => _slide(const OpeningHoursScreen()),
      ),
      GoRoute(
        path: '/merchant/more/socials',
        pageBuilder: (_, __) => _slide(const SocialsScreen()),
      ),
      GoRoute(
        path: '/merchant/more/change-password',
        pageBuilder: (_, __) => _slide(const ChangePasswordScreen()),
      ),
      GoRoute(
        path: '/merchant/more/birthday-reward',
        pageBuilder: (_, __) => _slide(const BirthdayRewardScreen()),
      ),
      GoRoute(
        path: '/merchant/more/referral-reward',
        pageBuilder: (_, __) => _slide(const ReferralRewardScreen()),
      ),
      GoRoute(
        path: '/merchant/more/welcome-reward',
        pageBuilder: (_, __) => _slide(const WelcomeRewardScreen()),
      ),
      GoRoute(
        path: '/merchant/more/proximity-notification',
        pageBuilder: (_, __) => _slide(const ProximityNotificationScreen()),
      ),
      GoRoute(
        path: '/merchant/more/referrals',
        pageBuilder: (_, __) => _slide(const ReferralsScreen()),
      ),
      GoRoute(
        path: '/merchant/more/reviews',
        pageBuilder: (_, __) => _slide(const ReviewsScreen()),
      ),
      GoRoute(
        path: '/merchant/more/account',
        pageBuilder: (_, __) => _slide(const AccountCategoryScreen()),
        routes: [
          GoRoute(
            path: 'vitrine',
            pageBuilder: (_, __) => _slide(const VitrineScreen()),
          ),
          GoRoute(
            path: 'qrcode',
            pageBuilder: (_, __) => _slide(const QrCodeScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/merchant/more/subscription',
        pageBuilder: (_, __) => _slide(const SubscriptionScreen()),
        routes: [
          GoRoute(
            path: 'plan',
            pageBuilder: (_, __) => _slide(const SubscriptionScreen()),
          ),
          GoRoute(
            path: 'team',
            pageBuilder: (_, __) => _slide(const TeamScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/merchant/qrcode',
        pageBuilder: (_, __) => _fade(const QrCodeScreen()),
      ),
      GoRoute(
        path: '/merchant/legal/terms',
        pageBuilder: (_, __) => _slide(const MerchantLegalScreen(document: MerchantLegalDocument.terms)),
      ),
      GoRoute(
        path: '/merchant/legal/privacy',
        pageBuilder: (_, __) => _slide(const MerchantLegalScreen(document: MerchantLegalDocument.privacy)),
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
        begin: const Offset(0, 0.03),
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

