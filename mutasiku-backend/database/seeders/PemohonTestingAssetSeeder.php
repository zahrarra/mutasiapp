<?php

namespace Database\Seeders;

use App\Models\Asset;
use App\Models\AssetCategory;
use App\Models\Location;
use App\Models\User;
use Illuminate\Database\Seeder;

class PemohonTestingAssetSeeder extends Seeder
{
    /**
     * Run the database seeds for exactly 20 dummy assets:
     * - 10 TI Assets (AST-TI-2026-001..010)
     * - 10 Umum Assets (AST-UM-2026-001..010)
     *
     * Varied PICs across Pemohon and other staff members.
     * Fully idempotent with updateOrCreate to prevent duplication on re-run.
     */
    public function run(): void
    {
        $pemohon = User::where('email', 'pemohon@mutasiku.test')->first()
            ?? User::whereHas('role', fn ($q) => $q->where('name', 'pemohon'))->first();

        if (! $pemohon) {
            $this->command?->error('User pemohon utama belum tersedia. Jalankan UserSeeder terlebih dahulu.');
            return;
        }

        $budi = User::where('email', 'budi.santoso@mutasiku.test')->first() ?? $pemohon;
        $ahmad = User::where('email', 'ahmad.fauzi@mutasiku.test')->first() ?? $pemohon;
        $siti = User::where('email', 'siti.nurhaliza@mutasiku.test')->first() ?? $pemohon;
        $dewi = User::where('email', 'dewi.lestari@mutasiku.test')->first() ?? $pemohon;
        $rizky = User::where('email', 'rizky.pratama@mutasiku.test')->first() ?? $pemohon;

        $catTi = AssetCategory::where('code', 'TI')->first();
        $catUmum = AssetCategory::where('code', 'UM')->first();

        $locTi = Location::where('code', 'RG-TI')->first() ?? Location::first();
        $locOps = Location::where('code', 'RG-OPS')->first() ?? $locTi;
        $locSiber = Location::where('code', 'RG-SIBER')->first() ?? $locTi;
        $locTeller = Location::where('code', 'UMUM-TELLER')->first() ?? $locOps;
        $locKrd = Location::where('code', 'RG-KRD')->first() ?? $locOps;
        $locHkm = Location::where('code', 'RG-HKM')->first() ?? $locOps;
        $locRapat = Location::where('code', 'UMUM-RAPAT')->first() ?? $locTi;
        $locServer = Location::where('code', 'UMUM-SERVER')->first() ?? $locTi;
        $locUma = Location::where('code', 'RG-UMA')->first() ?? $locOps;
        $locSdm = Location::where('code', 'RG-SDM')->first() ?? $locOps;
        $locGudang = Location::where('code', 'UMUM-GUDANG')->first() ?? $locUma;
        $locLobby = Location::where('code', 'UMUM-LOBBY')->first() ?? $locTeller;
        $locTunggu = Location::where('code', 'UMUM-TUNGGU')->first() ?? $locTeller;
        $locAtm = Location::where('code', 'UMUM-ATM')->first() ?? $locTeller;
        $locParkir = Location::where('code', 'UMUM-PKB')->first() ?? Location::first();

        if (! $catTi || ! $catUmum || ! $locTi) {
            $this->command?->error('Prasyarat Kategori TI/Umum atau Lokasi belum lengkap di database.');
            return;
        }

        $assets = [
            // ==========================================
            // 10 ASET TI (Kategori TI)
            // ==========================================
            [
                'asset_code' => 'AST-TI-2026-001',
                'name' => 'Laptop Lenovo ThinkPad L14 Gen 4',
                'asset_category_id' => $catTi->id,
                'location_id' => $locTi->id,
                'pic_id' => $pemohon->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-LNV-2026-001',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-TI-2026-002',
                'name' => 'Laptop ASUS ExpertBook B1 B1400',
                'asset_category_id' => $catTi->id,
                'location_id' => $locOps->id,
                'pic_id' => $pemohon->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-ASUS-2026-002',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-TI-2026-003',
                'name' => 'Laptop HP ProBook 440 G9 Core i7',
                'asset_category_id' => $catTi->id,
                'location_id' => $locSiber->id,
                'pic_id' => $pemohon->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-HP-2026-003',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-TI-2026-004',
                'name' => 'PC Desktop Dell OptiPlex 7090 Micro',
                'asset_category_id' => $catTi->id,
                'location_id' => $locTeller->id,
                'pic_id' => $pemohon->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-DELL-2026-004',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-TI-2026-005',
                'name' => 'Monitor Dell UltraSharp 24" U2422H',
                'asset_category_id' => $catTi->id,
                'location_id' => $locTi->id,
                'pic_id' => $pemohon->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-DELL-2026-005',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-TI-2026-006',
                'name' => 'Monitor LG 27 Inch UltraFine 4K UHD',
                'asset_category_id' => $catTi->id,
                'location_id' => $locSiber->id,
                'pic_id' => $budi->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-LG-2026-006',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-TI-2026-007',
                'name' => 'Printer Canon imageCLASS LBP6030w',
                'asset_category_id' => $catTi->id,
                'location_id' => $locKrd->id,
                'pic_id' => $ahmad->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-CAN-2026-007',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-TI-2026-008',
                'name' => 'Scanner Epson Perfection V39 II Flatbed',
                'asset_category_id' => $catTi->id,
                'location_id' => $locHkm->id,
                'pic_id' => $siti->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-EPS-2026-008',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-TI-2026-009',
                'name' => 'Proyektor Epson EB-E500 3300 Lumens',
                'asset_category_id' => $catTi->id,
                'location_id' => $locRapat->id,
                'pic_id' => $dewi->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-EPS-2026-009',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-TI-2026-010',
                'name' => 'UPS APC Back-UPS 1100VA BX1100LI-MS',
                'asset_category_id' => $catTi->id,
                'location_id' => $locServer->id,
                'pic_id' => $rizky->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-APC-2026-010',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],

            // ==========================================
            // 10 ASET UMUM (Kategori UM)
            // ==========================================
            [
                'asset_code' => 'AST-UM-2026-001',
                'name' => 'AC Split Daikin 1.5 PK Flash Inverter',
                'asset_category_id' => $catUmum->id,
                'location_id' => $locRapat->id,
                'pic_id' => $pemohon->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-DKN-2026-001',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-UM-2026-002',
                'name' => 'Meja Kerja Kayu Jati Minimalis 1/2 Biro',
                'asset_category_id' => $catUmum->id,
                'location_id' => $locUma->id,
                'pic_id' => $pemohon->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-MJA-2026-002',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-UM-2026-003',
                'name' => 'Kursi Kerja Ergonomis Mesh Chairman Pro',
                'asset_category_id' => $catUmum->id,
                'location_id' => $locSdm->id,
                'pic_id' => $pemohon->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-KRS-2026-003',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-UM-2026-004',
                'name' => 'Lemari Arsip Besi 4 Pintu Swing Lion',
                'asset_category_id' => $catUmum->id,
                'location_id' => $locGudang->id,
                'pic_id' => $pemohon->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-LMR-2026-004',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-UM-2026-005',
                'name' => 'Rak Dokumen 5 Susun Modera File Storage',
                'asset_category_id' => $catUmum->id,
                'location_id' => $locOps->id,
                'pic_id' => $pemohon->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-RAK-2026-005',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-UM-2026-006',
                'name' => 'Sofa Tamu 3 Seater Executive Kulit Oscar',
                'asset_category_id' => $catUmum->id,
                'location_id' => $locLobby->id,
                'pic_id' => $budi->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-SFA-2026-006',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-UM-2026-007',
                'name' => 'Whiteboard Magnetic 120x240cm Sakana Roda',
                'asset_category_id' => $catUmum->id,
                'location_id' => $locRapat->id,
                'pic_id' => $ahmad->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-WBD-2026-007',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-UM-2026-008',
                'name' => 'Televisi LED Smart TV Samsung 55 Inch 4K UHD',
                'asset_category_id' => $catUmum->id,
                'location_id' => $locTunggu->id,
                'pic_id' => $siti->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-SMG-2026-008',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-UM-2026-009',
                'name' => 'CCTV Dome Hikvision 4MP Indoor IP Network Cam',
                'asset_category_id' => $catUmum->id,
                'location_id' => $locAtm->id,
                'pic_id' => $dewi->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-HIK-2026-009',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-UM-2026-010',
                'name' => 'Kendaraan Operasional Toyota Avanza 1.5 G MT',
                'asset_category_id' => $catUmum->id,
                'location_id' => $locParkir->id,
                'pic_id' => $rizky->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-KDR-2026-010',
                'acquisition_year' => 2026,
                'usage_year' => 2026,
                'is_active' => true,
            ],
        ];

        $validCodes = collect($assets)->pluck('asset_code')->all();

        // Ambil ID aset yang sedang terikat dalam mutasi aktif (belum berstatus terminal)
        $activeMutationAssetIds = \App\Models\Mutation::active()
            ->pluck('asset_id')
            ->filter()
            ->unique()
            ->all();

        // Hanya hapus aset testing dummy usang yang spesifik, BUKAN aset nyata,
        // dan pastikan tidak terikat riwayat/mutasi apa pun.
        Asset::where(function ($q) {
                $q->where('asset_code', 'like', 'AST-TI-2026-01%')
                  ->orWhere('asset_code', 'like', 'AST-TI-2026-02%')
                  ->orWhere('asset_code', 'like', 'AST-ELK-2024-%')
                  ->orWhere('asset_code', 'like', '%DUMMY%');
            })
            ->whereNotIn('asset_code', $validCodes)
            ->whereDoesntHave('mutations')
            ->delete();

        foreach ($assets as $data) {
            $existing = Asset::where('asset_code', $data['asset_code'])->first();
            if ($existing) {
                // Jangan mengubah data aset jika sedang terkait mutasi aktif
                if (in_array($existing->id, $activeMutationAssetIds)) {
                    continue;
                }
                $existing->update($data);
            } else {
                Asset::create($data);
            }
        }

        $this->command?->info('Berhasil menyelaraskan tepat 20 aset dummy (10 TI, 10 Umum) dengan perlindungan aset nyata & mutasi aktif.');
    }
}
