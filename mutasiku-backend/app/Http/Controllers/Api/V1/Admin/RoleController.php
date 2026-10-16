<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreRoleRequest;
use App\Http\Requests\Admin\UpdateRoleRequest;
use App\Http\Resources\RoleResource;
use App\Models\Role;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RoleController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $roles = Role::all();

        return response()->json([
            'success' => true,
            'message' => 'Daftar role berhasil diambil.',
            'data' => RoleResource::collection($roles),
        ], 200);
    }

    public function store(StoreRoleRequest $request): JsonResponse
    {
        $role = Role::create($request->validated());

        return response()->json([
            'success' => true,
            'message' => 'Role berhasil dibuat.',
            'data' => new RoleResource($role),
        ], 201);
    }

    public function show(string|int $id): JsonResponse
    {
        $role = Role::find($id);

        if (! $role) {
            return response()->json([
                'success' => false,
                'message' => 'Role tidak ditemukan.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail role berhasil diambil.',
            'data' => new RoleResource($role),
        ], 200);
    }

    public function update(UpdateRoleRequest $request, string|int $id): JsonResponse
    {
        $role = Role::find($id);

        if (! $role) {
            return response()->json([
                'success' => false,
                'message' => 'Role tidak ditemukan.',
            ], 404);
        }

        $role->update($request->validated());

        return response()->json([
            'success' => true,
            'message' => 'Role berhasil diperbarui.',
            'data' => new RoleResource($role),
        ], 200);
    }

    public function destroy(string|int $id): JsonResponse
    {
        $role = Role::find($id);

        if (! $role) {
            return response()->json([
                'success' => false,
                'message' => 'Role tidak ditemukan.',
            ], 404);
        }

        try {
            $role->delete();

            return response()->json([
                'success' => true,
                'message' => 'Role berhasil dihapus.',
                'data' => null,
            ], 200);
        } catch (QueryException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Role tidak dapat dihapus karena masih digunakan oleh user.',
            ], 409);
        }
    }
}
