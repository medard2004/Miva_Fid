import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/core/notifications/notification_destination.dart';
import 'package:miva_fid/core/widgets/app_dialog.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/models/app_notification.dart';
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

  ({IconData icon, Color color}) _styleFor(String type) {
    switch (type) {
      case 'reward_unlocked':
      case 'reward':
      case 'birthday':
        return (icon: LucideIcons.gift, color: const Color(0xFF10B981));
      case 'referral_pending':
      case 'referral_validated':
      case 'referral':
        return (icon: LucideIcons.users, color: const Color(0xFF8B5CF6));
      case 'campaign':
      case 'announcement':
      case 'admin_broadcast':
        return (icon: LucideIcons.megaphone, color: const Color(0xFF3B82F6));
      case 'promotion':
        return (icon: LucideIcons.tag, color: const Color(0xFFEC4899));
      case 'reminder':
        return (icon: LucideIcons.bellRing, color: const Color(0xFFF59E0B));
      case 'review':
        return (icon: LucideIcons.star, color: const Color(0xFFEAB308));
      case 'progress':
      case 'level_up':
        return (icon: LucideIcons.trophy, color: const Color(0xFFF59E0B));
      case 'cashback':
      case 'cashback_received':
      case 'cashback_redeemed':
        return (icon: LucideIcons.wallet, color: const Color(0xFF10B981));
      case 'stamp_added':
      case 'points_added':
        return (icon: LucideIcons.sparkles, color: AppColors.primary);
      case 'stamp_removed':
      case 'points_removed':
        return (icon: LucideIcons.undo2, color: const Color(0xFFEF4444));
      default:
        return (icon: LucideIcons.bell, color: AppColors.primary);
    }
  }

  bool _matchesFilter(AppNotification n, NotificationFilter filter) {
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
        trailing: unreadCount > 0
            ? TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).markAllRead(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  t.notificationsMarkAllRead,
                  style: AppTextStyles.bodySmall(color: AppColors.primary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // ── Filtres ouverts et épurés ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _OpenFilterChip(
                    label: 'Toutes',
                    count: allNotifications.length,
                    selected: _filter == NotificationFilter.all,
                    onTap: () => setState(() => _filter = NotificationFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _OpenFilterChip(
                    label: 'Non lues',
                    count: unreadCount,
                    selected: _filter == NotificationFilter.unread,
                    onTap: () => setState(() => _filter = NotificationFilter.unread),
                  ),
                  const SizedBox(width: 8),
                  _OpenFilterChip(
                    label: 'Récompenses',
                    selected: _filter == NotificationFilter.rewards,
                    onTap: () => setState(() => _filter = NotificationFilter.rewards),
                  ),
                  const SizedBox(width: 8),
                  _OpenFilterChip(
                    label: 'Offres',
                    selected: _filter == NotificationFilter.offers,
                    onTap: () => setState(() => _filter = NotificationFilter.offers),
                  ),
                  const SizedBox(width: 8),
                  _OpenFilterChip(
                    label: 'Activité',
                    selected: _filter == NotificationFilter.activity,
                    onTap: () => setState(() => _filter = NotificationFilter.activity),
                  ),
                ],
              ),
            ),
          ),

          // ── Liste ouverte des notifications ──────────────────────────────────
          Expanded(
            child: filteredList.isEmpty
                ? (allNotifications.isEmpty
                    ? _EmptyNotifications(t: t)
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: EmptyState(
                            compact: true,
                            icon: LucideIcons.filterX,
                            title: 'Aucune notification',
                            message:
                                'Aucune notification ne correspond à ce filtre.',
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
                      padding: const EdgeInsets.only(bottom: 24, top: 4),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        indent: 72,
                        endIndent: 16,
                        color: AppColors.border,
                      ),
                      itemBuilder: (context, i) {
                        final n = filteredList[i];
                        final style = _styleFor(n.type);

                        return Dismissible(
                          key: ValueKey(n.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            return await AppDialog.confirm(
                              context,
                              title: 'Supprimer la notification',
                              message:
                                  'Voulez-vous vraiment supprimer cette notification ?',
                              confirmLabel: 'Supprimer',
                              cancelLabel: 'Annuler',
                              destructive: true,
                              icon: LucideIcons.trash2,
                            );
                          },
                          onDismissed: (_) =>
                              ref.read(notificationsProvider.notifier).remove(n.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            child: const Icon(
                              LucideIcons.trash2,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                          ),
                          child: InkWell(
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
                            splashColor: AppColors.primary.withValues(alpha: 0.06),
                            highlightColor: AppColors.primary.withValues(alpha: 0.03),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Icône douce et ouverte sans boîte rigide ──
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: style.color.withValues(alpha: n.isRead ? 0.08 : 0.14),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      style.icon,
                                      color: n.isRead
                                          ? style.color.withValues(alpha: 0.75)
                                          : style.color,
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // ── Contenu texte aéré ─────────────────────────
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n.title,
                                                style: AppTextStyles.label().copyWith(
                                                  fontSize: 14,
                                                  fontWeight: n.isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                  color: n.isRead
                                                      ? AppColors.ink
                                                      : AppColors.primary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              n.relativeTime,
                                              style: AppTextStyles.monoSmall(
                                                color: AppColors.inkMuted(opacity: 0.5),
                                              ).copyWith(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          n.message,
                                          style: AppTextStyles.bodyMedium(
                                            color: n.isRead
                                                ? AppColors.inkMuted(opacity: 0.7)
                                                : AppColors.ink,
                                          ).copyWith(
                                            fontSize: 13,
                                            height: 1.35,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ── Point lumineux épuré pour les non-lues ────
                                  if (!n.isRead) ...[
                                    const SizedBox(width: 10),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.4),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
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

/// Filtre ouvert et moderne (sans cadre rectangulaire lourd)
class _OpenFilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _OpenFilterChip({
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.surfaceMuted.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : AppColors.inkMuted(opacity: 0.8),
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: EmptyState(
          icon: LucideIcons.bell,
          title: t.notificationsEmptyTitle,
          message: t.notificationsEmptyMessage,
        ),
      ),
    );
  }
}
