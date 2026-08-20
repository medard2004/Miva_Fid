# Récompenses — mise à jour en direct + build client cassé

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Combler les deux derniers écarts réels entre `MivaFid-doc/recompense.md` et le code : l'écran client cassé à la compilation, et les transitions d'état d'une récompense (déblocage, validation marchand, annulation) qui n'atteignent pas le client en direct — il faut aujourd'hui fermer/rouvrir l'écran "Mes récompenses" pour les voir.

**Architecture:** Réutilise exactement le mécanisme déjà en place pour `LoyaltyCard` (`LoyaltyCardUpdated` → canal privé Reverb `loyalty.{clientId}` → `RealtimeService` côté Flutter, déjà connecté dès l'authentification) : un nouvel événement `LoyaltyRewardUpdated` sur le **même** canal, un nouveau flux `onRewardUpdated` dans `RealtimeService`, et `RewardsNotifier` qui s'y abonne pour recharger la liste — même schéma que `WalletNotifier`.

**Tech Stack:** Laravel 13 + Reverb (broadcasting Pusher-protocol) côté `restaurant-loyalty-api` ; Flutter + Riverpod (`StateNotifierProvider`) + `web_socket_channel` côté `Miva_Fid`.

**Spec:** `/home/othnelio/fcm/MivaFid-doc/recompense.md` — sections 2.3.5 (notification immédiate au déblocage), 10.1 étape 10 (confirmation temps réel après validation), 13 (synchronisation temps réel).

## Global Constraints

- Aucune nouvelle connexion WebSocket côté client : tout passe par le canal `loyalty.{clientId}` déjà ouvert (`WalletNotifier` le connecte dès l'authentification, indépendamment de l'écran affiché).
- Le payload Reverb reste minimal (id + statut) : le client recharge la liste complète via `GET /rewards` plutôt que de patcher localement — c'est déjà le comportement existant après fermeture du QR sheet, on le déclenche juste automatiquement.
- Ne pas toucher aux migrations existantes (`loyalty_rewards`, `loyalty_transactions`) ni au modèle `LoyaltyReward` — la table a déjà toutes les colonnes nécessaires.
- Suivre le style de commentaire du fichier voisin `LoyaltyCardUpdated.php` (explique le *pourquoi*, pas le *quoi*).

## Hors périmètre (constaté en examinant le code, pas oublié)

Le doc `recompense.md` couvre plus que ce que ce plan traite. Deux écarts réels restent, volontairement exclus ici car ils ont un vrai prérequis manquant plutôt qu'une simple omission :

1. **§12 — identité de l'opérateur (« Serveur Kevin »), journal consultable par le manager, suspension/permissions du staff.** L'app marchand s'authentifie aujourd'hui *en tant que `Restaurant`* (`config/auth.php`, provider `restaurants`, token Sanctum créé sur le compte propriétaire) — il n'y a **aucun** utilisateur `StaffUser` connecté dans une requête marchand actuelle, alors que `used_by_staff_user_id`/`canceled_by_staff_user_id` (déjà dans la table `loyalty_rewards`) pointent vers `staff_users`. Aucune requête ne peut donc renseigner ces colonnes tant que l'authentification multi-staff n'existe pas côté API. C'est un prérequis, pas un bug de câblage — mérite son propre plan.
2. **Push FCM quand l'app est fermée, au déblocage d'une récompense.** Un pipeline complet existe déjà (`NotificationDispatcher`, `RewardUnlocked`, `SendRewardFcmFallback`, `PresenceChecker`) mais il est câblé sur le domaine legacy (`App\Models\Reward` + `User` + canal `presence-customer.{id}`), pas sur `LoyaltyReward` + `Client` (canal `loyalty.{clientId}`). `Client` n'a même pas de relation `deviceTokens`. Le réutiliser correctement est un vrai chantier, pas une ligne à ajouter — ce plan couvre seulement le temps réel via Reverb (app ouverte), qui satisfait déjà la lettre de la section 13.
3. **§6.3 — notification préventive avant expiration.** Le spec la marque lui-même optionnelle (« *peut* être envoyée »). Non traitée ici.

---

### Task 1: Débloquer la compilation client — `rewardsShowQrInstruction` manquant

L'écran `rewards_screen.dart` utilise `t.rewardsShowQrInstruction` (déjà présent dans `lib/l10n/app_fr.arb` et `app_en.arb`), mais la classe générée `AppLocalizations` ne l'expose pas — elle n'a simplement jamais été régénérée depuis l'ajout de la clé. `flutter analyze` échoue actuellement sur ce fichier avec `undefined_getter`.

**Files:**
- Modify (généré, pas de code à écrire à la main) : `lib/l10n/gen/app_localizations*.dart`
- Vérifier : `lib/l10n/app_fr.arb:128`, `lib/l10n/app_en.arb:128` (déjà présents, aucun changement)

**Interfaces:**
- Consomme : rien.
- Produit : `AppLocalizations.rewardsShowQrInstruction`, utilisé par une tâche ultérieure indirectement (aucune, cette tâche est indépendante des suivantes — juste un déblocage de build).

- [ ] **Step 1: Confirmer le symptôme**

Run: `cd /home/othnelio/fcm/Miva_Fid && flutter analyze lib/features/client/rewards/rewards_screen.dart`
Expected (avant fix): `error • The getter 'rewardsShowQrInstruction' isn't defined for the type 'AppLocalizations' • lib/features/client/rewards/rewards_screen.dart:147:15`

- [ ] **Step 2: Régénérer les fichiers de localisation**

Run: `cd /home/othnelio/fcm/Miva_Fid && flutter gen-l10n`
Expected: sortie sans erreur, `lib/l10n/gen/app_localizations_fr.dart` et `app_localizations_en.dart` réécrits avec le getter `rewardsShowQrInstruction`.

- [ ] **Step 3: Vérifier que l'erreur a disparu**

Run: `cd /home/othnelio/fcm/Miva_Fid && flutter analyze lib/features/client/rewards/rewards_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
cd /home/othnelio/fcm/Miva_Fid
git add lib/l10n/gen/
git commit -m "fix: régénère les l10n générés, rewardsShowQrInstruction manquant cassait la compilation"
```

---

### Task 2: Backend — événement `LoyaltyRewardUpdated`

Nouvel événement Reverb, calqué sur `app/Events/LoyaltyCardUpdated.php` (même canal privé `loyalty.{clientId}`, déjà autorisé dans `routes/channels.php` — aucun changement de canal nécessaire).

**Files:**
- Create: `restaurant-loyalty-api/app/Events/LoyaltyRewardUpdated.php`
- Test: `restaurant-loyalty-api/tests/Feature/Merchant/RewardRealtimeTest.php`

**Interfaces:**
- Consomme : `App\Models\LoyaltyReward` (déjà existant, relation `loyaltyCard()` déjà définie).
- Produit : `LoyaltyRewardUpdated::dispatch(LoyaltyReward $reward)`, diffuse `loyalty.reward.updated` avec payload `{id, status}` sur le canal `private-loyalty.{clientId}`. Consommé par Task 3.

- [ ] **Step 1: Écrire le test qui échoue**

```php
<?php

namespace Tests\Feature\Merchant;

use App\Events\LoyaltyRewardUpdated;
use App\Models\Client;
use App\Models\LoyaltyCard;
use App\Models\LoyaltyProgram;
use App\Models\LoyaltyReward;
use App\Models\Restaurant;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Str;
use Tests\TestCase;

/**
 * Le client doit voir une récompense passer à "Utilisée"/"Annulée" sans
 * pull-to-refresh — voir `MivaFid-doc/recompense.md` section 13. Un seul
 * événement, réutilisé aux trois points de transition (déblocage,
 * validation, annulation), sur le canal Reverb déjà ouvert par le wallet.
 */
class RewardRealtimeTest extends TestCase
{
    use RefreshDatabase;

    private function restaurantWithToken(): array
    {
        $restaurant = Restaurant::create([
            'name'     => 'Chez Awa',
            'category' => 'Restaurant',
            'email'    => 'commerce@example.com',
            'password' => bcrypt('password123'),
        ]);
        $token = $restaurant->createToken('merchant-app')->plainTextToken;

        return [$restaurant, $token];
    }

    private function cardFor(Restaurant $restaurant, LoyaltyProgram $program): LoyaltyCard
    {
        $client = Client::create([
            'uuid'       => (string) Str::uuid(),
            'first_name' => 'Ada',
            'phone'      => '+22890000001',
            'password'   => bcrypt('secret123'),
        ]);

        return LoyaltyCard::create([
            'client_id'          => $client->id,
            'restaurant_id'      => $restaurant->id,
            'loyalty_program_id' => $program->id,
            'progress'           => ['stamps_current' => 0],
        ]);
    }

    public function test_unlocking_a_reward_broadcasts_it(): void
    {
        Event::fake([LoyaltyRewardUpdated::class]);

        [$restaurant, $token] = $this->restaurantWithToken();
        $program = LoyaltyProgram::create([
            'restaurant_id' => $restaurant->id,
            'name'          => 'Programme',
            'type'          => 'stamps',
            'config'        => ['goal' => 1, 'reward_description' => 'Burger offert'],
        ]);
        $card = $this->cardFor($restaurant, $program);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/merchant/clients/{$card->id}/stamps")->assertOk();

        $reward = LoyaltyReward::first();

        Event::assertDispatched(
            LoyaltyRewardUpdated::class,
            fn (LoyaltyRewardUpdated $e) => $e->reward->id === $reward->id
        );
    }

    public function test_redeeming_a_reward_broadcasts_it(): void
    {
        [$restaurant, $token] = $this->restaurantWithToken();
        $program = LoyaltyProgram::create([
            'restaurant_id' => $restaurant->id,
            'name'          => 'Programme',
            'type'          => 'stamps',
            'config'        => ['goal' => 1],
        ]);
        $card = $this->cardFor($restaurant, $program);
        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/merchant/clients/{$card->id}/stamps")->assertOk();
        $reward = LoyaltyReward::first();

        Event::fake([LoyaltyRewardUpdated::class]);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/merchant/rewards/{$reward->id}/redeem")->assertOk();

        Event::assertDispatched(
            LoyaltyRewardUpdated::class,
            fn (LoyaltyRewardUpdated $e) => $e->reward->id === $reward->id && $e->reward->status === 'used'
        );
    }

    public function test_canceling_a_reward_broadcasts_it(): void
    {
        [$restaurant, $token] = $this->restaurantWithToken();
        $program = LoyaltyProgram::create([
            'restaurant_id' => $restaurant->id,
            'name'          => 'Programme',
            'type'          => 'stamps',
            'config'        => ['goal' => 1],
        ]);
        $card = $this->cardFor($restaurant, $program);
        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/merchant/clients/{$card->id}/stamps")->assertOk();
        $reward = LoyaltyReward::first();

        Event::fake([LoyaltyRewardUpdated::class]);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/merchant/rewards/{$reward->id}/cancel")->assertOk();

        Event::assertDispatched(
            LoyaltyRewardUpdated::class,
            fn (LoyaltyRewardUpdated $e) => $e->reward->id === $reward->id && $e->reward->status === 'canceled'
        );
    }

    public function test_broadcasts_on_the_clients_private_channel(): void
    {
        [$restaurant, $token] = $this->restaurantWithToken();
        $program = LoyaltyProgram::create([
            'restaurant_id' => $restaurant->id,
            'name'          => 'Programme',
            'type'          => 'stamps',
            'config'        => ['goal' => 1],
        ]);
        $card = $this->cardFor($restaurant, $program);
        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/merchant/clients/{$card->id}/stamps")->assertOk();
        $reward = LoyaltyReward::first()->load('loyaltyCard');

        $event = new LoyaltyRewardUpdated($reward);

        $channels = $event->broadcastOn();
        $this->assertCount(1, $channels);
        $this->assertSame('private-loyalty.' . $card->client_id, $channels[0]->name);
        $this->assertSame('loyalty.reward.updated', $event->broadcastAs());
        $this->assertSame(
            ['id' => $reward->id, 'status' => 'available'],
            $event->broadcastWith()
        );
    }
}
```

- [ ] **Step 2: Lancer les tests, vérifier qu'ils échouent**

Run: `cd /home/othnelio/fcm/restaurant-loyalty-api && php artisan test --filter=RewardRealtimeTest`
Expected: FAIL — `Class "App\Events\LoyaltyRewardUpdated" not found`.

- [ ] **Step 3: Créer l'événement**

```php
<?php

namespace App\Events;

use App\Models\LoyaltyReward;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Diffusé à chaque transition d'état d'une récompense (déblocage, validation
 * marchand, annulation) — permet à l'écran "Mes récompenses" de se mettre à
 * jour en direct, sans pull-to-refresh (voir `MivaFid-doc/recompense.md`
 * section 13). Réutilise le canal privé de `LoyaltyCardUpdated`
 * (`loyalty.{clientId}`, déjà autorisé dans `routes/channels.php` et déjà
 * ouvert côté app dès l'authentification) plutôt que d'en ouvrir un second.
 */
class LoyaltyRewardUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public LoyaltyReward $reward)
    {
    }

    /**
     * @return array<int, Channel>
     */
    public function broadcastOn(): array
    {
        $clientId = $this->reward->loyaltyCard?->client_id;

        // Une carte supprimée après coup laisse `loyalty_card_id` à null
        // (nullOnDelete, voir la migration) : rien à diffuser, pas d'erreur.
        return $clientId === null ? [] : [new PrivateChannel('loyalty.' . $clientId)];
    }

    public function broadcastAs(): string
    {
        return 'loyalty.reward.updated';
    }

    public function broadcastWith(): array
    {
        return [
            'id'     => $this->reward->id,
            'status' => $this->reward->status,
        ];
    }
}
```

- [ ] **Step 4: Lancer les tests, vérifier qu'ils échouent encore (pas encore dispatché)**

Run: `cd /home/othnelio/fcm/restaurant-loyalty-api && php artisan test --filter=RewardRealtimeTest`
Expected: `test_broadcasts_on_the_clients_private_channel` PASS (l'événement existe et se construit correctement) ; `test_unlocking_a_reward_broadcasts_it`, `test_redeeming_a_reward_broadcasts_it`, `test_canceling_a_reward_broadcasts_it` FAIL — rien ne dispatche encore l'événement.

- [ ] **Step 5: Commit**

```bash
cd /home/othnelio/fcm/restaurant-loyalty-api
git add app/Events/LoyaltyRewardUpdated.php tests/Feature/Merchant/RewardRealtimeTest.php
git commit -m "feat: ajoute l'événement LoyaltyRewardUpdated (pas encore dispatché)"
```

---

### Task 3: Backend — dispatcher l'événement aux trois points de transition

**Files:**
- Modify: `restaurant-loyalty-api/app/Http/Controllers/Api/MerchantDashboardController.php:5` (import), `:373-393` (déblocage), `:448-481` (redeem), `:486-509` (cancel)
- Test: `restaurant-loyalty-api/tests/Feature/Merchant/RewardRealtimeTest.php` (déjà écrit en Task 2)

**Interfaces:**
- Consomme : `LoyaltyRewardUpdated::dispatch()` (Task 2).
- Produit : rien de nouveau — complète le comportement testé en Task 2.

- [ ] **Step 1: Ajouter l'import en haut du fichier**

Modifier `app/Http/Controllers/Api/MerchantDashboardController.php:5`, juste après l'import existant de `LoyaltyCardUpdated` :

```php
use App\Events\LoyaltyCardUpdated;
use App\Events\LoyaltyRewardUpdated;
```

- [ ] **Step 2: Dispatcher au déblocage (dans la boucle de franchissement de cycle)**

Dans `grantStampOrPoints`, remplacer (autour de la ligne 384-393) :

```php
                // Une récompense tracée par franchissement — titre figé au
                // moment du déblocage (jamais résolu depuis `config` plus
                // tard, qui peut avoir changé entretemps).
                \App\Models\LoyaltyReward::create([
                    'loyalty_card_id' => $loyaltyCard->id,
                    'restaurant_id'   => $restaurantId,
                    'title'           => $rewardTitle,
                    'unlocked_at'     => now(),
                    'expires_at'      => $validityDays ? now()->addDays((int) $validityDays) : null,
                ]);
```

par :

```php
                // Une récompense tracée par franchissement — titre figé au
                // moment du déblocage (jamais résolu depuis `config` plus
                // tard, qui peut avoir changé entretemps).
                $reward = \App\Models\LoyaltyReward::create([
                    'loyalty_card_id' => $loyaltyCard->id,
                    'restaurant_id'   => $restaurantId,
                    'title'           => $rewardTitle,
                    'unlocked_at'     => now(),
                    'expires_at'      => $validityDays ? now()->addDays((int) $validityDays) : null,
                ]);
                $reward->setRelation('loyaltyCard', $loyaltyCard);
                LoyaltyRewardUpdated::dispatch($reward);
```

(`setRelation` évite une requête de rechargement inutile : la carte est déjà en mémoire dans cette même transaction.)

- [ ] **Step 3: Dispatcher à la validation marchand**

Dans `redeemReward` (lignes 469-480), remplacer :

```php
            $loyaltyReward->update([
                'status'  => 'used',
                'used_at' => now(),
            ]);
        } finally {
            $lock->release();
        }

        return response()->json([
            'message' => 'Récompense validée.',
            'reward'  => $this->rewardData($loyaltyReward->fresh()->load('loyaltyCard.client')),
        ]);
```

par :

```php
            $loyaltyReward->update([
                'status'  => 'used',
                'used_at' => now(),
            ]);
        } finally {
            $lock->release();
        }

        $freshReward = $loyaltyReward->fresh()->load('loyaltyCard.client');
        LoyaltyRewardUpdated::dispatch($freshReward);

        return response()->json([
            'message' => 'Récompense validée.',
            'reward'  => $this->rewardData($freshReward),
        ]);
```

- [ ] **Step 4: Dispatcher à l'annulation**

Dans `cancelReward` (lignes 499-508), remplacer :

```php
        $loyaltyReward->update([
            'status'        => 'canceled',
            'canceled_at'   => now(),
            'cancel_reason' => $request->input('reason'),
        ]);

        return response()->json([
            'message' => 'Récompense annulée.',
            'reward'  => $this->rewardData($loyaltyReward->fresh()),
        ]);
```

par :

```php
        $loyaltyReward->update([
            'status'        => 'canceled',
            'canceled_at'   => now(),
            'cancel_reason' => $request->input('reason'),
        ]);

        $freshReward = $loyaltyReward->fresh()->load('loyaltyCard');
        LoyaltyRewardUpdated::dispatch($freshReward);

        return response()->json([
            'message' => 'Récompense annulée.',
            'reward'  => $this->rewardData($freshReward),
        ]);
```

- [ ] **Step 5: Lancer tous les tests du contrôleur, vérifier qu'ils passent**

Run: `cd /home/othnelio/fcm/restaurant-loyalty-api && php artisan test --filter=RewardRealtimeTest && php artisan test --filter=RewardRedemptionTest`
Expected: les 4 tests de `RewardRealtimeTest` PASS, et les 7 tests existants de `RewardRedemptionTest` restent au vert (aucune régression — `rewardData()` reçoit toujours le même objet, juste rechargé une fois en variable plutôt que deux fois en ligne).

- [ ] **Step 6: Suite complète du contrôleur (pas de régression ailleurs)**

Run: `cd /home/othnelio/fcm/restaurant-loyalty-api && php artisan test --filter=MerchantDashboard`
Expected: tout au vert.

- [ ] **Step 7: Commit**

```bash
cd /home/othnelio/fcm/restaurant-loyalty-api
git add app/Http/Controllers/Api/MerchantDashboardController.php
git commit -m "feat: diffuse LoyaltyRewardUpdated au déblocage, à la validation et à l'annulation"
```

---

### Task 4: Flutter — `RealtimeService.onRewardUpdated`

Même schéma que `onCardUpdated` existant, nouveau type de message reconnu dans `_onMessage`.

**Files:**
- Modify: `Miva_Fid/lib/core/services/realtime_service.dart`

**Interfaces:**
- Consomme : l'événement `loyalty.reward.updated` diffusé par Task 3, sur le canal déjà souscrit (`_subscribePrivateChannel`, inchangé).
- Produit : `RealtimeService.instance.onRewardUpdated` — `Stream<Map<String, dynamic>>`, payload `{id, status}`. Consommé par Task 5.

- [ ] **Step 1: Ajouter le controller et le getter**

Dans `realtime_service.dart`, juste après la déclaration de `_cardUpdatedController` :

```dart
  final _cardUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _rewardUpdatedController = StreamController<Map<String, dynamic>>.broadcast();

  /// Payload `LoyaltyCardUpdated::broadcastWith()` — id/progress/status/etc.
  Stream<Map<String, dynamic>> get onCardUpdated => _cardUpdatedController.stream;

  /// Payload `LoyaltyRewardUpdated::broadcastWith()` — `{id, status}`, à
  /// chaque déblocage/validation/annulation d'une récompense.
  Stream<Map<String, dynamic>> get onRewardUpdated => _rewardUpdatedController.stream;
```

- [ ] **Step 2: Reconnaître l'événement dans `_onMessage`**

Ajouter un `case` dans le `switch (event)` de `_onMessage`, juste après celui de `'loyalty.card.updated'` :

```dart
      case 'loyalty.card.updated':
        final data = _decodeData(message['data']);
        if (data != null) _cardUpdatedController.add(data);
        return;
      case 'loyalty.reward.updated':
        final data = _decodeData(message['data']);
        if (data != null) _rewardUpdatedController.add(data);
        return;
```

- [ ] **Step 3: Fermer le nouveau controller dans `dispose()`**

```dart
  void dispose() {
    disconnect();
    _cardUpdatedController.close();
    _rewardUpdatedController.close();
  }
```

- [ ] **Step 4: Vérifier la compilation**

Run: `cd /home/othnelio/fcm/Miva_Fid && flutter analyze lib/core/services/realtime_service.dart`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
cd /home/othnelio/fcm/Miva_Fid
git add lib/core/services/realtime_service.dart
git commit -m "feat: RealtimeService expose onRewardUpdated"
```

---

### Task 5: Flutter — `RewardsNotifier` se met à jour en direct

Même schéma que `WalletNotifier._realtimeSub` (`lib/features/client/providers/wallet_provider.dart:17`).

**Files:**
- Modify: `Miva_Fid/lib/features/client/providers/app_providers.dart:1-39`

**Interfaces:**
- Consomme : `RealtimeService.instance.onRewardUpdated` (Task 4).
- Produit : rien de nouveau — complète le comportement de `rewardsProvider` déjà consommé par `rewards_screen.dart` et `NotificationsNotifier`.

- [ ] **Step 1: Ajouter les imports nécessaires**

En haut de `app_providers.dart`, ajouter :

```dart
import 'dart:async';

import 'package:miva_fid/core/services/realtime_service.dart';
```

- [ ] **Step 2: Ouvrir l'abonnement dans le constructeur et le fermer**

Remplacer :

```dart
class RewardsNotifier extends StateNotifier<List<Reward>> {
  RewardsNotifier(this._ref) : super(const []) {
    _ref.listen<AuthState>(authProvider, _onAuthChanged, fireImmediately: true);
  }

  final Ref _ref;
```

par :

```dart
class RewardsNotifier extends StateNotifier<List<Reward>> {
  RewardsNotifier(this._ref) : super(const []) {
    _ref.listen<AuthState>(authProvider, _onAuthChanged, fireImmediately: true);
    // Le canal Reverb est déjà ouvert dès l'authentification par
    // `WalletNotifier` (même `loyalty.{clientId}`) — on ne fait
    // qu'écouter un événement de plus dessus, pas de connexion en propre.
    _realtimeSub = RealtimeService.instance.onRewardUpdated.listen(
      (_) => loadMine().catchError((_) {}),
    );
  }

  final Ref _ref;
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
```

- [ ] **Step 3: Vérifier la compilation**

Run: `cd /home/othnelio/fcm/Miva_Fid && flutter analyze lib/features/client/providers/app_providers.dart`
Expected: `No issues found!`

- [ ] **Step 4: Vérification manuelle de bout en bout**

Pas de précédent de test automatisé pour les notifiers Riverpod à flux temps réel dans ce repo (`wallet_provider.dart` n'en a pas non plus) — vérification manuelle, comme pour le fix équivalent sur le wallet :

1. Backend : `composer dev` (démarre Laravel + Reverb + le proxy nginx de dev — voir `CLAUDE.md`).
2. Flutter : lancer l'app, se connecter côté client, ouvrir "Mes récompenses" avec au moins une récompense disponible, afficher son QR (**ne pas fermer la feuille**).
3. Dans une autre session (app marchand ou Postman avec le token marchand), appeler `POST /api/merchant/rewards/{id}/redeem`.
4. Attendu : sans toucher à l'app client, la liste "Mes récompenses" repasse la récompense en "Utilisée" — visible dès la fermeture du QR sheet (ou immédiatement si l'écran "Mes récompenses" est déjà affiché en dessous, `ref.watch(rewardsProvider)` déclenche un rebuild automatique).
5. Répéter avec `POST /api/merchant/rewards/{id}/cancel` sur une autre récompense disponible.
6. Répéter en déclenchant un déblocage (`POST /api/merchant/clients/{card}/stamps` jusqu'à l'objectif) pendant que l'écran "Mes récompenses" est ouvert côté client : la nouvelle récompense doit apparaître sans pull-to-refresh.

- [ ] **Step 5: Commit**

```bash
cd /home/othnelio/fcm/Miva_Fid
git add lib/features/client/providers/app_providers.dart
git commit -m "feat: RewardsNotifier se recharge en direct sur les transitions de récompense"
```

---

## Self-Review

**Couverture spec** (sections concernées par ce plan uniquement) :
- §2.3.5 « notification immédiate » → couvert côté Reverb (Task 3+5) ; push FCM hors app explicitement hors périmètre (voir en-tête).
- §10.1 étape 10 « confirmation en temps réel » → Task 3 (dispatch redeem) + Task 5 (écoute côté client).
- §13 synchronisation temps réel (les 4 puces) → déblocage ✅ Task 3, validation ✅ Task 3, expiration automatique = déjà passive/calculée à la lecture (`is_expired`), aucun dispatch nécessaire ; changement de niveau = hors périmètre (aucune notification de niveau n'existe encore, ni legacy ni réelle — non mentionné comme régression, non traité ici).
- §12, une partie de §10.1 étape 8 (identité opérateur), §6.3 → explicitement hors périmètre, raisons documentées en en-tête.

**Placeholders** : aucun — chaque step contient soit une commande exacte, soit un bloc de code complet.

**Cohérence des types/noms** : `LoyaltyRewardUpdated` (Task 2) → `LoyaltyRewardUpdated::dispatch()` (Task 3) → `'loyalty.reward.updated'` (Task 2 `broadcastAs`, repris tel quel dans Task 4 `_onMessage`) → `onRewardUpdated` (Task 4 getter, repris tel quel dans Task 5). Payload `{id, status}` cohérent entre `broadcastWith()` (Task 2) et l'usage côté Flutter (Task 4/5 ne lisent pas le contenu du payload, se contentent de déclencher `loadMine()` — donc aucune dépendance de forme exacte au-delà de « c'est un Map non nul »).
