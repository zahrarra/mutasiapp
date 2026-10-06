<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\AssetCategoryResource;
use App\Models\AssetCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AssetCategoryController extends Controller
{
    /**
     * Display a listing of asset categories.
     */
    public function index(Request $request): JsonResponse
    {
        $categories = AssetCategory::all();

        return response()->json([
            'success' => true,
            'message' => 'Daftar kategori aset berhasil diambil.',
            'data' => AssetCategoryResource::collection($categories),
        ], 200);
    }
}
