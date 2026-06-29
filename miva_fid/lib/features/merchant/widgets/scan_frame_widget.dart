import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ScanFrameWidget extends StatefulWidget {
  const ScanFrameWidget({super.key, this.size = 260});
  final double size;

  @override
  State<ScanFrameWidget> createState() => _ScanFrameWidgetState();
}

class _ScanFrameWidgetState extends State<ScanFrameWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _sweep;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _sweep = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CornerBracketPainter(),
          ),
          AnimatedBuilder(
            animation: _sweep,
            builder: (_, __) => Positioned(
              top: _sweep.value * widget.size,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    AppColors.primary.withOpacity(0.8),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const length = 20.0;
    final corners = [
      [Offset(0, length), Offset.zero, Offset(length, 0)],
      [Offset(size.width - length, 0), Offset(size.width, 0), Offset(size.width, length)],
      [Offset(size.width, size.height - length), Offset(size.width, size.height), Offset(size.width - length, size.height)],
      [Offset(length, size.height), Offset(0, size.height), Offset(0, size.height - length)],
    ];
    for (final pts in corners) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy)..lineTo(pts[1].dx, pts[1].dy)..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
