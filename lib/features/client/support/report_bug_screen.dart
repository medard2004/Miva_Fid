import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:miva_fid/core/utils/loading_overlay_service.dart';
import 'package:miva_fid/core/utils/toast_service.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Écran Signaler un bug — Épuré avec sélection de catégorie en champ et formulaires soignés.
class ReportBugScreen extends ConsumerStatefulWidget {
  const ReportBugScreen({super.key});

  @override
  ConsumerState<ReportBugScreen> createState() => _ReportBugScreenState();
}

class _ReportBugScreenState extends ConsumerState<ReportBugScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'display';
  bool _isSubmitting = false;

  final List<({String id, String label, IconData icon})> _categories = const [
    (id: 'display', label: 'Affichage / UI', icon: LucideIcons.layoutGrid),
    (id: 'scan', label: 'Scan QR Code', icon: LucideIcons.qrCode),
    (id: 'rewards', label: 'Récompenses', icon: LucideIcons.gift),
    (id: 'gps', label: 'Localisation / Plan', icon: LucideIcons.mapPin),
    (id: 'account', label: 'Compte & Connexion', icon: LucideIcons.user),
    (id: 'other', label: 'Autre problème', icon: LucideIcons.circleHelp),
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Text(
                  'Choisir une catégorie',
                  style: AppTextStyles.titleMedium().copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ..._categories.map((cat) {
                  final isSelected = _selectedCategory == cat.id;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedCategory = cat.id);
                      Navigator.of(ctx).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            cat.icon,
                            size: 18,
                            color: isSelected ? AppColors.primary : AppColors.inkMuted(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cat.label,
                              style: AppTextStyles.bodyMedium().copyWith(
                                color: isSelected ? AppColors.primary : AppColors.ink,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(LucideIcons.check, size: 18, color: AppColors.primary),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitReport(AppLocalizations t) async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    LoadingOverlayService.show(message: 'Envoi du signalement...');

    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));

      await LoadingOverlayService.hide();
      if (!mounted) return;

      ToastService.showSuccess(t.reportBugSuccess);
      context.pop();
    } catch (_) {
      await LoadingOverlayService.hide();
      if (mounted) {
        ToastService.showError('Une erreur est survenue');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    final currentCat = _categories.firstWhere(
      (c) => c.id == _selectedCategory,
      orElse: () => _categories.first,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(
        title: t.reportBugTitle.toUpperCase(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sélecteur de catégorie stylé avec contour
                Text(
                  'Catégorie'.toUpperCase(),
                  style: AppTextStyles.eyebrow(color: AppColors.inkMuted()),
                ),
                const SizedBox(height: 8),
                AppTapScale(
                  onTap: _showCategoryPicker,
                  scaleDown: 0.98,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(currentCat.icon, size: 18, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            currentCat.label,
                            style: AppTextStyles.bodyMedium().copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(LucideIcons.chevronDown, size: 18, color: AppColors.inkMuted()),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Sujet
                Text(
                  'Sujet'.toUpperCase(),
                  style: AppTextStyles.eyebrow(color: AppColors.inkMuted()),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _subjectController,
                  style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ex: Le QR code ne s\'affiche pas',
                    hintStyle: AppTextStyles.bodyMedium(
                      color: AppColors.inkMuted(opacity: 0.4),
                    ).copyWith(fontSize: 13.5),
                    filled: true,
                    fillColor: AppColors.surfaceCard,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFEF4444)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Veuillez saisir un sujet';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Description
                Text(
                  'Description'.toUpperCase(),
                  style: AppTextStyles.eyebrow(color: AppColors.inkMuted()),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Expliquez brièvement le problème rencontré...',
                    hintStyle: AppTextStyles.bodyMedium(
                      color: AppColors.inkMuted(opacity: 0.4),
                    ).copyWith(fontSize: 13.5),
                    filled: true,
                    fillColor: AppColors.surfaceCard,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFEF4444)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Veuillez décrire le problème rencontré';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Footnote appareil
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.smartphone,
                        size: 13,
                        color: AppColors.inkMuted(opacity: 0.45),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${Platform.operatingSystem.toUpperCase()} · Miva-Fid v1.0.0${user != null ? ' · ${user.phoneNumber}' : ''}',
                          style: AppTextStyles.monoSmall(
                            color: AppColors.inkMuted(opacity: 0.5),
                          ).copyWith(fontSize: 10.5),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                AppButton(
                  label: 'Envoyer le signalement',
                  icon: LucideIcons.send,
                  fullWidth: true,
                  height: 46,
                  loading: _isSubmitting,
                  onTap: () => _submitReport(t),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
