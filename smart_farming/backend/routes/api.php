<?php

use App\Http\Controllers\DeviceController;
use App\Http\Controllers\PredictionController;
use App\Http\Controllers\SensorController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/predict', [PredictionController::class, 'store'])->middleware('throttle:30,1');
Route::get('/predictions', [PredictionController::class, 'index']);

Route::post('/sensor', [SensorController::class, 'store'])->middleware('throttle:120,1');
Route::get('/sensor/latest', [SensorController::class, 'latest']);

Route::post('/devices', [DeviceController::class, 'store']);
