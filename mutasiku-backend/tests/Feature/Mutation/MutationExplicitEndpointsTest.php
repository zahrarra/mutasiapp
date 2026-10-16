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

class MutationExplicitEndpointsTest extends TestCase
{
    use RefreshDatabase;

    private function createRole(string $name): Role
    {
        return Role::firstOrCreate(['name' => $name]);
    }

    private function createUser(string $roleName, array $attributes = []): User
    {
        $role = $this->createRole($roleName);

        return User::factory()->create(array_merge([
            'email' => "{$roleName}_".uniqid().'@mutasiku.test',
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

    public function test_operator_forward_endpoint_success(): void
    {
        $pemohon = $this->createUser('pemohon');
        $operator = $this->createUser('operator');
        $mutation = $this->createMutation($pemohon, 'diajukan');

        $token = $operator->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/forward");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'menunggu_verifikasi_bagian_aset',
                ],
            ]);

        $this->assertEquals('menunggu_verifikasi_bagian_aset', $mutation->fresh()->status);
        $this->assertDatabaseHas('mutation_status_histories', [
            'mutation_id' => $mutation->id,
            'action' => 'forward',
            'status_to' => 'menunggu_verifikasi_bagian_aset',
        ]);
    }

    public function test_operator_return_endpoint_forbidden(): void
    {
        $pemohon = $this->createUser('pemohon');
        $operator = $this->createUser('operator');
        $mutation = $this->createMutation($pemohon, 'diajukan');

        $token = $operator->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/return-by-operator", [
                'reason' => 'Dokumen lampiran SK kurang jelas.',
            ]);

        $response->assertStatus(403);
        $this->assertEquals('diajukan', $mutation->fresh()->status);
    }

    public function test_bagian_aset_return_endpoint_is_forbidden(): void
    {
        $pemohon = $this->createUser('pemohon');
        $bagianAset = $this->createUser('bagian_aset');
        $mutation = $this->createMutation($pemohon, 'menunggu_verifikasi_bagian_aset');

        $token = $bagianAset->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/return-by-asset", [
                'reason' => 'Nomor seri aset tidak cocok dengan fisik.',
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Bagian Aset tidak memiliki kewenangan untuk mengembalikan atau menolak pengajuan mutasi.',
            ]);
    }

    public function test_bagian_aset_reject_endpoint_success(): void
    {
        $pemohon = $this->createUser('pemohon');
        $bagianAset = $this->createUser('bagian_aset');
        $kadiv = $this->createUser('pemimpin_divisi');
        $mutation = $this->createMutation($pemohon, 'menunggu_verifikasi_bagian_aset');

        $token = $bagianAset->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/reject-by-asset", [
                'reason' => 'Aset rusak berat dan tidak layak dimutasi.',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'ditolak',
                    'rejection_reason' => 'Aset rusak berat dan tidak layak dimutasi.',
                    'rejected_by' => $bagianAset->name,
                    'rejected_by_id' => $bagianAset->id,
                    'rejected_by_role' => 'bagian_aset',
                    'asset_rejected_by' => $bagianAset->name,
                    'kadiv_rejected_by' => null,
                ],
            ]);

        $fresh = $mutation->fresh();
        $this->assertEquals('ditolak', $fresh->status);
        $this->assertEquals('Aset rusak berat dan tidak layak dimutasi.', $fresh->rejection_reason);
        $this->assertNotNull($fresh->rejected_at);
        $this->assertEquals($bagianAset->id, $fresh->rejected_by);

        // Riwayat mencatat role bagian_aset dengan action reject
        $lastHistory = $fresh->statusHistories()->latest('id')->first();
        $this->assertEquals('bagian_aset', $lastHistory->role);
        $this->assertEquals('reject', $lastHistory->action);
        $this->assertEquals('ditolak', $lastHistory->status_to);

        // Pengajuan tidak boleh masuk atau diproses pada approval Kadiv (409 Conflict)
        $kadivResponse = $this->actingAs($kadiv)
            ->postJson("/api/v1/mutations/{$mutation->id}/approve");
        $kadivResponse->assertStatus(409);
    }

    public function test_pemimpin_divisi_reject_endpoint_success(): void
    {
        $pemohon = $this->createUser('pemohon');
        $kadiv = $this->createUser('pemimpin_divisi');
        $mutation = $this->createMutation($pemohon, 'menunggu_approval_pemimpin_divisi');

        $token = $kadiv->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/reject", [
                'reason' => 'Aset masih dibutuhkan di unit kerja asal.',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'ditolak',
                    'rejection_reason' => 'Aset masih dibutuhkan di unit kerja asal.',
                    'rejected_by' => $kadiv->name,
                    'rejected_by_id' => $kadiv->id,
                    'rejected_by_role' => 'pemimpin_divisi',
                    'asset_rejected_by' => null,
                    'kadiv_rejected_by' => $kadiv->name,
                ],
            ]);

        $fresh = $mutation->fresh();
        $this->assertEquals('ditolak', $fresh->status);
        $this->assertEquals('Aset masih dibutuhkan di unit kerja asal.', $fresh->rejection_reason);
        $this->assertNotNull($fresh->rejected_at);
        $this->assertEquals($kadiv->id, $fresh->rejected_by);

        // Riwayat mencatat role pemimpin_divisi dengan action reject
        $lastHistory = $fresh->statusHistories()->latest('id')->first();
        $this->assertEquals('pemimpin_divisi', $lastHistory->role);
        $this->assertEquals('reject', $lastHistory->action);
        $this->assertEquals('ditolak', $lastHistory->status_to);

        // Status final tidak dapat diapprove kembali (409 Conflict)
        $approveAgain = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/approve");
        $approveAgain->assertStatus(409);
    }

    public function test_pemohon_report_discrepancy_endpoint_success(): void
    {
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_konfirmasi_pemohon');

        $token = $pemohon->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/report-discrepancy", [
                'reason' => 'Kondisi barang rusak di layar saat diterima.',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'menunggu_verifikasi_bagian_aset',
                    'discrepancy_reason' => 'Kondisi barang rusak di layar saat diterima.',
                ],
            ]);

        $fresh = $mutation->fresh();
        $this->assertEquals('menunggu_verifikasi_bagian_aset', $fresh->status);
        $this->assertEquals('Kondisi barang rusak di layar saat diterima.', $fresh->discrepancy_reason);
    }

    public function test_put_update_mutation_endpoint_is_removed_and_returns_404_or_405(): void
    {
        $pemohon = $this->createUser('pemohon');
        $newLoc = $this->createLocation('Gedung Baru', 'GB_NEW');
        $mutation = $this->createMutation($pemohon, 'dikembalikan_ke_pemohon');

        $token = $pemohon->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->putJson("/api/v1/mutations/{$mutation->id}", [
                'destination_location_id' => $newLoc->id,
                'reason' => 'Perbaikan data lokasi tujuan mutasi.',
            ]);

        $this->assertTrue(in_array($response->status(), [404, 405]));

        $fresh = $mutation->fresh();
        $this->assertEquals('dikembalikan_ke_pemohon', $fresh->status);
    }

    public function test_explicit_endpoints_wrong_role_returns_403(): void
    {
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'diajukan');

        $tokenPemohon = $pemohon->createToken('test')->plainTextToken;

        // Pemohon tries operator forward
        $this->withHeader('Authorization', 'Bearer '.$tokenPemohon)
            ->postJson("/api/v1/mutations/{$mutation->id}/forward")
            ->assertStatus(403);

        // Pemohon tries operator return
        $this->withHeader('Authorization', 'Bearer '.$tokenPemohon)
            ->postJson("/api/v1/mutations/{$mutation->id}/return-by-operator", ['reason' => 'Alasan'])
            ->assertStatus(403);

        // Pemohon tries asset return
        $this->withHeader('Authorization', 'Bearer '.$tokenPemohon)
            ->postJson("/api/v1/mutations/{$mutation->id}/return-by-asset", ['reason' => 'Alasan'])
            ->assertStatus(403);

        // Pemohon tries kadiv reject
        $this->withHeader('Authorization', 'Bearer '.$tokenPemohon)
            ->postJson("/api/v1/mutations/{$mutation->id}/reject", ['reason' => 'Alasan'])
            ->assertStatus(403);
    }

    public function test_explicit_endpoints_invalid_transition_returns_409(): void
    {
        $pemohon = $this->createUser('pemohon');
        $operator = $this->createUser('operator');
        $token = $operator->createToken('test')->plainTextToken;

        // Status is already 'selesai'
        $mutation = $this->createMutation($pemohon, 'selesai');

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/forward")
            ->assertStatus(409);

        // Operator return is forbidden (403)
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/return-by-operator", ['reason' => 'Alasan'])
            ->assertStatus(403);

        // Bagian Aset return is forbidden (403)
        $bagianAset = $this->createUser('bagian_aset');
        $this->actingAs($bagianAset)
            ->postJson("/api/v1/mutations/{$mutation->id}/return-by-asset", ['reason' => 'Alasan'])
            ->assertStatus(403);
    }

    public function test_bagian_aset_cannot_return_via_verify_asset_action(): void
    {
        $pemohon = $this->createUser('pemohon');
        $bagianAset = $this->createUser('bagian_aset');
        $mutation = $this->createMutation($pemohon, 'menunggu_verifikasi_bagian_aset');

        $response = $this->actingAs($bagianAset)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify-asset", [
                'action' => 'return',
                'reason' => 'Mencoba return lewat verify-asset',
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Bagian Aset tidak memiliki kewenangan untuk mengembalikan atau menolak pengajuan mutasi.',
            ]);

        $this->assertEquals('menunggu_verifikasi_bagian_aset', $mutation->fresh()->status);
    }
}
