import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';

const _fallbackCenter = LatLng(6.1319, 1.2228);

class MerchantMapArguments {
  final String merchantName;
  final String address;
  final double? latitude;
  final double? longitude;

  const MerchantMapArguments({
    required this.merchantName,
    required this.address,
    this.latitude,
    this.longitude,
  });
}

class MerchantMapScreen extends StatelessWidget {
  final String merchantName;
  final String address;
  final double? latitude;
  final double? longitude;

  const MerchantMapScreen({
    super.key,
    required this.merchantName,
    required this.address,
    this.latitude,
    this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final center = latitude != null && longitude != null
        ? LatLng(latitude!, longitude!)
        : _fallbackCenter;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppDetailBar(title: 'Plan'),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: latitude != null && longitude != null ? 16 : 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mivafid.app',
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
              if (latitude != null && longitude != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 56,
                      height: 64,
                      child: Column(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.store,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronDown,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.mapPin,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            merchantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium().copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            address.isNotEmpty ? address : 'Emplacement du commerce',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall(
                              color: AppColors.inkMuted(opacity: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (latitude == null || longitude == null)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Text(
                    'Position exacte non disponible',
                    style: AppTextStyles.bodySmall(
                      color: AppColors.inkMuted(opacity: 0.72),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
