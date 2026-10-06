<?php

use App\Http\Controllers\Api\V1\AssetCategoryController;
use App\Http\Controllers\Api\V1\AssetController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\LocationController;
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
    });
});
