<?php

namespace App\Support;

use Carbon\Carbon;
use Carbon\CarbonInterface;

class SlaCalculator
{
    public const TIMEZONE = 'Asia/Makassar';
    public const WORK_START_HOUR = 8;
    public const WORK_END_HOUR = 17;
    public const STAGE_TARGET_MINUTES = 120; // Maksimal 2 jam kerja operasional

    /**
     * Menghitung total menit kerja bisnis (Senin-Jumat, 08:00-17:00 WITA)
     * yang telah berjalan antara $startDate dan $endDate.
     * Tidak menghitung akhir pekan atau waktu di luar jam kerja.
     */
    public static function calculateBusinessMinutes(CarbonInterface $startDate, ?CarbonInterface $endDate = null): int
    {
        $start = Carbon::parse($startDate)->setTimezone(self::TIMEZONE);
        $end = ($endDate ? Carbon::parse($endDate) : Carbon::now())->setTimezone(self::TIMEZONE);

        if ($start->greaterThanOrEqualTo($end)) {
            return 0;
        }

        $totalMinutes = 0;
        $current = $start->copy();

        while ($current->lessThan($end)) {
            // Lewati hari Sabtu (6) dan Minggu (7)
            if ($current->isWeekend()) {
                $current->addDay()->startOfDay()->setHour(self::WORK_START_HOUR);
                continue;
            }

            // Jika sebelum jam 08:00 pada hari kerja, majukan ke 08:00
            if ($current->hour < self::WORK_START_HOUR) {
                $current->setHour(self::WORK_START_HOUR)->setMinute(0)->setSecond(0);
                if ($current->greaterThanOrEqualTo($end)) {
                    break;
                }
            }

            // Jika sudah di atas jam 17:00, lompat ke 08:00 hari kerja berikutnya
            if ($current->hour >= self::WORK_END_HOUR) {
                $current->addDay()->startOfDay()->setHour(self::WORK_START_HOUR);
                continue;
            }

            // Hitung menit hingga akhir jam kerja hari ini (17:00) atau hingga $end
            $endOfWorkDay = $current->copy()->setHour(self::WORK_END_HOUR)->setMinute(0)->setSecond(0);
            $segmentEnd = $end->lessThan($endOfWorkDay) ? $end : $endOfWorkDay;

            $diff = $current->diffInMinutes($segmentEnd, false);
            if ($diff > 0) {
                $totalMinutes += $diff;
            }

            $current = $endOfWorkDay->addDay()->setHour(self::WORK_START_HOUR);
        }

        return $totalMinutes;
    }

    /**
     * Memformat durasi menit kerja bisnis menjadi teks yang mudah dipahami.
     * Contoh: "2 Jam 15 Menit (WITA)"
     */
    public static function formatBusinessDuration(int $minutes): string
    {
        if ($minutes <= 0) {
            return '0 Menit';
        }

        $hours = intdiv($minutes, 60);
        $remainingMinutes = $minutes % 60;

        if ($hours > 0 && $remainingMinutes > 0) {
            return "{$hours} Jam {$remainingMinutes} Menit";
        }

        if ($hours > 0) {
            return "{$hours} Jam";
        }

        return "{$remainingMinutes} Menit";
    }

    /**
     * Cek apakah saat ini berada dalam jendela jam kerja operasional WITA.
     */
    public static function isWithinWorkingHours(?CarbonInterface $now = null): bool
    {
        $current = ($now ? Carbon::parse($now) : Carbon::now())->setTimezone(self::TIMEZONE);

        if ($current->isWeekend()) {
            return false;
        }

        return $current->hour >= self::WORK_START_HOUR && $current->hour < self::WORK_END_HOUR;
    }

    /**
     * Evaluasi SLA untuk tahap tertentu:
     * - Batas SLA: 120 menit (2 jam kerja).
     * - Jika selesai: tampilkan "Durasi: X".
     * - Jika berjalan <= 120 menit: tampilkan "Sisa SLA: X".
     * - Jika berjalan > 120 menit: tandai terlambat dan tampilkan "SLA Terlambat: X" tanpa mengubah status.
     */
    public static function evaluateStageSla(
        CarbonInterface $startDate,
        ?CarbonInterface $endDate = null,
        ?CarbonInterface $now = null
    ): array {
        $effectiveEnd = $endDate ?? ($now ? Carbon::parse($now)->setTimezone(self::TIMEZONE) : Carbon::now(self::TIMEZONE));
        $elapsed = self::calculateBusinessMinutes($startDate, $effectiveEnd);
        $isFinished = $endDate !== null;

        if ($isFinished) {
            return [
                'elapsed_minutes' => $elapsed,
                'is_finished' => true,
                'is_overdue' => $elapsed > self::STAGE_TARGET_MINUTES,
                'label' => 'Durasi: ' . self::formatBusinessDuration($elapsed),
            ];
        }

        if ($elapsed <= self::STAGE_TARGET_MINUTES) {
            $remaining = self::STAGE_TARGET_MINUTES - $elapsed;
            return [
                'elapsed_minutes' => $elapsed,
                'remaining_minutes' => $remaining,
                'is_finished' => false,
                'is_overdue' => false,
                'label' => 'Sisa SLA: ' . self::formatBusinessDuration($remaining),
            ];
        }

        $overdue = $elapsed - self::STAGE_TARGET_MINUTES;
        return [
            'elapsed_minutes' => $elapsed,
            'overdue_minutes' => $overdue,
            'is_finished' => false,
            'is_overdue' => true,
            'label' => 'SLA Terlambat: ' . self::formatBusinessDuration($overdue),
        ];
    }

    /**
     * Evaluasi SLA pengajuan mutasi:
     * 1. SLA TIDAK berjalan saat pengajuan masih diproses Operator ('diajukan').
     * 2. SLA mulai berjalan tepat saat Operator berhasil meneruskan ke Bagian Aset ('verified_at').
     * 3. Batas SLA adalah 2 jam kerja (120 menit), Senin–Jumat 08.00–17.00 WITA.
     * 4. Setelah tahap Bagian Aset selesai dan diteruskan ke Kadiv, SLA Bagian Aset berhenti dan SLA Kadiv mulai dari timestamp transisi ke Kadiv ('approved_at').
     * 5. Waktu tunggu Pemohon tidak dihitung sebagai SLA petugas ('dikembalikan_ke_pemohon', 'menunggu_konfirmasi_pemohon').
     * 6. Tidak ada perubahan status otomatis saat SLA terlambat.
     */
    public static function evaluateMutationSla(
        \App\Models\Mutation $mutation,
        ?CarbonInterface $now = null
    ): array {
        $status = $mutation->status;

        switch ($status) {
            case 'diajukan':
                return [
                    'stage' => 'operator',
                    'sla_active' => false,
                    'is_finished' => false,
                    'is_overdue' => false,
                    'elapsed_minutes' => 0,
                    'label' => 'Dalam Pemeriksaan Operator',
                ];

            case 'menunggu_verifikasi_bagian_aset':
                $start = $mutation->verified_at
                    ? Carbon::parse($mutation->verified_at)->setTimezone(self::TIMEZONE)
                    : Carbon::parse($mutation->created_at)->setTimezone(self::TIMEZONE);
                $res = self::evaluateStageSla($start, null, $now);
                $res['stage'] = 'bagian_aset';
                $res['sla_active'] = true;
                return $res;

            case 'menunggu_approval_pemimpin_divisi':
                $start = $mutation->approved_at
                    ? Carbon::parse($mutation->approved_at)->setTimezone(self::TIMEZONE)
                    : ($mutation->verified_at
                        ? Carbon::parse($mutation->verified_at)->setTimezone(self::TIMEZONE)
                        : Carbon::parse($mutation->created_at)->setTimezone(self::TIMEZONE));
                $res = self::evaluateStageSla($start, null, $now);
                $res['stage'] = 'pemimpin_divisi';
                $res['sla_active'] = true;
                return $res;

            case 'dikembalikan_ke_pemohon':
            case 'menunggu_konfirmasi_pemohon':
                return [
                    'stage' => 'pemohon',
                    'sla_active' => false,
                    'is_finished' => false,
                    'is_overdue' => false,
                    'elapsed_minutes' => 0,
                    'label' => 'Menunggu Pemohon',
                ];

            case 'selesai':
            case 'ditolak':
            default:
                $start = Carbon::parse($mutation->created_at)->setTimezone(self::TIMEZONE);
                $end = $mutation->rejected_at ?? $mutation->confirmed_at ?? $mutation->approved_at;
                $endDate = $end ? Carbon::parse($end)->setTimezone(self::TIMEZONE) : null;
                $res = self::evaluateStageSla($start, $endDate, $now);
                $res['stage'] = 'completed';
                $res['sla_active'] = false;
                return $res;
        }
    }
}
