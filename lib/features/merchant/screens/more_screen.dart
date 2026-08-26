import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/app_dialog.dart';
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
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Se déconnecter ?',
      message: 'Vous devrez vous reconnecter pour accéder à votre espace commerçant.',
      confirmLabel: 'Se déconnecter',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(merchantAuthProvider.notifier).signOut();
    if (context.mounted) context.go('/auth/merchant/auth');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final locale = ref.watch(localeProvider);
    final merchant = ref.watch(merchantNotifierProvider).value;
    final merchantName = merchant?.name.isNotEmpty == true
        ? merchant!.name
        : 'Restaurant La Saveur';
    final city = merchant?.address?.isNotEmpty == true
        ? 'Lomé'
        : 'Lomé';
    final category = 'Restaurant';
    final initials = merchant?.initials ?? 'RL';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TOP HEADER ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.settings,
                      color: Color(0xFF5B50EC),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Paramètres',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(
                            LucideIcons.bell,
                            size: 18,
                            color: Color(0xFF1E293B),
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
              const SizedBox(height: 16),

              // ── 1. PROFIL DU COMMERCE CARD ──────────────────────────────
              InkWell(
                onTap: () => context.push('/merchant/more/profile'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEDF0F7)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEF2FF),
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
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$category • $city',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: Color(0xFF94A3B8),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEDF0F7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Compléter mon profil',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '2/5',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
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
                        color: const Color(0xFFEEF2FF),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.4,
                          child: Container(color: const Color(0xFF5B50EC)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTaskRow(
                      title: 'Logo du commerce',
                      onTap: () => context.push('/merchant/more/profile'),
                    ),
                    const Divider(height: 16, color: Color(0xFFF1F5F9)),
                    _buildTaskRow(
                      title: 'Réseaux sociaux',
                      onTap: () => context.push('/merchant/more/socials'),
                    ),
                    const Divider(height: 16, color: Color(0xFFF1F5F9)),
                    _buildTaskRow(
                      title: 'Lien d\'avis Google',
                      onTap: () => context.push('/merchant/more/profile'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 3. SECTION COMPTE ────────────────────────────────────────
              _buildSectionLabel('COMPTE'),
              const SizedBox(height: 8),
              _buildGroupCard([
                _buildMenuItem(
                  icon: LucideIcons.user,
                  label: 'Profil du commerce',
                  onTap: () => context.push('/merchant/more/profile'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.clock,
                  label: 'Horaires d\'ouverture',
                  onTap: () => context.push('/merchant/more/hours'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.link,
                  label: 'Réseaux sociaux',
                  tag: 'À compléter',
                  onTap: () => context.push('/merchant/more/socials'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.creditCard,
                  label: 'Abonnement',
                  tag: 'Pro',
                  onTap: () => context.push('/merchant/more/subscription'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.bell,
                  label: 'Notifications',
                  onTap: () => context.push('/merchant/more/notifications'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.globe,
                  label: 'Langue & thème',
                  tag: locale.languageCode == 'en' ? 'English' : 'Français',
                  onTap: () => context.push('/merchant/more/language'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.users,
                  label: 'Équipe',
                  tag: '3',
                  onTap: () => context.push('/merchant/more/team'),
                ),
              ]),
              const SizedBox(height: 20),

              // ── 4. SECTION MA CARTE DE FIDÉLITÉ ──────────────────────────
              _buildSectionLabel('MA CARTE DE FIDÉLITÉ'),
              const SizedBox(height: 8),
              _buildGroupCard([
                _buildMenuItem(
                  icon: LucideIcons.creditCard,
                  label: 'Personnaliser la carte',
                  onTap: () => context.push('/merchant/more/programme/design'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.gift,
                  label: 'Objectif & récompense',
                  tag: '10 visites',
                  onTap: () => context.push('/merchant/more/programme/tiers'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.sparkles,
                  label: 'Programme de fidélité',
                  onTap: () => context.push('/merchant/more/programme/rules'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.qrCode,
                  label: 'Mon QR code',
                  onTap: () => context.push('/merchant/more/account/qrcode'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.globe,
                  label: 'Ma vitrine',
                  onTap: () => context.push('/merchant/more/account/vitrine'),
                ),
              ]),
              const SizedBox(height: 20),

              // ── 5. SECTION ASSISTANCE ────────────────────────────────────
              _buildSectionLabel('ASSISTANCE'),
              const SizedBox(height: 8),
              _buildGroupCard([
                _buildMenuItem(
                  icon: LucideIcons.shieldCheck,
                  label: 'Confidentialité',
                  onTap: () => context.push('/client/legal/privacy'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.fileText,
                  label: 'Conditions d\'utilisation',
                  onTap: () => context.push('/client/legal/terms'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.messageCircle,
                  label: 'Support WhatsApp',
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFEE2E2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(LucideIcons.logOut, size: 18, color: Color(0xFFDC2626)),
                      SizedBox(width: 8),
                      Text(
                        'Se déconnecter',
                        style: TextStyle(
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
              const Center(
                child: Text(
                  'Miva-Fid v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF0F7)),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Column(
            children: [
              item,
              if (idx < children.length - 1)
                const Divider(height: 1, indent: 48, color: Color(0xFFF1F5F9)),
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
                color: const Color(0xFF94A3B8),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: Color(0xFF94A3B8),
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
            Icon(icon, size: 18, color: const Color(0xFF475569)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            if (tag != null) ...[
              Text(
                tag,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
