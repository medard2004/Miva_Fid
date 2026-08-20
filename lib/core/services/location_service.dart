import 'package:geolocator/geolocator.dart';

/// Raison précise d'un échec de géolocalisation — distincte d'une simple
/// erreur réseau, chacune appelle une action différente côté écran (ouvrir
/// les réglages OS vs proposer directement le choix manuel sur la carte).
enum LocationFailureReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationServiceException implements Exception {
  final LocationFailureReason reason;
  const LocationServiceException(this.reason);
}

/// Géolocalisation du restaurant à l'inscription marchand — voir
/// `merchant_location_screen.dart`. Pas d'état interne : chaque appel
/// vérifie service + permission avant de lire la position.
class LocationService {
  LocationService._();

  static Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceException(LocationFailureReason.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(LocationFailureReason.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(LocationFailureReason.permissionDeniedForever);
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }
}
