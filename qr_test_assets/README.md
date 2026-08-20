# QR de test — Miva Fid

Deux QR codes prêts à scanner, pour tester le flux marchand ↔ client sans
générer de compte à chaque fois. Encodent des données réelles d'un compte de
test en base locale (`restaurant-loyalty-api`, serveur `php artisan serve`) —
pas des données factices.

## Fichiers

| Fichier | Contenu encodé | À scanner avec |
|---|---|---|
| `merchant_qr_test.png` | `qr_token` du restaurant "Chez Testeur" (`75a29191-7463-4634-9337-69485cfd946f`) | **App client** — écran scan (`/client/onboarding/scan`). Rejoint le programme du commerce via `POST /loyalty-cards/join`. |
| `client_card_qr_test.png` | `card_code` de la carte d'Ama (`QDA9D363`) | **App marchand** — écran validation (`/merchant/validate`). Retrouve la carte via `GET /merchant/clients/lookup` pour accorder un tampon. |

## Utiliser

1. Lancer le backend : `cd restaurant-loyalty-api && php artisan serve --host=0.0.0.0 --port=8000`
2. Vérifier que l'IP configurée dans l'app (`lib/core/api/config/api_constants.dart`) pointe vers cette machine.
3. Afficher le PNG voulu à l'écran (ou l'imprimer) et scanner depuis l'app.

Si les comptes de test ont été supprimés de la base, régénérer avec le script
`scripts/generate_qr_fixtures.py` (voir plus bas) après avoir remplacé les
deux constantes par des valeurs actuelles — `qr_token` d'un restaurant
(`restaurants.qr_token`) et `card_code` d'une carte (`loyalty_cards.card_code`).

## Régénérer

```bash
python3 -m venv .venv && .venv/bin/pip install "qrcode[pil]"
.venv/bin/python scripts/generate_qr_fixtures.py
```

Ce dossier est un fixture de développement, pas un asset embarqué dans l'app —
il n'est référencé par aucun `pubspec.yaml`.
