import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/toast_service.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../../client/providers/settings_provider.dart';

class _DayConfig {
  bool open;
  TimeOfDay from;
  TimeOfDay to;

  _DayConfig({
    required this.open,
    required this.from,
    required this.to,
  });
}

class OpeningHoursScreen extends ConsumerStatefulWidget {
  const OpeningHoursScreen({super.key});

  @override
  ConsumerState<OpeningHoursScreen> createState() => _OpeningHoursScreenState();
}

class _OpeningHoursScreenState extends ConsumerState<OpeningHoursScreen> {
  static const _days = [
    ('mon', 'Lundi'),
    ('tue', 'Mardi'),
    ('wed', 'Mercredi'),
    ('thu', 'Jeudi'),
    ('fri', 'Vendredi'),
    ('sat', 'Samedi'),
    ('sun', 'Dimanche'),
  ];

  late final Map<String, _DayConfig> _hours;
  bool _initialized = false;
  bool _isSaving = false;

  TimeOfDay _parseTime(String? value, TimeOfDay fallback) {
    final parts = (value ?? '').split(':');
    final h = int.tryParse(parts.first);
    final m = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (h == null || h < 0 || h > 23) return fallback;
    return TimeOfDay(hour: h, minute: (m != null && m >= 0 && m <= 59) ? m : 0);
  }

  String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);

    if (!_initialized) {
      final account = ref.watch(merchantAuthProvider).restaurant;
      final saved = account?.openingHours ?? const {};
      final defaultFrom = const TimeOfDay(hour: 8, minute: 0);
      final defaultTo = const TimeOfDay(hour: 22, minute: 0);
      _hours = {
        for (final (key, _) in _days)
          key: (() {
            final day = saved[key];
            if (day is Map && day['open'] == true) {
              return _DayConfig(
                open: true,
                from: _parseTime(day['from']?.toString(), defaultFrom),
                to: _parseTime(day['to']?.toString(), defaultTo),
              );
            }
            return _DayConfig(
                open: false, from: defaultFrom, to: defaultTo);
          })(),
      };
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
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
                      "Horaires d'ouverture",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEDF0F7)),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _days.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildDayRow(_days[i].$1, _days[i].$2),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
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
                          'Enregistrer les horaires',
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
      ),
    );
  }

  Widget _buildDayRow(String key, String label) {
    final day = _hours[key]!;
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        Switch(
          value: day.open,
          activeColor: const Color(0xFF5B50EC),
          onChanged: (v) => setState(() => day.open = v),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: day.open
              ? Row(
                  children: [
                    Expanded(
                      child: _buildTimeButton(label: 'Ouverture', time: day.from,
                        onPicked: (t) => setState(() => day.from = t)),
                    ),
                    const SizedBox(width: 6),
                    const Text('–',
                        style: TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildTimeButton(label: 'Fermeture', time: day.to,
                        onPicked: (t) => setState(() => day.to = t)),
                    ),
                  ],
                )
              : const Text(
                  'Fermé',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                ),
        ),
      ],
    );
  }

  Widget _buildTimeButton({
    required String label,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _format(time),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'opening_hours': {
          for (final (key, _) in _days)
            key: {
              'open': _hours[key]!.open,
              if (_hours[key]!.open) ...{
                'from': _format(_hours[key]!.from),
                'to': _format(_hours[key]!.to),
              },
            },
        },
      });
      if (mounted) ToastService.showSuccess('Horaires enregistrés !');
    } catch (_) {
      if (mounted) {
        ToastService.showError("Impossible d'enregistrer les horaires.");
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
