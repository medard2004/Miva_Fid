import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../client/providers/settings_provider.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  final GlobalKey<AnimatedListState> _teamListKey = GlobalKey<AnimatedListState>();
  final List<Map<String, String>> _teamMembers = [
    {'name': 'Kofi Mensah', 'role': 'Propriétaire', 'status': 'Actif', 'initials': 'KM'},
    {'name': 'Ama Doe', 'role': 'Caissière', 'status': 'Actif', 'initials': 'AD'},
    {'name': 'Yao Lawson', 'role': 'Serveur', 'status': 'Invité', 'initials': 'YL'},
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Membres de l\'équipe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: Rd.card,
                border: Border.all(color: AppColors.border),
              ),
              child: AnimatedList(
                key: _teamListKey,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                initialItemCount: _teamMembers.length,
                itemBuilder: (context, index, animation) {
                  return _buildTeamMemberItem(_teamMembers[index], animation, index);
                },
              ),
            ),
            const SizedBox(height: Sp.md),
            _buildInviteMemberButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMemberItem(Map<String, String> member, Animation<double> animation, int index) {
    final initials = member['initials'] ?? 'KM';
    final name = member['name'] ?? '';
    final role = member['role'] ?? '';
    final status = member['status'] ?? '';
    final isActif = status == 'Actif';

    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.merchantTint,
                    child: Text(
                      initials,
                      style: AppTextStyles.bodyMd().copyWith(
                        color: AppColors.merchant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.bodyMd().copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role,
                          style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActif ? AppColors.successTint : AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActif) ...[
                          const Icon(LucideIcons.check, color: AppColors.success, size: 12),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          status,
                          style: AppTextStyles.caption().copyWith(
                            color: isActif ? AppColors.success : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  IconButton(
                    icon: const Icon(LucideIcons.trash, color: AppColors.danger, size: 18),
                    onPressed: () => _removeTeamMember(index),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            if (index < _teamMembers.length - 1)
              const Divider(height: 0, indent: 56),
          ],
        ),
      ),
    );
  }

  void _removeTeamMember(int index) {
    if (index < 0 || index >= _teamMembers.length) return;

    final removedItem = _teamMembers[index];

    setState(() {
      _teamMembers.removeAt(index);
    });

    _teamListKey.currentState?.removeItem(
      index,
      (context, animation) => _buildTeamMemberItem(removedItem, animation, index),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildInviteMemberButton() {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: AppColors.merchant.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        dashLength: 6.0,
        gap: 4.0,
      ),
      child: InkWell(
        onTap: _showInviteMemberDialog,
        borderRadius: Rd.card,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: Sp.md),
          alignment: Alignment.center,
          child: Text(
            '+ Inviter un membre',
            style: AppTextStyles.labelBold().copyWith(
              color: AppColors.merchant,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _showInviteMemberDialog() {
    final nameController = TextEditingController();
    String selectedRole = 'Serveur';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: Rd.card),
              title: Text(
                'Inviter un membre d\'équipe',
                style: AppTextStyles.h3().copyWith(color: AppColors.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInputLabel('NOM COMPLET'),
                  const SizedBox(height: Sp.xs),
                  TextField(
                    controller: nameController,
                    style: AppTextStyles.bodyMd(),
                    decoration: InputDecoration(
                      fillColor: AppColors.background,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
                      border: const OutlineInputBorder(
                        borderRadius: Rd.input,
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Ex: Yao Lawson',
                    ),
                  ),
                  const SizedBox(height: Sp.md),
                  _buildInputLabel('RÔLE'),
                  const SizedBox(height: Sp.xs),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    icon: const Icon(LucideIcons.chevronDown),
                    style: AppTextStyles.bodyMd().copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      fillColor: AppColors.background,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
                      border: const OutlineInputBorder(
                        borderRadius: Rd.input,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: ['Propriétaire', 'Caissière', 'Serveur'].map((role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRole = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(context);
                    _addTeamMember(name, selectedRole);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.merchant,
                    shape: const RoundedRectangleBorder(borderRadius: Rd.button),
                  ),
                  child: const Text('Inviter', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addTeamMember(String name, String role) {
    final parts = name.split(' ');
    String initials = '?';
    if (parts.length >= 2) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      initials = name[0].toUpperCase();
    }

    final newMember = {
      'name': name,
      'role': role,
      'status': 'Invité',
      'initials': initials,
    };

    final int newIndex = _teamMembers.length;
    setState(() {
      _teamMembers.add(newMember);
    });

    _teamListKey.currentState?.insertItem(
      newIndex,
      duration: const Duration(milliseconds: 300),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name a été invité(e) en tant que $role'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.caption().copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashLength = 6.0,
    required this.borderRadius,
  });

  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    final PathMetrics pathMetrics = path.computeMetrics();
    for (final PathMetric metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = dashLength;
        dashedPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length + gap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}
