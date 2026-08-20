# Récompenses : obtention → utilisation (QR, marchand-validée)

## Contexte

Les 3 programmes (Tampons, Achats, Cashback) génèrent déjà un signal d'objectif atteint (`rewards_unlocked_count`, `loyalty_transactions.type = cycle_completed`, un couple obtention/récompense par programme, cf. spec précédente niveaux/pourcentage). Mais aucune récompense n'est réellement suivie une fois débloquée : `loyalty_cards.status = 'reward_available'` est un simple booléen de carte, jamais explicitement remis à `active` (écrasé par le prochain octroi), sans identité, sans historique, sans mécanisme d'utilisation. Une table `rewards` existe déjà en base mais est morte : jamais alimentée par le flux réel, sans statut, sans expiration, sans lien restaurant/carte.

Ce chantier construit le cycle de vie complet : une récompense débloquée devient une entité traçée, affichée au client, utilisable une seule fois via un QR unique scanné par le marchand.

## Ce qui ne change pas

- Les 3 mécaniques et leur déclenchement (`grantStampOrPoints`, carry-over, `cycle_completed`).
- `LoyaltyLevelService` — continue de compter les lignes `cycle_completed` existantes, non touché.
- Aucune nouvelle infrastructure de notifications générique (le système actuel est 100% mock pour tous les types) — seule la partie récompenses de l'écran notifications client est reconnectée aux vraies données, dérivée de la liste de récompenses.

## Modèle

**Nouvelle table `rewards`** (remplace l'ancienne, non tenant-scopée et jamais utilisée) : une ligne par récompense débloquée, insérée dans la même transaction DB que le `cycle_completed` correspondant (un-à-un, mais table distincte — le calcul de niveau reste adossé à `cycle_completed` uniquement).

Champs (niveau conceptuel) : carte concernée, établissement (accès direct pour les contrôles marchand sans jointure), **titre/description capturés en snapshot** au moment du déblocage (jamais résolus dynamiquement depuis `config.rewards`, qui peut être édité après coup par le marchand — un déblocage passé garde le libellé qui était vrai à ce moment-là), statut (`disponible` / `utilisée` / `annulée` — 3 états stockés), jeton QR unique à usage unique, `unlocked_at`, `expires_at` (nullable), `used_at` + identité du staff validateur, `canceled_at` + identité du staff + motif optionnel.

**Franchissements multiples en un seul octroi** (`rewards_unlocked_count` > 1) → une ligne `rewards` indépendante par franchissement, chacune son propre QR, aucune interaction entre elles.

**Config programme** : nouveau champ optionnel "durée de validité" (en jours), mirroring `goal`/`levels` dans `config`. Absent = récompenses sans expiration.

## Expiration — calculée à la lecture, pas de tâche planifiée

Seuls 3 statuts sont stockés (`disponible`/`utilisée`/`annulée`) — pas de 4ᵉ statut `expirée` persisté. `expires_at` est calculé une fois à l'obtention (`unlocked_at + durée configurée`, ou `null`). Une récompense `disponible` dont `expires_at` est dépassé s'affiche et se comporte comme expirée partout où elle est lue (liste client, tentative de validation marchand rejetée) — même principe que le calcul de niveau à la lecture, déjà en place. Pas de job cron à maintenir.

## Annulation

Action marchand, réservée aux récompenses encore `disponible` (aucun retour arrière sur une récompense déjà `utilisée`). Motif en texte libre, optionnel. Une fois `annulée`, définitivement inutilisable — visible dans l'historique du client comme telle.

## Flux de validation (synchrone, QR à usage unique)

1. **Côté client** : "Mes récompenses" devient une vraie liste (disponible/utilisée/annulée/expirée-calculée), plus mock. Sur une récompense disponible, "Utiliser" affiche son QR unique (widget `qr_flutter` déjà utilisé pour la carte).
2. **Côté marchand** : réutilise l'écran de scan existant (`validate_screen.dart`, `mobile_scanner`). Le contenu du QR récompense porte un préfixe distinct de celui d'une carte, pour que le même scanner route automatiquement vers la bonne feuille (recherche client vs confirmation récompense), sans ambiguïté ni double écran.
3. **Backend**, à la résolution du jeton scanné : vérifie appartenance à l'établissement connecté, statut `disponible`, non expirée (sinon rejet explicite).
4. **Confirmation marchand** (un tap, même geste qu'aujourd'hui pour l'octroi d'un tampon) → passage à `utilisée`, horodatage + identité du staff enregistrés, diffusion temps réel (même canal Reverb existant) pour mise à jour instantanée de l'app client sans pull-to-refresh.

## Notifications (câblées, périmètre limité aux récompenses)

L'écran notifications client existe déjà (`NotificationKind.reward` inclus) mais tourne intégralement sur données mock, pour tous les types. Seules les entrées liées aux récompenses sont reconnectées : dérivées directement de la vraie liste de récompenses (déblocage, utilisation), sans nouvelle table de notifications côté backend. Les autres types (tampon, points, cashback, parrainage, système) restent mock — hors périmètre de ce chantier.

## Séquencement

1. Nouvelle table `rewards` + insertion dans `grantStampOrPoints` (même transaction que `cycle_completed`), snapshot titre/description au moment du déblocage.
2. Config programme : durée de validité optionnelle.
3. Endpoints marchand : résolution d'un jeton scanné (recherche + détail), confirmation d'utilisation, annulation.
4. Endpoint/inclusion client : liste des récompenses de ses cartes.
5. Flutter marchand : branchement du scan existant sur le nouveau flux récompense (préfixe de routage), feuille de confirmation, action annulation.
6. Flutter client : `rewards_screen.dart` rebranché sur l'API réelle (fin du mock), affichage QR par récompense.
7. Notifications client : section récompenses dérivée des vraies données.

## Fichiers clés

- `restaurant-loyalty-api/app/Http/Controllers/Api/MerchantDashboardController.php` (`grantStampOrPoints`, nouveaux endpoints récompense)
- `restaurant-loyalty-api/app/Models/Reward.php` + migration (à reconstruire, l'existant est mort/inutilisable — voir Contexte)
- `restaurant-loyalty-api/app/Listeners/CheckRewardUnlock.php` (mort, `StampAdded` jamais émis — à retirer, remplacé par l'insertion directe dans `grantStampOrPoints`)
- `restaurant-loyalty-api/app/Http/Requests/Auth/StoreLoyaltyProgramRequest.php` (durée de validité)
- `Miva_Fid/lib/features/client/rewards/rewards_screen.dart`, `lib/features/client/models/reward.dart`, `lib/features/client/providers/app_providers.dart` (`RewardsNotifier`)
- `Miva_Fid/lib/features/merchant/screens/validate_screen.dart` (routage scan)
- `Miva_Fid/lib/features/client/notifications/notifications_screen.dart` (section récompenses)

## Vérification

- Tests backend : obtention crée bien N lignes `rewards` (N = `rewards_unlocked_count`) avec snapshot correct ; validation réussie sur récompense valide ; rejet sur récompense déjà utilisée/annulée/expirée/hors établissement ; annulation bloque toute validation ultérieure ; expiration calculée correcte aux bornes (juste avant/après `expires_at`).
- Test end-to-end manuel : déblocage d'une récompense → apparition immédiate côté client (temps réel) → QR affiché → scan marchand → confirmation → statut mis à jour des deux côtés sans refresh manuel.
