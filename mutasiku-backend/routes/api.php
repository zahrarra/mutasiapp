<?php

use App\Http\Controllers\Api\V1\AssetCategoryController;
use App\Http\Controllers\Api\V1\AssetController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\LocationController;
use App\Http\Controllers\Api\V1\MutationController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::prefix('v1')->group(function () {
    Route::prefix('auth')->group(function () {
        Route::post('/login', [AuthController::class, 'login']);

        Route::middleware('auth:sanctum')->group(function () {
            Route::get('/me', [AuthController::class, 'me']);
            Route::post('/logout', [AuthController::class, 'logout']);
        });
    });

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/locations', [LocationController::class, 'index']);
        Route::get('/asset-categories', [AssetCategoryController::class, 'index']);
        Route::get('/assets', [AssetController::class, 'index']);
        Route::get('/assets/{id}', [AssetController::class, 'show']);
        Route::get('/assets/{id}/history', [AssetController::class, 'history']);

        Route::get('/mutations', [MutationController::class, 'index']);
        Route::post('/mutations', [MutationController::class, 'store']);
        Route::get('/mutations/{id}', [MutationController::class, 'show']);

        // Stage 5: Mutation Transitions
        Route::post('/mutations/{id}/verify', [MutationController::class, 'verify']);
        Route::post('/mutations/{id}/verify-asset', [MutationController::class, 'verifyAsset']);
        Route::post('/mutations/{id}/approve', [MutationController::class, 'approve']);
        Route::post('/mutations/{id}/confirm', [MutationController::class, 'confirm']);
        Route::post('/mutations/{id}/resubmit', [MutationController::class, 'resubmit']);
    });
});
