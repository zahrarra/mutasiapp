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

class MutationOfficerNameResolutionTest extends TestCase
{
    use RefreshDatabase;

    private function createRole(string $name): Role
    {
        return Role::firstOrCreate(['name' => $name]);
    }

    private function createUser(string $roleName, string $name, ?string $email = null): User
    {
        $role = $this->createRole($roleName);

        return User::factory()->create([
            'name' => $name,
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
            'reason' => 'Alasan mutasi kerja',
            'sk_document' => 'SK.pdf',
            'status' => $status,
        ]);
    }

    /**
     * Test verification officer name is resolved as real string name (not integer ID).
     */
    public function test_officer_names_are_returned_as_strings_not_numbers(): void
    {
        $pemohon = $this->createUser('pemohon', 'Ahmad Pemohon');
        $operator = $this->createUser('operator', 'Dirly Dwi Operator');
        $bagianAset = $this->createUser('bagian_aset', 'Siti Bagian Aset');
        $kadiv = $this->createUser('pemimpin_divisi', 'Budi Kadiv');

        $mutation = $this->createMutation($pemohon, 'diajukan');

        // 1. Operator verifies
        \Laravel\Sanctum\Sanctum::actingAs($operator);
        $verifyRes = $this->postJson("/api/v1/mutations/{$mutation->id}/verify", [
            'action' => 'verify',
        ]);

        $verifyRes->assertStatus(200);
        $verifyData = $verifyRes->json('data');

        // verified_by must be officer's name, NOT integer ID
        $this->assertEquals('Dirly Dwi Operator', $verifyData['verified_by']);
        $this->assertNotEquals($operator->id, $verifyData['verified_by']);
        $this->assertEquals($operator->id, $verifyData['verified_by_id']);

        // 2. Bagian Aset verifies asset
        \Laravel\Sanctum\Sanctum::actingAs($bagianAset);
        $assetVerifyRes = $this->postJson("/api/v1/mutations/{$mutation->id}/verify-asset", [
            'action' => 'verify',
            'target_pic_id' => $pemohon->id,
        ]);

        $assetVerifyRes->assertStatus(200);
        $assetData = $assetVerifyRes->json('data');

        $this->assertEquals('Siti Bagian Aset', $assetData['asset_verified_by']);
        $this->assertNotEquals($bagianAset->id, $assetData['asset_verified_by']);

        // 3. Kadiv approves
        \Laravel\Sanctum\Sanctum::actingAs($kadiv);
        $approveRes = $this->postJson("/api/v1/mutations/{$mutation->id}/approve", [
            'action' => 'approve',
        ]);

        $approveRes->assertStatus(200);
        $approveData = $approveRes->json('data');

        $this->assertEquals('Budi Kadiv', $approveData['approved_by']);
        $this->assertEquals('Budi Kadiv', $approveData['kadiv_approved_by']);
        $this->assertNotEquals($kadiv->id, $approveData['approved_by']);

        // 4. Detail GET check
        \Laravel\Sanctum\Sanctum::actingAs($operator);
        $detailRes = $this->getJson("/api/v1/mutations/{$mutation->id}");

        $detailRes->assertStatus(200);
        $detailData = $detailRes->json('data');

        $this->assertEquals('Dirly Dwi Operator', $detailData['verified_by']);
        $this->assertEquals('Siti Bagian Aset', $detailData['asset_verified_by']);
        $this->assertEquals('Budi Kadiv', $detailData['approved_by']);
        $this->assertEquals('Budi Kadiv', $detailData['kadiv_approved_by']);
    }
}
