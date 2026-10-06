<?php

namespace Tests\Feature\Auth;

use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LoginTest extends TestCase
{
    use RefreshDatabase;

    private function createRole(string $name): Role
    {
        return Role::firstOrCreate(['name' => $name]);
    }

    public function test_user_can_login_with_valid_credentials(): void
    {
        $role = $this->createRole('admin');

        $user = User::factory()->create([
            'email' => 'admin@mutasiku.test',
            'password' => 'password',
            'role_id' => $role->id,
            'nip' => '100001',
            'is_active' => true,
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin@mutasiku.test',
            'password' => 'password',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'status' => 'success',
                'message' => 'Login berhasil.',
                'role' => 'admin',
                'user' => [
                    'id' => $user->id,
                    'email' => 'admin@mutasiku.test',
                    'nip' => '100001',
                    'role' => 'admin',
                    'is_active' => true,
                ],
                'data' => [
                    'role' => 'admin',
                    'token_type' => 'Bearer',
                    'user' => [
                        'id' => $user->id,
                        'email' => 'admin@mutasiku.test',
                        'role' => 'admin',
                    ],
                ],
            ]);

        $this->assertNotEmpty($response->json('token'));
        $this->assertNotEmpty($response->json('data.token'));

        // Assert the generated token works with Sanctum authentication
        $token = $response->json('token');
        $authResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/user');

        $authResponse->assertStatus(200)
            ->assertJson(['id' => $user->id, 'email' => $user->email]);
    }

    public function test_login_returns_correct_role_for_all_five_roles(): void
    {
        $roles = [
            'admin',
            'pemohon',
            'operator',
            'bagian_aset',
            'pemimpin_divisi',
        ];

        foreach ($roles as $index => $roleName) {
            $role = $this->createRole($roleName);

            $user = User::factory()->create([
                'email' => "{$roleName}@mutasiku.test",
                'password' => 'password123',
                'role_id' => $role->id,
                'nip' => (string) (200000 + $index),
                'is_active' => true,
            ]);

            $response = $this->postJson('/api/v1/auth/login', [
                'email' => "{$roleName}@mutasiku.test",
                'password' => 'password123',
            ]);

            $response->assertStatus(200)
                ->assertJson([
                    'success' => true,
                    'role' => $roleName,
                    'user' => [
                        'email' => "{$roleName}@mutasiku.test",
                        'role' => $roleName,
                    ],
                ]);
        }
    }

    public function test_login_fails_with_invalid_password(): void
    {
        $role = $this->createRole('pemohon');

        User::factory()->create([
            'email' => 'pemohon@mutasiku.test',
            'password' => 'password',
            'role_id' => $role->id,
            'is_active' => true,
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'pemohon@mutasiku.test',
            'password' => 'wrong-password',
        ]);

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'status' => 'error',
                'message' => 'Email atau password salah.',
            ]);
    }

    public function test_login_fails_with_nonexistent_email(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'nonexistent@mutasiku.test',
            'password' => 'password',
        ]);

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'status' => 'error',
                'message' => 'Email atau password salah.',
            ]);
    }

    public function test_login_validation_fails_when_fields_are_missing(): void
    {
        $response = $this->postJson('/api/v1/auth/login', []);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'status' => 'error',
                'message' => 'Validasi gagal.',
            ])
            ->assertJsonValidationErrors(['email', 'password']);
    }

    public function test_login_validation_fails_with_invalid_email_format(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'not-an-email',
            'password' => 'password',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_inactive_user_cannot_login(): void
    {
        $role = $this->createRole('pemohon');

        User::factory()->create([
            'email' => 'inactive@mutasiku.test',
            'password' => 'password',
            'role_id' => $role->id,
            'is_active' => false,
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'inactive@mutasiku.test',
            'password' => 'password',
        ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'status' => 'error',
                'message' => 'Akun Anda dinonaktifkan. Silakan hubungi Administrator.',
            ]);
    }

    public function test_login_is_throttled_after_five_failed_attempts(): void
    {
        $role = $this->createRole('pemohon');
        $user = User::factory()->create([
            'email' => 'throttled@mutasiku.test',
            'password' => 'secret123',
            'role_id' => $role->id,
            'is_active' => true,
        ]);

        // 5 percobaan pertama gagal dengan 401
        for ($i = 1; $i <= 5; $i++) {
            $response = $this->postJson('/api/v1/auth/login', [
                'email' => $user->email,
                'password' => 'wrong-pass',
            ]);
            $response->assertStatus(401)
                ->assertJson([
                    'success' => false,
                    'status' => 'error',
                    'message' => 'Email atau password salah.',
                ]);
        }

        // Percobaan ke-6 harus di-throttle dengan HTTP 429
        $throttledResponse = $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'wrong-pass',
        ]);

        $throttledResponse->assertStatus(429)
            ->assertJson([
                'success' => false,
                'status' => 'error',
            ])
            ->assertJsonStructure([
                'success',
                'status',
                'message',
                'retry_after',
            ]);

        $this->assertGreaterThan(0, $throttledResponse->json('retry_after'));
        $this->assertStringContainsString('Terlalu banyak percobaan login', $throttledResponse->json('message'));
        $this->assertNotEmpty($throttledResponse->headers->get('Retry-After'));
    }

    public function test_successful_login_clears_rate_limiter_attempts(): void
    {
        $role = $this->createRole('pemohon');
        $user = User::factory()->create([
            'email' => 'reset_attempt@mutasiku.test',
            'password' => 'secret123',
            'role_id' => $role->id,
            'is_active' => true,
        ]);

        // 3 kali gagal
        for ($i = 1; $i <= 3; $i++) {
            $this->postJson('/api/v1/auth/login', [
                'email' => $user->email,
                'password' => 'wrong-pass',
            ])->assertStatus(401);
        }

        // Login sukses harus mereset counter
        $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'secret123',
        ])->assertStatus(200);

        // Setelah reset, percobaan gagal ke-4 seharusnya tidak memicu throttle
        // melainkan hanya mengembalikan 401 karena counter direset ke 1
        $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'wrong-pass',
        ])->assertStatus(401);
    }

    public function test_rate_limiter_is_scoped_by_email_and_ip(): void
    {
        $role = $this->createRole('pemohon');
        $userA = User::factory()->create([
            'email' => 'user_a@mutasiku.test',
            'password' => 'secretA',
            'role_id' => $role->id,
            'is_active' => true,
        ]);

        $userB = User::factory()->create([
            'email' => 'user_b@mutasiku.test',
            'password' => 'secretB',
            'role_id' => $role->id,
            'is_active' => true,
        ]);

        // User A gagal 5 kali berturut-turut dari IP default
        for ($i = 1; $i <= 5; $i++) {
            $this->postJson('/api/v1/auth/login', [
                'email' => $userA->email,
                'password' => 'wrong',
            ])->assertStatus(401);
        }

        // User A sekarang terkunci
        $this->postJson('/api/v1/auth/login', [
            'email' => $userA->email,
            'password' => 'wrong',
        ])->assertStatus(429);

        // User B dari IP yang sama TIDAK terpengaruh dan tetap bisa login sukses
        $this->postJson('/api/v1/auth/login', [
            'email' => $userB->email,
            'password' => 'secretB',
        ])->assertStatus(200);

        // User A jika mencoba dari IP berbeda tidak terpengaruh limit IP lama
        $this->withServerVariables(['REMOTE_ADDR' => '192.168.10.50'])
            ->postJson('/api/v1/auth/login', [
                'email' => $userA->email,
                'password' => 'secretA',
            ])->assertStatus(200);
    }
}
