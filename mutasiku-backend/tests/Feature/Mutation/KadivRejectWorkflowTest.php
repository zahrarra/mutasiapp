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

class KadivRejectWorkflowTest extends TestCase
{
    use RefreshDatabase;

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

        $rolePemohon = Role::firstOrCreate(['name' => 'pemohon']);
        $roleOperator = Role::firstOrCreate(['name' => 'operator']);
        $roleAset = Role::firstOrCreate(['name' => 'bagian_aset']);
        $roleKadiv = Role::firstOrCreate(['name' => 'pemimpin_divisi']);

        $this->pemohon = User::factory()->create(['role_id' => $rolePemohon->id, 'email' => 'pemohon@test.com']);
        $this->operator = User::factory()->create(['role_id' => $roleOperator->id, 'email' => 'operator@test.com']);
        $this->bagianAset = User::factory()->create(['role_id' => $roleAset->id, 'email' => 'aset@test.com']);
        $this->kadiv = User::factory()->create(['role_id' => $roleKadiv->id, 'email' => 'kadiv@test.com']);

        $category = AssetCategory::firstOrCreate(['code' => 'TI'], ['name' => 'Perangkat IT']);
        $this->originLoc = Location::firstOrCreate(['code' => 'LOC-A'], ['name' => 'Ruang Server']);
        $this->destLoc = Location::firstOrCreate(['code' => 'LOC-B'], ['name' => 'Ruang Kantor']);

        $this->asset = Asset::create([
            'asset_code' => 'AST-'.uniqid(),
            'name' => 'Laptop ThinkPad',
            'asset_category_id' => $category->id,
            'location_id' => $this->originLoc->id,
            'pic_id' => $this->pemohon->id,
            'condition' => 'Baik',
            'serial_number' => 'SN-'.uniqid(),
            'acquisition_year' => 2024,
            'usage_year' => 2024,
            'is_active' => true,
        ]);
    }

    private function createMutationAtWaitingKadiv(): Mutation
    {
        // 1. Submit by Pemohon
        $submitRes = $this->actingAs($this->pemohon)->post('/api/v1/mutations', [
            'asset_id' => $this->asset->id,
            'destination_location_id' => $this->destLoc->id,
            'reason' => 'Pindah ruang kerja untuk operasional',
            'asset_moves_with_applicant' => false,
            'target_pic_id' => $this->pemohon->id,
            'sk_document' => \Illuminate\Http\UploadedFile::fake()->create('sk_mutasi.pdf', 100, 'application/pdf'),
        ]);
        $submitRes->assertStatus(201);
        $mutationId = $submitRes->json('data.id');

        // 2. Forward by Operator
        $forwardRes = $this->actingAs($this->operator)->postJson("/api/v1/mutations/{$mutationId}/forward", [
            'notes' => 'Forwarded by operator',
        ]);
        $forwardRes->assertStatus(200);

        // 3. Verify by Bagian Aset
        $verifyRes = $this->actingAs($this->bagianAset)->postJson("/api/v1/mutations/{$mutationId}/verify-asset", [
            'action' => 'verify',
            'target_pic_id' => $this->pemohon->id,
            'notes' => 'Verified by asset team',
        ]);
        $verifyRes->assertStatus(200);

        $mutation = Mutation::find($mutationId);
        $this->assertEquals('menunggu_approval_pemimpin_divisi', $mutation->status);

        return $mutation;
    }

    public function test_kadiv_can_reject_mutation_via_dedicated_reject_endpoint(): void
    {
        $mutation = $this->createMutationAtWaitingKadiv();
        $mutationId = $mutation->id;

        // Kadiv rejects via POST /api/v1/mutations/{id}/reject
        $rejectRes = $this->actingAs($this->kadiv)->postJson("/api/v1/mutations/{$mutationId}/reject", [
            'reason' => 'Pengajuan ditolak karena anggaran pemindahan belum tersedia.',
        ]);

        $rejectRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $mutationId,
                    'status' => 'ditolak',
                    'rejection_reason' => 'Pengajuan ditolak karena anggaran pemindahan belum tersedia.',
                ],
            ]);

        // Verify DB state
        $mutation->refresh();
        $this->assertEquals('ditolak', $mutation->status);
        $this->assertEquals('Pengajuan ditolak karena anggaran pemindahan belum tersedia.', $mutation->rejection_reason);
        $this->assertNotNull($mutation->rejected_at);
        $this->assertEquals($this->kadiv->id, $mutation->rejected_by);

        // Verify Status History exists
        $this->assertDatabaseHas('mutation_status_histories', [
            'mutation_id' => $mutationId,
            'user_id' => $this->kadiv->id,
            'role' => 'pemimpin_divisi',
            'action' => 'reject',
            'status_from' => 'menunggu_approval_pemimpin_divisi',
            'status_to' => 'ditolak',
            'notes' => 'Pengajuan ditolak karena anggaran pemindahan belum tersedia.',
        ]);

        // GET /api/v1/mutations/{id} by Kadiv must succeed (200) with complete data
        $detailRes = $this->actingAs($this->kadiv)->getJson("/api/v1/mutations/{$mutationId}");
        $detailRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $mutationId,
                    'status' => 'ditolak',
                    'rejection_reason' => 'Pengajuan ditolak karena anggaran pemindahan belum tersedia.',
                ],
            ]);

        // GET /api/v1/mutations?view=history by Kadiv must include the rejected mutation
        $historyRes = $this->actingAs($this->kadiv)->getJson('/api/v1/mutations?view=history');
        $historyRes->assertStatus(200);
        $historyIds = collect($historyRes->json('data'))->pluck('id')->all();
        $this->assertContains($mutationId, $historyIds);

        // GET /api/v1/mutations?view=all by Kadiv must include the rejected mutation
        $allRes = $this->actingAs($this->kadiv)->getJson('/api/v1/mutations?view=all');
        $allRes->assertStatus(200);
        $allIds = collect($allRes->json('data'))->pluck('id')->all();
        $this->assertContains($mutationId, $allIds);

        // GET /api/v1/mutations (active queue) must NOT include the rejected mutation
        $queueRes = $this->actingAs($this->kadiv)->getJson('/api/v1/mutations');
        $queueRes->assertStatus(200);
        $queueIds = collect($queueRes->json('data'))->pluck('id')->all();
        $this->assertNotContains($mutationId, $queueIds);
    }

    public function test_kadiv_can_reject_mutation_via_approve_endpoint_with_action_reject(): void
    {
        $mutation = $this->createMutationAtWaitingKadiv();
        $mutationId = $mutation->id;

        // Kadiv rejects via POST /api/v1/mutations/{id}/approve with action: reject
        $rejectRes = $this->actingAs($this->kadiv)->postJson("/api/v1/mutations/{$mutationId}/approve", [
            'action' => 'reject',
            'reason' => 'Ditolak via action reject.',
        ]);

        $rejectRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $mutationId,
                    'status' => 'ditolak',
                    'rejection_reason' => 'Ditolak via action reject.',
                ],
            ]);

        // Verify DB state
        $mutation->refresh();
        $this->assertEquals('ditolak', $mutation->status);
        $this->assertEquals('Ditolak via action reject.', $mutation->rejection_reason);
    }
}
