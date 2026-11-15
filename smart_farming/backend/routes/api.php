<?php

use App\Http\Controllers\DeviceController;
use App\Http\Controllers\PredictionController;
use App\Http\Controllers\SensorController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// Semua route di bawah memakai identitas dari ID token Firebase (middleware firebase.auth).
// uid TIDAK diambil dari query/body lagi. Device IoT yang belum punya akun Firebase harus
// memakai mekanisme kredensial sendiri (lihat docs/PLAN.md §4A) sebelum route ini dibuka.
Route::middleware('firebase.auth')->group(function () {
    Route::post('/predict', [PredictionController::class, 'store'])->middleware('throttle:30,1');
    Route::get('/predictions', [PredictionController::class, 'index'])->middleware('throttle:60,1');

    Route::post('/sensor', [SensorController::class, 'store'])->middleware('throttle:120,1');
    Route::get('/sensor/latest', [SensorController::class, 'latest'])->middleware('throttle:120,1');

    Route::post('/devices', [DeviceController::class, 'store'])->middleware('throttle:30,1');
});
