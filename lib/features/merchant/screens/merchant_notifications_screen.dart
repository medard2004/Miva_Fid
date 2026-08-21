import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_toast.dart';

class NotificationItemModel {
  NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.category,
    required this.icon,
    this.isUnread = false,
  });

  final String id;
  final String title;
  final String body;
  final String time;
  final String category; // 'AUJOURD\'HUI', 'HIER', 'CETTE SEMAINE'
  final IconData icon;
  bool isUnread;
}

class MerchantNotificationsScreen extends StatefulWidget {
  const MerchantNotificationsScreen({super.key});

  @override
  State<MerchantNotificationsScreen> createState() =>
      _MerchantNotificationsScreenState();
}

class _MerchantNotificationsScreenState
    extends State<MerchantNotificationsScreen> {
  int _selectedFilter = 0; // 0: Toutes, 1: Non lues

  final List<NotificationItemModel> _notifications = [
    NotificationItemModel(
      id: '1',
      title: 'Nouveau client',
      body: 'Fafa Lawson a rejoint votre programme de fidélité.',
      time: '09:12',
      category: 'AUJOURD\'HUI',
      icon: LucideIcons.userPlus,
      isUnread: true,
    ),
    NotificationItemModel(
      id: '2',
      title: 'Récompense atteinte',
      body: 'Yawa Kpodo a complété sa carte 10/10.',
      time: '08:40',
      category: 'AUJOURD\'HUI',
      icon: LucideIcons.gift,
      isUnread: true,
    ),
    NotificationItemModel(
      id: '3',
      title: 'Quota SMS',
      body: 'Il vous reste 87 SMS sur votre forfait mensuel.',
      time: '07:55',
      category: 'AUJOURD\'HUI',
      icon: LucideIcons.gauge,
      isUnread: false,
    ),
    NotificationItemModel(
      id: '4',
      title: 'Campagne envoyée',
      body: '« Promo week-end » envoyée à 24 clients.',
      time: '18:20',
      category: 'HIER',
      icon: LucideIcons.messageSquare,
      isUnread: true,
    ),
    NotificationItemModel(
      id: '5',
      title: 'Client de retour',
      body: 'Mawuli Dossou est revenu après 12 jours.',
      time: '15:05',
      category: 'HIER',
      icon: LucideIcons.userCheck,
      isUnread: false,
    ),
    NotificationItemModel(
      id: '6',
      title: 'Rapport hebdomadaire',
      body: '43 validations cette semaine, +8 nouveaux clients.',
      time: 'Lundi',
      category: 'CETTE SEMAINE',
      icon: LucideIcons.fileText,
      isUnread: false,
    ),
  ];

  int get _unreadCount => _notifications.where((n) => n.isUnread).length;

  void _markAllAsRead() {
    setState(() {
      for (final item in _notifications) {
        item.isUnread = false;
      }
    });
    AppToast.success(context, 'Toutes les notifications marquées comme lues');
  }

  Future<void> _clearAll() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Effacer les notifications ?',
      message: 'Toutes vos notifications seront définitivement supprimées.',
      confirmLabel: 'Effacer',
      destructive: true,
    );
    if (!confirmed) return;

    setState(() {
      _notifications.clear();
    });
    if (mounted) {
      AppToast.info(context, 'Notifications effacées');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 1
        ? _notifications.where((n) => n.isUnread).toList()
        : _notifications;

    final categories = ['AUJOURD\'HUI', 'HIER', 'CETTE SEMAINE'];

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.h2().copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: _unreadCount > 0 ? _markAllAsRead : null,
            icon: const Icon(LucideIcons.check, size: 16, color: AppColors.merchant),
            label: Text(
              'Tout lire',
              style: AppTextStyles.caption().copyWith(
                color: _unreadCount > 0 ? AppColors.merchant : AppColors.gray400,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border.withValues(alpha: 0.5), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter Pills
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.md, Sp.md, Sp.md, Sp.sm),
              child: Row(
                children: [
                  _FilterPill(
                    label: 'Toutes',
                    isSelected: _selectedFilter == 0,
                    onTap: () => setState(() => _selectedFilter = 0),
                  ),
                  const SizedBox(width: Sp.sm),
                  _FilterPill(
                    label: 'Non lues ($_unreadCount)',
                    isSelected: _selectedFilter == 1,
                    onTap: () => setState(() => _selectedFilter = 1),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.bellOff, size: 48, color: AppColors.gray400),
                          const SizedBox(height: Sp.sm),
                          Text(
                            _selectedFilter == 1
                                ? 'Aucune notification non lue'
                                : 'Aucune notification',
                            style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
                      children: [
                        for (final category in categories) ...[
                          if (filtered.any((n) => n.category == category)) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 14, bottom: 8),
                              child: Text(
                                category,
                                style: AppTextStyles.caption().copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            for (final item in filtered.where((n) => n.category == category))
                              _NotificationCard(
                                item: item,
                                onTap: () {
                                  setState(() {
                                    item.isUnread = false;
                                  });
                                },
                              ),
                          ],
                        ],
                        const SizedBox(height: Sp.lg),
                        if (_notifications.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: Sp.md),
                            child: OutlinedButton.icon(
                              onPressed: _clearAll,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(LucideIcons.trash2, color: AppColors.danger, size: 18),
                              label: Text(
                                'Effacer',
                                style: AppTextStyles.labelBold().copyWith(
                                  color: AppColors.danger,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: Sp.xl),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1B4B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1E1B4B).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

  final NotificationItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: item.isUnread ? const Color(0xFFF7F5FE) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isUnread ? const Color(0xFFDDD6FE) : AppColors.border,
          width: item.isUnread ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.isUnread
                      ? AppColors.merchant.withValues(alpha: 0.1)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: item.isUnread ? AppColors.merchant : AppColors.gray600,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.title,
                          style: AppTextStyles.labelBold().copyWith(
                            fontSize: 14.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (item.isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.merchant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.time,
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.gray400,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
