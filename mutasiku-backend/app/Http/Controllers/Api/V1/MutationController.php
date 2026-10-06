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
use App\Models\MutationStatusHistory;
use App\Models\User;
use App\Notifications\MutationStatusChangedNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;

class MutationController extends Controller
{
    /**
     * Display a listing of mutations with role-based scoping.
     * Supports ?view=queue (default) and ?view=history.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user()->loadMissing('role');
        $roleName = $user->role?->name;
        $view = $request->query('view', 'queue');

        $query = Mutation::with([
            'asset.category',
            'asset.location',
            'applicant.role',
            'originLocation',
            'destinationLocation',
            'currentPic.role',
            'targetPic.role',
        ]);

        if ($view === 'history') {
            switch ($roleName) {
                case 'pemohon':
                    // Pemohon tetap hanya melihat mutation miliknya
                    $query->where('applicant_id', $user->id);
                    break;

                case 'operator':
                    // Operator history: mutasi yang memiliki catatan riwayat proses oleh role operator
                    $query->whereHas('statusHistories', function ($q) {
                        $q->where('role', 'operator');
                    });
                    break;

                case 'bagian_aset':
                    // Bagian Aset history: mutasi yang memiliki catatan riwayat proses oleh role bagian_aset
                    $query->whereHas('statusHistories', function ($q) {
                        $q->where('role', 'bagian_aset');
                    });
                    break;

                case 'pemimpin_divisi':
                    // Pemimpin Divisi history: mutasi yang memiliki catatan riwayat proses oleh role pemimpin_divisi
                    $query->whereHas('statusHistories', function ($q) {
                        $q->where('role', 'pemimpin_divisi');
                    });
                    break;

                case 'admin':
                    // Admin dapat melihat seluruh mutation
                    break;

                default:
                    $query->whereRaw('1 = 0');
                    break;
            }
        } else {
            // Default view: antrean aktif (queue)
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
        $user = $request->user()->loadMissing('role');
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

            $newMutation = Mutation::create([
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

            MutationStatusHistory::create([
                'mutation_id' => $newMutation->id,
                'user_id' => $user->id,
                'role' => $user->role?->name ?? 'pemohon',
                'action' => 'store',
                'status_from' => null,
                'status_to' => 'diajukan',
                'notes' => (string) $request->validated('reason'),
            ]);

            $this->notifyRole('operator', new MutationStatusChangedNotification(
                mutation: $newMutation,
                title: 'Pengajuan Mutasi Baru',
                message: "Pengajuan mutasi {$newMutation->ticket_number} memerlukan verifikasi Operator.",
                action: 'store',
                status: 'diajukan'
            ));

            return $newMutation;
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
            'operator' => in_array($mutation->status, [
                'diajukan',
                'menunggu_verifikasi_bagian_aset',
                'menunggu_approval_pemimpin_divisi',
                'menunggu_konfirmasi_pemohon',
                'selesai',
                'ditolak',
                'dikembalikan_ke_pemohon',
            ]) || $mutation->statusHistories()->where('role', 'operator')->exists(),
            'bagian_aset' => in_array($mutation->status, [
                'menunggu_verifikasi_bagian_aset',
                'menunggu_approval_pemimpin_divisi',
                'menunggu_konfirmasi_pemohon',
                'selesai',
                'ditolak',
            ]) || $mutation->statusHistories()->where('role', 'bagian_aset')->exists(),
            'pemimpin_divisi' => in_array($mutation->status, [
                'menunggu_approval_pemimpin_divisi',
                'menunggu_konfirmasi_pemohon',
                'selesai',
                'ditolak',
            ]) || $mutation->statusHistories()->where('role', 'pemimpin_divisi')->exists(),
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
        $user = $request->user()->loadMissing('role');
        $statusBefore = $mutation->status;

        DB::transaction(function () use ($mutation, $isReturn, $request, $user, $statusBefore) {
            if ($isReturn) {
                $mutation->status = 'dikembalikan_ke_pemohon';
                $mutation->return_reason = (string) $request->input('reason');
            } else {
                $mutation->status = 'menunggu_verifikasi_bagian_aset';
                $mutation->return_reason = null;
            }
            $mutation->save();

            MutationStatusHistory::create([
                'mutation_id' => $mutation->id,
                'user_id' => $user->id,
                'role' => $user->role?->name ?? 'operator',
                'action' => $isReturn ? 'return' : 'verify',
                'status_from' => $statusBefore,
                'status_to' => $mutation->status,
                'notes' => (string) $request->input('reason'),
            ]);

            if ($isReturn) {
                $applicant = $mutation->applicant ?? User::find($mutation->applicant_id);
                if ($applicant) {
                    $this->notifyUser($applicant, new MutationStatusChangedNotification(
                        mutation: $mutation,
                        title: 'Pengajuan Mutasi Dikembalikan',
                        message: "Pengajuan mutasi {$mutation->ticket_number} dikembalikan oleh Operator: {$request->input('reason')}",
                        action: 'return',
                        status: 'dikembalikan_ke_pemohon'
                    ));
                }
            } else {
                $this->notifyRole('bagian_aset', new MutationStatusChangedNotification(
                    mutation: $mutation,
                    title: 'Menunggu Verifikasi Bagian Aset',
                    message: "Pengajuan mutasi {$mutation->ticket_number} telah diverifikasi oleh Operator dan memerlukan pemeriksaan Bagian Aset.",
                    action: 'verify',
                    status: 'menunggu_verifikasi_bagian_aset'
                ));
            }
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
        $user = $request->user()->loadMissing('role');
        $statusBefore = $mutation->status;

        if ($isReturn) {
            DB::transaction(function () use ($mutation, $request, $user, $statusBefore) {
                $mutation->status = 'dikembalikan_ke_pemohon';
                $mutation->return_reason = (string) $request->input('reason');
                $mutation->save();

                MutationStatusHistory::create([
                    'mutation_id' => $mutation->id,
                    'user_id' => $user->id,
                    'role' => $user->role?->name ?? 'bagian_aset',
                    'action' => 'return',
                    'status_from' => $statusBefore,
                    'status_to' => $mutation->status,
                    'notes' => (string) $request->input('reason'),
                ]);

                $applicant = $mutation->applicant ?? User::find($mutation->applicant_id);
                if ($applicant) {
                    $this->notifyUser($applicant, new MutationStatusChangedNotification(
                        mutation: $mutation,
                        title: 'Pengajuan Mutasi Dikembalikan',
                        message: "Pengajuan mutasi {$mutation->ticket_number} dikembalikan oleh Bagian Aset: {$request->input('reason')}",
                        action: 'return',
                        status: 'dikembalikan_ke_pemohon'
                    ));
                }
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

        DB::transaction(function () use ($mutation, $targetPicId, $user, $statusBefore, $request) {
            $mutation->target_pic_id = $targetPicId;
            $mutation->status = 'menunggu_approval_pemimpin_divisi';
            $mutation->return_reason = null;
            $mutation->save();

            MutationStatusHistory::create([
                'mutation_id' => $mutation->id,
                'user_id' => $user->id,
                'role' => $user->role?->name ?? 'bagian_aset',
                'action' => 'verify_asset',
                'status_from' => $statusBefore,
                'status_to' => $mutation->status,
                'notes' => (string) $request->input('reason'),
            ]);

            $this->notifyRole('pemimpin_divisi', new MutationStatusChangedNotification(
                mutation: $mutation,
                title: 'Menunggu Approval Pemimpin Divisi',
                message: "Pengajuan mutasi {$mutation->ticket_number} telah diverifikasi oleh Bagian Aset dan memerlukan persetujuan Pemimpin Divisi.",
                action: 'verify_asset',
                status: 'menunggu_approval_pemimpin_divisi'
            ));
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
        $user = $request->user()->loadMissing('role');
        $statusBefore = $mutation->status;

        DB::transaction(function () use ($mutation, $isReject, $request, $user, $statusBefore) {
            if ($isReject) {
                $mutation->status = 'ditolak';
                $mutation->rejection_reason = (string) $request->input('reason');
            } else {
                $mutation->status = 'menunggu_konfirmasi_pemohon';
                $mutation->rejection_reason = null;
            }
            $mutation->save();

            MutationStatusHistory::create([
                'mutation_id' => $mutation->id,
                'user_id' => $user->id,
                'role' => $user->role?->name ?? 'pemimpin_divisi',
                'action' => $isReject ? 'reject' : 'approve',
                'status_from' => $statusBefore,
                'status_to' => $mutation->status,
                'notes' => (string) $request->input('reason'),
            ]);

            $applicant = $mutation->applicant ?? User::find($mutation->applicant_id);
            if ($applicant) {
                if ($isReject) {
                    $this->notifyUser($applicant, new MutationStatusChangedNotification(
                        mutation: $mutation,
                        title: 'Pengajuan Mutasi Ditolak',
                        message: "Pengajuan mutasi {$mutation->ticket_number} ditolak oleh Pemimpin Divisi: {$request->input('reason')}",
                        action: 'reject',
                        status: 'ditolak'
                    ));
                } else {
                    $this->notifyUser($applicant, new MutationStatusChangedNotification(
                        mutation: $mutation,
                        title: 'Mutasi Disetujui - Menunggu Konfirmasi Pemohon',
                        message: "Pengajuan mutasi {$mutation->ticket_number} telah disetujui Pemimpin Divisi. Silakan lakukan konfirmasi fisik penerimaan aset.",
                        action: 'approve',
                        status: 'menunggu_konfirmasi_pemohon'
                    ));
                }
            }
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
        $user = $request->user()->loadMissing('role');
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
        $statusBefore = $mutation->status;

        if ($isSesuai) {
            // Perubahan resmi Asset dan pencatatan mutation history dalam satu transaksi
            DB::transaction(function () use ($mutation, $user, $statusBefore, $request) {
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

                MutationStatusHistory::create([
                    'mutation_id' => $mutation->id,
                    'user_id' => $user->id,
                    'role' => $user->role?->name ?? 'pemohon',
                    'action' => 'confirm_sesuai',
                    'status_from' => $statusBefore,
                    'status_to' => $mutation->status,
                    'notes' => (string) $request->input('reason'),
                ]);

                $applicant = $mutation->applicant ?? User::find($mutation->applicant_id);
                if ($applicant) {
                    $this->notifyUser($applicant, new MutationStatusChangedNotification(
                        mutation: $mutation,
                        title: 'Mutasi Selesai',
                        message: "Proses mutasi aset {$mutation->ticket_number} telah selesai.",
                        action: 'confirm_sesuai',
                        status: 'selesai'
                    ));
                }
            });

            $this->loadMutationRelations($mutation);

            return response()->json([
                'success' => true,
                'message' => 'Konfirmasi fisik berhasil. Proses mutasi aset telah selesai.',
                'data' => new MutationResource($mutation),
            ], 200);
        }

        // Jika tidak sesuai: kembalikan ke Bagian Aset, asset tidak berubah
        DB::transaction(function () use ($mutation, $request, $user, $statusBefore) {
            $mutation->status = 'menunggu_verifikasi_bagian_aset';
            $mutation->return_reason = (string) $request->input('reason');
            $mutation->save();

            MutationStatusHistory::create([
                'mutation_id' => $mutation->id,
                'user_id' => $user->id,
                'role' => $user->role?->name ?? 'pemohon',
                'action' => 'confirm_tidak_sesuai',
                'status_from' => $statusBefore,
                'status_to' => $mutation->status,
                'notes' => (string) $request->input('reason'),
            ]);

            $this->notifyRole('bagian_aset', new MutationStatusChangedNotification(
                mutation: $mutation,
                title: 'Konfirmasi Fisik Tidak Sesuai',
                message: "Pemohon melaporkan ketidaksesuaian fisik pada mutasi {$mutation->ticket_number} dan dikembalikan ke Bagian Aset.",
                action: 'confirm_tidak_sesuai',
                status: 'menunggu_verifikasi_bagian_aset'
            ));
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
        $user = $request->user()->loadMissing('role');
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

        $statusBefore = $mutation->status;

        DB::transaction(function () use ($mutation, $request, $user, $statusBefore) {
            if ($request->filled('destination_location_id')) {
                $mutation->destination_location_id = (int) $request->input('destination_location_id');
            }
            if ($request->filled('reason')) {
                $mutation->reason = (string) $request->input('reason');
            }
            if ($newSkDocument = $request->getSkDocument()) {
                $mutation->sk_document = $newSkDocument;
            }

            // Resubmit langsung ke Bagian Aset (tidak kembali ke operator)
            $mutation->status = 'menunggu_verifikasi_bagian_aset';
            $mutation->return_reason = null;
            $mutation->save();

            MutationStatusHistory::create([
                'mutation_id' => $mutation->id,
                'user_id' => $user->id,
                'role' => $user->role?->name ?? 'pemohon',
                'action' => 'resubmit',
                'status_from' => $statusBefore,
                'status_to' => $mutation->status,
                'notes' => (string) $request->input('reason'),
            ]);

            $this->notifyRole('bagian_aset', new MutationStatusChangedNotification(
                mutation: $mutation,
                title: 'Pengajuan Ulang Mutasi',
                message: "Pengajuan mutasi {$mutation->ticket_number} telah diajukan ulang oleh Pemohon dan siap diverifikasi oleh Bagian Aset.",
                action: 'resubmit',
                status: 'menunggu_verifikasi_bagian_aset'
            ));
        });

        $this->loadMutationRelations($mutation);

        return response()->json([
            'success' => true,
            'message' => 'Pengajuan mutasi berhasil diperbaiki dan diteruskan ke Bagian Aset.',
            'data' => new MutationResource($mutation),
        ], 200);
    }

    /**
     * Notify all active users with a specific role.
     */
    private function notifyRole(string $roleName, MutationStatusChangedNotification $notification): void
    {
        $users = User::whereHas('role', fn ($q) => $q->where('name', $roleName))
            ->where('is_active', true)
            ->get();

        if ($users->isNotEmpty()) {
            Notification::send($users, $notification);
        }
    }

    /**
     * Notify an individual user.
     */
    private function notifyUser(User $user, MutationStatusChangedNotification $notification): void
    {
        $user->notify($notification);
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
