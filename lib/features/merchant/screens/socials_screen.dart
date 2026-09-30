import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../../client/providers/settings_provider.dart';

class _SocialPlatformConfig {
  final String key;
  final String name;
  final IconData icon;
  final Color brandColor;
  final String placeholder;
  final String helper;
  final String? prefixText;
  final TextInputType keyboardType;

  const _SocialPlatformConfig({
    required this.key,
    required this.name,
    required this.icon,
    required this.brandColor,
    required this.placeholder,
    required this.helper,
    this.prefixText,
    this.keyboardType = TextInputType.text,
  });
}

const _kAvailablePlatforms = <_SocialPlatformConfig>[
  _SocialPlatformConfig(
    key: 'whatsapp',
    name: 'WhatsApp',
    icon: SimpleIcons.whatsapp,
    brandColor: Color(0xFF25D366),
    placeholder: '+228 90 12 34 56',
    helper: 'Numéro WhatsApp pour un contact client direct en 1 clic',
    prefixText: null,
    keyboardType: TextInputType.phone,
  ),
  _SocialPlatformConfig(
    key: 'instagram',
    name: 'Instagram',
    icon: SimpleIcons.instagram,
    brandColor: Color(0xFFE1306C),
    placeholder: 'chic_coin',
    helper: 'Pseudo ou nom de votre compte Instagram',
    prefixText: '@',
    keyboardType: TextInputType.text,
  ),
  _SocialPlatformConfig(
    key: 'facebook',
    name: 'Facebook',
    icon: SimpleIcons.facebook,
    brandColor: Color(0xFF1877F2),
    placeholder: 'Botega',
    helper: 'Nom de votre page ou identifiant Facebook',
    prefixText: null,
    keyboardType: TextInputType.text,
  ),
  _SocialPlatformConfig(
    key: 'tiktok',
    name: 'TikTok',
    icon: SimpleIcons.tiktok,
    brandColor: Color(0xFF0F172A),
    placeholder: 'chez_x',
    helper: 'Pseudo ou nom de votre compte TikTok',
    prefixText: '@',
    keyboardType: TextInputType.text,
  ),
];

_SocialPlatformConfig _platformForKey(String key) {
  return _kAvailablePlatforms.firstWhere(
    (p) => p.key == key,
    orElse: () => _kAvailablePlatforms.first,
  );
}

class SocialsScreen extends ConsumerStatefulWidget {
  const SocialsScreen({super.key});

  @override
  ConsumerState<SocialsScreen> createState() => _SocialsScreenState();
}

class _SocialsScreenState extends ConsumerState<SocialsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final List<String> _selectedKeys = [];
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    for (final p in _kAvailablePlatforms) {
      final ctrl = TextEditingController();
      ctrl.addListener(_onFieldChanged);
      _controllers[p.key] = ctrl;
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _initData() {
    if (_initialized) return;
    final account = ref.read(merchantAuthProvider).restaurant;
    if (account == null) {
      _initialized = true;
      return;
    }

    final profiles = account.socialProfiles;

    for (final p in _kAvailablePlatforms) {
      final entry = profiles[p.key];
      String val = '';

      if (entry is Map) {
        val = entry['handle']?.toString() ??
            entry['name']?.toString() ??
            entry['link']?.toString() ??
            '';
      } else if (entry is String) {
        val = entry;
      }

      if (val.isEmpty) {
        switch (p.key) {
          case 'whatsapp':
            val = account.whatsapp ?? '';
            break;
          case 'instagram':
            val = account.instagram ?? '';
            break;
          case 'facebook':
            val = account.facebook ?? '';
            break;
          case 'tiktok':
            val = account.tiktok ?? '';
            break;
        }
      }

      if (p.key != 'whatsapp') {
        val = _cleanInput(p.key, val);
      }

      _controllers[p.key]!.text = val;
    }

    // Ordre sauvegardé s'il existe
    final savedOrder = (profiles['_order'] as List? ??
            account.loyaltyConfig['socials_order'] as List?)
        ?.map((e) => e.toString())
        .where((k) => _kAvailablePlatforms.any((p) => p.key == k))
        .toList();

    if (savedOrder != null && savedOrder.isNotEmpty) {
      for (final key in savedOrder) {
        if (!_selectedKeys.contains(key)) {
          _selectedKeys.add(key);
        }
      }
    }

    // Ajouter les réseaux déjà renseignés qui ne seraient pas dans l'ordre sauvegardé
    for (final p in _kAvailablePlatforms) {
      if (_controllers[p.key]!.text.trim().isNotEmpty &&
          !_selectedKeys.contains(p.key)) {
        _selectedKeys.add(p.key);
      }
    }

    _initialized = true;
  }

  void _addPlatform(String key) {
    if (_selectedKeys.contains(key)) return;
    HapticFeedback.selectionClick();

    setState(() {
      _selectedKeys.add(key);
    });
  }

  void _removePlatform(String key) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedKeys.remove(key);
      _controllers[key]?.clear();
    });
  }

  void _moveUp(int index) {
    if (index <= 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      final item = _selectedKeys.removeAt(index);
      _selectedKeys.insert(index - 1, item);
    });
  }

  void _moveDown(int index) {
    if (index >= _selectedKeys.length - 1) return;
    HapticFeedback.selectionClick();
    setState(() {
      final item = _selectedKeys.removeAt(index);
      _selectedKeys.insert(index + 1, item);
    });
  }

  String _cleanInput(String key, String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    if (key == 'instagram' || key == 'tiktok') {
      if (trimmed.startsWith('@')) {
        return trimmed.substring(1).trim();
      }
      if (trimmed.contains('instagram.com/')) {
        final parts = trimmed.split('instagram.com/');
        return parts.last.split('?').first.replaceAll('/', '').trim();
      }
      if (trimmed.contains('tiktok.com/@')) {
        final parts = trimmed.split('tiktok.com/@');
        return parts.last.split('?').first.replaceAll('/', '').trim();
      }
    } else if (key == 'facebook') {
      if (trimmed.contains('facebook.com/')) {
        final parts = trimmed.split('facebook.com/');
        return parts.last.split('?').first.replaceAll('/', '').trim();
      }
    }
    return trimmed;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final whatsapp = _selectedKeys.contains('whatsapp')
          ? _controllers['whatsapp']!.text.trim()
          : '';
      final instagram = _selectedKeys.contains('instagram')
          ? _cleanInput('instagram', _controllers['instagram']!.text)
          : '';
      final facebook = _selectedKeys.contains('facebook')
          ? _cleanInput('facebook', _controllers['facebook']!.text)
          : '';
      final tiktok = _selectedKeys.contains('tiktok')
          ? _cleanInput('tiktok', _controllers['tiktok']!.text)
          : '';

      final Map<String, dynamic> socialProfilesPayload = {};
      for (final key in _selectedKeys) {
        final raw = _controllers[key]!.text.trim();
        final cleaned = _cleanInput(key, raw);
        if (raw.isNotEmpty) {
          socialProfilesPayload[key] = {
            'name': raw,
            'handle': cleaned,
            'link': cleaned,
          };
        }
      }
      socialProfilesPayload['_order'] = _selectedKeys;

      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'whatsapp': whatsapp,
        'instagram': instagram,
        'facebook': facebook,
        'tiktok': tiktok,
        'socials_order': _selectedKeys,
        'social_profiles': socialProfilesPayload,
      });

      if (mounted) {
        ToastService.showSuccess('Réseaux sociaux enregistrés avec succès !');
      }
    } catch (e) {
      debugPrint('[socials_screen] Erreur sauvegarde réseaux sociaux: $e');
      if (mounted) {
        ToastService.showError("Impossible d'enregistrer les réseaux sociaux.");
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    _initData();

    final unselectedPlatforms = _kAvailablePlatforms
        .where((p) => !_selectedKeys.contains(p.key))
        .toList();

    final activeEntriesWithValues = _selectedKeys
        .where((k) => _controllers[k]!.text.trim().isNotEmpty)
        .map((k) => _platformForKey(k))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: AppColors.textPrimary,
            size: 22,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/merchant/more');
            }
          },
        ),
        title: Text(
          'Réseaux sociaux & Contact',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1 : APERÇU RENDU CÔTÉ CLIENT (Pass & Vitrine)
                    _buildClientPreviewSection(activeEntriesWithValues),
                    const SizedBox(height: 20),

                    // Section 2 : RÉSEAUX SÉLECTIONNÉS (Modifiables & Réorganisables)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Réseaux configurés (${_selectedKeys.length})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_selectedKeys.isNotEmpty)
                          Text(
                            'Utilisez les flèches pour réordonner',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_selectedKeys.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.6),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B50EC).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.plus,
                                color: Color(0xFF5B50EC),
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun réseau social configuré',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choisissez un réseau dans la liste ci-dessous pour l\'ajouter en un clic.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...List.generate(_selectedKeys.length, (index) {
                        final key = _selectedKeys[index];
                        final platform = _platformForKey(key);
                        final ctrl = _controllers[key]!;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildConfiguredPlatformCard(
                            platform: platform,
                            controller: ctrl,
                            index: index,
                            total: _selectedKeys.length,
                          ),
                        );
                      }),

                    const SizedBox(height: 16),

                    // Section 3 : RÉSEAUX DISPONIBLES À AJOUTER
                    Text(
                      'Réseaux disponibles à ajouter',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Touchez un réseau pour l\'activer et renseigner son profil :',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (unselectedPlatforms.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.checkCircle2,
                                color: Color(0xFF10B981), size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tous les réseaux disponibles ont été ajoutés !',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: unselectedPlatforms.map((platform) {
                          return InkWell(
                            onTap: () => _addPlatform(platform.key),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: platform.brandColor.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: platform.brandColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      platform.icon,
                                      size: 15,
                                      color: platform.brandColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    platform.name,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    LucideIcons.plus,
                                    size: 16,
                                    color: platform.brandColor,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // Barre fixe d'enregistrement
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.6),
                    width: 0.5,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B50EC),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.check, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Enregistrer les modifications',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Aperçu dynamique en direct du rendu côté client
  Widget _buildClientPreviewSection(List<_SocialPlatformConfig> activePlatforms) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF5B50EC).withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B50EC).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B50EC).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.eye,
                  size: 15,
                  color: Color(0xFF5B50EC),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aperçu rendu côté client',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Affichage en direct sur la vitrine client avec vos pseudos et noms',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activePlatforms.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 16,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Renseignez un pseudo ou nom pour visualiser l\'affichage client.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: activePlatforms.map((platform) {
                  final text = _controllers[platform.key]?.text.trim() ?? '';
                  final displayText = text.isNotEmpty ? text : platform.name;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: platform.brandColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: platform.brandColor.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            platform.icon,
                            size: 14,
                            color: platform.brandColor,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              displayText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: platform.brandColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  /// Carte d'édition d'un réseau sélectionné avec réorganisation et suppression
  Widget _buildConfiguredPlatformCard({
    required _SocialPlatformConfig platform,
    required TextEditingController controller,
    required int index,
    required int total,
  }) {
    final isFirst = index == 0;
    final isLast = index == total - 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la carte : Icône + Nom + Réorganisation + Suppression
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: platform.brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  platform.icon,
                  size: 17,
                  color: platform.brandColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Position #${index + 1}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Boutons réorganisation (Monter / Descendre)
              IconButton(
                icon: const Icon(LucideIcons.arrowUp, size: 16),
                color: isFirst
                    ? AppColors.textSecondary.withValues(alpha: 0.25)
                    : AppColors.textPrimary,
                visualDensity: VisualDensity.compact,
                tooltip: 'Monter',
                onPressed: isFirst ? null : () => _moveUp(index),
              ),
              IconButton(
                icon: const Icon(LucideIcons.arrowDown, size: 16),
                color: isLast
                    ? AppColors.textSecondary.withValues(alpha: 0.25)
                    : AppColors.textPrimary,
                visualDensity: VisualDensity.compact,
                tooltip: 'Descendre',
                onPressed: isLast ? null : () => _moveDown(index),
              ),
              const SizedBox(width: 4),
              // Bouton supprimer
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 16),
                color: const Color(0xFFEF4444),
                visualDensity: VisualDensity.compact,
                tooltip: 'Retirer',
                onPressed: () => _removePlatform(platform.key),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Champ unique : Nom de la page ou pseudo
          Text(
            platform.key == 'whatsapp'
                ? 'Numéro WhatsApp :'
                : 'Nom de page ou pseudo :',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: platform.keyboardType,
            textCapitalization: platform.key == 'facebook'
                ? TextCapitalization.words
                : TextCapitalization.none,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixText: platform.prefixText != null
                  ? '${platform.prefixText} '
                  : null,
              prefixStyle: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: platform.brandColor,
              ),
              hintText: platform.placeholder,
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: platform.brandColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 13,
                color: platform.brandColor.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${platform.helper} • Redirection directe automatique',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
