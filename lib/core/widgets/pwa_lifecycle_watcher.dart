import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Surveille le cycle de vie de l'application (en particulier sur Web et PWA).
///
/// Lorsqu'une PWA ou un onglet mobile revient au premier plan après un long séjour
/// en arrière-plan, le moteur de rendu Flutter (CanvasKit / WebGL) peut se trouver
/// dans un état inerte ou avoir manqué le signal de réveil. Ce widget force le
/// réordonnancement d'une frame et un redessin propre pour éviter tout écran noir.
class PwaLifecycleWatcher extends StatefulWidget {
  final Widget child;

  const PwaLifecycleWatcher({
    super.key,
    required this.child,
  });

  @override
  State<PwaLifecycleWatcher> createState() => _PwaLifecycleWatcherState();
}

class _PwaLifecycleWatcherState extends State<PwaLifecycleWatcher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force le moteur Flutter à planifier une frame de rendu
      WidgetsBinding.instance.scheduleFrame();

      // Sur Web / PWA, force une actualisation du sous-arbre après le cycle d'arrière-plan
      if (kIsWeb && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
