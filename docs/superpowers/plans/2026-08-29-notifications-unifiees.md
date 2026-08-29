# Centre de notifications unifié — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer les deux écrans notifications mock (client + marchand) par un vrai centre de notifications persistant côté serveur, et unifier les 6 points d'envoi push existants derrière un dispatcher unique appliquant une politique fixe par type d'événement (push+in-app, ou in-app seul).

**Architecture:** Nouvelle table `notifications` (polymorphe Client/Restaurant) = source de vérité du contenu et de l'état lu. `App\Services\NotificationDispatcher::send()` devient le point de passage unique : crée toujours la ligne in-app, déclenche le push FCM existant seulement si la politique du type le permet. Les 6 sites d'envoi existants sont réécrits pour l'appeler au lieu de contacter `FcmService`/`SendPromoNotification` directement. Un seul `NotificationController` (méthodes réutilisables) est monté sous deux groupes de routes (`/notifications` client, `/merchant/notifications` marchand) car `$request->user()` résout déjà vers `Client` ou `Restaurant` selon le token — pas de duplication de contrôleur.

**Tech Stack:** Laravel (backend, Sanctum, Eloquent, PHPUnit), Flutter/Riverpod (client : `StateNotifierProvider` manuel : merchant : `@riverpod` codegen, conventions existantes de chaque répertoire).

**Spec:** `docs/superpowers/specs/2026-08-29-notifications-unifiees-design.md`

## Corrections apportées pendant la préparation du plan (à lire avant d'exécuter)

Trois écarts découverts en localisant précisément le code, par rapport au texte du spec — comportement/portée inchangés sur le fond, seuls les points d'intégration exacts sont corrigés :

1. **`reward_unlocked` ne passe PAS par `NotificationDispatcher::dispatchRewardUnlocked`.** Cette méthode existante appartient à un système de récompenses parallèle et non branché en pratique (`App\Models\Reward`, table `customer_id` → `App\Models\User`, qui n'est jamais peuplée — voir le commentaire dans `SendBirthdayNotifications.php`). Le vrai flux de récompense utilisé par l'app (`LoyaltyReward`, déclenché par `MerchantDashboardController::grantStampOrPoints`/`grantCashback`) ne crée aujourd'hui **aucune** notification (ni push, ni in-app) — seul un événement Reverb temps réel (`LoyaltyRewardUpdated`) existe, sans repli si le client est hors ligne. Le Task 7 ci-dessous ajoute `reward_unlocked` exactement à ces deux points réels, pas à l'ancien `NotificationDispatcher::dispatchRewardUnlocked` (laissé intact, hors périmètre).
2. **`merchant_low_sms` et `merchant_weekly_report` ne sont PAS câblés dans ce plan.** Aucune infrastructure de suivi de quota SMS ni de génération de rapport hebdomadaire n'existe côté backend (vérifié : aucune colonne, aucun job, seule la clé de préférence `notification_preferences` existe et n'est lue nulle part). Les construire est hors périmètre (ni demandé, ni dans le spec). Seul `merchant_new_client` est câblé (Task 8). Les deux autres types restent définis dans la table de politique pour un futur projet, mais ne seront produits par aucun événement pour l'instant — la boîte marchand sera donc plus clairsemée que la maquette retirée, c'est attendu.
3. **`SendGlobalNotification` interroge aujourd'hui `App\Models\User`**, une table jamais peuplée (même bug que döcrit dans `SendBirthdayNotifications.php` avant son correctif) — la commande ne notifie donc personne en pratique. Le Task 6 la corrige pour interroger `Client` et `Restaurant`, sans quoi router `admin_broadcast` à travers le dispatcher serait un no-op silencieux.
4. **Endpoints étendus à 6 au lieu de 4** (spec en listait 4) : `DELETE /notifications/{id}` et `DELETE /notifications` s'ajoutent à liste/compteur/lu/tout-lu. Nécessaire pour que les actions déjà présentes dans l'UI existante (glisser-pour-supprimer côté client, "Effacer toutes les notifications" côté marchand) restent correctes une fois les données réelles branchées — sans ça, une notification supprimée localement réapparaîtrait au prochain rechargement.

## Global Constraints

- Les 3 tables de logs de livraison existantes (`notification_logs`, `notification_campaigns`, `reward_notification_logs`) ne sont ni modifiées ni migrées.
- Aucun backfill : la table `notifications` démarre vide.
- Un seul `NotificationController`/service de politique, réutilisé par les deux apps (pas de duplication de code entre client et marchand).
- `notification_logs.client_id` a une contrainte `FOREIGN KEY → clients` NOT NULL : ne jamais y écrire un id de `Restaurant`.
- Types de politique (`NotificationDispatcher::PUSH_ENABLED_TYPES`) :

| `type` | push | in-app |
|---|---|---|
| `reward_unlocked` | oui | oui |
| `referral_pending` | oui | oui |
| `referral_validated` | oui | oui |
| `birthday` | oui | oui |
| `campaign` | oui | oui |
| `admin_broadcast` | oui | oui |
| `merchant_new_client` | non | oui |
| `merchant_low_sms` | non | oui |
| `merchant_weekly_report` | non | oui |

---

## Backend (`restaurant-loyalty-api`)

### Task 1: Table et modèle `Notification`

**Files:**
- Create: `database/migrations/2026_08_29_190000_create_notifications_table.php`
- Create: `app/Models/Notification.php`
- Test: `tests/Feature/NotificationModelTest.php`

**Interfaces:**
- Produces: `App\Models\Notification` avec colonnes `notifiable_type`/`notifiable_id` (morph), `type` (string), `title` (string), `body` (text), `data` (array, cast json), `read_at` (datetime nullable), scope `unread()`.

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Feature;

use App\Models\Client;
use App\Models\Notification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class NotificationModelTest extends TestCase
{
    use RefreshDatabase;

    public function test_notification_belongs_to_a_polymorphic_recipient_and_casts_data(): void
    {
        $client = Client::create([
            'uuid' => (string) Str::uuid(),
            'first_name' => 'Ada',
            'phone' => '+22890000101',
            'password' => bcrypt('secret123'),
        ]);

        $notification = Notification::create([
            'notifiable_type' => $client->getMorphClass(),
            'notifiable_id' => $client->id,
            'type' => 'reward_unlocked',
            'title' => 'Récompense débloquée 🎁',
            'body' => 'Récompense débloquée : Café offert',
            'data' => ['reward_id' => 42],
        ]);

        $this->assertTrue($notification->notifiable->is($client));
        $this->assertSame(42, $notification->data['reward_id']);
        $this->assertNull($notification->read_at);
        $this->assertSame(1, Notification::unread()->count());

        $notification->update(['read_at' => now()]);
        $this->assertSame(0, Notification::unread()->count());
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test --filter=NotificationModelTest`
Expected: FAIL — table `notifications` doesn't exist / class `App\Models\Notification` not found.

- [ ] **Step 3: Write the migration**

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->morphs('notifiable');
            $table->string('type');
            $table->string('title');
            $table->text('body');
            $table->json('data')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            $table->index(['notifiable_type', 'notifiable_id', 'read_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
```

- [ ] **Step 4: Write the model**

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    protected $guarded = [];

    protected $casts = [
        'data' => 'array',
        'read_at' => 'datetime',
    ];

    public function notifiable()
    {
        return $this->morphTo();
    }

    public function scopeUnread(Builder $query): Builder
    {
        return $query->whereNull('read_at');
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `php artisan test --filter=NotificationModelTest`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add database/migrations/2026_08_29_190000_create_notifications_table.php app/Models/Notification.php tests/Feature/NotificationModelTest.php
git commit -m "feat: table et modèle Notification (centre de notifications unifié)"
```

---

### Task 2: `NotificationDispatcher::send()` — point de passage unique

**Files:**
- Modify: `app/Services/NotificationDispatcher.php`
- Test: `tests/Feature/NotificationDispatcherTest.php`

**Interfaces:**
- Consumes: `App\Models\Notification` (Task 1), `App\Services\Fcm\FcmService::sendToToken(string $token, array $notification, array $data, ?int $userId, string $type): bool` (existant, inchangé).
- Produces: `NotificationDispatcher::send(\Illuminate\Database\Eloquent\Model $recipient, string $type, string $title, string $body, array $data = []): Notification` — crée toujours la ligne in-app, envoie un push FCM à chaque `deviceTokens` du destinataire si `$type` est activé pour le push. `NotificationDispatcher::recordOnly(...)` (même signature) — crée la ligne in-app sans jamais pousser, pour les appelants qui gèrent déjà eux-mêmes leur propre envoi push (Task 5).

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Feature;

use App\Models\Client;
use App\Models\Notification;
use App\Models\Restaurant;
use App\Services\Fcm\FcmService;
use App\Services\NotificationDispatcher;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class NotificationDispatcherTest extends TestCase
{
    use RefreshDatabase;

    public function test_send_creates_in_app_row_and_pushes_when_type_allows_push(): void
    {
        $client = Client::create([
            'uuid' => (string) Str::uuid(),
            'first_name' => 'Ada',
            'phone' => '+22890000102',
            'password' => bcrypt('secret123'),
        ]);
        $client->deviceTokens()->create(['token' => 'tok-client-1', 'platform' => 'android']);

        $this->mock(FcmService::class, function ($mock) use ($client) {
            $mock->shouldReceive('sendToToken')
                ->once()
                ->with(
                    'tok-client-1',
                    ['title' => 'Récompense débloquée 🎁', 'body' => 'Café offert'],
                    ['type' => 'reward_unlocked', 'reward_id' => 42],
                    $client->id,
                    'reward_unlocked'
                )
                ->andReturn(true);
        });

        $notification = app(NotificationDispatcher::class)->send(
            $client,
            'reward_unlocked',
            'Récompense débloquée 🎁',
            'Café offert',
            ['reward_id' => 42],
        );

        $this->assertDatabaseHas('notifications', [
            'id' => $notification->id,
            'notifiable_type' => $client->getMorphClass(),
            'notifiable_id' => $client->id,
            'type' => 'reward_unlocked',
            'title' => 'Récompense débloquée 🎁',
        ]);
    }

    public function test_send_records_in_app_only_and_skips_push_for_types_without_push(): void
    {
        $restaurant = Restaurant::create([
            'name' => 'Chez Awa',
            'category' => 'Restaurant',
            'email' => 'commerce-dispatcher@example.com',
            'password' => bcrypt('password123'),
        ]);
        $restaurant->deviceTokens()->create(['token' => 'tok-restaurant-1', 'platform' => 'android']);

        $this->mock(FcmService::class, function ($mock) {
            $mock->shouldNotReceive('sendToToken');
        });

        app(NotificationDispatcher::class)->send(
            $restaurant,
            'merchant_new_client',
            'Nouveau client 👋',
            'Ada a rejoint votre programme de fidélité.',
        );

        $this->assertDatabaseHas('notifications', [
            'notifiable_type' => $restaurant->getMorphClass(),
            'notifiable_id' => $restaurant->id,
            'type' => 'merchant_new_client',
        ]);
    }

    public function test_record_only_never_pushes_even_for_a_push_enabled_type(): void
    {
        $client = Client::create([
            'uuid' => (string) Str::uuid(),
            'first_name' => 'Bo',
            'phone' => '+22890000103',
            'password' => bcrypt('secret123'),
        ]);
        $client->deviceTokens()->create(['token' => 'tok-client-2', 'platform' => 'ios']);

        $this->mock(FcmService::class, function ($mock) {
            $mock->shouldNotReceive('sendToToken');
        });

        app(NotificationDispatcher::class)->recordOnly(
            $client,
            'campaign',
            'Campagne',
            'Message',
        );

        $this->assertSame(1, Notification::where('type', 'campaign')->count());
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test --filter=NotificationDispatcherTest`
Expected: FAIL — `send()`/`recordOnly()` don't exist on `NotificationDispatcher`.

- [ ] **Step 3: Implement `send()`/`recordOnly()`**

Remplace le contenu de `app/Services/NotificationDispatcher.php` par :

```php
<?php

namespace App\Services;

use App\Events\RewardUnlocked;
use App\Models\Client;
use App\Models\Notification;
use App\Models\Reward;
use App\Models\RewardNotificationLog;
use App\Jobs\SendRewardFcmFallback;
use App\Services\Fcm\FcmService;
use Illuminate\Database\Eloquent\Model;

class NotificationDispatcher
{
    /**
     * Politique fixe par type d'événement — voir
     * `docs/superpowers/specs/2026-08-29-notifications-unifiees-design.md`.
     * `true` : push FCM + ligne in-app. `false` : ligne in-app seule.
     */
    private const PUSH_ENABLED_TYPES = [
        'reward_unlocked' => true,
        'referral_pending' => true,
        'referral_validated' => true,
        'birthday' => true,
        'campaign' => true,
        'admin_broadcast' => true,
        'merchant_new_client' => false,
        'merchant_low_sms' => false,
        'merchant_weekly_report' => false,
    ];

    public function __construct(
        protected PresenceChecker $presenceChecker,
        protected FcmService $fcm,
    ) {
    }

    public function dispatchRewardUnlocked(Reward $reward): void
    {
        // Étape 1 : diffusion immédiate via Reverb, qu'il y ait
        // quelqu'un en écoute ou pas (ça ne coûte rien)
        event(new RewardUnlocked($reward));

        RewardNotificationLog::create([
            'reward_id' => $reward->id,
            'channel' => 'reverb',
            'status' => 'sent',
        ]);

        // Étape 2 : ajustement du délai de fallback selon la présence
        // détectée à cet instant précis. Ce n'est qu'une optimisation
        // de timing — l'ack reste la seule vraie preuve de réception.
        $isOnline = $this->presenceChecker->isCustomerOnline($reward->customer_id);
        $fallbackDelay = $isOnline ? 6 : 1;

        SendRewardFcmFallback::dispatch($reward->id)
            ->delay(now()->addSeconds($fallbackDelay));
    }

    /**
     * Point de passage unique pour toute notification utilisateur : crée
     * toujours la ligne in-app, et pousse un FCM à chaque appareil du
     * destinataire si la politique du type l'autorise (voir
     * `PUSH_ENABLED_TYPES`).
     */
    public function send(Model $recipient, string $type, string $title, string $body, array $data = []): Notification
    {
        $notification = $this->recordOnly($recipient, $type, $title, $body, $data);

        if (self::PUSH_ENABLED_TYPES[$type] ?? false) {
            $this->pushToRecipient($recipient, $type, $title, $body, $data);
        }

        return $notification;
    }

    /**
     * Crée uniquement la ligne in-app, sans jamais pousser — pour les
     * appelants qui gèrent déjà leur propre envoi push (ex. les campagnes
     * marchand, qui journalisent aussi dans `notification_logs`).
     */
    public function recordOnly(Model $recipient, string $type, string $title, string $body, array $data = []): Notification
    {
        return Notification::create([
            'notifiable_type' => $recipient->getMorphClass(),
            'notifiable_id' => $recipient->getKey(),
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'data' => $data,
        ]);
    }

    private function pushToRecipient(Model $recipient, string $type, string $title, string $body, array $data): void
    {
        foreach ($recipient->deviceTokens as $deviceToken) {
            $this->fcm->sendToToken(
                $deviceToken->token,
                ['title' => $title, 'body' => $body],
                array_merge(['type' => $type], $data),
                $recipient instanceof Client ? $recipient->id : null,
                $type,
            );
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test --filter=NotificationDispatcherTest`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/Services/NotificationDispatcher.php tests/Feature/NotificationDispatcherTest.php
git commit -m "feat: NotificationDispatcher::send() unifie push et notification in-app"
```

---

### Task 3: Parrainage — passe par le dispatcher

**Files:**
- Modify: `app/Services/Referral/ReferralService.php`
- Modify: `tests/Feature/ReferralTest.php:262-307` (`test_referrer_is_notified_when_referred_joins_and_again_when_validated`)

**Interfaces:**
- Consumes: `NotificationDispatcher::send()` (Task 2).

- [ ] **Step 1: Modify `ReferralService` to use the dispatcher**

Dans `app/Services/Referral/ReferralService.php` :

Remplace l'import :
```php
use App\Jobs\SendPromoNotification;
```
par :
```php
use App\Services\NotificationDispatcher;
```

Ajoute le constructeur (la classe n'en a pas aujourd'hui) juste après l'ouverture de la classe :
```php
    public function __construct(private readonly NotificationDispatcher $notifications)
    {
    }
```

Remplace les trois méthodes `notifyPending`/`notifyValidated`/`notifyClient` (lignes 115-150 du fichier actuel) par :

```php
    private function notifyPending(Referral $referral): void
    {
        $referrer = $referral->referrerClient()->first();
        if (! $referrer) {
            return;
        }

        $referredName = $referral->referredClient()->first()?->first_name ?? 'Un ami';

        $this->notifications->send(
            $referrer,
            'referral_pending',
            'Parrainage en cours 👀',
            "{$referredName} a rejoint grâce à votre parrainage — votre récompense arrive dès sa première visite !",
        );
    }

    private function notifyValidated(Referral $referral): void
    {
        $referrer = $referral->referrerClient()->first();
        if (! $referrer) {
            return;
        }

        $referredName = $referral->referredClient()->first()?->first_name ?? 'Un ami';

        $this->notifications->send(
            $referrer,
            'referral_validated',
            'Parrainage validé 🎉',
            "{$referredName} a rejoint le programme grâce à vous — votre récompense est débloquée !",
        );
    }
```

(La méthode `notifyClient` disparaît — son seul rôle, la boucle sur `deviceTokens`, vit maintenant dans `NotificationDispatcher`.)

- [ ] **Step 2: Rewrite the now-outdated assertion in `ReferralTest`**

`ReferralTest::test_referrer_is_notified_when_referred_joins_and_again_when_validated` (lignes 262-307) asserte aujourd'hui `Bus::assertDispatchedTimes(SendPromoNotification::class, ...)` — ce job n'est plus utilisé sur ce chemin. Remplace le corps du test par :

```php
    public function test_referrer_is_notified_when_referred_joins_and_again_when_validated(): void
    {
        [$restaurant, $program] = $this->restaurantWithProgram();
        [$parrain] = $this->clientWithToken('+22890000017');
        $parrainCard = $this->cardFor($parrain, $restaurant, $program);
        $parrain->deviceTokens()->create(['token' => 'device-token-parrain', 'platform' => 'android']);

        $this->mock(\App\Services\Fcm\FcmService::class, function ($mock) {
            $mock->shouldReceive('sendToToken')->twice()->andReturn(true);
        });

        [, $filleulToken] = $this->clientWithToken('+22890000018');
        $this->withHeader('Authorization', "Bearer {$filleulToken}")
            ->postJson('/api/loyalty-cards/join', [
                'qr_token' => ReferralService::QR_PREFIX.$parrainCard->referral_qr_token,
            ])->assertCreated();

        // Le simple scan/join notifie déjà A, une seule fois, sans mention de récompense.
        $this->assertDatabaseHas('notifications', [
            'notifiable_type' => $parrain->getMorphClass(),
            'notifiable_id' => $parrain->id,
            'type' => 'referral_pending',
        ]);
        $this->assertSame(1, \App\Models\Notification::where('type', 'referral_pending')->count());

        $filleulCard = LoyaltyCard::where('restaurant_id', $restaurant->id)
            ->where('id', '!=', $parrainCard->id)
            ->first();

        $this->app['auth']->forgetGuards();
        $merchantToken = $restaurant->createToken('merchant-app')->plainTextToken;
        $this->withHeader('Authorization', "Bearer {$merchantToken}")
            ->postJson("/api/merchant/clients/{$filleulCard->id}/stamps")
            ->assertOk();

        // Première opération : une deuxième ligne in-app, distincte, "validée".
        $this->assertDatabaseHas('notifications', [
            'notifiable_type' => $parrain->getMorphClass(),
            'notifiable_id' => $parrain->id,
            'type' => 'referral_validated',
        ]);

        // Une deuxième opération du filleul ne doit pas en redéclencher un troisième.
        $this->withHeader('Authorization', "Bearer {$merchantToken}")
            ->postJson("/api/merchant/clients/{$filleulCard->id}/stamps")
            ->assertOk();
        $this->assertSame(1, \App\Models\Notification::where('type', 'referral_validated')->count());
    }
```

Le mock `FcmService::shouldReceive('sendToToken')->twice()` remplace `Bus::fake()` (qui n'a plus rien à intercepter ici) — deux envois attendus : un pour `referral_pending`, un pour `referral_validated`. Supprime aussi l'import `use App\Jobs\SendPromoNotification;` et `use Illuminate\Support\Bus;`/`Bus::fake();` en haut du fichier s'ils ne sont plus utilisés ailleurs dans la classe (vérifie avec `grep -n "Bus::\|SendPromoNotification" tests/Feature/ReferralTest.php` avant de les retirer).

- [ ] **Step 3: Run the referral test suite**

Run: `php artisan test --filter=ReferralTest`
Expected: PASS (10 tests)

- [ ] **Step 4: Commit**

```bash
git add app/Services/Referral/ReferralService.php tests/Feature/ReferralTest.php
git commit -m "refactor: parrainage route ses notifications via NotificationDispatcher"
```

---

### Task 4: Anniversaire — passe par le dispatcher

**Files:**
- Modify: `app/Console/Commands/SendBirthdayNotifications.php`
- Test: `tests/Feature/SendBirthdayNotificationsTest.php` (nouveau — aucun test existant ne couvrait cette commande)

**Interfaces:**
- Consumes: `NotificationDispatcher::send()` (Task 2).

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Feature;

use App\Models\Client;
use App\Models\LoyaltyCard;
use App\Models\LoyaltyProgram;
use App\Models\Notification;
use App\Models\Restaurant;
use App\Services\Fcm\FcmService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Str;
use Tests\TestCase;

class SendBirthdayNotificationsTest extends TestCase
{
    use RefreshDatabase;

    public function test_command_records_an_in_app_birthday_notification_and_pushes(): void
    {
        $restaurant = Restaurant::create([
            'name' => 'Chez Awa',
            'category' => 'Restaurant',
            'email' => 'commerce-birthday@example.com',
            'password' => bcrypt('password123'),
        ]);
        $program = LoyaltyProgram::create([
            'restaurant_id' => $restaurant->id,
            'name' => 'Programme',
            'type' => 'stamps',
            'config' => ['goal' => 10, 'birthday_reward' => ['enabled' => true]],
        ]);

        $client = Client::create([
            'uuid' => (string) Str::uuid(),
            'first_name' => 'Ada',
            'phone' => '+22890000104',
            'password' => bcrypt('secret123'),
            'birthdate' => now()->addDays(3)->format('Y-m-d'),
        ]);
        $client->deviceTokens()->create(['token' => 'tok-birthday', 'platform' => 'android']);

        LoyaltyCard::create([
            'client_id' => $client->id,
            'restaurant_id' => $restaurant->id,
            'loyalty_program_id' => $program->id,
        ]);

        $this->mock(FcmService::class, function ($mock) {
            $mock->shouldReceive('sendToToken')->once()->andReturn(true);
        });

        Artisan::call('notifications:birthdays');

        $this->assertDatabaseHas('notifications', [
            'notifiable_type' => $client->getMorphClass(),
            'notifiable_id' => $client->id,
            'type' => 'birthday',
        ]);
        $this->assertSame(1, Notification::where('type', 'birthday')->count());
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test --filter=SendBirthdayNotificationsTest`
Expected: FAIL — aucune ligne `notifications` créée (la commande envoie encore via `SendPromoNotification`).

- [ ] **Step 3: Modify the command**

Dans `app/Console/Commands/SendBirthdayNotifications.php`, remplace l'import :
```php
use App\Jobs\SendPromoNotification;
```
par :
```php
use App\Services\NotificationDispatcher;
```

Remplace la signature de `handle()` :
```php
    public function handle(): void
```
par :
```php
    public function handle(NotificationDispatcher $notifications): void
```

Remplace le bloc (lignes 96-102 du fichier actuel) :
```php
                foreach ($client->deviceTokens as $deviceToken) {
                    SendPromoNotification::dispatch($client->id, $deviceToken->token, [
                        'title' => 'Joyeux anniversaire 🎂',
                        'body' => $notificationBody,
                    ]);
                    $notificationsSent++;
                }
```
par :
```php
                $notifications->send($client, 'birthday', 'Joyeux anniversaire 🎂', $notificationBody);
                $notificationsSent++;
```

(Le décompte `$notificationsSent` passe d'un compte par appareil à un compte par carte notifiée — le message de résumé de la commande reste correct, juste une granularité différente.)

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test --filter=SendBirthdayNotificationsTest`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/Console/Commands/SendBirthdayNotifications.php tests/Feature/SendBirthdayNotificationsTest.php
git commit -m "refactor: notification anniversaire route via NotificationDispatcher"
```

---

### Task 5: Campagne marchand — ajoute la ligne in-app

**Files:**
- Modify: `app/Jobs/SendCampaignNotification.php`
- Test: `tests/Feature/SendCampaignNotificationTest.php` (nouveau)

**Interfaces:**
- Consumes: `NotificationDispatcher::recordOnly()` (Task 2) — le push et son log restent gérés directement par ce job (déjà plus riche que le dispatcher générique : `notification_campaign_id`/`restaurant_id`/`failure_reason`), seule la ligne in-app est nouvelle.

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Feature;

use App\Jobs\SendCampaignNotification;
use App\Models\Client;
use App\Models\Notification;
use App\Models\NotificationCampaign;
use App\Models\Restaurant;
use App\Services\Fcm\FcmService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class SendCampaignNotificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_job_records_an_in_app_notification_in_addition_to_the_existing_push_and_log(): void
    {
        $restaurant = Restaurant::create([
            'name' => 'Chez Awa',
            'category' => 'Restaurant',
            'email' => 'commerce-campaign@example.com',
            'password' => bcrypt('password123'),
        ]);
        $client = Client::create([
            'uuid' => (string) Str::uuid(),
            'first_name' => 'Ada',
            'phone' => '+22890000105',
            'password' => bcrypt('secret123'),
        ]);
        $client->deviceTokens()->create(['token' => 'tok-campaign', 'platform' => 'android']);

        $campaign = NotificationCampaign::create([
            'restaurant_id' => $restaurant->id,
            'title' => 'Campagne SMS',
            'message' => 'Weekend -20% !',
            'target' => ['recipient_type' => 'all'],
            'status' => 'sent',
        ]);

        $this->mock(FcmService::class, function ($mock) {
            $mock->shouldReceive('sendToToken')->once()->andReturn(true);
        });

        (new SendCampaignNotification($campaign->id, $client->id))->handle(app(FcmService::class), app(\App\Services\NotificationDispatcher::class));

        $this->assertDatabaseHas('notifications', [
            'notifiable_type' => $client->getMorphClass(),
            'notifiable_id' => $client->id,
            'type' => 'campaign',
            'title' => 'Campagne SMS',
            'body' => 'Weekend -20% !',
        ]);
        $this->assertDatabaseHas('notification_logs', [
            'notification_campaign_id' => $campaign->id,
            'client_id' => $client->id,
            'status' => 'sent',
        ]);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test --filter=SendCampaignNotificationTest`
Expected: FAIL — `handle()` ne prend pas de deuxième argument, aucune ligne `notifications`.

- [ ] **Step 3: Modify the job**

Dans `app/Jobs/SendCampaignNotification.php`, ajoute l'import :
```php
use App\Services\NotificationDispatcher;
```

Remplace la signature :
```php
    public function handle(FcmService $fcm): void
```
par :
```php
    public function handle(FcmService $fcm, NotificationDispatcher $notifications): void
```

Juste après le `if (! $campaign || ! $client) { return; }` (avant la vérification `deviceTokens->isEmpty()`), ajoute :
```php
        $notifications->recordOnly(
            $client,
            'campaign',
            $campaign->title,
            $campaign->message,
            ['campaign_id' => $campaign->id],
        );
```

(Placé avant la vérification des `deviceTokens` : la ligne in-app existe même si le client n'a aucun appareil enregistré — il la verra à la prochaine ouverture de l'app.)

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test --filter=SendCampaignNotificationTest`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/Jobs/SendCampaignNotification.php tests/Feature/SendCampaignNotificationTest.php
git commit -m "feat: campagne marchand crée aussi une notification in-app"
```

---

### Task 6: Broadcast admin — corrige la requête morte et route via le dispatcher

**Files:**
- Modify: `app/Console/Commands/SendGlobalNotification.php`
- Test: `tests/Feature/SendGlobalNotificationTest.php` (nouveau)

**Interfaces:**
- Consumes: `NotificationDispatcher::send()` (Task 2).

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Feature;

use App\Models\Client;
use App\Models\Notification;
use App\Models\Restaurant;
use App\Services\Fcm\FcmService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Str;
use Tests\TestCase;

class SendGlobalNotificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_broadcasts_to_clients_and_restaurants_with_device_tokens(): void
    {
        $client = Client::create([
            'uuid' => (string) Str::uuid(),
            'first_name' => 'Ada',
            'phone' => '+22890000106',
            'password' => bcrypt('secret123'),
        ]);
        $client->deviceTokens()->create(['token' => 'tok-client-broadcast', 'platform' => 'android']);

        $restaurant = Restaurant::create([
            'name' => 'Chez Awa',
            'category' => 'Restaurant',
            'email' => 'commerce-broadcast@example.com',
            'password' => bcrypt('password123'),
        ]);
        $restaurant->deviceTokens()->create(['token' => 'tok-restaurant-broadcast', 'platform' => 'android']);

        $this->mock(FcmService::class, function ($mock) {
            $mock->shouldReceive('sendToToken')->twice()->andReturn(true);
        });

        Artisan::call('notifications:send-all', ['title' => 'Annonce', 'body' => 'Nouveau !', '--delay' => 0]);

        $this->assertSame(1, Notification::where('notifiable_type', $client->getMorphClass())
            ->where('notifiable_id', $client->id)->where('type', 'admin_broadcast')->count());
        $this->assertSame(1, Notification::where('notifiable_type', $restaurant->getMorphClass())
            ->where('notifiable_id', $restaurant->id)->where('type', 'admin_broadcast')->count());
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test --filter=SendGlobalNotificationTest`
Expected: FAIL — la commande interroge `App\Models\User` (table vide), aucune notification créée.

- [ ] **Step 3: Rewrite the command**

Remplace le contenu de `app/Console/Commands/SendGlobalNotification.php` par :

```php
<?php

namespace App\Console\Commands;

use App\Models\Client;
use App\Models\Restaurant;
use App\Services\NotificationDispatcher;
use Illuminate\Console\Command;

class SendGlobalNotification extends Command
{
    protected $signature = 'notifications:send-all {title?} {body?} {--delay=5 : Délai en minutes avant l\'envoi}';

    protected $description = 'Envoie une notification à tous les clients et marchands avec un délai (par défaut 5 minutes)';

    public function handle(NotificationDispatcher $notifications): void
    {
        $title = $this->argument('title') ?? 'Annonce Spéciale 🚀';
        $body = $this->argument('body') ?? 'Découvrez nos nouveautés dès maintenant !';
        $delay = (int) $this->option('delay');

        $recipients = Client::with('deviceTokens')->get()
            ->concat(Restaurant::with('deviceTokens')->get());

        $count = 0;

        foreach ($recipients as $recipient) {
            if ($delay > 0) {
                dispatch(function () use ($notifications, $recipient, $title, $body) {
                    $notifications->send($recipient, 'admin_broadcast', $title, $body);
                })->delay(now()->addMinutes($delay));
            } else {
                $notifications->send($recipient, 'admin_broadcast', $title, $body);
            }
            $count++;
        }

        $this->info("Notification prévue pour {$count} destinataire(s) dans {$delay} minute(s).");
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test --filter=SendGlobalNotificationTest`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/Console/Commands/SendGlobalNotification.php tests/Feature/SendGlobalNotificationTest.php
git commit -m "fix: broadcast admin ciblait App\\Models\\User (jamais peuplé), cible Client+Restaurant via NotificationDispatcher"
```

---

### Task 7: Récompense débloquée — notifie enfin le client réel

**Files:**
- Modify: `app/Http/Controllers/Api/MerchantDashboardController.php:30` (constructeur), `:517-520` (`grantCashback`), `:938-941` (`grantStampOrPoints`)
- Test: `tests/Feature/RewardUnlockedNotificationTest.php` (nouveau)

**Interfaces:**
- Consumes: `NotificationDispatcher::send()` (Task 2).

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Feature;

use App\Models\Client;
use App\Models\LoyaltyCard;
use App\Models\LoyaltyProgram;
use App\Models\Notification;
use App\Models\Restaurant;
use App\Services\Fcm\FcmService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class RewardUnlockedNotificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_client_is_notified_when_a_stamp_operation_unlocks_a_reward(): void
    {
        $restaurant = Restaurant::create([
            'name' => 'Chez Awa',
            'category' => 'Restaurant',
            'email' => 'commerce-reward@example.com',
            'password' => bcrypt('password123'),
        ]);
        $program = LoyaltyProgram::create([
            'restaurant_id' => $restaurant->id,
            'name' => 'Programme',
            'type' => 'stamps',
            'config' => ['goal' => 1, 'reward_description' => 'Café offert'],
        ]);

        $client = Client::create([
            'uuid' => (string) Str::uuid(),
            'first_name' => 'Ada',
            'phone' => '+22890000107',
            'password' => bcrypt('secret123'),
        ]);
        $client->deviceTokens()->create(['token' => 'tok-reward', 'platform' => 'android']);
        $card = LoyaltyCard::create([
            'client_id' => $client->id,
            'restaurant_id' => $restaurant->id,
            'loyalty_program_id' => $program->id,
        ]);

        $this->mock(FcmService::class, function ($mock) {
            $mock->shouldReceive('sendToToken')->once()->andReturn(true);
        });

        $merchantToken = $restaurant->createToken('merchant-app')->plainTextToken;
        $this->withHeader('Authorization', "Bearer {$merchantToken}")
            ->postJson("/api/merchant/clients/{$card->id}/stamps")
            ->assertOk();

        $this->assertDatabaseHas('notifications', [
            'notifiable_type' => $client->getMorphClass(),
            'notifiable_id' => $client->id,
            'type' => 'reward_unlocked',
            'title' => 'Récompense débloquée 🎁',
            'body' => 'Récompense débloquée : Café offert',
        ]);
        $this->assertSame(1, Notification::where('type', 'reward_unlocked')->count());
    }
}
```

Pas de ligne `LoyaltyProgramTier` à créer : `LoyaltyTierService::tiers()` (`app/Services/Loyalty/LoyaltyTierService.php`) synthétise automatiquement un palier unique depuis `config['goal']`/`config['reward_description']` quand aucune ligne n'existe dans `loyalty_program_tiers` — c'est ce chemin de repli que ce test exerce.

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test --filter=RewardUnlockedNotificationTest`
Expected: FAIL — aucune ligne `notifications` créée.

- [ ] **Step 3: Inject the dispatcher and record the notification at both unlock sites**

Dans `app/Http/Controllers/Api/MerchantDashboardController.php`, remplace le constructeur (ligne 30) :
```php
    public function __construct(private readonly ReferralService $referralService)
```
par :
```php
    public function __construct(
        private readonly ReferralService $referralService,
        private readonly \App\Services\NotificationDispatcher $notifications,
    )
```

Dans `grantCashback()`, remplace le bloc (lignes 517-520 du fichier actuel) :
```php
        foreach (LoyaltyReward::whereIn('id', $createdRewardIds)->get() as $reward) {
            $reward->setRelation('loyaltyCard', $freshCard);
            LoyaltyRewardUpdated::dispatch($reward);
        }
```
par :
```php
        foreach (LoyaltyReward::whereIn('id', $createdRewardIds)->get() as $reward) {
            $reward->setRelation('loyaltyCard', $freshCard);
            LoyaltyRewardUpdated::dispatch($reward);
            $this->notifications->send(
                $freshCard->client,
                'reward_unlocked',
                'Récompense débloquée 🎁',
                "Récompense débloquée : {$reward->title}",
                ['reward_id' => $reward->id],
            );
        }
```

Dans `grantStampOrPoints()`, applique le même changement au bloc identique (lignes 938-941 du fichier actuel).

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test --filter=RewardUnlockedNotificationTest`
Expected: PASS

- [ ] **Step 5: Run the full merchant dashboard test suite to catch constructor-signature regressions**

Run: `php artisan test --filter=MerchantDashboard`
Expected: PASS — si un test instancie `MerchantDashboardController` directement (plutôt que via une requête HTTP passant par le container), adapte-le pour fournir le nouvel argument.

- [ ] **Step 6: Commit**

```bash
git add app/Http/Controllers/Api/MerchantDashboardController.php tests/Feature/RewardUnlockedNotificationTest.php
git commit -m "feat: notifie le client (push+in-app) quand une récompense se débloque réellement"
```

---

### Task 8: Nouveau client marchand — notification in-app

**Files:**
- Modify: `app/Http/Controllers/Api/LoyaltyCardController.php:16-18` (constructeur), méthode `join()`, méthode `joinViaReferral()`
- Test: `tests/Feature/MerchantNewClientNotificationTest.php` (nouveau)

**Interfaces:**
- Consumes: `NotificationDispatcher::send()` (Task 2).

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Feature;

use App\Models\Notification;
use App\Models\LoyaltyProgram;
use App\Models\Restaurant;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class MerchantNewClientNotificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_restaurant_gets_an_in_app_notification_when_a_new_card_is_created(): void
    {
        $restaurant = Restaurant::create([
            'name' => 'Chez Awa',
            'category' => 'Restaurant',
            'email' => 'commerce-newclient@example.com',
            'password' => bcrypt('password123'),
        ]);
        LoyaltyProgram::create([
            'restaurant_id' => $restaurant->id,
            'name' => 'Programme',
            'type' => 'stamps',
            'config' => ['goal' => 10],
        ]);

        $client = \App\Models\Client::create([
            'uuid' => (string) Str::uuid(),
            'first_name' => 'Ada',
            'phone' => '+22890000108',
            'password' => bcrypt('secret123'),
        ]);
        $token = $client->createToken('mobile-app')->plainTextToken;

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/loyalty-cards/join', ['qr_token' => $restaurant->qr_token])
            ->assertCreated();

        $this->assertDatabaseHas('notifications', [
            'notifiable_type' => $restaurant->getMorphClass(),
            'notifiable_id' => $restaurant->id,
            'type' => 'merchant_new_client',
        ]);
    }

    public function test_no_notification_when_the_client_was_already_a_member(): void
    {
        $restaurant = Restaurant::create([
            'name' => 'Chez Awa',
            'category' => 'Restaurant',
            'email' => 'commerce-newclient2@example.com',
            'password' => bcrypt('password123'),
        ]);
        $program = LoyaltyProgram::create([
            'restaurant_id' => $restaurant->id,
            'name' => 'Programme',
            'type' => 'stamps',
            'config' => ['goal' => 10],
        ]);

        $client = \App\Models\Client::create([
            'uuid' => (string) Str::uuid(),
            'first_name' => 'Ada',
            'phone' => '+22890000109',
            'password' => bcrypt('secret123'),
        ]);
        \App\Models\LoyaltyCard::create([
            'client_id' => $client->id,
            'restaurant_id' => $restaurant->id,
            'loyalty_program_id' => $program->id,
        ]);
        $token = $client->createToken('mobile-app')->plainTextToken;

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/loyalty-cards/join', ['qr_token' => $restaurant->qr_token])
            ->assertCreated();

        $this->assertSame(0, Notification::where('type', 'merchant_new_client')->count());
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test --filter=MerchantNewClientNotificationTest`
Expected: FAIL — aucune ligne `notifications` créée.

- [ ] **Step 3: Inject the dispatcher and record on real creation only**

Dans `app/Http/Controllers/Api/LoyaltyCardController.php`, remplace le constructeur :
```php
    public function __construct(private readonly ReferralService $referralService)
    {
    }
```
par :
```php
    public function __construct(
        private readonly ReferralService $referralService,
        private readonly \App\Services\NotificationDispatcher $notifications,
    ) {
    }
```

Dans `join()`, juste après la ligne qui lit `$wasRecentlyCreated` (`$wasRecentlyCreated = $card->wasRecentlyCreated;`) et avant `$card->load([...]);`, ajoute :
```php
        if ($wasRecentlyCreated) {
            $this->notifications->send(
                $restaurant,
                'merchant_new_client',
                'Nouveau client 👋',
                "{$client->first_name} a rejoint votre programme de fidélité.",
            );
        }
```

Dans `joinViaReferral()`, juste après le bloc `$card = DB::transaction(...)` (qui ne s'exécute que pour une carte réellement nouvelle — les cas "déjà membre"/"auto-parrainage" sont déjà retournés plus haut) et avant `$card->load(['restaurant', 'loyaltyProgram']);`, ajoute :
```php
        $this->notifications->send(
            $restaurant,
            'merchant_new_client',
            'Nouveau client 👋',
            "{$client->first_name} a rejoint votre programme de fidélité.",
        );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test --filter=MerchantNewClientNotificationTest`
Expected: PASS

- [ ] **Step 5: Run the full loyalty-card and referral suites to catch constructor-signature regressions**

Run: `php artisan test --filter=LoyaltyCard`
Run: `php artisan test --filter=ReferralTest`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/Http/Controllers/Api/LoyaltyCardController.php tests/Feature/MerchantNewClientNotificationTest.php
git commit -m "feat: notifie le marchand (in-app) à l'arrivée d'un nouveau client"
```

---

### Task 9: API — liste, compteur, lu, tout-lu, suppression

**Files:**
- Create: `app/Http/Controllers/Api/NotificationController.php`
- Modify: `routes/api.php:4-16` (imports), `:89-109` (groupe marchand), `:199-201` (ancienne route à remplacer)
- Test: `tests/Feature/NotificationControllerTest.php`

**Interfaces:**
- Consumes: `App\Models\Notification` (Task 1).
- Produces: routes `GET|DELETE /api/notifications`, `GET /api/notifications/unread-count`, `POST /api/notifications/{notification}/read`, `POST /api/notifications/read-all`, `DELETE /api/notifications/{notification}` — et le même quatuor+deux sous `/api/merchant/notifications`.

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Feature;

use App\Models\Client;
use App\Models\Notification;
use App\Models\Restaurant;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class NotificationControllerTest extends TestCase
{
    use RefreshDatabase;

    private function clientWithToken(): array
    {
        $client = Client::create([
            'uuid' => (string) Str::uuid(),
            'first_name' => 'Ada',
            'phone' => '+22890000110',
            'password' => bcrypt('secret123'),
        ]);

        return [$client, $client->createToken('mobile-app')->plainTextToken];
    }

    private function notificationFor($recipient, string $type = 'reward_unlocked'): Notification
    {
        return Notification::create([
            'notifiable_type' => $recipient->getMorphClass(),
            'notifiable_id' => $recipient->id,
            'type' => $type,
            'title' => 'Titre',
            'body' => 'Corps',
        ]);
    }

    public function test_client_lists_only_their_own_notifications(): void
    {
        [$client, $token] = $this->clientWithToken();
        [$other] = $this->clientWithToken();
        $this->notificationFor($client);
        $this->notificationFor($other);

        $response = $this->withHeader('Authorization', "Bearer {$token}")->getJson('/api/notifications');

        $response->assertOk();
        $response->assertJsonCount(1, 'data');
    }

    public function test_unread_count(): void
    {
        [$client, $token] = $this->clientWithToken();
        $this->notificationFor($client);
        $this->notificationFor($client)->update(['read_at' => now()]);

        $response = $this->withHeader('Authorization', "Bearer {$token}")->getJson('/api/notifications/unread-count');

        $response->assertOk();
        $response->assertJsonPath('unread_count', 1);
    }

    public function test_mark_read_rejects_another_users_notification(): void
    {
        [$client, $token] = $this->clientWithToken();
        [$other] = $this->clientWithToken();
        $notification = $this->notificationFor($other);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/notifications/{$notification->id}/read")
            ->assertNotFound();

        $this->assertNull($notification->fresh()->read_at);
    }

    public function test_mark_read_and_mark_all_read(): void
    {
        [$client, $token] = $this->clientWithToken();
        $a = $this->notificationFor($client);
        $b = $this->notificationFor($client);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/notifications/{$a->id}/read")
            ->assertOk();
        $this->assertNotNull($a->fresh()->read_at);
        $this->assertNull($b->fresh()->read_at);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/notifications/read-all')
            ->assertOk();
        $this->assertNotNull($b->fresh()->read_at);
    }

    public function test_delete_and_delete_all(): void
    {
        [$client, $token] = $this->clientWithToken();
        $a = $this->notificationFor($client);
        $b = $this->notificationFor($client);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->deleteJson("/api/notifications/{$a->id}")
            ->assertOk();
        $this->assertDatabaseMissing('notifications', ['id' => $a->id]);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->deleteJson('/api/notifications')
            ->assertOk();
        $this->assertDatabaseMissing('notifications', ['id' => $b->id]);
    }

    public function test_merchant_endpoints_use_the_same_controller_scoped_to_the_restaurant(): void
    {
        $restaurant = Restaurant::create([
            'name' => 'Chez Awa',
            'category' => 'Restaurant',
            'email' => 'commerce-notif-api@example.com',
            'password' => bcrypt('password123'),
        ]);
        $this->notificationFor($restaurant, 'merchant_new_client');
        $merchantToken = $restaurant->createToken('merchant-app')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$merchantToken}")
            ->getJson('/api/merchant/notifications');

        $response->assertOk();
        $response->assertJsonCount(1, 'data');
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test --filter=NotificationControllerTest`
Expected: FAIL — routes/contrôleur inexistants.

- [ ] **Step 3: Write the controller**

Create `app/Http/Controllers/Api/NotificationController.php` :

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * GET /api/notifications ou /api/merchant/notifications — `$request->user()`
     * résout déjà vers `Client` ou `Restaurant` selon le token, ce contrôleur
     * n'a donc besoin d'aucune branche par rôle.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json(
            Notification::where('notifiable_type', $user->getMorphClass())
                ->where('notifiable_id', $user->getKey())
                ->latest()
                ->paginate(20)
        );
    }

    public function unreadCount(Request $request): JsonResponse
    {
        $user = $request->user();

        $count = Notification::where('notifiable_type', $user->getMorphClass())
            ->where('notifiable_id', $user->getKey())
            ->unread()
            ->count();

        return response()->json(['unread_count' => $count]);
    }

    public function markRead(Request $request, Notification $notification): JsonResponse
    {
        $this->authorizeOwnership($request, $notification);

        $notification->update(['read_at' => $notification->read_at ?? now()]);

        return response()->json(['message' => 'Notification marquée comme lue.']);
    }

    public function markAllRead(Request $request): JsonResponse
    {
        $user = $request->user();

        Notification::where('notifiable_type', $user->getMorphClass())
            ->where('notifiable_id', $user->getKey())
            ->unread()
            ->update(['read_at' => now()]);

        return response()->json(['message' => 'Toutes les notifications ont été marquées comme lues.']);
    }

    public function destroy(Request $request, Notification $notification): JsonResponse
    {
        $this->authorizeOwnership($request, $notification);

        $notification->delete();

        return response()->json(['message' => 'Notification supprimée.']);
    }

    public function destroyAll(Request $request): JsonResponse
    {
        $user = $request->user();

        Notification::where('notifiable_type', $user->getMorphClass())
            ->where('notifiable_id', $user->getKey())
            ->delete();

        return response()->json(['message' => 'Toutes les notifications ont été supprimées.']);
    }

    private function authorizeOwnership(Request $request, Notification $notification): void
    {
        $user = $request->user();

        abort_if(
            $notification->notifiable_type !== $user->getMorphClass()
                || $notification->notifiable_id !== $user->getKey(),
            404
        );
    }
}
```

- [ ] **Step 4: Wire the routes**

Dans `routes/api.php`, ajoute l'import (ordre alphabétique, entre `MerchantDashboardController` et `ReferralController`) :
```php
use App\Http\Controllers\Api\NotificationController;
```

Remplace l'ancienne route (lignes 199-201 du fichier actuel) :
```php
Route::middleware('auth:sanctum')->get('/notifications', function (Request $request) {
    return $request->user()->notificationLogs()->latest()->paginate(20);
});
```
par :
```php
Route::middleware('auth:sanctum')->prefix('notifications')->group(function () {
    Route::get('/', [NotificationController::class, 'index']);
    Route::get('/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('/read-all', [NotificationController::class, 'markAllRead']);
    Route::post('/{notification}/read', [NotificationController::class, 'markRead']);
    Route::delete('/{notification}', [NotificationController::class, 'destroy']);
    Route::delete('/', [NotificationController::class, 'destroyAll']);
});
```

(`/read-all` et `/` doivent être déclarées avant `/{notification}/...` pour ne pas être avalées par le paramètre de route.)

Dans le groupe marchand (`routes/api.php:89-109`), ajoute juste avant la ligne `});` qui ferme le groupe (après `Route::get('/referrals', ...)`, ligne 108) :
```php
    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'index']);
        Route::get('/unread-count', [NotificationController::class, 'unreadCount']);
        Route::post('/read-all', [NotificationController::class, 'markAllRead']);
        Route::post('/{notification}/read', [NotificationController::class, 'markRead']);
        Route::delete('/{notification}', [NotificationController::class, 'destroy']);
        Route::delete('/', [NotificationController::class, 'destroyAll']);
    });
```

- [ ] **Step 5: Run test to verify it passes**

Run: `php artisan test --filter=NotificationControllerTest`
Expected: PASS

- [ ] **Step 6: Run the full backend suite**

Run: `php artisan test`
Expected: PASS — vérifie qu'aucune route/test existant n'a été cassé par le remplacement de l'ancienne route `/notifications`.

- [ ] **Step 7: Commit**

```bash
git add app/Http/Controllers/Api/NotificationController.php routes/api.php tests/Feature/NotificationControllerTest.php
git commit -m "feat: endpoints liste/compteur/lu/suppression du centre de notifications"
```

---

## Flutter (`Miva_Fid`)

### Task 10: Couche données partagée — `AppNotification`, service, repository

**Files:**
- Modify: `lib/features/client/models/app_notification.dart`
- Create: `lib/core/api/services/notification_service.dart`
- Create: `lib/core/api/repositories/notification_repository.dart`
- Modify: `lib/core/api/providers/api_providers.dart`
- Test: `test/core/api/repositories/notification_repository_test.dart`

**Interfaces:**
- Produces: `AppNotification` (id, type: String, title, message, timestamp, isRead — `restaurantName`/`kind`/`NotificationKind` supprimés), `AppNotification.fromApi(Map<String, dynamic>)`. `NotificationService(ApiClient apiClient, {String basePath = '/notifications'})` avec `list()`, `unreadCount()`, `markRead(String id)`, `markAllRead()`, `delete(String id)`, `deleteAll()`. `NotificationRepository(NotificationService)` avec les mêmes méthodes, parsant vers `AppNotification`. Providers `notificationServiceProvider`/`notificationRepositoryProvider` (client, `apiClientProvider`) et `merchantNotificationServiceProvider`/`merchantNotificationRepositoryProvider` (marchand, `merchantApiClientProvider`, `basePath: '/merchant/notifications'`).

- [ ] **Step 1: Rewrite `AppNotification`**

Remplace le contenu de `lib/features/client/models/app_notification.dart` par :

```dart
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromApi(Map<String, dynamic> json) => AppNotification(
        id: json['id'].toString(),
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['body'] as String,
        timestamp: DateTime.parse(json['created_at'] as String),
        isRead: json['read_at'] != null,
      );

  /// Horodatage relatif, ex. "il y a 2h".
  String get relativeTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
      );
}
```

- [ ] **Step 2: Write `NotificationService`**

Create `lib/core/api/services/notification_service.dart` :

```dart
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exceptions.dart';

/// Appels HTTP du centre de notifications (`/notifications/*` côté client,
/// `/merchant/notifications/*` côté marchand — même forme des deux côtés,
/// seul [basePath] change).
class NotificationService {
  final ApiClient _apiClient;
  final String _basePath;

  NotificationService(this._apiClient, {String basePath = '/notifications'})
      : _basePath = basePath;

  Never _throwFromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (status == 422 || status == 429) {
      throw ValidationException.fromResponse(data, statusCode: status);
    }
    if (status == 401) {
      throw UnauthorizedException(_backendMessage(data) ?? 'unauthorized');
    }
    if (status != null) {
      throw ServerException(
        _backendMessage(data) ?? e.message ?? 'server error',
        statusCode: status,
      );
    }
    throw NetworkException(e.message ?? 'network error');
  }

  String? _backendMessage(dynamic data) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return null;
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      _throwFromDio(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> list() => _guard(() async {
        final response = await _apiClient.dio.get(_basePath);
        return ((response.data as Map)['data'] as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
      });

  Future<void> markRead(String id) => _guard(() async {
        await _apiClient.dio.post('$_basePath/$id/read');
      });

  Future<void> markAllRead() => _guard(() async {
        await _apiClient.dio.post('$_basePath/read-all');
      });

  Future<void> delete(String id) => _guard(() async {
        await _apiClient.dio.delete('$_basePath/$id');
      });

  Future<void> deleteAll() => _guard(() async {
        await _apiClient.dio.delete(_basePath);
      });
}
```

- [ ] **Step 3: Write `NotificationRepository`**

Create `lib/core/api/repositories/notification_repository.dart` :

```dart
import '../services/notification_service.dart';
import '../../../features/client/models/app_notification.dart';

class NotificationRepository {
  final NotificationService _service;

  NotificationRepository(this._service);

  Future<List<AppNotification>> list() async {
    final rows = await _service.list();
    return rows.map(AppNotification.fromApi).toList();
  }

  Future<void> markRead(String id) => _service.markRead(id);
  Future<void> markAllRead() => _service.markAllRead();
  Future<void> delete(String id) => _service.delete(id);
  Future<void> deleteAll() => _service.deleteAll();
}
```

- [ ] **Step 4: Register the providers**

Dans `lib/core/api/providers/api_providers.dart`, ajoute les imports nécessaires en haut du fichier (à côté des imports `LoyaltyCardService`/`LoyaltyCardRepository` existants) puis, à la suite des providers `referralRepositoryProvider` en fin de fichier :

```dart
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationService(apiClient);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationRepository(service);
});

final merchantNotificationServiceProvider = Provider<NotificationService>((ref) {
  final apiClient = ref.watch(merchantApiClientProvider);
  return NotificationService(apiClient, basePath: '/merchant/notifications');
});

final merchantNotificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final service = ref.watch(merchantNotificationServiceProvider);
  return NotificationRepository(service);
});
```

- [ ] **Step 5: Write the failing repository test**

Create `test/core/api/repositories/notification_repository_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/api/core/api_client.dart';
import 'package:miva_fid/core/api/repositories/notification_repository.dart';
import 'package:miva_fid/core/api/services/notification_service.dart';
import 'package:miva_fid/core/api/storage/token_storage.dart';

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService(ApiClient apiClient) : super(apiClient);

  final List<String> markedRead = [];
  bool markedAllRead = false;
  final List<String> deleted = [];
  bool deletedAll = false;

  @override
  Future<List<Map<String, dynamic>>> list() async => [
        {
          'id': 1,
          'type': 'reward_unlocked',
          'title': 'Récompense débloquée 🎁',
          'body': 'Récompense débloquée : Café offert',
          'read_at': null,
          'created_at': '2026-08-29T10:00:00.000000Z',
        },
        {
          'id': 2,
          'type': 'referral_pending',
          'title': 'Parrainage en cours 👀',
          'body': 'Ada a rejoint grâce à votre parrainage.',
          'read_at': '2026-08-29T09:00:00.000000Z',
          'created_at': '2026-08-28T10:00:00.000000Z',
        },
      ];

  @override
  Future<void> markRead(String id) async => markedRead.add(id);

  @override
  Future<void> markAllRead() async => markedAllRead = true;

  @override
  Future<void> delete(String id) async => deleted.add(id);

  @override
  Future<void> deleteAll() async => deletedAll = true;
}

class _FakeTokenStorage implements TokenStorageBase {
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<String?> getToken() async => 'token';
  @override
  Future<void> deleteToken() async {}
}

void main() {
  group('NotificationRepository', () {
    test('list() parses API rows into AppNotification, preserving read state', () async {
      final apiClient = ApiClient(tokenStorage: _FakeTokenStorage());
      final repo = NotificationRepository(_FakeNotificationService(apiClient));

      final notifications = await repo.list();

      expect(notifications, hasLength(2));
      expect(notifications[0].id, '1');
      expect(notifications[0].type, 'reward_unlocked');
      expect(notifications[0].title, 'Récompense débloquée 🎁');
      expect(notifications[0].isRead, false);
      expect(notifications[1].isRead, true);
    });

    test('markRead/markAllRead/delete/deleteAll delegate to the service', () async {
      final apiClient = ApiClient(tokenStorage: _FakeTokenStorage());
      final service = _FakeNotificationService(apiClient);
      final repo = NotificationRepository(service);

      await repo.markRead('1');
      await repo.markAllRead();
      await repo.delete('2');
      await repo.deleteAll();

      expect(service.markedRead, ['1']);
      expect(service.markedAllRead, true);
      expect(service.deleted, ['2']);
      expect(service.deletedAll, true);
    });
  });
}
```

- [ ] **Step 6: Run the test**

Run: `flutter test test/core/api/repositories/notification_repository_test.dart`
Expected: PASS (aucune requête réseau réelle — `_FakeNotificationService` surcharge toutes les méthodes).

- [ ] **Step 7: Update the mock-data seed no longer used by notifications**

`lib/features/client/data/mock_data.dart` expose `MockData.notifications` (utilisé jusqu'ici par `NotificationsNotifier`, Task 11 le retire). Vérifie avec `grep -rn "MockData.notifications" lib/` qu'aucun autre appelant ne reste après le Task 11 ; si c'est le cas, retire le getter `notifications` de `MockData` dans ce fichier. Sinon, laisse-le (peut encore servir à d'autres écrans de démo).

- [ ] **Step 8: Commit**

```bash
git add lib/features/client/models/app_notification.dart lib/core/api/services/notification_service.dart lib/core/api/repositories/notification_repository.dart lib/core/api/providers/api_providers.dart test/core/api/repositories/notification_repository_test.dart
git commit -m "feat: couche données du centre de notifications (service+repository, client et marchand)"
```

---

### Task 11: App client — branchement réel

**Files:**
- Modify: `lib/features/client/providers/app_providers.dart:88-181` (bloc "Notifications")
- Modify: `lib/features/client/notifications/notifications_screen.dart`

**Interfaces:**
- Consumes: `notificationRepositoryProvider` (Task 10), `AppNotification` (Task 10).

- [ ] **Step 1: Replace `NotificationsNotifier` with a real-API-backed version**

Dans `lib/features/client/providers/app_providers.dart`, remplace tout le bloc "Notifications" (de `// Notifications` ligne ~90 jusqu'à la fermeture de `notificationsProvider` ligne ~161, qui inclut `NotificationsNotifier` et sa dérivation `rewardsProvider`) par :

```dart
// ─────────────────────────────────────────────────────────────────────────────
// Notifications
// ─────────────────────────────────────────────────────────────────────────────

/// Chargé depuis `GET /notifications` — les récompenses débloquées arrivent
/// maintenant par ce même flux serveur (voir `NotificationDispatcher::send`
/// côté backend, appelé au vrai déblocage), plus besoin de les synthétiser
/// depuis [rewardsProvider].
class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier(this._ref) : super(const []) {
    _ref.listen<AuthState>(authProvider, _onAuthChanged, fireImmediately: true);
  }

  final Ref _ref;

  void _onAuthChanged(AuthState? previous, AuthState next) {
    if (next.isAuthenticated && (previous == null || !previous.isAuthenticated)) {
      load();
    } else if (previous?.isAuthenticated == true && !next.isAuthenticated) {
      state = const [];
    }
  }

  Future<void> load() async {
    state = await _ref.read(notificationRepositoryProvider).list();
  }

  int get unreadCount => state.where((n) => !n.isRead).length;

  Future<void> markAllRead() async {
    await _ref.read(notificationRepositoryProvider).markAllRead();
    state = [for (final n in state) n.copyWith(isRead: true)];
  }

  Future<void> markRead(String id) async {
    await _ref.read(notificationRepositoryProvider).markRead(id);
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n
    ];
  }

  Future<void> remove(String id) async {
    await _ref.read(notificationRepositoryProvider).delete(id);
    state = state.where((n) => n.id != id).toList();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  (ref) => NotificationsNotifier(ref),
);
```

Ajoute l'import `import 'package:miva_fid/core/api/providers/api_providers.dart';` en haut du fichier s'il n'y est pas déjà (les providers `loyaltyCardRepositoryProvider` etc. y étant déjà utilisés dans ce fichier, l'import devrait déjà exister — vérifie avec `grep -n "api_providers.dart" lib/features/client/providers/app_providers.dart`).

- [ ] **Step 2: Update the icon mapping in the notifications screen**

Dans `lib/features/client/notifications/notifications_screen.dart`, remplace `_iconFor(NotificationKind k)` par :

```dart
  IconData _iconFor(String type) {
    switch (type) {
      case 'reward_unlocked':
        return LucideIcons.gift;
      case 'referral_pending':
      case 'referral_validated':
        return LucideIcons.users;
      case 'birthday':
        return LucideIcons.gift;
      case 'campaign':
      case 'admin_broadcast':
        return LucideIcons.megaphone;
      default:
        return LucideIcons.info;
    }
  }
```

Remplace l'appel `_iconFor(n.kind)` (dans `itemBuilder`) par `_iconFor(n.type)`, et l'affichage `Text(n.restaurantName, ...)` par `Text(n.title, ...)` (le champ `restaurantName` n'existe plus sur `AppNotification`, Task 10).

- [ ] **Step 3: Manual verification**

Pas d'infrastructure de test widget existante sur cet écran (cohérent avec le reste du projet — voir `docs/superpowers/specs/2026-08-29-notifications-unifiees-design.md`, section Tests). Lance l'app (skill `run`), connecte-toi avec un compte client, déclenche un événement notifiable (ex. `POST /api/simulate` avec `type: promo`, ou un vrai scan de parrainage comme dans la session précédente), vérifie que l'écran `/client/notifications` affiche la notification réelle, que "Tout lire" et le glissé-pour-supprimer persistent après un redémarrage de l'app (pull-to-refresh ou relance).

- [ ] **Step 4: Commit**

```bash
git add lib/features/client/providers/app_providers.dart lib/features/client/notifications/notifications_screen.dart
git commit -m "feat: écran notifications client branché sur l'API réelle"
```

---

### Task 12: App marchand — branchement réel

**Files:**
- Create: `lib/features/merchant/providers/notifications_provider.dart`
- Modify: `lib/features/merchant/screens/notifications_screen.dart`

**Interfaces:**
- Consumes: `merchantNotificationRepositoryProvider` (Task 10), `AppNotification` (Task 10).
- Produces: `merchantNotificationsProvider` (`AsyncNotifierProvider`, cohérent avec le style codegen déjà utilisé par les autres providers marchand — `SmsNotifier` dans `sms_provider.dart`), exposant `List<AppNotification>` + `markRead`/`markAllRead`/`delete`/`deleteAll`.

- [ ] **Step 1: Write the merchant notifications provider**

Create `lib/features/merchant/providers/notifications_provider.dart` :

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../client/models/app_notification.dart';
import 'merchant_auth_provider.dart';

part 'notifications_provider.g.dart';

/// Centre de notifications marchand (`/merchant/notifications`).
@riverpod
class MerchantNotificationsNotifier extends _$MerchantNotificationsNotifier {
  @override
  Future<List<AppNotification>> build() async {
    final restaurant = ref.watch(
      merchantAuthProvider.select((s) => s.restaurant),
    );
    if (restaurant == null) return [];

    return ref.read(merchantNotificationRepositoryProvider).list();
  }

  Future<void> markRead(String id) async {
    await ref.read(merchantNotificationRepositoryProvider).markRead(id);
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final n in current)
        if (n.id == id) n.copyWith(isRead: true) else n
    ]);
  }

  Future<void> markAllRead() async {
    await ref.read(merchantNotificationRepositoryProvider).markAllRead();
    final current = state.value;
    if (current == null) return;
    state = AsyncData([for (final n in current) n.copyWith(isRead: true)]);
  }

  Future<void> delete(String id) async {
    await ref.read(merchantNotificationRepositoryProvider).delete(id);
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.where((n) => n.id != id).toList());
  }

  Future<void> deleteAll() async {
    await ref.read(merchantNotificationRepositoryProvider).deleteAll();
    state = const AsyncData([]);
  }
}
```

- [ ] **Step 2: Generate the codegen file**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: crée `lib/features/merchant/providers/notifications_provider.g.dart` sans erreur (même commande que pour `sms_provider.g.dart`/`clients_provider.g.dart` existants).

- [ ] **Step 3: Wire the screen to real data**

Dans `lib/features/merchant/screens/notifications_screen.dart` :

1. Convertit `_NotificationsScreenState` pour lire `ref.watch(merchantNotificationsNotifierProvider)` (un `AsyncValue<List<AppNotification>>`) au lieu du champ local `_notifications` initialisé en dur dans `initState`. Supprime `initState`/le champ `late List<NotificationItem> _notifications` : la liste vient maintenant du provider à chaque `build()`.
2. Ajoute une fonction de mapping `AppNotification` → présentation (icône/couleurs/section), remplaçant les valeurs jusqu'ici codées en dur dans chaque `NotificationItem` :

```dart
  ({IconData icon, Color bg, Color color}) _visualFor(String type) {
    switch (type) {
      case 'merchant_new_client':
        return (icon: LucideIcons.userPlus, bg: const Color(0xFFEEF2FF), color: const Color(0xFF6366F1));
      case 'reward_unlocked':
        return (icon: LucideIcons.gift, bg: const Color(0xFFFEF3C7), color: const Color(0xFFD97706));
      case 'campaign':
        return (icon: LucideIcons.messageSquare, bg: const Color(0xFFE0F2FE), color: const Color(0xFF0284C7));
      case 'merchant_low_sms':
        return (icon: LucideIcons.triangleAlert, bg: const Color(0xFFFEE2E2), color: const Color(0xFFDC2626));
      case 'merchant_weekly_report':
        return (icon: LucideIcons.trendingUp, bg: const Color(0xFFDCFCE7), color: const Color(0xFF16A34A));
      default:
        return (icon: LucideIcons.bell, bg: const Color(0xFFF3E8FF), color: const Color(0xFF9333EA));
    }
  }

  String _sectionFor(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inDays == 0 && now.day == timestamp.day) return "AUJOURD'HUI";
    if (diff.inDays < 7) return 'CETTE SEMAINE';
    return 'PLUS ANCIEN';
  }
```

3. Construit la liste de `NotificationItem` affichée à partir des `AppNotification` reçues (`title`, `message` → `subtitle`, `relativeTime` → `time`, `_sectionFor(timestamp)` → `section`, `_visualFor(type)` → `icon`/`iconBg`/`iconColor`, `!isRead` → `isUnread`), en conservant `_buildNotificationTile`/`_buildFilterChip` et toute la structure visuelle telle quelle.
4. Remplace `_markAllRead()` par un appel à `ref.read(merchantNotificationsNotifierProvider.notifier).markAllRead()`, et `_clearAll()` par `ref.read(merchantNotificationsNotifierProvider.notifier).deleteAll()`.
5. Ajoute la gestion `AsyncValue` standard (`.when(data: ..., loading: () => const Center(child: CircularProgressIndicator()), error: (e, st) => ...)`) autour du corps actuellement construit depuis `_notifications`.

- [ ] **Step 4: Manual verification**

Pas d'infrastructure de test widget existante sur cet écran. Lance l'app marchand (skill `run`), connecte-toi, fais rejoindre un nouveau client (scan QR côté app client sur ce commerce), vérifie que `/merchant/notifications` (ou son point d'entrée dans le menu marchand) affiche la notification "Nouveau client 👋" réelle, que "Tout lire" et "Effacer toutes les notifications" persistent après relance de l'app.

- [ ] **Step 5: Commit**

```bash
git add lib/features/merchant/providers/notifications_provider.dart lib/features/merchant/providers/notifications_provider.g.dart lib/features/merchant/screens/notifications_screen.dart
git commit -m "feat: écran notifications marchand branché sur l'API réelle"
```

---

## Vérification finale

- [ ] **Backend** : `php artisan test` — tout doit passer.
- [ ] **Flutter** : `flutter analyze` puis `flutter test` — tout doit passer.
- [ ] **Manuel** : parcours complet — un nouveau client scanne le QR d'un commerce → le marchand voit "Nouveau client" dans son centre de notifications ; le client atteint un palier de récompense → il reçoit un push ET voit l'entrée dans `/client/notifications` même après avoir coupé/rouvert l'app.
