import 'package:flutter/material.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color1.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (emoji3D != null) ...[
            const Positioned(
              right: 15,
              top: 15,
              child: Text(
                '🪙',
                style: TextStyle(fontSize: 24, shadows: [
                  Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2))
                ]),
              ),
            ),
            const Positioned(
              right: 100,
              bottom: 20,
              child: Text(
                '✨',
                style: TextStyle(fontSize: 20),
              ),
            ),
            const Positioned(
              right: 35,
              bottom: 10,
              child: Text(
                '🪙',
                style: TextStyle(fontSize: 18, shadows: [
                  Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2))
                ]),
              ),
            ),
            Positioned(
              right: 10,
              top: 30,
              child: Transform.rotate(
                angle: -0.1,
                child: Text(
                  emoji3D!,
                  style: const TextStyle(
                    fontSize: 80,
                    shadows: [
                      Shadow(
                          color: Colors.black45,
                          blurRadius: 20,
                          offset: Offset(0, 10))
                    ],
                  ),
                ),
              ),
            ),
          ],
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
            padding: const EdgeInsets.all(16.0),
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
                    style: AppTextStyles.label(color: Colors.white)
                        .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: AppTextStyles.titleMedium(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w900, height: 1.2),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: Text(
                    description,
                    style: AppTextStyles.bodySmall(color: Colors.white),
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
                        style: AppTextStyles.label(color: color1)
                            .copyWith(fontWeight: FontWeight.bold),
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
