<?php

namespace Tests\Feature\Notification;

use App\Models\Asset;
use App\Models\AssetCategory;
use App\Models\Location;
use App\Models\Mutation;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AutomaticMutationNotificationTest extends TestCase
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

    public function test_pemohon_submits_mutation_notifies_operator(): void
    {
        $operator = $this->createUser('operator');
        $pemohon = $this->createUser('pemohon');
        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation('Gedung C', 'GC_'.uniqid());

        $token = $pemohon->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/mutations', [
                'asset_id' => $asset->id,
                'destination_location_id' => $destLocation->id,
                'is_asset_moves_with_applicant' => true,
                'reason' => 'Pindah tugas ke divisi baru',
                'sk_document' => 'SK-01.pdf',
            ]);

        $response->assertStatus(201);
        $mutationId = $response->json('data.id');

        // Operator harus menerima notifikasi
        $this->assertEquals(1, $operator->notifications()->count());
        $notif = $operator->notifications()->first();
        $this->assertEquals('Pengajuan Mutasi Baru', $notif->data['title']);
        $this->assertEquals($mutationId, $notif->data['mutation_id']);
        $this->assertEquals('diajukan', $notif->data['status']);
        $this->assertEquals('store', $notif->data['action']);

        // Pemohon sendiri tidak menerima notifikasi tahap ini
        $this->assertEquals(0, $pemohon->notifications()->count());
    }

    public function test_operator_verify_forward_notifies_bagian_aset(): void
    {
        $operator = $this->createUser('operator');
        $bagianAset = $this->createUser('bagian_aset');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'diajukan');

        $token = $operator->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify", [
                'action' => 'verify',
                'reason' => 'Dokumen lengkap dan valid',
            ]);

        $response->assertStatus(200);

        // Bagian aset menerima notifikasi
        $this->assertEquals(1, $bagianAset->notifications()->count());
        $notif = $bagianAset->notifications()->first();
        $this->assertEquals('Menunggu Verifikasi Bagian Aset', $notif->data['title']);
        $this->assertEquals($mutation->id, $notif->data['mutation_id']);
        $this->assertEquals('menunggu_verifikasi_bagian_aset', $notif->data['status']);
        $this->assertEquals('verify', $notif->data['action']);

        // Pemohon & operator tidak menerima
        $this->assertEquals(0, $pemohon->notifications()->count());
        $this->assertEquals(0, $operator->notifications()->count());
    }

    public function test_operator_return_notifies_pemohon(): void
    {
        $operator = $this->createUser('operator');
        $bagianAset = $this->createUser('bagian_aset');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'diajukan');

        $token = $operator->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify", [
                'action' => 'return',
                'reason' => 'Lampiran SK tidak terbaca',
            ]);

        $response->assertStatus(200);

        // Pemohon menerima notifikasi
        $this->assertEquals(1, $pemohon->notifications()->count());
        $notif = $pemohon->notifications()->first();
        $this->assertEquals('Pengajuan Mutasi Dikembalikan', $notif->data['title']);
        $this->assertEquals($mutation->id, $notif->data['mutation_id']);
        $this->assertEquals('dikembalikan_ke_pemohon', $notif->data['status']);
        $this->assertEquals('return', $notif->data['action']);
        $this->assertStringContainsString('Lampiran SK tidak terbaca', $notif->data['message']);

        // Bagian aset tidak menerima
        $this->assertEquals(0, $bagianAset->notifications()->count());
    }

    public function test_bagian_aset_verify_forward_notifies_pemimpin_divisi(): void
    {
        $bagianAset = $this->createUser('bagian_aset');
        $pemimpinDivisi = $this->createUser('pemimpin_divisi');
        $pemohon = $this->createUser('pemohon');
        $targetPic = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_verifikasi_bagian_aset');

        $token = $bagianAset->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify-asset", [
                'action' => 'verify',
                'target_pic_id' => $targetPic->id,
                'reason' => 'Aset fisik telah diperiksa',
            ]);

        $response->assertStatus(200);

        // Pemimpin divisi menerima notifikasi
        $this->assertEquals(1, $pemimpinDivisi->notifications()->count());
        $notif = $pemimpinDivisi->notifications()->first();
        $this->assertEquals('Menunggu Approval Pemimpin Divisi', $notif->data['title']);
        $this->assertEquals($mutation->id, $notif->data['mutation_id']);
        $this->assertEquals('menunggu_approval_pemimpin_divisi', $notif->data['status']);
        $this->assertEquals('verify_asset', $notif->data['action']);

        // Pemohon tidak menerima
        $this->assertEquals(0, $pemohon->notifications()->count());
    }

    public function test_bagian_aset_return_notifies_pemohon(): void
    {
        $bagianAset = $this->createUser('bagian_aset');
        $pemimpinDivisi = $this->createUser('pemimpin_divisi');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_verifikasi_bagian_aset');

        $token = $bagianAset->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/verify-asset", [
                'action' => 'return',
                'reason' => 'Kondisi fisik aset rusak ringan butuh servis',
            ]);

        $response->assertStatus(200);

        // Pemohon menerima notifikasi
        $this->assertEquals(1, $pemohon->notifications()->count());
        $notif = $pemohon->notifications()->first();
        $this->assertEquals('Pengajuan Mutasi Dikembalikan', $notif->data['title']);
        $this->assertEquals($mutation->id, $notif->data['mutation_id']);
        $this->assertEquals('dikembalikan_ke_pemohon', $notif->data['status']);
        $this->assertEquals('return', $notif->data['action']);

        // Pemimpin divisi tidak menerima
        $this->assertEquals(0, $pemimpinDivisi->notifications()->count());
    }

    public function test_pemimpin_divisi_approve_notifies_pemohon(): void
    {
        $pemimpinDivisi = $this->createUser('pemimpin_divisi');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_approval_pemimpin_divisi');

        $token = $pemimpinDivisi->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/approve", [
                'action' => 'approve',
                'reason' => 'Disetujui',
            ]);

        $response->assertStatus(200);

        // Pemohon menerima notifikasi untuk konfirmasi
        $this->assertEquals(1, $pemohon->notifications()->count());
        $notif = $pemohon->notifications()->first();
        $this->assertEquals('Mutasi Disetujui - Menunggu Konfirmasi Pemohon', $notif->data['title']);
        $this->assertEquals($mutation->id, $notif->data['mutation_id']);
        $this->assertEquals('menunggu_konfirmasi_pemohon', $notif->data['status']);
        $this->assertEquals('approve', $notif->data['action']);
    }

    public function test_pemimpin_divisi_reject_notifies_pemohon(): void
    {
        $pemimpinDivisi = $this->createUser('pemimpin_divisi');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_approval_pemimpin_divisi');

        $token = $pemimpinDivisi->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/approve", [
                'action' => 'reject',
                'reason' => 'Kebutuhan aset di unit lama masih tinggi',
            ]);

        $response->assertStatus(200);

        // Pemohon menerima notifikasi penolakan
        $this->assertEquals(1, $pemohon->notifications()->count());
        $notif = $pemohon->notifications()->first();
        $this->assertEquals('Pengajuan Mutasi Ditolak', $notif->data['title']);
        $this->assertEquals($mutation->id, $notif->data['mutation_id']);
        $this->assertEquals('ditolak', $notif->data['status']);
        $this->assertEquals('reject', $notif->data['action']);
    }

    public function test_pemohon_confirm_sesuai_notifies_pemohon_mutasi_selesai(): void
    {
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_konfirmasi_pemohon');

        $token = $pemohon->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/confirm", [
                'confirmation' => 'sesuai',
                'reason' => 'Barang diterima dalam kondisi baik',
            ]);

        $response->assertStatus(200);

        // Pemohon menerima notifikasi mutasi selesai
        $this->assertEquals(1, $pemohon->notifications()->count());
        $notif = $pemohon->notifications()->first();
        $this->assertEquals('Mutasi Selesai', $notif->data['title']);
        $this->assertEquals($mutation->id, $notif->data['mutation_id']);
        $this->assertEquals('selesai', $notif->data['status']);
        $this->assertEquals('confirm_sesuai', $notif->data['action']);
    }

    public function test_pemohon_confirm_tidak_sesuai_notifies_bagian_aset(): void
    {
        $bagianAset = $this->createUser('bagian_aset');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_konfirmasi_pemohon');

        $token = $pemohon->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/confirm", [
                'confirmation' => 'tidak_sesuai',
                'reason' => 'Nomor seri tidak cocok dengan fisik',
            ]);

        $response->assertStatus(200);

        // Bagian aset menerima notifikasi
        $this->assertEquals(1, $bagianAset->notifications()->count());
        $notif = $bagianAset->notifications()->first();
        $this->assertEquals('Konfirmasi Fisik Tidak Sesuai', $notif->data['title']);
        $this->assertEquals($mutation->id, $notif->data['mutation_id']);
        $this->assertEquals('menunggu_verifikasi_bagian_aset', $notif->data['status']);
        $this->assertEquals('confirm_tidak_sesuai', $notif->data['action']);

        // Pemohon tidak menerima notifikasi aksi ini
        $this->assertEquals(0, $pemohon->notifications()->count());
    }

    public function test_pemohon_resubmit_notifies_bagian_aset(): void
    {
        $bagianAset = $this->createUser('bagian_aset');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'dikembalikan_ke_pemohon');
        $newLoc = $this->createLocation('Gedung Baru', 'GBARU_'.uniqid());

        $token = $pemohon->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/mutations/{$mutation->id}/resubmit", [
                'destination_location_id' => $newLoc->id,
                'reason' => 'Sudah diperbaiki lokasi tujuan',
            ]);

        $response->assertStatus(200);

        // Bagian aset menerima notifikasi pengajuan ulang
        $this->assertEquals(1, $bagianAset->notifications()->count());
        $notif = $bagianAset->notifications()->first();
        $this->assertEquals('Pengajuan Ulang Mutasi', $notif->data['title']);
        $this->assertEquals($mutation->id, $notif->data['mutation_id']);
        $this->assertEquals('menunggu_verifikasi_bagian_aset', $notif->data['status']);
        $this->assertEquals('resubmit', $notif->data['action']);

        // Pemohon tidak menerima
        $this->assertEquals(0, $pemohon->notifications()->count());
    }

    public function test_generated_notifications_are_retrievable_via_api(): void
    {
        $operator = $this->createUser('operator');
        $pemohon = $this->createUser('pemohon');
        $asset = $this->createAsset($pemohon);
        $destLocation = $this->createLocation('Gedung D', 'GD_'.uniqid());

        $tokenPemohon = $pemohon->createToken('test')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer '.$tokenPemohon)
            ->postJson('/api/v1/mutations', [
                'asset_id' => $asset->id,
                'destination_location_id' => $destLocation->id,
                'is_asset_moves_with_applicant' => true,
                'reason' => 'Pindah tugas',
                'sk_document' => 'SK.pdf',
            ])
            ->assertStatus(201);

        // Reset auth context
        $this->app['auth']->forgetGuards();

        $tokenOperator = $operator->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$tokenOperator)
            ->getJson('/api/v1/notifications');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Daftar notifikasi berhasil diambil.',
            ])
            ->assertJsonCount(1, 'data');

        $item = $response->json('data.0');
        $this->assertEquals('Pengajuan Mutasi Baru', $item['data']['title']);
        $this->assertEquals('diajukan', $item['data']['status']);
        $this->assertEquals('store', $item['data']['action']);
        $this->assertFalse($item['is_read']);
    }
}
