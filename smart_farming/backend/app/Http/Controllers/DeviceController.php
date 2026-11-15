<?php

namespace App\Http\Controllers;

use App\Models\ActivityLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    /**
     * Registrasi perangkat FCM. Flutter previously POST ke Flask /devices;
     * kini lewat Laravel agar tercatat di ActivityLog.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'fcm_token' => ['required', 'string'],
            'platform' => ['nullable', 'string', 'max:32'],
            'user_uid' => ['nullable', 'string', 'max:128'],
        ]);

        ActivityLog::record(
            'device.registered',
            'Perangkat '.($data['platform'] ?? 'unknown').' mendaftarkan token FCM.',
            null,
            ['fcm_token' => $data['fcm_token'], 'user_uid' => $data['user_uid'] ?? null],
        );

        return response()->json(['message' => 'Device terdaftar.'], 201);
    }
}
