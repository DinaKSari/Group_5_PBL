<?php

namespace App\Http\Controllers;

use App\Http\Requests\PredictionRequest;
use App\Http\Resources\PredictionResource;
use App\Models\ActivityLog;
use App\Models\AppUser;
use App\Models\Prediction;
use App\Models\SensorReading;
use App\Services\MlInferenceService;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class PredictionController extends Controller
{
    public function __construct(private readonly MlInferenceService $ml) {}

    /**
     * Validasi -> panggil model ML -> simpan hasil + sensor reading + activity log -> balas JSON.
     * Response digabung dengan payload mentah ML agar Flutter cukup parse satu format.
     */
    public function store(PredictionRequest $request): JsonResponse
    {
        $data = $request->validated();
        $uid = $request->identity()->uid;

        // Identitas petani (uid + email/name) diambil dari klaim token yang sudah
        // tervalidasi, bukan dari isian client. Hanya kolom yang terisi yang ditimpa,
        // supaya prediksi tanpa email tidak menghapus identitas yang sudah ada.
        $petani = AppUser::firstOrNew(['uid' => $uid]);
        if ($request->identity()->email !== null) {
            $petani->email = $request->identity()->email;
        }
        if ($request->identity()->name !== null) {
            $petani->name = $request->identity()->name;
        }
        $petani->save();

        $prediction = $this->ml->predict($request->mlFeatures());

        $daysLeft = (int) ($prediction['days_left'] ?? 0);
        $harvestDate = CarbonImmutable::parse($data['tanggal_input'] ?? now())
            ->addDays($daysLeft)
            ->toDateString();

        $record = Prediction::create([
            'user_uid' => $uid,
            'lokasi' => $data['lokasi'] ?? 'Kebun',
            'tanggal_input' => $data['tanggal_input'] ?? now()->toDateString(),
            'umur_hst' => $data['umur_hst'],
            'suhu' => $data['suhu'],
            'kelembapan' => $data['kelembapan'],
            'tds' => $data['tds'],
            'ph' => $data['ph'],
            'days_left' => $daysLeft,
            'estimated_total_hst' => (int) ($prediction['estimated_total_hst'] ?? round($data['umur_hst'] + $daysLeft)),
            'harvest_date' => $harvestDate,
            'ml_model' => $prediction['selected_model'] ?? null,
            'meta' => $prediction['features_used'] ?? null,
            'ml_result' => $prediction,
        ]);

        SensorReading::create([
            'user_uid' => $uid,
            'lokasi' => $record->lokasi,
            'umur_hst' => $data['umur_hst'],
            'suhu' => $data['suhu'],
            'kelembapan' => $data['kelembapan'],
            'tds' => $data['tds'],
            'ph' => $data['ph'],
            'source' => 'manual',
        ]);

        ActivityLog::record(
            'prediction.created',
            "Prediksi panen untuk {$record->lokasi}: {$record->days_left} hari lagi.",
            $record,
            ['days_left' => $record->days_left, 'harvest_date' => $record->harvest_date],
        );

        return response()->json([
            ...$prediction,
            'id' => $record->id,
            'lokasi' => $record->lokasi,
            'harvest_date' => $record->harvest_date->toDateString(),
        ], 201);
    }

    /**
     * Riwayat prediksi milik user yang terautentikasi. Tidak ada jalur untuk
     * membaca riwayat user lain, termasuk tanpa filter.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Prediction::query()
            ->where('user_uid', $request->attributes->get('firebase_identity')->uid)
            ->latest()
            ->limit((int) $request->integer('limit', 50));

        return PredictionResource::collection($query->get());
    }
}
