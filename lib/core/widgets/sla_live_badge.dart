// lib/core/widgets/sla_live_badge.dart
//
// Widget live SLA:
// - Menghitung durasi / sisa SLA / keterlambatan secara dinamis dari timestamp transisi.
// - Memperbarui tampilan secara otomatis setiap 30 detik saat halaman tetap terbuka tanpa reload.
// - Menampilkan penanda terlambat jika melewati batas 120 menit kerja tanpa mengubah status mutasi.

import 'dart:async';
import 'package:flutter/material.dart';

import '../utils/sla_wita_helper.dart';

/// Builder widget yang me-rebuild dirinya secara berkala (setiap 30 detik)
/// untuk memperbarui perhitungan SLA saat halaman tetap terbuka.
class SlaLiveBuilder extends StatefulWidget {
  final dynamic mutation;
  final DateTime? now;
  final Widget Function(BuildContext context, SlaStageResult sla) builder;

  const SlaLiveBuilder({
    super.key,
    required this.mutation,
    this.now,
    required this.builder,
  });

  @override
  State<SlaLiveBuilder> createState() => _SlaLiveBuilderState();
}

class _SlaLiveBuilderState extends State<SlaLiveBuilder> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh otomatis setiap 30 detik saat halaman terbuka
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sla = SlaWitaHelper.evaluateMutationSla(
      widget.mutation,
      now: widget.now,
    );
    return widget.builder(context, sla);
  }
}

/// Pill badge responsif yang menampilkan status SLA real-time:
/// "Sisa SLA: X", "SLA Terlambat: X", atau "Durasi: X".
class SlaLiveBadge extends StatelessWidget {
  final dynamic mutation;
  final DateTime? now;
  final bool showWhenInactive;

  const SlaLiveBadge({
    super.key,
    required this.mutation,
    this.now,
    this.showWhenInactive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SlaLiveBuilder(
      mutation: mutation,
      now: now,
      builder: (context, sla) {
        // Jika SLA tidak aktif untuk tahap ini (misal Operator saat 'submitted')
        // dan tidak diminta menampilkan pesan inaktif, jangan render apa-apa
        if (!sla.slaActive && !sla.isFinished && !showWhenInactive) {
          return const SizedBox.shrink();
        }

        final isOverdue = sla.isOverdue;
        final bgColor = isOverdue
            ? const Color(0xFFFEE2E2) // Red 100
            : (sla.isFinished
                ? const Color(0xFFF1F5F9) // Slate 100
                : const Color(0xFFE0F2FE)); // Light Sky 100
        final textColor = isOverdue
            ? const Color(0xFFDC2626) // Red 600
            : (sla.isFinished
                ? const Color(0xFF475569) // Slate 600
                : const Color(0xFF0369A1)); // Sky 700
        final iconColor = textColor;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isOverdue
                  ? const Color(0xFFFCA5A5)
                  : (sla.isFinished
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFFBAE6FD)),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOverdue
                    ? Icons.warning_amber_rounded
                    : (sla.isFinished
                        ? Icons.timer_outlined
                        : Icons.schedule_rounded),
                size: 13,
                color: iconColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  sla.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
