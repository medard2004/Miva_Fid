import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../providers/merchant_provider.dart';
import '../providers/validate_provider.dart';
import '../widgets/client_card_sheet.dart';
import '../widgets/scan_frame_widget.dart';
import '../widgets/validation_success_overlay.dart';

class ValidateScreen extends ConsumerStatefulWidget {
  const ValidateScreen({super.key});

  @override
  ConsumerState<ValidateScreen> createState() => _ValidateScreenState();
}

class _ValidateScreenState extends ConsumerState<ValidateScreen> {
  final MobileScannerController _scanCtrl = MobileScannerController();
  bool _processing = false;
  final List<TextEditingController> _otpCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _scanCtrl.dispose();
    for (final c in _otpCtrl) c.dispose();
    for (final f in _otpFocus) f.dispose();
    super.dispose();
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    setState(() => _processing = true);
    try {
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final clientId = payload['clientId'] as String? ?? payload['merchantId'] as String?;
      if (clientId == null) return;
      final card = await ref.read(validateNotifierProvider.notifier).lookupClient(clientId);
      if (!mounted) return;
      if (card == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client introuvable')));
        return;
      }
      final merchant = await ref.read(merchantNotifierProvider.future);
      await AppHaptics.medium();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ClientCardSheet(
          card: card,
          stampsRequired: merchant?.stampsRequired ?? 10,
          onValidate: () => _validateStamp(card.id, card.stampsCount),
        ),
      );
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _validateStamp(String cardId, int currentStamps) async {
    final newCount = await ref.read(validateNotifierProvider.notifier).addStamp(cardId);
    await AppHaptics.medium();
    if (!mounted) return;
    final merchant = await ref.read(merchantNotifierProvider.future);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ValidationSuccessOverlay(
        clientName: 'Client',
        stampCount: newCount,
        stampsRequired: merchant?.stampsRequired ?? 10,
        onDone: () => Navigator.pop(context),
        onAnother: () => Navigator.pop(context),
      ),
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
    });
  }

  Future<void> _lookupByCode() async {
    final code = _otpCtrl.map((c) => c.text).join();
    if (code.length < 6) return;
    final card = await ref.read(validateNotifierProvider.notifier).lookupByCode(code);
    if (!mounted) return;
    if (card == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code introuvable')));
      return;
    }
    final merchant = await ref.read(merchantNotifierProvider.future);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClientCardSheet(
        card: card,
        stampsRequired: merchant?.stampsRequired ?? 10,
        onValidate: () => _validateStamp(card.id, card.stampsCount),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          title: Text('Valider un achat', style: AppTextStyles.h3()),
          bottom: TabBar(
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: Rd.pill,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Scanner QR'),
              Tab(text: 'Code manuel'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_ScannerTab(controller: _scanCtrl, onDetect: _onQrDetected),
                     _ManualTab(ctrls: _otpCtrl, focuses: _otpFocus, onSubmit: _lookupByCode)],
        ),
      ),
    );
  }
}

class _ScannerTab extends StatelessWidget {
  const _ScannerTab({required this.controller, required this.onDetect});
  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Sp.md),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: Rd.card,
                  child: MobileScanner(controller: controller, onDetect: onDetect),
                ),
                const ScanFrameWidget(),
              ],
            ),
          ),
          const SizedBox(height: Sp.md),
          Text('Pointez vers le QR code du client',
              style: AppTextStyles.bodyMd(), textAlign: TextAlign.center),
          const SizedBox(height: Sp.sm),
          IconButton.filled(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.black.withOpacity(0.12))),
            icon: const Icon(Icons.flashlight_on, color: Colors.white),
            onPressed: controller.toggleTorch,
          ),
          const SizedBox(height: Sp.md),
        ],
      ),
    );
  }
}

class _ManualTab extends StatelessWidget {
  const _ManualTab({required this.ctrls, required this.focuses, required this.onSubmit});
  final List<TextEditingController> ctrls;
  final List<FocusNode> focuses;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(
        children: [
          const SizedBox(height: Sp.xl),
          Text('Code à 6 chiffres du client',
              style: AppTextStyles.labelBold()),
          const SizedBox(height: Sp.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: 48,
                height: 56,
                child: TextFormField(
                  controller: ctrls[i],
                  focusNode: focuses[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: AppTextStyles.monoLg(),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: Rd.input),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) focuses[i + 1].requestFocus();
                  },
                ),
              ),
            )),
          ),
          const SizedBox(height: Sp.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(borderRadius: Rd.button),
              ),
              child: Text('Rechercher le client', style: AppTextStyles.labelBold().copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
