<?php

use App\Http\Controllers\Api\V1\Admin\AssetCategoryController as AdminAssetCategoryController;
use App\Http\Controllers\Api\V1\Admin\AssetController as AdminAssetController;
use App\Http\Controllers\Api\V1\Admin\LocationController as AdminLocationController;
use App\Http\Controllers\Api\V1\Admin\RoleController as AdminRoleController;
use App\Http\Controllers\Api\V1\Admin\UserController as AdminUserController;
use App\Http\Controllers\Api\V1\AssetCategoryController;
use App\Http\Controllers\Api\V1\AssetController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\LocationController;
use App\Http\Controllers\Api\V1\MutationController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Middleware\EnsureUserIsAdmin;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::prefix('v1')->group(function () {
    Route::prefix('auth')->group(function () {
        Route::post('/login', [AuthController::class, 'login'])->name('login');

        Route::middleware('auth:sanctum')->group(function () {
            Route::get('/me', [AuthController::class, 'me']);
            Route::post('/logout', [AuthController::class, 'logout']);
            Route::post('/change-password', [AuthController::class, 'changePassword']);
        });
    });

    // Alias / fallback route jika client memanggil POST /api/v1/login tanpa segmen auth
    Route::post('/login', [AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/locations', [LocationController::class, 'index']);
        Route::get('/asset-categories', [AssetCategoryController::class, 'index']);
        Route::get('/assets', [AssetController::class, 'index']);
        Route::get('/assets/{id}', [AssetController::class, 'show']);
        Route::get('/assets/{id}/history', [AssetController::class, 'history']);

        // Stage 5: Mutation CRUD & Transitions
        Route::get('/mutations', [MutationController::class, 'index']);
        Route::post('/mutations', [MutationController::class, 'store']);
        Route::get('/mutations/{id}', [MutationController::class, 'show']);
        Route::get('/mutations/{id}/document', [MutationController::class, 'downloadDocument']);
        Route::put('/mutations/{id}', [MutationController::class, 'update']);
        Route::post('/mutations/{id}/resubmit', [MutationController::class, 'resubmit']);

        // Operator
        Route::post('/mutations/{id}/forward', [MutationController::class, 'forward']);
        Route::post('/mutations/{id}/return-by-operator', [MutationController::class, 'returnByOperator']);

        // Bagian Aset
        Route::post('/mutations/{id}/verify-asset', [MutationController::class, 'verifyAsset']);
        Route::post('/mutations/{id}/return-by-asset', [MutationController::class, 'returnByAsset']);

        // Pemimpin Divisi
        Route::post('/mutations/{id}/approve', [MutationController::class, 'approve']);
        Route::post('/mutations/{id}/reject', [MutationController::class, 'reject']);

        // Pemohon (Konfirmasi & Pelaporan)
        Route::post('/mutations/{id}/confirm', [MutationController::class, 'confirm']);
        Route::post('/mutations/{id}/report-discrepancy', [MutationController::class, 'reportDiscrepancy']);

        // Backward compatibility / unified
        Route::post('/mutations/{id}/verify', [MutationController::class, 'verify']);

        // Stage 6: Notifications
        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::post('/notifications/read-all', [NotificationController::class, 'readAll']);
        Route::post('/notifications/{id}/read', [NotificationController::class, 'read']);

        // Stage 7: Admin CRUD
        Route::prefix('admin')->middleware(EnsureUserIsAdmin::class)->group(function () {
            Route::apiResource('users', AdminUserController::class);
            Route::apiResource('roles', AdminRoleController::class);
            Route::apiResource('locations', AdminLocationController::class);
            Route::apiResource('asset-categories', AdminAssetCategoryController::class);
            Route::apiResource('assets', AdminAssetController::class);
        });
    });
});
