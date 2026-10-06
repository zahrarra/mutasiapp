<?php

namespace Tests\Feature\Mutation;

use App\Models\Asset;
use App\Models\AssetCategory;
use App\Models\Location;
use App\Models\Mutation;
use App\Models\MutationStatusHistory;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MutationWorkflowHistoryTest extends TestCase
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
            'sk_document' => 'SK.pdf',
            'status' => $status,
        ]);
    }

    public function test_operator_verify_records_operator_status_history(): void
    {
        $operator = $this->createUser('operator');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'diajukan');

        $token = $operator->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify", [
                'action' => 'verify',
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('mutation_status_histories', [
            'mutation_id' => $mutation->id,
            'user_id' => $operator->id,
            'role' => 'operator',
            'action' => 'verify',
            'status_from' => 'diajukan',
            'status_to' => 'menunggu_verifikasi_bagian_aset',
        ]);
    }

    public function test_bagian_aset_verify_records_bagian_aset_status_history(): void
    {
        $bagianAset = $this->createUser('bagian_aset');
        $pemohon = $this->createUser('pemohon');
        $targetPic = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_verifikasi_bagian_aset');

        $token = $bagianAset->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify-asset", [
                'action' => 'verify',
                'target_pic_id' => $targetPic->id,
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('mutation_status_histories', [
            'mutation_id' => $mutation->id,
            'user_id' => $bagianAset->id,
            'role' => 'bagian_aset',
            'action' => 'verify_asset',
            'status_from' => 'menunggu_verifikasi_bagian_aset',
            'status_to' => 'menunggu_approval_pemimpin_divisi',
        ]);
    }

    public function test_pemimpin_divisi_approve_records_pemimpin_divisi_status_history(): void
    {
        $pemimpinDivisi = $this->createUser('pemimpin_divisi');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_approval_pemimpin_divisi');

        $token = $pemimpinDivisi->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/approve", [
                'action' => 'approve',
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('mutation_status_histories', [
            'mutation_id' => $mutation->id,
            'user_id' => $pemimpinDivisi->id,
            'role' => 'pemimpin_divisi',
            'action' => 'approve',
            'status_from' => 'menunggu_approval_pemimpin_divisi',
            'status_to' => 'menunggu_konfirmasi_pemohon',
        ]);
    }

    public function test_pemohon_resubmit_records_pemohon_status_history(): void
    {
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'dikembalikan_ke_pemohon');

        $token = $pemohon->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/resubmit", [
                'reason' => 'Perbaikan data dan dokumen pendukung',
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('mutation_status_histories', [
            'mutation_id' => $mutation->id,
            'user_id' => $pemohon->id,
            'role' => 'pemohon',
            'action' => 'resubmit',
            'status_from' => 'dikembalikan_ke_pemohon',
            'status_to' => 'menunggu_verifikasi_bagian_aset',
            'notes' => 'Perbaikan data dan dokumen pendukung',
        ]);
    }

    public function test_bagian_aset_return_to_pemohon_still_shows_in_bagian_aset_history(): void
    {
        $bagianAset = $this->createUser('bagian_aset');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_verifikasi_bagian_aset');

        $token = $bagianAset->createToken('test')->plainTextToken;

        // Bagian aset mengembalikan mutasi ke pemohon
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify-asset", [
                'action' => 'return',
                'reason' => 'Perlu revisi data aset',
            ])
            ->assertStatus(200);

        $this->assertEquals('dikembalikan_ke_pemohon', $mutation->fresh()->status);

        // Status mutasi saat ini 'dikembalikan_ke_pemohon', tapi harus tetap muncul di view=history Bagian Aset
        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/mutations?view=history');

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals($mutation->id, $response->json('data.0.id'));
    }

    public function test_pemimpin_divisi_approve_followed_by_confirm_reject_still_shows_in_pemimpin_divisi_history(): void
    {
        $pemimpinDivisi = $this->createUser('pemimpin_divisi');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_approval_pemimpin_divisi');

        $tokenKadiv = $pemimpinDivisi->createToken('test')->plainTextToken;
        $tokenPemohon = $pemohon->createToken('test')->plainTextToken;

        // Pemimpin Divisi menyetujui mutasi
        $this->withHeader('Authorization', 'Bearer '.$tokenKadiv)
            ->postJson("/api/v1/mutations/{$mutation->id}/approve", [
                'action' => 'approve',
            ])
            ->assertStatus(200);

        // Pemohon melaporkan tidak sesuai -> status mundur kembali ke 'menunggu_verifikasi_bagian_aset'
        $this->app['auth']->forgetGuards();
        $this->withHeader('Authorization', 'Bearer '.$tokenPemohon)
            ->postJson("/api/v1/mutations/{$mutation->id}/confirm", [
                'confirmation' => 'tidak_sesuai',
                'reason' => 'Fisik tidak sesuai deskripsi',
            ])
            ->assertStatus(200);

        $this->assertEquals('menunggu_verifikasi_bagian_aset', $mutation->fresh()->status);

        // Meskipun status saat ini menunggu_verifikasi_bagian_aset, mutasi tetap harus muncul di history Pemimpin Divisi
        $this->app['auth']->forgetGuards();
        $response = $this->withHeader('Authorization', 'Bearer '.$tokenKadiv)
            ->getJson('/api/v1/mutations?view=history');

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals($mutation->id, $response->json('data.0.id'));
    }

    public function test_view_queue_and_view_history_behave_correctly(): void
    {
        $operator = $this->createUser('operator');
        $pemohon = $this->createUser('pemohon');

        $token = $operator->createToken('test')->plainTextToken;

        // Mutasi 1: Belum diproses Operator (antrean aktif)
        $mutQueue = $this->createMutation($pemohon, 'diajukan');

        // Mutasi 2: Pernah diproses Operator
        $mutHistory = $this->createMutation($pemohon, 'diajukan');
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutHistory->id}/verify", ['action' => 'verify'])
            ->assertStatus(200);

        // Queue hanya menampilkan mutasi yang belum diproses (diajukan)
        $queueResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/mutations?view=queue');
        $queueResponse->assertStatus(200);
        $this->assertCount(1, $queueResponse->json('data'));
        $this->assertEquals($mutQueue->id, $queueResponse->json('data.0.id'));

        // History hanya menampilkan mutasi yang sudah diproses oleh operator
        $historyResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/mutations?view=history');
        $historyResponse->assertStatus(200);
        $this->assertCount(1, $historyResponse->json('data'));
        $this->assertEquals($mutHistory->id, $historyResponse->json('data.0.id'));
    }
}
