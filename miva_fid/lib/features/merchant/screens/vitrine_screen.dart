import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/merchant_provider.dart';

class VitrineScreen extends ConsumerStatefulWidget {
  const VitrineScreen({super.key});

  @override
  ConsumerState<VitrineScreen> createState() => _VitrineScreenState();
}

class _VitrineScreenState extends ConsumerState<VitrineScreen> {
  final _nameCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final m = ref.read(merchantNotifierProvider).value;
      if (m != null) {
        _nameCtrl.text = m.name;
        _catCtrl.text = 'Restaurant'; // Mockup default
        _descCtrl.text = m.description ?? 'Cuisine togolaise authentique au cœur de Lomé. Spécialités maison et accueil chaleureux.';
        _phoneCtrl.text = m.phone ?? '+228 90 12 34 56';
        _addrCtrl.text = 'Rue des Cocotiers, Lomé'; // Mockup default
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _catCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'description': _descCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vitrine mise à jour avec succès')),
        );
        context.go('/merchant');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showPreviewSheet(BuildContext context, dynamic merchant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Aperçu public', style: AppTextStyles.h3()),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: Sp.md),
            _PreviewWidget(
              name: _nameCtrl.text,
              category: _catCtrl.text,
              description: _descCtrl.text,
              phone: _phoneCtrl.text,
              address: _addrCtrl.text,
              initials: merchant?.initials ?? 'RS',
            ),
            const SizedBox(height: Sp.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync = ref.watch(merchantNotifierProvider);
    final merchant = merchantAsync.value;

    // No duplicated header variables needed


    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Column(
        children: [
          const SizedBox(height: Sp.sm),

            // 2. Title and "Aperçu" Button Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ma Vitrine',
                        style: AppTextStyles.h1().copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Page publique de votre commerce',
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _showPreviewSheet(context, merchant),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.visibility_outlined, color: AppColors.textPrimary, size: 16),
                    label: Text(
                      'Aperçu',
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms, delay: 80.ms).slideY(begin: 0.06, end: 0),
            const SizedBox(height: Sp.md),

            // 3. Scrollable Editor Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: Sp.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // URL link badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.language_rounded, color: AppColors.merchant, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'miva.fid/lasaveur',
                            style: AppTextStyles.labelBold().copyWith(
                              color: AppColors.merchant,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.open_in_new_rounded, color: AppColors.textSecondary, size: 16),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.08, end: 0),
                    const SizedBox(height: Sp.lg),

                    // Section Photo de couverture
                    _SectionTitle('Photo de couverture').animate().fadeIn(duration: 300.ms, delay: 220.ms),
                    const SizedBox(height: 6),
                    CustomPaint(
                      painter: _DashedBorderPainter(
                        color: AppColors.border.withOpacity(0.8),
                        borderRadius: 12,
                      ),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary.withOpacity(0.6), size: 28),
                            const SizedBox(height: 8),
                            Text(
                              'Ajouter une photo',
                              style: AppTextStyles.caption().copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 260.ms).slideY(begin: 0.06, end: 0),
                    const SizedBox(height: Sp.lg),

                    // Section Informations
                    _SectionTitle('Informations').animate().fadeIn(duration: 300.ms, delay: 330.ms),
                    const SizedBox(height: 8),
                    _buildInputLabel('NOM DU COMMERCE'),
                    _buildTextField(_nameCtrl, 'Restaurant La Saveur'),
                    const SizedBox(height: 12),
                    _buildInputLabel('CATÉGORIE'),
                    _buildTextField(_catCtrl, 'Restaurant'),
                    const SizedBox(height: 12),
                    _buildInputLabel('DESCRIPTION'),
                    _buildTextField(_descCtrl, 'Description...', maxLines: 3),
                    const SizedBox(height: Sp.lg),

                    // Section Contact & adresse
                    _SectionTitle('Contact & adresse').animate().fadeIn(duration: 300.ms, delay: 400.ms),
                    const SizedBox(height: 8),
                    _buildIconLabel(Icons.phone_outlined, 'TÉLÉPHONE'),
                    _buildTextField(_phoneCtrl, '+228 90 12 34 56', keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildIconLabel(Icons.location_on_outlined, 'ADRESSE'),
                    _buildTextField(_addrCtrl, 'Rue des Cocotiers, Lomé'),
                    const SizedBox(height: Sp.lg),

                    // Section Horaires
                    _SectionTitle('Horaires').animate().fadeIn(duration: 300.ms, delay: 460.ms),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(Sp.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: const [
                          _HourRow(day: 'Lundi', hours: '08:00 - 22:00'),
                          _HourRow(day: 'Mardi', hours: '08:00 - 22:00'),
                          _HourRow(day: 'Mercredi', hours: '08:00 - 22:00'),
                          _HourRow(day: 'Jeudi', hours: '08:00 - 22:00'),
                          _HourRow(day: 'Vendredi', hours: '08:00 - 22:00'),
                          _HourRow(day: 'Samedi', hours: '08:00 - 22:00'),
                          _HourRow(day: 'Dimanche', hours: 'Fermé', isClosed: true),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 500.ms).slideY(begin: 0.05, end: 0),
                    const SizedBox(height: Sp.xl),
                  ],
                ),
              ),
            ),

            // 4. Sticky Bottom Action Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.merchant,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.publish_rounded, color: Colors.white, size: 18),
                  label: Text(
                    'Publier les modifications',
                    style: AppTextStyles.labelBold().copyWith(color: Colors.white),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 550.ms).slideY(begin: 0.15, end: 0),
          ],
        ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textSecondary.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildIconLabel(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary.withOpacity(0.8)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: AppColors.textSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.4)),
        filled: true,
        fillColor: AppColors.bgLight.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.merchant, width: 1.5),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.labelBold().copyWith(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _HourRow extends StatelessWidget {
  const _HourRow({required this.day, required this.hours, this.isClosed = false});
  final String day;
  final String hours;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            day,
            style: AppTextStyles.bodyMd().copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            hours,
            style: AppTextStyles.bodyMd().copyWith(
              color: isClosed ? AppColors.textSecondary.withOpacity(0.6) : AppColors.textPrimary,
              fontWeight: isClosed ? FontWeight.w500 : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Dashed Border Painter
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, this.borderRadius = 12});
  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    const double dashWidth = 5.0;
    const double dashSpace = 3.0;

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double nextDistance = distance + dashWidth;
        final Path extract = metric.extractPath(distance, nextDistance);
        canvas.drawPath(extract, paint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Preview Screen Card Widget
class _PreviewWidget extends StatelessWidget {
  const _PreviewWidget({
    required this.name,
    required this.category,
    required this.description,
    required this.phone,
    required this.address,
    required this.initials,
  });

  final String name;
  final String category;
  final String description;
  final String phone;
  final String address;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            color: AppColors.merchant,
            alignment: Alignment.center,
            child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 40),
          ),
          Padding(
            padding: const EdgeInsets.all(Sp.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.merchant.withOpacity(0.1),
                      child: Text(initials, style: TextStyle(color: AppColors.merchant, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: Sp.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.isEmpty ? 'La Saveur' : name, style: AppTextStyles.labelBold()),
                          Text(category.isEmpty ? 'Commerce' : category, style: AppTextStyles.caption()),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.md),
                Text(description, style: AppTextStyles.caption()),
                const Divider(height: Sp.lg),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(phone, style: AppTextStyles.caption()),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(address, style: AppTextStyles.caption()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

