<?php

namespace Database\Seeders;

use App\Models\Location;
use Illuminate\Database\Seeder;

class LocationSeeder extends Seeder
{
    public function run(): void
    {
        $locations = [
            [
                'name' => 'Kantor Pusat',
                'code' => 'KP',
            ],
            [
                'name' => 'Gedung A',
                'code' => 'GA',
            ],
            [
                'name' => 'Gedung B',
                'code' => 'GB',
            ],
            [
                'name' => 'Ruang Divisi Umum',
                'code' => 'DU',
            ],
        ];

        foreach ($locations as $location) {
            Location::firstOrCreate(
                ['code' => $location['code']],
                $location
            );
        }
    }
}