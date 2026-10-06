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

class MutationSubmissionTest extends TestCase
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

    public function test_pemohon_can_submit_valid_mutation(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;

        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation('Gedung Cabang', 'GC');

        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Pindah tugas ke divisi baru',
            'sk_document' => 'SK-SDM-2026-001.pdf',
            'asset_moves_with_applicant' => true,
        ];

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/mutations', $payload);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Pengajuan mutasi berhasil dibuat.',
                'data' => [
                    'asset_id' => $asset->id,
                    'applicant_id' => $pemohon->id,
                    'origin_location_id' => $asset->location_id,
                    'destination_location_id' => $destLocation->id,
                    'current_pic_id' => $pemohon->id,
                    'target_pic_id' => $pemohon->id,
                    'status' => 'diajukan',
                    'reason' => 'Pindah tugas ke divisi baru',
                    'sk_document' => 'SK-SDM-2026-001.pdf',
                    'is_asset_moves_with_applicant' => true,
                ],
            ]);

        $this->assertDatabaseHas('mutations', [
            'asset_id' => $asset->id,
            'applicant_id' => $pemohon->id,
            'status' => 'diajukan',
            'origin_location_id' => $asset->location_id,
            'destination_location_id' => $destLocation->id,
            'target_pic_id' => $pemohon->id,
        ]);

        // Verifikasi aset asli di master data TIDAK berubah pada saat submission
        $assetFresh = $asset->fresh();
        $this->assertEquals($asset->location_id, $assetFresh->location_id);
        $this->assertEquals($pemohon->id, $assetFresh->pic_id);
    }

    public function test_asset_moves_with_applicant_true_automatically_assigns_auth_user_as_target_pic(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation('Gedung B', 'GB');

        $payload = [
            'asset_id' => $asset->id,
            'target_location_id' => $destLocation->id,
            'reason' => 'Mutasi kerja',
            'sk_sdm' => 'SK-SDM-002.pdf',
            'asset_moves_with_applicant' => true,
        ];

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/mutations', $payload);

        $response->assertStatus(201);
        $this->assertEquals($pemohon->id, $response->json('data.target_pic_id'));
    }

    public function test_client_target_pic_id_is_ignored_when_asset_moves_with_applicant(): void
    {
        $pemohon = $this->createUser('pemohon');
        $otherUser = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation('Gedung B', 'GB');

        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Mutasi kerja',
            'sk_document' => 'SK-SDM-003.pdf',
            'asset_moves_with_applicant' => true,
            'target_pic_id' => $otherUser->id, // Client mencoba memaksakan PIC lain
        ];

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/mutations', $payload);

        $response->assertStatus(201);
        // Server WAJIB mengabaikan target_pic_id dari client dan menetapkan user yang login
        $this->assertEquals($pemohon->id, $response->json('data.target_pic_id'));
        $this->assertNotEquals($otherUser->id, $response->json('data.target_pic_id'));
    }

    public function test_asset_moves_with_applicant_false_sets_target_pic_id_to_null(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation('Gedung B', 'GB');

        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Aset ditinggal di kantor lama',
            'sk_document' => 'SK-SDM-004.pdf',
            'asset_moves_with_applicant' => false,
        ];

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/mutations', $payload);

        $response->assertStatus(201);
        $this->assertNull($response->json('data.target_pic_id'));

        $this->assertDatabaseHas('mutations', [
            'asset_id' => $asset->id,
            'target_pic_id' => null,
            'is_asset_moves_with_applicant' => false,
        ]);
    }

    public function test_pemohon_cannot_choose_arbitrary_pic_when_asset_does_not_move_with_applicant(): void
    {
        $pemohon = $this->createUser('pemohon');
        $otherUser = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation('Gedung B', 'GB');

        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Aset ditinggalkan',
            'sk_document' => 'SK-SDM-005.pdf',
            'asset_moves_with_applicant' => false,
            'target_pic_id' => $otherUser->id, // Mencoba memilih PIC sembarangan
        ];

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/mutations', $payload);

        $response->assertStatus(201);
        // Server WAJIB menetapkan target_pic_id = null
        $this->assertNull($response->json('data.target_pic_id'));
    }

    public function test_submission_fails_when_asset_not_found(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $destLocation = $this->createLocation();

        $payload = [
            'asset_id' => 99999,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Pindah',
            'sk_document' => 'SK.pdf',
        ];

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/mutations', $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['asset_id']);
    }

    public function test_submission_fails_when_asset_is_not_held_by_applicant(): void
    {
        $pemohon1 = $this->createUser('pemohon');
        $pemohon2 = $this->createUser('pemohon');

        $token1 = $pemohon1->createToken('test')->plainTextToken;
        // Aset dipegang oleh pemohon2
        $assetMilikPemohon2 = $this->createAsset($pemohon2);
        $destLocation = $this->createLocation();

        $payload = [
            'asset_id' => $assetMilikPemohon2->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Mencoba mutasi aset orang lain',
            'sk_document' => 'SK.pdf',
        ];

        $response = $this->withHeader('Authorization', 'Bearer '.$token1)
            ->postJson('/api/v1/mutations', $payload);

        // Ditolak: Hanya pemegang aset saat ini yang dapat mengajukan mutasi
        $response->assertStatus(422)
            ->assertJsonValidationErrors(['asset_id']);
    }

    public function test_submission_fails_when_asset_already_has_active_mutation(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation();

        // Mutasi aktif pertama
        Mutation::create([
            'ticket_number' => 'TI-2026-0001',
            'asset_id' => $asset->id,
            'applicant_id' => $pemohon->id,
            'origin_location_id' => $asset->location_id,
            'destination_location_id' => $destLocation->id,
            'current_pic_id' => $pemohon->id,
            'target_pic_id' => $pemohon->id,
            'is_asset_moves_with_applicant' => true,
            'reason' => 'Mutasi 1',
            'sk_document' => 'SK1.pdf',
            'status' => 'diajukan', // Masih aktif
        ]);

        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Mutasi kedua padahal mutasi pertama aktif',
            'sk_document' => 'SK2.pdf',
        ];

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/mutations', $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['asset_id']);
    }

    public function test_submission_succeeds_if_previous_mutation_was_completed_or_rejected(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation();

        // Mutasi lama yang sudah selesai
        Mutation::create([
            'ticket_number' => 'TI-2026-0001',
            'asset_id' => $asset->id,
            'applicant_id' => $pemohon->id,
            'origin_location_id' => $asset->location_id,
            'destination_location_id' => $destLocation->id,
            'current_pic_id' => $pemohon->id,
            'target_pic_id' => $pemohon->id,
            'is_asset_moves_with_applicant' => true,
            'reason' => 'Mutasi masa lalu',
            'sk_document' => 'SK_old.pdf',
            'status' => 'selesai',
        ]);

        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Pengajuan baru setelah mutasi lama selesai',
            'sk_document' => 'SK_new.pdf',
        ];

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/mutations', $payload);

        $response->assertStatus(201);
    }

    public function test_submission_fails_when_sk_document_is_missing(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation();

        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Tanpa SK SDM',
        ];

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/mutations', $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['sk_document']);
    }

    public function test_non_pemohon_roles_cannot_submit_mutation(): void
    {
        $roles = ['operator', 'bagian_aset', 'pemimpin_divisi', 'admin'];

        foreach ($roles as $roleName) {
            $user = $this->createUser($roleName);
            $token = $user->createToken('test')->plainTextToken;
            $asset = $this->createAsset($user);
            $destLocation = $this->createLocation();

            $payload = [
                'asset_id' => $asset->id,
                'destination_location_id' => $destLocation->id,
                'reason' => 'Pengajuan oleh '.$roleName,
                'sk_document' => 'SK.pdf',
            ];

            $response = $this->withHeader('Authorization', 'Bearer '.$token)
                ->postJson('/api/v1/mutations', $payload);

            // FormRequest authorize() me-reject role non-pemohon dengan 403 Forbidden
            $response->assertStatus(403);
        }
    }
}
