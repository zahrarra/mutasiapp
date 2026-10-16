<?php

namespace Tests\Feature\Admin;

use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AdminUserLoginTest extends TestCase
{
    use RefreshDatabase;

    public function test_newly_created_user_by_admin_can_login_and_requires_password_change(): void
    {
        $adminRole = Role::firstOrCreate(['name' => 'admin']);
        $pemohonRole = Role::firstOrCreate(['name' => 'pemohon']);

        $admin = User::factory()->create([
            'role_id' => $adminRole->id,
            'is_active' => true,
        ]);
        $adminToken = $admin->createToken('admin')->plainTextToken;

        $emailInput = 'userbaru@mutasiku.test';
        $passwordInput = 'secret123';

        // 1. Admin creates new user
        $createResponse = $this->withHeader('Authorization', 'Bearer ' . $adminToken)
            ->postJson('/api/v1/admin/users', [
                'name' => 'User Baru MutasiKu',
                'email' => $emailInput,
                'password' => $passwordInput,
                'role_id' => $pemohonRole->id,
                'nip' => '1234567890',
                'is_active' => true,
            ]);

        $createResponse->assertStatus(201)
            ->assertJsonPath('data.must_change_password', true);

        // 2. Verify controlled password match in DB without logging/leaking password
        $userInDb = User::where('email', $emailInput)->first();
        $this->assertNotNull($userInDb);
        $this->assertTrue(Hash::check($passwordInput, $userInDb->password));
        $this->assertTrue($userInDb->must_change_password);

        $this->app['auth']->forgetGuards();
        $this->flushSession();

        // 3. New user attempts login (with case and spacing tolerance)
        $loginResponse = $this->postJson('/api/v1/auth/login', [
            'email' => '  UserBaru@mutasiku.test ',
            'password' => $passwordInput,
        ]);

        $loginResponse->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('must_change_password', true);

        $userToken = $loginResponse->json('token');
        $this->assertNotEmpty($userToken);

        // 4. User changes password upon first login
        $newPassword = 'newPassword456';
        $changePasswordResponse = $this->withHeader('Authorization', 'Bearer ' . $userToken)
            ->postJson('/api/v1/auth/change-password', [
                'current_password' => $passwordInput,
                'password' => $newPassword,
                'password_confirmation' => $newPassword,
            ]);

        $changePasswordResponse->assertStatus(200)
            ->assertJsonPath('success', true);

        // 5. User can login with new password and must_change_password is now false
        $this->app['auth']->forgetGuards();
        $this->flushSession();

        $secondLoginResponse = $this->postJson('/api/v1/auth/login', [
            'email' => $emailInput,
            'password' => $newPassword,
        ]);

        $secondLoginResponse->assertStatus(200)
            ->assertJsonPath('must_change_password', false);
    }
}
