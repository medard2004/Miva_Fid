import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class ColorPalettePicker extends StatefulWidget {
  const ColorPalettePicker({
    super.key,
    required this.onColorSelected,
    this.selected,
  });

  final ValueChanged<Color> onColorSelected;
  final Color? selected;

  @override
  State<ColorPalettePicker> createState() => _ColorPalettePickerState();
}

class _ColorPalettePickerState extends State<ColorPalettePicker> {
  static const _presets = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF7C3AED), // Violet
    Color(0xFFDB2777), // Rose
    Color(0xFFDC2626), // Rouge
    Color(0xFFEA580C), // Orange
    Color(0xFFD97706), // Ambre
    Color(0xFF16A34A), // Vert
    Color(0xFF0891B2), // Cyan
    Color(0xFF0284C7), // Bleu
    Color(0xFF475569), // Ardoise
    Color(0xFF1C1917), // Noir
    Color(0xFF78716C), // Pierre
  ];

  Color? _selected;

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
          'Couleur principale',
          style: AppTextStyles.caption().copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Sp.sm),
        Wrap(
          spacing: Sp.sm,
          runSpacing: Sp.sm,
          children: _presets.map((color) {
            final isSelected = _selected?.value == color.value;
            return GestureDetector(
              onTap: () {
                setState(() => _selected = color);
                widget.onColorSelected(color);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 2.5)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: Sp.xs),
        TextButton.icon(
          onPressed: () => _showCustomPicker(context),
          icon: const Icon(Icons.color_lens_outlined, size: 16),
          label: Text(
            'Choisir une autre couleur',
            style: AppTextStyles.caption().copyWith(color: AppColors.primary),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: Sp.md),
      ],
    );
  }

  void _showCustomPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomColorSheet(
        initial: _selected ?? _presets.first,
        onPicked: (c) {
          setState(() => _selected = c);
          widget.onColorSelected(c);
        },
      ),
    );
  }
}

class _CustomColorSheet extends StatefulWidget {
  const _CustomColorSheet({required this.initial, required this.onPicked});
  final Color initial;
  final ValueChanged<Color> onPicked;

  @override
  State<_CustomColorSheet> createState() => _CustomColorSheetState();
}

class _CustomColorSheetState extends State<_CustomColorSheet> {
  late double _hue;
  late double _saturation;
  late double _lightness;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.initial);
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _lightness = hsl.lightness;
  }

  Color get _current =>
      HSLColor.fromAHSL(1, _hue, _saturation, _lightness).toColor();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: Sp.md),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Text('Couleur personnalisée', style: AppTextStyles.h3()),
          const SizedBox(height: Sp.md),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: _current,
              borderRadius: Rd.card,
            ),
          ),
          const SizedBox(height: Sp.md),
          Text('Teinte', style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
          Slider(
            value: _hue,
            min: 0,
            max: 360,
            onChanged: (v) => setState(() => _hue = v),
            activeColor: _current,
          ),
          Text('Saturation', style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
          Slider(
            value: _saturation,
            min: 0,
            max: 1,
            onChanged: (v) => setState(() => _saturation = v),
            activeColor: _current,
          ),
          Text('Luminosité', style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
          Slider(
            value: _lightness,
            min: 0.1,
            max: 0.9,
            onChanged: (v) => setState(() => _lightness = v),
            activeColor: _current,
          ),
          const SizedBox(height: Sp.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onPicked(_current);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: Rd.button),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Confirmer', style: AppTextStyles.labelBold().copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(height: Sp.md),
        ],
      ),
    );
  }
}
