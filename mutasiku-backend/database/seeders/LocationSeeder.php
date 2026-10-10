<?php

namespace Database\Seeders;

use App\Models\Location;
use Illuminate\Database\Seeder;

class LocationSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Daftar Lokasi Acuan Resmi dari Pengguna (Aktif di formulir Pemohon & publik API)
        $officialLocations = [
            // Gedung / Area Umum
            ['name' => 'Parkiran Basement', 'code' => 'UMUM-PKB'],
            ['name' => 'Parkiran Lobby', 'code' => 'UMUM-PKL'],
            ['name' => 'Lobby', 'code' => 'UMUM-LOBBY'],
            ['name' => 'Area Teller', 'code' => 'UMUM-TELLER'],
            ['name' => 'Ruang Tunggu Nasabah', 'code' => 'UMUM-TUNGGU'],
            ['name' => 'Area ATM', 'code' => 'UMUM-ATM'],
            ['name' => 'Toilet', 'code' => 'UMUM-TOILET'],
            ['name' => 'Pantry', 'code' => 'UMUM-PANTRY'],
            ['name' => 'Mushola', 'code' => 'UMUM-MUSHOLA'],
            ['name' => 'Ruang Rapat', 'code' => 'UMUM-RAPAT'],
            ['name' => 'Gudang Penyimpanan', 'code' => 'UMUM-GUDANG'],
            ['name' => 'Ruang Server', 'code' => 'UMUM-SERVER'],

            // Lantai & Ruang Divisi
            ['name' => 'Lantai 1', 'code' => 'LT-1'],
            ['name' => 'Lantai 2', 'code' => 'LT-2'],
            ['name' => 'Lantai 3', 'code' => 'LT-3'],
            ['name' => 'Lantai 4', 'code' => 'LT-4'],
            ['name' => 'Ruang Divisi TI', 'code' => 'RG-TI'],
            ['name' => 'Ruang UKK Siber', 'code' => 'RG-SIBER'],
            ['name' => 'Ruang Divisi Treasury', 'code' => 'RG-TRS'],
            ['name' => 'Ruang Divisi Umum dan Aset', 'code' => 'RG-UMA'],
            ['name' => 'Ruang Divisi SDM', 'code' => 'RG-SDM'],
            ['name' => 'Ruang Divisi Operasional', 'code' => 'RG-OPS'],
            ['name' => 'Ruang Divisi Kredit', 'code' => 'RG-KRD'],
            ['name' => 'Ruang Divisi SKAI', 'code' => 'RG-SKAI'],
            ['name' => 'Ruang Divisi Pemasaran', 'code' => 'RG-MKT'],
            ['name' => 'Ruang Divisi Literasi', 'code' => 'RG-LIT'],
            ['name' => 'Ruang Divisi Hukum', 'code' => 'RG-HKM'],

            // Kantor / Cabang
            ['name' => 'KCU Palu', 'code' => 'CAB-PLU-KCU'],
            ['name' => 'Cabang Tawaeli', 'code' => 'CAB-TWL'],
            ['name' => 'Cabang Sigi', 'code' => 'CAB-SIGI'],
            ['name' => 'Cabang Donggala', 'code' => 'CAB-DGL'],
            ['name' => 'Cabang Palu Barat', 'code' => 'CAB-PLUBAR'],
            ['name' => 'Cabang Tinombala', 'code' => 'CAB-TNM'],
            ['name' => 'Cabang Poso', 'code' => 'CAB-POSO'],
            ['name' => 'Cabang Luwuk', 'code' => 'CAB-LWK'],
            ['name' => 'Cabang Jakarta', 'code' => 'CAB-JKT'],
            ['name' => 'Cabang Makassar', 'code' => 'CAB-MKS'],
        ];

        // Seed / perbarui seluruh lokasi acuan pengguna agar berstatus is_active = true
        foreach ($officialLocations as $location) {
            Location::updateOrCreate(
                ['code' => $location['code']],
                [
                    'name' => $location['name'],
                    'code' => $location['code'],
                    'is_active' => true,
                ]
            );
        }

        // Nonaktifkan lokasi lama yang tidak sesuai (Kantor Pusat, Gedung A, Gedung B, Ruang Divisi Umum,
        // Cabang Surabaya, Cabang Bandung, Cabang Semarang) serta lokasi dummy audit.
        // Data lama dipertahankan di database demi menjaga integritas foreign key aset dan mutasi historis,
        // namun tidak boleh lagi muncul sebagai opsi aktif di formulir Pemohon / publik API.
        Location::whereIn('code', [
            'KP',
            'GA',
            'GB',
            'DU',
            'CAB-SBY',
            'CAB-BDG',
            'CAB-SMG',
            'AUD_L1',
            'AUD_L2',
        ])->update(['is_active' => false]);
    }
}