<?php

namespace Tests\Unit;

use App\Support\SlaCalculator;
use Carbon\Carbon;
use Tests\TestCase;

class SlaCalculatorTest extends TestCase
{
    public function test_calculates_minutes_within_same_business_day(): void
    {
        // Jumat, 09 Okt 2026, 09:00 WITA ke 11:30 WITA = 150 menit (2.5 jam)
        $start = Carbon::create(2026, 10, 9, 9, 0, 0, SlaCalculator::TIMEZONE);
        $end = Carbon::create(2026, 10, 9, 11, 30, 0, SlaCalculator::TIMEZONE);

        $minutes = SlaCalculator::calculateBusinessMinutes($start, $end);
        $this->assertEquals(150, $minutes);
        $this->assertEquals('2 Jam 30 Menit', SlaCalculator::formatBusinessDuration($minutes));
    }

    public function test_ignores_weekend_hours(): void
    {
        // Jumat, 09 Okt 2026, 15:00 WITA ke Senin, 12 Okt 2026, 10:00 WITA
        // Jumat 15:00 - 17:00 = 2 jam (120 menit)
        // Sabtu & Minggu = 0 menit
        // Senin 08:00 - 10:00 = 2 jam (120 menit)
        // Total = 4 jam (240 menit)
        $start = Carbon::create(2026, 10, 9, 15, 0, 0, SlaCalculator::TIMEZONE);
        $end = Carbon::create(2026, 10, 12, 10, 0, 0, SlaCalculator::TIMEZONE);

        $minutes = SlaCalculator::calculateBusinessMinutes($start, $end);
        $this->assertEquals(240, $minutes);
        $this->assertEquals('4 Jam', SlaCalculator::formatBusinessDuration($minutes));
    }

    public function test_ignores_non_working_hours_at_night(): void
    {
        // Kamis 16:00 WITA ke Jumat 09:00 WITA
        // Kamis 16:00 - 17:00 = 1 jam (60 menit)
        // Malam (17:00 - 08:00) = 0 menit
        // Jumat 08:00 - 09:00 = 1 jam (60 menit)
        // Total = 2 jam (120 menit)
        $start = Carbon::create(2026, 10, 8, 16, 0, 0, SlaCalculator::TIMEZONE);
        $end = Carbon::create(2026, 10, 9, 9, 0, 0, SlaCalculator::TIMEZONE);

        $minutes = SlaCalculator::calculateBusinessMinutes($start, $end);
        $this->assertEquals(120, $minutes);
    }

    public function test_returns_zero_if_entirely_in_weekend(): void
    {
        // Sabtu 10 Okt 2026 10:00 ke Minggu 11 Okt 2026 16:00
        $start = Carbon::create(2026, 10, 10, 10, 0, 0, SlaCalculator::TIMEZONE);
        $end = Carbon::create(2026, 10, 11, 16, 0, 0, SlaCalculator::TIMEZONE);

        $minutes = SlaCalculator::calculateBusinessMinutes($start, $end);
        $this->assertEquals(0, $minutes);
    }

    public function test_evaluates_stage_sla_remaining_and_overdue_with_2_hours_limit(): void
    {
        // 1 Jam kerja berjalan (masih ada sisa 1 jam)
        $start = Carbon::create(2026, 10, 9, 9, 0, 0, SlaCalculator::TIMEZONE);
        $oneHourLater = Carbon::create(2026, 10, 9, 10, 0, 0, SlaCalculator::TIMEZONE);

        $res1 = SlaCalculator::evaluateStageSla($start, $oneHourLater);
        $this->assertEquals(60, $res1['elapsed_minutes']);
        $this->assertEquals('Durasi: 1 Jam', $res1['label']);
        $this->assertFalse($res1['is_overdue']);

        // Masih berjalan setelah 45 menit (Sisa SLA 75 Menit = 1 Jam 15 Menit)
        $fortyFiveMinLater = Carbon::create(2026, 10, 9, 9, 45, 0, SlaCalculator::TIMEZONE);
        Carbon::setTestNow($fortyFiveMinLater);

        $res2 = SlaCalculator::evaluateStageSla($start);
        $this->assertEquals(45, $res2['elapsed_minutes']);
        $this->assertEquals(75, $res2['remaining_minutes']);
        $this->assertEquals('Sisa SLA: 1 Jam 15 Menit', $res2['label']);
        $this->assertFalse($res2['is_overdue']);

        // Melewati 2 jam kerja (misal 2.5 jam = 150 menit -> SLA Terlambat: 30 Menit)
        $twoAndHalfHoursLater = Carbon::create(2026, 10, 9, 11, 30, 0, SlaCalculator::TIMEZONE);
        Carbon::setTestNow($twoAndHalfHoursLater);

        $res3 = SlaCalculator::evaluateStageSla($start);
        $this->assertEquals(150, $res3['elapsed_minutes']);
        $this->assertEquals(30, $res3['overdue_minutes']);
        $this->assertEquals('SLA Terlambat: 30 Menit', $res3['label']);
        $this->assertTrue($res3['is_overdue']);

        Carbon::setTestNow(); // Reset test now
    }

    public function test_evaluates_mutation_sla_stages_correctly(): void
    {
        $created = Carbon::create(2026, 10, 9, 8, 30, 0, SlaCalculator::TIMEZONE);
        $forwardedToAsset = Carbon::create(2026, 10, 9, 9, 0, 0, SlaCalculator::TIMEZONE);
        $forwardedToKadiv = Carbon::create(2026, 10, 9, 10, 30, 0, SlaCalculator::TIMEZONE);

        // 1. Tahap Operator (diajukan): SLA TIDAK BERJALAN
        $mutationOperator = new \App\Models\Mutation([
            'status' => 'diajukan',
            'created_at' => $created,
        ]);
        $resOperator = SlaCalculator::evaluateMutationSla($mutationOperator);
        $this->assertFalse($resOperator['sla_active']);
        $this->assertEquals('Dalam Pemeriksaan Operator', $resOperator['label']);

        // 2. Tahap Bagian Aset (menunggu_verifikasi_bagian_aset):
        // SLA mulai tepat dari timestamp saat Operator meneruskan (verified_at = 09:00 WITA)
        $mutationAsset = new \App\Models\Mutation([
            'status' => 'menunggu_verifikasi_bagian_aset',
            'created_at' => $created,
            'verified_at' => $forwardedToAsset,
        ]);
        // Pada pukul 10:00 (berjalan 60 menit) -> Sisa SLA 60 menit (1 Jam)
        $nowAt10 = Carbon::create(2026, 10, 9, 10, 0, 0, SlaCalculator::TIMEZONE);
        $resAsset = SlaCalculator::evaluateMutationSla($mutationAsset, $nowAt10);
        $this->assertTrue($resAsset['sla_active']);
        $this->assertEquals(60, $resAsset['elapsed_minutes']);
        $this->assertEquals('Sisa SLA: 1 Jam', $resAsset['label']);
        $this->assertFalse($resAsset['is_overdue']);

        // Pada pukul 11:30 (berjalan 150 menit > 120 menit) -> Terlambat 30 menit
        $nowAt1130 = Carbon::create(2026, 10, 9, 11, 30, 0, SlaCalculator::TIMEZONE);
        $resAssetOverdue = SlaCalculator::evaluateMutationSla($mutationAsset, $nowAt1130);
        $this->assertTrue($resAssetOverdue['is_overdue']);
        $this->assertEquals('SLA Terlambat: 30 Menit', $resAssetOverdue['label']);

        // 3. Tahap Kadiv (menunggu_approval_pemimpin_divisi):
        // SLA Bagian Aset berhenti. SLA Kadiv mulai tepat saat diteruskan Bagian Aset (approved_at = 10:30 WITA)
        $mutationKadiv = new \App\Models\Mutation([
            'status' => 'menunggu_approval_pemimpin_divisi',
            'created_at' => $created,
            'verified_at' => $forwardedToAsset,
            'approved_at' => $forwardedToKadiv,
        ]);
        // Pada pukul 11:15 (berjalan 45 menit untuk Kadiv) -> Sisa SLA 75 menit (1 Jam 15 Menit)
        $nowAt1115 = Carbon::create(2026, 10, 9, 11, 15, 0, SlaCalculator::TIMEZONE);
        $resKadiv = SlaCalculator::evaluateMutationSla($mutationKadiv, $nowAt1115);
        $this->assertTrue($resKadiv['sla_active']);
        $this->assertEquals(45, $resKadiv['elapsed_minutes']);
        $this->assertEquals('Sisa SLA: 1 Jam 15 Menit', $resKadiv['label']);

        // 4. Tahap Pemohon (menunggu_konfirmasi_pemohon atau dikembalikan):
        // Waktu tunggu Pemohon tidak dihitung sebagai SLA petugas
        $mutationPemohon = new \App\Models\Mutation([
            'status' => 'menunggu_konfirmasi_pemohon',
            'created_at' => $created,
        ]);
        $resPemohon = SlaCalculator::evaluateMutationSla($mutationPemohon);
        $this->assertFalse($resPemohon['sla_active']);
        $this->assertEquals('Menunggu Pemohon', $resPemohon['label']);
    }
}
