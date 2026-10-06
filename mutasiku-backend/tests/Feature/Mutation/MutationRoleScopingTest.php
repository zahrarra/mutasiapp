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

class MutationRoleScopingTest extends TestCase
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

    // ─── GET /mutations Scoping Tests ─────────────────────────────────────────

    public function test_pemohon_only_sees_their_own_mutations(): void
    {
        $pemohon1 = $this->createUser('pemohon', 'pemohon1@mutasiku.test');
        $pemohon2 = $this->createUser('pemohon', 'pemohon2@mutasiku.test');

        $mut1 = $this->createMutation($pemohon1, 'diajukan');
        $mut2 = $this->createMutation($pemohon2, 'diajukan');

        $token1 = $pemohon1->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token1)
            ->getJson('/api/v1/mutations');

        $response->assertStatus(200);
        $data = $response->json('data');

        $this->assertCount(1, $data);
        $this->assertEquals($mut1->id, $data[0]['id']);
        $this->assertEquals($pemohon1->id, $data[0]['applicant_id']);
    }

    public function test_operator_only_sees_mutations_with_status_diajukan(): void
    {
        $operator = $this->createUser('operator');
        $pemohon = $this->createUser('pemohon');

        $mutDiajukan = $this->createMutation($pemohon, 'diajukan');
        $mutVerifAset = $this->createMutation($pemohon, 'menunggu_verifikasi_bagian_aset');
        $mutSelesai = $this->createMutation($pemohon, 'selesai');

        $token = $operator->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/mutations');

        $response->assertStatus(200);
        $data = $response->json('data');

        $this->assertCount(1, $data);
        $this->assertEquals($mutDiajukan->id, $data[0]['id']);
        $this->assertEquals('diajukan', $data[0]['status']);
    }

    public function test_bagian_aset_only_sees_mutations_waiting_asset_verification(): void
    {
        $bagianAset = $this->createUser('bagian_aset');
        $pemohon = $this->createUser('pemohon');

        $mutDiajukan = $this->createMutation($pemohon, 'diajukan');
        $mutVerifAset = $this->createMutation($pemohon, 'menunggu_verifikasi_bagian_aset');
        $mutKadiv = $this->createMutation($pemohon, 'menunggu_approval_pemimpin_divisi');

        $token = $bagianAset->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/mutations');

        $response->assertStatus(200);
        $data = $response->json('data');

        $this->assertCount(1, $data);
        $this->assertEquals($mutVerifAset->id, $data[0]['id']);
        $this->assertEquals('menunggu_verifikasi_bagian_aset', $data[0]['status']);
    }

    public function test_pemimpin_divisi_only_sees_mutations_waiting_division_approval(): void
    {
        $pemimpinDivisi = $this->createUser('pemimpin_divisi');
        $pemohon = $this->createUser('pemohon');

        $mutDiajukan = $this->createMutation($pemohon, 'diajukan');
        $mutKadiv = $this->createMutation($pemohon, 'menunggu_approval_pemimpin_divisi');
        $mutSelesai = $this->createMutation($pemohon, 'selesai');

        $token = $pemimpinDivisi->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/mutations');

        $response->assertStatus(200);
        $data = $response->json('data');

        $this->assertCount(1, $data);
        $this->assertEquals($mutKadiv->id, $data[0]['id']);
        $this->assertEquals('menunggu_approval_pemimpin_divisi', $data[0]['status']);
    }

    public function test_admin_can_view_all_mutations(): void
    {
        $admin = $this->createUser('admin');
        $pemohon = $this->createUser('pemohon');

        $this->createMutation($pemohon, 'diajukan');
        $this->createMutation($pemohon, 'menunggu_verifikasi_bagian_aset');
        $this->createMutation($pemohon, 'menunggu_approval_pemimpin_divisi');
        $this->createMutation($pemohon, 'selesai');

        $token = $admin->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/mutations');

        $response->assertStatus(200);
        $this->assertCount(4, $response->json('data'));
    }

    // ─── GET /mutations/{id} Authorization Tests ─────────────────────────────

    public function test_pemohon_can_view_detail_of_their_own_mutation(): void
    {
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'diajukan');
        $token = $pemohon->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/mutations/'.$mutation->id);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $mutation->id,
                    'applicant_id' => $pemohon->id,
                ],
            ]);
    }

    public function test_pemohon_cannot_view_detail_of_another_users_mutation(): void
    {
        $pemohon1 = $this->createUser('pemohon');
        $pemohon2 = $this->createUser('pemohon');
        $mutationMilikePemohon2 = $this->createMutation($pemohon2, 'diajukan');

        $token1 = $pemohon1->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token1)
            ->getJson('/api/v1/mutations/'.$mutationMilikePemohon2->id);

        $response->assertStatus(403);
    }

    public function test_operator_can_view_detail_of_diajukan_mutation(): void
    {
        $operator = $this->createUser('operator');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'diajukan');

        $token = $operator->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/mutations/'.$mutation->id);

        $response->assertStatus(200);
    }

    public function test_operator_cannot_view_detail_of_mutation_outside_their_flow(): void
    {
        $operator = $this->createUser('operator');
        $pemohon = $this->createUser('pemohon');
        $mutation = $this->createMutation($pemohon, 'menunggu_verifikasi_bagian_aset');

        $token = $operator->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/mutations/'.$mutation->id);

        $response->assertStatus(403);
    }

    public function test_mutation_detail_returns_404_when_not_found(): void
    {
        $admin = $this->createUser('admin');
        $token = $admin->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/mutations/99999');

        $response->assertStatus(404);
    }

    public function test_unauthenticated_access_is_rejected_on_all_mutation_endpoints(): void
    {
        $this->getJson('/api/v1/mutations')->assertStatus(401);
        $this->postJson('/api/v1/mutations', [])->assertStatus(401);
        $this->getJson('/api/v1/mutations/1')->assertStatus(401);
    }
}
