# Niveaux de paliers — icônes et noms unifiés — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer le système emoji de niveaux de fidélité par un système unique d'icônes Material (`LoyaltyLevel`, déjà utilisé dans le filtre marchand), verrouiller nom+icône des 5 premiers paliers (Bronze/Argent/Or/Platine/Fidèle) et permettre au marchand de choisir nom+icône pour les paliers au-delà de 5.

**Architecture:** Le backend Laravel (`restaurant-loyalty-api`) arrête de calculer une icône par rang (suppression de `LoyaltyTierService::iconForRank`/emoji) et expose à la place la position (rang 1-based, déjà déterministe) et une `icon_key` optionnelle (paliers 6+ uniquement) par palier. Le Flutter (`Miva_Fid`) déduit l'icône/couleur/nom du niveau depuis cette position via l'enum existant `LoyaltyLevel` (positions 1-5) ou une nouvelle palette `TierIconPalette` (position 6+), à travers un unique widget partagé `TierLevelIcon`. Une commande Artisan one-shot renomme de force les paliers 1-5 existants vers les noms canoniques.

**Tech Stack:** Laravel 13 / PHPUnit (`restaurant-loyalty-api`), Flutter 3.41 / flutter_test (`Miva_Fid`).

**Spec:** `docs/superpowers/specs/2026-08-26-niveaux-paliers-icones-design.md`

## Global Constraints

- Ordre canonique fixe et non négociable : `Bronze < Argent < Or < Platine < Fidèle` (positions 1 à 5).
- Position `i` d'un programme à N paliers (N≥2) : si `i ≤ 5`, nom/icône imposés par la position ; si `i > 5`, nom libre + icône choisie par le marchand.
- 1 seul palier configuré = aucun niveau affiché (comportement existant, non modifié).
- Aucun emoji ne doit plus être rendu à l'écran pour un niveau de fidélité, nulle part dans l'app.
- Les noms canoniques existants écrasent tout nom marchand personnalisé pour les positions 1-5 (décision produit validée) — les positions 6+ gardent leur nom actuel.
- Le filtre marchand (`clients_screen.dart`, `MerchantDashboardController`) et le comportement mono-palier restent inchangés (hors périmètre).
- Backend : tests via `php artisan test`. Flutter : tests via `flutter test`.

---

## Task 1: `icon_key` de palier + refonte de `LoyaltyTierService` (position, suppression des emoji)

**Repo:** `restaurant-loyalty-api`

**Files:**
- Create: `database/migrations/2026_08_26_150000_add_icon_key_to_loyalty_program_tiers_table.php`
- Modify: `app/Models/LoyaltyProgramTier.php:8-16`
- Modify: `app/Services/Loyalty/LoyaltyTierService.php` (fichier entier)
- Modify: `app/Models/LoyaltyCard.php:166-180`
- Test: `tests/Unit/Services/Loyalty/LoyaltyTierServiceTest.php`

**Interfaces:**
- Produces: `LoyaltyTierService::tiers(?LoyaltyProgram $program): array` — chaque élément gagne `position` (int, 1-based) et `icon_key` (?string). `LoyaltyTierService::resolve(LoyaltyCard $card): array` — gagne `position` (?int) et `icon_key` (?string) au niveau racine (niveau courant). `LoyaltyCard::getLevelAttribute()` — le tableau JSON `level` gagne les clés `position`/`icon_key`. Ces noms de champs sont consommés par les tâches F2/F5/F6 côté Flutter.

- [ ] **Step 1: Mettre à jour les tests existants pour refléter le nouveau contrat (avant d'implémenter)**

Dans `tests/Unit/Services/Loyalty/LoyaltyTierServiceTest.php`, remplacer les deux tests suivants (lignes 39-65) :

```php
    public function test_icon_for_rank_follows_fixed_sequence_when_five_tiers(): void
    {
        $service = app(LoyaltyTierService::class);
        $this->assertSame('🥉', $service->iconForRank(1, 5));
        $this->assertSame('🥈', $service->iconForRank(2, 5));
        $this->assertSame('🥇', $service->iconForRank(3, 5));
        $this->assertSame('💎', $service->iconForRank(4, 5));
        $this->assertSame('👑', $service->iconForRank(5, 5));
    }

    public function test_icon_for_rank_last_tier_is_always_max_regardless_of_total(): void
    {
        $service = app(LoyaltyTierService::class);

        // 2 paliers : le dernier passe directement à l'icône maximale.
        $this->assertSame('🥉', $service->iconForRank(1, 2));
        $this->assertSame('👑', $service->iconForRank(2, 2));

        // 3 paliers : réparti sur toute la plage, dernier toujours 👑.
        $this->assertSame('🥉', $service->iconForRank(1, 3));
        $this->assertSame('🥇', $service->iconForRank(2, 3));
        $this->assertSame('👑', $service->iconForRank(3, 3));

        // Plus de 5 paliers : toujours borné à 👑 au dernier.
        $this->assertSame('🥉', $service->iconForRank(1, 8));
        $this->assertSame('👑', $service->iconForRank(8, 8));
    }
```

par :

```php
    public function test_tiers_expose_sequential_position_and_stored_icon_key(): void
    {
        $card = $this->cardWithProgram('stamps', [], stampsCurrent: 0);
        LoyaltyProgramTier::create([
            'loyalty_program_id' => $card->loyalty_program_id, 'order' => 1,
            'goal' => 500, 'level_name' => 'Bronze', 'reward_description' => 'Boisson offerte',
        ]);
        LoyaltyProgramTier::create([
            'loyalty_program_id' => $card->loyalty_program_id, 'order' => 2,
            'goal' => 1000, 'level_name' => 'Custom Elite', 'reward_description' => 'Menu offert',
            'icon_key' => 'rocket_launch',
        ]);

        $tiers = app(LoyaltyTierService::class)->tiers($card->loyaltyProgram->fresh());

        $this->assertSame(1, $tiers[0]['position']);
        $this->assertNull($tiers[0]['icon_key']);
        $this->assertSame(2, $tiers[1]['position']);
        $this->assertSame('rocket_launch', $tiers[1]['icon_key']);
    }

    public function test_tiers_fallback_mono_tier_has_position_one_and_no_icon_key(): void
    {
        $card = $this->cardWithProgram('stamps', ['goal' => 8, 'reward_description' => 'Café offert']);
        $tiers = app(LoyaltyTierService::class)->tiers($card->loyaltyProgram);

        $this->assertSame(1, $tiers[0]['position']);
        $this->assertNull($tiers[0]['icon_key']);
    }
```

Dans `test_resolve_progresses_through_multi_tier_levels` (ligne ~124), remplacer :

```php
        $this->assertSame('🥉', $resolved['tiers'][0]['icon']);
```

par :

```php
        $this->assertSame(1, $resolved['tiers'][0]['position']);
        $this->assertNull($resolved['tiers'][0]['icon_key']);
        $this->assertSame(1, $resolved['position']);
```

Dans `test_next_reward_shows_the_real_reward_for_a_mono_tier_program` (ligne ~175), remplacer :

```php
        $this->assertSame('🎁', $nextReward['icon']);
```

par :

```php
        $this->assertSame(1, $nextReward['position']);
```

Dans `test_next_reward_targets_the_first_unreached_tier_for_a_multi_tier_program` (ligne ~194), remplacer :

```php
        $this->assertSame('👑', $nextReward['icon']);
```

par :

```php
        $this->assertSame(2, $nextReward['position']);
```

Dans `test_next_reward_shows_the_last_tier_once_everything_is_reached` (ligne ~212), remplacer :

```php
        $this->assertSame('👑', $nextReward['icon']);
```

par :

```php
        $this->assertSame(2, $nextReward['position']);
```

Ajouter aussi, à la fin de la classe (avant la dernière accolade), un test pour `getLevelAttribute` :

```php
    public function test_card_level_attribute_exposes_position_and_icon_key(): void
    {
        $card = $this->cardWithProgram('stamps', [], stampsCurrent: 700);
        LoyaltyProgramTier::create([
            'loyalty_program_id' => $card->loyalty_program_id, 'order' => 1,
            'goal' => 500, 'level_name' => 'Bronze', 'reward_description' => 'Boisson offerte',
        ]);
        LoyaltyProgramTier::create([
            'loyalty_program_id' => $card->loyalty_program_id, 'order' => 2,
            'goal' => 1000, 'level_name' => 'Argent', 'reward_description' => 'Dessert offert',
        ]);

        $level = $card->fresh()->level;

        $this->assertSame(1, $level['position']);
        $this->assertNull($level['icon_key']);
    }
```

- [ ] **Step 2: Lancer les tests, vérifier qu'ils échouent**

Run: `php artisan test --filter=LoyaltyTierServiceTest`
Expected: FAIL — `iconForRank` n'existe plus dans les anciens appels supprimés (n/a, déjà supprimés), et les nouvelles assertions (`position`, `icon_key`) échouent car ces clés n'existent pas encore dans les tableaux retournés.

- [ ] **Step 3: Migration — colonne `icon_key`**

Créer `database/migrations/2026_08_26_150000_add_icon_key_to_loyalty_program_tiers_table.php` :

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Icône du palier, uniquement pour les paliers au-delà de la position 5 —
 * les 5 premiers (Bronze/Argent/Or/Platine/Fidèle) ont une icône fixe
 * calculée côté client (`LoyaltyLevel`), jamais stockée. `null` pour eux.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('loyalty_program_tiers', function (Blueprint $table) {
            $table->string('icon_key')->nullable()->after('level_name');
        });
    }

    public function down(): void
    {
        Schema::table('loyalty_program_tiers', function (Blueprint $table) {
            $table->dropColumn('icon_key');
        });
    }
};
```

- [ ] **Step 4: `LoyaltyProgramTier` — ajouter `icon_key` au fillable**

Dans `app/Models/LoyaltyProgramTier.php:8-16`, remplacer :

```php
    protected $fillable = [
        'loyalty_program_id',
        'order',
        'goal',
        'level_name',
        'reward_description',
        'reveal_reward',
        'validity_days',
    ];
```

par :

```php
    protected $fillable = [
        'loyalty_program_id',
        'order',
        'goal',
        'level_name',
        'icon_key',
        'reward_description',
        'reveal_reward',
        'validity_days',
    ];
```

- [ ] **Step 5: Réécrire `LoyaltyTierService`**

Remplacer le contenu entier de `app/Services/Loyalty/LoyaltyTierService.php` par :

```php
<?php

namespace App\Services\Loyalty;

use App\Models\LoyaltyCard;
use App\Models\LoyaltyProgram;
use Illuminate\Support\Facades\DB;

/**
 * Résout les paliers d'un programme (objectif + niveau + récompense
 * unifiés). Remplace `RewardTierService` et `LoyaltyLevelService`.
 *
 * Distinction volontaire, cœur de la conception (voir spec) :
 * - 1 seul palier configuré : comportement "cycle répété" existant,
 *   `progress['stamps_current']` remis à zéro à chaque déblocage, jamais de
 *   niveau affiché. Géré directement par `MerchantDashboardController`, pas
 *   par ce service (`resolve()` renvoie `tiers: []`, `level_name: null`).
 * - 2 paliers ou plus : cumulatif à vie (jamais reset), plafonné au dernier
 *   palier une fois atteint. C'est ce que `resolve()` calcule.
 *
 * Icône/nom de niveau : pour les paliers en position 1 à 5, nom et icône
 * sont imposés côté client (`LoyaltyLevel.forPosition`, ordre Bronze <
 * Argent < Or < Platine < Fidèle) — ce service ne les calcule pas, il
 * expose seulement la `position` (rang 1-based, déterministe). Au-delà de
 * la position 5, le marchand choisit nom (`level_name`, texte libre déjà
 * existant) et icône (`icon_key`, palette côté client) — ce service se
 * contente de faire transiter `icon_key` tel que stocké.
 */
class LoyaltyTierService
{
    /**
     * Clé canonique d'un niveau de fidélité, dérivée de son nom tel que
     * configuré par le marchand (`level_name` des paliers). Permet au client
     * mobile de filtrer/représenter les niveaux sans faire de matching
     * fragile sur les libellés libres (« Or », « Gold », « VIP Or »...).
     * Matching insensible à la casse et aux accents ; `custom` en fallback.
     */
    public function levelKey(?string $levelName): string
    {
        $n = mb_strtolower(trim((string) $levelName));
        $n = strtr($n, [
            'à' => 'a', 'â' => 'a', 'ä' => 'a', 'é' => 'e', 'è' => 'e',
            'ê' => 'e', 'ë' => 'e', 'î' => 'i', 'ï' => 'i', 'ô' => 'o',
            'ö' => 'o', 'ù' => 'u', 'û' => 'u', 'ü' => 'u', 'ç' => 'c',
        ]);

        return match (true) {
            str_contains($n, 'bronze') => 'bronze',
            str_contains($n, 'argent'), str_contains($n, 'silver') => 'silver',
            str_contains($n, 'platine'), str_contains($n, 'platinum') => 'platinum',
            str_contains($n, 'gold') => 'gold',
            $n === 'or' || str_ends_with($n, ' or') || str_starts_with($n, 'or ') => 'gold',
            default => 'custom',
        };
    }

    /**
     * Vide `reward_description` quand ce palier précis n'est pas encore
     * débloqué et que le marchand le masque (`tier.reveal_reward === false`,
     * réglage propre à chaque palier — un programme peut cacher un seul
     * palier "surprise" et laisser les autres visibles).
     */
    private function redact(array $tier): array
    {
        return ($tier['reveal_reward'] ?? true) ? $tier : [...$tier, 'reward_description' => ''];
    }

    /**
     * @return array<int, array{id: ?int, order: int, position: int, goal: int, level_name: ?string, icon_key: ?string, reward_description: string, reveal_reward: bool, validity_days: ?int}>
     *                                                                                                                                                                                                    Trié par `goal` croissant.
     */
    public function tiers(?LoyaltyProgram $program): array
    {
        if ($program === null) {
            return [];
        }

        $rows = $program->tiers;
        if ($rows->isNotEmpty()) {
            return $rows
                ->sortBy('goal')
                ->values()
                ->map(fn ($r, $i) => [
                    'id' => $r->id,
                    'order' => $r->order,
                    'position' => $i + 1,
                    'goal' => max(1, (int) $r->goal),
                    'level_name' => $r->level_name,
                    'icon_key' => $r->icon_key,
                    'reward_description' => $r->reward_description,
                    'reveal_reward' => $r->reveal_reward,
                    'validity_days' => $r->validity_days ?? ($program->config['reward_validity_days'] ?? null),
                ])
                ->all();
        }

        // Programme jamais migré vers la table de paliers (tests qui
        // construisent `LoyaltyProgram` directement, ou programme historique
        // non passé par la commande de migration) — reproduit exactement le
        // fallback mono-palier de l'ancien `RewardTierService`. Le cashback
        // n'a par défaut aucun palier (comportement actuel : pas de cycle).
        if ($program->type === 'cashback') {
            return [];
        }

        $goal = (int) ($program->config['goal'] ?? 10);
        $title = (string) ($program->config['reward_description'] ?? '') ?: 'Récompense débloquée';

        return [[
            'id' => null,
            'order' => 1,
            'position' => 1,
            'goal' => max(1, $goal),
            'level_name' => null,
            'icon_key' => null,
            'reward_description' => $title,
            'reveal_reward' => true,
            'validity_days' => $program->config['reward_validity_days'] ?? null,
        ]];
    }

    /**
     * Palier vers lequel la carte progresse actuellement (pas encore
     * atteint) — sert d'aperçu tant qu'aucune `LoyaltyReward` n'est encore
     * débloquée (voir `LoyaltyCard::getNextRewardAttribute`). Contrairement à
     * `resolve()['tiers']`, jamais vide pour un mono-palier : c'est
     * justement le seul cas où ce champ a un rôle (pas de roadmap de niveau
     * pour montrer la récompense visée).
     *
     * @return array{id: ?int, order: int, position: int, goal: int, level_name: ?string, icon_key: ?string, reward_description: string, reveal_reward: bool, validity_days: ?int}|null
     */
    public function nextReward(LoyaltyCard $card): ?array
    {
        $tiers = $this->tiers($card->loyaltyProgram);
        if ($tiers === []) {
            return null;
        }

        if (count($tiers) === 1) {
            return $this->redact($tiers[0]);
        }

        $metric = $this->lifetimeMetric($card);

        foreach ($tiers as $tier) {
            if ($tier['goal'] > $metric) {
                return $this->redact($tier);
            }
        }

        // Tous les paliers sont atteints : aperçu du dernier (le max), déjà
        // débloqué en réalité — jamais masqué, quel que soit le réglage.
        return $tiers[count($tiers) - 1];
    }

    public function lifetimeCashback(LoyaltyCard $card): float
    {
        return (float) DB::table('loyalty_transactions')
            ->where('loyalty_card_id', $card->id)
            ->where('type', 'cashback_earn')
            ->where('status', 'valid')
            ->sum('value');
    }

    /**
     * Métrique multi-palier : jamais reset. Cashback = cashback cumulé à
     * vie. Tampons/Achats = `progress['stamps_current']`, qui n'est plus
     * remis à zéro dès qu'un programme a 2+ paliers (voir
     * `MerchantDashboardController::grantStampOrPoints`).
     */
    private function lifetimeMetric(LoyaltyCard $card): float
    {
        return $card->loyaltyProgram?->type === 'cashback'
            ? $this->lifetimeCashback($card)
            : (float) ($card->progress['stamps_current'] ?? 0);
    }

    /** @return array{level_name: ?string, percent_to_next: ?int, is_max_level: bool, position: ?int, icon_key: ?string, tiers: array} */
    public function resolve(LoyaltyCard $card): array
    {
        $tiers = $this->tiers($card->loyaltyProgram);

        if (count($tiers) <= 1) {
            return ['level_name' => null, 'percent_to_next' => null, 'is_max_level' => false, 'position' => null, 'icon_key' => null, 'tiers' => []];
        }

        $metric = $this->lifetimeMetric($card);

        $current = null;
        $next = null;
        foreach ($tiers as $tier) {
            if ($tier['goal'] <= $metric) {
                $current = $tier;
            } else {
                $next = $tier;
                break;
            }
        }

        // Paliers déjà débloqués au moins une fois pour cette carte (une
        // vraie `LoyaltyReward` existe) — un reset de cycle (`loops=true`)
        // ne remet à zéro que la progression courante, jamais l'historique
        // des récompenses déjà accordées : ces paliers restent "reached" et
        // ne se refont jamais masquer, même si la métrique du nouveau cycle
        // ne les couvre plus.
        $everUnlockedTierIds = DB::table('loyalty_rewards')
            ->where('loyalty_card_id', $card->id)
            ->whereNotNull('program_tier_id')
            ->pluck('program_tier_id')
            ->all();

        $tiersWithStatus = collect($tiers)->values()->map(function ($tier) use ($metric, $next, $everUnlockedTierIds) {
            $alreadyUnlocked = $tier['id'] !== null && in_array($tier['id'], $everUnlockedTierIds, true);
            $status = ($tier['goal'] <= $metric || $alreadyUnlocked)
                ? 'reached'
                : ($next !== null && $tier['order'] === $next['order'] ? 'current' : 'upcoming');

            $tier = $status === 'reached' ? $tier : $this->redact($tier);

            return [...$tier, 'status' => $status];
        })->all();

        if ($current === null) {
            $firstGoal = $tiers[0]['goal'];

            return [
                'level_name' => null,
                'percent_to_next' => (int) round(max(0, min(100, ($metric / $firstGoal) * 100))),
                'is_max_level' => false,
                'position' => null,
                'icon_key' => null,
                'tiers' => $tiersWithStatus,
            ];
        }

        if ($next === null) {
            return [
                'level_name' => $current['level_name'],
                'percent_to_next' => null,
                'is_max_level' => true,
                'position' => $current['position'],
                'icon_key' => $current['icon_key'],
                'tiers' => $tiersWithStatus,
            ];
        }

        $span = $next['goal'] - $current['goal'];
        $percent = $span > 0 ? (($metric - $current['goal']) / $span) * 100 : 0;

        return [
            'level_name' => $current['level_name'],
            'percent_to_next' => (int) round(max(0, min(100, $percent))),
            'is_max_level' => false,
            'position' => $current['position'],
            'icon_key' => $current['icon_key'],
            'tiers' => $tiersWithStatus,
        ];
    }
}
```

- [ ] **Step 6: `LoyaltyCard::getLevelAttribute` — exposer `position`/`icon_key`**

Dans `app/Models/LoyaltyCard.php:166-180`, remplacer :

```php
    /** Niveau de fidélité — `null` tant que le programme n'a qu'un seul palier configuré (voir `LoyaltyTierService`). */
    public function getLevelAttribute(): ?array
    {
        $resolved = app(LoyaltyTierService::class)->resolve($this);
        $tierService = app(LoyaltyTierService::class);

        return $resolved['level_name'] === null && $resolved['tiers'] === []
            ? null
            : [
                'name' => $resolved['level_name'],
                'key' => $tierService->levelKey($resolved['level_name']),
                'percent_to_next' => $resolved['percent_to_next'],
                'is_max_level' => $resolved['is_max_level'],
            ];
    }
```

par :

```php
    /** Niveau de fidélité — `null` tant que le programme n'a qu'un seul palier configuré (voir `LoyaltyTierService`). */
    public function getLevelAttribute(): ?array
    {
        $resolved = app(LoyaltyTierService::class)->resolve($this);
        $tierService = app(LoyaltyTierService::class);

        return $resolved['level_name'] === null && $resolved['tiers'] === []
            ? null
            : [
                'name' => $resolved['level_name'],
                'key' => $tierService->levelKey($resolved['level_name']),
                'percent_to_next' => $resolved['percent_to_next'],
                'is_max_level' => $resolved['is_max_level'],
                'position' => $resolved['position'],
                'icon_key' => $resolved['icon_key'],
            ];
    }
```

- [ ] **Step 7: Lancer les tests, vérifier qu'ils passent**

Run: `php artisan test --filter=LoyaltyTierServiceTest`
Expected: PASS (toutes les assertions, y compris les nouvelles)

Puis lancer la suite complète pour vérifier l'absence de régression ailleurs (`MerchantDashboardController`, sérialisation carte, etc.) :

Run: `php artisan test`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add database/migrations/2026_08_26_150000_add_icon_key_to_loyalty_program_tiers_table.php app/Models/LoyaltyProgramTier.php app/Services/Loyalty/LoyaltyTierService.php app/Models/LoyaltyCard.php tests/Unit/Services/Loyalty/LoyaltyTierServiceTest.php
git commit -m "feat: expose la position et l'icon_key des paliers, supprime les emoji calculés par rang"
```

---

## Task 2: Commande one-shot — renommage canonique des 5 premiers paliers

**Repo:** `restaurant-loyalty-api`

**Files:**
- Create: `app/Console/Commands/RenameCanonicalLoyaltyTiers.php`
- Create: `database/migrations/2026_08_26_150001_run_rename_canonical_loyalty_tiers.php`
- Test: `tests/Feature/Console/RenameCanonicalLoyaltyTiersTest.php`

**Interfaces:**
- Consumes: `LoyaltyProgram::tiers()` (relation existante, `app/Models/LoyaltyProgram.php:35-38`).
- Produces: commande Artisan `loyalty:rename-canonical-tiers`, idempotente.

- [ ] **Step 1: Écrire le test (avant d'implémenter)**

Créer `tests/Feature/Console/RenameCanonicalLoyaltyTiersTest.php` :

```php
<?php

namespace Tests\Feature\Console;

use App\Models\LoyaltyProgram;
use App\Models\LoyaltyProgramTier;
use App\Models\Restaurant;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RenameCanonicalLoyaltyTiersTest extends TestCase
{
    use RefreshDatabase;

    private function programWithTiers(array $tierNames): LoyaltyProgram
    {
        $restaurant = Restaurant::create([
            'name' => 'Chez Awa', 'category' => 'Restaurant',
            'email' => 'commerce@example.com', 'password' => bcrypt('password123'),
        ]);
        $program = LoyaltyProgram::create([
            'restaurant_id' => $restaurant->id, 'name' => 'Programme', 'type' => 'stamps', 'config' => [],
        ]);
        foreach ($tierNames as $index => $name) {
            LoyaltyProgramTier::create([
                'loyalty_program_id' => $program->id,
                'order' => $index + 1,
                'goal' => ($index + 1) * 500,
                'level_name' => $name,
                'reward_description' => 'Récompense',
            ]);
        }

        return $program;
    }

    public function test_renames_the_first_five_tiers_to_canonical_names_by_position(): void
    {
        $program = $this->programWithTiers(['Débutant', 'VIP', 'Elite', 'Ambassadeur', 'Légende']);

        $this->artisan('loyalty:rename-canonical-tiers')->assertExitCode(0);

        $names = $program->fresh()->tiers->sortBy('goal')->pluck('level_name')->values()->all();
        $this->assertSame(['Bronze', 'Argent', 'Or', 'Platine', 'Fidèle'], $names);
    }

    public function test_keeps_the_free_name_of_tiers_beyond_position_five(): void
    {
        $program = $this->programWithTiers(['A', 'B', 'C', 'D', 'E', 'Mon Palier Custom']);

        $this->artisan('loyalty:rename-canonical-tiers')->assertExitCode(0);

        $names = $program->fresh()->tiers->sortBy('goal')->pluck('level_name')->values()->all();
        $this->assertSame(['Bronze', 'Argent', 'Or', 'Platine', 'Fidèle', 'Mon Palier Custom'], $names);
    }

    public function test_is_idempotent(): void
    {
        $program = $this->programWithTiers(['Débutant', 'VIP']);

        $this->artisan('loyalty:rename-canonical-tiers')->assertExitCode(0);
        $this->artisan('loyalty:rename-canonical-tiers')->assertExitCode(0);

        $names = $program->fresh()->tiers->sortBy('goal')->pluck('level_name')->values()->all();
        $this->assertSame(['Bronze', 'Argent'], $names);
    }
}
```

- [ ] **Step 2: Lancer le test, vérifier qu'il échoue**

Run: `php artisan test --filter=RenameCanonicalLoyaltyTiersTest`
Expected: FAIL — commande `loyalty:rename-canonical-tiers` introuvable.

- [ ] **Step 3: Implémenter la commande**

Créer `app/Console/Commands/RenameCanonicalLoyaltyTiers.php` :

```php
<?php

namespace App\Console\Commands;

use App\Models\LoyaltyProgram;
use Illuminate\Console\Command;

/**
 * Migration one-shot (pas une migration de schéma — logique métier) : impose
 * les noms canoniques (Bronze/Argent/Or/Platine/Fidèle) aux 5 premiers
 * paliers de chaque programme, par position (triée par `goal` croissant,
 * même tri que `LoyaltyTierService::tiers()`) — écrase tout nom personnalisé
 * par le marchand, cohérent avec la règle "noms des 5 premiers niveaux non
 * modifiables". Les paliers en position 6+ gardent leur nom actuel.
 * Idempotente : ré-écrit toujours le même nom canonique par position, donc
 * sans danger si `php artisan migrate` est rejoué.
 */
class RenameCanonicalLoyaltyTiers extends Command
{
    protected $signature = 'loyalty:rename-canonical-tiers';

    protected $description = 'Renomme de force les paliers 1-5 de chaque programme vers Bronze/Argent/Or/Platine/Fidèle';

    private const CANONICAL_NAMES = ['Bronze', 'Argent', 'Or', 'Platine', 'Fidèle'];

    public function handle(): int
    {
        $count = 0;

        LoyaltyProgram::with('tiers')->chunk(50, function ($programs) use (&$count) {
            foreach ($programs as $program) {
                $tiers = $program->tiers->sortBy('goal')->values();
                foreach ($tiers as $index => $tier) {
                    if ($index >= count(self::CANONICAL_NAMES)) {
                        break;
                    }
                    $canonicalName = self::CANONICAL_NAMES[$index];
                    if ($tier->level_name !== $canonicalName) {
                        $tier->update(['level_name' => $canonicalName]);
                        $count++;
                    }
                }
            }
        });

        $this->info("{$count} palier(s) renommé(s) vers un nom canonique.");

        return self::SUCCESS;
    }
}
```

- [ ] **Step 4: Migration qui déclenche la commande au déploiement**

Créer `database/migrations/2026_08_26_150001_run_rename_canonical_loyalty_tiers.php` :

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Artisan;

/**
 * Exécute `loyalty:rename-canonical-tiers` au déploiement (même stratégie
 * que `2026_08_21_200000_run_loyalty_tier_migration.php`) : sans ça, un
 * marchand qui modifie ses paliers avant qu'un humain ne pense à lancer la
 * commande manuellement verrait ses 5 premiers paliers rester sur d'anciens
 * noms libres. Idempotente, donc sans danger si `php artisan migrate` est
 * rejoué.
 */
return new class extends Migration
{
    public function up(): void
    {
        Artisan::call('loyalty:rename-canonical-tiers');
    }

    public function down(): void
    {
        // Non réversible : les noms libres d'origine ne sont pas conservés.
    }
};
```

- [ ] **Step 5: Lancer le test, vérifier qu'il passe**

Run: `php artisan test --filter=RenameCanonicalLoyaltyTiersTest`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/Console/Commands/RenameCanonicalLoyaltyTiers.php database/migrations/2026_08_26_150001_run_rename_canonical_loyalty_tiers.php tests/Feature/Console/RenameCanonicalLoyaltyTiersTest.php
git commit -m "feat: commande one-shot pour imposer les noms canoniques aux 5 premiers paliers"
```

---

## Task 3: `LoyaltyLevel.forPosition` + nouvelle palette `TierIconPalette`

**Repo:** `Miva_Fid`

**Files:**
- Modify: `lib/core/domain/loyalty_level.dart`
- Create: `lib/core/domain/tier_icon_palette.dart`
- Test: `test/core/domain/loyalty_level_test.dart`
- Test: `test/core/domain/tier_icon_palette_test.dart`

**Interfaces:**
- Produces: `LoyaltyLevel.forPosition(int position) -> LoyaltyLevel?` (null si position > 5). `TierIconPalette.options -> List<TierIconOption>`, `TierIconPalette.byKey(String? key) -> TierIconOption`, `TierIconPalette.fallback -> TierIconOption`. `TierIconOption { key, icon, label }`. Consommé par F3/F4/F5/F6.

- [ ] **Step 1: Écrire les tests (avant d'implémenter)**

Créer `test/core/domain/loyalty_level_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/domain/loyalty_level.dart';

void main() {
  group('LoyaltyLevel.forPosition', () {
    test('maps positions 1 to 5 to the fixed canonical order', () {
      expect(LoyaltyLevel.forPosition(1), LoyaltyLevel.bronze);
      expect(LoyaltyLevel.forPosition(2), LoyaltyLevel.silver);
      expect(LoyaltyLevel.forPosition(3), LoyaltyLevel.gold);
      expect(LoyaltyLevel.forPosition(4), LoyaltyLevel.platinum);
      expect(LoyaltyLevel.forPosition(5), LoyaltyLevel.custom);
    });

    test('returns null beyond position 5', () {
      expect(LoyaltyLevel.forPosition(6), isNull);
      expect(LoyaltyLevel.forPosition(10), isNull);
    });
  });
}
```

Créer `test/core/domain/tier_icon_palette_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/domain/tier_icon_palette.dart';

void main() {
  group('TierIconPalette.byKey', () {
    test('finds an option by its key', () {
      final option = TierIconPalette.byKey('rocket_launch');
      expect(option.key, 'rocket_launch');
    });

    test('falls back to a default icon for an unknown or null key', () {
      expect(TierIconPalette.byKey('does_not_exist').key, TierIconPalette.fallback.key);
      expect(TierIconPalette.byKey(null).key, TierIconPalette.fallback.key);
    });

    test('has no duplicate keys', () {
      final keys = TierIconPalette.options.map((o) => o.key).toList();
      expect(keys.toSet().length, keys.length);
    });
  });
}
```

- [ ] **Step 2: Lancer les tests, vérifier qu'ils échouent**

Run: `flutter test test/core/domain/loyalty_level_test.dart test/core/domain/tier_icon_palette_test.dart`
Expected: FAIL — `LoyaltyLevel.forPosition` inexistant, fichier `tier_icon_palette.dart` inexistant.

- [ ] **Step 3: Ajouter `forPosition` à `LoyaltyLevel`**

Dans `lib/core/domain/loyalty_level.dart`, juste avant la fermeture de la classe (après `fromKey`), ajouter :

```dart

  /// Niveau canonique pour un palier en position [position] (1-based) parmi
  /// les 5 premiers d'un programme — `null` au-delà (palier personnalisé,
  /// voir `TierIconPalette`). L'ordre de déclaration de cet enum EST l'ordre
  /// métier (Bronze < Argent < Or < Platine < Fidèle), d'où l'indexation
  /// directe sans table de correspondance séparée.
  static LoyaltyLevel? forPosition(int position) =>
      position >= 1 && position <= LoyaltyLevel.values.length
          ? LoyaltyLevel.values[position - 1]
          : null;
```

- [ ] **Step 4: Créer `TierIconPalette`**

Créer `lib/core/domain/tier_icon_palette.dart` :

```dart
import 'package:flutter/material.dart';

/// Une icône proposée au marchand pour un palier au-delà du 5ᵉ (voir
/// [LoyaltyLevel.forPosition]) — distincte des 5 icônes fixes pour éviter
/// toute confusion visuelle avec Bronze/Argent/Or/Platine/Fidèle.
class TierIconOption {
  final String key;
  final IconData icon;
  final String label;
  const TierIconOption(this.key, this.icon, this.label);
}

/// Palette d'icônes pour les paliers en position 6+ — le marchand choisit
/// nom ET icône librement pour ceux-là (voir `TierEditorForm`).
class TierIconPalette {
  static const List<TierIconOption> options = [
    TierIconOption('local_fire_department', Icons.local_fire_department, 'Flamme'),
    TierIconOption('bolt', Icons.bolt, 'Éclair'),
    TierIconOption('favorite', Icons.favorite, 'Cœur'),
    TierIconOption('shield', Icons.shield, 'Bouclier'),
    TierIconOption('rocket_launch', Icons.rocket_launch, 'Fusée'),
    TierIconOption('auto_awesome', Icons.auto_awesome, 'Étincelle'),
    TierIconOption('verified', Icons.verified, 'Vérifié'),
    TierIconOption('celebration', Icons.celebration, 'Fête'),
    TierIconOption('whatshot', Icons.whatshot, 'Tendance'),
    TierIconOption('grade', Icons.grade, 'Insigne'),
    TierIconOption('thumb_up', Icons.thumb_up, 'Pouce levé'),
    TierIconOption('sports_score', Icons.sports_score, 'Podium'),
  ];

  static const TierIconOption fallback = TierIconOption('grade', Icons.grade, 'Insigne');

  static TierIconOption byKey(String? key) => options.firstWhere(
        (o) => o.key == key,
        orElse: () => fallback,
      );
}
```

- [ ] **Step 5: Lancer les tests, vérifier qu'ils passent**

Run: `flutter test test/core/domain/loyalty_level_test.dart test/core/domain/tier_icon_palette_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/core/domain/loyalty_level.dart lib/core/domain/tier_icon_palette.dart test/core/domain/loyalty_level_test.dart test/core/domain/tier_icon_palette_test.dart
git commit -m "feat: LoyaltyLevel.forPosition et palette d'icones pour paliers custom"
```

---

## Task 4: `ProgramTier`/`CardTier`/`LoyaltyCardModel` — champs `position`/`iconKey`

**Repo:** `Miva_Fid`

**Files:**
- Modify: `lib/features/onboarding/models/program_tier.dart` (fichier entier)
- Modify: `lib/features/client/models/loyalty_card.dart:11-40` (classe `CardTier`)
- Modify: `lib/models/loyalty_card_model.dart` (fichier entier)
- Test: `test/features/client/models/loyalty_card_reward_test.dart` (ajouts)
- Test: `test/models/loyalty_card_model_test.dart` (nouveau)

**Interfaces:**
- Produces: `ProgramTier.iconKey` (?String, sérialisé `icon_key`). `CardTier.position` (?int), `CardTier.iconKey` (?String) — remplace `CardTier.icon`. `LoyaltyCardModel.levelPosition` (?int), `LoyaltyCardModel.levelIconKey` (?String). Consommé par F4 (ProgramTier), F5 (CardTier), F6 (LoyaltyCardModel).

- [ ] **Step 1: Écrire/étendre les tests (avant d'implémenter)**

Dans `test/features/client/models/loyalty_card_reward_test.dart`, ajouter (dans le `group` existant, après le test `'parses goal/percent/level from a real backend payload'`) :

```dart

    test('parses tier position and icon_key from the tiers roadmap', () {
      final json = baseJson(
        stampsCurrent: 700,
        goal: 1000,
        percent: 40,
        level: {'name': 'Argent', 'percent_to_next': 40, 'is_max_level': false, 'position': 2, 'icon_key': null},
      )..['tiers'] = [
          {'order': 1, 'position': 1, 'goal': 500, 'level_name': 'Bronze', 'reward_description': 'Boisson offerte', 'icon_key': null, 'status': 'reached'},
          {'order': 2, 'position': 2, 'goal': 1000, 'level_name': 'Argent', 'reward_description': 'Dessert offert', 'icon_key': null, 'status': 'current'},
        ];

      final card = LoyaltyCard.fromApi(json);

      expect(card.tiers, hasLength(2));
      expect(card.tiers[0].position, 1);
      expect(card.tiers[0].iconKey, isNull);
      expect(card.tiers[1].position, 2);
    });
```

Créer `test/models/loyalty_card_model_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/models/loyalty_card_model.dart';

void main() {
  group('LoyaltyCardModel.fromJson — level.position/icon_key', () {
    Map<String, dynamic> baseJson(Map<String, dynamic>? level) {
      return {
        'id': 1,
        'client_id': 1,
        'restaurant_id': 1,
        'created_at': '2026-08-01T00:00:00Z',
        'level': level,
      };
    }

    test('parses position and icon_key when a level is resolved', () {
      final card = LoyaltyCardModel.fromJson(baseJson({
        'name': 'Argent',
        'key': 'silver',
        'percent_to_next': 40,
        'is_max_level': false,
        'position': 2,
        'icon_key': null,
      }));

      expect(card.levelName, 'Argent');
      expect(card.levelPosition, 2);
      expect(card.levelIconKey, isNull);
    });

    test('exposes null position/icon_key when there is no level', () {
      final card = LoyaltyCardModel.fromJson(baseJson(null));

      expect(card.levelName, isNull);
      expect(card.levelPosition, isNull);
      expect(card.levelIconKey, isNull);
    });

    test('copyWith forwards levelPosition and levelIconKey unchanged', () {
      final card = LoyaltyCardModel.fromJson(baseJson({
        'name': 'Or', 'key': 'gold', 'percent_to_next': 10, 'is_max_level': false,
        'position': 3, 'icon_key': null,
      }));

      final copied = card.copyWith(levelName: 'Or');

      expect(copied.levelPosition, 3);
      expect(copied.levelIconKey, isNull);
    });
  });
}
```

- [ ] **Step 2: Lancer les tests, vérifier qu'ils échouent**

Run: `flutter test test/features/client/models/loyalty_card_reward_test.dart test/models/loyalty_card_model_test.dart`
Expected: FAIL — `CardTier.position`/`iconKey` et `LoyaltyCardModel.levelPosition`/`levelIconKey` n'existent pas encore.

- [ ] **Step 3: `ProgramTier` — ajouter `iconKey`**

Remplacer le contenu entier de `lib/features/onboarding/models/program_tier.dart` par :

```dart
/// Palier unifié : objectif (seuil) + niveau (nom libre du marchand,
/// `null`/ignoré si un seul palier) + récompense. Remplace `RewardTier` et
/// `LoyaltyLevel`, auparavant deux systèmes indépendants.
class ProgramTier {
  final int goal;

  /// Nom du niveau — libre, masqué côté UI si un seul palier est configuré.
  /// Pour les paliers en position 1-5 d'un programme multi-palier, ce champ
  /// est toujours le nom canonique imposé (voir `LoyaltyLevel.forPosition`),
  /// non éditable par le marchand.
  final String? levelName;
  final String rewardDescription;

  /// Durée de validité (jours) propre à ce palier — `null` = utilise la
  /// valeur par défaut du programme (`reward_validity_days`).
  final int? validityDays;

  /// `false` = récompense "surprise" : le client voit que ce palier existe
  /// mais pas son contenu tant qu'il ne l'a pas débloqué. Réglable palier
  /// par palier — un programme peut cacher un seul palier et laisser les
  /// autres visibles.
  final bool revealReward;

  /// Icône choisie par le marchand pour un palier au-delà du 5ᵉ (voir
  /// `TierIconPalette`) — toujours `null` pour les 5 premiers, dont l'icône
  /// est fixe (`LoyaltyLevel.forPosition`), jamais stockée.
  final String? iconKey;

  const ProgramTier({
    required this.goal,
    this.levelName,
    required this.rewardDescription,
    this.validityDays,
    this.revealReward = true,
    this.iconKey,
  });

  ProgramTier copyWith({
    int? goal,
    String? levelName,
    bool clearLevelName = false,
    String? rewardDescription,
    int? validityDays,
    bool clearValidityDays = false,
    bool? revealReward,
    String? iconKey,
    bool clearIconKey = false,
  }) {
    return ProgramTier(
      goal: goal ?? this.goal,
      levelName: clearLevelName ? null : (levelName ?? this.levelName),
      rewardDescription: rewardDescription ?? this.rewardDescription,
      validityDays:
          clearValidityDays ? null : (validityDays ?? this.validityDays),
      revealReward: revealReward ?? this.revealReward,
      iconKey: clearIconKey ? null : (iconKey ?? this.iconKey),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal': goal,
      'level_name': levelName,
      'reward_description': rewardDescription,
      if (validityDays != null) 'validity_days': validityDays,
      'reveal_reward': revealReward,
      if (iconKey != null) 'icon_key': iconKey,
    };
  }

  factory ProgramTier.fromJson(Map<String, dynamic> json) {
    return ProgramTier(
      goal: (json['goal'] as num?)?.toInt() ?? 10,
      levelName: json['level_name'] as String?,
      rewardDescription: (json['reward_description'] as String?) ?? '',
      validityDays: (json['validity_days'] as num?)?.toInt(),
      revealReward: json['reveal_reward'] as bool? ?? true,
      iconKey: json['icon_key'] as String?,
    );
  }
}
```

- [ ] **Step 4: `CardTier` — remplacer `icon` par `position`/`iconKey`**

Dans `lib/features/client/models/loyalty_card.dart:11-40`, remplacer :

```dart
class CardTier {
  final int order;
  final int goal;
  final String? levelName;
  final String rewardDescription;
  final String icon;

  /// `reached`, `current` ou `upcoming`.
  final String status;

  const CardTier({
    required this.order,
    required this.goal,
    this.levelName,
    required this.rewardDescription,
    required this.icon,
    required this.status,
  });

  factory CardTier.fromJson(Map<String, dynamic> json) {
    return CardTier(
      order: (json['order'] as num?)?.toInt() ?? 0,
      goal: (json['goal'] as num?)?.toInt() ?? 0,
      levelName: json['level_name'] as String?,
      rewardDescription: json['reward_description'] as String? ?? '',
      icon: json['icon'] as String? ?? '⭐',
      status: json['status'] as String? ?? 'upcoming',
    );
  }
}
```

par :

```dart
class CardTier {
  final int order;

  /// Rang 1-based du palier dans le programme — pilote l'icône/couleur
  /// fixe pour les positions 1 à 5 (voir `LoyaltyLevel.forPosition`).
  final int? position;
  final int goal;
  final String? levelName;
  final String rewardDescription;

  /// Icône choisie par le marchand pour un palier custom (position > 5,
  /// voir `TierIconPalette`) — `null` pour les positions 1 à 5.
  final String? iconKey;

  /// `reached`, `current` ou `upcoming`.
  final String status;

  const CardTier({
    required this.order,
    this.position,
    required this.goal,
    this.levelName,
    required this.rewardDescription,
    this.iconKey,
    required this.status,
  });

  factory CardTier.fromJson(Map<String, dynamic> json) {
    return CardTier(
      order: (json['order'] as num?)?.toInt() ?? 0,
      position: (json['position'] as num?)?.toInt(),
      goal: (json['goal'] as num?)?.toInt() ?? 0,
      levelName: json['level_name'] as String?,
      rewardDescription: json['reward_description'] as String? ?? '',
      iconKey: json['icon_key'] as String?,
      status: json['status'] as String? ?? 'upcoming',
    );
  }
}
```

- [ ] **Step 5: `LoyaltyCardModel` — ajouter `levelPosition`/`levelIconKey`**

Remplacer le contenu entier de `lib/models/loyalty_card_model.dart` par :

```dart
import 'merchant_model.dart';
import 'user_model.dart';

class LoyaltyCardModel {
  const LoyaltyCardModel({
    required this.id,
    required this.clientId,
    required this.merchantId,
    this.stampsCount = 0,
    this.pointsTotal = 0,
    this.cashbackBalanceFcfa = 0,
    this.status = 'active',
    required this.createdAt,
    this.lastActivityAt,
    this.merchant,
    this.client,
    this.levelName,
    this.levelKey,
    this.levelPercentToNext,
    this.isMaxLevel = false,
    this.levelPosition,
    this.levelIconKey,
    this.cyclesCompleted = 0,
  });

  final String id;
  final String clientId;
  final String merchantId;
  final int stampsCount;
  final int pointsTotal;
  final double cashbackBalanceFcfa;
  final String status; // 'active' | 'reward_available'
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final MerchantModel? merchant;
  final UserModel? client;

  /// Niveau de fidélité du client (Bronze/Argent/Or...) — indépendant du
  /// cycle en cours, voir `LoyaltyCard::level` côté API. `null` si le
  /// programme n'a pas encore été résolu côté serveur.
  final String? levelName;

  /// Clé canonique du niveau (`bronze|silver|gold|platinum|custom`),
  /// dérivée côté serveur du libellé libre configuré par le marchand —
  /// source de vérité pour l'affichage et le filtrage, voir
  /// [LoyaltyLevel.fromKey]. `null` si pas de niveau résolu.
  final String? levelKey;
  final int? levelPercentToNext;
  final bool isMaxLevel;

  /// Rang 1-based du palier courant — pilote l'icône fixe pour les
  /// positions 1 à 5 (voir `LoyaltyLevel.forPosition`). `null` si pas de
  /// niveau résolu, ou si aucun palier n'est encore atteint.
  final int? levelPosition;

  /// Icône choisie par le marchand pour un palier custom (position > 5,
  /// voir `TierIconPalette`) — `null` pour les positions 1 à 5.
  final String? levelIconKey;

  /// Nombre de cycles complets terminés à vie (programme bouclé N fois) —
  /// sert au filtrage marchand (« a déjà terminé le programme »).
  final int cyclesCompleted;

  bool get hasRewardAvailable => status == 'reward_available';

  double progressRatio(int stampsRequired) {
    if (stampsRequired == 0) return 0;
    return (stampsCount / stampsRequired).clamp(0.0, 1.0);
  }

  int stampsRemaining(int stampsRequired) {
    final rem = stampsRequired - stampsCount;
    return rem < 0 ? 0 : rem;
  }

  /// Construit une carte depuis `GET /merchant/clients*`.
  ///
  /// Le backend expose `stamps_current` (extrait du JSON `progress`) et
  /// imbrique le client sous `client` — les identifiants arrivent en string
  /// pour rester compatibles avec l'ancien format.
  factory LoyaltyCardModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    final level = json['level'] as Map<String, dynamic>?;
    return LoyaltyCardModel(
      id: json['id'].toString(),
      clientId: json['client_id'].toString(),
      merchantId: json['restaurant_id']?.toString() ??
          json['merchant_id']?.toString() ??
          '',
      stampsCount: _asInt(json['stamps_current']),
      pointsTotal: _asInt(json['points_total']),
      cashbackBalanceFcfa:
          double.tryParse(json['cashback_balance_fcfa']?.toString() ?? '') ?? 0,
      status: json['status'] as String? ?? 'active',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
              DateTime.now(),
      lastActivityAt:
          DateTime.tryParse(json['last_activity_at']?.toString() ?? ''),
      levelName: level?['name'] as String?,
      levelKey: level?['key'] as String?,
      levelPercentToNext: level == null ? null : _asInt(level['percent_to_next']),
      isMaxLevel: level?['is_max_level'] as bool? ?? false,
      levelPosition: level == null ? null : (level['position'] as num?)?.toInt(),
      levelIconKey: level?['icon_key'] as String?,
      cyclesCompleted: _asInt(json['cycles_completed']),
      client: client == null
          ? null
          : UserModel(
              id: client['id'].toString(),
              name: client['name'] as String? ?? 'Client',
              phone: client['phone'] as String?,
              role: 'client',
              avatarUrl: client['avatar_url'] as String?,
              createdAt:
                  DateTime.tryParse(json['created_at']?.toString() ?? '') ??
                      DateTime.now(),
            ),
    );
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'merchant_id': merchantId,
      'stamps_count': stampsCount,
      'points_total': pointsTotal,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LoyaltyCardModel copyWith({
    String? id,
    String? clientId,
    String? merchantId,
    int? stampsCount,
    int? pointsTotal,
    double? cashbackBalanceFcfa,
    String? status,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    MerchantModel? merchant,
    UserModel? client,
    String? levelName,
    String? levelKey,
    int? levelPercentToNext,
    bool? isMaxLevel,
    int? levelPosition,
    String? levelIconKey,
    int? cyclesCompleted,
  }) {
    return LoyaltyCardModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      merchantId: merchantId ?? this.merchantId,
      stampsCount: stampsCount ?? this.stampsCount,
      pointsTotal: pointsTotal ?? this.pointsTotal,
      cashbackBalanceFcfa: cashbackBalanceFcfa ?? this.cashbackBalanceFcfa,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      merchant: merchant ?? this.merchant,
      client: client ?? this.client,
      levelName: levelName ?? this.levelName,
      levelKey: levelKey ?? this.levelKey,
      levelPercentToNext: levelPercentToNext ?? this.levelPercentToNext,
      isMaxLevel: isMaxLevel ?? this.isMaxLevel,
      levelPosition: levelPosition ?? this.levelPosition,
      levelIconKey: levelIconKey ?? this.levelIconKey,
      cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
    );
  }
}
```

- [ ] **Step 6: Lancer les tests, vérifier qu'ils passent**

Run: `flutter test test/features/client/models/loyalty_card_reward_test.dart test/models/loyalty_card_model_test.dart`
Expected: PASS

Puis lancer l'analyse statique pour détecter tout appelant cassé par la suppression de `CardTier.icon` :

Run: `flutter analyze`
Expected: des erreurs vont apparaître sur les usages de `CardTier.icon`/`iconForTierRank` — c'est normal et attendu, ils sont corrigés dans les tâches F4/F5. Vérifier qu'il n'y a PAS d'autre appelant en dehors de ceux déjà listés dans les tâches F4/F5.

- [ ] **Step 7: Commit**

```bash
git add lib/features/onboarding/models/program_tier.dart lib/features/client/models/loyalty_card.dart lib/models/loyalty_card_model.dart test/features/client/models/loyalty_card_reward_test.dart test/models/loyalty_card_model_test.dart
git commit -m "feat: ajoute position/icon_key aux modeles de palier (ProgramTier, CardTier, LoyaltyCardModel)"
```

---

## Task 5: Widget partagé `TierLevelIcon`

**Repo:** `Miva_Fid`

**Files:**
- Create: `lib/core/widgets/tier_level_icon.dart`
- Test: `test/core/widgets/tier_level_icon_test.dart`

**Interfaces:**
- Consumes: `LoyaltyLevel.forPosition` et `TierIconPalette.byKey` (Task 3).
- Produces: `TierLevelIcon({int? position, String? iconKey, double size, Color? color})` — un `Widget`. Consommé par F4, F5, F6.

- [ ] **Step 1: Écrire le test (avant d'implémenter)**

Créer `test/core/widgets/tier_level_icon_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/domain/loyalty_level.dart';
import 'package:miva_fid/core/domain/tier_icon_palette.dart';
import 'package:miva_fid/core/widgets/tier_level_icon.dart';

void main() {
  Future<Icon> pumpAndGetIcon(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    return tester.widget<Icon>(find.byType(Icon));
  }

  testWidgets('renders the fixed LoyaltyLevel icon for position 1 to 5', (tester) async {
    final icon = await pumpAndGetIcon(tester, const TierLevelIcon(position: 1));
    expect(icon.icon, LoyaltyLevel.bronze.icon);
  });

  testWidgets('renders the palette icon for a custom tier beyond position 5', (tester) async {
    final icon = await pumpAndGetIcon(
      tester,
      const TierLevelIcon(position: null, iconKey: 'rocket_launch'),
    );
    expect(icon.icon, TierIconPalette.byKey('rocket_launch').icon);
  });

  testWidgets('falls back to the default palette icon when neither is known', (tester) async {
    final icon = await pumpAndGetIcon(tester, const TierLevelIcon(position: null, iconKey: null));
    expect(icon.icon, TierIconPalette.fallback.icon);
  });
}
```

- [ ] **Step 2: Lancer le test, vérifier qu'il échoue**

Run: `flutter test test/core/widgets/tier_level_icon_test.dart`
Expected: FAIL — fichier `tier_level_icon.dart` inexistant.

- [ ] **Step 3: Implémenter `TierLevelIcon`**

Créer `lib/core/widgets/tier_level_icon.dart` :

```dart
import 'package:flutter/material.dart';

import '../domain/loyalty_level.dart';
import '../domain/tier_icon_palette.dart';

/// Icône Material d'un palier de fidélité, résolue à partir de sa position
/// (1-based) et, pour un palier custom (position > 5 ou position inconnue),
/// de la clé choisie par le marchand dans la palette. Remplace l'ancien
/// rendu emoji (`Text(tier.icon, ...)`) partout où un niveau de fidélité
/// est affiché — un seul point d'implémentation, marchand ET client.
class TierLevelIcon extends StatelessWidget {
  final int? position;
  final String? iconKey;
  final double size;
  final Color? color;

  const TierLevelIcon({
    super.key,
    required this.position,
    this.iconKey,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final level = position == null ? null : LoyaltyLevel.forPosition(position!);
    if (level != null) {
      return Icon(level.icon, size: size, color: color ?? level.color);
    }
    final custom = TierIconPalette.byKey(iconKey);
    return Icon(custom.icon, size: size, color: color ?? Theme.of(context).colorScheme.primary);
  }
}
```

- [ ] **Step 4: Lancer le test, vérifier qu'il passe**

Run: `flutter test test/core/widgets/tier_level_icon_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/tier_level_icon.dart test/core/widgets/tier_level_icon_test.dart
git commit -m "feat: widget TierLevelIcon partage pour le rendu des niveaux de palier"
```

---

## Task 6: `TierEditorForm` — verrouillage positions 1-5, sélecteur d'icône pour 6+

**Repo:** `Miva_Fid`

**Files:**
- Modify: `lib/features/merchant/widgets/tier_editor_form.dart` (fichier entier)
- Create: `lib/features/merchant/widgets/tier_icon_picker_sheet.dart`
- Test: `test/features/merchant/widgets/tier_editor_form_test.dart`

**Interfaces:**
- Consumes: `ProgramTier.iconKey` (Task 4), `LoyaltyLevel.forPosition` (Task 3), `TierIconPalette` (Task 3), `TierLevelIcon` (Task 5).
- Produces: `showTierIconPickerSheet(BuildContext, String? currentKey) -> Future<String?>`.

- [ ] **Step 1: Écrire le test (avant d'implémenter)**

Créer `test/features/merchant/widgets/tier_editor_form_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/features/merchant/widgets/tier_editor_form.dart';
import 'package:miva_fid/features/onboarding/models/program_tier.dart';

void main() {
  Future<void> pump(WidgetTester tester, List<ProgramTier> tiers) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TierEditorForm(
          initialTiers: tiers,
          goalUnit: 'tampons',
          onChanged: (_) {},
        ),
      ),
    ));
  }

  testWidgets('positions 1 to 5 show a locked name, no editable field', (tester) async {
    await pump(tester, const [
      ProgramTier(goal: 500, levelName: 'Bronze', rewardDescription: 'A'),
      ProgramTier(goal: 1000, levelName: 'Argent', rewardDescription: 'B'),
    ]);
    // Déplie le premier palier.
    await tester.tap(find.text('Bronze').first);
    await tester.pumpAndSettle();

    expect(find.text('Nom du niveau *'), findsNothing);
    expect(find.text('Niveau : Bronze'), findsOneWidget);
  });

  testWidgets('position 6 shows a free name field and an icon picker trigger', (tester) async {
    await pump(tester, [
      const ProgramTier(goal: 100, levelName: 'Bronze', rewardDescription: 'A'),
      const ProgramTier(goal: 200, levelName: 'Argent', rewardDescription: 'B'),
      const ProgramTier(goal: 300, levelName: 'Or', rewardDescription: 'C'),
      const ProgramTier(goal: 400, levelName: 'Platine', rewardDescription: 'D'),
      const ProgramTier(goal: 500, levelName: 'Fidèle', rewardDescription: 'E'),
      const ProgramTier(goal: 600, levelName: 'Mon Palier Custom', rewardDescription: 'F'),
    ]);
    await tester.tap(find.text('Mon Palier Custom').first);
    await tester.pumpAndSettle();

    expect(find.text('Nom du niveau *'), findsOneWidget);
    expect(find.text('Choisir une icône'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Lancer le test, vérifier qu'il échoue**

Run: `flutter test test/features/merchant/widgets/tier_editor_form_test.dart`
Expected: FAIL — le texte "Niveau : Bronze" et "Choisir une icône" n'existent pas encore dans le widget actuel.

- [ ] **Step 3: Créer le sélecteur d'icône**

Créer `lib/features/merchant/widgets/tier_icon_picker_sheet.dart` :

```dart
import 'package:flutter/material.dart';

import '../../../core/domain/tier_icon_palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Sélecteur d'icône pour un palier au-delà du 5ᵉ (voir `TierEditorForm` —
/// les 5 premiers ont une icône fixe, non modifiable).
Future<String?> showTierIconPickerSheet(BuildContext context, String? currentKey) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choisir une icône', style: AppTextStyles.labelBold()),
            const SizedBox(height: Sp.md),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: Sp.sm,
              crossAxisSpacing: Sp.sm,
              children: [
                for (final option in TierIconPalette.options)
                  _IconTile(
                    option: option,
                    selected: option.key == currentKey,
                    onTap: () => Navigator.pop(context, option.key),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _IconTile extends StatelessWidget {
  final TierIconOption option;
  final bool selected;
  final VoidCallback onTap;
  const _IconTile({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.merchantTint : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.merchant : AppColors.border),
        ),
        child: Icon(option.icon, color: selected ? AppColors.merchant : AppColors.textSecondary),
      ),
    );
  }
}
```

- [ ] **Step 4: Réécrire `TierEditorForm`**

Remplacer le contenu entier de `lib/features/merchant/widgets/tier_editor_form.dart` par :

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/domain/loyalty_level.dart';
import '../../../core/domain/tier_icon_palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/tier_level_icon.dart';
import '../../onboarding/models/program_tier.dart';
import 'tier_icon_picker_sheet.dart';

/// Éditeur de paliers réutilisé par l'onboarding (step2) et les réglages
/// marchand — un palier = objectif + nom de niveau (masqué si un seul
/// palier) + récompense + validité optionnelle.
///
/// Nom/icône des 5 premiers paliers d'un programme multi-palier sont
/// imposés par leur position (`LoyaltyLevel.forPosition`, ordre Bronze <
/// Argent < Or < Platine < Fidèle), non éditables. Au-delà de la position
/// 5, le marchand choisit nom libre + icône (`TierIconPalette`).
class TierEditorForm extends StatefulWidget {
  final List<ProgramTier> initialTiers;
  final String goalUnit;
  final ValueChanged<List<ProgramTier>> onChanged;
  final bool allowEmpty;
  final int goalStep;

  const TierEditorForm({
    super.key,
    required this.initialTiers,
    required this.goalUnit,
    required this.onChanged,
    this.allowEmpty = false,
    this.goalStep = 500,
  });

  @override
  State<TierEditorForm> createState() => TierEditorFormState();
}

class TierEditorFormState extends State<TierEditorForm> {
  final List<TextEditingController> _goalCtrls = [];
  final List<TextEditingController> _levelNameCtrls = [];
  final List<TextEditingController> _descCtrls = [];
  final List<TextEditingController> _validityCtrls = [];
  final List<String?> _iconKeys = [];
  final List<bool> _isExpanded = [];
  final List<bool> _revealReward = [];

  @override
  void initState() {
    super.initState();
    final tiers = widget.initialTiers.isEmpty && !widget.allowEmpty
        ? [const ProgramTier(goal: 10, rewardDescription: '')]
        : widget.initialTiers;
    for (int i = 0; i < tiers.length; i++) {
      _addController(tiers[i], expanded: false);
    }
  }

  void _addController(ProgramTier tier, {bool expanded = true}) {
    _goalCtrls.add(TextEditingController(text: tier.goal.toString()));
    _levelNameCtrls.add(TextEditingController(text: tier.levelName ?? ''));
    _descCtrls.add(TextEditingController(text: tier.rewardDescription));
    _validityCtrls
        .add(TextEditingController(text: tier.validityDays?.toString() ?? ''));
    _iconKeys.add(tier.iconKey);
    _isExpanded.add(expanded);
    _revealReward.add(tier.revealReward);
  }

  void _emitChange() {
    widget.onChanged(currentTiers());
  }

  /// Snapshot lisible par l'appelant à tout moment (ex. juste avant soumission).
  List<ProgramTier> currentTiers() {
    final isMultiTier = _goalCtrls.length > 1;
    return List.generate(_goalCtrls.length, (i) {
      final position = i + 1;
      final isLocked = position <= 5;
      return ProgramTier(
        goal: int.tryParse(_goalCtrls[i].text.trim()) ?? 10,
        levelName: !isMultiTier
            ? null
            : (isLocked
                ? LoyaltyLevel.forPosition(position)?.label
                : (_levelNameCtrls[i].text.trim().isNotEmpty
                    ? _levelNameCtrls[i].text.trim()
                    : null)),
        iconKey: !isMultiTier || isLocked ? null : _iconKeys[i],
        rewardDescription: _descCtrls[i].text.trim(),
        validityDays: int.tryParse(_validityCtrls[i].text.trim()),
        revealReward: _revealReward[i],
      );
    });
  }

  void addTier() {
    final lastGoal =
        _goalCtrls.isNotEmpty ? (int.tryParse(_goalCtrls.last.text) ?? 10) : 10;
    setState(() {
      for (int i = 0; i < _isExpanded.length; i++) {
        _isExpanded[i] = false;
      }
      _addController(ProgramTier(goal: lastGoal + widget.goalStep, rewardDescription: ''), expanded: true);
    });
    _emitChange();
  }

  void removeTier(int index) {
    if (_goalCtrls.length <= (widget.allowEmpty ? 0 : 1)) return;
    setState(() {
      _goalCtrls[index].dispose();
      _levelNameCtrls[index].dispose();
      _descCtrls[index].dispose();
      _validityCtrls[index].dispose();
      _goalCtrls.removeAt(index);
      _levelNameCtrls.removeAt(index);
      _descCtrls.removeAt(index);
      _validityCtrls.removeAt(index);
      _iconKeys.removeAt(index);
      _isExpanded.removeAt(index);
      _revealReward.removeAt(index);
    });
    _emitChange();
  }

  @override
  void dispose() {
    for (final c in [..._goalCtrls, ..._levelNameCtrls, ..._descCtrls, ..._validityCtrls]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMultiTier = _goalCtrls.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Vos paliers', style: AppTextStyles.labelBold()),
            Text(
              '${_goalCtrls.length} palier${_goalCtrls.length > 1 ? 's' : ''}',
              style: AppTextStyles.caption()
                  .copyWith(color: AppColors.merchant, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (isMultiTier) ...[
          const SizedBox(height: Sp.xs),
          Text(
            'Chaque palier attribue un niveau et débloque sa propre '
            'récompense, sans jamais redescendre une fois atteint. Les 5 '
            'premiers niveaux (Bronze, Argent, Or, Platine, Fidèle) sont '
            'fixes ; au-delà, vous choisissez le nom et l\'icône.',
            style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: Sp.sm),
        if (widget.allowEmpty && _goalCtrls.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Sp.sm),
            child: Text(
              'Aucun palier configuré — le cashback fonctionne normalement sans palier.',
              style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
            ),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _goalCtrls.length,
          separatorBuilder: (_, __) => const SizedBox(height: Sp.md),
          itemBuilder: (context, index) {
            final isExpanded = _isExpanded[index];
            final position = index + 1;
            final isLocked = position <= 5;
            final fixedLevel = isLocked ? LoyaltyLevel.forPosition(position) : null;
            final levelName = _levelNameCtrls[index].text.trim();
            final goal = _goalCtrls[index].text.trim();
            final reward = _descCtrls[index].text.trim();

            final summaryTitle = !isMultiTier
                ? 'Palier ${index + 1}'
                : (isLocked
                    ? fixedLevel!.label
                    : (levelName.isNotEmpty ? levelName : 'Palier ${index + 1}'));
            String summarySubtitle = '';
            if (goal.isNotEmpty && reward.isNotEmpty) {
              summarySubtitle = '$goal ${widget.goalUnit} • $reward';
            } else if (goal.isNotEmpty) {
              summarySubtitle = '$goal ${widget.goalUnit}';
            } else if (reward.isNotEmpty) {
              summarySubtitle = reward;
            } else {
              summarySubtitle = 'Configurer ce palier';
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isExpanded ? AppColors.merchant : AppColors.border,
                    width: isExpanded ? 2 : 1),
                boxShadow: [
                  BoxShadow(
                    color: (isExpanded ? AppColors.merchant : Colors.black)
                        .withValues(alpha: isExpanded ? 0.08 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isExpanded[index] = !isExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(Sp.md),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isExpanded ? AppColors.merchantTint : AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: !isMultiTier
                                    ? const Icon(Icons.flag_outlined, size: 20)
                                    : TierLevelIcon(
                                        position: isLocked ? position : null,
                                        iconKey: isLocked ? null : _iconKeys[index],
                                        size: 20,
                                      ),
                              ),
                              const SizedBox(width: Sp.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      summaryTitle,
                                      style: AppTextStyles.bodyMd().copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isExpanded ? AppColors.merchant : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (!isExpanded) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        summarySubtitle,
                                        style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (_goalCtrls.length > 1)
                                IconButton(
                                  icon: Icon(LucideIcons.trash2, size: isExpanded ? 20 : 18, color: isExpanded ? AppColors.danger : AppColors.textSecondary),
                                  onPressed: () => removeTier(index),
                                  tooltip: 'Supprimer ce palier',
                                ),
                              const SizedBox(width: Sp.xs),
                              Icon(
                                isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                size: 20,
                                color: isExpanded ? AppColors.merchant : AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox(width: double.infinity, height: 0),
                      secondChild: Padding(
                        padding: const EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, Sp.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: Sp.md),
                            AppInput(
                              label: 'Objectif (${widget.goalUnit}) *',
                              hint: 'Ex: 500',
                              controller: _goalCtrls[index],
                              keyboardType: TextInputType.number,
                              prefixIcon: LucideIcons.target,
                              accentColor: AppColors.merchant,
                              onChanged: (_) {
                                setState(() {});
                                _emitChange();
                              },
                              validator: (v) {
                                final val = v?.trim() ?? '';
                                if (val.isEmpty) return "L'objectif est obligatoire";
                                final parsed = int.tryParse(val);
                                if (parsed == null || parsed <= 0) {
                                  return 'Veuillez entrer un nombre supérieur à 0';
                                }
                                if (index > 0) {
                                  final prev = int.tryParse(_goalCtrls[index - 1].text.trim());
                                  if (prev != null && parsed <= prev) {
                                    return 'Doit être supérieur au palier précédent ($prev)';
                                  }
                                }
                                return null;
                              },
                            ),
                            if (isMultiTier) ...[
                              const SizedBox(height: Sp.sm),
                              if (isLocked) ...[
                                _LockedLevelPreview(level: fixedLevel!),
                              ] else ...[
                                AppInput(
                                  label: 'Nom du niveau *',
                                  hint: 'Ex : Ambassadeur, Légende',
                                  controller: _levelNameCtrls[index],
                                  prefixIcon: LucideIcons.award,
                                  accentColor: AppColors.merchant,
                                  onChanged: (_) {
                                    setState(() {});
                                    _emitChange();
                                  },
                                  validator: (v) => (v?.trim() ?? '').isEmpty
                                      ? 'Le nom du niveau est obligatoire'
                                      : null,
                                ),
                                const SizedBox(height: Sp.sm),
                                _IconPickerField(
                                  iconKey: _iconKeys[index],
                                  onPick: () async {
                                    final picked = await showTierIconPickerSheet(context, _iconKeys[index]);
                                    if (picked != null) {
                                      setState(() => _iconKeys[index] = picked);
                                      _emitChange();
                                    }
                                  },
                                ),
                              ],
                            ],
                            const SizedBox(height: Sp.sm),
                            AppInput(
                              label: 'Récompense offerte *',
                              hint: 'Ex : 1 café offert, 10% de réduction',
                              controller: _descCtrls[index],
                              prefixIcon: LucideIcons.gift,
                              accentColor: AppColors.merchant,
                              maxLength: 255,
                              onChanged: (_) {
                                setState(() {});
                                _emitChange();
                              },
                              validator: (v) => (v?.trim() ?? '').isEmpty
                                  ? 'La description de la récompense est obligatoire'
                                  : null,
                            ),
                            const SizedBox(height: Sp.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Récompense surprise 🎁',
                                            style: AppTextStyles.caption()
                                                .copyWith(fontWeight: FontWeight.bold)),
                                        Text(
                                          'Cacher ce palier au client jusqu\'à ce qu\'il le débloque.',
                                          style: AppTextStyles.caption()
                                              .copyWith(color: AppColors.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: !_revealReward[index],
                                    onChanged: (hide) {
                                      setState(() => _revealReward[index] = !hide);
                                      _emitChange();
                                    },
                                    activeThumbColor: AppColors.merchant,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: Sp.sm),
                            AppInput(
                              label: 'Validité (jours, optionnel)',
                              hint: "Ex: 30 — vide = pas d'expiration",
                              controller: _validityCtrls[index],
                              keyboardType: TextInputType.number,
                              prefixIcon: LucideIcons.calendarClock,
                              accentColor: AppColors.merchant,
                              onChanged: (_) => _emitChange(),
                              validator: (v) {
                                final trimmed = v?.trim() ?? '';
                                if (trimmed.isEmpty) return null;
                                final parsed = int.tryParse(trimmed);
                                if (parsed == null || parsed <= 0) {
                                  return 'Veuillez entrer un nombre de jours supérieur à 0';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Aperçu non modifiable du nom/icône imposés pour les 5 premiers paliers
/// (Bronze/Argent/Or/Platine/Fidèle).
class _LockedLevelPreview extends StatelessWidget {
  final LoyaltyLevel level;
  const _LockedLevelPreview({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(level.icon, size: 18, color: level.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Niveau : ${level.label}', style: AppTextStyles.bodyMd()),
          ),
          Icon(LucideIcons.lock, size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

/// Déclencheur du sélecteur d'icône pour un palier custom (position > 5).
class _IconPickerField extends StatelessWidget {
  final String? iconKey;
  final VoidCallback onPick;
  const _IconPickerField({required this.iconKey, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final option = TierIconPalette.byKey(iconKey);
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(option.icon, size: 18, color: AppColors.merchant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                iconKey == null ? 'Choisir une icône' : option.label,
                style: AppTextStyles.bodyMd(),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Lancer le test, vérifier qu'il passe**

Run: `flutter test test/features/merchant/widgets/tier_editor_form_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/merchant/widgets/tier_editor_form.dart lib/features/merchant/widgets/tier_icon_picker_sheet.dart test/features/merchant/widgets/tier_editor_form_test.dart
git commit -m "feat: verrouille nom/icone des 5 premiers paliers, ajoute le picker pour les paliers custom"
```

---

## Task 7: Rendu client — remplace les emoji par `TierLevelIcon`

**Repo:** `Miva_Fid`

**Files:**
- Modify: `lib/features/client/wallet/widgets/card_face_content.dart`
- Modify: `lib/features/client/card_detail/card_detail_screen.dart`

**Interfaces:**
- Consumes: `TierLevelIcon` (Task 5), `CardTier.position`/`iconKey` (Task 4).

- [ ] **Step 1: `card_face_content.dart` — badge de niveau sur le logo**

Dans `lib/features/client/wallet/widgets/card_face_content.dart`, ajouter l'import en haut du fichier (après les imports existants) :

```dart
import '../../../../core/widgets/tier_level_icon.dart';
```

Remplacer (ligne 80) :

```dart
                  levelIcon: currentTier?.icon,
```

par :

```dart
                  levelPosition: currentTier?.position,
                  levelIconKey: currentTier?.iconKey,
```

Remplacer la classe `_CardLogo` (lignes 151-264) :

```dart
class _CardLogo extends StatelessWidget {
  final String? logoUrl;
  final String restaurantName;
  final Color textColor;
  final bool compact;
  final String? levelIcon;

  const _CardLogo({
    required this.logoUrl,
    required this.restaurantName,
    required this.textColor,
    required this.compact,
    this.levelIcon,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 38.0;
    final medallion = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14)),
          child: _content(size),
        ),
      ),
    );

    if (levelIcon == null) return medallion;

    // Badge de niveau ancré côté gauche de la carte, sur le logo — pas en
    // bas de carte : dans les cartes courtes/compactes, la ligne de niveau
    // en pied de carte se faisait pousser hors cadre ou wrap.
    final badgeSize = compact ? 15.0 : 18.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        medallion,
        Positioned(
          left: -4,
          bottom: -4,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.95),
              border: Border.all(color: textColor.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              levelIcon!,
              style: TextStyle(fontSize: badgeSize * 0.62, height: 1),
            ),
          ),
        ),
      ],
    );
  }
```

par :

```dart
class _CardLogo extends StatelessWidget {
  final String? logoUrl;
  final String restaurantName;
  final Color textColor;
  final bool compact;
  final int? levelPosition;
  final String? levelIconKey;

  const _CardLogo({
    required this.logoUrl,
    required this.restaurantName,
    required this.textColor,
    required this.compact,
    this.levelPosition,
    this.levelIconKey,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 38.0;
    final medallion = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14)),
          child: _content(size),
        ),
      ),
    );

    if (levelPosition == null && levelIconKey == null) return medallion;

    // Badge de niveau ancré côté gauche de la carte, sur le logo — pas en
    // bas de carte : dans les cartes courtes/compactes, la ligne de niveau
    // en pied de carte se faisait pousser hors cadre ou wrap.
    final badgeSize = compact ? 15.0 : 18.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        medallion,
        Positioned(
          left: -4,
          bottom: -4,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.95),
              border: Border.all(color: textColor.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TierLevelIcon(
              position: levelPosition,
              iconKey: levelIconKey,
              size: badgeSize * 0.62,
            ),
          ),
        ),
      ],
    );
  }
```

(Le reste de la classe `_CardLogo` — `_content()` et `_monogram()` — ne change pas.)

- [ ] **Step 2: `card_detail_screen.dart` — import**

Ajouter l'import en haut du fichier :

```dart
import '../../../core/widgets/tier_level_icon.dart';
```

- [ ] **Step 3: `_TierRoadmapRow` — remplacer l'emoji par l'icône**

Remplacer (ligne 550) :

```dart
          child: Text(tier.icon, style: const TextStyle(fontSize: 16)),
```

par :

```dart
          child: TierLevelIcon(position: tier.position, iconKey: tier.iconKey, size: 18),
```

- [ ] **Step 4: `_LockedTierCard` — distinguer palier réel vs aperçu mono-palier**

Remplacer les deux call sites (lignes 137-147) :

```dart
                              if (showLockedTiers) {
                                return _LockedTierCard(
                                  t: t,
                                  tier: lockedTiers[i - rewards.length],
                                );
                              }
                              return _LockedTierCard(
                                t: t,
                                tier: card.nextReward,
                                fallbackGoal: card.stampsGoal,
                              );
```

par :

```dart
                              if (showLockedTiers) {
                                return _LockedTierCard(
                                  t: t,
                                  tier: lockedTiers[i - rewards.length],
                                  isLevelTier: true,
                                );
                              }
                              return _LockedTierCard(
                                t: t,
                                tier: card.nextReward,
                                fallbackGoal: card.stampsGoal,
                                isLevelTier: false,
                              );
```

Remplacer la classe `_LockedTierCard` (lignes 658-708) :

```dart
class _LockedTierCard extends StatelessWidget {
  final AppLocalizations t;
  final CardTier? tier;
  final int? fallbackGoal;
  const _LockedTierCard({required this.t, this.tier, this.fallbackGoal});

  @override
  Widget build(BuildContext context) {
    final goal = tier?.goal ?? fallbackGoal;
    final description = tier?.rewardDescription ?? '';
    final title = description.isNotEmpty
        ? (tier != null ? '${tier!.icon} $description' : description)
        : t.cardDetailDefaultOfferTitle;

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 250,
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusBadge(
                label: t.rewardStatusLocked,
                tone: StatusTone.neutral,
                icon: LucideIcons.lock,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.titleMedium().copyWith(fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (goal != null) ...[
                const SizedBox(height: 3),
                Text(
                  'Objectif : ${formatGroupedNumber(goal)}',
                  style: AppTextStyles.bodySmall(
                      color: AppColors.inkMuted(opacity: 0.7)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

par :

```dart
class _LockedTierCard extends StatelessWidget {
  final AppLocalizations t;
  final CardTier? tier;
  final int? fallbackGoal;

  /// `true` quand [tier] est un vrai palier de la roadmap de niveau (icône
  /// pilotée par sa position/icon_key) ; `false` pour l'aperçu générique de
  /// prochaine récompense d'un programme mono-palier (pas de niveau, voir
  /// `LoyaltyTierService` — icône générique de cadeau).
  final bool isLevelTier;

  const _LockedTierCard({
    required this.t,
    this.tier,
    this.fallbackGoal,
    required this.isLevelTier,
  });

  @override
  Widget build(BuildContext context) {
    final goal = tier?.goal ?? fallbackGoal;
    final description = tier?.rewardDescription ?? '';
    final title = description.isNotEmpty ? description : t.cardDetailDefaultOfferTitle;

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 250,
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusBadge(
                label: t.rewardStatusLocked,
                tone: StatusTone.neutral,
                icon: LucideIcons.lock,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tier != null) ...[
                    isLevelTier
                        ? TierLevelIcon(position: tier!.position, iconKey: tier!.iconKey, size: 15)
                        : Icon(Icons.card_giftcard, size: 15, color: AppColors.inkMuted(opacity: 0.6)),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.titleMedium().copyWith(fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (goal != null) ...[
                const SizedBox(height: 3),
                Text(
                  'Objectif : ${formatGroupedNumber(goal)}',
                  style: AppTextStyles.bodySmall(
                      color: AppColors.inkMuted(opacity: 0.7)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: `_CurrentLevelCard` — remplacer l'emoji par défaut**

Remplacer (ligne 746) :

```dart
            child: Text(tier?.icon ?? '⭐', style: const TextStyle(fontSize: 16)),
```

par :

```dart
            child: TierLevelIcon(position: tier?.position, iconKey: tier?.iconKey, size: 18),
```

- [ ] **Step 6: Vérifier — plus aucune référence à `CardTier.icon` dans le repo**

Run: `grep -rn "\.icon\b" lib/features/client --include=*.dart | grep -i tier`
Expected: aucune occurrence restante référençant `tier.icon`/`CardTier.icon` (uniquement `tier.iconKey`/`level.icon` d'`AppColors`/Material, à vérifier manuellement s'il y a un faux positif).

Run: `flutter analyze`
Expected: PASS (0 erreur sur `card_face_content.dart`/`card_detail_screen.dart`)

- [ ] **Step 7: Commit**

```bash
git add lib/features/client/wallet/widgets/card_face_content.dart lib/features/client/card_detail/card_detail_screen.dart
git commit -m "feat: remplace les emoji de niveau par TierLevelIcon cote client"
```

---

## Task 8: Rendu marchand — remplace les emoji/texte brut par `TierLevelIcon`

**Repo:** `Miva_Fid`

**Files:**
- Modify: `lib/features/merchant/widgets/client_card_sheet.dart`
- Modify: `lib/features/merchant/screens/client_detail_screen.dart`

**Interfaces:**
- Consumes: `TierLevelIcon` (Task 5), `LoyaltyCardModel.levelPosition`/`levelIconKey` (Task 4).

- [ ] **Step 1: `client_card_sheet.dart` — import**

Ajouter l'import en haut du fichier :

```dart
import '../../../core/widgets/tier_level_icon.dart';
```

- [ ] **Step 2: Passer position/icon_key au badge**

Remplacer (ligne 365) :

```dart
                                    _LevelBadge(name: card.levelName!),
```

par :

```dart
                                    _LevelBadge(
                                      name: card.levelName!,
                                      position: card.levelPosition,
                                      iconKey: card.levelIconKey,
                                    ),
```

Remplacer la classe `_LevelBadge` (lignes 514-536) :

```dart
class _LevelBadge extends StatelessWidget {
  final String name;
  const _LevelBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.merchantTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        name.toUpperCase(),
        style: AppTextStyles.caption().copyWith(
          color: AppColors.merchant,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
```

par :

```dart
class _LevelBadge extends StatelessWidget {
  final String name;
  final int? position;
  final String? iconKey;
  const _LevelBadge({required this.name, this.position, this.iconKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.merchantTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TierLevelIcon(position: position, iconKey: iconKey, size: 11, color: AppColors.merchant),
          const SizedBox(width: 4),
          Text(
            name.toUpperCase(),
            style: AppTextStyles.caption().copyWith(
              color: AppColors.merchant,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: `client_detail_screen.dart` — import + fallback 'Bronze' incorrect**

Ajouter l'import en haut du fichier :

```dart
import '../../../core/widgets/tier_level_icon.dart';
```

Remplacer (ligne 122) :

```dart
            final clientTier = level?['name'] as String? ?? 'Bronze';
```

par :

```dart
            final clientTier = level?['name'] as String?;
            final clientTierPosition = level?['position'] as int?;
            final clientTierIconKey = level?['icon_key'] as String?;
```

- [ ] **Step 4: Masquer le badge/mini-stat quand il n'y a pas de niveau (mono-palier)**

Remplacer (lignes 231-246) :

```dart
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningTint,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      clientTier.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.warningDark,
                                      ),
                                    ),
                                  ),
```

par :

```dart
                                  if (clientTier != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.warningTint,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TierLevelIcon(
                                            position: clientTierPosition,
                                            iconKey: clientTierIconKey,
                                            size: 11,
                                            color: AppColors.warningDark,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            clientTier.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.warningDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
```

Remplacer (lignes 385-391) :

```dart
                            Expanded(
                              child: _buildMiniStat(
                                icon: LucideIcons.medal,
                                value: clientTier,
                                label: 'Niveau',
                                isSmallValue: true,
                              ),
                            ),
```

par :

```dart
                            Expanded(
                              child: _buildMiniStat(
                                icon: clientTier == null ? LucideIcons.medal : null,
                                iconWidget: clientTier == null
                                    ? null
                                    : TierLevelIcon(
                                        position: clientTierPosition,
                                        iconKey: clientTierIconKey,
                                        size: 18,
                                      ),
                                value: clientTier ?? '—',
                                label: 'Niveau',
                                isSmallValue: true,
                              ),
                            ),
```

Remplacer la signature/le corps de `_buildMiniStat` (lignes 465-504) :

```dart
  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    bool isSmallValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
```

par :

```dart
  Widget _buildMiniStat({
    IconData? icon,
    Widget? iconWidget,
    required String value,
    required String label,
    bool isSmallValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          iconWidget ?? Icon(icon, size: 18, color: AppColors.textSecondary),
```

(Le reste de `_buildMiniStat` — affichage de `value`/`label` — ne change pas.)

- [ ] **Step 5: Vérifier**

Run: `flutter analyze`
Expected: PASS (0 erreur sur `client_card_sheet.dart`/`client_detail_screen.dart`)

- [ ] **Step 6: Commit**

```bash
git add lib/features/merchant/widgets/client_card_sheet.dart lib/features/merchant/screens/client_detail_screen.dart
git commit -m "feat: remplace le badge de niveau texte/emoji par TierLevelIcon cote marchand"
```

---

## Task 9: Vérification finale

**Repo:** les deux

**Files:** aucun (vérification uniquement)

- [ ] **Step 1: Suite complète backend**

Run (dans `restaurant-loyalty-api`): `php artisan migrate:fresh && php artisan test`
Expected: PASS, 0 échec.

- [ ] **Step 2: Suite complète Flutter**

Run (dans `Miva_Fid`): `flutter analyze && flutter test`
Expected: PASS, 0 erreur d'analyse, 0 échec de test.

- [ ] **Step 3: Recherche résiduelle d'emoji de niveau**

Run: `grep -rn "🥉\|🥈\|🥇\|💎\|👑" lib/ app/ 2>/dev/null` (lancer depuis chaque repo)
Expected: aucune occurrence restante (en dehors de commentaires historiques éventuels, à nettoyer si trouvés).

- [ ] **Step 4: Relire le spec et cocher chaque exigence**

Relire `docs/superpowers/specs/2026-08-26-niveaux-paliers-icones-design.md` section par section et confirmer qu'une tâche de ce plan couvre chaque point (icônes unifiées, verrouillage 1-5, palette 6+, migration de données, hors périmètre inchangé). Aucune étape de code ici — juste une relecture croisée.
