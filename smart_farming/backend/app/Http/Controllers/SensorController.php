<?php

namespace App\Http\Controllers;

use App\Models\SensorReading;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SensorController extends Controller
{
    /**
     * Simpan satu pembacaan parameter kebun (manual/simulasi IoT).
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'umur_hst' => ['required', 'numeric', 'between:1,45'],
            'suhu' => ['required', 'numeric', 'between:10,40'],
            'kelembapan' => ['required', 'numeric', 'between:30,100'],
            'tds' => ['required', 'numeric', 'between:200,1500'],
            'ph' => ['required', 'numeric', 'between:4,9'],
            'lokasi' => ['nullable', 'string', 'max:120'],
            'user_uid' => ['nullable', 'string', 'max:128'],
            'source' => ['nullable', 'string', 'in:manual,iot,simulasi'],
        ]);

        $reading = SensorReading::create([
            ...$data,
            'lokasi' => $data['lokasi'] ?? 'Kebun',
            'source' => $data['source'] ?? 'manual',
        ]);

        return response()->json(['data' => $reading], 201);
    }

    /**
     * Pembacaan terbaru untuk dashboard monitoring.
     */
    public function latest(Request $request): JsonResponse
    {
        $reading = SensorReading::query()
            ->when($request->query('user_uid'), fn ($q, $uid) => $q->where('user_uid', $uid))
            ->latest()
            ->first();

        if (! $reading) {
            return response()->json(['data' => null, 'message' => 'Belum ada data sensor.']);
        }

        return response()->json([
            'data' => [
                'id' => $reading->id,
                'lokasi' => $reading->lokasi,
                'umur_hst' => $reading->umur_hst,
                'suhu' => $reading->suhu,
                'kelembapan' => $reading->kelembapan,
                'tds' => $reading->tds,
                'ph' => $reading->ph,
                'source' => $reading->source,
                'created_at' => $reading->created_at?->toIso8601String(),
            ],
        ]);
    }
}
