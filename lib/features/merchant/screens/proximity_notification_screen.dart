import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/toast_service.dart';
import '../../client/providers/settings_provider.dart';
import '../models/proximity_settings_model.dart';
import '../providers/proximity_settings_provider.dart';

class ProximityNotificationScreen extends ConsumerStatefulWidget {
  const ProximityNotificationScreen({super.key});

  @override
  ConsumerState<ProximityNotificationScreen> createState() =>
      _ProximityNotificationScreenState();
}

class _ProximityNotificationScreenState
    extends ConsumerState<ProximityNotificationScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _messageCtrl;
  final MapController _mapController = MapController();

  bool _enabled = false;
  int _radiusMeters = 500;
  bool _isSaving = false;
  bool _initialized = false;

  final List<int> _presetRadii = const [100, 250, 500, 1000, 2000];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _messageCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _syncFromModel(ProximitySettingsModel model) {
    if (_initialized) return;
    _enabled = model.enabled;
    _radiusMeters = model.radiusMeters;
    _titleCtrl.text = model.title;
    _messageCtrl.text = model.message;
    _initialized = true;
  }

  void _applyTemplate(String title, String message) {
    setState(() {
      _titleCtrl.text = title;
      _messageCtrl.text = message;
    });
    AppHaptics.selection();
  }

  Future<void> _save() async {
    if (_enabled) {
      if (_titleCtrl.text.trim().isEmpty) {
        ToastService.showError('Veuillez renseigner le titre du message.');
        return;
      }
      if (_messageCtrl.text.trim().isEmpty) {
        ToastService.showError('Veuillez renseigner le contenu du message.');
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(proximitySettingsProvider.notifier).save(
            enabled: _enabled,
            radiusMeters: _radiusMeters,
            title: _titleCtrl.text.trim(),
            message: _messageCtrl.text.trim(),
          );
      AppHaptics.heavy();
      if (mounted) {
        ToastService.showSuccess(
          _enabled
              ? 'Notifications de proximité activées et enregistrées !'
              : 'Notifications de proximité désactivées.',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError('Impossible d\'enregistrer les modifications.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final asyncSettings = ref.watch(proximitySettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft,
              color: AppColors.textPrimary, size: 24),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications de proximité',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: asyncSettings.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF5B50EC)),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.alertCircle,
                    color: AppColors.textSecondary, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Impossible de charger les paramètres.',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(proximitySettingsProvider.notifier).load(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (model) {
          _syncFromModel(model);

          final hasCoordinates = model.latitude != null && model.longitude != null;
          final restaurantCoords = hasCoordinates
              ? LatLng(model.latitude!, model.longitude!)
              : const LatLng(6.1319, 1.2228);

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. BANNIÈRE STATUT & TOGGLE PRINCIPAL ────────────
                        _buildStatusHeader(model),
                        const SizedBox(height: 16),

                        // Avertissements éventuels (plan ou géolocalisation)
                        if (!model.planAllowsGeolocation) ...[
                          _buildWarningCard(
                            icon: LucideIcons.crown,
                            title: 'Formule Pro requise',
                            message:
                                'Votre abonnement actuel n\'inclut pas les notifications géolocalisées. Passez à la formule Pro pour activer la fonction.',
                            actionLabel: 'Voir les formules',
                            onAction: () =>
                                context.push('/merchant/more/subscription'),
                          ),
                          const SizedBox(height: 16),
                        ] else if (!model.hasLocation) ...[
                          _buildWarningCard(
                            icon: LucideIcons.mapPinOff,
                            title: 'Position du commerce manquante',
                            message:
                                'Veuillez positionner votre établissement sur la carte pour permettre le calcul de proximité.',
                            actionLabel: 'Définir la position',
                            onAction: () =>
                                context.push('/merchant/more/profile'),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── 2. CARTE & RAYON DE DÉCLENCHEMENT ─────────────────
                        _buildSectionTitle('Zone de déclenchement autour du commerce'),
                        const SizedBox(height: 8),
                        _buildRadiusSelector(restaurantCoords, hasCoordinates),
                        const SizedBox(height: 20),

                        // ── 3. CONFIGURATION DU MESSAGE ──────────────────────
                        _buildSectionTitle('Message envoyé au client'),
                        const SizedBox(height: 8),
                        _buildMessageInputs(),
                        const SizedBox(height: 12),
                        _buildTemplateSuggestions(),
                        const SizedBox(height: 20),

                        // ── 4. APERÇU DE LA NOTIFICATION PUSH ─────────────────
                        _buildSectionTitle('Aperçu de la notification'),
                        const SizedBox(height: 8),
                        _buildNotificationPreview(),
                        const SizedBox(height: 20),

                        // ── 5. RÈGLES ANTI-SPAM ET CONFIDENTIALITÉ ───────────
                        _buildAntiSpamCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── 6. BOUTON D'ENREGISTREMENT FIXE ──────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5B50EC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Enregistrer les modifications',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildStatusHeader(ProximitySettingsModel model) {
    final isActuallyActive = _enabled && model.hasLocation && model.planAllowsGeolocation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActuallyActive
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActuallyActive
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActuallyActive ? LucideIcons.radar : LucideIcons.bellOff,
              color: isActuallyActive
                  ? const Color(0xFF10B981)
                  : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Notifications de proximité',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActuallyActive
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFF6B7280).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActuallyActive ? 'ACTIVÉE' : 'DÉSACTIVÉE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isActuallyActive
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActuallyActive
                          ? 'Envoi auto lors du passage'
                          : 'Aucun envoi',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _enabled,
            activeTrackColor: const Color(0xFF5B50EC),
            onChanged: (val) {
              setState(() => _enabled = val);
              AppHaptics.selection();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFD97706), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF78350F),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onAction,
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD97706),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSelector(LatLng center, bool hasCoordinates) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visualisation interactive cartographique du rayon
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 180,
              child: hasCoordinates
                  ? FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: _zoomForRadius(_radiusMeters),
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.pinchZoom |
                              InteractiveFlag.drag,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.mivafid.app',
                        ),
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: center,
                              radius: _radiusMeters.toDouble(),
                              useRadiusInMeter: true,
                              color: const Color(0xFF5B50EC).withValues(alpha: 0.18),
                              borderColor: const Color(0xFF5B50EC),
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: center,
                              width: 38,
                              height: 38,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF5B50EC),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  LucideIcons.store,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Container(
                      color: AppColors.background,
                      child: Center(
                        child: Text(
                          'Définissez d\'abord l\'adresse de votre établissement.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rayon de déclenchement',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B50EC).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatRadius(_radiusMeters),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5B50EC),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF5B50EC),
                    inactiveTrackColor: AppColors.border,
                    thumbColor: const Color(0xFF5B50EC),
                    overlayColor: const Color(0xFF5B50EC).withValues(alpha: 0.12),
                  ),
                  child: Slider(
                    value: _radiusMeters.toDouble(),
                    min: 50,
                    max: 2000,
                    divisions: 39,
                    onChanged: (val) {
                      setState(() {
                        _radiusMeters = val.round();
                      });
                    },
                  ),
                ),

                // Boutons de présélection rapide
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _presetRadii.map((r) {
                      final selected = _radiusMeters == r;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_formatRadius(r)),
                          selected: selected,
                          selectedColor: const Color(0xFF5B50EC).withValues(alpha: 0.15),
                          backgroundColor: AppColors.background,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? const Color(0xFF5B50EC)
                                : AppColors.textSecondary,
                          ),
                          onSelected: (_) {
                            setState(() => _radiusMeters = r);
                            AppHaptics.selection();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Titre de la notification',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${_titleCtrl.text.length}/100',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            maxLength: 100,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Ex: Vous êtes tout près de nous !',
              hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                borderSide: const BorderSide(color: Color(0xFF5B50EC)),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Contenu du message
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contenu du message',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${_messageCtrl.text.length}/255',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _messageCtrl,
            maxLength: 255,
            maxLines: 3,
            decoration: InputDecoration(
              counterText: '',
              hintText:
                  'Ex: Passez faire un tour et profitez de vos avantages fidélité.',
              hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                borderSide: const BorderSide(color: Color(0xFF5B50EC)),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSuggestions() {
    final templates = [
      {
        'label': 'Bienvenue',
        'title': 'Vous êtes tout près de nous !',
        'body': 'Passez nous rendre visite et profitez de vos avantages fidélité.',
      },
      {
        'label': 'Offre spéciale',
        'title': 'Offre exclusive à deux pas ! 🎁',
        'body': 'Vous êtes à proximité : venez cumuler des points aujourd\'hui !',
      },
      {
        'label': 'Pause gourmande',
        'title': 'C\'est l\'heure de votre pause ! ☕',
        'body': 'Faites une halte chez nous et débloquez votre prochaine récompense.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modèles suggérés :',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: templates.map((tmpl) {
            return ActionChip(
              backgroundColor: AppColors.surface,
              side: BorderSide(color: AppColors.border),
              label: Text(
                tmpl['label']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              onPressed: () => _applyTemplate(tmpl['title']!, tmpl['body']!),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotificationPreview() {
    final title = _titleCtrl.text.trim().isNotEmpty
        ? _titleCtrl.text.trim()
        : 'Vous êtes tout près de nous !';
    final body = _messageCtrl.text.trim().isNotEmpty
        ? _messageCtrl.text.trim()
        : 'Passez nous voir et profitez de vos avantages fidélité.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B50EC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'MIVA-FID',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '• À l\'instant',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(LucideIcons.creditCard, size: 13, color: Color(0xFF5B50EC)),
              SizedBox(width: 5),
              Text(
                'Cible : détenteurs de votre carte de fidélité',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5B50EC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAntiSpamCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.shieldCheck,
              color: Color(0xFF16A34A), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Politique anti-spam stricte (24h)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF166534),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Un client ne recevra jamais plus d\'une notification toutes les 24h pour votre établissement. S\'il reste dans votre zone, aucune notification répétée n\'est envoyée.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF15803D),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRadius(int meters) {
    if (meters >= 1000) {
      final km = meters / 1000.0;
      return km == km.roundToDouble()
          ? '${km.toInt()} km'
          : '${km.toStringAsFixed(1)} km';
    }
    return '$meters m';
  }

  double _zoomForRadius(int meters) {
    if (meters <= 150) return 17.5;
    if (meters <= 300) return 16.5;
    if (meters <= 600) return 15.5;
    if (meters <= 1200) return 14.5;
    return 13.5;
  }
}
