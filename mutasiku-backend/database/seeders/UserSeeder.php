<?php

namespace Database\Seeders;

use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $users = [
            [
                'name' => 'Admin MutasiKu',
                'email' => 'admin@mutasiku.test',
                'nip' => '100001',
                'role' => 'admin',
            ],
            [
                'name' => 'Pemohon MutasiKu',
                'email' => 'pemohon@mutasiku.test',
                'nip' => '100002',
                'role' => 'pemohon',
            ],
            [
                'name' => 'Operator MutasiKu',
                'email' => 'operator@mutasiku.test',
                'nip' => '100003',
                'role' => 'operator',
            ],
            [
                'name' => 'Bagian Aset MutasiKu',
                'email' => 'aset@mutasiku.test',
                'nip' => '100004',
                'role' => 'bagian_aset',
            ],
            [
                'name' => 'Pemimpin Divisi MutasiKu',
                'email' => 'pemimpin@mutasiku.test',
                'nip' => '100005',
                'role' => 'pemimpin_divisi',
            ],
            [
                'name' => 'Budi Santoso',
                'email' => 'budi.santoso@mutasiku.test',
                'nip' => '100006',
                'role' => 'pemohon',
            ],
            [
                'name' => 'Ahmad Fauzi',
                'email' => 'ahmad.fauzi@mutasiku.test',
                'nip' => '100007',
                'role' => 'pemohon',
            ],
            [
                'name' => 'Siti Nurhaliza',
                'email' => 'siti.nurhaliza@mutasiku.test',
                'nip' => '100008',
                'role' => 'pemohon',
            ],
            [
                'name' => 'Dewi Lestari',
                'email' => 'dewi.lestari@mutasiku.test',
                'nip' => '100009',
                'role' => 'pemohon',
            ],
            [
                'name' => 'Rizky Pratama',
                'email' => 'rizky.pratama@mutasiku.test',
                'nip' => '100010',
                'role' => 'pemohon',
            ],
        ];

        foreach ($users as $data) {
            $role = Role::where('name', $data['role'])->firstOrFail();

            $existing = User::where('email', $data['email'])->first();
            if ($existing) {
                // Pertahankan password, is_active, dan must_change_password yang sudah ada
                $existing->update([
                    'name' => $data['name'],
                    'nip' => $data['nip'],
                    'role_id' => $role->id,
                ]);
            } else {
                User::create([
                    'name' => $data['name'],
                    'email' => $data['email'],
                    'nip' => $data['nip'],
                    'role_id' => $role->id,
                    'password' => 'password',
                    'is_active' => true,
                    'must_change_password' => true,
                ]);
            }
        }
    }
}