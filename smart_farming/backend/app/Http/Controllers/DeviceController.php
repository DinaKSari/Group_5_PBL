<?php

namespace App\Http\Controllers;

use App\Models\ActivityLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    /**
     * Registrasi perangkat FCM. Token dikirim lewat header Authorization
     * (firebase.auth), bukan sebagai identitas di body.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'fcm_token' => ['required', 'string'],
            'platform' => ['nullable', 'string', 'max:32'],
        ]);

        ActivityLog::record(
            'device.registered',
            'Perangkat '.($data['platform'] ?? 'unknown').' mendaftarkan token FCM.',
            null,
            [
                // Token utuh adalah kredensial push device: tidak disimpan/dilog
                // apa adanya, cukup sidik jarinya untuk korelasi.
                'fcm_token_fingerprint' => substr(hash('sha256', $data['fcm_token']), 0, 16),
                'user_uid' => $request->attributes->get('firebase_identity')->uid,
            ],
        );

        return response()->json(['message' => 'Device terdaftar.'], 201);
    }
}
