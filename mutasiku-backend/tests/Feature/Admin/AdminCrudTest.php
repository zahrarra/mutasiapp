<?php

namespace Tests\Feature\Admin;

use App\Models\Asset;
use App\Models\AssetCategory;
use App\Models\Location;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminCrudTest extends TestCase
{
    use RefreshDatabase;

    private function createRole(string $name): Role
    {
        return Role::firstOrCreate(['name' => $name]);
    }

    private function createUser(string $roleName = 'admin', array $attributes = []): User
    {
        $role = $this->createRole($roleName);

        return User::factory()->create(array_merge([
            'role_id' => $role->id,
            'is_active' => true,
        ], $attributes));
    }

    private function createLocation(string $name = 'Kantor Pusat', string $code = 'KP'): Location
    {
        return Location::firstOrCreate(
            ['code' => $code],
            ['name' => $name, 'is_active' => true]
        );
    }

    private function createCategory(string $name = 'Aset Komputer', string $code = 'KOMP'): AssetCategory
    {
        return AssetCategory::firstOrCreate(
            ['code' => $code],
            ['name' => $name]
        );
    }

    private function createAsset(User $pic, Location $location, AssetCategory $category, array $attributes = []): Asset
    {
        return Asset::create(array_merge([
            'asset_code' => 'AST-'.uniqid(),
            'name' => 'MacBook Pro M3',
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

    // ─── 1. USER CRUD TESTS ─────────────────────────────────────────────────

    public function test_admin_can_crud_user(): void
    {
        $admin = $this->createUser('admin');
        $token = $admin->createToken('admin')->plainTextToken;
        $operatorRole = $this->createRole('operator');

        // Create
        $createResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/users', [
                'name' => 'Budi Santoso',
                'email' => 'budi@mutasiku.test',
                'password' => 'secret123',
                'role_id' => $operatorRole->id,
                'nip' => '198501012010011001',
                'is_active' => true,
            ]);

        $createResponse->assertStatus(201)
            ->assertJsonPath('data.name', 'Budi Santoso')
            ->assertJsonPath('data.email', 'budi@mutasiku.test')
            ->assertJsonPath('data.role', 'operator');

        $userId = $createResponse->json('data.id');
        $this->assertDatabaseHas('users', ['id' => $userId, 'email' => 'budi@mutasiku.test']);

        // Index
        $indexResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/admin/users');

        $indexResponse->assertStatus(200)
            ->assertJsonStructure(['data' => [['id', 'name', 'email', 'role']]]);

        // Show
        $showResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson("/api/v1/admin/users/{$userId}");

        $showResponse->assertStatus(200)
            ->assertJsonPath('data.id', $userId)
            ->assertJsonPath('data.name', 'Budi Santoso');

        // Update
        $updateResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->putJson("/api/v1/admin/users/{$userId}", [
                'name' => 'Budi Santoso Updated',
                'is_active' => false,
            ]);

        $updateResponse->assertStatus(200)
            ->assertJsonPath('data.name', 'Budi Santoso Updated')
            ->assertJsonPath('data.is_active', false);

        // Delete
        $deleteResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->deleteJson("/api/v1/admin/users/{$userId}");

        $deleteResponse->assertStatus(200)
            ->assertJson(['success' => true]);

        $this->assertDatabaseMissing('users', ['id' => $userId]);
    }

    public function test_non_admin_cannot_access_user_crud(): void
    {
        $nonAdmin = $this->createUser('operator');
        $token = $nonAdmin->createToken('op')->plainTextToken;

        $targetUser = $this->createUser('pemohon');

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/admin/users')
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/users', ['name' => 'Hack'])
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson("/api/v1/admin/users/{$targetUser->id}")
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->putJson("/api/v1/admin/users/{$targetUser->id}", ['name' => 'Hack'])
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->deleteJson("/api/v1/admin/users/{$targetUser->id}")
            ->assertStatus(403);
    }

    // ─── 2. ROLE CRUD TESTS ─────────────────────────────────────────────────

    public function test_admin_can_crud_role(): void
    {
        $admin = $this->createUser('admin');
        $token = $admin->createToken('admin')->plainTextToken;

        // Create
        $createResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/roles', [
                'name' => 'auditor',
            ]);

        $createResponse->assertStatus(201)
            ->assertJsonPath('data.name', 'auditor');

        $roleId = $createResponse->json('data.id');

        // Index
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/admin/roles')
            ->assertStatus(200);

        // Show
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson("/api/v1/admin/roles/{$roleId}")
            ->assertStatus(200)
            ->assertJsonPath('data.name', 'auditor');

        // Update
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->putJson("/api/v1/admin/roles/{$roleId}", [
                'name' => 'internal_auditor',
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.name', 'internal_auditor');

        // Delete
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->deleteJson("/api/v1/admin/roles/{$roleId}")
            ->assertStatus(200);

        $this->assertDatabaseMissing('roles', ['id' => $roleId]);
    }

    public function test_non_admin_cannot_access_role_crud(): void
    {
        $nonAdmin = $this->createUser('pemohon');
        $token = $nonAdmin->createToken('pemohon')->plainTextToken;
        $role = $this->createRole('custom_role');

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/admin/roles')
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/roles', ['name' => 'new_role'])
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->putJson("/api/v1/admin/roles/{$role->id}", ['name' => 'edit'])
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->deleteJson("/api/v1/admin/roles/{$role->id}")
            ->assertStatus(403);
    }

    // ─── 3. LOCATION CRUD TESTS ─────────────────────────────────────────────

    public function test_admin_can_crud_location(): void
    {
        $admin = $this->createUser('admin');
        $token = $admin->createToken('admin')->plainTextToken;

        // Create
        $createResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/locations', [
                'name' => 'Gedung Arsip',
                'code' => 'GA-01',
                'is_active' => true,
            ]);

        $createResponse->assertStatus(201)
            ->assertJsonPath('data.name', 'Gedung Arsip')
            ->assertJsonPath('data.code', 'GA-01');

        $locationId = $createResponse->json('data.id');

        // Index
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/admin/locations')
            ->assertStatus(200);

        // Show
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson("/api/v1/admin/locations/{$locationId}")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $locationId);

        // Update
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->putJson("/api/v1/admin/locations/{$locationId}", [
                'name' => 'Gedung Arsip Baru',
                'is_active' => false,
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.name', 'Gedung Arsip Baru')
            ->assertJsonPath('data.is_active', false);

        // Delete
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->deleteJson("/api/v1/admin/locations/{$locationId}")
            ->assertStatus(200);

        $this->assertDatabaseMissing('locations', ['id' => $locationId]);
    }

    public function test_non_admin_cannot_access_location_crud(): void
    {
        $nonAdmin = $this->createUser('bagian_aset');
        $token = $nonAdmin->createToken('ba')->plainTextToken;
        $location = $this->createLocation('Kantor Cabang', 'KC');

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/admin/locations')
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/locations', ['name' => 'Lokasi Baru'])
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->putJson("/api/v1/admin/locations/{$location->id}", ['name' => 'Ganti'])
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->deleteJson("/api/v1/admin/locations/{$location->id}")
            ->assertStatus(403);
    }

    // ─── 4. ASSET CATEGORY CRUD TESTS ───────────────────────────────────────

    public function test_admin_can_crud_asset_category(): void
    {
        $admin = $this->createUser('admin');
        $token = $admin->createToken('admin')->plainTextToken;

        // Create
        $createResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/asset-categories', [
                'name' => 'Kendaraan Operasional',
                'code' => 'KNDR',
            ]);

        $createResponse->assertStatus(201)
            ->assertJsonPath('data.name', 'Kendaraan Operasional')
            ->assertJsonPath('data.code', 'KNDR');

        $categoryId = $createResponse->json('data.id');

        // Index
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/admin/asset-categories')
            ->assertStatus(200);

        // Show
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson("/api/v1/admin/asset-categories/{$categoryId}")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $categoryId);

        // Update
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->putJson("/api/v1/admin/asset-categories/{$categoryId}", [
                'name' => 'Kendaraan Dinas',
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.name', 'Kendaraan Dinas');

        // Delete
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->deleteJson("/api/v1/admin/asset-categories/{$categoryId}")
            ->assertStatus(200);

        $this->assertDatabaseMissing('asset_categories', ['id' => $categoryId]);
    }

    public function test_non_admin_cannot_access_asset_category_crud(): void
    {
        $nonAdmin = $this->createUser('pemimpin_divisi');
        $token = $nonAdmin->createToken('pd')->plainTextToken;
        $category = $this->createCategory('Elektronik', 'ELK');

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/admin/asset-categories')
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/asset-categories', ['name' => 'Kategori Baru', 'code' => 'NEW'])
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->putJson("/api/v1/admin/asset-categories/{$category->id}", ['name' => 'Ganti'])
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->deleteJson("/api/v1/admin/asset-categories/{$category->id}")
            ->assertStatus(403);
    }

    // ─── 5. ASSET CRUD TESTS ────────────────────────────────────────────────

    public function test_admin_can_crud_asset(): void
    {
        $admin = $this->createUser('admin');
        $token = $admin->createToken('admin')->plainTextToken;
        $pic = $this->createUser('pemohon');
        $location = $this->createLocation('Gedung Utama', 'GU');
        $category = $this->createCategory('Aset TI', 'TI-01');

        // Create
        $createResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/assets', [
                'asset_code' => 'AST-ADM-001',
                'name' => 'Laptop Dell XPS 15',
                'asset_category_id' => $category->id,
                'location_id' => $location->id,
                'pic_id' => $pic->id,
                'condition' => 'Baik',
                'serial_number' => 'SN-DELL-001',
                'acquisition_year' => 2024,
                'usage_year' => 2024,
                'is_active' => true,
            ]);

        $createResponse->assertStatus(201)
            ->assertJsonPath('data.asset_code', 'AST-ADM-001')
            ->assertJsonPath('data.name', 'Laptop Dell XPS 15')
            ->assertJsonPath('data.pic.id', $pic->id);

        $assetId = $createResponse->json('data.id');

        // Index
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/admin/assets')
            ->assertStatus(200);

        // Show
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson("/api/v1/admin/assets/{$assetId}")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $assetId)
            ->assertJsonPath('data.asset_code', 'AST-ADM-001');

        // Update
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->putJson("/api/v1/admin/assets/{$assetId}", [
                'name' => 'Laptop Dell XPS 15 (Upgraded)',
                'condition' => 'Sangat Baik',
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.name', 'Laptop Dell XPS 15 (Upgraded)')
            ->assertJsonPath('data.condition', 'Sangat Baik');

        // Delete
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->deleteJson("/api/v1/admin/assets/{$assetId}")
            ->assertStatus(200);

        $this->assertDatabaseMissing('assets', ['id' => $assetId]);
    }

    public function test_non_admin_cannot_access_asset_crud(): void
    {
        $nonAdmin = $this->createUser('operator');
        $token = $nonAdmin->createToken('op')->plainTextToken;
        $pic = $this->createUser('pemohon');
        $location = $this->createLocation();
        $category = $this->createCategory();
        $asset = $this->createAsset($pic, $location, $category);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/admin/assets')
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/assets', ['name' => 'Aset Baru'])
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson("/api/v1/admin/assets/{$asset->id}")
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->putJson("/api/v1/admin/assets/{$asset->id}", ['name' => 'Ganti'])
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->deleteJson("/api/v1/admin/assets/{$asset->id}")
            ->assertStatus(403);
    }

    // ─── 6. VALIDATION & SECURITY TESTS ─────────────────────────────────────

    public function test_validation_works_for_all_admin_endpoints(): void
    {
        $admin = $this->createUser('admin');
        $token = $admin->createToken('admin')->plainTextToken;

        // User validation
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/users', [
                'name' => '',
                'email' => 'bukan-email',
                'password' => '123',
                'role_id' => 99999,
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['name', 'email', 'password', 'role_id']);

        // Role validation (duplicate name)
        $this->createRole('duplikat_role');
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/roles', ['name' => 'duplikat_role'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['name']);

        // Location validation
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/locations', ['name' => ''])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['name']);

        // Category validation
        $this->createCategory('Kat 1', 'KAT-01');
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/asset-categories', ['name' => '', 'code' => 'KAT-01'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['name', 'code']);

        // Asset validation
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/assets', [
                'asset_code' => '',
                'name' => '',
                'asset_category_id' => 99999,
                'location_id' => 99999,
                'pic_id' => 99999,
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['asset_code', 'name', 'asset_category_id', 'location_id', 'pic_id']);
    }

    public function test_password_is_never_returned_in_user_responses(): void
    {
        $admin = $this->createUser('admin');
        $token = $admin->createToken('admin')->plainTextToken;
        $operatorRole = $this->createRole('operator');

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/admin/users', [
                'name' => 'User Rahasia',
                'email' => 'rahasia@mutasiku.test',
                'password' => 'passwordSangatRahasia123',
                'role_id' => $operatorRole->id,
            ]);

        $response->assertStatus(201);
        $this->assertArrayNotHasKey('password', $response->json('data'));

        $userId = $response->json('data.id');

        $showResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson("/api/v1/admin/users/{$userId}");

        $showResponse->assertStatus(200);
        $this->assertArrayNotHasKey('password', $showResponse->json('data'));

        $indexResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/admin/users');

        $indexResponse->assertStatus(200);
        foreach ($indexResponse->json('data') as $u) {
            $this->assertArrayNotHasKey('password', $u);
        }
    }

    public function test_delete_violating_foreign_key_fails_safely_and_returns_409(): void
    {
        $admin = $this->createUser('admin');
        $token = $admin->createToken('admin')->plainTextToken;

        $pic = $this->createUser('pemohon');
        $location = $this->createLocation('Gedung Terkait', 'GT');
        $category = $this->createCategory('Kategori Terkait', 'KT');
        $asset = $this->createAsset($pic, $location, $category);

        // 1. Coba hapus User yang menjadi PIC suatu aset (FK restrictOnDelete)
        $deleteUserResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->deleteJson("/api/v1/admin/users/{$pic->id}");

        $deleteUserResponse->assertStatus(409)
            ->assertJson(['success' => false]);
        $this->assertDatabaseHas('users', ['id' => $pic->id]);

        // 2. Coba hapus Location yang sedang digunakan oleh aset (FK restrictOnDelete)
        $deleteLocationResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->deleteJson("/api/v1/admin/locations/{$location->id}");

        $deleteLocationResponse->assertStatus(409)
            ->assertJson(['success' => false]);
        $this->assertDatabaseHas('locations', ['id' => $location->id]);

        // 3. Coba hapus AssetCategory yang sedang digunakan oleh aset (FK restrictOnDelete)
        $deleteCategoryResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->deleteJson("/api/v1/admin/asset-categories/{$category->id}");

        $deleteCategoryResponse->assertStatus(409)
            ->assertJson(['success' => false]);
        $this->assertDatabaseHas('asset_categories', ['id' => $category->id]);

        // 4. Coba hapus Role yang masih digunakan oleh user
        $deleteRoleResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->deleteJson("/api/v1/admin/roles/{$pic->role_id}");

        $deleteRoleResponse->assertStatus(409)
            ->assertJson(['success' => false]);
        $this->assertDatabaseHas('roles', ['id' => $pic->role_id]);
    }
}
