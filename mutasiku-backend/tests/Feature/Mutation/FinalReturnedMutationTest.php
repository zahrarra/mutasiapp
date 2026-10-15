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

class FinalReturnedMutationTest extends TestCase
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

    private function createMutation(User $applicant, Asset $asset, string $status = 'diajukan'): Mutation
    {
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
            'sk_document_name' => 'sk.pdf',
            'status' => $status,
        ]);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Skenario 1: Operator dilarang mengembalikan pengajuan (Opsi A) -> 403 Forbidden
    // ──────────────────────────────────────────────────────────────────────────
    public function test_operator_cannot_return_mutation(): void
    {
        $pemohon = $this->createUser('pemohon');
        $operator = $this->createUser('operator');
        $asset = $this->createAsset($pemohon);
        $mutation = $this->createMutation($pemohon, $asset, 'diajukan');

        // Operator attempts return -> 403 Forbidden
        $response = $this->actingAs($operator)
            ->postJson("/api/v1/mutations/{$mutation->id}/return-by-operator", [
                'reason' => 'Berkas belum lengkap.',
            ]);
        $response->assertStatus(403);

        $this->assertEquals('diajukan', $mutation->fresh()->status);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Skenario 2: Bagian Aset mengembalikan pengajuan -> tiket lama final & 409 on edit/resubmit
    // ──────────────────────────────────────────────────────────────────────────
    public function test_asset_section_return_makes_mutation_final_and_cannot_be_resubmitted(): void
    {
        $pemohon = $this->createUser('pemohon');
        $bagianAset = $this->createUser('bagian_aset');
        $asset = $this->createAsset($pemohon);
        $mutation = $this->createMutation($pemohon, $asset, 'menunggu_verifikasi_bagian_aset');

        // Bagian Aset returns mutation
        $response = $this->actingAs($bagianAset)
            ->postJson("/api/v1/mutations/{$mutation->id}/return-by-asset", [
                'reason' => 'Fisik aset tidak sesuai spesifikasi.',
            ]);
        $response->assertStatus(200);

        $fresh = $mutation->fresh();
        $this->assertEquals('dikembalikan_ke_pemohon', $fresh->status);
        $this->assertEquals('Fisik aset tidak sesuai spesifikasi.', $fresh->return_reason);

        // Resubmit route is removed -> 404
        $resubmitResponse = $this->actingAs($pemohon)
            ->postJson("/api/v1/mutations/{$mutation->id}/resubmit", [
                'reason' => 'Mencoba resubmit',
            ]);
        $resubmitResponse->assertStatus(404);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Skenario 3: Kadiv menolak pengajuan -> tiket lama final & route resubmit 404
    // ──────────────────────────────────────────────────────────────────────────
    public function test_kadiv_reject_makes_mutation_final_and_cannot_be_resubmitted(): void
    {
        $pemohon = $this->createUser('pemohon');
        $kadiv = $this->createUser('pemimpin_divisi');
        $asset = $this->createAsset($pemohon);
        $mutation = $this->createMutation($pemohon, $asset, 'menunggu_approval_pemimpin_divisi');

        // Kadiv rejects
        $response = $this->actingAs($kadiv)
            ->postJson("/api/v1/mutations/{$mutation->id}/reject", [
                'reason' => 'Tidak disetujui untuk mutasi saat ini.',
            ]);
        $response->assertStatus(200);

        $fresh = $mutation->fresh();
        $this->assertEquals('ditolak', $fresh->status);
        $this->assertEquals('Tidak disetujui untuk mutasi saat ini.', $fresh->rejection_reason);

        // Resubmit route is removed -> 404
        $resubmitResponse = $this->actingAs($pemohon)
            ->postJson("/api/v1/mutations/{$mutation->id}/resubmit", [
                'reason' => 'Mencoba resubmit mutasi yang ditolak',
            ]);
        $resubmitResponse->assertStatus(404);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Skenario 4 & 5: Request edit dan resubmit langsung ke API mengembalikan 404/405
    // ──────────────────────────────────────────────────────────────────────────
    public function test_direct_api_edit_and_resubmit_endpoints_are_removed(): void
    {
        $pemohon = $this->createUser('pemohon');
        $asset = $this->createAsset($pemohon);

        $finalStatuses = ['dikembalikan_ke_pemohon', 'ditolak', 'selesai'];

        foreach ($finalStatuses as $status) {
            $mutation = $this->createMutation($pemohon, $asset, $status);

            // PUT /mutations/{id} -> 404 or 405
            $putRes = $this->actingAs($pemohon)
                ->putJson("/api/v1/mutations/{$mutation->id}", [
                    'reason' => 'Edit payload direct',
                ]);
            $this->assertTrue(in_array($putRes->status(), [404, 405]));

            // POST /mutations/{id}/resubmit -> 404
            $postRes = $this->actingAs($pemohon)
                ->postJson("/api/v1/mutations/{$mutation->id}/resubmit", [
                    'reason' => 'Resubmit payload direct',
                ]);
            $postRes->assertStatus(404);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Skenario 6 & 7: Pemohon dapat membuat mutasi baru untuk aset yang sama
    // ──────────────────────────────────────────────────────────────────────────
    public function test_applicant_can_submit_new_mutation_with_new_ticket_for_returned_or_rejected_asset(): void
    {
        Storage::fake('public');
        $pemohon = $this->createUser('pemohon');
        $asset = $this->createAsset($pemohon);
        $loc2 = $this->createLocation('Gedung Cabang', 'GC_'.uniqid());

        // 1. Buat mutasi pertama lalu dikembalikan oleh Operator
        $firstMutation = $this->createMutation($pemohon, $asset, 'diajukan');
        $firstMutation->status = 'dikembalikan_ke_pemohon';
        $firstMutation->return_reason = 'Dokumen awal kurang spesifik';
        $firstMutation->save();

        // 2. Pemohon mengajukan mutasi baru untuk aset yang sama
        $token = $pemohon->createToken('test')->plainTextToken;
        $pdfFile = UploadedFile::fake()->create('sk_baru.pdf', 300, 'application/pdf');

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->post('/api/v1/mutations', [
                'asset_id' => $asset->id,
                'destination_location_id' => $loc2->id,
                'reason' => 'Pengajuan baru menggantikan pengajuan sebelumnya yang dikembalikan',
                'sk_document' => $pdfFile,
                'asset_moves_with_applicant' => 1,
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Pengajuan mutasi berhasil dibuat.',
            ]);

        $newMutationId = $response->json('data.id');
        $newTicketNumber = $response->json('data.ticket_number');

        $this->assertNotEquals($firstMutation->id, $newMutationId);
        $this->assertNotEquals($firstMutation->ticket_number, $newTicketNumber);

        // 3. Tiket lama tetap ada di database dengan status final
        $firstMutationFresh = $firstMutation->fresh();
        $this->assertEquals('dikembalikan_ke_pemohon', $firstMutationFresh->status);
        $this->assertEquals('Dokumen awal kurang spesifik', $firstMutationFresh->return_reason);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Skenario 8: Pengajuan final lama tetap tampil pada riwayat
    // ──────────────────────────────────────────────────────────────────────────
    public function test_final_mutations_still_appear_in_history_view(): void
    {
        $pemohon = $this->createUser('pemohon');
        $asset = $this->createAsset($pemohon);

        $returnedMutation = $this->createMutation($pemohon, $asset, 'dikembalikan_ke_pemohon');
        $returnedMutation->return_reason = 'Alasan pengembalian tercatat';
        $returnedMutation->save();

        $rejectedMutation = $this->createMutation($pemohon, $asset, 'ditolak');
        $rejectedMutation->rejection_reason = 'Alasan penolakan tercatat';
        $rejectedMutation->save();

        $historyRes = $this->actingAs($pemohon)
            ->getJson('/api/v1/mutations?view=history');

        $historyRes->assertStatus(200);
        $ids = collect($historyRes->json('data'))->pluck('id')->all();

        $this->assertContains($returnedMutation->id, $ids);
        $this->assertContains($rejectedMutation->id, $ids);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Skenario 9: Pengajuan aktif yang sah tetap mengikuti workflow sebelumnya
    // ──────────────────────────────────────────────────────────────────────────
    public function test_valid_active_mutation_follows_standard_workflow(): void
    {
        $pemohon = $this->createUser('pemohon');
        $operator = $this->createUser('operator');
        $bagianAset = $this->createUser('bagian_aset');
        $asset = $this->createAsset($pemohon);

        $mutation = $this->createMutation($pemohon, $asset, 'diajukan');

        // Operator forwards
        $forwardRes = $this->actingAs($operator)
            ->postJson("/api/v1/mutations/{$mutation->id}/forward");
        $forwardRes->assertStatus(200);
        $this->assertEquals('menunggu_verifikasi_bagian_aset', $mutation->fresh()->status);

        // Bagian Aset verifies
        $verifyRes = $this->actingAs($bagianAset)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify-asset", [
                'target_pic_id' => $pemohon->id,
            ]);
        $verifyRes->assertStatus(200);
        $this->assertEquals('menunggu_approval_pemimpin_divisi', $mutation->fresh()->status);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Skenario 10: Penolakan tidak mengubah lokasi atau PIC aset
    // ──────────────────────────────────────────────────────────────────────────
    public function test_rejection_or_return_does_not_modify_asset_location_or_pic(): void
    {
        $pemohon = $this->createUser('pemohon');
        $kadiv = $this->createUser('pemimpin_divisi');
        $asset = $this->createAsset($pemohon);

        $originalLocationId = $asset->location_id;
        $originalPicId = $asset->pic_id;

        $mutation = $this->createMutation($pemohon, $asset, 'menunggu_approval_pemimpin_divisi');

        // Kadiv rejects
        $this->actingAs($kadiv)
            ->postJson("/api/v1/mutations/{$mutation->id}/reject", [
                'reason' => 'Ditolak',
            ]);

        $assetFresh = $asset->fresh();
        $this->assertEquals($originalLocationId, $assetFresh->location_id);
        $this->assertEquals($originalPicId, $assetFresh->pic_id);
        $this->assertTrue($assetFresh->is_active);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Skenario 11: Validasi satu mutasi aktif per aset tetap berfungsi
    // ──────────────────────────────────────────────────────────────────────────
    public function test_validation_one_active_mutation_per_asset_remains_enforced(): void
    {
        Storage::fake('public');
        $pemohon = $this->createUser('pemohon');
        $asset = $this->createAsset($pemohon);
        $loc2 = $this->createLocation('Gedung Tujuan', 'GT_'.uniqid());

        // Aset sedang dalam mutasi aktif (diajukan)
        $this->createMutation($pemohon, $asset, 'diajukan');

        $token = $pemohon->createToken('test')->plainTextToken;
        $pdfFile = UploadedFile::fake()->create('sk.pdf', 300, 'application/pdf');

        // Mencoba mengajukan mutasi baru untuk aset yang sama saat masih ada mutasi aktif
        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->post('/api/v1/mutations', [
                'asset_id' => $asset->id,
                'destination_location_id' => $loc2->id,
                'reason' => 'Mencoba submit lagi saat masih aktif',
                'sk_document' => $pdfFile,
                'asset_moves_with_applicant' => 1,
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['asset_id']);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Skenario 12: PATCH /api/v1/mutations/{id} juga mengembalikan 409 untuk mutasi final
    // ──────────────────────────────────────────────────────────────────────────
    public function test_patch_mutation_endpoint_is_removed_and_returns_405_or_404(): void
    {
        $pemohon = $this->createUser('pemohon');
        $asset = $this->createAsset($pemohon);
        $loc2 = $this->createLocation('Gedung B', 'GB_'.uniqid());

        $mutation = $this->createMutation($pemohon, $asset, 'dikembalikan_ke_pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->patchJson("/api/v1/mutations/{$mutation->id}", [
                'destination_location_id' => $loc2->id,
                'reason' => 'Mencoba PATCH mutasi yang sudah final',
            ]);

        $this->assertTrue(in_array($response->status(), [404, 405]));
        $this->assertEquals('dikembalikan_ke_pemohon', $mutation->fresh()->status);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Skenario 13: Aset dengan mutasi aktif tidak muncul di query available
    // dan AssetResource memuat has_active_mutation = true
    // ──────────────────────────────────────────────────────────────────────────
    public function test_asset_with_active_mutation_is_excluded_from_available_assets(): void
    {
        $pemohon = $this->createUser('pemohon');
        $asset1 = $this->createAsset($pemohon);
        $asset2 = $this->createAsset($pemohon);

        // asset1 has active mutation
        $this->createMutation($pemohon, $asset1, 'diajukan');

        // Query available assets for pemohon dropdown
        $res = $this->actingAs($pemohon)->getJson('/api/v1/assets?mine=true&available=true');
        $res->assertStatus(200);

        $ids = collect($res->json('data'))->pluck('id')->all();
        $this->assertNotContains($asset1->id, $ids);
        $this->assertContains($asset2->id, $ids);

        // Query all mine assets: asset1 has_active_mutation is true, asset2 is false
        $allRes = $this->actingAs($pemohon)->getJson('/api/v1/assets?mine=true');
        $allRes->assertStatus(200);
        $data = collect($allRes->json('data'));

        $asset1Data = $data->firstWhere('id', $asset1->id);
        $asset2Data = $data->firstWhere('id', $asset2->id);

        $this->assertTrue($asset1Data['has_active_mutation']);
        $this->assertFalse($asset2Data['has_active_mutation']);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Skenario 14: Aset dengan mutasi terminal (dikembalikan/ditolak/selesai)
    // dapat diajukan kembali dengan tiket baru
    // ──────────────────────────────────────────────────────────────────────────
    public function test_asset_with_terminal_mutation_can_be_submitted_as_new_ticket(): void
    {
        $pemohon = $this->createUser('pemohon');
        $asset = $this->createAsset($pemohon);
        $dest = $this->createLocation('Tujuan Baru', 'TB_'.uniqid());

        // Previous mutation was returned to applicant
        $oldMutation = $this->createMutation($pemohon, $asset, 'dikembalikan_ke_pemohon');

        // Check dropdown query: asset should appear as available
        $resAvailable = $this->actingAs($pemohon)->getJson('/api/v1/assets?mine=true&available=true');
        $ids = collect($resAvailable->json('data'))->pluck('id')->all();
        $this->assertContains($asset->id, $ids);

        // Pemohon submits a NEW ticket for this asset
        $token = $pemohon->createToken('test')->plainTextToken;
        $pdfFile = UploadedFile::fake()->create('sk_new.pdf', 300, 'application/pdf');

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->post('/api/v1/mutations', [
                'asset_id' => $asset->id,
                'destination_location_id' => $dest->id,
                'reason' => 'Pengajuan tiket baru setelah pengajuan lama dikembalikan.',
                'sk_document' => $pdfFile,
                'asset_moves_with_applicant' => 1,
            ]);

        $response->assertStatus(201);
        $newMutationId = $response->json('data.id');
        $this->assertNotEquals($oldMutation->id, $newMutationId);
        $this->assertEquals('diajukan', Mutation::find($newMutationId)->status);
        $this->assertEquals('dikembalikan_ke_pemohon', $oldMutation->fresh()->status);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Skenario 15: Operator list tidak menduplikasi tiket & Operator dilarang return
    // ──────────────────────────────────────────────────────────────────────────
    public function test_operator_list_does_not_duplicate_single_ticket_and_operator_cannot_return(): void
    {
        $pemohon = $this->createUser('pemohon');
        $operator = $this->createUser('operator');
        $asset = $this->createAsset($pemohon);

        $mutation = $this->createMutation($pemohon, $asset, 'diajukan');

        // Query Operator list
        $res = $this->actingAs($operator)->getJson('/api/v1/mutations');
        $res->assertStatus(200);

        $items = collect($res->json('data'))->filter(fn ($m) => $m['id'] === $mutation->id);
        $this->assertCount(1, $items);

        // Operator attempt return -> 403 Forbidden
        $returnRes = $this->actingAs($operator)->postJson("/api/v1/mutations/{$mutation->id}/return-by-operator", [
            'reason' => 'Operator dilarang mengembalikan',
        ]);
        $returnRes->assertStatus(403);
    }
}
