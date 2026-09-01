import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/22890123456?text=Bonjour%20Miva-Fid,%20j\'ai%20besoin%20d\'aide.');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.confirm(
      context,
      title: t.merchantSignOutConfirmTitle,
      message: t.merchantSignOutConfirmMessage,
      confirmLabel: t.merchantSignOutConfirm,
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(merchantAuthProvider.notifier).signOut();
    if (context.mounted) context.go('/auth/merchant/auth');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final merchant = ref.watch(merchantNotifierProvider).value;
    final merchantName = merchant?.name.isNotEmpty == true
        ? merchant!.name
        : 'Restaurant La Saveur';
    final city = merchant?.address?.isNotEmpty == true
        ? 'Lomé'
        : 'Lomé';
    const category = 'Restaurant';
    final initials = merchant?.initials ?? 'RL';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP HEADER (STATIC) ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.settings,
                      color: Color(0xFF5B50EC),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.merchantNavSettings,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/merchant/more/notifications'),
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            LucideIcons.bell,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── SCROLLABLE BODY ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. PROFIL DU COMMERCE CARD ────────────────────────
              InkWell(
                onTap: () => context.push('/merchant/more/profile'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Color(0xFF5B50EC),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              merchantName,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$category • $city',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── 2. COMPLÉTER MON PROFIL 2/5 CARD ────────────────────────
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
              const SizedBox(height: 20),

              // ── 3. SECTION COMPTE ────────────────────────────────────────
              _buildSectionLabel(t.merchantMoreSectionAccount),
              const SizedBox(height: 8),
              _buildGroupCard([
                _buildMenuItem(
                  icon: LucideIcons.user,
                  label: t.merchantMoreBusinessProfile,
                  onTap: () => context.push('/merchant/more/profile'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.link,
                  label: t.merchantMoreSocials,
                  tag: t.merchantMoreToComplete,
                  onTap: () => context.push('/merchant/more/socials'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.creditCard,
                  label: t.merchantMoreSubscription,
                  tag: t.merchantMoreProTag,
                  onTap: () => context.push('/merchant/more/subscription'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.sliders,
                  label: t.settingsPreferences,
                  onTap: () => context.push('/merchant/more/preferences'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.globe,
                  label: t.merchantMoreLanguageTheme,
                  tag: locale.languageCode == 'en'
                      ? t.settingsLanguageEnglish
                      : t.settingsLanguageFrench,
                  onTap: () => context.push('/merchant/more/language'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.users,
                  label: t.merchantMoreTeam,
                  tag: '3',
                  onTap: () => context.push('/merchant/more/team'),
                ),
              ]),
              const SizedBox(height: 20),

              // ── 4. SECTION MA CARTE DE FIDÉLITÉ ──────────────────────────
              _buildSectionLabel(t.merchantMoreSectionLoyaltyCard),
              const SizedBox(height: 8),
              _buildGroupCard([
                _buildMenuItem(
                  icon: LucideIcons.creditCard,
                  label: t.merchantMoreCustomizeCard,
                  onTap: () => context.push('/merchant/more/programme/design'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.gift,
                  label: t.merchantMoreGoalReward,
                  tag: '10 visites',
                  onTap: () => context.push('/merchant/more/programme/tiers'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.qrCode,
                  label: t.merchantMoreMyQrCode,
                  onTap: () => context.push('/merchant/more/qrcode'),
                ),
              ]),
              const SizedBox(height: 20),

              // ── 5. SECTION ASSISTANCE ────────────────────────────────────
              _buildSectionLabel(t.merchantMoreSectionSupport),
              const SizedBox(height: 8),
              _buildGroupCard([
                _buildMenuItem(
                  icon: LucideIcons.shieldCheck,
                  label: t.merchantMoreLegalPrivacy,
                  onTap: () => context.push('/client/legal/privacy'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.fileText,
                  label: t.merchantMoreLegalTerms,
                  onTap: () => context.push('/client/legal/terms'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.messageCircle,
                  label: t.merchantMoreWhatsappSupport,
                  onTap: _launchWhatsApp,
                ),
              ]),
              const SizedBox(height: 20),

              // ── 6. SE DÉCONNECTER BUTTON ─────────────────────────────────
              InkWell(
                onTap: () => _signOut(context, ref),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.dangerTint),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Text(
                        t.settingsSignOut,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── 7. FOOTER ────────────────────────────────────────────────
              Center(
                child: Text(
                  'Miva-Fid v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ],
  ),
),
);
}

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.6,
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
