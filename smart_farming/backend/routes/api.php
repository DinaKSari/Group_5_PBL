<?php

use App\Http\Controllers\PredictionController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/predict', [PredictionController::class, 'store'])->middleware('throttle:30,1');
Route::get('/predictions', [PredictionController::class, 'index']);
