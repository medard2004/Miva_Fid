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
/// celui déjà porté par la notification elle-même (titre/corps), jamais
/// re-chargé depuis le serveur.
class CampaignDestination extends NotificationDestination {
  const CampaignDestination({
    required this.campaignId,
    required this.title,
    required this.body,
  });
  final String campaignId;
  final String title;
  final String body;
}

class ReferralDestination extends NotificationDestination {
  const ReferralDestination();
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
      final campaignId = data['campaign_id']?.toString();
      if (campaignId != null) {
        return CampaignDestination(campaignId: campaignId, title: title, body: body);
      }
      return const InboxDestination();

    case 'referral_pending':
    case 'referral_validated':
      return const ReferralDestination();

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
  // `push` partout, jamais `go` : ces destinations affichent un bouton
  // retour (`AppDetailBar`, dont le comportement par défaut est
  // `context.pop()`) — `go` remplace tout l'historique de navigation, il
  // n'y aurait alors plus rien à dépiler et le bouton resterait inerte.
  switch (destination) {
    case CardDestination(:final cardId):
      // `CardDetailScreen` sait déjà afficher un état "carte introuvable" —
      // pas de vérification préalable ici, une seule source de vérité.
      context.push('/client/card/$cardId');
    case RewardDestination(:final rewardId):
      // Idem : `RewardsScreen` vérifie l'existence et ouvre la fiche, ou
      // affiche l'état indisponible — pas de doublon de logique ici.
      context.push('/client/rewards?openReward=$rewardId');
    case CampaignDestination(:final campaignId, :final title, :final body):
      context.push('/client/campaign/$campaignId', extra: {'title': title, 'body': body});
    case ReferralDestination():
      context.push('/client/referral');
    case InboxDestination():
      context.push(inboxPath);
  }
}
