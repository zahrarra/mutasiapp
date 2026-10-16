<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            RoleSeeder::class,
            AssetCategorySeeder::class,
            LocationSeeder::class,
            UserSeeder::class,
            AssetSeeder::class,
        ]);
    }
}