import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/core/api_exceptions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';
import '../models/restaurant_account.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;

  bool _isSaving = false;
  bool _uploadingLogo = false;
  bool _initialized = false;

  static const _maxLogoBytes = 2 * 1024 * 1024;
  static const _allowedLogoExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _categoryController = TextEditingController();
    _descriptionController = TextEditingController();
    _phoneController = TextEditingController();
    _whatsappController = TextEditingController();
    _cityController = TextEditingController();
    _addressController = TextEditingController();
    _descriptionController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (!mounted || file == null) return;

    final extension = file.name.split('.').last.toLowerCase();
    if (!_allowedLogoExtensions.contains(extension)) {
      ToastService.showError('Format non supporté. Utilisez PNG ou JPG.');
      return;
    }
    if (File(file.path).lengthSync() > _maxLogoBytes) {
      ToastService.showError('Image trop lourde. Maximum 2 Mo.');
      return;
    }

    setState(() => _uploadingLogo = true);
    final ok = await ref
        .read(merchantAuthProvider.notifier)
        .uploadLogo(File(file.path));
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;
    if (ok) {
      ToastService.showSuccess(t.merchantProfileLogoSuccess);
    } else {
      ToastService.showError(t.merchantProfileLogoError);
    }
    setState(() => _uploadingLogo = false);
  }

  Future<void> _removeLogo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le logo ?'),
        content:
            const Text('Votre commerce réapparaîtra avec ses initiales.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer',
                style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _uploadingLogo = true);
    final ok = await ref.read(merchantAuthProvider.notifier).deleteLogo();
    if (!mounted) return;
    if (ok) {
      ToastService.showSuccess('Logo supprimé');
    } else {
      ToastService.showError('Impossible de supprimer le logo.');
    }
    setState(() => _uploadingLogo = false);
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
      });
      if (mounted) {
        ToastService.showSuccess(
            AppLocalizations.of(context)!.merchantProfileSaveSuccess);
      }
    } catch (_) {
      if (mounted) {
        ToastService.showError(
            AppLocalizations.of(context)!.errProfileSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeEmail(String currentEmail) async {
    final emailCtrl = TextEditingController(text: currentEmail);
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var submitting = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Changer l'adresse e-mail"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Nouvel e-mail'),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'E-mail requis.';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                      return 'Adresse e-mail invalide.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Mot de passe actuel'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Mot de passe requis.' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => submitting = true);
                      try {
                        await ref
                            .read(merchantAuthProvider.notifier)
                            .updateEmail(
                              emailCtrl.text.trim(),
                              passwordCtrl.text,
                            );
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop({'ok': true});
                        }
                      } on ValidationException catch (e) {
                        setDialogState(() => submitting = false);
                        if (ctx.mounted) {
                          ToastService.showError(e.message);
                        }
                      } catch (_) {
                        setDialogState(() => submitting = false);
                        if (ctx.mounted) {
                          ToastService.showError(
                              "Impossible de changer l'adresse e-mail.");
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (result?['ok'] == true && mounted) {
      ToastService.showSuccess('Adresse e-mail mise à jour.');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final merchantState = ref.watch(merchantAuthProvider);
    final RestaurantAccount? account = merchantState.restaurant;

    if (account != null && !_initialized) {
      _nameController.text = account.name ?? '';
      _categoryController.text = account.category ?? '';
      _descriptionController.text = account.description ?? '';
      _phoneController.text = account.phone ?? '';
      _whatsappController.text = account.whatsapp ?? '';
      _cityController.text = account.city ?? '';
      _addressController.text = account.address ?? '';
      _initialized = true;
    }

    final logoUrl = account?.logoUrl;
    final initials = (account?.name?.isNotEmpty == true)
        ? account!.name!.substring(0, 1).toUpperCase()
        : 'M';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft,
              color: AppColors.textPrimary, size: 22),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/merchant/more');
            }
          },
        ),
        title: Text(
          t.merchantMoreBusinessProfile,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.bell,
                size: 20, color: AppColors.textPrimary),
            onPressed: () => context.push('/merchant/more/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. HERO AVATAR & HEADER CARD ──────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _uploadingLogo ? null : _pickLogo,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5B50EC)
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF5B50EC)
                                            .withValues(alpha: 0.25),
                                        width: 2,
                                      ),
                                      image: (logoUrl != null &&
                                              logoUrl.isNotEmpty)
                                          ? DecorationImage(
                                              image: CachedNetworkImageProvider(
                                                  logoUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: (logoUrl == null ||
                                            logoUrl.isEmpty)
                                        ? Center(
                                            child: Text(
                                              initials,
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF5B50EC),
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5B50EC),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        LucideIcons.camera,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                    ),
                                  ),
                                  if (_uploadingLogo)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.4),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              account?.name ?? 'Mon Commerce',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (account?.category?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5B50EC)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  account!.category!,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF5B50EC),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _uploadingLogo ? null : _pickLogo,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 34),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    side: BorderSide(
                                        color: AppColors.border),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(LucideIcons.image, size: 14),
                                  label: Text(
                                    logoUrl != null && logoUrl.isNotEmpty
                                        ? 'Changer le logo'
                                        : 'Ajouter un logo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (logoUrl != null && logoUrl.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed:
                                        _uploadingLogo ? null : _removeLogo,
                                    tooltip: 'Supprimer le logo',
                                    icon: const Icon(LucideIcons.trash2,
                                        size: 16, color: Color(0xFFEF4444)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── 2. SECTION INFORMATIONS ───────────────────────────
                      _buildSectionHeader(
                        title: 'Établissement',
                        icon: LucideIcons.store,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildModernField(
                              label: t.merchantProfileBusinessNameLabel,
                              controller: _nameController,
                              icon: LucideIcons.building2,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Le nom du commerce est obligatoire.'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _buildModernField(
                              label: t.merchantProfileCategoryLabel,
                              controller: _categoryController,
                              icon: LucideIcons.tag,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'La catégorie est obligatoire.'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _buildModernField(
                              label: t.merchantProfileDescriptionLabel,
                              controller: _descriptionController,
                              icon: LucideIcons.alignLeft,
                              maxLines: 3,
                              maxLength: 200,
                              helperText:
                                  '${_descriptionController.text.length}/200 caractères',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── 3. SECTION CONTACT ────────────────────────────────
                      _buildSectionHeader(
                        title: 'Coordonnées & Contact',
                        icon: LucideIcons.phoneCall,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildModernField(
                              label: t.merchantProfileEmailLabel,
                              initialText: account?.email.isNotEmpty == true
                                  ? account!.email
                                  : '',
                              icon: LucideIcons.mail,
                              enabled: false,
                              onTap: account != null
                                  ? () => _changeEmail(account.email)
                                  : null,
                              trailing: const Icon(LucideIcons.pencil,
                                  size: 14, color: Color(0xFF5B50EC)),
                            ),
                            const SizedBox(height: 14),
                            _buildModernField(
                              label: t.merchantProfilePhoneLabel,
                              controller: _phoneController,
                              icon: LucideIcons.phone,
                              keyboardType: TextInputType.phone,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Le téléphone est obligatoire.'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _buildModernField(
                              label: t.merchantProfileWhatsappLabel,
                              controller: _whatsappController,
                              icon: LucideIcons.messageCircle,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── 4. SECTION EMPLACEMENT ────────────────────────────
                      _buildSectionHeader(
                        title: 'Emplacement',
                        icon: LucideIcons.mapPin,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildModernField(
                              label: t.merchantProfileCityLabel,
                              controller: _cityController,
                              icon: LucideIcons.mapPin,
                            ),
                            const SizedBox(height: 14),
                            _buildModernField(
                              label: t.merchantProfileAddressLabel,
                              controller: _addressController,
                              icon: LucideIcons.navigation,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 5. BOTTOM SAVE ACTION BAR ─────────────────────────────────
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
                height: 46,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B50EC),
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.check,
                                size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              t.merchantProfileSaveButton,
                              style: const TextStyle(
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

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF5B50EC)),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildModernField({
    required String label,
    TextEditingController? controller,
    String? initialText,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    String? helperText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            if (helperText != null)
              Text(
                helperText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          initialValue: initialText,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          onTap: onTap,
          buildCounter: (_,
                  {required currentLength,
                  required isFocused,
                  maxLength}) =>
              null,
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
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            prefixIcon: Icon(icon, size: 16, color: AppColors.textSecondary),
            suffixIcon: trailing,
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
              borderSide:
                  const BorderSide(color: Color(0xFF5B50EC), width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
            ),
          ),
        ),
      ],
    );
  }
}
