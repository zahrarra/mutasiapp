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
}
