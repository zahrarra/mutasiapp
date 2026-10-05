<?php

namespace Database\Seeders;

use App\Models\AssetCategory;
use Illuminate\Database\Seeder;

class AssetCategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            [
                'name' => 'Aset TI',
                'code' => 'TI',
            ],
            [
                'name' => 'Aset Umum',
                'code' => 'UM',
            ],
        ];

        foreach ($categories as $category) {
            AssetCategory::firstOrCreate(
                ['code' => $category['code']],
                $category
            );
        }
    }
}