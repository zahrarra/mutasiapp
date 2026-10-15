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
                'name' => 'Dirly Dwi',
                'email' => 'admin@mutasiku.test',
                'nip' => '100001',
                'role' => 'admin',
                'department' => 'Umum & Aset',
            ],
            [
                'name' => 'Zahra Aya',
                'email' => 'pemohon@mutasiku.test',
                'nip' => '100002',
                'role' => 'pemohon',
            ],
            [
                'name' => 'Alifa Marsya',
                'email' => 'operator@mutasiku.test',
                'nip' => '100003',
                'role' => 'operator',
                'department' => 'Umum & Aset',
            ],
            [
                'name' => 'Atalya Rara',
                'email' => 'aset@mutasiku.test',
                'nip' => '100004',
                'role' => 'bagian_aset',
                'department' => 'Umum & Aset',
            ],
            [
                'name' => 'Nadia Nad',
                'email' => 'pemimpin@mutasiku.test',
                'nip' => '100005',
                'role' => 'pemimpin_divisi',
                'department' => 'Umum & Aset',
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
            [
                'name' => 'Anisa Aulia',
                'email' => 'anisa.aulia@mutasiku.test',
                'nip' => '100011',
                'role' => 'pemohon',
            ],
        ];

        foreach ($users as $data) {
            $role = Role::where('name', $data['role'])->firstOrFail();

            // Cari pengguna berdasarkan identitas unik: NIP terlebih dahulu, lalu email
            $existing = null;
            if (! empty($data['nip'])) {
                $existing = User::where('nip', $data['nip'])->first();
            }
            if (! $existing && ! empty($data['email'])) {
                $existing = User::where('email', $data['email'])->first();
            }

            if ($existing) {
                // Pengguna sudah ada: pertahankan seluruh data yang sudah ada
                // (nama, email, role, password, status aktif, must_change_password)
                // Sinkronkan divisi pengujian jika ditentukan pada seeder dan berbeda
                if (isset($data['department']) && $existing->department !== $data['department']) {
                    $existing->update(['department' => $data['department']]);
                }
                continue;
            }

            // Pengguna contoh belum ada: buat pengguna baru
            User::create([
                'name' => $data['name'],
                'email' => $data['email'],
                'nip' => $data['nip'],
                'role_id' => $role->id,
                'password' => 'password',
                'department' => $data['department'] ?? null,
                'is_active' => true,
                'must_change_password' => true,
            ]);
        }
    }
}