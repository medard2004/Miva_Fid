import 'dart:async';
import 'package:flutter/material.dart';
import 'package:miva_fid/core/theme/app_text_styles.dart';

class SmsPromoCarousel extends StatefulWidget {
  const SmsPromoCarousel({super.key});

  @override
  State<SmsPromoCarousel> createState() => _SmsPromoCarouselState();
}

class _SmsPromoCarouselState extends State<SmsPromoCarousel> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  Timer? _timer;
  int _currentPage = 0;

  final List<Widget> _banners = [
    const Padding(
      padding: EdgeInsets.only(right: 8),
      child: MerchantPromoBanner(
        title: 'Boostez vos ventes',
        subtitle: 'ASTUCE',
        description: 'Envoyez des promos ciblées par SMS à vos inactifs.',
        color1: Color(0xFF3B1F83),
        color2: Color(0xFF1E0F45),
        emoji3D: '🚀',
        showButton: false,
      ),
    ),
    const Padding(
      padding: EdgeInsets.only(right: 8),
      child: MerchantPromoBanner(
        title: 'Rappels automatiques',
        subtitle: 'NOUVEAU',
        description: 'Planifiez des SMS pour les anniversaires de vos clients.',
        color1: Color(0xFF7B3AED),
        color2: Color(0xFF4C1D95),
        emoji3D: '🎂',
        showButton: false,
      ),
    ),
    const Padding(
      padding: EdgeInsets.only(right: 8),
      child: MerchantPromoBanner(
        title: 'Pack SMS Pro',
        subtitle: 'OFFRE',
        description: "Profitez de -10% sur les recharges de 1000 SMS.",
        color1: Color(0xFFF59E0B),
        color2: Color(0xFF78350F),
        emoji3D: '📱',
        showButton: true,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
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
      height: 120, // Hauteur réduite
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

class MerchantPromoBanner extends StatelessWidget {
  const MerchantPromoBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color1,
    required this.color2,
    this.backgroundIcon,
    this.emoji3D,
    this.showButton = false,
  });

  final String title;
  final String subtitle;
  final String description;
  final Color color1;
  final Color color2;
  final IconData? backgroundIcon;
  final String? emoji3D;
  final bool showButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color1.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: -20,
            child: Opacity(
              opacity: 0.05,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (emoji3D != null)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Text(
                  emoji3D!,
                  style: const TextStyle(fontSize: 60),
                ),
              ),
            ),
          if (backgroundIcon != null && emoji3D == null)
            Positioned(
              right: -10,
              top: 0,
              child: Transform.rotate(
                angle: -0.1,
                child: Icon(
                  backgroundIcon,
                  size: 140,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 10))
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B3AED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subtitle,
                      style: AppTextStyles.labelBold()
                        .copyWith(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: AppTextStyles.h3()
                      .copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.55,
                    child: Text(
                      description,
                      style: AppTextStyles.caption().copyWith(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showButton) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2))
                          ],
                        ),
                        child: Text(
                          'En profiter',
                          style: AppTextStyles.labelBold()
                            .copyWith(color: color1),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
