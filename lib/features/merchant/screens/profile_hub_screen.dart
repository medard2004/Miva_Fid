import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';
import '../providers/merchant_provider.dart';

class ProfileHubScreen extends ConsumerWidget {
  const ProfileHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final merchant = ref.watch(merchantNotifierProvider).value;
    final merchantName = merchant?.name.isNotEmpty == true
        ? merchant!.name
        : 'Restaurant La Saveur';
    final city = merchant?.address?.isNotEmpty == true ? 'Lomé' : 'Lomé';
    final category = 'Restaurant';
    final initials = merchant?.initials ?? 'RL';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 24),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t.merchantMoreBusinessProfile, // Using profile translation as a fallback
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── COMPLÉTER MON PROFIL 2/5 CARD (Moved from main screen) ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.merchantMoreCompleteProfile,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '2/5',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 5,
                        width: double.infinity,
                        color: AppColors.border,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.4,
                          child: Container(color: const Color(0xFF5B50EC)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTaskRow(
                      title: t.merchantMoreLogoBusiness,
                      onTap: () => context.push('/merchant/more/profile'),
                    ),
                    Divider(height: 16, color: AppColors.border),
                    _buildTaskRow(
                      title: t.merchantMoreSocials,
                      onTap: () => context.push('/merchant/more/socials'),
                    ),
                    Divider(height: 16, color: AppColors.border),
                    _buildTaskRow(
                      title: t.merchantMoreGoogleReviewLink,
                      onTap: () => context.push('/merchant/more/profile'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              _buildGroupCard([
                _buildMenuItem(
                  icon: LucideIcons.user,
                  label: t.merchantMoreBusinessProfile,
                  onTap: () => context.push('/merchant/more/profile'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.clock,
                  label: t.merchantMoreHours,
                  onTap: () => context.push('/merchant/more/hours'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.link,
                  label: t.merchantMoreSocials,
                  tag: t.merchantMoreToComplete,
                  onTap: () => context.push('/merchant/more/socials'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.users,
                  label: t.merchantMoreTeam,
                  tag: '3',
                  onTap: () => context.push('/merchant/more/team'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.qrCode,
                  label: t.merchantMoreMyQrCode,
                  onTap: () => context.push('/merchant/more/account/qrcode'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.globe,
                  label: t.merchantMoreMyShowcase,
                  onTap: () => context.push('/merchant/more/account/vitrine'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Column(
            children: [
              item,
              if (idx < children.length - 1)
                Divider(height: 1, indent: 48, color: AppColors.border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskRow({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textSecondary,
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    String? tag,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (tag != null) ...[
              Text(
                tag,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
