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
use Tests\TestCase;

class CompletedMutationVisibilityTest extends TestCase
{
    use RefreshDatabase;

    private User $pemohon;
    private User $operator;
    private User $bagianAset;
    private User $kadiv;
    private User $admin;
    private User $otherOperator;
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
        $roleAdmin = Role::firstOrCreate(['name' => 'admin']);

        $this->pemohon = User::factory()->create(['role_id' => $rolePemohon->id, 'email' => 'pemohon@test.com']);
        $this->operator = User::factory()->create(['role_id' => $roleOperator->id, 'email' => 'operator@test.com']);
        $this->otherOperator = User::factory()->create(['role_id' => $roleOperator->id, 'email' => 'other_operator@test.com']);
        $this->bagianAset = User::factory()->create(['role_id' => $roleAset->id, 'email' => 'aset@test.com']);
        $this->kadiv = User::factory()->create(['role_id' => $roleKadiv->id, 'email' => 'kadiv@test.com']);
        $this->admin = User::factory()->create(['role_id' => $roleAdmin->id, 'email' => 'admin@test.com']);

        $category = AssetCategory::firstOrCreate(['code' => 'TI'], ['name' => 'Perangkat IT']);
        $this->originLoc = Location::firstOrCreate(['code' => 'LOC-A'], ['name' => 'Ruang Server']);
        $this->destLoc = Location::firstOrCreate(['code' => 'LOC-B'], ['name' => 'Ruang Kantor']);

        $this->asset = Asset::create([
            'asset_code' => 'AST-'.uniqid(),
            'name' => 'Laptop ThinkPad X1',
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

    public function test_full_workflow_to_completed_and_role_visibility(): void
    {
        // 1. Pemohon submit
        $submitRes = $this->actingAs($this->pemohon)->post('/api/v1/mutations', [
            'asset_id' => $this->asset->id,
            'destination_location_id' => $this->destLoc->id,
            'reason' => 'Pindah tugas operasional divisi baru.',
            'asset_moves_with_applicant' => false,
            'target_pic_id' => $this->pemohon->id,
            'sk_document' => UploadedFile::fake()->create('sk_mutasi.pdf', 100, 'application/pdf'),
        ]);
        $submitRes->assertStatus(201);
        $mutationId = $submitRes->json('data.id');

        // 2. Operator forward
        $forwardRes = $this->actingAs($this->operator)->postJson("/api/v1/mutations/{$mutationId}/forward", [
            'notes' => 'Forwarded by operator',
        ]);
        $forwardRes->assertStatus(200);

        // 3. Bagian Aset verify
        $verifyRes = $this->actingAs($this->bagianAset)->postJson("/api/v1/mutations/{$mutationId}/verify-asset", [
            'action' => 'verify',
            'target_pic_id' => $this->pemohon->id,
            'notes' => 'Verified by asset team',
        ]);
        $verifyRes->assertStatus(200);

        // 4. Pemimpin Divisi approve
        $approveRes = $this->actingAs($this->kadiv)->postJson("/api/v1/mutations/{$mutationId}/approve", [
            'action' => 'approve',
            'notes' => 'Approved by division head',
        ]);
        $approveRes->assertStatus(200);

        // 5. Pemohon confirm (sesuai)
        $confirmRes = $this->actingAs($this->pemohon)->postJson("/api/v1/mutations/{$mutationId}/confirm", [
            'condition_status' => 'sesuai',
            'notes' => 'Aset diterima dalam kondisi baik.',
        ]);
        $confirmRes->assertStatus(200);

        // 6. Verifikasi status database menjadi 'selesai'
        $mutation = Mutation::find($mutationId);
        $this->assertEquals('selesai', $mutation->status);

        // ─── A. Cek Default Active Queue (view = queue) ────────────────────────
        // Operator active queue: TIDAK boleh ada mutasi selesai (hanya 'diajukan')
        $opQueue = $this->actingAs($this->operator)->getJson('/api/v1/mutations');
        $opQueue->assertStatus(200);
        $this->assertNotContains($mutationId, collect($opQueue->json('data'))->pluck('id')->all());

        // Bagian Aset active queue: TIDAK boleh ada mutasi selesai
        $asetQueue = $this->actingAs($this->bagianAset)->getJson('/api/v1/mutations');
        $asetQueue->assertStatus(200);
        $this->assertNotContains($mutationId, collect($asetQueue->json('data'))->pluck('id')->all());

        // Kadiv active queue: TIDAK boleh ada mutasi selesai
        $kadivQueue = $this->actingAs($this->kadiv)->getJson('/api/v1/mutations');
        $kadivQueue->assertStatus(200);
        $this->assertNotContains($mutationId, collect($kadivQueue->json('data'))->pluck('id')->all());

        // ─── B. Cek History View (view = history) ──────────────────────────────
        // 1. Pemohon history -> DAPAT MELIHAT (applicant_id)
        $pemohonHistory = $this->actingAs($this->pemohon)->getJson('/api/v1/mutations?view=history');
        $pemohonHistory->assertStatus(200);
        $this->assertContains($mutationId, collect($pemohonHistory->json('data'))->pluck('id')->all());

        // 2. Operator yang memproses -> DAPAT MELIHAT via statusHistories
        $opHistory = $this->actingAs($this->operator)->getJson('/api/v1/mutations?view=history');
        $opHistory->assertStatus(200);
        $this->assertContains($mutationId, collect($opHistory->json('data'))->pluck('id')->all());

        // Operator history -> DAPAT MELIHAT via statusHistories role operator
        $otherOpHistory = $this->actingAs($this->otherOperator)->getJson('/api/v1/mutations?view=history');
        $otherOpHistory->assertStatus(200);
        $this->assertContains($mutationId, collect($otherOpHistory->json('data'))->pluck('id')->all());

        // 3. Bagian Aset yang memproses -> DAPAT MELIHAT via statusHistories
        $asetHistory = $this->actingAs($this->bagianAset)->getJson('/api/v1/mutations?view=history');
        $asetHistory->assertStatus(200);
        $this->assertContains($mutationId, collect($asetHistory->json('data'))->pluck('id')->all());

        // 4. Kadiv yang memproses -> DAPAT MELIHAT via statusHistories
        $kadivHistory = $this->actingAs($this->kadiv)->getJson('/api/v1/mutations?view=history');
        $kadivHistory->assertStatus(200);
        $this->assertContains($mutationId, collect($kadivHistory->json('data'))->pluck('id')->all());

        // 5. Admin -> DAPAT MELIHAT SELURUH MUTASI
        $adminHistory = $this->actingAs($this->admin)->getJson('/api/v1/mutations?view=history');
        $adminHistory->assertStatus(200);
        $this->assertContains($mutationId, collect($adminHistory->json('data'))->pluck('id')->all());

        // ─── C. Cek Detail Endpoint (GET /mutations/{id}) ─────────────────────
        $rolesToTest = [
            'pemohon' => $this->pemohon,
            'operator' => $this->operator,
            'bagian_aset' => $this->bagianAset,
            'kadiv' => $this->kadiv,
            'admin' => $this->admin,
        ];

        foreach ($rolesToTest as $name => $user) {
            $showRes = $this->actingAs($user)->getJson("/api/v1/mutations/{$mutationId}");
            $showRes->assertStatus(200)
                ->assertJson([
                    'success' => true,
                    'data' => [
                        'id' => $mutationId,
                        'status' => 'selesai',
                    ],
                ]);
        }
    }
}
