import 'package:intl/intl.dart';

/// Méthode d'authentification utilisée lors de l'inscription.
enum AuthProvider { phone, google, apple }

class AppUser {
  final String id;

  /// Identifiant numérique brut (`clients.id`) — distinct de [id] (l'uuid
  /// public). Nécessaire pour le canal Reverb `loyalty.{id}` : l'autorisation
  /// côté Laravel (`routes/channels.php`) compare `(int) $user->id`, jamais
  /// l'uuid. `null` si le backend ne l'a pas renvoyé (ne devrait pas arriver).
  final int? backendId;

  final String fullName;
  final String phoneNumber;
  final int? age;
  final DateTime? birthDate;
  final DateTime joinDate;
  final String? email;
  final String? photoUrl;
  final String referralCode;
  final int friendsInvited;
  final int friendsJoined;
  final String? city;
  final String? country;
  final String? neighborhood;
  final AuthProvider authProvider;
  final bool profileCompleted;

  const AppUser({
    required this.id,
    this.backendId,
    required this.fullName,
    required this.phoneNumber,
    this.age,
    this.birthDate,
    required this.joinDate,
    this.email,
    this.photoUrl,
    required this.referralCode,
    this.friendsInvited = 0,
    this.friendsJoined = 0,
    this.city,
    this.country,
    this.neighborhood,
    this.authProvider = AuthProvider.phone,
    this.profileCompleted = false,
  });

  /// Construit un [AppUser] depuis la charge utile `client` renvoyée par
  /// l'API Laravel (`ClientAuthController::clientData()`).
  ///
  /// Le backend sépare `first_name` et `last_name` alors que l'app manipule un
  /// `fullName` unique : on recompose ici, et [firstName] fait le chemin
  /// inverse pour les écrans qui n'affichent que le prénom.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final firstName = (json['first_name'] as String?)?.trim() ?? '';
    final lastName = (json['last_name'] as String?)?.trim() ?? '';
    final full = [firstName, lastName].where((e) => e.isNotEmpty).join(' ');

    final birthDate = json['birthdate'] != null
        ? DateTime.tryParse(json['birthdate'].toString())
        : null;

    return AppUser(
      // `uuid` est l'identifiant public stable ; `id` (auto-incrément) sert de
      // repli si le backend ne l'expose pas.
      id: json['uuid']?.toString() ?? json['id']?.toString() ?? '',
      backendId: (json['id'] as num?)?.toInt(),
      fullName: full,
      phoneNumber: json['phone']?.toString() ?? '',
      age: birthDate != null ? _ageFrom(birthDate) : null,
      birthDate: birthDate,
      // `created_at` n'est renvoyé que par les versions récentes de l'API :
      // sans lui, "Membre depuis" retombe sur la date du jour.
      joinDate: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      email: json['email'] as String?,
      photoUrl: json['avatar_url'] as String?,
      referralCode: json['referral_code']?.toString() ?? '',
      city: json['city'] as String?,
      country: json['country'] as String?,
      neighborhood: json['neighborhood'] as String?,
      authProvider: _parseProvider(json['oauth_provider']),
      profileCompleted: json['is_profile_complete'] as bool? ?? false,
    );
  }

  static AuthProvider _parseProvider(dynamic raw) {
    return switch (raw?.toString()) {
      'google' => AuthProvider.google,
      'apple' => AuthProvider.apple,
      _ => AuthProvider.phone,
    };
  }

  /// Âge révolu — calcul calendaire, et non une division par 365 qui dérive
  /// d'un jour tous les quatre ans.
  static int _ageFrom(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    final hasHadBirthdayThisYear = now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hasHadBirthdayThisYear) age--;
    return age;
  }

  /// Rétro-compatibilité : expose `firstName` comme premier prénom (avant le premier espace).
  String get firstName {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : fullName;
  }

  /// Numéro masqué partiellement pour l'écran Profil, ex. "+228 •• •• 45 12".
  String get maskedPhoneNumber {
    if (phoneNumber.length < 4) return phoneNumber;
    final visibleEnd = phoneNumber.substring(phoneNumber.length - 4);
    final prefix = phoneNumber.substring(0, phoneNumber.length - 8 > 0 ? 4 : 0);
    return '$prefix •• •• $visibleEnd';
  }

  /// Vrai si un des champs affichés dans l'écran d'édition manque encore —
  /// recalculé à partir des champs eux-mêmes plutôt que du flag serveur
  /// `profileCompleted`, qui peut rester figé à `true` après l'édition d'un
  /// seul champ alors que d'autres restent vides.
  bool get isProfileIncomplete =>
      fullName.isEmpty ||
      birthDate == null ||
      email == null ||
      email!.isEmpty ||
      country == null ||
      country!.isEmpty ||
      city == null ||
      city!.isEmpty;

  /// Vrai si l'anniversaire tombe dans le mois en cours (bloc anniversaire).
  bool get isBirthdayMonth {
    if (birthDate == null) return false;
    return birthDate!.month == DateTime.now().month;
  }

  /// Vrai si cet utilisateur s'est connecté via un fournisseur social.
  bool get isSocialUser =>
      authProvider == AuthProvider.google || authProvider == AuthProvider.apple;

  /// Nom lisible du fournisseur social, pour l'affichage dans les paramètres
  /// du compte (`null` pour un compte classique téléphone/mot de passe).
  String? get socialProviderLabel => switch (authProvider) {
        AuthProvider.google => 'Google',
        AuthProvider.apple => 'Apple',
        AuthProvider.phone => null,
      };

  /// Date d'inscription formatée ("mars 2024" / "March 2024") — le préfixe
  /// ("Membre depuis"/"Member since") vient d'[AppLocalizations] côté UI.
  String memberSinceDate(String dateFormatLocale) {
    return DateFormat('MMMM yyyy', dateFormatLocale).format(joinDate);
  }

  AppUser copyWith({
    String? fullName,
    String? firstName,
    String? phoneNumber,
    int? age,
    DateTime? birthDate,
    DateTime? joinDate,
    String? email,
    String? photoUrl,
    String? city,
    String? country,
    String? neighborhood,
    AuthProvider? authProvider,
    bool? profileCompleted,
  }) {
    return AppUser(
      id: id,
      backendId: backendId,
      // Si `fullName` est fourni, on le prend directement.
      // Si seulement `firstName` est fourni (compatibilité), on substitue.
      fullName: fullName ??
          (firstName != null
              ? '$firstName ${this.fullName.split(' ').skip(1).join(' ')}'
                  .trim()
              : this.fullName),
      phoneNumber: phoneNumber ?? this.phoneNumber,
      age: age ?? this.age,
      birthDate: birthDate ?? this.birthDate,
      joinDate: joinDate ?? this.joinDate,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      referralCode: referralCode,
      friendsInvited: friendsInvited,
      friendsJoined: friendsJoined,
      city: city ?? this.city,
      country: country ?? this.country,
      neighborhood: neighborhood ?? this.neighborhood,
      authProvider: authProvider ?? this.authProvider,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }
}
