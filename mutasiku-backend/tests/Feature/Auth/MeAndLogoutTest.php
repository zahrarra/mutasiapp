<?php

namespace Tests\Feature\Auth;

use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MeAndLogoutTest extends TestCase
{
    use RefreshDatabase;

    private function createRole(string $name): Role
    {
        return Role::firstOrCreate(['name' => $name]);
    }

    public function test_get_me_with_valid_token_returns_200_and_user_profile(): void
    {
        $role = $this->createRole('operator');

        $user = User::factory()->create([
            'email' => 'operator@mutasiku.test',
            'role_id' => $role->id,
            'nip' => '100003',
            'is_active' => true,
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/auth/me');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Data profil berhasil diambil.',
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'name' => $user->name,
                        'email' => 'operator@mutasiku.test',
                        'nip' => '100003',
                        'role' => 'operator',
                        'is_active' => true,
                    ],
                ],
            ]);
    }

    public function test_get_me_without_token_returns_401(): void
    {
        $response = $this->getJson('/api/v1/auth/me');

        $response->assertStatus(401);
    }

    public function test_post_logout_with_valid_token_returns_200(): void
    {
        $role = $this->createRole('pemohon');

        $user = User::factory()->create([
            'email' => 'pemohon@mutasiku.test',
            'role_id' => $role->id,
            'is_active' => true,
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/auth/logout');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Logout berhasil.',
                'data' => null,
            ]);
    }

    public function test_token_cannot_be_used_after_logout(): void
    {
        $role = $this->createRole('bagian_aset');

        $user = User::factory()->create([
            'email' => 'aset@mutasiku.test',
            'role_id' => $role->id,
            'is_active' => true,
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        // Pastikan token bisa digunakan sebelum logout
        $beforeLogoutResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/auth/me');
        $beforeLogoutResponse->assertStatus(200);

        // Lakukan logout
        $logoutResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/auth/logout');
        $logoutResponse->assertStatus(200);

        $this->assertDatabaseCount('personal_access_tokens', 0);

        // Reset guard cache in test environment
        $this->app['auth']->forgetGuards();

        // Coba gunakan token yang sama setelah logout -> harus 401
        $afterLogoutResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/auth/me');
        $afterLogoutResponse->assertStatus(401);
    }

    public function test_post_logout_without_token_returns_401(): void
    {
        $response = $this->postJson('/api/v1/auth/logout');

        $response->assertStatus(401);
    }

    public function test_logout_only_revokes_current_token_and_leaves_other_tokens_active(): void
    {
        $role = $this->createRole('admin');

        $user = User::factory()->create([
            'email' => 'admin@mutasiku.test',
            'role_id' => $role->id,
            'is_active' => true,
        ]);

        $token1 = $user->createToken('device_1')->plainTextToken;
        $token2 = $user->createToken('device_2')->plainTextToken;

        $this->assertDatabaseCount('personal_access_tokens', 2);

        // Logout menggunakan token1
        $this->withHeader('Authorization', 'Bearer '.$token1)
            ->postJson('/api/v1/auth/logout')
            ->assertStatus(200);

        $this->assertDatabaseCount('personal_access_tokens', 1);

        // Reset guard cache in test environment
        $this->app['auth']->forgetGuards();

        // token1 harus sudah tidak berlaku (401)
        $this->withHeader('Authorization', 'Bearer '.$token1)
            ->getJson('/api/v1/auth/me')
            ->assertStatus(401);

        // Reset guard cache in test environment
        $this->app['auth']->forgetGuards();

        // token2 HARUS tetap berlaku (200)
        $this->withHeader('Authorization', 'Bearer '.$token2)
            ->getJson('/api/v1/auth/me')
            ->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'email' => 'admin@mutasiku.test',
                    ],
                ],
            ]);
    }
}
