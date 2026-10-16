<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreAssetCategoryRequest;
use App\Http\Requests\Admin\UpdateAssetCategoryRequest;
use App\Http\Resources\AssetCategoryResource;
use App\Models\AssetCategory;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AssetCategoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $categories = AssetCategory::all();

        return response()->json([
            'success' => true,
            'message' => 'Daftar kategori aset berhasil diambil.',
            'data' => AssetCategoryResource::collection($categories),
        ], 200);
    }

    public function store(StoreAssetCategoryRequest $request): JsonResponse
    {
        $category = AssetCategory::create($request->validated());

        return response()->json([
            'success' => true,
            'message' => 'Kategori aset berhasil dibuat.',
            'data' => new AssetCategoryResource($category),
        ], 201);
    }

    public function show(string|int $id): JsonResponse
    {
        $category = AssetCategory::find($id);

        if (! $category) {
            return response()->json([
                'success' => false,
                'message' => 'Kategori aset tidak ditemukan.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail kategori aset berhasil diambil.',
            'data' => new AssetCategoryResource($category),
        ], 200);
    }

    public function update(UpdateAssetCategoryRequest $request, string|int $id): JsonResponse
    {
        $category = AssetCategory::find($id);

        if (! $category) {
            return response()->json([
                'success' => false,
                'message' => 'Kategori aset tidak ditemukan.',
            ], 404);
        }

        $category->update($request->validated());

        return response()->json([
            'success' => true,
            'message' => 'Kategori aset berhasil diperbarui.',
            'data' => new AssetCategoryResource($category),
        ], 200);
    }

    public function destroy(string|int $id): JsonResponse
    {
        $category = AssetCategory::find($id);

        if (! $category) {
            return response()->json([
                'success' => false,
                'message' => 'Kategori aset tidak ditemukan.',
            ], 404);
        }

        try {
            $category->delete();

            return response()->json([
                'success' => true,
                'message' => 'Kategori aset berhasil dihapus.',
                'data' => null,
            ], 200);
        } catch (QueryException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Kategori aset tidak dapat dihapus karena masih digunakan pada data aset.',
            ], 409);
        }
    }
}
