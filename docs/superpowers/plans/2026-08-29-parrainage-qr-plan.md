# Parrainage QR — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer les 3 mécanismes de parrainage incohérents actuels par un système unique : QR/identifiant par carte de fidélité, validation à la première opération, récompense configurable côté marchand.

**Architecture:** Backend Laravel étend `loyalty_cards` (referral_code/referral_qr_token) et remplace la table `referrals` morte. Le endpoint de join existant est étendu pour reconnaître un QR de parrainage. La validation se déclenche dans les mêmes points d'entrée que la création de récompense (addStamp/grantCashback). App Flutter : nouveau repository/provider/écran branchés sur l'API réelle, remplace le mock existant.

**Tech Stack:** Laravel (PHP), Pest/PHPUnit, Flutter/Dart, Riverpod, qr_flutter, mobile_scanner, share_plus, FCM (déjà en place).

**Spec:** `docs/superpowers/specs/2026-08-29-parrainage-qr-design.md`

## Global Constraints

- Un filleul = un seul parrain par établissement (contrainte unique `referred_client_id, restaurant_id`).
- Pas d'auto-parrainage.
- Ni le scan, ni la création de compte ne déclenchent la récompense — seule la première opération de fidélité valide.
- Suppression complète de l'ancien système (pas de logique résiduelle en conflit).
- Réutiliser les patterns existants (redeem_token retry, `source` sur LoyaltyReward, job FCM façon `SendCampaignNotification`).

---

## Backend (`restaurant-loyalty-api`)

### Task 1 — Schéma : loyalty_cards + referrals + suppression ancien
- Migration : ajoute `referral_code` (string, unique, nullable), `referral_qr_token` (string, unique, nullable) sur `loyalty_cards`.
- Migration : `Schema::dropIfExists('referrals')` puis recréation avec le nouveau schéma (restaurant_id, referrer_client_id, referrer_card_id, referred_client_id, referred_card_id, status, validated_at, reward_loyalty_reward_id, unique(referred_client_id, restaurant_id)).
- Migration : drop `clients.referral_code`, `clients.referred_by_client_id`.
- `LoyaltyCard::booted()` : génère `referral_code`/`referral_qr_token` comme `card_code`/`qr_token`, retry-on-collision.
- `Referral` model (Eloquent).
- `Client` model : retire `referral_code`/`referred_by_client_id` de `$fillable`, retire `referrer()`/`referrals()`.
- Test : génération référence unique à la création de carte.

### Task 2 — Nettoyage ClientAuthController / RegisterRequest
- Retire `generateReferralCode()`, logique `referral_code` dans `register()`.
- Retire validation `referral_code` de `RegisterRequest`.
- Retire `test_register_links_referrer_via_referral_code` de `AuditScenariosTest`.

### Task 3 — Join avec parrainage
- `LoyaltyCardController::join()` : si le code scanné matche `loyalty_cards.referral_qr_token` (avec ou sans préfixe `MIVAFID-REFERRAL:`) ou `referral_code`, résout établissement + parrain via cette carte. Rejette (422, message clair) : auto-parrainage, déjà membre.
- Après création de la carte du filleul dans ce cas : crée `Referral` en `status=pending`.
- Tests : join via referral_qr_token crée le parrainage pending ; rejet auto-parrainage ; rejet si déjà membre ; join normal (qr_token établissement) inchangé, aucun parrainage créé.

### Task 4 — ReferralService : validation à la première opération
- `app/Services/Referral/ReferralService.php` : `validateFirstOperation(LoyaltyCard $card): void` — si `Referral` pending pour `referred_card_id = $card->id` ET c'est la première transaction `stamp`/`cashback_earn` (status valid) de cette carte : marque `validated`, crée `LoyaltyReward` (source=referral) pour le parrain selon `loyalty_programs.config.referral_reward` (défaut si absent : `{type: 'stamp', amount: 1}` → 1 tampon manuel ou reward générique), lie `reward_loyalty_reward_id`, dispatch `SendReferralValidatedNotification`.
- Appelé depuis `MerchantDashboardController::grantStampOrPoints()` (après insert transaction `stamp`) et `grantCashback()` (après insert `cashback_earn`).
- Tests : validation sur 1er tampon, 1re opération points, 1re opération cashback ; pas de déclenchement sur scan/register seuls ; pas de double récompense sur 2e opération.

### Task 5 — Config récompense marchand
- `StoreLoyaltyProgramRequest` : ajoute règles `referral_reward_enabled` (bool), `referral_reward_type` (in:stamp,cashback,custom), `referral_reward_amount` (numeric), `referral_reward_label` (nullable string), mirroring `birthday_reward_*`.
- `LoyaltyProgramController::store()` : ajoute `referral_reward` au `config` (même bloc que `birthday_reward`).
- Test : sauvegarde et relecture de `referral_reward` dans le config.

### Task 6 — Endpoints de consultation + notification
- `ReferralController::mine(Request $request)` — GET, parrainages du client authentifié (pending + validated), avec établissement et filleul.
- `ReferralController::forRestaurant(Request $request)` — GET côté marchand, parrainages de l'établissement authentifié.
- `SendReferralValidatedNotification` job (mirror `SendCampaignNotification`) : push à tous les `DeviceToken` du parrain, log `NotificationLog`.
- Routes dans `routes/api.php` : `GET /referrals` (client), `GET /merchant/referrals` (marchand).
- Tests : les deux endpoints renvoient les bonnes données, scopés au bon client/restaurant.

---

## App Flutter (`Miva_Fid`)

### Task 7 — Suppression ancien système
- Supprime `lib/features/client/referral/referral_screen.dart`, `lib/features/client/providers/referral_provider.dart`.
- Retire `referralCode` de `User` (`lib/features/client/models/user.dart`).
- Retire mocks référence dans `mock_data.dart`.

### Task 8 — Modèle + repository
- `LoyaltyCard` (`lib/features/client/models/loyalty_card.dart`) : ajoute `referralCode`, `referralQrToken` (nullable String), mappés depuis le JSON existant de `/loyalty-cards`.
- `lib/core/api/repositories/referral_repository.dart` + `lib/core/api/services/referral_service.dart` (pattern `auth_repository.dart`/`auth_service.dart`) : `getMine()` → liste de parrainages (pending/validated).
- `lib/core/constants/referral_qr.dart` : `const referralQrPrefix = 'MIVAFID-REFERRAL:';`

### Task 9 — Provider + écran
- Nouveau `lib/features/client/providers/referral_provider.dart` (Riverpod `FutureProvider`/`AsyncNotifier`, remplace l'ancien) : charge la liste réelle via le repository.
- Nouveau `lib/features/client/referral/referral_screen.dart` : sélecteur d'établissement (cartes du wallet), QR (`qr_flutter`) généré depuis `referralQrPrefix + card.referralQrToken`, `referralCode` affiché, bouton Partager (`share_plus`), listes "En attente"/"Validés".
- Vérifie que la route `/client/referral` (déjà dans `app_router.dart`) pointe toujours vers `ReferralScreen` (même nom de classe, pas de changement de route nécessaire).

### Task 10 — Vérification
- `flutter analyze` propre sur les fichiers touchés.
- `flutter test` sur les tests existants + nouveaux touchant le parrainage.
- Backend : suite Pest/PHPUnit complète verte.

---

## Recommandations (hors périmètre de cette passe rapide)

- Écran marchand dédié pour visualiser la liste des parrainages (endpoint prêt, UI à construire).
- UI marchand pour configurer `referral_reward` dans l'assistant d'onboarding (backend accepte déjà les champs, défaut sensé appliqué si absent).
- Mention "parrainé par X" sur l'écran de révélation de carte (`_CardRevealScreen`).
- Lien profond de partage (`mivafid://join?ref=...`) en plus du QR/code.
- État "annulé/invalide" du parrainage (explicitement reporté, cf. spec).
- Couverture de tests plus large (cas limites additionnels au-delà du chemin critique).
