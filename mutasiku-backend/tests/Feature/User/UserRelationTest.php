<?php

namespace Tests\Feature\User;

use App\Models\Asset;
use App\Models\AssetCategory;
use App\Models\Location;
use App\Models\Mutation;
use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserRelationTest extends TestCase
{
    use RefreshDatabase;

    private function createRole(string $name = 'pemohon'): Role
    {
        return Role::firstOrCreate(['name' => $name]);
    }

    private function createUser(string $roleName = 'pemohon'): User
    {
        $role = $this->createRole($roleName);

        return User::factory()->create([
            'role_id' => $role->id,
            'is_active' => true,
        ]);
    }

    private function createAsset(User $pic): Asset
    {
        $location = Location::firstOrCreate(
            ['code' => 'KP'],
            ['name' => 'Kantor Pusat', 'is_active' => true]
        );

        $category = AssetCategory::firstOrCreate(
            ['code' => 'TI'],
            ['name' => 'Aset TI']
        );

        return Asset::create([
            'asset_code' => 'AST-'.uniqid(),
            'name' => 'Laptop Lenovo',
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

    private function createMutation(User $applicant, ?User $targetPic = null): Mutation
    {
        $asset = $this->createAsset($applicant);
        $loc1 = Location::firstOrCreate(['code' => 'GA'], ['name' => 'Gedung A', 'is_active' => true]);
        $loc2 = Location::firstOrCreate(['code' => 'GB'], ['name' => 'Gedung B', 'is_active' => true]);

        return Mutation::create([
            'ticket_number' => 'TI-2026-'.uniqid(),
            'asset_id' => $asset->id,
            'applicant_id' => $applicant->id,
            'origin_location_id' => $loc1->id,
            'destination_location_id' => $loc2->id,
            'current_pic_id' => $applicant->id,
            'target_pic_id' => $targetPic?->id ?? $applicant->id,
            'is_asset_moves_with_applicant' => true,
            'reason' => 'Alasan mutasi',
            'sk_document' => 'documents/sk_sdm/sk.pdf',
            'status' => 'diajukan',
        ]);
    }

    public function test_user_has_many_mutations_as_applicant(): void
    {
        $user1 = $this->createUser('pemohon');
        $user2 = $this->createUser('pemohon');

        $mutation1 = $this->createMutation($user1);
        $mutation2 = $this->createMutation($user1);
        $mutation3 = $this->createMutation($user2);

        // Pastikan tipe relasi adalah HasMany dengan foreign key applicant_id
        $relation = $user1->mutations();
        $this->assertInstanceOf(HasMany::class, $relation);
        $this->assertEquals('applicant_id', $relation->getForeignKeyName());

        // Pastikan koleksi yang dikembalikan hanya berisi mutasi milik user1
        $user1Mutations = $user1->mutations;
        $this->assertCount(2, $user1Mutations);
        $this->assertTrue($user1Mutations->contains($mutation1));
        $this->assertTrue($user1Mutations->contains($mutation2));
        $this->assertFalse($user1Mutations->contains($mutation3));

        // Pastikan user2 hanya memiliki mutation3
        $this->assertCount(1, $user2->mutations);
        $this->assertTrue($user2->mutations->contains($mutation3));
    }

    public function test_user_mutations_relation_only_loads_mutations_where_user_is_applicant(): void
    {
        $userA = $this->createUser('pemohon');
        $userB = $this->createUser('pemohon');

        // User A sebagai pemohon
        $mutationApplicantA = $this->createMutation($userA);

        // User B sebagai pemohon, tapi User A sebagai target_pic
        $mutationTargetPicA = $this->createMutation($userB, $userA);

        $this->assertEquals($userA->id, $mutationTargetPicA->target_pic_id);
        $this->assertEquals($userB->id, $mutationTargetPicA->applicant_id);

        // Relasi $userA->mutations HANYA memuat mutasi di mana userA bertindak sebagai applicant
        $userAMutations = $userA->mutations;
        $this->assertCount(1, $userAMutations);
        $this->assertTrue($userAMutations->contains($mutationApplicantA));
        $this->assertFalse($userAMutations->contains($mutationTargetPicA));
    }
}
