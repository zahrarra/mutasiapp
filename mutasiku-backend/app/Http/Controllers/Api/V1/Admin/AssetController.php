<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreAssetRequest;
use App\Http\Requests\Admin\UpdateAssetRequest;
use App\Http\Resources\AssetResource;
use App\Models\Asset;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AssetController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $assets = Asset::with(['category', 'location', 'pic.role'])->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar aset berhasil diambil.',
            'data' => AssetResource::collection($assets),
        ], 200);
    }

    public function store(StoreAssetRequest $request): JsonResponse
    {
        $asset = Asset::create($request->validated());
        $asset->load(['category', 'location', 'pic.role']);

        return response()->json([
            'success' => true,
            'message' => 'Aset berhasil dibuat.',
            'data' => new AssetResource($asset),
        ], 201);
    }

    public function show(string|int $id): JsonResponse
    {
        $asset = Asset::with(['category', 'location', 'pic.role'])->find($id);

        if (! $asset) {
            return response()->json([
                'success' => false,
                'message' => 'Aset tidak ditemukan.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail aset berhasil diambil.',
            'data' => new AssetResource($asset),
        ], 200);
    }

    public function update(UpdateAssetRequest $request, string|int $id): JsonResponse
    {
        $asset = Asset::find($id);

        if (! $asset) {
            return response()->json([
                'success' => false,
                'message' => 'Aset tidak ditemukan.',
            ], 404);
        }

        $asset->update($request->validated());
        $asset->load(['category', 'location', 'pic.role']);

        return response()->json([
            'success' => true,
            'message' => 'Aset berhasil diperbarui.',
            'data' => new AssetResource($asset),
        ], 200);
    }

    public function destroy(string|int $id): JsonResponse
    {
        $asset = Asset::find($id);

        if (! $asset) {
            return response()->json([
                'success' => false,
                'message' => 'Aset tidak ditemukan.',
            ], 404);
        }

        try {
            $asset->delete();

            return response()->json([
                'success' => true,
                'message' => 'Aset berhasil dihapus.',
                'data' => null,
            ], 200);
        } catch (QueryException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Aset tidak dapat dihapus karena memiliki riwayat mutasi atau referensi lain.',
            ], 409);
        }
    }
}
