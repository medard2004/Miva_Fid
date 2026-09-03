import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/notifications/notification_destination.dart';
import '../../client/models/app_notification.dart';
import '../../client/providers/settings_provider.dart';
import '../providers/notifications_provider.dart';

class NotificationItem {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final String title;
  final String subtitle;
  final String time;
  final String section;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final bool isUnread;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.data,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.section,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.isUnread = false,
  });
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'all'; // 'all' | 'unread'

  ({IconData icon, Color bg, Color color}) _visualFor(String type) {
    switch (type) {
      case 'merchant_new_client':
        return (
          icon: LucideIcons.userPlus,
          bg: const Color(0xFFEEF2FF),
          color: const Color(0xFF6366F1)
        );
      case 'reward_unlocked':
        return (
          icon: LucideIcons.gift,
          bg: const Color(0xFFFEF3C7),
          color: const Color(0xFFD97706)
        );
      case 'campaign':
        return (
          icon: LucideIcons.messageSquare,
          bg: const Color(0xFFE0F2FE),
          color: const Color(0xFF0284C7)
        );
      case 'merchant_low_sms':
      case 'merchant_sms_low':
        return (
          icon: LucideIcons.triangleAlert,
          bg: const Color(0xFFFEF3C7),
          color: const Color(0xFFD97706)
        );
      case 'merchant_sms_depleted':
        return (
          icon: LucideIcons.alertCircle,
          bg: const Color(0xFFFEE2E2),
          color: const Color(0xFFDC2626)
        );
      case 'fraud_alert':
        return (
          icon: LucideIcons.shieldAlert,
          bg: const Color(0xFFFEE2E2),
          color: const Color(0xFFDC2626)
        );
      case 'merchant_weekly_report':
        return (
          icon: LucideIcons.trendingUp,
          bg: const Color(0xFFDCFCE7),
          color: const Color(0xFF16A34A)
        );
      case 'merchant_new_review':
        return (
          icon: LucideIcons.star,
          bg: const Color(0xFFFEF3C7),
          color: const Color(0xFFD97706)
        );
      case 'merchant_campaign_sent':
        return (
          icon: LucideIcons.send,
          bg: const Color(0xFFE0F2FE),
          color: const Color(0xFF0284C7)
        );
      case 'merchant_birthday_reward':
        return (
          icon: LucideIcons.cake,
          bg: const Color(0xFFFCE7F3),
          color: const Color(0xFFDB2777)
        );
      case 'merchant_referral_new':
        return (
          icon: LucideIcons.userPlus,
          bg: const Color(0xFFEDE9FE),
          color: const Color(0xFF7C3AED)
        );
      case 'merchant_referral_valid':
        return (
          icon: LucideIcons.userCheck,
          bg: const Color(0xFFDCFCE7),
          color: const Color(0xFF16A34A)
        );
      default:
        return (
          icon: LucideIcons.bell,
          bg: const Color(0xFFF3E8FF),
          color: const Color(0xFF9333EA)
        );
    }
  }

  String _sectionFor(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inDays == 0 && now.day == timestamp.day) return "AUJOURD'HUI";
    if (diff.inDays < 7) return 'CETTE SEMAINE';
    return 'PLUS ANCIEN';
  }

  List<NotificationItem> _toItems(List<AppNotification> notifications) {
    return notifications.map((n) {
      final visual = _visualFor(n.type);
      return NotificationItem(
        id: n.id,
        type: n.type,
        data: n.data,
        title: n.title,
        subtitle: n.message,
        time: n.relativeTime,
        section: _sectionFor(n.timestamp),
        icon: visual.icon,
        iconBg: visual.bg,
        iconColor: visual.color,
        isUnread: !n.isRead,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final notificationsAsync = ref.watch(merchantNotificationsNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: Color(0xFF111827), size: 22),
          onPressed: () => context.pop(),
        ),
        title: notificationsAsync.when(
          data: (notifications) {
            final unreadCount = notifications.where((n) => !n.isRead).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  '$unreadCount non lues',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            );
          },
          loading: () => const Text(
            'Notifications',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827)),
          ),
          error: (_, __) => const Text(
            'Notifications',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings,
                color: Color(0xFF4B5563), size: 20),
            onPressed: () => context.push('/merchant/more/preferences'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Impossible de charger les notifications.',
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ),
        data: (notifications) {
          final items = _toItems(notifications);
          final unreadCount = items.where((n) => n.isUnread).length;

          final filtered = _selectedFilter == 'unread'
              ? items.where((n) => n.isUnread).toList()
              : items;

          final sections = <String, List<NotificationItem>>{};
          for (final item in filtered) {
            sections.putIfAbsent(item.section, () => []).add(item);
          }

          return Column(
            children: [
              // ── FILTER TABS ROW ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Toutes',
                      isSelected: _selectedFilter == 'all',
                      onTap: () => setState(() => _selectedFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Non lues',
                      count: unreadCount,
                      isSelected: _selectedFilter == 'unread',
                      onTap: () => setState(() => _selectedFilter = 'unread'),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: unreadCount > 0
                          ? () => ref
                              .read(merchantNotificationsNotifierProvider
                                  .notifier)
                              .markAllRead()
                          : null,
                      icon: const Icon(LucideIcons.check,
                          size: 16, color: Color(0xFF6366F1)),
                      label: const Text(
                        'Tout lire',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── LIST OF NOTIFICATIONS BY SECTION ──
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune notification',
                          style:
                              TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        children: [
                          for (final section in sections.keys) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 4, top: 12, bottom: 8),
                              child: Text(
                                section,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6B7280),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Column(
                                children: [
                                  for (var i = 0;
                                      i < sections[section]!.length;
                                      i++) ...[
                                    _buildNotificationTile(
                                        sections[section]![i]),
                                    if (i < sections[section]!.length - 1)
                                      const Divider(
                                          height: 1,
                                          indent: 64,
                                          color: Color(0xFFF3F4F6)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          if (items.isNotEmpty)
                            Center(
                              child: TextButton.icon(
                                onPressed: () => ref
                                    .read(merchantNotificationsNotifierProvider
                                        .notifier)
                                    .deleteAll(),
                                icon: const Icon(LucideIcons.trash2,
                                    size: 16, color: Color(0xFF6B7280)),
                                label: const Text(
                                  'Effacer toutes les notifications',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem item) {
    return InkWell(
      onTap: () {
        ref
            .read(merchantNotificationsNotifierProvider.notifier)
            .markRead(item.id);
        final destination = resolveNotificationDestination(
          type: item.type,
          data: item.data,
          title: item.title,
          body: item.subtitle,
        );
        navigateToNotificationDestination(
          context,
          destination,
          inboxPath: '/merchant/more/notifications',
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 20, color: item.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      if (item.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF4B5563),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
