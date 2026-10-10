<?php

namespace Tests\Feature;

use App\Models\Location;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LocationAuditTest extends TestCase
{
    use RefreshDatabase;

    private function createRole(string $name): Role
    {
        return Role::create([
            'name' => $name,
            'display_name' => ucfirst($name),
            'description' => 'Role for testing',
        ]);
    }

    private function createUser(string $roleName): User
    {
        $role = Role::where('name', $roleName)->first() ?? $this->createRole($roleName);

        return User::create([
            'name' => 'User ' . ucfirst($roleName),
            'email' => $roleName . '@test.com',
            'password' => bcrypt('password'),
            'role_id' => $role->id,
            'is_active' => true,
        ]);
    }

    public function test_public_locations_endpoint_only_returns_approved_active_locations(): void
    {
        // 1. Lokasi resmi disetujui (aktif)
        Location::create(['name' => 'Kantor Pusat', 'code' => 'KP', 'is_active' => true]);
        Location::create(['name' => 'Gedung A', 'code' => 'GA', 'is_active' => true]);
        Location::create(['name' => 'Cabang Surabaya', 'code' => 'CAB-SBY', 'is_active' => true]);

        // 2. Lokasi usulan / audit (nonaktif)
        Location::create(['name' => 'Gedung A Audit', 'code' => 'AUD_L1', 'is_active' => false]);
        Location::create(['name' => 'Parkiran Basement', 'code' => 'UMUM-PKB', 'is_active' => false]);

        $user = $this->createUser('pemohon');
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/locations');

        $response->assertStatus(200);
        $data = $response->json('data');

        // Pastikan hanya lokasi aktif (3) yang dikembalikan
        $this->assertCount(3, $data);
        $names = collect($data)->pluck('name')->all();
        $this->assertContains('Kantor Pusat', $names);
        $this->assertContains('Gedung A', $names);
        $this->assertContains('Cabang Surabaya', $names);
        $this->assertNotContains('Gedung A Audit', $names);
        $this->assertNotContains('Parkiran Basement', $names);
    }

    public function test_admin_locations_endpoint_returns_all_locations_including_proposed(): void
    {
        Location::create(['name' => 'Kantor Pusat', 'code' => 'KP', 'is_active' => true]);
        Location::create(['name' => 'Parkiran Basement', 'code' => 'UMUM-PKB', 'is_active' => false]);

        $admin = $this->createUser('admin');
        $token = $admin->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/admin/locations');

        $response->assertStatus(200);
        $data = $response->json('data');

        // Admin melihat semua (aktif maupun usulan)
        $this->assertCount(2, $data);
        $codes = collect($data)->pluck('code')->all();
        $this->assertContains('KP', $codes);
        $this->assertContains('UMUM-PKB', $codes);
    }

    public function test_locations_endpoint_can_filter_only_valid_assignment_units_excluding_physical_facilities(): void
    {
        // 1. Unit Penugasan Resmi (Divisi & Cabang)
        Location::create(['name' => 'Divisi TI', 'code' => 'RG-TI', 'is_active' => true]);
        Location::create(['name' => 'Divisi Treasury', 'code' => 'RG-TRS', 'is_active' => true]);
        Location::create(['name' => 'KCU Palu', 'code' => 'CAB-PLU-KCU', 'is_active' => true]);
        Location::create(['name' => 'Cabang Donggala', 'code' => 'CAB-DGL', 'is_active' => true]);

        // 2. Fasilitas / Lokasi Fisik Aset (Bukan unit penugasan)
        Location::create(['name' => 'Toilet', 'code' => 'UMUM-TOILET', 'is_active' => true]);
        Location::create(['name' => 'Parkiran Basement', 'code' => 'UMUM-PKB', 'is_active' => true]);
        Location::create(['name' => 'Lobby', 'code' => 'UMUM-LOBBY', 'is_active' => true]);
        Location::create(['name' => 'Lantai 1', 'code' => 'LT-1', 'is_active' => true]);
        Location::create(['name' => 'Lantai 2', 'code' => 'LT-2', 'is_active' => true]);
        Location::create(['name' => 'Ruang Tunggu Nasabah', 'code' => 'UMUM-TUNGGU', 'is_active' => true]);
        Location::create(['name' => 'Pantry', 'code' => 'UMUM-PANTRY', 'is_active' => true]);

        $user = $this->createUser('pemohon');
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/locations?assignment_only=1');

        $response->assertStatus(200);
        $data = $response->json('data');

        // Pastikan hanya 4 unit penugasan yang lolos
        $this->assertCount(4, $data);
        $names = collect($data)->pluck('name')->all();

        // Verifikasi divisi & cabang ADA
        $this->assertContains('Divisi TI', $names);
        $this->assertContains('Divisi Treasury', $names);
        $this->assertContains('KCU Palu', $names);
        $this->assertContains('Cabang Donggala', $names);

        // Verifikasi fasilitas fisik aset TIDAK MUNCUL
        $this->assertNotContains('Toilet', $names);
        $this->assertNotContains('Parkiran Basement', $names);
        $this->assertNotContains('Lobby', $names);
        $this->assertNotContains('Lantai 1', $names);
        $this->assertNotContains('Lantai 2', $names);
        $this->assertNotContains('Ruang Tunggu Nasabah', $names);
        $this->assertNotContains('Pantry', $names);
    }
}
