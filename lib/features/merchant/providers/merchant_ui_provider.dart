import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Masque la barre de navigation marchande (écrans plein écran type scan).
final hideMerchantNavProvider = StateProvider<bool>((ref) => false);
