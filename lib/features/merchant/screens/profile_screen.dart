import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/core/api_exceptions.dart';
import '../../../core/utils/toast_service.dart';
import '../models/restaurant_account.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../../client/providers/settings_provider.dart';

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
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
    if (ok) {
      ToastService.showSuccess('Logo mis à jour avec succès');
    } else {
      ToastService.showError('Impossible de mettre à jour le logo.');
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
        ToastService.showSuccess('Modifications enregistrées !');
      }
    } catch (_) {
      if (mounted) {
        ToastService.showError('Impossible d\'enregistrer les modifications.');
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
                  decoration: const InputDecoration(
                      labelText: 'Mot de passe actuel'),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP HEADER ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      color: Color(0xFF1E293B),
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
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Profil du commerce',
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
                    child: Container(
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
                  ),
                ],
              ),
            ),

            // ── FORM CONTENT ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. LOGO CARD
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEDF0F7)),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    shape: BoxShape.circle,
                                    image: (logoUrl != null &&
                                            logoUrl.isNotEmpty)
                                        ? DecorationImage(
                                            image: NetworkImage(logoUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: (logoUrl == null || logoUrl.isEmpty)
                                      ? const Center(
                                          child: Icon(
                                            LucideIcons.camera,
                                            color: Color(0xFF64748B),
                                            size: 22,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF5B50EC),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      LucideIcons.pencil,
                                      color: Colors.white,
                                      size: 11,
                                    ),
                                  ),
                                ),
                                if (_uploadingLogo)
                                  const Positioned.fill(
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Logo du commerce',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'PNG ou JPG, carré, max 2 Mo.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap:
                                            _uploadingLogo ? null : _pickLogo,
                                        child: Text(
                                          logoUrl != null &&
                                                  logoUrl.isNotEmpty
                                              ? 'Changer'
                                              : 'Ajouter un logo',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF5B50EC),
                                          ),
                                        ),
                                      ),
                                      if (logoUrl != null &&
                                          logoUrl.isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: _uploadingLogo
                                              ? null
                                              : _removeLogo,
                                          child: const Text(
                                            'Supprimer',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFDC2626),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. INFORMATIONS
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
                            _buildSectionHeader('INFORMATIONS'),
                            const SizedBox(height: 12),
                            _buildField(
                              label: 'NOM DU COMMERCE',
                              controller: _nameController,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Le nom du commerce est obligatoire.'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              label: 'CATÉGORIE',
                              controller: _categoryController,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'La catégorie est obligatoire.'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              label: 'DESCRIPTION',
                              controller: _descriptionController,
                              maxLines: 3,
                              maxLength: 200,
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${_descriptionController.text.length}/200 caractères',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: _descriptionController
                                          .text.length >
                                      200
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: _descriptionController.text.length > 200
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. CONTACT
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
                            _buildSectionHeader('CONTACT'),
                            const SizedBox(height: 12),
                            _buildField(
                              label: 'EMAIL',
                              initialText:
                                  account?.email.isNotEmpty == true
                                      ? account!.email
                                      : null,
                              keyboardType: TextInputType.emailAddress,
                              enabled: false,
                              onTap: account != null
                                  ? () => _changeEmail(account.email)
                                  : null,
                              hint: 'Toucher pour modifier',
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              label: 'TÉLÉPHONE',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Le téléphone est obligatoire.'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              label: 'WHATSAPP',
                              controller: _whatsappController,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. ADRESSE
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
                              children: [
                                const Icon(
                                  LucideIcons.mapPin,
                                  size: 13,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                _buildSectionHeader('ADRESSE'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              label: 'VILLE',
                              controller: _cityController,
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              label: 'ADRESSE / QUARTIER',
                              controller: _addressController,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 5. ENREGISTRER BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B50EC),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
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
                      const SizedBox(height: 24),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildField({
    required String label,
    TextEditingController? controller,
    String? initialText,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF8F9FD) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEDF0F7)),
          ),
          child: TextFormField(
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
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintText: onTap != null ? hint : null,
              hintStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
              suffixIcon: onTap != null
                  ? const Icon(LucideIcons.pencil, size: 14, color: Color(0xFF94A3B8))
                  : null,
              suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 0),
            ),
          ),
        ),
      ],
    );
  }
}
