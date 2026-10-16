<?php

namespace Tests\Feature\Mutation;

use App\Models\Asset;
use App\Models\AssetCategory;
use App\Models\Location;
use App\Models\Mutation;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class MutationDocumentViewTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;
    private User $pemohon;
    private User $otherPemohon;
    private User $operator;
    private User $bagianAset;
    private User $kadiv;
    private Mutation $mutationWithPdf;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');

        $roleAdmin = Role::firstOrCreate(['name' => 'admin']);
        $rolePemohon = Role::firstOrCreate(['name' => 'pemohon']);
        $roleOperator = Role::firstOrCreate(['name' => 'operator']);
        $roleAset = Role::firstOrCreate(['name' => 'bagian_aset']);
        $roleKadiv = Role::firstOrCreate(['name' => 'pemimpin_divisi']);

        $this->admin = User::factory()->create(['role_id' => $roleAdmin->id, 'email' => 'admin@test.com']);
        $this->pemohon = User::factory()->create(['role_id' => $rolePemohon->id, 'email' => 'pemohon@test.com']);
        $this->otherPemohon = User::factory()->create(['role_id' => $rolePemohon->id, 'email' => 'other_pemohon@test.com']);
        $this->operator = User::factory()->create(['role_id' => $roleOperator->id, 'email' => 'operator@test.com']);
        $this->bagianAset = User::factory()->create(['role_id' => $roleAset->id, 'email' => 'aset@test.com']);
        $this->kadiv = User::factory()->create(['role_id' => $roleKadiv->id, 'email' => 'kadiv@test.com']);

        $category = AssetCategory::firstOrCreate(['code' => 'TI'], ['name' => 'Perangkat IT']);
        $originLoc = Location::firstOrCreate(['code' => 'LOC-A'], ['name' => 'Ruang Server']);
        $destLoc = Location::firstOrCreate(['code' => 'LOC-B'], ['name' => 'Ruang Kantor']);

        $asset = Asset::create([
            'asset_code' => 'AST-'.uniqid(),
            'name' => 'Laptop ThinkPad X1',
            'asset_category_id' => $category->id,
            'location_id' => $originLoc->id,
            'pic_id' => $this->pemohon->id,
            'condition' => 'Baik',
            'serial_number' => 'SN-'.uniqid(),
            'acquisition_year' => 2024,
            'usage_year' => 2024,
            'is_active' => true,
        ]);

        // Simpan file dummy PDF di disk public
        $pdfPath = 'documents/sk_sdm/sk_resmi_mutasi.pdf';
        $dummyPdfContent = "%PDF-1.4\n1 0 obj<< /Title (SK Mutasi) >>endobj\ntrailer<<>>\n%%EOF";
        Storage::disk('public')->put($pdfPath, $dummyPdfContent);

        $this->mutationWithPdf = Mutation::create([
            'ticket_number' => 'MUT-'.uniqid(),
            'asset_id' => $asset->id,
            'applicant_id' => $this->pemohon->id,
            'origin_location_id' => $originLoc->id,
            'destination_location_id' => $destLoc->id,
            'current_pic_id' => $this->pemohon->id,
            'target_pic_id' => $this->pemohon->id,
            'is_asset_moves_with_applicant' => true,
            'reason' => 'Pindah tugas dinas.',
            'sk_document' => $pdfPath,
            'status' => 'menunggu_verifikasi_bagian_aset',
        ]);
    }

    public function test_all_five_roles_can_view_uploaded_pdf_document(): void
    {
        $id = $this->mutationWithPdf->id;

        // 1. Admin
        $resAdmin = $this->actingAs($this->admin)->get("/api/v1/mutations/{$id}/document");
        $resAdmin->assertOk();
        $resAdmin->assertHeader('Content-Disposition', 'inline; filename="sk_resmi_mutasi.pdf"');

        // 2. Pemohon (Pemilik Pengajuan)
        $resPemohon = $this->actingAs($this->pemohon)->get("/api/v1/mutations/{$id}/document");
        $resPemohon->assertOk();
        $resPemohon->assertHeader('Content-Disposition', 'inline; filename="sk_resmi_mutasi.pdf"');

        // 3. Operator
        $resOperator = $this->actingAs($this->operator)->get("/api/v1/mutations/{$id}/document");
        $resOperator->assertOk();
        $resOperator->assertHeader('Content-Disposition', 'inline; filename="sk_resmi_mutasi.pdf"');

        // 4. Bagian Aset
        $resAset = $this->actingAs($this->bagianAset)->get("/api/v1/mutations/{$id}/document");
        $resAset->assertOk();
        $resAset->assertHeader('Content-Disposition', 'inline; filename="sk_resmi_mutasi.pdf"');

        // 5. Pemimpin Divisi / Kadiv
        $resKadiv = $this->actingAs($this->kadiv)->get("/api/v1/mutations/{$id}/document");
        $resKadiv->assertOk();
        $resKadiv->assertHeader('Content-Disposition', 'inline; filename="sk_resmi_mutasi.pdf"');
    }

    public function test_other_pemohon_cannot_view_another_applicants_document(): void
    {
        $id = $this->mutationWithPdf->id;

        $response = $this->actingAs($this->otherPemohon)->get("/api/v1/mutations/{$id}/document");
        $response->assertStatus(403);
        $response->assertJson([
            'success' => false,
            'message' => 'Anda tidak memiliki hak akses untuk dokumen ini.',
        ]);
    }

    public function test_unauthenticated_request_is_rejected(): void
    {
        $id = $this->mutationWithPdf->id;

        $response = $this->getJson("/api/v1/mutations/{$id}/document");
        $response->assertStatus(401);
    }

    public function test_non_existent_mutation_returns_404(): void
    {
        $response = $this->actingAs($this->admin)->get('/api/v1/mutations/999999/document');
        $response->assertStatus(404);
        $response->assertJson([
            'success' => false,
            'message' => 'Pengajuan mutasi tidak ditemukan.',
        ]);
    }

    public function test_mutation_without_document_returns_404(): void
    {
        $this->mutationWithPdf->update(['sk_document' => '']);

        $response = $this->actingAs($this->admin)->get("/api/v1/mutations/{$this->mutationWithPdf->id}/document");
        $response->assertStatus(404);
        $response->assertJson([
            'success' => false,
            'message' => 'Dokumen tidak ditemukan untuk mutasi ini.',
        ]);
    }

    public function test_missing_physical_file_returns_404(): void
    {
        $this->mutationWithPdf->update(['sk_document' => 'documents/sk_sdm/file_hilang.pdf']);

        $response = $this->actingAs($this->admin)->get("/api/v1/mutations/{$this->mutationWithPdf->id}/document");
        $response->assertStatus(404);
        $response->assertJson([
            'success' => false,
            'message' => 'File dokumen fisik tidak ditemukan di server.',
        ]);
    }

    public function test_download_document_uses_original_filename_in_content_disposition(): void
    {
        $hashedPath = 'documents/sk_sdm/random_hash_a1b2c3d4.pdf';
        $originalName = 'sk_pengangkatan_dan_mutasi_asli.pdf';
        Storage::disk('public')->put($hashedPath, "%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF");

        $mutation = Mutation::create([
            'ticket_number' => 'MUT-ORIGINAL-NAME',
            'asset_id' => $this->mutationWithPdf->asset_id,
            'applicant_id' => $this->pemohon->id,
            'origin_location_id' => $this->mutationWithPdf->origin_location_id,
            'destination_location_id' => $this->mutationWithPdf->destination_location_id,
            'current_pic_id' => $this->pemohon->id,
            'target_pic_id' => $this->pemohon->id,
            'is_asset_moves_with_applicant' => true,
            'reason' => 'Pengujian nama asli dokumen pada unduhan/view.',
            'sk_document' => $hashedPath,
            'sk_document_name' => $originalName,
            'status' => 'menunggu_verifikasi_bagian_aset',
        ]);

        $response = $this->actingAs($this->pemohon)->get("/api/v1/mutations/{$mutation->id}/document");
        $response->assertOk();
        $response->assertHeader('Content-Disposition', 'inline; filename="' . $originalName . '"');
    }
}
