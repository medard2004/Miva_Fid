import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';

/// Repli si la position GPS est indisponible/refusée au moment d'ouvrir la
/// carte — centre-ville de Lomé, marché principal du produit.
const _fallbackCenter = LatLng(6.1319, 1.2228);

/// Carte plein écran pour positionner manuellement le restaurant — pin fixe
/// au centre, la carte bouge dessous. Renvoie `(latitude, longitude)` au pop.
///
/// Tuiles OpenStreetMap (gratuit, sans clé API) via `flutter_map` — pas de
/// compte Google Cloud ni de facturation requise.
class MerchantLocationMapScreen extends StatefulWidget {
  const MerchantLocationMapScreen({super.key});

  @override
  State<MerchantLocationMapScreen> createState() =>
      _MerchantLocationMapScreenState();
}

class _MerchantLocationMapScreenState
    extends State<MerchantLocationMapScreen> {
  LatLng _target = _fallbackCenter;
  final _controller = MapController();

  @override
  void initState() {
    super.initState();
    _centerOnGpsBestEffort();
  }

  /// Best-effort : n'affiche aucune erreur si la position n'est pas
  /// disponible, le repli sur `_fallbackCenter` suffit sur cet écran.
  Future<void> _centerOnGpsBestEffort() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      final target = LatLng(position.latitude, position.longitude);
      setState(() => _target = target);
      _controller.move(target, 16);
    } on LocationServiceException {
      // Reste sur _fallbackCenter — l'utilisateur ajuste le pin à la main.
    } catch (_) {
      // Idem pour un GPS trop lent (`TimeoutException` brute du plugin,
      // pas notre `LocationServiceException`) — best-effort, on n'affiche
      // rien, l'utilisateur ajuste le pin à la main.
    }
  }

  void _confirm() => context.pop((_target.latitude, _target.longitude));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _target,
              initialZoom: 16,
              onPositionChanged: (camera, hasGesture) =>
                  _target = camera.center,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mivafid.app',
              ),
            ],
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(LucideIcons.mapPin, size: 44, color: AppColors.merchant),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Sp.md),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: LucideIcons.arrowLeft,
                    onTap: () => context.pop(),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(Sp.md),
                child: AppButton.merchant(
                  'Confirmer cet emplacement',
                  onPressed: _confirm,
                  icon: LucideIcons.check,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}
