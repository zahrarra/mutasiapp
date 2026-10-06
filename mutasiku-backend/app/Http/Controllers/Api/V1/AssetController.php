<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\AssetHistoryResource;
use App\Http\Resources\AssetResource;
use App\Models\Asset;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AssetController extends Controller
{
    /**
     * Display a listing of assets with role scoping.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user()->loadMissing('role');
        $roleName = $user->role?->name;

        $query = Asset::with(['category', 'location', 'pic.role']);

        // Role scoping: Pemohon can scope to own assets via ?mine=true
        if ($roleName === 'pemohon' && $request->boolean('mine')) {
            $query->where('pic_id', $user->id);
        }

        $assets = $query->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar aset berhasil diambil.',
            'data' => AssetResource::collection($assets),
        ], 200);
    }

    /**
     * Display the specified asset detail.
     */
    public function show(Request $request, string|int $id): JsonResponse
    {
        $user = $request->user()->loadMissing('role');
        $roleName = $user->role?->name;

        $asset = Asset::with(['category', 'location', 'pic.role'])->find($id);

        if (! $asset) {
            return response()->json([
                'success' => false,
                'message' => 'Aset tidak ditemukan.',
            ], 404);
        }

        // Role authorization: Pemohon only has access to their own asset
        if ($roleName === 'pemohon' && $asset->pic_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki hak akses untuk aset ini.',
            ], 403);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail aset berhasil diambil.',
            'data' => new AssetResource($asset),
        ], 200);
    }

    /**
     * Display the change history of the specified asset.
     */
    public function history(Request $request, string|int $id): JsonResponse
    {
        $user = $request->user()->loadMissing('role');
        $roleName = $user->role?->name;

        $asset = Asset::find($id);

        if (! $asset) {
            return response()->json([
                'success' => false,
                'message' => 'Aset tidak ditemukan.',
            ], 404);
        }

        // Role authorization: Pemohon only has access to their own asset history
        if ($roleName === 'pemohon' && $asset->pic_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki hak akses untuk riwayat aset ini.',
            ], 403);
        }

        $histories = $asset->mutationHistories()
            ->with(['previousLocation', 'newLocation', 'previousPic.role', 'newPic.role', 'updater.role'])
            ->orderByDesc('date')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Riwayat perubahan aset berhasil diambil.',
            'data' => AssetHistoryResource::collection($histories),
        ], 200);
    }
}
