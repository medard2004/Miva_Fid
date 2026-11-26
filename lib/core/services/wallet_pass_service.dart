import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/client/card_detail/card_export_service.dart';
import '../../features/client/core/theme/app_colors.dart';
import '../../features/client/models/loyalty_card.dart';
import '../api/providers/api_providers.dart';

/// Gère l'ajout d'une carte de fidélité vers Google Wallet (JWT Save URL),
/// avec repli automatique vers l'enregistrement hors-ligne de l'image de la
/// carte si Google Wallet n'est pas encore activé sur le serveur.
class WalletPassService {
  static Future<void> addToGoogleWallet({
    required BuildContext context,
    required WidgetRef ref,
    required LoyaltyCard card,
    required GlobalKey exportKey,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    String? passUrl;
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get(
        '/loyalty-cards/${card.id}/wallet-pass',
        queryParameters: {'platform': 'google'},
      );
      if (response.data is Map) {
        final url = response.data['url']?.toString();
        if (url != null && url.isNotEmpty) {
          passUrl = url;
        }
      }
    } on DioException catch (e) {
      debugPrint(
        '[WalletPassService] Endpoint Google Wallet indisponible (${e.response?.statusCode}): ${e.message}',
      );
    } catch (e) {
      debugPrint('[WalletPassService] Erreur Google Wallet: $e');
    }

    if (context.mounted) Navigator.pop(context);

    if (passUrl != null) {
      final uri = Uri.tryParse(passUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: kIsWeb ? '_blank' : null,
        );
        return;
      }
    }

    if (!context.mounted) return;

    // Repli : enregistrement de l'image haute définition de la carte (avec QR)
    // tant que les clés Google Wallet ne sont pas encore configurées côté serveur.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Google Wallet non encore activé sur le serveur — export de la carte en cours…',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.inkSolid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    await CardExportService.exportAndShareCard(
      context,
      card,
      'save',
      exportKey,
    );
  }
}
