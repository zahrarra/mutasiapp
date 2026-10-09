<?php

namespace Tests\Feature\Auth;

use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class FirstLoginChangePasswordTest extends TestCase
{
    use RefreshDatabase;

    private function createRole(string $name): Role
    {
        return Role::firstOrCreate(['name' => $name]);
    }

    public function test_first_login_returns_must_change_password_true(): void
    {
        $role = $this->createRole('pemohon');

        $user = User::factory()->create([
            'email' => 'firstlogin@mutasiku.test',
            'password' => 'password',
            'role_id' => $role->id,
            'must_change_password' => true,
            'is_active' => true,
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'firstlogin@mutasiku.test',
            'password' => 'password',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'must_change_password' => true,
                'user' => [
                    'must_change_password' => true,
                ],
                'data' => [
                    'must_change_password' => true,
                ],
            ]);
    }

    public function test_unauthenticated_user_cannot_change_password(): void
    {
        $response = $this->postJson('/api/v1/auth/change-password', [
            'current_password' => 'password',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(401);
    }

    public function test_change_password_fails_if_current_password_is_incorrect(): void
    {
        $role = $this->createRole('pemohon');

        $user = User::factory()->create([
            'email' => 'testuser@mutasiku.test',
            'password' => Hash::make('password123'),
            'role_id' => $role->id,
            'must_change_password' => true,
        ]);

        $response = $this->actingAs($user)->postJson('/api/v1/auth/change-password', [
            'current_password' => 'wrongpassword',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'status' => 'error',
                'message' => 'Password lama tidak sesuai.',
            ])
            ->assertJsonValidationErrors(['current_password']);

        // Password in DB must not change
        $user->refresh();
        $this->assertTrue(Hash::check('password123', $user->password));
        $this->assertTrue($user->must_change_password);
    }

    public function test_change_password_fails_if_password_confirmation_does_not_match(): void
    {
        $role = $this->createRole('pemohon');

        $user = User::factory()->create([
            'password' => Hash::make('password123'),
            'role_id' => $role->id,
            'must_change_password' => true,
        ]);

        $response = $this->actingAs($user)->postJson('/api/v1/auth/change-password', [
            'current_password' => 'password123',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'DifferentPassword123!',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }

    public function test_change_password_fails_if_new_password_is_too_short(): void
    {
        $role = $this->createRole('pemohon');

        $user = User::factory()->create([
            'password' => Hash::make('password123'),
            'role_id' => $role->id,
            'must_change_password' => true,
        ]);

        $response = $this->actingAs($user)->postJson('/api/v1/auth/change-password', [
            'current_password' => 'password123',
            'password' => 'short',
            'password_confirmation' => 'short',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }

    public function test_change_password_fails_if_new_password_is_same_as_current(): void
    {
        $role = $this->createRole('pemohon');

        $user = User::factory()->create([
            'password' => Hash::make('password123'),
            'role_id' => $role->id,
            'must_change_password' => true,
        ]);

        $response = $this->actingAs($user)->postJson('/api/v1/auth/change-password', [
            'current_password' => 'password123',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }

    public function test_user_can_successfully_change_password_on_first_login_and_flag_becomes_false(): void
    {
        $role = $this->createRole('pemohon');

        $user = User::factory()->create([
            'email' => 'changeok@mutasiku.test',
            'password' => Hash::make('oldpassword'),
            'role_id' => $role->id,
            'must_change_password' => true,
        ]);

        $response = $this->actingAs($user)->postJson('/api/v1/auth/change-password', [
            'current_password' => 'oldpassword',
            'password' => 'NewSecretPassword2026!',
            'password_confirmation' => 'NewSecretPassword2026!',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'status' => 'success',
                'message' => 'Password berhasil diperbarui.',
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'must_change_password' => false,
                    ],
                ],
            ]);

        // DB state check
        $user->refresh();
        $this->assertFalse($user->must_change_password);
        $this->assertTrue(Hash::check('NewSecretPassword2026!', $user->password));
        $this->assertFalse(Hash::check('oldpassword', $user->password));

        // Subsequent login with old password fails
        $loginOld = $this->postJson('/api/v1/auth/login', [
            'email' => 'changeok@mutasiku.test',
            'password' => 'oldpassword',
        ]);
        $loginOld->assertStatus(401);

        // Subsequent login with new password succeeds and must_change_password is false
        $loginNew = $this->postJson('/api/v1/auth/login', [
            'email' => 'changeok@mutasiku.test',
            'password' => 'NewSecretPassword2026!',
        ]);
        $loginNew->assertStatus(200)
            ->assertJson([
                'success' => true,
                'must_change_password' => false,
                'user' => [
                    'must_change_password' => false,
                ],
                'data' => [
                    'must_change_password' => false,
                ],
            ]);
    }

    public function test_all_five_roles_seeded_have_must_change_password_true_and_can_change_password_successfully(): void
    {
        $this->seed(\Database\Seeders\RoleSeeder::class);
        $this->seed(\Database\Seeders\UserSeeder::class);

        $testAccounts = [
            'admin@mutasiku.test',
            'pemohon@mutasiku.test',
            'operator@mutasiku.test',
            'aset@mutasiku.test',
            'pemimpin@mutasiku.test',
        ];

        foreach ($testAccounts as $index => $email) {
            $this->app['auth']->forgetGuards();
            $this->flushSession();

            $user = User::where('email', $email)->first();
            $this->assertNotNull($user, "User {$email} must exist in seed.");
            $this->assertTrue($user->must_change_password, "User {$email} must have must_change_password = true.");

            // 1. Login with initial password returns must_change_password = true
            $loginRes = $this->postJson('/api/v1/auth/login', [
                'email' => $email,
                'password' => 'password',
            ]);
            $loginRes->assertOk()
                ->assertJson([
                    'success' => true,
                    'must_change_password' => true,
                    'data' => [
                        'must_change_password' => true,
                    ],
                ]);

            $token = $loginRes->json('token');
            $newPassword = "UpdatedSecurePass{$index}#2026";

            // 2. Change password via Sanctum endpoint
            $changeRes = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson('/api/v1/auth/change-password', [
                    'current_password' => 'password',
                    'password' => $newPassword,
                    'password_confirmation' => $newPassword,
                ]);

            $changeRes->assertOk()
                ->assertJson([
                    'success' => true,
                    'message' => 'Password berhasil diperbarui.',
                    'data' => [
                        'user' => [
                            'must_change_password' => false,
                        ],
                    ],
                ]);

            // 3. User in database must have must_change_password = false
            $user->refresh();
            $this->assertFalse($user->must_change_password);
            $this->assertTrue(Hash::check($newPassword, $user->password));

            // 4. Old password rejected
            $loginOld = $this->postJson('/api/v1/auth/login', [
                'email' => $email,
                'password' => 'password',
            ]);
            $loginOld->assertStatus(401);

            // 5. Subsequent login with new password succeeds and must_change_password is false
            $loginNew = $this->postJson('/api/v1/auth/login', [
                'email' => $email,
                'password' => $newPassword,
            ]);
            $loginNew->assertOk()
                ->assertJson([
                    'success' => true,
                    'must_change_password' => false,
                    'data' => [
                        'must_change_password' => false,
                    ],
                ]);
        }
    }
}
