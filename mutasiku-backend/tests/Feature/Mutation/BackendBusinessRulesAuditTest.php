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
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class BackendBusinessRulesAuditTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;
    private User $pemohon;
    private User $operator;
    private User $bagianAset;
    private User $kadiv;
    private Asset $asset;
    private Location $originLoc;
    private Location $destLoc;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');

        $roleAdmin = Role::firstOrCreate(['name' => 'admin']);
        $rolePemohon = Role::firstOrCreate(['name' => 'pemohon']);
        $roleOperator = Role::firstOrCreate(['name' => 'operator']);
        $roleAset = Role::firstOrCreate(['name' => 'bagian_aset']);
        $roleKadiv = Role::firstOrCreate(['name' => 'pemimpin_divisi']);

        $this->admin = User::factory()->create(['role_id' => $roleAdmin->id, 'email' => 'admin_audit@mutasiku.test']);
        $this->pemohon = User::factory()->create(['role_id' => $rolePemohon->id, 'email' => 'pemohon_audit@mutasiku.test']);
        $this->operator = User::factory()->create(['role_id' => $roleOperator->id, 'email' => 'operator_audit@mutasiku.test']);
        $this->bagianAset = User::factory()->create(['role_id' => $roleAset->id, 'email' => 'aset_audit@mutasiku.test']);
        $this->kadiv = User::factory()->create(['role_id' => $roleKadiv->id, 'email' => 'kadiv_audit@mutasiku.test']);

        $category = AssetCategory::firstOrCreate(['code' => 'TI'], ['name' => 'Perangkat IT']);
        $this->originLoc = Location::firstOrCreate(['code' => 'AUD-ORG'], ['name' => 'Ruang Asal']);
        $this->destLoc = Location::firstOrCreate(['code' => 'AUD-DST'], ['name' => 'Ruang Tujuan']);

        $this->asset = Asset::create([
            'asset_code' => 'AST-AUDIT-'.uniqid(),
            'name' => 'Workstation Lenovo ThinkStation',
            'asset_category_id' => $category->id,
            'location_id' => $this->originLoc->id,
            'pic_id' => $this->pemohon->id,
            'condition' => 'Baik',
            'serial_number' => 'SN-AUD-'.uniqid(),
            'acquisition_year' => 2024,
            'usage_year' => 2024,
            'is_active' => true,
        ]);
    }

    private function createMutation(string $status, ?User $applicant = null, array $attributes = []): Mutation
    {
        $applicant = $applicant ?? $this->pemohon;

        return Mutation::create(array_merge([
            'ticket_number' => 'TI-2026-'.uniqid(),
            'asset_id' => $this->asset->id,
            'applicant_id' => $applicant->id,
            'origin_location_id' => $this->asset->location_id,
            'destination_location_id' => $this->destLoc->id,
            'current_pic_id' => $this->asset->pic_id,
            'target_pic_id' => $applicant->id,
            'is_asset_moves_with_applicant' => true,
            'reason' => 'Audit business rules mutation',
            'sk_document' => 'documents/sk_sdm/audit.pdf',
            'sk_document_name' => 'audit.pdf',
            'status' => $status,
        ], $attributes));
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 1. Audit Hak Akses Role Admin Pada Endpoint Transaksi
    // ──────────────────────────────────────────────────────────────────────────

    public function test_admin_is_forbidden_from_executing_operational_mutation_actions(): void
    {
        $token = $this->admin->createToken('admin_token')->plainTextToken;
        $mutation = $this->createMutation('diajukan');

        // Admin cannot submit operational actions directly
        $endpoints = [
            ['postJson', "/api/v1/mutations/{$mutation->id}/forward", []],
            ['postJson', "/api/v1/mutations/{$mutation->id}/return-by-operator", ['reason' => 'Tes alasan']],
            ['postJson', "/api/v1/mutations/{$mutation->id}/verify-asset", ['action' => 'verify']],
            ['postJson', "/api/v1/mutations/{$mutation->id}/return-by-asset", ['reason' => 'Tes alasan']],
            ['postJson', "/api/v1/mutations/{$mutation->id}/approve", ['action' => 'approve']],
            ['postJson', "/api/v1/mutations/{$mutation->id}/reject", ['reason' => 'Tes alasan']],
            ['postJson', "/api/v1/mutations/{$mutation->id}/confirm", ['confirmation' => 'sesuai']],
            ['postJson', "/api/v1/mutations/{$mutation->id}/report-discrepancy", ['reason' => 'Tes alasan']],
            ['postJson', "/api/v1/mutations/{$mutation->id}/resubmit", ['reason' => 'Tes alasan']],
            ['putJson', "/api/v1/mutations/{$mutation->id}", ['reason' => 'Tes alasan']],
        ];

        foreach ($endpoints as [$method, $uri, $payload]) {
            $response = $this->withHeader('Authorization', 'Bearer '.$token)->{$method}($uri, $payload);
            $response->assertStatus(403);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 2. Audit Penolakan Final Kadiv: Mutasi Ditolak Tidak Boleh Diedit / Resubmit
    // ──────────────────────────────────────────────────────────────────────────

    public function test_rejected_mutation_cannot_be_updated_or_resubmitted(): void
    {
        $token = $this->pemohon->createToken('pemohon_token')->plainTextToken;
        $mutation = $this->createMutation('ditolak', $this->pemohon, [
            'rejection_reason' => 'Penolakan final oleh Pemimpin Divisi.',
        ]);

        // Attempt resubmit via POST /api/v1/mutations/{id}/resubmit
        $resubmitResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/resubmit", [
                'reason' => 'Mencoba mengajukan ulang mutasi yang telah ditolak.',
            ]);

        $resubmitResponse->assertStatus(409)
            ->assertJson([
                'success' => false,
            ]);

        // Attempt update via PUT /api/v1/mutations/{id}
        $updateResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->putJson("/api/v1/mutations/{$mutation->id}", [
                'reason' => 'Mencoba mengedit mutasi yang telah ditolak.',
            ]);

        $updateResponse->assertStatus(409)
            ->assertJson([
                'success' => false,
            ]);

        // Pastikan status dan data mutasi di database tetap tidak berubah
        $mutationFresh = $mutation->fresh();
        $this->assertEquals('ditolak', $mutationFresh->status);
        $this->assertEquals('Penolakan final oleh Pemimpin Divisi.', $mutationFresh->rejection_reason);
        $this->assertEquals('Audit business rules mutation', $mutationFresh->reason);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 3. Audit Verifikasi Bagian Aset Meneruskan Ke Kadiv & Tidak Mengubah Aset
    // ──────────────────────────────────────────────────────────────────────────

    public function test_bagian_aset_verification_transitions_to_kadiv_and_does_not_modify_asset(): void
    {
        $token = $this->bagianAset->createToken('aset_token')->plainTextToken;
        $mutation = $this->createMutation('menunggu_verifikasi_bagian_aset', $this->pemohon);

        $initialAssetLocation = $this->asset->location_id;
        $initialAssetPic = $this->asset->pic_id;

        $targetUser = User::factory()->create(['role_id' => $this->pemohon->role_id]);

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify-asset", [
                'action' => 'verify',
                'target_pic_id' => $targetUser->id,
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $mutation->id,
                    'status' => 'menunggu_approval_pemimpin_divisi',
                    'target_pic_id' => $targetUser->id,
                ],
            ]);

        // Memastikan status transisi tepat ke menunggu_approval_pemimpin_divisi (BUKAN selesai)
        $this->assertEquals('menunggu_approval_pemimpin_divisi', $mutation->fresh()->status);

        // Memastikan data fisik aset di tabel assets BELUM berubah sama sekali
        $assetFresh = $this->asset->fresh();
        $this->assertEquals($initialAssetLocation, $assetFresh->location_id);
        $this->assertEquals($initialAssetPic, $assetFresh->pic_id);

        // Belum ada baris riwayat mutasi aset di mutation_histories
        $this->assertDatabaseMissing('mutation_histories', [
            'mutation_id' => $mutation->id,
        ]);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 4. Audit Approval Kadiv Meneruskan Ke Konfirmasi Pemohon & Tidak Mengubah Aset
    // ──────────────────────────────────────────────────────────────────────────

    public function test_kadiv_approval_transitions_to_waiting_confirmation_and_does_not_modify_asset(): void
    {
        $token = $this->kadiv->createToken('kadiv_token')->plainTextToken;
        $mutation = $this->createMutation('menunggu_approval_pemimpin_divisi', $this->pemohon);

        $initialAssetLocation = $this->asset->location_id;
        $initialAssetPic = $this->asset->pic_id;

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

        // Memastikan status transisi ke menunggu_konfirmasi_pemohon (BUKAN selesai)
        $this->assertEquals('menunggu_konfirmasi_pemohon', $mutation->fresh()->status);

        // Memastikan data fisik aset di tabel assets BELUM berubah
        $assetFresh = $this->asset->fresh();
        $this->assertEquals($initialAssetLocation, $assetFresh->location_id);
        $this->assertEquals($initialAssetPic, $assetFresh->pic_id);

        // Belum ada baris riwayat mutasi aset di mutation_histories
        $this->assertDatabaseMissing('mutation_histories', [
            'mutation_id' => $mutation->id,
        ]);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 5. Audit Konfirmasi Pemohon Adalah Satu-satunya Tempat Aset Diperbarui
    // ──────────────────────────────────────────────────────────────────────────

    public function test_asset_location_and_pic_are_only_updated_upon_pemohon_confirm_sesuai(): void
    {
        $targetUser = User::factory()->create(['role_id' => $this->pemohon->role_id]);
        $newLocation = Location::firstOrCreate(['code' => 'AUD-NEW'], ['name' => 'Lokasi Terkonfirmasi']);

        $mutation = $this->createMutation('menunggu_konfirmasi_pemohon', $this->pemohon, [
            'destination_location_id' => $newLocation->id,
            'target_pic_id' => $targetUser->id,
        ]);

        $oldLocId = $this->asset->location_id;
        $oldPicId = $this->asset->pic_id;

        $token = $this->pemohon->createToken('pemohon_token')->plainTextToken;

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

        // 1. Status mutasi menjadi 'selesai'
        $this->assertEquals('selesai', $mutation->fresh()->status);

        // 2. Data aset resmi diperbarui
        $assetFresh = $this->asset->fresh();
        $this->assertEquals($newLocation->id, $assetFresh->location_id);
        $this->assertEquals($targetUser->id, $assetFresh->pic_id);

        // 3. Riwayat mutasi tercatat lengkap di mutation_histories
        $this->assertDatabaseHas('mutation_histories', [
            'asset_id' => $this->asset->id,
            'mutation_id' => $mutation->id,
            'ticket_number' => $mutation->ticket_number,
            'previous_location_id' => $oldLocId,
            'new_location_id' => $newLocation->id,
            'previous_pic_id' => $oldPicId,
            'new_pic_id' => $targetUser->id,
            'updated_by' => $this->pemohon->id,
            'field_changed' => 'location_and_pic',
        ]);
    }
}
