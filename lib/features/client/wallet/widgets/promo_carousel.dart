import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/models/advertisement_model.dart';
import '../providers/advertisements_provider.dart';
import 'promo_banner.dart';

class PromoCarousel extends ConsumerStatefulWidget {
  const PromoCarousel({super.key});

  @override
  ConsumerState<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends ConsumerState<PromoCarousel> {
  static bool isDismissedForSession = false;

  final PageController _pageController = PageController(viewportFraction: 1.0);
  Timer? _timer;
  int _currentPage = 0;

  static final List<List<Color>> _colorPalettes = [
    const [Color(0xFF3B1F83), Color(0xFF1E0F45)],
    [AppColors.primary, AppColors.ink],
    const [Color(0xFFF59E0B), Color(0xFF78350F)],
    const [Color(0xFF0D9488), Color(0xFF134E4A)],
    const [Color(0xFFE11D48), Color(0xFF881337)],
  ];

  static const List<String> _emojis = ['🎁', '✨', '🍹', '⭐', '🔥'];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!isDismissedForSession) {
      _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        if (_pageController.hasClients) {
          _currentPage++;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleAdTap(AdvertisementModel ad) async {
    final link = ad.linkUrl;
    if (link == null || link.trim().isEmpty) return;
    final uri = Uri.tryParse(link.trim());
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<Widget> _buildDefaultBanners() {
    return [
      const Padding(
        padding: EdgeInsets.only(right: 8),
        child: PromoBanner(
          title: 'Fidélisez plus,\nrécompensez mieux !',
          subtitle: 'NOUVEAU',
          description: 'Plus de fidélité, plus de succès.',
          color1: Color(0xFF3B1F83),
          color2: Color(0xFF1E0F45),
          emoji3D: '🎁',
          showButton: false,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: PromoBanner(
          title: "Promotion d'été",
          subtitle: "JUSQU'À -20%",
          description: "Profitez de réductions exclusives sur tous nos articles.",
          color1: AppColors.primary,
          color2: AppColors.ink,
          emoji3D: '☀️',
          showButton: false,
        ),
      ),
      const Padding(
        padding: EdgeInsets.only(right: 8),
        child: PromoBanner(
          title: 'Happy Hour',
          subtitle: 'ÉVÉNEMENT',
          description: "Tous les vendredis de 18h à 20h, 1 acheté = 1 offert !",
          color1: Color(0xFFF59E0B),
          color2: Color(0xFF78350F),
          emoji3D: '🍹',
          showButton: false,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (isDismissedForSession) {
      return const SizedBox.shrink();
    }

    final adsAsync = ref.watch(clientAdvertisementsProvider);

    final banners = adsAsync.when<List<Widget>>(
      data: (ads) {
        if (ads.isEmpty) {
          return _buildDefaultBanners();
        }
        return ads.asMap().entries.map((entry) {
          final idx = entry.key;
          final ad = entry.value;
          final palette = _colorPalettes[idx % _colorPalettes.length];
          final emoji = _emojis[idx % _emojis.length];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PromoBanner(
              title: ad.title,
              subtitle: ad.subtitle ?? 'ANNONCE',
              description: ad.description ?? '',
              imageUrl: ad.imageUrl,
              color1: palette[0],
              color2: palette[1],
              emoji3D: ad.imageUrl == null ? emoji : null,
              onTap: ad.linkUrl != null && ad.linkUrl!.isNotEmpty
                  ? () => _handleAdTap(ad)
                  : null,
              showButton: ad.linkUrl != null && ad.linkUrl!.isNotEmpty,
            ),
          );
        }).toList();
      },
      loading: () => _buildDefaultBanners(),
      error: (_, __) => _buildDefaultBanners(),
    );

    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 110,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              _currentPage = index;
            },
            itemBuilder: (context, index) {
              return banners[index % banners.length];
            },
          ),
          Positioned(
            top: 6,
            right: 14,
            child: AppTapScale(
              onTap: () {
                _timer?.cancel();
                setState(() {
                  isDismissedForSession = true;
                });
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: const Icon(
                  LucideIcons.x,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
