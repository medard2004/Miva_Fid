import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'merchant_provider.dart';

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

@riverpod
Future<DashboardStats> dashboardStats(DashboardStatsRef ref) async {
  final merchant = await ref.watch(merchantNotifierProvider.future);
  if (merchant == null) return const DashboardStats(
    totalClients: 0, stampsToday: 0, activeRewards: 0, recentActivity: []);

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

  final clients = await Supabase.instance.client
      .from('loyalty_cards')
      .select('id')
      .eq('merchant_id', merchant.id);

  final todayStamps = await Supabase.instance.client
      .from('stamps')
      .select('id')
      .eq('merchant_id', merchant.id)
      .gte('validated_at', todayStart);

  final rewards = await Supabase.instance.client
      .from('rewards')
      .select('id')
      .eq('merchant_id', merchant.id)
      .eq('status', 'available');

  final recentStamps = await Supabase.instance.client
      .from('stamps')
      .select('validated_at, users(name)')
      .eq('merchant_id', merchant.id)
      .order('validated_at', ascending: false)
      .limit(10);

  final activity = (recentStamps as List).map((s) {
    final name = (s['users'] as Map?)?['name'] as String? ?? 'Client';
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (name.isNotEmpty ? name[0].toUpperCase() : '?');
    final dt = DateTime.tryParse(s['validated_at'] as String? ?? '') ?? DateTime.now();
    final diff = DateTime.now().difference(dt);
    final timeStr = diff.inMinutes < 60
        ? 'il y a ${diff.inMinutes} min'
        : diff.inHours < 24
            ? 'il y a ${diff.inHours}h'
            : 'hier';
    return ActivityItem(
      clientName: name,
      action: 'Tampon accordé',
      time: timeStr,
      initials: initials,
    );
  }).toList();

  return DashboardStats(
    totalClients: (clients as List).length,
    stampsToday: (todayStamps as List).length,
    activeRewards: (rewards as List).length,
    recentActivity: activity,
  );
}
