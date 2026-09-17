import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';

class _Message {
  final String text;
  final String time;
  final bool isMerchant;

  const _Message({
    required this.text,
    required this.time,
    required this.isMerchant,
  });
}

class SmsConversationScreen extends ConsumerStatefulWidget {
  const SmsConversationScreen({
    super.key,
    this.clientName = 'Afi Mensah',
    this.clientPhone = '+228 90 12 34 56',
    this.clientInitials = 'AM',
  });

  final String clientName;
  final String clientPhone;
  final String clientInitials;

  @override
  ConsumerState<SmsConversationScreen> createState() =>
      _SmsConversationScreenState();
}

class _SmsConversationScreenState extends ConsumerState<SmsConversationScreen> {
  final _textController = TextEditingController();
  final List<_Message> _messages = [
    const _Message(
      text:
          'Bonjour ! Merci pour votre visite, il vous reste 3 tampons avant votre récompense 🎁',
      time: '09:12',
      isMerchant: true,
    ),
    const _Message(
      text: 'Super, merci ! Je repasse ce week-end.',
      time: '09:20',
      isMerchant: false,
    ),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(
        text: text,
        time: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        isMerchant: true,
      ));
      _textController.clear();
    });
    ToastService.showSuccess(AppLocalizations.of(context)!.merchantSmsConversationSentToast);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP HEADER (WHATSAPP-STYLE WITH AVATAR) ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.clientInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.clientName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          widget.clientPhone,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),

            // ── MESSAGES LIST ────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  if (msg.isMerchant) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF5B50EC),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              msg.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg.time,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.text,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg.time,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),

            // ── BOTTOM INPUT BAR ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: t.merchantSmsConversationInputHint,
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _sendMessage,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5B50EC),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.send,
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
