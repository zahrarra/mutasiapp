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
        ];

        foreach ($users as $data) {
            $role = Role::where('name', $data['role'])->firstOrFail();

            User::updateOrCreate(
                ['email' => $data['email']],
                [
                    'name' => $data['name'],
                    'nip' => $data['nip'],
                    'role_id' => $role->id,
                    'password' => 'password',
                    'is_active' => true,
                ]
            );
        }
    }
}