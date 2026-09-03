import 'dart:async';
import 'package:flutter/material.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'promo_banner.dart';

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  Timer? _timer;
  int _currentPage = 0;

  final List<Widget> _banners = [
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

  @override
  void initState() {
    super.initState();
    // Use an infinite initial page so we can even swipe left, or just start at 0 if we only want to auto-scroll right.
    // Starting at 0 is fine since we auto-scroll forward.
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
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

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          _currentPage = index;
        },
        itemBuilder: (context, index) {
          return _banners[index % _banners.length];
        },
      ),
    );
  }
}
