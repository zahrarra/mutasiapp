<?php

namespace Tests\Feature\Mutation;

use App\Models\Asset;
use App\Models\AssetCategory;
use App\Models\Location;
use App\Models\Mutation;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class MutationSubmissionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

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

    private function createFakePdf(string $name = 'SK.pdf', int $kilobytes = 100): UploadedFile
    {
        return UploadedFile::fake()->create($name, $kilobytes, 'application/pdf');
    }

    private function postMutation(string $token, array $payload)
    {
        return $this->withHeader('Authorization', 'Bearer '.$token)
            ->post('/api/v1/mutations', $payload, ['Accept' => 'application/json']);
    }

    public function test_pemohon_can_submit_valid_mutation(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;

        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation('Gedung Cabang', 'GC');
        $file = $this->createFakePdf('SK-SDM-2026-001.pdf', 500);

        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Pindah tugas ke divisi baru',
            'sk_document' => $file,
            'asset_moves_with_applicant' => 1,
        ];

        $response = $this->postMutation($token, $payload);

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
                    'is_asset_moves_with_applicant' => true,
                ],
            ]);

        $createdId = $response->json('data.id');
        $this->assertNotNull($createdId);
        $this->assertEquals($createdId, $response->json('data.mutation_id'));

        $savedPath = $response->json('data.sk_document');
        $this->assertNotNull($savedPath);
        $this->assertStringStartsWith('documents/sk_sdm/', $savedPath);
        Storage::disk('public')->assertExists($savedPath);

        $this->assertDatabaseHas('mutations', [
            'asset_id' => $asset->id,
            'applicant_id' => $pemohon->id,
            'status' => 'diajukan',
            'origin_location_id' => $asset->location_id,
            'destination_location_id' => $destLocation->id,
            'target_pic_id' => $pemohon->id,
            'sk_document' => $savedPath,
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
        $file = $this->createFakePdf('SK-SDM-002.pdf');

        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Mutasi kerja',
            'sk_document' => $file,
            'asset_moves_with_applicant' => 1,
        ];

        $response = $this->postMutation($token, $payload);

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
        $file = $this->createFakePdf('SK-SDM-003.pdf');

        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Mutasi kerja',
            'sk_document' => $file,
            'asset_moves_with_applicant' => 1,
            'target_pic_id' => $otherUser->id,
        ];

        $response = $this->postMutation($token, $payload);

        $response->assertStatus(201);
        $this->assertEquals($pemohon->id, $response->json('data.target_pic_id'));
        $this->assertNotEquals($otherUser->id, $response->json('data.target_pic_id'));
    }

    public function test_asset_moves_with_applicant_false_sets_target_pic_id_to_null(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation('Gedung B', 'GB');
        $file = $this->createFakePdf('SK-SDM-004.pdf');

        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Aset ditinggal di kantor lama',
            'sk_document' => $file,
            'asset_moves_with_applicant' => 0,
        ];

        $response = $this->postMutation($token, $payload);

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
        $file = $this->createFakePdf('SK-SDM-005.pdf');

        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Aset ditinggalkan',
            'sk_document' => $file,
            'asset_moves_with_applicant' => 0,
            'target_pic_id' => $otherUser->id,
        ];

        $response = $this->postMutation($token, $payload);

        $response->assertStatus(201);
        $this->assertNull($response->json('data.target_pic_id'));
    }

    public function test_submission_fails_when_asset_not_found(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $destLocation = $this->createLocation();
        $file = $this->createFakePdf();

        $payload = [
            'asset_id' => 99999,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Pindah',
            'sk_document' => $file,
        ];

        $response = $this->postMutation($token, $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['asset_id']);
    }

    public function test_submission_fails_when_asset_is_not_held_by_applicant(): void
    {
        $pemohon1 = $this->createUser('pemohon');
        $pemohon2 = $this->createUser('pemohon');

        $token1 = $pemohon1->createToken('test')->plainTextToken;
        $assetMilikPemohon2 = $this->createAsset($pemohon2);
        $destLocation = $this->createLocation();
        $file = $this->createFakePdf();

        $payload = [
            'asset_id' => $assetMilikPemohon2->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Mencoba mutasi aset orang lain',
            'sk_document' => $file,
        ];

        $response = $this->postMutation($token1, $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['asset_id']);
    }

    public function test_submission_fails_when_asset_already_has_active_mutation(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation();

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
            'sk_document' => 'documents/sk_sdm/sk1.pdf',
            'status' => 'diajukan',
        ]);

        $file = $this->createFakePdf('SK2.pdf');
        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Mutasi kedua padahal mutasi pertama aktif',
            'sk_document' => $file,
        ];

        $response = $this->postMutation($token, $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['asset_id']);
    }

    public function test_submission_succeeds_if_previous_mutation_was_completed_or_rejected(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation();

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
            'sk_document' => 'documents/sk_sdm/sk_old.pdf',
            'status' => 'selesai',
        ]);

        $file = $this->createFakePdf('SK_new.pdf');
        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'Pengajuan baru setelah mutasi lama selesai',
            'sk_document' => $file,
        ];

        $response = $this->postMutation($token, $payload);

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

        $response = $this->postMutation($token, $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['sk_document']);

        $this->assertEquals(
            'Surat Keputusan (SK) SDM wajib dilampirkan.',
            $response->json('errors.sk_document.0')
        );
    }

    public function test_submission_fails_when_sk_document_is_not_a_file(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation();

        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'SK bukan file',
            'sk_document' => 'hanya-string-bukan-file.pdf',
        ];

        $response = $this->postMutation($token, $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['sk_document']);

        $this->assertEquals(
            'Berkas SK SDM harus berupa dokumen yang valid.',
            $response->json('errors.sk_document.0')
        );
    }

    public function test_submission_fails_when_sk_document_is_not_pdf(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation();
        $file = UploadedFile::fake()->create('dokumen.docx', 500, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');

        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'SK format docx',
            'sk_document' => $file,
        ];

        $response = $this->postMutation($token, $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['sk_document']);

        $this->assertEquals(
            'Berkas SK SDM harus berupa dokumen dengan format PDF.',
            $response->json('errors.sk_document.0')
        );
    }

    public function test_submission_fails_when_sk_document_exceeds_30_mb(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation();

        // 30 MB = 30720 KB. Buat file 30721 KB (30 MB + 1 KB)
        $file = $this->createFakePdf('SK_besar.pdf', 30721);

        $payload = [
            'asset_id' => $asset->id,
            'destination_location_id' => $destLocation->id,
            'reason' => 'SK ukuran terlalu besar',
            'sk_document' => $file,
        ];

        $response = $this->postMutation($token, $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['sk_document']);

        $this->assertEquals(
            'Ukuran berkas SK SDM tidak boleh melebihi 30 MB.',
            $response->json('errors.sk_document.0')
        );
    }

    public function test_resubmit_with_new_valid_pdf_updates_path_and_stores_file(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $loc1 = $this->createLocation('Gedung A', 'GA_'.uniqid());
        $loc2 = $this->createLocation('Gedung B', 'GB_'.uniqid());

        $mutation = Mutation::create([
            'ticket_number' => 'TI-2026-'.uniqid(),
            'asset_id' => $asset->id,
            'applicant_id' => $pemohon->id,
            'origin_location_id' => $loc1->id,
            'destination_location_id' => $loc2->id,
            'current_pic_id' => $pemohon->id,
            'target_pic_id' => $pemohon->id,
            'is_asset_moves_with_applicant' => true,
            'reason' => 'Alasan awal',
            'sk_document' => 'documents/sk_sdm/old_sk.pdf',
            'status' => 'dikembalikan_ke_pemohon',
        ]);

        $newFile = $this->createFakePdf('SK_revisi.pdf', 250);

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->post("/api/v1/mutations/{$mutation->id}/resubmit", [
                'reason' => 'SK telah diperbaiki dan diunggah ulang',
                'sk_document' => $newFile,
            ], ['Accept' => 'application/json']);

        $response->assertStatus(200);

        $newPath = $response->json('data.sk_document');
        $this->assertNotNull($newPath);
        $this->assertNotEquals('documents/sk_sdm/old_sk.pdf', $newPath);
        $this->assertStringStartsWith('documents/sk_sdm/', $newPath);
        Storage::disk('public')->assertExists($newPath);

        $this->assertEquals($newPath, $mutation->fresh()->sk_document);
    }

    public function test_resubmit_without_new_file_preserves_existing_sk_document(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $loc1 = $this->createLocation('Gedung A', 'GA_'.uniqid());
        $loc2 = $this->createLocation('Gedung B', 'GB_'.uniqid());

        $oldPath = 'documents/sk_sdm/preserved_sk.pdf';

        $mutation = Mutation::create([
            'ticket_number' => 'TI-2026-'.uniqid(),
            'asset_id' => $asset->id,
            'applicant_id' => $pemohon->id,
            'origin_location_id' => $loc1->id,
            'destination_location_id' => $loc2->id,
            'current_pic_id' => $pemohon->id,
            'target_pic_id' => $pemohon->id,
            'is_asset_moves_with_applicant' => true,
            'reason' => 'Alasan awal',
            'sk_document' => $oldPath,
            'status' => 'dikembalikan_ke_pemohon',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->post("/api/v1/mutations/{$mutation->id}/resubmit", [
                'reason' => 'Hanya memperbaiki alasan tanpa ganti SK',
            ], ['Accept' => 'application/json']);

        $response->assertStatus(200);

        $this->assertEquals($oldPath, $response->json('data.sk_document'));
        $this->assertEquals($oldPath, $mutation->fresh()->sk_document);
    }

    public function test_resubmit_fails_when_uploaded_file_is_not_pdf(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;
        $asset = $this->createAsset($pemohon);
        $loc1 = $this->createLocation();

        $mutation = Mutation::create([
            'ticket_number' => 'TI-2026-'.uniqid(),
            'asset_id' => $asset->id,
            'applicant_id' => $pemohon->id,
            'origin_location_id' => $loc1->id,
            'destination_location_id' => $loc1->id,
            'current_pic_id' => $pemohon->id,
            'target_pic_id' => $pemohon->id,
            'is_asset_moves_with_applicant' => true,
            'reason' => 'Alasan awal',
            'sk_document' => 'documents/sk_sdm/sk_lama.pdf',
            'status' => 'dikembalikan_ke_pemohon',
        ]);

        $invalidFile = UploadedFile::fake()->create('foto.jpg', 200, 'image/jpeg');

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->post("/api/v1/mutations/{$mutation->id}/resubmit", [
                'reason' => 'Upload file bukan PDF',
                'sk_document' => $invalidFile,
            ], ['Accept' => 'application/json']);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['sk_document']);

        $this->assertEquals(
            'Berkas SK SDM harus berupa dokumen dengan format PDF.',
            $response->json('errors.sk_document.0')
        );
    }

    public function test_non_pemohon_roles_cannot_submit_mutation(): void
    {
        $roles = ['operator', 'bagian_aset', 'pemimpin_divisi', 'admin'];

        foreach ($roles as $roleName) {
            $user = $this->createUser($roleName);
            $token = $user->createToken('test')->plainTextToken;
            $asset = $this->createAsset($user);
            $destLocation = $this->createLocation();
            $file = $this->createFakePdf();

            $payload = [
                'asset_id' => $asset->id,
                'destination_location_id' => $destLocation->id,
                'reason' => 'Pengajuan oleh '.$roleName,
                'sk_document' => $file,
            ];

            $response = $this->postMutation($token, $payload);

            // FormRequest authorize() me-reject role non-pemohon dengan 403 Forbidden
            $response->assertStatus(403);
        }
    }
}
