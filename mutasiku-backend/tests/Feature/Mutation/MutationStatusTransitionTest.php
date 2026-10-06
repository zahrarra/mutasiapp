<?php

namespace Tests\Feature\Mutation;

use App\Models\Asset;
use App\Models\AssetCategory;
use App\Models\Location;
use App\Models\Mutation;
use App\Models\MutationHistory;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MutationStatusTransitionTest extends TestCase
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

    private function createMutation(User $applicant, string $status = 'diajukan', array $attributes = []): Mutation
    {
        $asset = $this->createAsset($applicant);
        $loc1 = $this->createLocation('Gedung A', 'GA_'.uniqid());
        $loc2 = $this->createLocation('Gedung B', 'GB_'.uniqid());

        return Mutation::create(array_merge([
            'ticket_number' => 'TI-2026-'.uniqid(),
            'asset_id' => $asset->id,
            'applicant_id' => $applicant->id,
            'origin_location_id' => $asset->location_id,
            'destination_location_id' => $loc2->id,
            'current_pic_id' => $applicant->id,
            'target_pic_id' => $applicant->id,
            'is_asset_moves_with_applicant' => true,
            'reason' => 'Alasan mutasi',
            'sk_document' => 'SK.pdf',
            'status' => $status,
        ], $attributes));
    }

    // ─── 1. Operator Verify Tests ───────────────────────────────────────────

    public function test_operator_verify_succeeds_and_moves_to_bagian_aset(): void
    {
        $operator = $this->createUser('operator');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'diajukan');

        $token = $operator->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify", [
                'action' => 'verify',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $mutation->id,
                    'status' => 'menunggu_verifikasi_bagian_aset',
                ],
            ]);

        $this->assertEquals('menunggu_verifikasi_bagian_aset', $mutation->fresh()->status);
    }

    public function test_operator_return_requires_reason(): void
    {
        $operator = $this->createUser('operator');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'diajukan');

        $token = $operator->createToken('test')->plainTextToken;

        // Return tanpa reason
        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify", [
                'action' => 'return',
                'reason' => '',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['reason']);

        // Return dengan reason
        $responseSuccess = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify", [
                'action' => 'return',
                'reason' => 'Dokumen SK SDM buram dan tidak terbaca.',
            ]);

        $responseSuccess->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'dikembalikan_ke_pemohon',
                    'return_reason' => 'Dokumen SK SDM buram dan tidak terbaca.',
                ],
            ]);

        $this->assertEquals('dikembalikan_ke_pemohon', $mutation->fresh()->status);
    }

    // ─── 2. Bagian Aset Verify Tests ────────────────────────────────────────

    public function test_bagian_aset_verify_succeeds_and_moves_to_pemimpin_divisi(): void
    {
        $bagianAset = $this->createUser('bagian_aset');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_verifikasi_bagian_aset');

        $token = $bagianAset->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify-asset", [
                'action' => 'verify',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $mutation->id,
                    'status' => 'menunggu_approval_pemimpin_divisi',
                ],
            ]);

        $this->assertEquals('menunggu_approval_pemimpin_divisi', $mutation->fresh()->status);
    }

    public function test_bagian_aset_verify_fails_if_target_pic_id_not_determined(): void
    {
        $bagianAset = $this->createUser('bagian_aset');
        $pemohon = $this->createUser('pemohon');

        // Mutasi di mana aset tidak ikut pemohon, sehingga target_pic_id awal null
        $mutation = $this->createMutation($pemohon, 'menunggu_verifikasi_bagian_aset', [
            'target_pic_id' => null,
            'is_asset_moves_with_applicant' => false,
        ]);

        $token = $bagianAset->createToken('test')->plainTextToken;

        // Mencoba verify tanpa menentukan target_pic_id
        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify-asset", [
                'action' => 'verify',
            ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);

        // Berhasil jika bagian_aset menyertakan target_pic_id
        $targetUser = $this->createUser('pemohon');
        $responseSuccess = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify-asset", [
                'action' => 'verify',
                'target_pic_id' => $targetUser->id,
            ]);

        $responseSuccess->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'target_pic_id' => $targetUser->id,
                    'status' => 'menunggu_approval_pemimpin_divisi',
                ],
            ]);
    }

    public function test_bagian_aset_return_requires_reason(): void
    {
        $bagianAset = $this->createUser('bagian_aset');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_verifikasi_bagian_aset');

        $token = $bagianAset->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify-asset", [
                'action' => 'return',
                'reason' => '',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['reason']);

        $responseSuccess = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify-asset", [
                'action' => 'return',
                'reason' => 'Kategori aset salah.',
            ]);

        $responseSuccess->assertStatus(200);
        $this->assertEquals('dikembalikan_ke_pemohon', $mutation->fresh()->status);
    }

    // ─── 3. Pemimpin Divisi Approve & Reject Tests ──────────────────────────

    public function test_pemimpin_divisi_approve_succeeds(): void
    {
        $kadiv = $this->createUser('pemimpin_divisi');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_approval_pemimpin_divisi');

        $token = $kadiv->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/approve", [
                'action' => 'approve',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $mutation->id,
                    'status' => 'menunggu_konfirmasi_pemohon',
                ],
            ]);

        $this->assertEquals('menunggu_konfirmasi_pemohon', $mutation->fresh()->status);

        // Pastikan approval tidak mengubah data fisik aset
        $asset = $mutation->asset->fresh();
        $this->assertEquals($mutation->origin_location_id, $asset->location_id);
    }

    public function test_pemimpin_divisi_reject_requires_reason(): void
    {
        $kadiv = $this->createUser('pemimpin_divisi');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_approval_pemimpin_divisi');

        $token = $kadiv->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/approve", [
                'action' => 'reject',
                'reason' => '',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['reason']);

        $responseSuccess = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/approve", [
                'action' => 'reject',
                'reason' => 'Anggaran transfer tidak disetujui.',
            ]);

        $responseSuccess->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'ditolak',
                    'rejection_reason' => 'Anggaran transfer tidak disetujui.',
                ],
            ]);

        $this->assertEquals('ditolak', $mutation->fresh()->status);
    }

    // ─── 4. Pemohon Confirm Tests ───────────────────────────────────────────

    public function test_pemohon_confirm_sesuai_completes_mutation_and_updates_asset_and_history(): void
    {
        $pemohon = $this->createUser('pemohon');
        $targetPic = $this->createUser('pemohon');
        $newLocation = $this->createLocation('Gedung Tujuan', 'GT');

        $mutation = $this->createMutation($pemohon, 'menunggu_konfirmasi_pemohon', [
            'destination_location_id' => $newLocation->id,
            'target_pic_id' => $targetPic->id,
        ]);

        $asset = $mutation->asset;
        $oldLocationId = $asset->location_id;
        $oldPicId = $asset->pic_id;

        $token = $pemohon->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/confirm", [
                'confirmation' => 'sesuai',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $mutation->id,
                    'status' => 'selesai',
                ],
            ]);

        // 1. Status mutation berubah menjadi selesai
        $this->assertEquals('selesai', $mutation->fresh()->status);

        // 2. Data resmi aset terupdate
        $assetFresh = $asset->fresh();
        $this->assertEquals($newLocation->id, $assetFresh->location_id);
        $this->assertEquals($targetPic->id, $assetFresh->pic_id);

        // 3. Mutation history tercatat
        $this->assertDatabaseHas('mutation_histories', [
            'asset_id' => $asset->id,
            'mutation_id' => $mutation->id,
            'ticket_number' => $mutation->ticket_number,
            'previous_location_id' => $oldLocationId,
            'new_location_id' => $newLocation->id,
            'previous_pic_id' => $oldPicId,
            'new_pic_id' => $targetPic->id,
            'updated_by' => $pemohon->id,
        ]);
    }

    public function test_pemohon_confirm_tidak_sesuai_returns_to_bagian_aset_without_modifying_asset(): void
    {
        $pemohon = $this->createUser('pemohon');
        $newLocation = $this->createLocation('Gedung Tujuan', 'GT');
        $mutation = $this->createMutation($pemohon, 'menunggu_konfirmasi_pemohon', [
            'destination_location_id' => $newLocation->id,
        ]);

        $asset = $mutation->asset;
        $oldLocationId = $asset->location_id;
        $oldPicId = $asset->pic_id;

        $token = $pemohon->createToken('test')->plainTextToken;

        // Wajib reason saat tidak sesuai
        $responseNoReason = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/confirm", [
                'confirmation' => 'tidak_sesuai',
                'reason' => '',
            ]);

        $responseNoReason->assertStatus(422)
            ->assertJsonValidationErrors(['reason']);

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/confirm", [
                'confirmation' => 'tidak_sesuai',
                'reason' => 'Fisik aset belum diterima di lokasi tujuan.',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'menunggu_verifikasi_bagian_aset',
                    'return_reason' => 'Fisik aset belum diterima di lokasi tujuan.',
                ],
            ]);

        // Status kembali ke menunggu_verifikasi_bagian_aset
        $this->assertEquals('menunggu_verifikasi_bagian_aset', $mutation->fresh()->status);

        // Data aset TIDAK berubah
        $assetFresh = $asset->fresh();
        $this->assertEquals($oldLocationId, $assetFresh->location_id);
        $this->assertEquals($oldPicId, $assetFresh->pic_id);

        // Tidak ada mutation history yang dibuat
        $this->assertDatabaseMissing('mutation_histories', [
            'mutation_id' => $mutation->id,
        ]);
    }

    public function test_other_user_cannot_confirm_another_users_mutation(): void
    {
        $pemohon1 = $this->createUser('pemohon');
        $pemohon2 = $this->createUser('pemohon');

        $mutation = $this->createMutation($pemohon1, 'menunggu_konfirmasi_pemohon');

        $token2 = $pemohon2->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token2)
            ->postJson("/api/v1/mutations/{$mutation->id}/confirm", [
                'confirmation' => 'sesuai',
            ]);

        $response->assertStatus(403);
    }

    // ─── 5. Pemohon Resubmit Tests ──────────────────────────────────────────

    public function test_pemohon_resubmit_moves_directly_to_bagian_aset(): void
    {
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'dikembalikan_ke_pemohon', [
            'return_reason' => 'Revisi deskripsi alasan mutasi.',
        ]);

        $token = $pemohon->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/resubmit", [
                'reason' => 'Alasan mutasi sudah diperbaiki secara lengkap.',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'menunggu_verifikasi_bagian_aset',
                    'reason' => 'Alasan mutasi sudah diperbaiki secara lengkap.',
                    'return_reason' => null,
                ],
            ]);

        $this->assertEquals('menunggu_verifikasi_bagian_aset', $mutation->fresh()->status);
    }

    // ─── 6. Role & Status Error Tests ───────────────────────────────────────

    public function test_wrong_role_is_rejected_with_403(): void
    {
        $pemohon = $this->createUser('pemohon');
        $operator = $this->createUser('operator');
        $mutation = $this->createMutation($pemohon, 'diajukan');

        $tokenPemohon = $pemohon->createToken('test')->plainTextToken;

        // Pemohon mencoba memverifikasi
        $response = $this->withHeader('Authorization', 'Bearer '.$tokenPemohon)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify", [
                'action' => 'verify',
            ]);

        $response->assertStatus(403);
    }

    public function test_wrong_status_transition_returns_409_conflict(): void
    {
        $operator = $this->createUser('operator');
        $pemohon = $this->createUser('pemohon');

        // Status bukan 'diajukan'
        $mutation = $this->createMutation($pemohon, 'menunggu_verifikasi_bagian_aset');

        $token = $operator->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify", [
                'action' => 'verify',
            ]);

        $response->assertStatus(409)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_transaction_rollback_when_history_creation_fails(): void
    {
        $pemohon = $this->createUser('pemohon');
        $targetPic = $this->createUser('pemohon');
        $newLocation = $this->createLocation('Gedung Tujuan', 'GT_TX');

        $mutation = $this->createMutation($pemohon, 'menunggu_konfirmasi_pemohon', [
            'destination_location_id' => $newLocation->id,
            'target_pic_id' => $targetPic->id,
        ]);

        $asset = $mutation->asset;
        $originalLocationId = $asset->location_id;
        $originalPicId = $asset->pic_id;

        $token = $pemohon->createToken('test')->plainTextToken;

        // Simulasi error saat menyimpan MutationHistory
        MutationHistory::saving(function () {
            throw new \RuntimeException('Simulated database error during history saving');
        });

        try {
            $this->withHeader('Authorization', 'Bearer '.$token)
                ->postJson("/api/v1/mutations/{$mutation->id}/confirm", [
                    'confirmation' => 'sesuai',
                ]);
        } catch (\RuntimeException $e) {
            // Simulated exception caught
        }

        // Status mutation harus tetap menunggu_konfirmasi_pemohon (rollback)
        $this->assertEquals('menunggu_konfirmasi_pemohon', $mutation->fresh()->status);

        // Data aset harus tetap pada data asli (rollback)
        $assetFresh = $asset->fresh();
        $this->assertEquals($originalLocationId, $assetFresh->location_id);
        $this->assertEquals($originalPicId, $assetFresh->pic_id);

        // Tidak ada riwayat mutasi yang tersimpan
        $this->assertDatabaseMissing('mutation_histories', [
            'mutation_id' => $mutation->id,
        ]);
    }
}
