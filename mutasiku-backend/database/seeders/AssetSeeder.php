<?php

namespace Database\Seeders;

use App\Models\Asset;
use App\Models\AssetCategory;
use App\Models\Location;
use App\Models\User;
use Illuminate\Database\Seeder;

class AssetSeeder extends Seeder
{
    public function run(): void
    {
        $pemohon = User::where('email', 'pemohon@mutasiku.test')->first();
        $operator = User::where('email', 'operator@mutasiku.test')->first();
        $catTi = AssetCategory::where('code', 'TI')->first();
        $catUmum = AssetCategory::where('code', 'UM')->first();
        $locKp = Location::where('code', 'KP')->first();
        $locGa = Location::where('code', 'GA')->first();

        if (! $pemohon || ! $catTi || ! $locKp) {
            return;
        }

        $assets = [
            [
                'asset_code' => 'AST-ELK-2024-001',
                'name' => 'Laptop Lenovo ThinkPad T14',
                'asset_category_id' => $catTi->id,
                'location_id' => $locKp->id,
                'pic_id' => $pemohon->id,
                'condition' => 'Baik',
                'serial_number' => 'PF-2024-001',
                'acquisition_year' => 2024,
                'usage_year' => 2024,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-ELK-2024-002',
                'name' => 'Monitor Dell UltraSharp 27"',
                'asset_category_id' => $catTi->id,
                'location_id' => $locKp->id,
                'pic_id' => $pemohon->id,
                'condition' => 'Baik',
                'serial_number' => 'CN-2024-002',
                'acquisition_year' => 2024,
                'usage_year' => 2024,
                'is_active' => true,
            ],
            [
                'asset_code' => 'AST-ELK-2024-003',
                'name' => 'Printer HP LaserJet Pro M404dn',
                'asset_category_id' => $catTi->id,
                'location_id' => $locGa?->id ?? $locKp->id,
                'pic_id' => $operator?->id ?? $pemohon->id,
                'condition' => 'Baik',
                'serial_number' => 'HP-2024-003',
                'acquisition_year' => 2023,
                'usage_year' => 2023,
                'is_active' => true,
            ],
        ];

        foreach ($assets as $assetData) {
            Asset::updateOrCreate(
                ['asset_code' => $assetData['asset_code']],
                $assetData
            );
        }
    }
}
