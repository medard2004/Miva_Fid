import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_toast.dart';

class DaySchedule {
  DaySchedule({
    required this.day,
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
  });

  final String day;
  String openTime;
  String closeTime;
  bool isOpen;
}

class MerchantHoursScreen extends ConsumerStatefulWidget {
  const MerchantHoursScreen({super.key});

  @override
  ConsumerState<MerchantHoursScreen> createState() => _MerchantHoursScreenState();
}

class _MerchantHoursScreenState extends ConsumerState<MerchantHoursScreen> {
  final List<DaySchedule> _days = [
    DaySchedule(day: 'Lundi', openTime: '08:00', closeTime: '22:00', isOpen: true),
    DaySchedule(day: 'Mardi', openTime: '08:00', closeTime: '22:00', isOpen: true),
    DaySchedule(day: 'Mercredi', openTime: '08:00', closeTime: '22:00', isOpen: true),
    DaySchedule(day: 'Jeudi', openTime: '08:00', closeTime: '22:00', isOpen: true),
    DaySchedule(day: 'Vendredi', openTime: '08:00', closeTime: '22:00', isOpen: true),
    DaySchedule(day: 'Samedi', openTime: '08:00', closeTime: '22:00', isOpen: true),
    DaySchedule(day: 'Dimanche', openTime: '08:00', closeTime: '22:00', isOpen: false),
  ];

  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _saving = false);
      AppToast.success(context, 'Horaires enregistrés !');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back Button
              GestureDetector(
                onTap: () => context.pop(),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    const Icon(LucideIcons.chevronLeft, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Paramètres',
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.sm),

              // Title
              Text(
                'Horaires d\'ouverture',
                style: AppTextStyles.h1().copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Sp.md),

              // Days Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < _days.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Day Name
                            SizedBox(
                              width: 85,
                              child: Text(
                                _days[i].day,
                                style: AppTextStyles.labelBold().copyWith(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Time inputs or "Fermé"
                            Expanded(
                              child: _days[i].isOpen
                                  ? Row(
                                      children: [
                                        _TimeBox(time: _days[i].openTime),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6),
                                          child: Text('–', style: TextStyle(color: AppColors.gray400)),
                                        ),
                                        _TimeBox(time: _days[i].closeTime),
                                      ],
                                    )
                                  : Text(
                                      'Fermé',
                                      style: AppTextStyles.bodyMd().copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 13.5,
                                      ),
                                    ),
                            ),

                            // Switch
                            Switch(
                              value: _days[i].isOpen,
                              activeTrackColor: AppColors.merchant,
                              inactiveTrackColor: const Color(0xFFF3F4F6),
                              onChanged: (val) {
                                setState(() {
                                  _days[i].isOpen = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if (i < _days.length - 1)
                        const Divider(height: 1, color: AppColors.gray100),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Sp.xl),

              // Save Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.merchant,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Enregistrer les modifications',
                          style: AppTextStyles.labelBold().copyWith(color: Colors.white, fontSize: 15),
                        ),
                ),
              ),
              const SizedBox(height: Sp.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        time,
        style: AppTextStyles.bodyMd().copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
