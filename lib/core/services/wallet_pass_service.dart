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
    String? apiError;
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
      final statusCode = e.response?.statusCode;
      if (statusCode == 501) {
        // Google Wallet pas encore activé côté serveur
        apiError = 'not_configured';
      } else {
        apiError = 'network';
      }
      debugPrint(
        '[WalletPassService] Endpoint Google Wallet indisponible ($statusCode): ${e.message}',
      );
    } catch (e) {
      apiError = 'unknown';
      debugPrint('[WalletPassService] Erreur Google Wallet: $e');
    }

    if (context.mounted) Navigator.pop(context);

    // Ouvrir l'URL Google Wallet si elle a été récupérée avec succès.
    //
    // IMPORTANT : sur Flutter Web, `canLaunchUrl` retourne toujours `false`
    // pour les schémas https:// car le navigateur ne peut pas vérifier à
    // l'avance si le schéma est géré. On lance donc directement `launchUrl`
    // et on gère l'échec éventuel dans le catch.
    if (passUrl != null) {
      final uri = Uri.tryParse(passUrl);
      if (uri != null) {
        try {
          final launched = await launchUrl(
            uri,
            mode: kIsWeb
                ? LaunchMode.platformDefault
                : LaunchMode.externalApplication,
            webOnlyWindowName: kIsWeb ? '_blank' : null,
          );
          if (launched) return;
        } catch (e) {
          debugPrint('[WalletPassService] Échec ouverture URL: $e');
        }
      }
    }

    if (!context.mounted) return;

    // Repli : message adapté selon la raison de l'échec + export de l'image
    // de la carte en dernier recours.
    final String snackMessage;
    if (apiError == 'not_configured') {
      snackMessage =
          'Google Wallet n\'est pas encore activé. Votre carte sera exportée en image.';
    } else if (apiError == 'network') {
      snackMessage =
          'Impossible de contacter le serveur. Vérifiez votre connexion et réessayez.';
    } else if (passUrl != null) {
      // L'URL a été générée mais n'a pas pu s'ouvrir
      snackMessage =
          'Impossible d\'ouvrir Google Wallet. Votre carte sera exportée en image.';
    } else {
      snackMessage =
          'Google Wallet indisponible pour le moment. Votre carte sera exportée en image.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(snackMessage),
        behavior: SnackBarBehavior.floating,
        backgroundColor: apiError == 'network'
            ? AppColors.error
            : AppColors.inkSolid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // En cas d'erreur réseau, pas d'export auto — l'utilisateur veut juste
    // ajouter à Google Wallet, pas sauvegarder une image.
    if (apiError != 'network') {
      await CardExportService.exportAndShareCard(
        context,
        card,
        'save',
        exportKey,
      );
    }
  }
}
