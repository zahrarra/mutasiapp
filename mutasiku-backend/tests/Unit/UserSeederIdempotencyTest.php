<?php

namespace Tests\Unit;

use App\Models\Role;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Database\Seeders\RoleSeeder;
use Database\Seeders\UserSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class UserSeederIdempotencyTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_seeder_creates_sample_users_with_unique_nip_and_email(): void
    {
        $this->seed(RoleSeeder::class);
        $this->seed(UserSeeder::class);

        $users = User::all();
        $this->assertGreaterThanOrEqual(7, $users->count());

        // Pastikan tidak ada duplikasi NIP
        $nips = $users->pluck('nip')->filter();
        $this->assertEquals($nips->count(), $nips->unique()->count(), 'Semua NIP pengguna harus unik.');

        // Pastikan tidak ada duplikasi email
        $emails = $users->pluck('email')->filter();
        $this->assertEquals($emails->count(), $emails->unique()->count(), 'Semua email pengguna harus unik.');
    }

    public function test_running_user_seeder_twice_is_idempotent_and_causes_no_errors(): void
    {
        $this->seed(RoleSeeder::class);

        // Eksekusi seeder pertama kali
        $this->seed(UserSeeder::class);
        $firstCount = User::count();

        // Eksekusi seeder kedua kali
        $this->seed(UserSeeder::class);
        $secondCount = User::count();

        $this->assertEquals($firstCount, $secondCount, 'Menjalankan UserSeeder dua kali tidak boleh menambah jumlah pengguna.');

        // Eksekusi DatabaseSeeder secara utuh dua kali
        $this->seed(DatabaseSeeder::class);
        $this->seed(DatabaseSeeder::class);

        $finalCount = User::count();
        $this->assertEquals($firstCount, $finalCount, 'DatabaseSeeder harus sepenuhnya idempotent tanpa duplikasi.');
    }

    public function test_user_seeder_preserves_existing_user_data_without_overwriting(): void
    {
        $this->seed(RoleSeeder::class);
        $rolePemohon = Role::where('name', 'pemohon')->firstOrFail();

        // Buat user 100006 secara manual dengan nama dan password kustom
        $customUser = User::create([
            'name' => 'Budi Kustomized',
            'email' => 'budi.santoso@mutasiku.test',
            'nip' => '100006',
            'role_id' => $rolePemohon->id,
            'password' => 'secret_custom_password',
            'is_active' => true,
            'must_change_password' => false,
        ]);

        $customHash = $customUser->password;

        // Jalankan UserSeeder
        $this->seed(UserSeeder::class);

        $customUser->refresh();

        // Data tidak boleh ditimpa
        $this->assertEquals('Budi Kustomized', $customUser->name, 'Nama pengguna yang sudah ada tidak boleh ditimpa seeder.');
        $this->assertEquals($customHash, $customUser->password, 'Password pengguna yang sudah ada tidak boleh ditimpa seeder.');
        $this->assertFalse($customUser->must_change_password, 'Atribut must_change_password tidak boleh di-reset.');
    }

    public function test_user_seeder_does_not_fail_when_existing_user_has_same_nip_but_different_email(): void
    {
        $this->seed(RoleSeeder::class);
        $rolePemohon = Role::where('name', 'pemohon')->firstOrFail();

        // Buat user dengan NIP 100006 tetapi email berbeda dari seeder default
        User::create([
            'name' => 'Pegawai NIP 100006 Eksisting',
            'email' => 'pegawai.lama@mutasiku.test',
            'nip' => '100006',
            'role_id' => $rolePemohon->id,
            'password' => 'existing_password',
            'is_active' => true,
            'must_change_password' => false,
        ]);

        // Jalankan UserSeeder: tidak boleh melempar QueryException Duplicate Entry NIP 100006
        $this->seed(UserSeeder::class);

        $user = User::where('nip', '100006')->firstOrFail();
        $this->assertEquals('Pegawai NIP 100006 Eksisting', $user->name);
        $this->assertEquals('pegawai.lama@mutasiku.test', $user->email);
    }
}
