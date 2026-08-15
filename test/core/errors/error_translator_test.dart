import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/api/core/api_exceptions.dart';
import 'package:miva_fid/core/errors/app_error.dart';
import 'package:miva_fid/core/errors/error_messages.dart';
import 'package:miva_fid/core/errors/error_translator.dart';

void main() {
  group('ErrorTranslator — auth method conflicts', () {
    test('login: Google-only account message maps to accountUsesGoogle', () {
      final error = ServerException(
        'Ce compte utilise une connexion Google. Connectez-vous avec Google pour accéder à votre compte.',
        statusCode: 403,
      );

      final result = ErrorTranslator.translate(error, context: ErrorContext.login);

      expect(result.generalMessage, ErrorMessages.accountUsesGoogle);
    });

    test('forgotPassword: Apple-only account message maps to accountUsesApple', () {
      final error = ServerException(
        'Ce compte utilise une connexion Apple. Connectez-vous avec Apple pour accéder à votre compte.',
        statusCode: 403,
      );

      final result = ErrorTranslator.translate(error, context: ErrorContext.forgotPassword);

      expect(result.generalMessage, ErrorMessages.accountUsesApple);
    });

    test('socialLogin: email already used by a password account maps to socialEmailUsesPassword', () {
      final error = ServerException(
        'Un compte existe déjà avec cet e-mail et utilise un mot de passe. Connectez-vous avec votre mot de passe.',
        statusCode: 403,
      );

      final result = ErrorTranslator.translate(error, context: ErrorContext.socialLogin);

      expect(result.generalMessage, ErrorMessages.socialEmailUsesPassword);
    });

    test('an unrelated 403 still falls back to the generic per-context message', () {
      final error = ServerException('Forbidden.', statusCode: 403);

      final result = ErrorTranslator.translate(error, context: ErrorContext.login);

      expect(result.generalMessage, ErrorMessages.loginInvalidCredentials);
    });
  });

  group('ErrorTranslator — flat 422 (no field bag) password checks', () {
    test('verifyPassword: wrong current password maps to passwordCurrentIncorrect, not the generic fallback', () {
      final error = ValidationException(
        'Le mot de passe est incorrect.',
        fieldErrors: const {},
        statusCode: 422,
      );

      final result = ErrorTranslator.translate(error, context: ErrorContext.verifyPassword);

      expect(result.generalMessage, ErrorMessages.passwordCurrentIncorrect);
    });

    test('changePassword: wrong current password maps to passwordCurrentIncorrect, not the generic fallback', () {
      final error = ValidationException(
        'Le mot de passe actuel est incorrect.',
        fieldErrors: const {},
        statusCode: 422,
      );

      final result = ErrorTranslator.translate(error, context: ErrorContext.changePassword);

      expect(result.generalMessage, ErrorMessages.passwordCurrentIncorrect);
    });

    test('login: account-not-found 401 maps to loginAccountNotFound, not the merged generic message', () {
      final error = UnauthorizedException('Aucun compte n\'est associé à ce numéro.');

      final result = ErrorTranslator.translate(error, context: ErrorContext.login);

      expect(result.generalMessage, ErrorMessages.loginAccountNotFound);
    });

    test('login: wrong-password 401 still maps to the generic invalid-credentials message', () {
      final error = UnauthorizedException('Mot de passe incorrect.');

      final result = ErrorTranslator.translate(error, context: ErrorContext.login);

      expect(result.generalMessage, ErrorMessages.loginInvalidCredentials);
    });

    test('changePassword: new password identical to current maps to passwordMustDiffer', () {
      final error = ValidationException(
        'Le nouveau mot de passe doit être différent de l\'actuel.',
        fieldErrors: const {},
        statusCode: 422,
      );

      final result = ErrorTranslator.translate(error, context: ErrorContext.changePassword);

      expect(result.generalMessage, ErrorMessages.passwordMustDiffer);
    });

    test('an unrelated flat 422 still falls back to the generic per-context message', () {
      final error = ValidationException(
        'Une erreur inattendue est survenue.',
        fieldErrors: const {},
        statusCode: 422,
      );

      final result = ErrorTranslator.translate(error, context: ErrorContext.changePassword);

      expect(result.generalMessage, ErrorMessages.passwordChangeFailed);
    });
  });
}
