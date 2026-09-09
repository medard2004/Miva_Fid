# Niveaux de paliers — icônes et noms unifiés

Date : 2026-08-26
Statut : approuvé (design), en attente d'implémentation

## Contexte

L'app a aujourd'hui **deux systèmes de niveau parallèles et incohérents** :

1. **`LoyaltyLevel`** (`lib/core/domain/loyalty_level.dart`) : enum avec de vraies `IconData` Material + couleurs, mais utilisé **uniquement** côté marchand dans le filtre de `clients_screen.dart` et le graphique de `dashboard_screen.dart`.
2. **Système emoji par rang** : `tierRankIcons = ['🥉','🥈','🥇','💎','👑']` (`tier_editor_form.dart`), miroir exact de `LoyaltyTierService::ICONS`/`iconForRank()` côté backend (`restaurant-loyalty-api`). Utilisé partout ailleurs : carte client (`card_face_content.dart`), détail carte (`card_detail_screen.dart`), fiche client marchand (`client_card_sheet.dart`, `client_detail_screen.dart` — ce dernier avec un fallback en dur `'Bronze'`).

Le rang→emoji actuel est en plus **non intuitif** : il étire l'échelle sur les 5 icônes quel que soit le nombre de paliers configurés (un programme à 2 paliers saute directement de 🥉 à 👑, sans jamais afficher 🥈/🥇/💎).

Le nom de niveau (`level_name`) est aujourd'hui du texte libre saisi par le marchand pour chaque palier, et la clé canonique (`bronze|silver|gold|platinum|custom`) est dérivée côté backend par matching flou de sous-chaînes sur ce texte (`LoyaltyTierService::levelKey()`).

## Objectif

Un seul système d'icônes/noms, cohérent sur toute l'app (marchand + client) :

- 5 niveaux fixes, dans l'ordre croissant : **Bronze, Argent, Or, Platine, Fidèle**.
- Nom et icône des 5 premiers paliers **non modifiables** par le marchand.
- Au-delà de 5 paliers, le marchand choisit nom + icône (palette fournie) pour chaque palier supplémentaire.
- 1 seul palier configuré = pas de niveau affiché (comportement déjà existant, inchangé).
- Suppression complète du système emoji.

## Règle d'attribution des niveaux

Pour un programme à **N paliers** (N ≥ 2), trié par `goal` croissant, le palier en position `i` (1-based) reçoit :

- Si `i ≤ 5` : le i-ème niveau de la liste fixe `[Bronze, Argent, Or, Platine, Fidèle]` (nom + icône imposés, non éditables).
- Si `i > 5` : nom libre + icône choisie par le marchand dans une palette dédiée.

Exemples :
- N=2 → Bronze, Argent
- N=3 → Bronze, Argent, Or
- N=4 → Bronze, Argent, Or, Platine
- N=5 → Bronze, Argent, Or, Platine, Fidèle
- N=6 → Bronze, Argent, Or, Platine, Fidèle, *[palier custom 6]*

N=1 → aucun niveau affiché (comportement existant `LoyaltyTierService`, non modifié).

## Design — Flutter (`Miva_Fid`)

### `LoyaltyLevel` (déjà existant, `lib/core/domain/loyalty_level.dart`)

Devient l'unique source d'icônes/couleurs/libellés de l'app, pour marchand ET client. Son ordre de déclaration (`bronze, silver, gold, platinum, custom`) correspond exactement à l'ordre canonique métier (Bronze, Argent, Or, Platine, Fidèle) : `LoyaltyLevel.values[position - 1]` donne directement le bon niveau pour toute position 1..5. Aucun changement de structure nécessaire à cet enum, seulement de nouveaux appelants.

### Palette d'icônes pour paliers 6+

Nouveau fichier (ex. `lib/core/domain/tier_icon_palette.dart`) : liste de paires `(key, IconData, label)`, Material Icons distincts des 5 déjà utilisés par `LoyaltyLevel`. Proposition (~12) : `local_fire_department, bolt, favorite, shield, rocket_launch, auto_awesome, verified, celebration, whatshot, grade, thumb_up, sports_score`. Une couleur par défaut cohérente avec le thème marchand (pas besoin d'une couleur par icône comme pour les 5 fixes).

### `ProgramTier` (`lib/features/onboarding/models/program_tier.dart`)

Ajout d'un champ optionnel `iconKey` (String?), sérialisé `icon_key`. Toujours `null` pour position ≤ 5 (calculé, pas stocké côté client) ; libre pour position > 5.

### `TierEditorForm` (`lib/features/merchant/widgets/tier_editor_form.dart`)

- Suppression de `tierRankIcons`/`iconForTierRank`.
- Pour un palier en position ≤ 5 : le nom et l'icône sont affichés en lecture seule (`LoyaltyLevel.values[position-1]`), recalculés dynamiquement à chaque ajout/suppression de palier (les positions peuvent bouger). Le champ "Nom du niveau" n'est pas affiché pour ces paliers.
- Pour un palier en position > 5 : champ nom libre (comportement actuel) + nouveau sélecteur d'icône (bottom sheet grille, même pattern que le picker d'emoji de tampon dans `programme_design_screen.dart`), piochant dans la palette ci-dessus.

### Suppression du rendu emoji

Remplacer `Text(tier.icon, ...)` / `Text(levelIcon!, ...)` par `Icon(loyaltyLevel.icon, color: loyaltyLevel.color)` (ou la palette custom) dans :
- `lib/features/client/wallet/widgets/card_face_content.dart` (`_CardLogo`)
- `lib/features/client/card_detail/card_detail_screen.dart` (`_TierRoadmapRow`, `_LockedTierCard`, `_CurrentLevelCard`)
- `lib/features/merchant/widgets/client_card_sheet.dart` (`_LevelBadge`)
- `lib/features/merchant/screens/client_detail_screen.dart` (badge niveau + fallback `'Bronze'` en dur → dérivé de la position réelle)

### Modèles consommant l'API

- `lib/features/client/models/loyalty_card.dart` (`CardTier.icon`) : le champ ne reçoit plus un emoji mais sert à véhiculer `icon_key` (custom, position > 5) — le rendu réel se fait via position + `LoyaltyLevel`/palette côté Flutter, pas via une chaîne affichée telle quelle.
- `lib/models/loyalty_card_model.dart` : `level` gagne un champ `position` (int?, rang 1-based du palier courant) en plus de `name`/`key`/`percentToNext`/`isMaxLevel`.

## Design — Backend (`restaurant-loyalty-api`)

### Migration de schéma

Nouvelle colonne nullable `icon_key` (string) sur `loyalty_program_tiers`. `null` par défaut, utilisée uniquement pour les paliers en position > 5.

### `LoyaltyTierService`

- Suppression de `ICONS` (const) et `iconForRank()` — devenus inutiles, l'icône n'est plus calculée par rang côté serveur.
- `tiers()` : chaque élément renvoyé inclut désormais `icon_key` (valeur brute de la colonne).
- `resolve()` : le `level` retourné inclut la position (rang 1-based, calculée depuis l'index de `$current` dans la liste triée) en plus de `level_name`/`percent_to_next`/`is_max_level`. Permet à Flutter de retrouver la bonne icône pour le palier courant même au-delà de la position 5, sans dépendre du matching flou par nom (qui renvoie `custom` pour tout nom non reconnu, donc ne distingue pas plusieurs paliers custom entre eux).
- `nextReward()` : ne renvoie plus de champ `icon` calculé (emoji) — position déjà disponible via l'index dans `tiers()`.
- **Aucun changement à `levelKey()`** : le matching flou nom→clé (`bronze|silver|gold|platinum|custom`) continue de fonctionner sans modification pour les 5 premiers paliers, puisque leur `level_name` sera désormais toujours exactement "Bronze"/"Argent"/"Or"/"Platine"/"Fidèle" (le mot "Fidèle" ne matchant aucun des 4 patterns, il retombe naturellement sur la clé `custom`, qui correspond déjà au libellé "Fidèle" côté `LoyaltyLevel`).

### Migration de données (commande Artisan one-shot)

Pour chaque programme, trier ses paliers par `goal` croissant et renommer de force le `level_name` des paliers en position 1 à 5 vers les noms canoniques (`Bronze`/`Argent`/`Or`/`Platine`/`Fidèle`), **en écrasant tout nom marchand existant** (décision validée : cohérence immédiate sur toute l'app plutôt que coexistence de deux régimes). Les paliers en position 6+ gardent leur `level_name` actuel tel quel ; `icon_key` reste `null` pour eux (le marchand devra en choisir une via le nouveau picker — aucune icône par défaut imposée).

## Hors périmètre

- Le filtre marchand par niveau (`clients_screen.dart`, `MerchantDashboardController` côté API) n'est pas modifié : il continue à filtrer sur `level.key`, qui reste `bronze|silver|gold|platinum|custom` — les paliers custom au-delà de 5 restent regroupés sous `custom` dans ce filtre (edge case rare, non demandé).
- Pas de changement au comportement mono-palier (1 palier = pas de niveau affiché).
- Pas de changement aux seuils (`goal`), à la récompense, à la validité ou au mécanisme "récompense surprise" des paliers.

## Tests

- Backend : tests existants sur `LoyaltyTierService`/`resolve()`/`tiers()` à mettre à jour (suppression des assertions sur emoji, ajout d'assertions sur `position`/`icon_key`). Test de la commande de migration de données (renommage forcé positions 1-5, préservation positions 6+).
- Flutter : tests existants sur `LoyaltyCardModel`/`copyWith` à étendre pour le nouveau champ `position`. Test manuel de `TierEditorForm` (verrouillage 1-5, picker 6+) et du rendu carte client/marchand pour 2, 3, 4, 5 et 6 paliers.
