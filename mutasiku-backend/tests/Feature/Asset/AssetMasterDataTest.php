<?php

namespace Tests\Feature\Asset;

use App\Models\Asset;
use App\Models\AssetCategory;
use App\Models\Location;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AssetMasterDataTest extends TestCase
{
    use RefreshDatabase;

    private function createRole(string $name): Role
    {
        return Role::firstOrCreate(['name' => $name]);
    }

    private function createUser(string $roleName, ?string $email = null): User
    {
        $role = $this->createRole($roleName);

        return User::factory()->create([
            'email' => $email ?? "{$roleName}_".uniqid().'@mutasiku.test',
            'role_id' => $role->id,
            'is_active' => true,
        ]);
    }

    private function createLocation(string $name = 'Kantor Pusat', string $code = 'KP'): Location
    {
        return Location::firstOrCreate(
            ['code' => $code],
            ['name' => $name, 'is_active' => true]
        );
    }

    private function createCategory(string $name = 'Aset TI', string $code = 'TI'): AssetCategory
    {
        return AssetCategory::firstOrCreate(
            ['code' => $code],
            ['name' => $name]
        );
    }

    private function createAsset(User $pic, array $attributes = []): Asset
    {
        $location = $this->createLocation();
        $category = $this->createCategory();

        return Asset::create(array_merge([
            'asset_code' => 'AST-'.uniqid(),
            'name' => 'Laptop Lenovo ThinkPad',
            'asset_category_id' => $category->id,
            'location_id' => $location->id,
            'pic_id' => $pic->id,
            'condition' => 'Baik',
            'serial_number' => 'SN-'.uniqid(),
            'acquisition_year' => 2024,
            'usage_year' => 2024,
            'is_active' => true,
        ], $attributes));
    }

    // ─── 1. Locations Test ──────────────────────────────────────────────────

    public function test_authenticated_user_can_get_locations_list(): void
    {
        $user = $this->createUser('pemohon');
        $token = $user->createToken('test')->plainTextToken;

        $loc1 = $this->createLocation('Gedung A', 'GA');
        $loc2 = $this->createLocation('Gedung B', 'GB');

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/locations');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Daftar lokasi berhasil diambil.',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    '*' => ['id', 'name', 'code', 'is_active', 'created_at', 'updated_at'],
                ],
            ]);

        $this->assertCount(2, $response->json('data'));
    }

    // ─── 2. Asset Categories Test ───────────────────────────────────────────

    public function test_authenticated_user_can_get_asset_categories_list(): void
    {
        $user = $this->createUser('operator');
        $token = $user->createToken('test')->plainTextToken;

        $cat1 = $this->createCategory('Aset TI', 'TI');
        $cat2 = $this->createCategory('Aset Umum', 'UM');

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/asset-categories');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Daftar kategori aset berhasil diambil.',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    '*' => ['id', 'name', 'code', 'created_at', 'updated_at'],
                ],
            ]);

        $this->assertCount(2, $response->json('data'));
    }

    // ─── 3. Assets List & Role Scoping Test ─────────────────────────────────

    public function test_authenticated_admin_or_asset_staff_can_view_all_assets(): void
    {
        $bagianAset = $this->createUser('bagian_aset');
        $token = $bagianAset->createToken('test')->plainTextToken;

        $user1 = $this->createUser('pemohon');
        $user2 = $this->createUser('pemohon');

        $this->createAsset($user1, ['name' => 'Aset User 1']);
        $this->createAsset($user2, ['name' => 'Aset User 2']);

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/assets');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Daftar aset berhasil diambil.',
            ]);

        $this->assertCount(2, $response->json('data'));
    }

    public function test_pemohon_with_mine_query_only_gets_their_own_assets(): void
    {
        $pemohon1 = $this->createUser('pemohon', 'pemohon1@mutasiku.test');
        $pemohon2 = $this->createUser('pemohon', 'pemohon2@mutasiku.test');

        $asset1 = $this->createAsset($pemohon1, ['name' => 'Laptop Pemohon 1']);
        $asset2 = $this->createAsset($pemohon2, ['name' => 'Laptop Pemohon 2']);

        $token1 = $pemohon1->createToken('test')->plainTextToken;

        // Pemohon 1 request dengan ?mine=true
        $response = $this->withHeader('Authorization', 'Bearer '.$token1)
            ->getJson('/api/v1/assets?mine=true');

        $response->assertStatus(200);

        // Hanya menerima asset1 milik pemohon1
        $data = $response->json('data');
        $this->assertCount(1, $data);
        $this->assertEquals($asset1->id, $data[0]['id']);
        $this->assertEquals($pemohon1->id, $data[0]['pic_id']);
    }

    public function test_client_cannot_override_scoping_with_arbitrary_pic_id_query(): void
    {
        $pemohon1 = $this->createUser('pemohon', 'pemohon1@mutasiku.test');
        $pemohon2 = $this->createUser('pemohon', 'pemohon2@mutasiku.test');

        $asset1 = $this->createAsset($pemohon1, ['name' => 'Laptop Pemohon 1']);
        $asset2 = $this->createAsset($pemohon2, ['name' => 'Laptop Pemohon 2']);

        $token1 = $pemohon1->createToken('test')->plainTextToken;

        // Pemohon 1 mencoba mengoper query ?mine=true&pic_id=pemohon2->id
        $response = $this->withHeader('Authorization', 'Bearer '.$token1)
            ->getJson('/api/v1/assets?mine=true&pic_id='.$pemohon2->id);

        $response->assertStatus(200);

        // Server tetap memaksa pic_id pemohon1 yang sedang login
        $data = $response->json('data');
        $this->assertCount(1, $data);
        $this->assertEquals($pemohon1->id, $data[0]['pic_id']);
    }

    // ─── 4. Asset Detail Test ───────────────────────────────────────────────

    public function test_asset_detail_succeeds_for_authorized_user(): void
    {
        $operator = $this->createUser('operator');
        $token = $operator->createToken('test')->plainTextToken;

        $pemohon = $this->createUser('pemohon');
        $asset = $this->createAsset($pemohon, [
            'name' => 'MacBook Pro M2',
            'serial_number' => 'MBP-2024-99',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/assets/'.$asset->id);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Detail aset berhasil diambil.',
                'data' => [
                    'id' => $asset->id,
                    'name' => 'MacBook Pro M2',
                    'serial_number' => 'MBP-2024-99',
                    'pic_id' => $pemohon->id,
                    'pic' => [
                        'id' => $pemohon->id,
                        'email' => $pemohon->email,
                    ],
                    'category' => [
                        'code' => 'TI',
                    ],
                    'location' => [
                        'code' => 'KP',
                    ],
                ],
            ]);
    }

    public function test_pemohon_can_view_detail_of_their_own_asset(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;

        $asset = $this->createAsset($pemohon, ['name' => 'Laptop Milik Sendiri']);

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/assets/'.$asset->id);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $asset->id,
                    'name' => 'Laptop Milik Sendiri',
                ],
            ]);
    }

    public function test_pemohon_cannot_view_detail_of_another_users_asset(): void
    {
        $pemohon1 = $this->createUser('pemohon');
        $pemohon2 = $this->createUser('pemohon');

        $token1 = $pemohon1->createToken('test')->plainTextToken;

        $assetMilikPemohon2 = $this->createAsset($pemohon2, ['name' => 'Laptop Milik Orang Lain']);

        $response = $this->withHeader('Authorization', 'Bearer '.$token1)
            ->getJson('/api/v1/assets/'.$assetMilikPemohon2->id);

        // Harus 403 Forbidden
        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Anda tidak memiliki hak akses untuk aset ini.',
            ]);
    }

    public function test_asset_detail_returns_404_when_not_found(): void
    {
        $user = $this->createUser('admin');
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/assets/99999');

        $response->assertStatus(404)
            ->assertJson([
                'success' => false,
                'message' => 'Aset tidak ditemukan.',
            ]);
    }

    // ─── 5. Asset History Test ──────────────────────────────────────────────

    public function test_asset_history_succeeds_for_authorized_user(): void
    {
        $bagianAset = $this->createUser('bagian_aset');
        $token = $bagianAset->createToken('test')->plainTextToken;

        $pemohon = $this->createUser('pemohon');
        $asset = $this->createAsset($pemohon);

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/assets/'.$asset->id.'/history');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Riwayat perubahan aset berhasil diambil.',
                'data' => [],
            ]);
    }

    public function test_pemohon_can_view_history_of_their_own_asset(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/assets/'.$asset->id.'/history');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Riwayat perubahan aset berhasil diambil.',
                'data' => [],
            ]);
    }

    public function test_pemohon_cannot_view_history_of_another_users_asset(): void
    {
        $pemohon1 = $this->createUser('pemohon');
        $pemohon2 = $this->createUser('pemohon');

        $token1 = $pemohon1->createToken('test')->plainTextToken;
        $assetMilikPemohon2 = $this->createAsset($pemohon2);

        $response = $this->withHeader('Authorization', 'Bearer '.$token1)
            ->getJson('/api/v1/assets/'.$assetMilikPemohon2->id.'/history');

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Anda tidak memiliki hak akses untuk riwayat aset ini.',
            ]);
    }

    public function test_asset_history_returns_404_when_asset_not_found(): void
    {
        $user = $this->createUser('admin');
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/assets/99999/history');

        $response->assertStatus(404)
            ->assertJson([
                'success' => false,
                'message' => 'Aset tidak ditemukan.',
            ]);
    }

    // ─── 6. Protected Endpoint Tests Without Token (401) ────────────────────

    public function test_unauthenticated_access_is_rejected_on_all_endpoints(): void
    {
        $this->getJson('/api/v1/locations')->assertStatus(401);
        $this->getJson('/api/v1/asset-categories')->assertStatus(401);
        $this->getJson('/api/v1/assets')->assertStatus(401);
        $this->getJson('/api/v1/assets/1')->assertStatus(401);
        $this->getJson('/api/v1/assets/1/history')->assertStatus(401);
    }
}
