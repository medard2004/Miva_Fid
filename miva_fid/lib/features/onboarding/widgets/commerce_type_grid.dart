import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class CommerceTypeGrid extends StatefulWidget {
  const CommerceTypeGrid({
    super.key,
    required this.onSelected,
    this.selected,
  });

  final ValueChanged<String> onSelected;
  final String? selected;

  @override
  State<CommerceTypeGrid> createState() => _CommerceTypeGridState();
}

class _CommerceTypeGridState extends State<CommerceTypeGrid> {
  static const _types = [
    ('Restaurant', Icons.restaurant_outlined),
    ('Hôtel', Icons.hotel_outlined),
    ('Salon', Icons.content_cut_outlined),
    ('Boutique', Icons.shopping_bag_outlined),
    ('Café', Icons.coffee_outlined),
    ('Autre', Icons.apps_outlined),
  ];

  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de commerce',
          style: AppTextStyles.caption().copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Sp.xs),
        GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Sp.sm,
          crossAxisSpacing: Sp.sm,
          children: _types.map((type) {
            final isSelected = _selected == type.$1;
            return GestureDetector(
              onTap: () {
                setState(() => _selected = type.$1);
                widget.onSelected(type.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryTint
                      : AppColors.surfaceLight,
                  borderRadius: Rd.button,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type.$2,
                      size: 20,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.$1,
                      style: AppTextStyles.caption().copyWith(
                        fontSize: 11,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: Sp.md),
      ],
    );
  }
}
