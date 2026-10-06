<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreLocationRequest;
use App\Http\Requests\Admin\UpdateLocationRequest;
use App\Http\Resources\LocationResource;
use App\Models\Location;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LocationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $locations = Location::all();

        return response()->json([
            'success' => true,
            'message' => 'Daftar lokasi berhasil diambil.',
            'data' => LocationResource::collection($locations),
        ], 200);
    }

    public function store(StoreLocationRequest $request): JsonResponse
    {
        $location = Location::create($request->validated());

        return response()->json([
            'success' => true,
            'message' => 'Lokasi berhasil dibuat.',
            'data' => new LocationResource($location),
        ], 201);
    }

    public function show(string|int $id): JsonResponse
    {
        $location = Location::find($id);

        if (! $location) {
            return response()->json([
                'success' => false,
                'message' => 'Lokasi tidak ditemukan.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail lokasi berhasil diambil.',
            'data' => new LocationResource($location),
        ], 200);
    }

    public function update(UpdateLocationRequest $request, string|int $id): JsonResponse
    {
        $location = Location::find($id);

        if (! $location) {
            return response()->json([
                'success' => false,
                'message' => 'Lokasi tidak ditemukan.',
            ], 404);
        }

        $location->update($request->validated());

        return response()->json([
            'success' => true,
            'message' => 'Lokasi berhasil diperbarui.',
            'data' => new LocationResource($location),
        ], 200);
    }

    public function destroy(string|int $id): JsonResponse
    {
        $location = Location::find($id);

        if (! $location) {
            return response()->json([
                'success' => false,
                'message' => 'Lokasi tidak ditemukan.',
            ], 404);
        }

        try {
            $location->delete();

            return response()->json([
                'success' => true,
                'message' => 'Lokasi berhasil dihapus.',
                'data' => null,
            ], 200);
        } catch (QueryException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Lokasi tidak dapat dihapus karena masih digunakan pada data aset atau mutasi.',
            ], 409);
        }
    }
}
