<?php

namespace Tests\Feature\User;

use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserDepartmentPersistenceTest extends TestCase
{
    use RefreshDatabase;

    private function createRole(string $name): Role
    {
        return Role::create([
            'name' => $name,
            'display_name' => ucfirst($name),
            'description' => 'Testing role',
        ]);
    }

    private function createAdmin(): User
    {
        $role = Role::where('name', 'admin')->first() ?? $this->createRole('admin');

        return User::create([
            'name' => 'System Admin',
            'email' => 'admin@mutasiku.test',
            'password' => bcrypt('password123'),
            'role_id' => $role->id,
            'department' => 'Divisi TI',
            'is_active' => true,
        ]);
    }

    public function test_admin_can_create_user_with_department_and_persisted_to_db(): void
    {
        $admin = $this->createAdmin();
        $token = $admin->createToken('test')->plainTextToken;
        $operatorRole = $this->createRole('operator');

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/admin/users', [
                'name' => 'Budi Santoso',
                'email' => 'budi.ops@mutasiku.test',
                'password' => 'secret123',
                'role_id' => $operatorRole->id,
                'department' => 'Divisi Operasional',
                'nip' => '198501012010011001',
                'is_active' => true,
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.name', 'Budi Santoso')
            ->assertJsonPath('data.department', 'Divisi Operasional');

        $userId = $response->json('data.id');

        // Buktikan tersimpan permanen di database
        $this->assertDatabaseHas('users', [
            'id' => $userId,
            'department' => 'Divisi Operasional',
        ]);
    }

    public function test_admin_can_update_user_department_and_persisted_to_db(): void
    {
        $admin = $this->createAdmin();
        $token = $admin->createToken('test')->plainTextToken;
        $operatorRole = $this->createRole('operator');

        $user = User::create([
            'name' => 'Siti Rohmah',
            'email' => 'siti@mutasiku.test',
            'password' => bcrypt('password123'),
            'role_id' => $operatorRole->id,
            'department' => 'Divisi SDM',
            'is_active' => true,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->putJson("/api/v1/admin/users/{$user->id}", [
                'department' => 'Divisi Kredit',
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.department', 'Divisi Kredit');

        // Buktikan update tersimpan permanen di database
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'department' => 'Divisi Kredit',
        ]);

        // Buktikan pembacaan ulang via GET show
        $showResponse = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson("/api/v1/admin/users/{$user->id}");

        $showResponse->assertStatus(200)
            ->assertJsonPath('data.department', 'Divisi Kredit');
    }

    public function test_backward_compatibility_with_legacy_users_having_null_department(): void
    {
        $admin = $this->createAdmin();
        $token = $admin->createToken('test')->plainTextToken;
        $pemohonRole = $this->createRole('pemohon');

        // User lama tanpa department (null)
        $legacyUser = User::create([
            'name' => 'User Lama Tanpa Divisi',
            'email' => 'legacy@mutasiku.test',
            'password' => bcrypt('password123'),
            'role_id' => $pemohonRole->id,
            'department' => null,
            'is_active' => true,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson("/api/v1/admin/users/{$legacyUser->id}");

        $response->assertStatus(200)
            ->assertJsonPath('data.id', $legacyUser->id)
            ->assertJsonPath('data.department', null);
    }

    public function test_login_returns_user_department(): void
    {
        $role = $this->createRole('pemohon');
        $user = User::create([
            'name' => 'Rina Pemohon',
            'email' => 'rina@mutasiku.test',
            'password' => bcrypt('password123'),
            'role_id' => $role->id,
            'department' => 'Divisi Umum dan Aset',
            'is_active' => true,
        ]);

        $response = $this->postJson('/api/v1/login', [
            'email' => 'rina@mutasiku.test',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('user.department', 'Divisi Umum dan Aset');
    }
}
