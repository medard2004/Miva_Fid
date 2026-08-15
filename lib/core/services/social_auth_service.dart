import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

import '../errors/error_translator.dart';

class SocialAuthService {
  static bool _googleInitialized = false;

  /// Client OAuth « Web » du projet Firebase.
  ///
  /// C'est bien le client **Web** qui est attendu ici, pas le client Android :
  /// Google le grave dans l'`audience` de l'`id_token`, et Firebase refuse le
  /// jeton si cette audience ne correspond pas au projet.
  ///
  /// Ce client n'existe qu'une fois le fournisseur Google activé dans la
  /// console Firebase : c'est cette activation qui le crée. Sa valeur est donc
  /// renseignée après coup, ici ou via :
  ///   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '829928583492-98upa68avrk6r20bqkg62p8ffrcqmt5m.apps.googleusercontent.com',
  );

  /// Le backend valide l'`id_token` Google comme un jeton **Firebase**.
  /// Sans `Firebase.initializeApp()` réussi, `signInWithCredential` échoue avec
  /// un message opaque ; on préfère dire tout de suite ce qui manque.
  static void _assertFirebaseReady() {
    if (Firebase.apps.isNotEmpty) return;
    throw StateError(
      'Firebase n\'est pas initialisé : le fichier de configuration '
      '(android/app/google-services.json ou ios/Runner/GoogleService-Info.plist) '
      'est absent. Lancer `flutterfire configure` avant d\'utiliser la '
      'connexion Google.',
    );
  }

  /// Initialise l'instance Google SignIn si besoin
  static Future<void> _ensureInitialized() async {
    if (_googleInitialized) return;

    // Laisser une valeur vide passer ici mène à un échec silencieux : Google
    // rend un compte sans `idToken` et l'écran ne montre rien.
    if (serverClientId.isEmpty) {
      throw StateError(
        'GOOGLE_SERVER_CLIENT_ID n\'est pas renseigné. Activer le fournisseur '
        'Google dans la console Firebase (ce qui crée le client OAuth « Web »), '
        'puis reporter son identifiant dans SocialAuthService.serverClientId.',
      );
    }

    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    _googleInitialized = true;
  }

  /// S'authentifie avec Google puis Firebase, et retourne l'id_token Firebase pour le backend
  static Future<String?> signInWithGoogle() async {
    try {
      _assertFirebaseReady();
      await _ensureInitialized();

      // Flux interactif systématique : la reconnexion silencieuse reprenait
      // toujours le dernier compte Google utilisé, sans jamais laisser
      // l'utilisateur en choisir un autre (login comme inscription).
      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate(
        scopeHint: ['email', 'profile'],
      );
      final String? googleIdToken = account.authentication.idToken;

      if (googleIdToken == null || googleIdToken.isEmpty) {
        throw Exception(
          'Google n\'a pas renvoyé d\'id_token. Vérifier que '
          'GOOGLE_SERVER_CLIENT_ID correspond au client OAuth « Web » du '
          'projet Firebase et que l\'empreinte SHA-1 de la machine est '
          'enregistrée dans ce projet.',
        );
      }

      // Crée une credential pour Firebase à partir des tokens Google
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleIdToken,
      );

      // Authentifie l'utilisateur dans Firebase
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Récupère le jeton JWT Firebase (idToken)
      // Ce jeton sera validé par le backend Laravel
      final String? firebaseIdToken = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception(
            'Impossible de récupérer le jeton Firebase après l\'authentification.');
      }

      return firebaseIdToken;
    } catch (e) {
      debugPrint('Erreur Firebase/Google Sign-In: $e');

      // Une annulation renvoie `null` : l'appelant l'interprète comme un
      // abandon volontaire et n'affiche rien. Toute autre panne (réseau,
      // Firebase mal configuré, jeton refusé) est relancée — la retourner en
      // `null` la rendrait indiscernable d'une annulation, et l'utilisateur
      // verrait le bouton ne rien faire, sans le moindre message.
      if (ErrorTranslator.isUserCancellation(e)) return null;
      rethrow;
    }
  }

  /// S'authentifie avec Apple et retourne l'id_token pour le backend
  ///
  /// Sur iOS/macOS le SDK natif suffit. Sur Android (et sur le Web), Apple
  /// impose de passer par sa page de connexion : sans
  /// `webAuthenticationOptions`, l'appel lève `MissingPluginException` /
  /// `SignInWithAppleNotSupportedException` au lieu d'ouvrir quoi que ce soit.
  static Future<String?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: _needsAppleWebFlow
            ? WebAuthenticationOptions(
                clientId: appleServiceId,
                redirectUri: Uri.parse(appleRedirectUri),
              )
            : null,
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Impossible de récupérer le token Apple.');
      }

      return idToken;
    } catch (e) {
      debugPrint('Erreur Apple Sign-In: $e');
      if (ErrorTranslator.isUserCancellation(e)) return null;
      rethrow;
    }
  }

  /// Le « Services ID » Apple (distinct du Bundle ID), requis hors iOS/macOS.
  ///   flutter run --dart-define=APPLE_SERVICE_ID=com.mivafid.app.service
  static const String appleServiceId = String.fromEnvironment(
    'APPLE_SERVICE_ID',
    defaultValue: 'com.mivafid.app.service',
  );

  /// URL de retour déclarée côté Apple Developer, qui doit pointer vers le
  /// backend (endpoint qui renvoie l'utilisateur vers l'app).
  ///   flutter run --dart-define=APPLE_REDIRECT_URI=https://api.example.com/api/auth/apple/callback
  static const String appleRedirectUri = String.fromEnvironment(
    'APPLE_REDIRECT_URI',
    defaultValue: 'https://example.com/api/auth/apple/callback',
  );

  static bool get _needsAppleWebFlow =>
      defaultTargetPlatform != TargetPlatform.iOS &&
      defaultTargetPlatform != TargetPlatform.macOS;
}
