import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/client/card_detail/card_export_service.dart';
import '../../features/client/core/theme/app_colors.dart';
import '../../features/client/models/loyalty_card.dart';
import '../api/providers/api_providers.dart';

enum WalletPlatform { apple, google }

/// Gère l'ajout d'une carte de fidélité vers Apple Wallet (.pkpass) ou
/// Google Wallet (JWT Save URL), avec repli automatique vers l'enregistrement
/// hors-ligne de la carte si les certificats Wallet serveur ne sont pas encore
/// activés.
class WalletPassService {
  static Future<void> addToWallet({
    required BuildContext context,
    required WidgetRef ref,
    required LoyaltyCard card,
    required WalletPlatform platform,
    required GlobalKey exportKey,
  }) async {
    final platformName =
        platform == WalletPlatform.apple ? 'Apple Wallet' : 'Google Wallet';

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
        queryParameters: {'platform': platform.name},
      );
      if (response.data is Map) {
        final url = response.data['url']?.toString();
        if (url != null && url.isNotEmpty) {
          passUrl = url;
        }
      }
    } on DioException catch (e) {
      debugPrint(
        '[WalletPassService] Endpoint $platformName indisponible (${e.response?.statusCode}): ${e.message}',
      );
    } catch (e) {
      debugPrint('[WalletPassService] Erreur $platformName: $e');
    }

    if (context.mounted) Navigator.pop(context);

    if (passUrl != null) {
      final uri = Uri.tryParse(passUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (!context.mounted) return;

    // Repli : enregistrement de l'image haute définition de la carte (avec QR)
    // pour un accès instantané hors-ligne, en attendant l'activation des
    // certificats Apple/Google Wallet côté serveur.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$platformName nécessite des certificats serveur actifs — export de la carte en cours…',
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

