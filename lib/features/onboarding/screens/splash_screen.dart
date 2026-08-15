import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

/// Écran de démarrage animé — affiché juste après le splash natif (celui-ci
/// se ferme tout seul, automatiquement, dès que ce widget peint sa première
/// frame — comportement par défaut de Flutter, le plus fiable).
///
/// Séquence façon Pinterest : le logo apparaît à taille normale, respire
/// (dézoome puis zoome), puis s'envole vers le haut en s'estompant avant de
/// naviguer vers l'écran suivant.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _backgroundColor = Color(0xFF0F0E1A);
  static const _totalDuration = Duration(milliseconds: 1950);
  static const _logoSize = 104.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(_totalDuration, () {
      if (mounted) context.go('/role-select');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: Image.asset(
          'assets/images/logo_mivaFid.png',
          width: _logoSize,
          height: _logoSize,
        )
            .animate()
            // Apparition à taille normale.
            .fadeIn(duration: 300.ms, curve: Curves.easeOut)
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.0, 1.0),
              duration: 300.ms,
              curve: Curves.easeOut,
            )
            // Respire : dézoome...
            .then(delay: 150.ms)
            .scale(
              end: const Offset(0.88, 0.88),
              duration: 260.ms,
              curve: Curves.easeInOut,
            )
            // ...puis rezoome avec un léger dépassement.
            .then()
            .scale(
              end: const Offset(1.08, 1.08),
              duration: 260.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              end: const Offset(1.0, 1.0),
              duration: 180.ms,
              curve: Curves.easeOut,
            )
            // Tient un court instant, puis s'envole vers le haut.
            .then(delay: 300.ms)
            .moveY(
              end: -260,
              duration: 460.ms,
              curve: Curves.easeInCubic,
            )
            .fadeOut(duration: 400.ms, curve: Curves.easeIn),
      ),
    );
  }
}
