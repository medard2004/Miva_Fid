# Miva-Fid

Plateforme de fidélité digitale pour commerces locaux — Lomé, Togo

## Stack technique

- Flutter 3.22+ / Dart 3.4+
- Riverpod 2.x (state management)
- GoRouter 13.x (navigation)
- Hive (cache offline)

## Configuration

### Variables d'environnement

Copiez `.env.example` en `.env` et remplissez vos clés :

```
API_BASE_URL=http://192.168.1.83:8000/api
```

### Lancer l'app

```bash
# Installer les dépendances
flutter pub get

# Générer les fichiers Riverpod
flutter pub run build_runner build --delete-conflicting-outputs

# Lancer sur Android
flutter run

# Ou avec un fichier .env via flutter_dotenv (optionnel)
flutter run
```

## Structure du projet

```
lib/
├── main.dart              # Point d'entrée
├── app.dart               # MaterialApp.router
├── core/                  # Thème, router, utils, widgets partagés
├── features/
│   ├── onboarding/        # Inscription marchand (5 étapes) + client
│   ├── merchant/          # Dashboard, validation, clients, SMS, QR, vitrine
│   └── client/            # Accueil, cartes, scanner, récompenses, profil
└── models/                # Modèles de données
```

## Règles importantes

- Zéro emoji dans l'UI — Material Icons uniquement
- Tout le texte en français
- Montants en FCFA via `FcfaFormatter`
- Police DM Mono pour tous les chiffres et codes
- Labels TOUJOURS au-dessus des champs (AppInput)
- SkeletonLoader sur tous les états de chargement
- HapticFeedback sur validation tampon et récompense
- File d'attente Hive pour les tampons offline

## Génération de code

Après modification des providers Riverpod :

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```
