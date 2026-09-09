import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/api/core/api_client.dart';
import 'package:miva_fid/core/api/repositories/auth_repository.dart';
import 'package:miva_fid/core/api/services/auth_service.dart';
import 'package:miva_fid/core/api/storage/token_storage.dart';
import 'package:miva_fid/features/client/models/user.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';

/// Double de [AuthRepository] : construit une chaîne réelle mais inerte
/// (aucun appel réseau tant que les méthodes utilisées à l'inscription
/// restent surchargées ci-dessous) pour pouvoir exercer le vrai
/// [AuthNotifier] sans dépendre du backend.
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
      : super(AuthService(ApiClient(tokenStorage: TokenStorage())), TokenStorage());

  bool shouldFail = false;
  Object failure = Exception('network error');
  AppUser? userToReturn;

  @override
  Future<bool> validateRegisterStep1(Map<String, dynamic> data) async {
    if (shouldFail) throw failure;
    return true;
  }

  @override
  Future<AppUser> register(Map<String, dynamic> data) async {
    if (shouldFail) throw failure;
    return userToReturn!;
  }
}

AppUser _sampleUser() => AppUser(
      id: '1',
      fullName: 'Ada Lovelace',
      phoneNumber: '+22890000000',
      joinDate: DateTime(2024, 1, 1),
    );

void main() {
  group('SignupFlowNotifier', () {
    test('startPhoneSignup calcule l\'âge depuis la date de naissance', () {
      final notifier = SignupFlowNotifier();
      final birthDate = DateTime.now().subtract(const Duration(days: 365 * 20 + 40));

      notifier.startPhoneSignup(
        fullName: 'Ada Lovelace',
        phone: '+22890000000',
        birthDate: birthDate,
      );

      expect(notifier.state.fullName, 'Ada Lovelace');
      expect(notifier.state.phone, '+22890000000');
      expect(notifier.state.age, 20);
      expect(notifier.state.provider, AuthProvider.phone);
    });

    test('startSocialSignup réinitialise les champs identité', () {
      final notifier = SignupFlowNotifier();
      notifier.startPhoneSignup(fullName: 'Ada', phone: '+22890000000');

      notifier.startSocialSignup(provider: AuthProvider.google);

      expect(notifier.state.provider, AuthProvider.google);
      expect(notifier.state.fullName, '');
      expect(notifier.state.phone, '');
    });

    test('reset revient à l\'état initial', () {
      final notifier = SignupFlowNotifier();
      notifier.startPhoneSignup(fullName: 'Ada', phone: '+22890000000');

      notifier.reset();

      expect(notifier.state.fullName, '');
      expect(notifier.state.phone, '');
      expect(notifier.state.provider, AuthProvider.phone);
    });
  });

  group('AuthNotifier — inscription téléphone', () {
    test('validateRegisterStep1 renvoie true et ne pose pas d\'erreur en cas de succès', () async {
      final repo = _FakeAuthRepository();
      final notifier = AuthNotifier(repo);

      final result = await notifier.validateRegisterStep1(const SignupFlowData(
        fullName: 'Ada',
        phone: '+22890000000',
      ));

      expect(result, isTrue);
      expect(notifier.state.lastError, isNull);
    });

    test('validateRegisterStep1 renvoie false et stocke l\'erreur en cas d\'échec', () async {
      final repo = _FakeAuthRepository()
        ..shouldFail = true
        ..failure = Exception('téléphone déjà utilisé');
      final notifier = AuthNotifier(repo);

      final result = await notifier.validateRegisterStep1(const SignupFlowData(
        fullName: 'Ada',
        phone: '+22890000000',
      ));

      expect(result, isFalse);
      expect(notifier.state.lastError, isNotNull);
      expect(notifier.state.isAuthenticated, isFalse);
    });

    test('register authentifie l\'utilisateur en cas de succès', () async {
      final repo = _FakeAuthRepository()..userToReturn = _sampleUser();
      final notifier = AuthNotifier(repo);

      final result = await notifier.register(
        const SignupFlowData(fullName: 'Ada', phone: '+22890000000'),
        'Password123',
      );

      expect(result, isTrue);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.user?.fullName, 'Ada Lovelace');
    });

    test('register laisse la session déconnectée et pose l\'erreur en cas d\'échec', () async {
      final repo = _FakeAuthRepository()..shouldFail = true;
      final notifier = AuthNotifier(repo);

      final result = await notifier.register(
        const SignupFlowData(fullName: 'Ada', phone: '+22890000000'),
        'Password123',
      );

      expect(result, isFalse);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.lastError, isNotNull);
    });
  });
}
