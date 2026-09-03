import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Destination unique où amener l'utilisateur au clic sur une notification
/// (push OS ou ligne de la boîte in-app) — le système décrit dans
/// `docs/superpowers/specs/...notifications-navigation-design.md` : un
/// nombre fixe de destinations, réutilisant des écrans déjà existants,
/// jamais une page bespoke par type de notification.
sealed class NotificationDestination {
  const NotificationDestination();
}

/// Rappel d'inactivité, cashback reçu, changement de niveau, ou tout futur
/// type portant un `card_id` — règle générique plutôt qu'un type en dur par
/// cas, pour rester extensible sans reparler navigation à chaque ajout.
class CardDestination extends NotificationDestination {
  const CardDestination(this.cardId);
  final String cardId;
}

/// Récompense débloquée ou récompense anniversaire (les deux créent une
/// vraie `LoyaltyReward`, portent donc un `reward_id`).
class RewardDestination extends NotificationDestination {
  const RewardDestination(this.rewardId);
  final String rewardId;
}

/// Campagne marchand (promo ou info générale) — le contenu affiché est
/// celui déjà porté par la notification elle-même (titre/corps + image_url
/// optionnelle), jamais re-chargé depuis le serveur.
class CampaignDestination extends NotificationDestination {
  const CampaignDestination({
    required this.campaignId,
    required this.title,
    required this.body,
    this.imageUrl,
    this.rewardId,
    this.campaignType,
    this.cardId,
  });
  final String campaignId;
  final String title;
  final String body;
  final String? imageUrl;
  final String? rewardId;
  final String? campaignType;
  final String? cardId;
}

/// Écran de notation (avis) spécifique pour un établissement (via la carte).
class ReviewDestination extends NotificationDestination {
  const ReviewDestination(this.cardId);
  final String cardId;
}

class ReferralDestination extends NotificationDestination {
  const ReferralDestination({this.cardId});
  final String? cardId;
}

/// Repli par défaut — type inconnu, annonce admin, ou tout type dont la
/// donnée nécessaire à une destination plus précise est absente.
class InboxDestination extends NotificationDestination {
  const InboxDestination();
}

/// Politique de résolution — pure, sans dépendance Flutter, testable seule.
NotificationDestination resolveNotificationDestination({
  required String type,
  required Map<String, dynamic> data,
  required String title,
  required String body,
}) {
  switch (type) {
    case 'reward_unlocked':
    case 'birthday':
      final rewardId = data['reward_id']?.toString();
      if (rewardId != null) return RewardDestination(rewardId);
      return const InboxDestination();

    case 'campaign':
    case 'promotion':
    case 'reminder':
    case 'review':
    case 'reward':
    case 'progress':
    case 'cashback':
    case 'referral':
    case 'announcement':
    case 'admin_broadcast':
      final campaignType = data['campaign_type']?.toString() ?? type;

      switch (campaignType) {
        case 'reminder':
        case 'progress':
          final cardId = data['card_id']?.toString();
          if (cardId != null) return CardDestination(cardId);
          break;
        case 'review':
          final cardId = data['card_id']?.toString();
          if (cardId != null) return ReviewDestination(cardId);
          break;
        case 'referral':
          final cardId = data['card_id']?.toString();
          return ReferralDestination(cardId: cardId);
        case 'reward':
          final rewardId = data['reward_id']?.toString();
          if (rewardId != null) return RewardDestination(rewardId);
          final cardId = data['card_id']?.toString();
          if (cardId != null) return CardDestination(cardId);
          break;
        case 'promotion':
        case 'announcement':
        default:
          final campaignId = (data['campaign_id'] ?? data['id'])?.toString();
          final imageUrl = data['image_url']?.toString();
          
          if (campaignId != null) {
            return CampaignDestination(
              campaignId: campaignId,
              title: title,
              body: body,
              imageUrl: imageUrl,
              campaignType: campaignType,
            );
          }

          if (title.isNotEmpty || body.isNotEmpty) {
            return CampaignDestination(
              campaignId: 'broadcast',
              title: title,
              body: body,
              imageUrl: imageUrl,
              campaignType: campaignType,
            );
          }
          break;
      }
      return const InboxDestination();

    case 'referral_pending':
    case 'referral_validated':
      final cardId = data['card_id']?.toString();
      return ReferralDestination(cardId: cardId);

    default:
      final cardId = data['card_id']?.toString();
      if (cardId != null) return CardDestination(cardId);
      return const InboxDestination();
  }
}

/// Exécute la navigation réelle pour une [NotificationDestination] déjà
/// résolue. `inboxPath` diffère entre app client et marchand — tout le
/// reste (carte/récompense/campagne/parrainage) est un concept client
/// uniquement : côté marchand, seuls les types sans donnée exploitable
/// existent aujourd'hui, ils retombent donc toujours sur `inboxPath`.
void navigateToNotificationDestination(
  BuildContext context,
  NotificationDestination destination, {
  String inboxPath = '/client/notifications',
}) {
  // Fiches hors coquille (`/client/card/:id`, campagne, boîte) : `push`,
  // pour que `AppDetailBar` puisse `pop`. Onglets de la coquille
  // (`/client/rewards`, `/client/referral`) : `go` — `push` d'un enfant du
  // `ShellRoute` alors que la coquille est déjà sous la boîte duplique
  // la pageKey du Navigator (`!keyReservation.contains(key)`).
  switch (destination) {
    case CardDestination(:final cardId):
      // `CardDetailScreen` sait déjà afficher un état "carte introuvable" —
      // pas de vérification préalable ici, une seule source de vérité.
      context.push('/client/card/$cardId');
    case RewardDestination(:final rewardId):
      // Idem : `RewardsScreen` vérifie l'existence et ouvre la fiche, ou
      // affiche l'état indisponible — pas de doublon de logique ici.
      context.go('/client/rewards?openReward=$rewardId');
    case CampaignDestination(:final campaignId, :final title, :final body, :final imageUrl, :final rewardId, :final campaignType, :final cardId):
      context.push('/client/campaign/$campaignId', extra: {
        'title': title,
        'body': body,
        'image_url': imageUrl,
        'reward_id': rewardId,
        'campaign_type': campaignType,
        'card_id': cardId,
      });
    case ReviewDestination(:final cardId):
      context.push('/client/review/$cardId');
    case ReferralDestination(:final cardId):
      if (cardId != null) {
        context.go('/client/referral?cardId=$cardId');
      } else {
        context.go('/client/referral');
      }
    case InboxDestination():
      context.push(inboxPath);
  }
}
