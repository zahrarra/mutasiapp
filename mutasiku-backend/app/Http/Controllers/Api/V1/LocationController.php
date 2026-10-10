<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\LocationResource;
use App\Models\Location;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LocationController extends Controller
{
    /**
     * Display a listing of active locations.
     */
    public function index(Request $request): JsonResponse
    {
        $locations = Location::where('is_active', true)->get();

        if ($request->boolean('assignment_only') || $request->input('type') === 'assignment') {
            $locations = $locations->filter(fn (Location $loc) => $loc->isAssignmentUnit())->values();
        }

        return response()->json([
            'success' => true,
            'message' => 'Daftar lokasi berhasil diambil.',
            'data' => LocationResource::collection($locations),
        ], 200);
    }
}
