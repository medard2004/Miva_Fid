import 'package:flutter/services.dart';

class AppHaptics {
  AppHaptics._();

  /// Légère vibration — sélection, navigation
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibration moyenne — validation tampon
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Vibration forte — récompense débloquée
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Vibration légère — interactions générales
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }
}
