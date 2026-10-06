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

class MutationInvalidTransitionTest extends TestCase
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
            'name' => 'Laptop Lenovo ThinkPad',
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

    private function createMutation(User $applicant, string $status): Mutation
    {
        $asset = $this->createAsset($applicant);
        $loc1 = $this->createLocation('Gedung A', 'GA_'.uniqid());
        $loc2 = $this->createLocation('Gedung B', 'GB_'.uniqid());

        return Mutation::create([
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
        ]);
    }

    public function test_operator_verify_rejected_for_all_non_diajukan_statuses(): void
    {
        $operator = $this->createUser('operator');
        $pemohon = $this->createUser('pemohon');
        $token = $operator->createToken('test')->plainTextToken;

        $invalidStatuses = [
            'menunggu_verifikasi_bagian_aset',
            'dikembalikan_ke_pemohon',
            'menunggu_approval_pemimpin_divisi',
            'menunggu_konfirmasi_pemohon',
            'ditolak',
            'selesai',
        ];

        foreach ($invalidStatuses as $status) {
            $mutation = $this->createMutation($pemohon, $status);

            $response = $this->withHeader('Authorization', 'Bearer '.$token)
                ->postJson("/api/v1/mutations/{$mutation->id}/verify", ['action' => 'verify']);

            $response->assertStatus(409);
        }
    }

    public function test_bagian_aset_verify_rejected_for_all_non_waiting_asset_statuses(): void
    {
        $bagianAset = $this->createUser('bagian_aset');
        $pemohon = $this->createUser('pemohon');
        $token = $bagianAset->createToken('test')->plainTextToken;

        $invalidStatuses = [
            'diajukan',
            'dikembalikan_ke_pemohon',
            'menunggu_approval_pemimpin_divisi',
            'menunggu_konfirmasi_pemohon',
            'ditolak',
            'selesai',
        ];

        foreach ($invalidStatuses as $status) {
            $mutation = $this->createMutation($pemohon, $status);

            $response = $this->withHeader('Authorization', 'Bearer '.$token)
                ->postJson("/api/v1/mutations/{$mutation->id}/verify-asset", ['action' => 'verify']);

            $response->assertStatus(409);
        }
    }

    public function test_pemimpin_divisi_approve_rejected_for_all_non_waiting_approval_statuses(): void
    {
        $kadiv = $this->createUser('pemimpin_divisi');
        $pemohon = $this->createUser('pemohon');
        $token = $kadiv->createToken('test')->plainTextToken;

        $invalidStatuses = [
            'diajukan',
            'menunggu_verifikasi_bagian_aset',
            'dikembalikan_ke_pemohon',
            'menunggu_konfirmasi_pemohon',
            'ditolak',
            'selesai',
        ];

        foreach ($invalidStatuses as $status) {
            $mutation = $this->createMutation($pemohon, $status);

            $response = $this->withHeader('Authorization', 'Bearer '.$token)
                ->postJson("/api/v1/mutations/{$mutation->id}/approve", ['action' => 'approve']);

            $response->assertStatus(409);
        }
    }

    public function test_pemohon_confirm_rejected_for_all_non_waiting_confirmation_statuses(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;

        $invalidStatuses = [
            'diajukan',
            'menunggu_verifikasi_bagian_aset',
            'dikembalikan_ke_pemohon',
            'menunggu_approval_pemimpin_divisi',
            'ditolak',
            'selesai',
        ];

        foreach ($invalidStatuses as $status) {
            $mutation = $this->createMutation($pemohon, $status);

            $response = $this->withHeader('Authorization', 'Bearer '.$token)
                ->postJson("/api/v1/mutations/{$mutation->id}/confirm", ['confirmation' => 'sesuai']);

            $response->assertStatus(409);
        }
    }

    public function test_pemohon_resubmit_rejected_for_all_non_returned_statuses(): void
    {
        $pemohon = $this->createUser('pemohon');
        $token = $pemohon->createToken('test')->plainTextToken;

        $invalidStatuses = [
            'diajukan',
            'menunggu_verifikasi_bagian_aset',
            'menunggu_approval_pemimpin_divisi',
            'menunggu_konfirmasi_pemohon',
            'ditolak',
            'selesai',
        ];

        foreach ($invalidStatuses as $status) {
            $mutation = $this->createMutation($pemohon, $status);

            $response = $this->withHeader('Authorization', 'Bearer '.$token)
                ->postJson("/api/v1/mutations/{$mutation->id}/resubmit", ['reason' => 'Perbaikan']);

            $response->assertStatus(409);
        }
    }
}
