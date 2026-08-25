import 'dart:convert';
import 'package:dio/dio.dart';
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

class GeocodedAddress {
  final String country;
  final String city;
  final String address;
  final String? displayName;

  const GeocodedAddress({
    required this.country,
    required this.city,
    required this.address,
    this.displayName,
  });
}

/// Géolocalisation et reverse-geocoding du commerce à l'inscription marchand.
class LocationService {
  LocationService._();

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'User-Agent': 'MivaFid-App/1.0 (contact@mivafid.tg)',
        'Accept-Language': 'fr,fr-FR;q=0.9,en;q=0.8',
      },
    ),
  );

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

  /// Déduit automatiquement le Pays, la Ville et le Quartier/Rue à partir
  /// des coordonnées GPS via OpenStreetMap Nominatim (Gratuit, en Français).
  static Future<GeocodedAddress?> reverseGeocode(double latitude, double longitude) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1&accept-language=fr';
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data is Map<String, dynamic>) {
          final addr = data['address'] as Map<String, dynamic>? ?? {};

          final country = (addr['country'] as String?)?.trim() ?? 'Togo';

          final city = (addr['city'] as String?)?.trim() ??
              (addr['town'] as String?)?.trim() ??
              (addr['village'] as String?)?.trim() ??
              (addr['municipality'] as String?)?.trim() ??
              (addr['county'] as String?)?.trim() ??
              (addr['state'] as String?)?.trim() ??
              'Lomé';

          final road = (addr['road'] as String?)?.trim();
          final suburb = (addr['suburb'] as String?)?.trim() ??
              (addr['neighbourhood'] as String?)?.trim() ??
              (addr['quarter'] as String?)?.trim() ??
              (addr['residential'] as String?)?.trim() ??
              (addr['subdistrict'] as String?)?.trim();

          String streetOrQuarter = '';
          if (road != null && road.isNotEmpty && suburb != null && suburb.isNotEmpty) {
            streetOrQuarter = '$road, $suburb';
          } else if (suburb != null && suburb.isNotEmpty) {
            streetOrQuarter = suburb;
          } else if (road != null && road.isNotEmpty) {
            streetOrQuarter = road;
          } else {
            streetOrQuarter = (data['display_name'] as String?)?.split(',').take(2).join(',').trim() ?? '';
          }

          return GeocodedAddress(
            country: country,
            city: city,
            address: streetOrQuarter,
            displayName: data['display_name'] as String?,
          );
        }
      }
    } catch (_) {
      // Ignorer l'erreur réseau et laisser la saisie manuelle
    }
    return null;
  }
}
