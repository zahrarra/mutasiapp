<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreMutationRequest;
use App\Http\Resources\MutationResource;
use App\Models\Asset;
use App\Models\Mutation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MutationController extends Controller
{
    /**
     * Display a listing of mutations with role-based scoping.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user()->loadMissing('role');
        $roleName = $user->role?->name;

        $query = Mutation::with([
            'asset.category',
            'asset.location',
            'applicant.role',
            'originLocation',
            'destinationLocation',
            'currentPic.role',
            'targetPic.role',
        ]);

        switch ($roleName) {
            case 'pemohon':
                // Pemohon hanya mutation miliknya
                $query->where('applicant_id', $user->id);
                break;

            case 'operator':
                // Operator hanya mutation yang perlu diproses sesuai alur Operator
                $query->where('status', 'diajukan');
                break;

            case 'bagian_aset':
                // Bagian Aset hanya mutation yang berada pada tahap verifikasi Bagian Aset
                $query->where('status', 'menunggu_verifikasi_bagian_aset');
                break;

            case 'pemimpin_divisi':
                // Pemimpin Divisi hanya mutation yang berada pada tahap approval
                $query->where('status', 'menunggu_approval_pemimpin_divisi');
                break;

            case 'admin':
                // Admin dapat melihat seluruh mutation
                break;

            default:
                $query->whereRaw('1 = 0');
                break;
        }

        $mutations = $query->orderByDesc('id')->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar pengajuan mutasi berhasil diambil.',
            'data' => MutationResource::collection($mutations),
        ], 200);
    }

    /**
     * Store a newly created mutation submission for Pemohon.
     */
    public function store(StoreMutationRequest $request): JsonResponse
    {
        $user = $request->user();
        $asset = Asset::with('category')->findOrFail($request->validated('asset_id'));

        $isMoving = $request->isMovingWithApplicant();

        // Server-enforced PIC rule:
        // asset_moves_with_applicant = true -> target_pic_id = auth()->id() (client target_pic_id diabaikan)
        // asset_moves_with_applicant = false -> target_pic_id = null
        $targetPicId = $isMoving ? $user->id : null;

        $destinationLocationId = $request->getDestinationLocationId();
        $skDocument = $request->getSkDocument();

        $mutation = DB::transaction(function () use (
            $asset,
            $user,
            $destinationLocationId,
            $targetPicId,
            $isMoving,
            $request,
            $skDocument
        ) {
            $ticketNumber = $this->generateTicketNumber($asset);

            return Mutation::create([
                'ticket_number' => $ticketNumber,
                'asset_id' => $asset->id,
                'applicant_id' => $user->id,
                'origin_location_id' => $asset->location_id,
                'destination_location_id' => $destinationLocationId,
                'current_pic_id' => $asset->pic_id,
                'target_pic_id' => $targetPicId,
                'is_asset_moves_with_applicant' => $isMoving,
                'reason' => (string) $request->validated('reason'),
                'sk_document' => $skDocument,
                'status' => 'diajukan',
            ]);
        });

        $mutation->load([
            'asset.category',
            'asset.location',
            'applicant.role',
            'originLocation',
            'destinationLocation',
            'currentPic.role',
            'targetPic.role',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pengajuan mutasi berhasil dibuat.',
            'data' => new MutationResource($mutation),
        ], 201);
    }

    /**
     * Display the specified mutation detail.
     */
    public function show(Request $request, string|int $id): JsonResponse
    {
        $user = $request->user()->loadMissing('role');
        $roleName = $user->role?->name;

        $mutation = Mutation::with([
            'asset.category',
            'asset.location',
            'applicant.role',
            'originLocation',
            'destinationLocation',
            'currentPic.role',
            'targetPic.role',
        ])->find($id);

        if (! $mutation) {
            return response()->json([
                'success' => false,
                'message' => 'Pengajuan mutasi tidak ditemukan.',
            ], 404);
        }

        // Role authorization check for detail
        $isAuthorized = match ($roleName) {
            'admin' => true,
            'pemohon' => $mutation->applicant_id === $user->id,
            'operator' => $mutation->status === 'diajukan',
            'bagian_aset' => $mutation->status === 'menunggu_verifikasi_bagian_aset',
            'pemimpin_divisi' => $mutation->status === 'menunggu_approval_pemimpin_divisi',
            default => false,
        };

        if (! $isAuthorized) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki hak akses untuk mutasi ini.',
            ], 403);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail pengajuan mutasi berhasil diambil.',
            'data' => new MutationResource($mutation),
        ], 200);
    }

    /**
     * Generate unique ticket number based on asset category, year, and sequence.
     * Format: KATEGORI-TAHUN-NOURUT (e.g. TI-2026-0001).
     */
    private function generateTicketNumber(Asset $asset): string
    {
        $categoryCode = strtoupper($asset->category?->code ?? 'MUT');
        $year = (int) date('Y');

        $count = Mutation::whereYear('created_at', $year)->count();
        $sequence = $count + 1;

        do {
            $ticketNumber = sprintf('%s-%d-%04d', $categoryCode, $year, $sequence);
            $exists = Mutation::where('ticket_number', $ticketNumber)->exists();
            if ($exists) {
                $sequence++;
            }
        } while ($exists);

        return $ticketNumber;
    }
}
