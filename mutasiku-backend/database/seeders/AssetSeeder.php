<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class AssetSeeder extends Seeder
{
    /**
     * Mendelegasikan pembentukan master data aset ke PemohonTestingAssetSeeder
     * untuk memastikan tepat 20 aset dummy (10 TI, 10 Umum) tanpa duplikasi.
     */
    public function run(): void
    {
        $this->call(PemohonTestingAssetSeeder::class);
    }
}
