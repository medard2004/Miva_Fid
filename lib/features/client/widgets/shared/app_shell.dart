import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miva_fid/core/widgets/offline_banner.dart';
import 'package:miva_fid/features/client/core/router/tab_transition_direction.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'bottom_nav_bar.dart';

const _shellRoutes = [
  '/client/wallet',
  '/client/rewards',
  '/client/referral',
  '/client/settings',
];

/// Coquille avec bottom tab bar. Le device frame desktop (fond neutre
/// assombri) est appliqué ici pour détacher l'app du chrome du navigateur
/// sur les grands écrans.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  DateTime? _lastBackPressTime;

  int _indexForLocation(String location) {
    final i = _shellRoutes.indexWhere((r) => location.startsWith(r));
    return i == -1 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    // AppColors est un flag global lu directement (pas via Theme.of), donc
    // rien ne force naturellement ce widget à se reconstruire quand le
    // thème change ailleurs dans l'app. On observe explicitement le thème.
    ref.watch(appBrightnessProvider);
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);
    final isWide = MediaQuery.of(context).size.width > 620;

    final scaffold = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Si l'utilisateur n'est pas sur l'onglet principal (Wallet / Cartes = index 0),
        // on retourne d'abord sur la page Cartes.
        if (currentIndex != 0) {
          tabSlideDirection = -1;
          context.go('/client/wallet');
          return;
        }
        // Sur la page Cartes : double tap requis dans les 2 secondes pour quitter
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appuyez à nouveau pour quitter l\'application'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        // Quitter l'application proprement
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const OfflineBanner(),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNavBar(
                currentIndex: currentIndex,
                onTap: (i) {
                  tabSlideDirection = i >= currentIndex ? 1 : -1;
                  context.go(_shellRoutes[i]);
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (!isWide) return scaffold;

    // Version desktop : device frame centré sur fond neutre.
    return ColoredBox(
      color: AppColors.surfaceDesktopFrame,
      child: Center(
        child: Container(
          width: 420,
          height: 860,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: AppColors.inkSolid, width: 8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: scaffold,
        ),
      ),
    );
  }
}
