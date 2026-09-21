import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/core/notifications/notification_destination.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';

enum NotificationFilter { all, unread, rewards, offers, activity }

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationFilter _filter = NotificationFilter.all;

  IconData _iconFor(String type) {
    switch (type) {
      case 'reward_unlocked':
        return LucideIcons.gift;
      case 'referral_pending':
      case 'referral_validated':
        return LucideIcons.users;
      case 'birthday':
        return LucideIcons.gift;
      case 'campaign':
      case 'announcement':
      case 'admin_broadcast':
        return LucideIcons.megaphone;
      case 'promotion':
        return LucideIcons.tag;
      case 'reminder':
        return LucideIcons.bellRing;
      case 'review':
        return LucideIcons.star;
      case 'reward':
        return LucideIcons.gift;
      case 'progress':
        return LucideIcons.trendingUp;
      case 'cashback':
        return LucideIcons.wallet;
      case 'referral':
        return LucideIcons.userPlus;
      case 'stamp_added':
        return LucideIcons.stamp;
      case 'points_added':
        return LucideIcons.coins;
      case 'stamp_removed':
      case 'points_removed':
        return LucideIcons.undo2;
      case 'cashback_received':
      case 'cashback_redeemed':
        return LucideIcons.wallet;
      case 'level_up':
        return LucideIcons.trophy;
      default:
        return LucideIcons.info;
    }
  }

  bool _matchesFilter(dynamic n, NotificationFilter filter) {
    switch (filter) {
      case NotificationFilter.all:
        return true;
      case NotificationFilter.unread:
        return !n.isRead;
      case NotificationFilter.rewards:
        return n.type == 'reward_unlocked' ||
            n.type == 'reward' ||
            n.type == 'birthday';
      case NotificationFilter.offers:
        return n.type == 'campaign' ||
            n.type == 'announcement' ||
            n.type == 'admin_broadcast' ||
            n.type == 'promotion';
      case NotificationFilter.activity:
        return n.type == 'stamp_added' ||
            n.type == 'points_added' ||
            n.type == 'stamp_removed' ||
            n.type == 'points_removed' ||
            n.type == 'cashback_received' ||
            n.type == 'cashback_redeemed' ||
            n.type == 'level_up' ||
            n.type == 'referral_pending' ||
            n.type == 'referral_validated' ||
            n.type == 'referral';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final allNotifications = ref.watch(notificationsProvider);
    final unreadCount = allNotifications.where((n) => !n.isRead).length;

    final filteredList = allNotifications
        .where((n) => _matchesFilter(n, _filter))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(
        title: t.notificationsTitle,
        trailing: TextButton(
          onPressed: () =>
              ref.read(notificationsProvider.notifier).markAllRead(),
          child: Text(t.notificationsMarkAllRead,
              style: AppTextStyles.bodySmall(color: AppColors.primary)),
        ),
      ),
      body: Column(
        children: [
          // ── Barre de filtre / tri ──────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Toutes',
                  count: allNotifications.length,
                  selected: _filter == NotificationFilter.all,
                  onTap: () => setState(() => _filter = NotificationFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Non lues',
                  count: unreadCount,
                  selected: _filter == NotificationFilter.unread,
                  onTap: () => setState(() => _filter = NotificationFilter.unread),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Récompenses',
                  selected: _filter == NotificationFilter.rewards,
                  onTap: () => setState(() => _filter = NotificationFilter.rewards),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Offres',
                  selected: _filter == NotificationFilter.offers,
                  onTap: () => setState(() => _filter = NotificationFilter.offers),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Activité',
                  selected: _filter == NotificationFilter.activity,
                  onTap: () => setState(() => _filter = NotificationFilter.activity),
                ),
              ],
            ),
          ),

          // ── Liste des notifications ───────────────────────────────────────
          Expanded(
            child: filteredList.isEmpty
                ? (allNotifications.isEmpty
                    ? _EmptyNotifications(t: t)
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: EmptyState(
                            compact: true,
                            icon: LucideIcons.filterX,
                            title: 'Aucune notification',
                            message:
                                'Aucune notification ne correspond au filtre sélectionné.',
                          ),
                        ),
                      ))
                : RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceCard,
                    onRefresh: () =>
                        ref.read(notificationsProvider.notifier).load(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final n = filteredList[i];
                        return Dismissible(
                          key: ValueKey(n.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Supprimer la notification'),
                                content: const Text(
                                  'Voulez-vous vraiment supprimer cette notification ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text(
                                      'Supprimer',
                                      style: TextStyle(color: Color(0xFFDC2626)),
                                    ),
                                  ),
                                ],
                              ),
                            ) ?? false;
                          },
                          onDismissed: (_) =>
                              ref.read(notificationsProvider.notifier).remove(n.id),
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
                          ),
                          child: AppTapScale(
                            onTap: () {
                              ref.read(notificationsProvider.notifier).markRead(n.id);
                              final destination = resolveNotificationDestination(
                                type: n.type,
                                data: n.data,
                                title: n.title,
                                body: n.message,
                              );
                              navigateToNotificationDestination(context, destination);
                            },
                            scaleDown: 0.985,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: n.isRead
                                    ? AppColors.surfaceCard
                                    : AppColors.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: n.isRead
                                      ? AppColors.border
                                      : AppColors.primary.withValues(alpha: 0.25),
                                  width: n.isRead ? 0.8 : 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: n.isRead
                                          ? AppColors.surfaceMuted
                                          : AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _iconFor(n.type),
                                      color: n.isRead
                                          ? AppColors.inkMuted(opacity: 0.7)
                                          : AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n.title,
                                                style: AppTextStyles.label().copyWith(
                                                  fontSize: 13,
                                                  fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w700,
                                                  color: n.isRead ? AppColors.ink : AppColors.primary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              n.relativeTime,
                                              style: AppTextStyles.monoSmall(
                                                color: AppColors.inkMuted(opacity: 0.55),
                                              ).copyWith(fontSize: 11),
                                            ),
                                            if (!n.isRead) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          n.message,
                                          style: AppTextStyles.bodyMedium(
                                            color: n.isRead
                                                ? AppColors.inkMuted(opacity: 0.8)
                                                : AppColors.ink,
                                          ).copyWith(fontSize: 13, height: 1.35),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTapScale(
      onTap: onTap,
      scaleDown: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : AppColors.inkMuted(opacity: 0.85),
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  final AppLocalizations t;
  const _EmptyNotifications({required this.t});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: LucideIcons.bell,
        title: t.notificationsEmptyTitle,
        message: t.notificationsEmptyMessage,
      ),
    );
  }
}
