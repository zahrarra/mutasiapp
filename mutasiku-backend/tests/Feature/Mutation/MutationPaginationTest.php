<?php

namespace Tests\Feature\Mutation;

use App\Models\Asset;
use App\Models\AssetCategory;
use App\Models\Location;
use App\Models\Mutation;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MutationPaginationTest extends TestCase
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

    private function createAsset(User $pic): Asset
    {
        $location = $this->createLocation();
        $category = $this->createCategory();

        return Asset::create([
            'asset_code' => 'AST-'.uniqid(),
            'name' => 'Laptop ThinkPad X1',
            'asset_category_id' => $category->id,
            'location_id' => $location->id,
            'pic_id' => $pic->id,
            'condition' => 'Baik',
            'serial_number' => 'SN-'.uniqid(),
            'acquisition_year' => 2024,
            'usage_year' => 2024,
            'is_active' => true,
        ]);
    }

    private function createMutation(User $applicant, string $status = 'diajukan'): Mutation
    {
        $asset = $this->createAsset($applicant);
        $loc1 = $this->createLocation('Gedung A', 'GA_'.uniqid());
        $loc2 = $this->createLocation('Gedung B', 'GB_'.uniqid());

        return Mutation::create([
            'ticket_number' => 'TI-2026-'.uniqid(),
            'asset_id' => $asset->id,
            'applicant_id' => $applicant->id,
            'origin_location_id' => $loc1->id,
            'destination_location_id' => $loc2->id,
            'current_pic_id' => $applicant->id,
            'target_pic_id' => $applicant->id,
            'is_asset_moves_with_applicant' => true,
            'reason' => 'Alasan mutasi',
            'sk_document' => 'documents/sk_sdm/sk.pdf',
            'status' => $status,
        ]);
    }

    public function test_default_pagination_returns_15_items_and_meta(): void
    {
        $admin = $this->createUser('admin');
        $pemohon = $this->createUser('pemohon');

        // Buat 20 mutasi
        for ($i = 0; $i < 20; $i++) {
            $this->createMutation($pemohon);
        }

        $token = $admin->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/mutations');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Daftar pengajuan mutasi berhasil diambil.',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data',
                'meta' => [
                    'current_page',
                    'last_page',
                    'per_page',
                    'total',
                ],
                'links' => [
                    'first',
                    'last',
                    'prev',
                    'next',
                ],
            ]);

        $data = $response->json('data');
        $this->assertIsArray($data);
        $this->assertCount(15, $data);

        $meta = $response->json('meta');
        $this->assertEquals(1, $meta['current_page']);
        $this->assertEquals(2, $meta['last_page']);
        $this->assertEquals(15, $meta['per_page']);
        $this->assertEquals(20, $meta['total']);

        $links = $response->json('links');
        $this->assertNull($links['prev']);
        $this->assertNotNull($links['next']);
    }

    public function test_custom_per_page_and_page_query(): void
    {
        $admin = $this->createUser('admin');
        $pemohon = $this->createUser('pemohon');

        for ($i = 0; $i < 20; $i++) {
            $this->createMutation($pemohon);
        }

        $token = $admin->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/mutations?per_page=5&page=2');

        $response->assertStatus(200);

        $data = $response->json('data');
        $this->assertCount(5, $data);

        $meta = $response->json('meta');
        $this->assertEquals(2, $meta['current_page']);
        $this->assertEquals(4, $meta['last_page']);
        $this->assertEquals(5, $meta['per_page']);
        $this->assertEquals(20, $meta['total']);

        $links = $response->json('links');
        $this->assertNotNull($links['prev']);
        $this->assertNotNull($links['next']);
    }

    public function test_pagination_caps_per_page_to_maximum_100(): void
    {
        $admin = $this->createUser('admin');
        $token = $admin->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/mutations?per_page=500');

        $response->assertStatus(200);
        $this->assertEquals(100, $response->json('meta.per_page'));
    }

    public function test_pagination_preserves_role_scoping_and_view(): void
    {
        $pemohon1 = $this->createUser('pemohon');
        $pemohon2 = $this->createUser('pemohon');

        // Buat 10 mutasi milik pemohon 1 dan 10 milik pemohon 2
        for ($i = 0; $i < 10; $i++) {
            $this->createMutation($pemohon1);
            $this->createMutation($pemohon2);
        }

        $tokenPemohon1 = $pemohon1->createToken('test')->plainTextToken;

        // Pemohon 1 hanya boleh melihat miliknya (total = 10)
        $response = $this->withHeader('Authorization', 'Bearer '.$tokenPemohon1)
            ->getJson('/api/v1/mutations?per_page=6');

        $response->assertStatus(200);
        $this->assertCount(6, $response->json('data'));
        $this->assertEquals(10, $response->json('meta.total'));
        $this->assertEquals(2, $response->json('meta.last_page'));

        foreach ($response->json('data') as $item) {
            $this->assertEquals($pemohon1->id, $item['applicant_id']);
        }
    }
}
