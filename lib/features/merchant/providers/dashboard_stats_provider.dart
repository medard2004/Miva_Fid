import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/api_providers.dart';
import 'merchant_auth_provider.dart';

part 'dashboard_stats_provider.g.dart';

class KpiData {
  const KpiData({required this.label, required this.value});
  final String label;
  final int value;
}

class ActivityItem {
  const ActivityItem({
    required this.clientName,
    required this.action,
    required this.time,
    required this.initials,
  });
  final String clientName;
  final String action;
  final String time;
  final String initials;
}

class DashboardStats {
  const DashboardStats({
    required this.totalClients,
    required this.stampsToday,
    required this.activeRewards,
    required this.recentActivity,
  });
  final int totalClients;
  final int stampsToday;
  final int activeRewards;
  final List<ActivityItem> recentActivity;

  List<KpiData> get kpiPills => [
        KpiData(label: 'Clients', value: totalClients),
        KpiData(label: 'Tampons auj.', value: stampsToday),
        KpiData(label: 'Récompenses', value: activeRewards),
      ];
}

/// Statistiques du dashboard marchand (`GET /merchant/stats`) : clientèle,
/// tampons du jour, récompenses en attente et dernières validations.
@riverpod
Future<DashboardStats> dashboardStats(DashboardStatsRef ref) async {
  final restaurant = ref.watch(
    merchantAuthProvider.select((s) => s.restaurant),
  );
  if (restaurant == null) {
    return const DashboardStats(
        totalClients: 0, stampsToday: 0, activeRewards: 0, recentActivity: []);
  }

  final data = await ref.read(merchantDashboardServiceProvider).stats();

  final activity = ((data['recent_activity'] as List?) ?? []).map((raw) {
    final entry = (raw as Map).cast<String, dynamic>();
    final name = entry['client_name'] as String? ?? 'Client';
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (name.isNotEmpty ? name[0].toUpperCase() : '?');
    final dt =
        DateTime.tryParse(entry['at']?.toString() ?? '') ?? DateTime.now();
    final diff = DateTime.now().difference(dt);
    final timeStr = diff.inMinutes < 60
        ? 'il y a ${diff.inMinutes} min'
        : diff.inHours < 24
            ? 'il y a ${diff.inHours}h'
            : 'hier';
    return ActivityItem(
      clientName: name,
      action: entry['action'] as String? ?? 'Tampon accordé',
      time: timeStr,
      initials: initials,
    );
  }).toList();

  return DashboardStats(
    totalClients: data['total_clients'] as int? ?? 0,
    stampsToday: data['stamps_today'] as int? ?? 0,
    activeRewards: data['active_rewards'] as int? ?? 0,
    recentActivity: activity,
  );
}
