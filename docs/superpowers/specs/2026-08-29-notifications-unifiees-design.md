# Centre de notifications unifié (push + in-app)

Date : 2026-08-29
Statut : validé, en attente de plan d'implémentation

## Contexte

L'app envoie déjà des push FCM depuis 6 points d'origine (récompense
débloquée, parrainage en attente, parrainage validé, anniversaire,
campagne marchand manuelle/planifiée, broadcast admin CLI), chacun
appelant directement `FcmService`/`SendPromoNotification` sans point
de passage commun. Trois tables (`notification_logs`,
`notification_campaigns`, `reward_notification_logs`) journalisent la
*livraison* (succès/échec FCM) mais aucune ne porte de contenu
consultable (pas de titre/corps/état lu) — ce sont des logs d'audit,
pas une boîte de réception.

Côté Flutter, les deux écrans qui prétendent afficher un historique de
notifications sont mock :
- Client (`lib/features/client/notifications/notifications_screen.dart`,
  provider `NotificationsNotifier` dans
  `lib/features/client/providers/app_providers.dart`) : seule la
  catégorie "récompense" est réelle (dérivée de `rewardsProvider`) ;
  stamp/points/cashback/vip/referral/system sont des données `MockData`
  figées, et `markRead`/`markAllRead` ne mutent que l'état Riverpod
  local — rien n'est persisté côté serveur.
- Marchand (`lib/features/merchant/screens/notifications_screen.dart`) :
  liste 100% inline en dur, aucun provider, aucun appel réseau.

Objectif de ce projet : remplacer les deux écrans mock par un vrai
centre de notifications persistant côté serveur, et unifier la
décision "push, in-app, ou les deux" derrière une politique fixe par
type d'événement plutôt que des appels FCM dispersés et incohérents.

## Périmètre

Couvre l'app client ET l'app marchand (même modèle de données, deux
consommateurs). Les 3 tables de logs de livraison existantes ne sont
pas modifiées ni migrées — nouvelle table dédiée au contenu/lu, vide
au démarrage (pas de backfill historique : seules les notifications
créées après la mise en service apparaissent dans la boîte de
réception).

## Modèle de données

Nouvelle table `notifications` :

| colonne | type | notes |
|---|---|---|
| `id` | bigint PK | |
| `notifiable_type` / `notifiable_id` | morph | cible `App\Models\Client` ou `App\Models\Restaurant` — réutilise la même convention que `device_tokens.tokenable_type/tokenable_id` (migration `2026_08_28_152951_make_device_tokens_polymorphic.php`) |
| `type` | string | identifiant d'événement, voir table de politique ci-dessous |
| `title` | string | |
| `body` | text | |
| `data` | json nullable | payload de deep-link (ex. `card_id`, `reward_id`, `campaign_id`) |
| `read_at` | timestamp nullable | `null` = non lu |
| `created_at` / `updated_at` | timestamp | |

Index : `(notifiable_type, notifiable_id, created_at)` pour le listing
paginé, `(notifiable_type, notifiable_id, read_at)` pour le comptage
non-lu.

Modèle Eloquent `App\Models\Notification` (`$guarded = []`, relation
`morphTo('notifiable')`).

Les tables `notification_logs`, `notification_campaigns`,
`reward_notification_logs` gardent leur rôle actuel d'audit de
livraison FCM (consommé par `NotificationHealthReport`) — non
touchées par ce projet.

## Dispatcher unifié et politique par type

`App\Services\NotificationDispatcher` (déjà existant, aujourd'hui
dédié aux récompenses) devient le point de passage unique :

```php
NotificationDispatcher::send(
    Model $recipient,      // Client ou Restaurant
    string $type,          // clé de politique, ex. 'reward_unlocked'
    string $title,
    string $body,
    array $data = [],
): void
```

Comportement : crée systématiquement une ligne `notifications`
(in-app toujours). Consulte ensuite une table de politique fixe,
codée en constante dans le service, pour savoir si un push FCM doit
aussi partir :

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

Les trois derniers types sont nouveaux : ils remplacent les entrées
mock de l'écran marchand ("Nouveau client", "Quota SMS faible",
"Rapport hebdomadaire") par du contenu réel, sans push — purement
informatif dans la boîte de réception marchand, pour éviter de
spammer le marchand de push sur des événements de routine. Ajuster
cette table ne touche qu'une constante, pas le reste du système.

Quand `push = oui`, le dispatcher résout les `device_tokens` du
destinataire (comme le fait déjà `FcmService`/les jobs actuels) et
envoie via le mécanisme FCM existant, inchangé.

### Sites refactorés pour passer par `send()`

Les 6 points d'origine actuels sont réécrits pour appeler le
dispatcher au lieu d'appeler `FcmService`/`SendPromoNotification`
directement — chacun garde sa logique de résolution d'audience
existante, seul le "comment livrer" change :

1. **Récompense débloquée** — `NotificationDispatcher::dispatchRewardUnlocked`
   (`app/Services/NotificationDispatcher.php`) : garde le
   broadcast Reverb immédiat + le fallback FCM différé
   (`SendRewardFcmFallback`) tels quels ; ajoute l'appel à `send()`
   pour la ligne `notifications`.
2. **Parrainage en attente** — `ReferralService::notifyPending`
   (`app/Services/Referral/ReferralService.php:115`).
3. **Parrainage validé** — `ReferralService::notifyValidated`
   (`app/Services/Referral/ReferralService.php:130`).
4. **Anniversaire** — `SendBirthdayNotifications`
   (`app/Console/Commands/SendBirthdayNotifications.php`).
5. **Campagne marchand** (immédiate et planifiée, même job) —
   `SendCampaignNotification` (`app/Jobs/SendCampaignNotification.php`).
6. **Broadcast admin CLI** — `SendGlobalNotification`
   (`app/Console/Commands/SendGlobalNotification.php`).

Les 3 nouveaux types marchand (`merchant_new_client`,
`merchant_low_sms`, `merchant_weekly_report`) sont déclenchés depuis
les points du code où ces événements sont déjà détectables côté
backend (nouveau client sur une carte du restaurant, quota SMS bas,
génération du rapport hebdomadaire) — à localiser précisément pendant
le plan d'implémentation ; aujourd'hui ces trois n'ont aucune
détection serveur, seulement une maquette d'écran.

## API backend

Quatre endpoints, dupliqués sous deux guards (`auth:sanctum` côté
client existant, garde marchand existant) :

- `GET /api/notifications` — liste paginée (20/page) du destinataire
  authentifié, triée `created_at` desc. Remplace l'implémentation
  actuelle (`routes/api.php:199`) qui paginait `notificationLogs()`
  sans contenu exploitable.
- `GET /api/notifications/unread-count` — pour le badge de la cloche.
- `POST /api/notifications/{id}/read` — vérifie que la notification
  appartient au destinataire authentifié avant de poser `read_at`
  (404/403 sinon — pas d'accès à la notification d'un autre compte).
- `POST /api/notifications/read-all` — pose `read_at` sur toutes les
  notifications non lues du destinataire authentifié.
- Même quatuor sous `/api/merchant/notifications` (guard restaurant).

## Client Flutter

**App client** :
- Nouveaux `NotificationService`/`NotificationRepository`
  (`lib/core/api/...`, même structure que les repositories existants)
  branchés sur les 4 endpoints.
- `NotificationsNotifier` (`lib/features/client/providers/app_providers.dart`)
  perd son seed `MockData.notifications` : charge depuis
  `GET /notifications`, `markRead`/`markAllRead` appellent les `POST`
  correspondants au lieu de ne muter que l'état local. La dérivation
  depuis `rewardsProvider` (récompenses) est retirée — les
  notifications de récompense arrivent maintenant par le même flux
  serveur que les autres types.
- `NotificationKind` (icônes, `notifications_screen.dart`) reste,
  remappé depuis le champ `type` renvoyé par l'API au lieu d'être fixé
  par la source mock.
- `notification_bell_button.dart` branché sur
  `GET /notifications/unread-count`.

**App marchand** :
- Même topologie : nouveaux repository/provider,
  `lib/features/merchant/screens/notifications_screen.dart` perd sa
  liste inline en dur et consomme l'API réelle.

Aucune refonte visuelle des deux écrans — structure UI actuelle
conservée, seul le branchement données change.

## Tests

- Backend : test feature par site de déclenchement, vérifiant qu'une
  ligne `notifications` correcte est créée (type/`read_at` null) et
  que le push part ou non selon la table de politique ; tests
  d'endpoint pour liste/lu/tout-lu/compteur, un jeu par guard
  (client, marchand), y compris le contrôle d'appartenance sur
  `POST .../{id}/read`.
- Client : pas d'infrastructure de test widget existante sur ces
  écrans — vérification manuelle via lancement de l'app après
  implémentation, comme pratiqué ailleurs dans le projet.
