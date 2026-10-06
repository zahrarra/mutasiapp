<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\AssetVerifyMutationRequest;
use App\Http\Requests\ConfirmMutationRequest;
use App\Http\Requests\DivisionApproveMutationRequest;
use App\Http\Requests\OperatorVerifyMutationRequest;
use App\Http\Requests\ResubmitMutationRequest;
use App\Http\Requests\StoreMutationRequest;
use App\Http\Resources\MutationResource;
use App\Models\Asset;
use App\Models\Mutation;
use App\Models\MutationHistory;
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
     * Operator verify: transitions from 'diajukan' to 'menunggu_verifikasi_bagian_aset' or 'dikembalikan_ke_pemohon'.
     */
    public function verify(OperatorVerifyMutationRequest $request, string|int $id): JsonResponse
    {
        $mutation = Mutation::find($id);

        if (! $mutation) {
            return response()->json([
                'success' => false,
                'message' => 'Pengajuan mutasi tidak ditemukan.',
            ], 404);
        }

        if ($mutation->status !== 'diajukan') {
            return response()->json([
                'success' => false,
                'message' => "Status pengajuan saat ini ({$mutation->status}) tidak valid untuk verifikasi Operator.",
            ], 409);
        }

        $isReturn = $request->isReturn();

        DB::transaction(function () use ($mutation, $isReturn, $request) {
            if ($isReturn) {
                $mutation->status = 'dikembalikan_ke_pemohon';
                $mutation->return_reason = (string) $request->input('reason');
            } else {
                $mutation->status = 'menunggu_verifikasi_bagian_aset';
                $mutation->return_reason = null;
            }
            $mutation->save();
        });

        $this->loadMutationRelations($mutation);

        $message = $isReturn
            ? 'Pengajuan mutasi berhasil dikembalikan ke Pemohon.'
            : 'Pengajuan mutasi berhasil diverifikasi dan diteruskan ke Bagian Aset.';

        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => new MutationResource($mutation),
        ], 200);
    }

    /**
     * Bagian Aset verify: transitions from 'menunggu_verifikasi_bagian_aset' to 'menunggu_approval_pemimpin_divisi' or 'dikembalikan_ke_pemohon'.
     */
    public function verifyAsset(AssetVerifyMutationRequest $request, string|int $id): JsonResponse
    {
        $mutation = Mutation::find($id);

        if (! $mutation) {
            return response()->json([
                'success' => false,
                'message' => 'Pengajuan mutasi tidak ditemukan.',
            ], 404);
        }

        if ($mutation->status !== 'menunggu_verifikasi_bagian_aset') {
            return response()->json([
                'success' => false,
                'message' => "Status pengajuan saat ini ({$mutation->status}) tidak valid untuk verifikasi Bagian Aset.",
            ], 409);
        }

        $isReturn = $request->isReturn();

        if ($isReturn) {
            DB::transaction(function () use ($mutation, $request) {
                $mutation->status = 'dikembalikan_ke_pemohon';
                $mutation->return_reason = (string) $request->input('reason');
                $mutation->save();
            });

            $this->loadMutationRelations($mutation);

            return response()->json([
                'success' => true,
                'message' => 'Pengajuan mutasi berhasil dikembalikan ke Pemohon.',
                'data' => new MutationResource($mutation),
            ], 200);
        }

        // Jika diteruskan ke approval Pemimpin Divisi: target_pic_id wajib sudah ditentukan
        $targetPicId = $request->filled('target_pic_id')
            ? (int) $request->input('target_pic_id')
            : $mutation->target_pic_id;

        if (! $targetPicId) {
            return response()->json([
                'success' => false,
                'message' => 'Penanggung jawab baru (target_pic_id) wajib ditentukan sebelum diteruskan ke Pemimpin Divisi.',
            ], 422);
        }

        DB::transaction(function () use ($mutation, $targetPicId) {
            $mutation->target_pic_id = $targetPicId;
            $mutation->status = 'menunggu_approval_pemimpin_divisi';
            $mutation->return_reason = null;
            $mutation->save();
        });

        $this->loadMutationRelations($mutation);

        return response()->json([
            'success' => true,
            'message' => 'Pengajuan mutasi berhasil diverifikasi dan diteruskan ke Pemimpin Divisi.',
            'data' => new MutationResource($mutation),
        ], 200);
    }

    /**
     * Pemimpin Divisi approve: transitions from 'menunggu_approval_pemimpin_divisi' to 'menunggu_konfirmasi_pemohon' or 'ditolak'.
     */
    public function approve(DivisionApproveMutationRequest $request, string|int $id): JsonResponse
    {
        $mutation = Mutation::find($id);

        if (! $mutation) {
            return response()->json([
                'success' => false,
                'message' => 'Pengajuan mutasi tidak ditemukan.',
            ], 404);
        }

        if ($mutation->status !== 'menunggu_approval_pemimpin_divisi') {
            return response()->json([
                'success' => false,
                'message' => "Status pengajuan saat ini ({$mutation->status}) tidak valid untuk approval Pemimpin Divisi.",
            ], 409);
        }

        $isReject = $request->isReject();

        DB::transaction(function () use ($mutation, $isReject, $request) {
            if ($isReject) {
                $mutation->status = 'ditolak';
                $mutation->rejection_reason = (string) $request->input('reason');
            } else {
                $mutation->status = 'menunggu_konfirmasi_pemohon';
                $mutation->rejection_reason = null;
            }
            $mutation->save();
        });

        $this->loadMutationRelations($mutation);

        $message = $isReject
            ? 'Pengajuan mutasi telah ditolak oleh Pemimpin Divisi.'
            : 'Pengajuan mutasi berhasil disetujui dan menunggu konfirmasi fisik Pemohon.';

        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => new MutationResource($mutation),
        ], 200);
    }

    /**
     * Pemohon confirm: transitions from 'menunggu_konfirmasi_pemohon' to 'selesai' (sesuai) or 'menunggu_verifikasi_bagian_aset' (tidak_sesuai).
     */
    public function confirm(ConfirmMutationRequest $request, string|int $id): JsonResponse
    {
        $user = $request->user();
        $mutation = Mutation::find($id);

        if (! $mutation) {
            return response()->json([
                'success' => false,
                'message' => 'Pengajuan mutasi tidak ditemukan.',
            ], 404);
        }

        // Ownership check: hanya pemohon pemilik mutation
        if ($mutation->applicant_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki hak akses untuk mengonfirmasi mutasi ini.',
            ], 403);
        }

        if ($mutation->status !== 'menunggu_konfirmasi_pemohon') {
            return response()->json([
                'success' => false,
                'message' => "Status pengajuan saat ini ({$mutation->status}) tidak valid untuk konfirmasi Pemohon.",
            ], 409);
        }

        $isSesuai = $request->isSesuai();

        if ($isSesuai) {
            // Perubahan resmi Asset dan pencatatan mutation history dalam satu transaksi
            DB::transaction(function () use ($mutation, $user) {
                $mutation->status = 'selesai';
                $mutation->return_reason = null;
                $mutation->save();

                $asset = Asset::findOrFail($mutation->asset_id);
                $asset->location_id = $mutation->destination_location_id;
                $asset->pic_id = $mutation->target_pic_id;
                $asset->save();

                MutationHistory::create([
                    'asset_id' => $asset->id,
                    'mutation_id' => $mutation->id,
                    'ticket_number' => $mutation->ticket_number,
                    'date' => now(),
                    'previous_location_id' => $mutation->origin_location_id,
                    'new_location_id' => $mutation->destination_location_id,
                    'previous_pic_id' => $mutation->current_pic_id,
                    'new_pic_id' => $mutation->target_pic_id,
                    'updated_by' => $user->id,
                ]);
            });

            $this->loadMutationRelations($mutation);

            return response()->json([
                'success' => true,
                'message' => 'Konfirmasi fisik berhasil. Proses mutasi aset telah selesai.',
                'data' => new MutationResource($mutation),
            ], 200);
        }

        // Jika tidak sesuai: kembalikan ke Bagian Aset, asset tidak berubah
        DB::transaction(function () use ($mutation, $request) {
            $mutation->status = 'menunggu_verifikasi_bagian_aset';
            $mutation->return_reason = (string) $request->input('reason');
            $mutation->save();
        });

        $this->loadMutationRelations($mutation);

        return response()->json([
            'success' => true,
            'message' => 'Laporan ketidaksesuaian berhasil dikirim. Pengajuan dikembalikan ke Bagian Aset.',
            'data' => new MutationResource($mutation),
        ], 200);
    }

    /**
     * Pemohon resubmit: transitions from 'dikembalikan_ke_pemohon' directly to 'menunggu_verifikasi_bagian_aset'.
     */
    public function resubmit(ResubmitMutationRequest $request, string|int $id): JsonResponse
    {
        $user = $request->user();
        $mutation = Mutation::find($id);

        if (! $mutation) {
            return response()->json([
                'success' => false,
                'message' => 'Pengajuan mutasi tidak ditemukan.',
            ], 404);
        }

        // Ownership check: hanya pemohon pemilik mutation
        if ($mutation->applicant_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki hak akses untuk mengajukan ulang mutasi ini.',
            ], 403);
        }

        if ($mutation->status !== 'dikembalikan_ke_pemohon') {
            return response()->json([
                'success' => false,
                'message' => "Status pengajuan saat ini ({$mutation->status}) tidak valid untuk pengajuan ulang.",
            ], 409);
        }

        DB::transaction(function () use ($mutation, $request) {
            if ($request->filled('destination_location_id')) {
                $mutation->destination_location_id = (int) $request->input('destination_location_id');
            }
            if ($request->filled('reason')) {
                $mutation->reason = (string) $request->input('reason');
            }
            if ($request->filled('sk_document')) {
                $mutation->sk_document = (string) $request->input('sk_document');
            }

            // Resubmit langsung ke Bagian Aset (tidak kembali ke operator)
            $mutation->status = 'menunggu_verifikasi_bagian_aset';
            $mutation->return_reason = null;
            $mutation->save();
        });

        $this->loadMutationRelations($mutation);

        return response()->json([
            'success' => true,
            'message' => 'Pengajuan mutasi berhasil diperbaiki dan diteruskan ke Bagian Aset.',
            'data' => new MutationResource($mutation),
        ], 200);
    }

    /**
     * Eager load relations for resource response.
     */
    private function loadMutationRelations(Mutation $mutation): void
    {
        $mutation->load([
            'asset.category',
            'asset.location',
            'applicant.role',
            'originLocation',
            'destinationLocation',
            'currentPic.role',
            'targetPic.role',
        ]);
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
