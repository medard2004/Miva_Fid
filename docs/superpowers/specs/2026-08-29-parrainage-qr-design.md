# Parrainage — QR code + identifiant unique par établissement

Date : 2026-08-29
Statut : approuvé (design), en attente d'implémentation
Périmètre : backend (`restaurant-loyalty-api`) + app (`Miva_Fid`)

## Contexte

Le système de parrainage actuel est en réalité **trois mécanismes différents, incohérents entre eux, et aucun ne correspond au besoin** :

1. **App Flutter** (`lib/features/client/referral/referral_screen.dart`, `lib/features/client/providers/referral_provider.dart`) : flow de partage entièrement mocké (`MockData`), aucun appel API. Règle métier fictive : "100 partages uniques validés = 3 points", validation anti-fraude simulée côté client.
2. **Backend Laravel** (`ClientAuthController::register()`/`generateReferralCode()`) : code de parrainage **global** (pas par établissement) saisi au signup, lie `referred_by_client_id` sur `clients`. **Aucune récompense n'est jamais attribuée.**
3. **Table `referrals`** (migration `2026_07_20_000013_create_referrals_table.php`) : schéma scaffoldé (`status`, `restaurant_id`, `bonus_points`) mais **jamais branché** — aucun modèle, contrôleur, route.

Les docs (`PRD_App_Client.md` §7, `MivaFid_Architecture_Technique.md`) décrivent encore un quatrième modèle (partage+clic), lui-même incohérent avec `MivaFid_Vision_Produit_Complet.md`.

Infra réutilisable déjà en place :
- QR : `mobile_scanner` + `qr_flutter`, pattern `LoyaltyReward.redeem_token` / `Restaurant.qr_token` (UUID, généré à la création avec retry sur collision), préfixe de type (`MIVAFID-REWARD:`) pour distinguer les QR au scan.
- `LoyaltyCard` : déjà unique par (client, restaurant), porte déjà `qr_token` (utilisé par le marchand pour scanner et ajouter un tampon/point — usage différent du join).
- `LoyaltyReward.source` : précédent pour brancher un nouveau type de récompense (`'tier'`, puis `'birthday'`) sans toucher au cœur du modèle.
- FCM déjà opérationnel de bout en bout : `App\Services\Fcm\FcmService`, `DeviceToken`, `NotificationLog`, job `SendCampaignNotification` comme modèle d'envoi push + log.

## Objectif

Remplacer entièrement les trois mécanismes ci-dessus par un système unique :

- Chaque `LoyaltyCard` (= chaque adhésion client↔établissement) porte son propre identifiant de parrainage et son propre QR.
- Le parrainage reste **en attente** jusqu'à la première opération de fidélité réelle du filleul sur cet établissement (premier tampon / première opération points / premier cashback) — ni le scan, ni la création de compte ne déclenchent la récompense.
- La récompense du parrain est configurée par le marchand, une seule fois par établissement.
- Suppression complète de l'ancien système, sans logique résiduelle en conflit.

## Modèle de données

### `loyalty_cards` (migration d'ajout)

- `referral_code` : string, unique, nullable. Court, partageable (ex. `AMINA-R7X2`). Généré à la création de la carte, retry-on-collision comme `LoyaltyReward.redeem_token`.
- `referral_qr_token` : string, unique, nullable. UUID encodé dans le QR avec préfixe `MIVAFID-REFERRAL:` (distinct du préfixe `MIVAFID-REWARD:` et du `qr_token` brut de la carte, pour ne jamais être confondu au scan avec un scan marchand de tampon/point).

Les deux sont générés en même temps que `qr_token`/`card_code` (même hook `booted()`/`creating()` que le pattern existant).

### `referrals` (remplace la table morte `2026_07_20_000013_create_referrals_table.php`)

```
id
restaurant_id            (FK restaurants)
referrer_client_id       (FK clients)
referrer_card_id         (FK loyalty_cards)
referred_client_id       (FK clients)
referred_card_id         (FK loyalty_cards)
status                   enum: pending, validated   — défaut pending
validated_at             timestamp nullable
reward_loyalty_reward_id (FK loyalty_rewards, nullable — rempli à la validation)
timestamps
```

Contraintes :
- `unique(referred_client_id, restaurant_id)` — un filleul n'a qu'un seul parrain par établissement (règle 6), et une fois posé il ne peut pas être remplacé (insert-only, aucun update de `referrer_*`).
- Check applicatif : `referrer_client_id != referred_client_id` (pas d'auto-parrainage).

### `loyalty_programs.config` (JSON existant)

Nouvelle clé `referral_reward` : `{ "type": "stamp" | "cashback" | "custom", "amount": number, "label": string|null }`. Un seul réglage par établissement (pas par type de programme). Configuré par le marchand dans `programme_screen.dart`.

### Suppression

- `clients.referral_code`, `clients.referred_by_client_id` (migration drop).
- `ClientAuthController::generateReferralCode()`, logique `referral_code` dans `register()`.
- `RegisterRequest` : validation `referral_code`.
- Test `AuditScenariosTest::test_register_links_referrer_via_referral_code`.
- `User.referralCode` (Flutter, `lib/features/client/models/user.dart`).
- `lib/features/client/referral/referral_screen.dart`, `lib/features/client/providers/referral_provider.dart`, mocks associés dans `mock_data.dart`.

## Flow

### 1. Génération (automatique)

Dès qu'une `LoyaltyCard` est créée (un client rejoint un établissement, avec ou sans parrain), `referral_code` et `referral_qr_token` sont générés pour cette carte. Chaque client a donc un identifiant de parrainage distinct par établissement, dès son adhésion.

### 2. Scan par le filleul (réutilise le flow de join existant)

`qr_scan_screen.dart` → `join_restaurant_screen.dart` → `LoyaltyCardController@join` (étendu, comportement actuel préservé pour le cas normal) :

1. Code scanné matche `restaurants.qr_token` → join normal, **aucun parrain** (comportement actuel inchangé).
2. Code scanné matche `loyalty_cards.referral_qr_token` d'une carte existante → résout `restaurant_id` et `referrer_client_id`/`referrer_card_id` via cette carte. Deux rejets explicites (erreur retournée à l'app, pas de fallback silencieux) :
   - le scanneur est le même client que le parrain (auto-parrainage) ;
   - le scanneur a déjà une `LoyaltyCard` sur cet établissement (déjà membre — pas de parrainage rétroactif).
3. Dans le cas 2, après création normale de la `LoyaltyCard` du filleul : création d'une ligne `referrals` en `status=pending`. **Aucune récompense n'est attribuée à ce stade.**

### 3. Validation (première opération de fidélité)

Aux mêmes points d'entrée qui déclenchent déjà `CheckRewardUnlock` (ajout de tampon, opération points, génération de cashback) : après l'opération, si c'est la **première** opération de ce type sur la carte du filleul ET qu'une ligne `referrals` `pending` existe pour `referred_card_id` = cette carte :

1. `referrals.status = validated`, `validated_at = now()`.
2. Crée un `LoyaltyReward` pour le parrain (`source = 'referral'`), selon `loyalty_programs.config.referral_reward` de l'établissement.
3. `referrals.reward_loyalty_reward_id` = la récompense créée.
4. Dispatch du job `SendReferralValidatedNotification` (push + log, voir ci-dessous).

Le simple scan et la simple création de compte ne passent jamais par ce chemin — seule une opération de fidélité réelle le déclenche.

### 4. Notification

Nouveau job `SendReferralValidatedNotification` (même forme que `SendCampaignNotification`) : parcourt les `DeviceToken` du parrain, envoie via `FcmService::sendToToken` (`type: 'referral_validated'`, payload avec établissement + récompense), log dans `NotificationLog`. Côté Flutter, `notification_service.dart` route ce type comme les autres types déjà gérés. Aucune nouvelle infra push — réutilisation intégrale de l'existant.

## Écrans

### Client — Page Parrainage (remplace l'écran actuel)

- Sélecteur d'établissement si le client a plusieurs cartes (comme le flow de join gère déjà le multi-carte).
- QR généré depuis `referral_qr_token` de la carte active + `referral_code` affiché en dessous.
- Bouton Partager (`share_plus`, pattern déjà utilisé pour l'export de carte et le QR marchand).
- Liste "En attente" (filleuls avec `referrals.status = pending`) et "Validés" (avec date de validation + récompense obtenue).
- Nouveau `referral_repository.dart` / `referral_service.dart` (pattern `auth_repository.dart`), branché sur l'API réelle.

### Client — Écran de succès de join

`_CardRevealScreen` (dans `join_restaurant_screen.dart`) : mention optionnelle "parrainé par [prénom du parrain]" quand la carte créée a un `referrer_card_id`.

### Marchand — Liste des parrainages

Nouvel écran (pattern des listes existantes sous `more_screen.dart`/`account_category_screen.dart`) : parrain, filleul, statut, date, récompense attribuée, pour l'établissement du marchand.

### Marchand — Configuration de la récompense

Ajout dans `programme_screen.dart` : type de récompense parrainage (tampon / cashback / personnalisée) + valeur, écrit dans `loyalty_programs.config.referral_reward`.

## États

Seuls deux états implémentés (le "annulé/invalide" de la spec initiale est explicitement laissé de côté — YAGNI, les règles ci-dessus empêchent déjà structurellement les cas invalides à la création plutôt que de les détecter après coup) :

- **pending** : filleul a rejoint via le parrain, aucune opération de fidélité encore effectuée.
- **validated** : première opération effectuée, récompense attribuée, parrain notifié.

## Tests

**Backend** (suit les conventions Pest/PHPUnit existantes) :
- Génération `referral_code`/`referral_qr_token` à la création de carte (unicité, retry sur collision).
- Join via QR de parrainage : résolution établissement + parrain, rejet auto-parrainage, rejet si déjà membre.
- Transition `pending` → `validated` sur la première opération, pour chacun des trois types de programme (stamp/points/cashback).
- Non-déclenchement sur simple scan ou simple création de compte.
- Unicité : un filleul ne peut avoir qu'un seul parrain par établissement (contrainte + comportement applicatif).
- Création du `LoyaltyReward` (`source=referral`) selon la config du programme, et déclenchement de la notification.

**Flutter** :
- Provider/repository parrainage (mocks HTTP), suit le pattern des tests existants pour `auth_repository`.
- Génération et affichage du QR sur l'écran parrainage.
- Parsing du préfixe `MIVAFID-REFERRAL:` au scan, distinction avec le QR d'établissement normal.
