import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/clients_provider.dart';
import '../providers/merchant_provider.dart';
import '../../client/providers/settings_provider.dart';
import '../../client/models/loyalty_card.dart';
import '../../client/wallet/widgets/loyalty_card_widget.dart';

class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  /// Identifiant de la carte de fidélité (`loyalty_cards.id`) — c'est lui que
  /// `GET /merchant/clients/{card}` attend, la liste le fournit directement.
  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ces ecrans peignent via les tokens statiques d'AppColors,
    // invisibles pour le systeme de dependances de Flutter : observer
    // la luminosite effective est leur seul declencheur de rebuild sur
    // une bascule clair/sombre.
    ref.watch(appBrightnessProvider);
    final merchantAsync = ref.watch(merchantNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text('Détail client', style: AppTextStyles.h3()),
      ),
      body: FutureBuilder(
        future: ref.read(merchantDashboardServiceProvider).client(clientId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(Sp.md),
              child: Column(children: [SkeletonCard(height: 200), SkeletonCard(height: 120)]),
            );
          }
          if (snap.data == null) {
            return Center(child: Text('Client introuvable', style: AppTextStyles.bodyMd()));
          }
          final data = snap.data as Map<String, dynamic>;
          final client = data['client'] as Map<String, dynamic>?;
          final stamps = data['stamps_current'] as int? ?? 0;
          final required = merchantAsync.value?.stampsRequired ?? 10;
          final name = client?['name'] as String? ?? 'Client';
          final phone = client?['phone'] as String? ?? '';
          final email = client?['email'] as String? ?? '';
          final firstName = client?['first_name'] as String? ?? '';
          final lastName = client?['last_name'] as String? ?? '';
          final city = client?['city'] as String? ?? '';
          final country = client?['country'] as String? ?? '';
          final birthdate = client?['birthdate'] as String? ?? '';
          final avatarUrl = client?['avatar_url'] as String? ?? '';
          final cardCode = data['card_code'] as String? ?? '';
          final status = data['status'] as String? ?? 'active';
          final lastActivity = data['last_activity_at'] as String?;
          final level = data['level'] as Map<String, dynamic>?;
          final levelName = level?['name'] as String?;
          final since = DateFormatter.relative(
              DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now());

          final merchant = merchantAsync.value;
          LoyaltyMechanic mechanic = LoyaltyMechanic.stamps;
          if (merchant?.loyaltyMode == 'points') mechanic = LoyaltyMechanic.points;
          if (merchant?.loyaltyMode == 'spend') mechanic = LoyaltyMechanic.spend;
          if (merchant?.loyaltyMode == 'cashback') mechanic = LoyaltyMechanic.cashback;

          final card = LoyaltyCard(
            id: data['id']?.toString() ?? clientId,
            restaurantName: merchant?.name ?? 'Commerce',
            restaurantCategory: merchant?.category ?? '',
            mechanic: mechanic,
            liningColor: merchant?.primaryColor ?? AppColors.primary,
            secondaryColor: merchant?.secondaryColor,
            gradientType: merchant?.cardGradientType ?? 'linear',
            decorationPattern: merchant?.cardDecorationPattern ?? 'none',
            logoUrl: merchant?.logoUrl,
            stampDesignType: merchant?.stampDesignType ?? 'check',
            stampEmoji: merchant?.stampEmoji ?? '✨',
            stampIcon: merchant?.stampIcon ?? 'check_rounded',
            stampsCurrent: stamps,
            stampsGoal: required,
            pointsBalance: stamps,
            levelName: levelName,
            fallbackId: data['card_code']?.toString() ?? '',
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Sp.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profil Header ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(Sp.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: Rd.card20,
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primaryTint,
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: AppTextStyles.h1().copyWith(color: AppColors.primary),
                              )
                            : null,
                      ),
                      const SizedBox(height: Sp.sm),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: AppTextStyles.h2(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (levelName != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.merchantTint,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                levelName.toUpperCase(),
                                style: AppTextStyles.caption().copyWith(
                                  color: AppColors.merchant,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (phone.isNotEmpty)
                        Text(phone, style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary)),
                      Text('Membre depuis $since',
                          style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
                      const Divider(height: Sp.xl),
                      LoyaltyCardWidget(card: card, height: 180),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.lg),

                // ── Informations Client ─────────────────────────
                Text('Informations', style: AppTextStyles.h3()),
                const SizedBox(height: Sp.sm),
                Container(
                  padding: const EdgeInsets.all(Sp.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: Rd.card20,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      if (firstName.isNotEmpty || lastName.isNotEmpty)
                        _infoRow(LucideIcons.user, 'Nom complet', '$firstName $lastName'),
                      if (email.isNotEmpty)
                        _infoRow(LucideIcons.mail, 'E-mail', email),
                      if (phone.isNotEmpty)
                        _infoRow(LucideIcons.phone, 'Téléphone', phone),
                      if (city.isNotEmpty || country.isNotEmpty)
                        _infoRow(LucideIcons.mapPin, 'Localisation',
                            [city, country].where((s) => s.isNotEmpty).join(', ')),
                      if (birthdate.isNotEmpty)
                        _infoRow(LucideIcons.cake, 'Date de naissance', birthdate),
                      _infoRow(LucideIcons.creditCard, 'Code carte', cardCode.isNotEmpty ? cardCode : '—'),
                      _infoRow(
                        status == 'active' ? LucideIcons.circleCheck : LucideIcons.circleAlert,
                        'Statut',
                        _statusLabel(status),
                        valueColor: _statusColor(status),
                      ),
                      if (lastActivity != null)
                        _infoRow(LucideIcons.clock, 'Dernière activité',
                            DateFormatter.relative(DateTime.tryParse(lastActivity) ?? DateTime.now())),
                      _infoRow(LucideIcons.hash, 'Tampons', '$stamps / $required'),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.lg),
                
                // ── Actions Rapides ─────────────────────────────
                Text('Actions rapides', style: AppTextStyles.h3()),
                const SizedBox(height: Sp.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton.primary(
                      'Ajouter tampon',
                      icon: LucideIcons.circlePlus,
                      onPressed: () async {
                        await ref.read(clientsNotifierProvider.notifier)
                            .addBonusStamp(data['id'].toString());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tampon ajouté')));
                        }
                      },
                    ),
                    const SizedBox(height: Sp.sm),
                    AppButton.tint(
                      'Retirer tampon',
                      icon: LucideIcons.circleMinus,
                      onPressed: () => AppToast.info(context, 'Ajustement bientôt disponible'),
                    ),
                    const SizedBox(height: Sp.sm),
                    AppButton.outlined(
                      'Envoyer SMS',
                      icon: LucideIcons.messageSquare,
                      onPressed: () => AppToast.info(context, 'Marketing SMS bientôt disponible'),
                    ),
                    const SizedBox(height: Sp.sm),
                    AppButton.outlined(
                      'Historique',
                      icon: LucideIcons.history,
                      onPressed: () => _showHistorySheet(context, ref, data['id'].toString()),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.xl),
                TextButton.icon(
                  onPressed: () => AppToast.error(context, 'Suspension bientôt disponible'),
                  icon: const Icon(LucideIcons.ban, color: Colors.red),
                  label: Text('Suspendre ce client', style: AppTextStyles.bodyMd().copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: Sp.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHistorySheet(BuildContext context, WidgetRef ref, String cardId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          padding: const EdgeInsets.all(Sp.md),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: Sp.md),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text('Historique', style: AppTextStyles.h3()),
                const SizedBox(height: Sp.md),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: ref.read(merchantDashboardServiceProvider).history(cardId),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Text(
                            "Impossible de charger l'historique.",
                            style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                          ),
                        );
                      }
                      final entries = snap.data ?? const [];
                      if (entries.isEmpty) {
                        return Center(
                          child: Text(
                            'Aucune opération enregistrée pour ce client.',
                            style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: Sp.sm),
                        itemBuilder: (context, i) => _historyEntryTile(entries[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _historyEntryTile(Map<String, dynamic> entry) {
    final type = entry['type'] as String? ?? '';
    final value = entry['value'];
    final createdAt = DateTime.tryParse(entry['created_at'] as String? ?? '');
    final staffName = entry['staff_name'] as String?;
    final staffRole = entry['staff_role'] as String?;

    return Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Rd.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_historyTypeIcon(type), size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_historyTypeLabel(type, value), style: AppTextStyles.labelBold()),
                if (createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormatter.short(createdAt)} à ${DateFormatter.time(createdAt)}',
                    style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  staffName != null
                      ? 'Effectué par : $staffName — ${staffRole == 'admin' ? 'Administrateur' : 'Opérateur'}'
                      : 'Effectué par : Administrateur',
                  style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _historyTypeIcon(String type) {
    return switch (type) {
      'cashback_redeem' => LucideIcons.circleMinus,
      _ => LucideIcons.circlePlus,
    };
  }

  String _historyTypeLabel(String type, dynamic value) {
    final n = value is num ? value : 0;
    return switch (type) {
      'stamp' => n == 1 ? '+1 tampon' : '+$n points',
      'cashback_earn' => '+$n FCFA de cashback crédité',
      'cashback_redeem' => '-$n FCFA de cashback utilisé',
      _ => type,
    };
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMd().copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'active' => 'Actif',
      'reward_available' => 'Récompense disponible',
      'suspended' => 'Suspendu',
      'inactive' => 'Inactif',
      _ => status,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'active' => Colors.green,
      'reward_available' => AppColors.merchant,
      'suspended' => Colors.red,
      _ => AppColors.textSecondary,
    };
  }
}
