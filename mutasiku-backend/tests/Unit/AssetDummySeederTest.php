<?php

namespace Tests\Unit;

use App\Models\Asset;
use Database\Seeders\DatabaseSeeder;
use Database\Seeders\PemohonTestingAssetSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AssetDummySeederTest extends TestCase
{
    use RefreshDatabase;
    public function test_dummy_assets_have_exactly_20_assets_with_10_ti_and_10_umum(): void
    {
        $this->seed(DatabaseSeeder::class);

        $totalAssets = Asset::count();
        $this->assertEquals(20, $totalAssets, 'Total aset dummy harus tepat 20 aset.');

        $tiCount = Asset::whereHas('category', fn ($q) => $q->where('code', 'TI'))->count();
        $this->assertEquals(10, $tiCount, 'Aset TI harus tepat 10.');

        $umCount = Asset::whereHas('category', fn ($q) => $q->where('code', 'UM'))->count();
        $this->assertEquals(10, $umCount, 'Aset Umum harus tepat 10.');
    }

    public function test_dummy_assets_have_varied_pics(): void
    {
        $this->seed(DatabaseSeeder::class);

        $pics = Asset::with('pic')
            ->get()
            ->pluck('pic.name')
            ->unique()
            ->values();

        $this->assertGreaterThan(1, $pics->count(), 'PIC aset harus bervariasi, tidak boleh hanya 1 nama.');
        $this->assertContains('Pemohon MutasiKu', $pics->all());
        $this->assertTrue(
            $pics->contains(fn ($name) => $name !== 'Pemohon MutasiKu'),
            'Harus ada PIC selain Pemohon MutasiKu.'
        );
    }

    public function test_seeder_is_idempotent_and_does_not_duplicate(): void
    {
        // Jalankan seeder pertama kali melalui DatabaseSeeder
        $this->seed(DatabaseSeeder::class);
        $countFirst = Asset::count();

        // Jalankan seeder kedua kali
        $this->seed(PemohonTestingAssetSeeder::class);
        $countSecond = Asset::count();

        $this->assertEquals(20, $countFirst);
        $this->assertEquals(20, $countSecond, 'Seeder tidak boleh menambah aset saat dijalankan ulang.');
    }

    public function test_seeder_does_not_modify_asset_under_active_mutation(): void
    {
        $this->seed(DatabaseSeeder::class);

        $asset = Asset::where('asset_code', 'AST-TI-2026-001')->firstOrFail();

        // Buat mutasi aktif untuk aset ini
        $pemohon = \App\Models\User::where('email', 'pemohon@mutasiku.test')->firstOrFail();
        $loc = \App\Models\Location::firstOrFail();

        \App\Models\Mutation::create([
            'ticket_number' => 'TEST-ACTIVE-001',
            'asset_id' => $asset->id,
            'applicant_id' => $pemohon->id,
            'origin_location_id' => $loc->id,
            'destination_location_id' => $loc->id,
            'reason' => 'Pengujian mutasi aktif',
            'sk_document' => 'test.pdf',
            'status' => 'diajukan',
        ]);

        // Ubah atribut aset untuk mensimulasikan status berjalan
        $asset->update(['condition' => 'Dalam Proses Pemindahan']);

        // Jalankan seeder ulang
        $this->seed(PemohonTestingAssetSeeder::class);

        // Aset tidak boleh ditimpa kembali ke 'Baik'
        $asset->refresh();
        $this->assertEquals('Dalam Proses Pemindahan', $asset->condition, 'Aset dengan mutasi aktif tidak boleh ditimpa seeder.');
    }

    public function test_seeder_does_not_delete_real_assets(): void
    {
        $this->seed(DatabaseSeeder::class);

        $cat = \App\Models\AssetCategory::firstOrFail();
        $loc = \App\Models\Location::firstOrFail();
        $user = \App\Models\User::firstOrFail();

        // Buat aset nyata
        $realAsset = Asset::create([
            'asset_code' => 'KANTOR-PUSAT-001',
            'name' => 'Server Produksi Utama',
            'asset_category_id' => $cat->id,
            'location_id' => $loc->id,
            'pic_id' => $user->id,
            'condition' => 'Baik',
            'serial_number' => 'REAL-SRV-999',
            'acquisition_year' => 2025,
            'usage_year' => 2025,
            'is_active' => true,
        ]);

        // Jalankan seeder ulang
        $this->seed(PemohonTestingAssetSeeder::class);

        // Aset nyata harus tetap ada di database
        $this->assertDatabaseHas('assets', ['asset_code' => 'KANTOR-PUSAT-001']);
    }
}
