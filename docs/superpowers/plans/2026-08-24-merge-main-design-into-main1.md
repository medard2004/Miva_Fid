# Fusion design main → main1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Récupérer sélectivement 4 éléments de design/logique de la branche `main` vers `main1` (qui a le vrai backend), sans régresser le backend fonctionnel de `main1`.

**Architecture:** Ce n'est pas un `git merge` classique — c'est un portage fichier par fichier. Pour chaque tâche, soit le fichier de `main` est copié tel quel (quand ses imports/providers résolvent déjà sur `main1`), soit il est réécrit en gardant le backend de `main1` et en n'empruntant que la structure visuelle de `main`. Chaque tâche est vérifiée avec `flutter analyze <fichier(s)>` (pas de suite de tests widgets existante dans ce repo pour ces écrans — `flutter analyze` + relecture manuelle du diff tient lieu de red/green ici) puis un commit dédié.

**Tech Stack:** Flutter 3.41, Riverpod (riverpod_annotation/codegen), go_router (StatefulShellRoute), lucide_icons_flutter, flutter_animate.

**Spec:** Demande utilisateur (conversation), résumée en 5 points :
1. Page marchande affichée en premier = écran de validation (scan), pas le dashboard. Bottom nav bar client déjà identique sur les deux branches (rien à porter).
2. Réorganiser la page "Plus"/réglages marchand (`more_screen.dart` sur main1) en s'inspirant de l'organisation de `main`, sans rien porter qui n'a pas d'écran cible sur main1.
3. Récupérer le design de la page SMS marchand.
4. Page de validation de tampon : main1 a déjà scan + code manuel (accepte code carte/qr_token/id client), résolu côté serveur — confirmé suffisant par l'utilisateur, **aucun portage requis**.
5. Tout doit rester fonctionnel après la fusion.

## Global Constraints

- Ne jamais réintroduire d'appel Supabase direct depuis l'UI — main1 passe tout par ses providers/services API dédiés (`merchantDashboardServiceProvider`, `merchantAuthProvider`, etc.). Quand un fichier de `main` contient un appel Supabase direct, il ne doit PAS être copié tel quel : on ne garde que sa structure visuelle.
- Ne jamais créer une route ou un écran qui n'existe pas déjà sur `main1` (pas de nouvelles pages "Horaires", "Réseaux sociaux", "Confidentialité/CGU" — ces routes n'existent pas côté main1 et sont hors scope).
- Chaque tâche se termine par `flutter analyze` sur les fichiers touchés (0 nouvelle erreur) et un commit séparé.
- Travailler sur la branche `main1` (déjà checked out, working tree propre au démarrage).

---

## Recherche préalable (déjà faite, ne pas refaire)

- `bottom_nav_bar.dart` (client) est byte-identique sur les deux branches → **aucune action**.
- `app_shell.dart` (client) : main1 est déjà plus avancé (`appBrightnessProvider`) → **aucune action**.
- `sms_campaign_screen.dart` de `main` importe uniquement des fichiers qui existent tels quels sur main1 (`core/widgets/app_button.dart`, `app_dialog.dart`, `app_toast.dart`, `providers/merchant_provider.dart`, `providers/sms_provider.dart`) et appelle les **mêmes noms de provider** (`smsNotifierProvider`, `merchantNotifierProvider`) avec la même signature que main1 → copie de fichier quasi verbatim possible, `sms_provider.dart` de main1 (le vrai backend) ne doit PAS être touché.
- `promo_carousel.dart` + `promo_banner.dart` (client, wallet) : tous leurs imports (`client/core/theme/*`) existent sur main1 → copie verbatim possible.
- `more_screen.dart` (main1) n'a pas d'équivalent 1:1 sur `main` (qui a un `settings_screen.dart` marchand de 580 lignes, avec des routes `/merchant/settings/*` et un appel Supabase direct au sign-out) → **pas de copie de fichier**, seulement une réorganisation manuelle inspirée de la structure à 3 sections de main, réalisée avec les routes déjà existantes sur main1 (`/merchant/more/account`, `/merchant/more/subscription`, `/merchant/more/programme`, `/merchant/more/preferences`).
- Landing marchand : deux points de redirection contrôlent la page affichée après connexion — `lib/features/client/splash/splash_screen.dart:49` et `lib/core/router/app_router.dart:247`. Les opérateurs (non-admin) sont déjà redirigés vers `/merchant/validate` par le garde-fou de `app_router.dart:224-229` ; seul le cas "admin" doit changer.

---

### Task 1: Landing marchand = écran de validation (scan)

**Files:**
- Modify: `lib/features/client/splash/splash_screen.dart:49`
- Modify: `lib/core/router/app_router.dart:247`

**Interfaces:**
- Ne change aucune signature, juste la route cible d'une redirection existante.

- [ ] **Step 1: Modifier la redirection post-splash**

Dans `lib/features/client/splash/splash_screen.dart`, remplacer :

```dart
            context.go(switch ((
              restaurant?.hasLoyaltyProgram ?? false,
              restaurant?.hasLocation ?? false,
              restaurant?.hasBusinessInfo ?? false,
            )) {
              (true, _, _) => '/merchant',
              (false, true, _) => '/auth/merchant/step2',
              (false, false, true) => '/auth/merchant/location',
              _ => '/auth/merchant/step1',
            });
```

par :

```dart
            context.go(switch ((
              restaurant?.hasLoyaltyProgram ?? false,
              restaurant?.hasLocation ?? false,
              restaurant?.hasBusinessInfo ?? false,
            )) {
              (true, _, _) => '/merchant/validate',
              (false, true, _) => '/auth/merchant/step2',
              (false, false, true) => '/auth/merchant/location',
              _ => '/auth/merchant/step1',
            });
```

- [ ] **Step 2: Modifier la redirection quand un marchand déjà connecté revisite une route d'entrée**

Dans `lib/core/router/app_router.dart`, remplacer :

```dart
          // `/auth/merchant/success` est l'écran d'arrivée juste après la
          // création du programme : le renvoyer au dashboard priverait le
          // marchand de son QR code et de la feuille comptoir.
          if ((merchantAuth.restaurant?.hasLoyaltyProgram ?? false) &&
              location != '/auth/merchant/success') {
            return '/merchant';
          }
```

par :

```dart
          // `/auth/merchant/success` est l'écran d'arrivée juste après la
          // création du programme : le renvoyer directement à la validation
          // priverait le marchand de son QR code et de la feuille comptoir.
          if ((merchantAuth.restaurant?.hasLoyaltyProgram ?? false) &&
              location != '/auth/merchant/success') {
            return '/merchant/validate';
          }
```

- [ ] **Step 3: Vérifier**

Run: `flutter analyze lib/features/client/splash/splash_screen.dart lib/core/router/app_router.dart`
Expected: aucune nouvelle erreur.

Relire manuellement `lib/core/router/app_router.dart:203-232` : confirmer que le garde-fou `isOperatorReachable` (ligne 225) reste cohérent — il vérifie déjà `location.startsWith('/merchant/validate')`, donc rien d'autre à changer là.

- [ ] **Step 4: Commit**

```bash
git add lib/features/client/splash/splash_screen.dart lib/core/router/app_router.dart
git commit -m "feat: la page de validation devient l'accueil marchand après connexion"
```

---

### Task 2: Carousel promo sur la page d'accueil client (wallet)

**Files:**
- Create: `lib/features/client/wallet/widgets/promo_carousel.dart`
- Create: `lib/features/client/wallet/widgets/promo_banner.dart`
- Modify: `lib/features/client/wallet/wallet_dashboard_screen.dart`

**Interfaces:**
- Produces: `PromoCarousel` (StatefulWidget, pas de paramètre requis) — utilisé par `wallet_dashboard_screen.dart`.

- [ ] **Step 1: Copier les deux fichiers de main tels quels**

```bash
git show main:lib/features/client/wallet/widgets/promo_carousel.dart > lib/features/client/wallet/widgets/promo_carousel.dart
git show main:lib/features/client/wallet/widgets/promo_banner.dart > lib/features/client/wallet/widgets/promo_banner.dart
```

- [ ] **Step 2: Vérifier que les imports résolvent**

Run: `flutter analyze lib/features/client/wallet/widgets/promo_carousel.dart lib/features/client/wallet/widgets/promo_banner.dart`
Expected: aucune erreur (les deux fichiers n'importent que `client/core/theme/*`, déjà présent sur main1).

- [ ] **Step 3: Monter le carousel en tête de la page portefeuille**

Dans `lib/features/client/wallet/wallet_dashboard_screen.dart`, ajouter l'import en haut du fichier (à côté des autres imports `package:miva_fid/features/client/...`) :

```dart
import 'widgets/promo_carousel.dart';
```

Puis, dans le `build`, remplacer :

```dart
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: cards.isEmpty
                      ? _EmptyWallet(
                          t: t, onScan: () => context.push('/client/onboarding/scan'))
                      : LoyaltyCardStack(
                          cards: cards,
                          onCardTap: (card) => context.push('/client/card/${card.id}'),
                        ),
                ),
```

par :

```dart
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PromoCarousel(),
                      const SizedBox(height: 24),
                      cards.isEmpty
                          ? _EmptyWallet(
                              t: t, onScan: () => context.push('/client/onboarding/scan'))
                          : LoyaltyCardStack(
                              cards: cards,
                              onCardTap: (card) => context.push('/client/card/${card.id}'),
                            ),
                    ],
                  ),
                ),
```

Ne pas toucher au `onRefresh:` de ce `RefreshIndicator` — main1 y appelle déjà `ref.read(walletProvider.notifier).loadMine()` (vrai backend), c'est strictement meilleur que le `Future.delayed` cosmétique de `main` : le garder tel quel.

- [ ] **Step 4: Vérifier**

Run: `flutter analyze lib/features/client/wallet/wallet_dashboard_screen.dart`
Expected: aucune nouvelle erreur.

- [ ] **Step 5: Commit**

```bash
git add lib/features/client/wallet/widgets/promo_carousel.dart lib/features/client/wallet/widgets/promo_banner.dart lib/features/client/wallet/wallet_dashboard_screen.dart
git commit -m "feat: ajoute le carousel promo en tête du portefeuille client"
```

---

### Task 3: Design de la page SMS marchand

**Files:**
- Modify (remplacement complet du fichier) : `lib/features/merchant/screens/sms_campaign_screen.dart`
- Ne PAS toucher : `lib/features/merchant/providers/sms_provider.dart`, `lib/models/sms_campaign_model.dart` (le backend réel de main1)

**Interfaces:**
- Consomme : `smsNotifierProvider` (`AsyncValue<List<SmsCampaignModel>>`, méthodes `.sendCampaign({required String message, required String recipientType, DateTime? scheduledAt})` et `.countRecipients(String recipientType)`) — déjà défini par `sms_provider.dart` de main1, signature inchangée.
- Consomme : `merchantNotifierProvider` → `.value?.smsRemaining` (int, déjà présent dans `MerchantModel` de main1).

- [ ] **Step 1: Remplacer le fichier par la version de main**

```bash
git show main:lib/features/merchant/screens/sms_campaign_screen.dart > lib/features/merchant/screens/sms_campaign_screen.dart
```

- [ ] **Step 2: Vérifier qu'aucun appel backend direct ne s'est glissé**

Run: `grep -n "Supabase" lib/features/merchant/screens/sms_campaign_screen.dart`
Expected: aucune correspondance (le fichier de `main` pour cet écran n'appelle jamais Supabase directement — seul `sms_provider.dart`, qu'on ne touche pas, le faisait sur `main`).

- [ ] **Step 3: Vérifier la compilation**

Run: `flutter analyze lib/features/merchant/screens/sms_campaign_screen.dart`
Expected: aucune nouvelle erreur. Si une erreur apparaît sur un symbole absent de main1, corriger l'import concerné avant de continuer (mais l'audit préalable n'en a trouvé aucun).

- [ ] **Step 4: Commit**

```bash
git add lib/features/merchant/screens/sms_campaign_screen.dart
git commit -m "feat: reprend le design de la page campagnes SMS de main sur le backend main1"
```

---

### Task 4: Réorganiser la page "Plus" (réglages marchand)

**Files:**
- Modify (remplacement complet du fichier) : `lib/features/merchant/screens/more_screen.dart`

**Interfaces:**
- Consomme : `merchantNotifierProvider` → `.value?.name`, `.value?.initials`, `.value?.isPro` (déjà utilisés ailleurs, ex. `merchant_shell.dart`).
- Consomme : `merchantAuthProvider.notifier.signOut()` (inchangé par rapport à la version actuelle).
- Routes utilisées (toutes existent déjà sur main1, aucune nouvelle route) : `/merchant/more/account`, `/merchant/more/subscription`, `/merchant/more/programme`, `/merchant/more/preferences`.

- [ ] **Step 1: Remplacer le contenu du fichier**

Remplacer tout le contenu de `lib/features/merchant/screens/more_screen.dart` par :

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../client/providers/settings_provider.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final merchant = ref.watch(merchantNotifierProvider).value;
    final merchantName = merchant?.name ?? 'Votre Commerce';
    final initials = merchant?.initials ?? 'MC';
    final planLabel = (merchant?.isPro ?? false) ? 'Plan Pro' : 'Plan Standard';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Sp.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paramètres',
                style: AppTextStyles.h1().copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Sp.md),

              // En-tête profil
              Container(
                padding: const EdgeInsets.all(Sp.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: Rd.card,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.merchant,
                      child: Text(
                        initials,
                        style: AppTextStyles.monoLg().copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchantName,
                            style: AppTextStyles.labelBold().copyWith(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.merchant.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              planLabel,
                              style: TextStyle(
                                color: AppColors.merchant,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.lg),

              _buildSectionLabel('COMPTE'),
              const SizedBox(height: Sp.sm),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: Rd.card,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: LucideIcons.user,
                      label: 'Compte & Profil',
                      route: '/merchant/more/account',
                    ),
                    const Divider(height: 0, indent: Sp.md),
                    _buildMenuItem(
                      context: context,
                      icon: LucideIcons.creditCard,
                      label: 'Abonnement & Équipe',
                      route: '/merchant/more/subscription',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.lg),

              _buildSectionLabel('FIDÉLISATION'),
              const SizedBox(height: Sp.sm),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: Rd.card,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: LucideIcons.award,
                      label: 'Programme de fidélité',
                      route: '/merchant/more/programme',
                    ),
                    const Divider(height: 0, indent: Sp.md),
                    _buildMenuItem(
                      context: context,
                      icon: LucideIcons.bell,
                      label: 'Préférences',
                      route: '/merchant/more/preferences',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.lg),

              _buildSectionLabel('ASSISTANCE'),
              const SizedBox(height: Sp.sm),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: Rd.card,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: LucideIcons.messageCircle,
                      label: 'Support WhatsApp',
                      color: AppColors.success,
                      onTap: () async {
                        final url = Uri.parse('https://wa.me/22899001122');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                    const Divider(height: 0, indent: Sp.md),
                    _buildMenuItem(
                      context: context,
                      icon: LucideIcons.logOut,
                      label: 'Se déconnecter',
                      color: AppColors.danger,
                      onTap: () async {
                        final confirmed = await AppDialog.confirm(
                          context,
                          title: 'Se déconnecter ?',
                          message: 'Vous devrez vous reconnecter pour accéder à votre espace marchand.',
                          confirmLabel: 'Se déconnecter',
                          destructive: true,
                        );
                        if (!confirmed) return;
                        await ref.read(merchantAuthProvider.notifier).signOut();
                        if (context.mounted) context.go('/auth/merchant/auth');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: Sp.xl),
              Center(
                child: Text(
                  'Miva-Fid v1.0.0 • Lomé, Togo',
                  style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: Sp.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: AppTextStyles.caption().copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? route,
    VoidCallback? onTap,
    Color? color,
  }) {
    final itemColor = color ?? AppColors.primary;
    return ListTile(
      leading: Icon(icon, color: itemColor, size: 20),
      title: Text(
        label,
        style: AppTextStyles.bodyMd().copyWith(
          color: color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: route != null ? Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary) : null,
      onTap: onTap ?? (route != null ? () => context.go(route) : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 2),
    );
  }
}
```

- [ ] **Step 2: Vérifier**

Run: `flutter analyze lib/features/merchant/screens/more_screen.dart`
Expected: aucune nouvelle erreur.

- [ ] **Step 3: Commit**

```bash
git add lib/features/merchant/screens/more_screen.dart
git commit -m "feat: réorganise la page Plus marchand en sections (Compte, Fidélisation, Assistance)"
```

---

### Task 5: Vérification finale globale

**Files:** aucun fichier modifié — tâche de vérification uniquement.

- [ ] **Step 1: Analyse statique complète**

Run: `flutter analyze`
Expected: aucune erreur (des warnings préexistants sans rapport avec les 4 tâches ci-dessus sont tolérés, mais zéro nouvelle erreur sur les fichiers touchés).

- [ ] **Step 2: Suite de tests existante**

Run: `flutter test`
Expected: tous les tests passent (aucun test existant ne couvre les écrans modifiés, donc aucune régression attendue côté tests automatisés — cette étape garde le reste de l'app sous contrôle).

- [ ] **Step 3: Confirmer le point 4 du besoin (aucun code à changer)**

Relire `lib/features/merchant/screens/validate_screen.dart` (déjà audité) : confirmer que l'onglet "Code manuel" appelle bien `validateNotifierProvider.lookupByCode(code)` et que ce endpoint accepte code de carte, `qr_token` ou identifiant client. Rien à modifier ici — décision déjà validée avec l'utilisateur.

- [ ] **Step 4: Vérification manuelle dans l'app**

Lancer l'app (`flutter run`) et vérifier à la main :
1. Connexion marchand admin → atterrit directement sur l'écran "Valider" (pas le dashboard).
2. Page portefeuille client → le carousel promo s'affiche en premier, au-dessus des cartes.
3. Onglet SMS marchand → nouveau design (carte quota, cartes stats, liste de campagnes) affiche les vraies données du backend (pas de mock cassé).
4. Onglet "Plus" marchand → 3 sections visibles (Compte, Fidélisation, Assistance), chaque tuile navigue vers un écran existant et fonctionnel.
5. Écran "Valider" marchand → les deux onglets (scan QR / code manuel) fonctionnent toujours.

- [ ] **Step 5: Commit final si des ajustements manuels ont eu lieu pendant la vérification**

```bash
git status
# Si des fichiers ont été ajustés pendant la vérification manuelle :
git add -A
git commit -m "fix: ajustements post-vérification de la fusion design main → main1"
```

---

## Self-Review

1. **Couverture spec** : point 1 → Task 1 (landing) + note (nav bar déjà identique) ; point 2 → Task 4 ; point 3 → Task 3 ; point 4 → Task 5 Step 3 (confirmé sans code) ; point 5 → Task 5 en entier.
2. **Placeholders** : aucun — chaque étape de code contient le contenu réel (copies de fichiers via `git show`, diffs exacts, fichier complet pour `more_screen.dart`).
3. **Cohérence des types/signatures** : `smsNotifierProvider`, `merchantNotifierProvider`, `merchantAuthProvider` utilisés avec les mêmes noms/signatures que dans le code actuel de main1 — vérifié par lecture directe des providers avant écriture du plan.
