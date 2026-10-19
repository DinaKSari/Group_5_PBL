<?php

namespace App\Http\Controllers;

use App\Http\Requests\PredictionRequest;
use App\Http\Resources\PredictionResource;
use App\Models\ActivityLog;
use App\Models\Prediction;
use App\Services\MlInferenceService;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class PredictionController extends Controller
{
    public function __construct(private readonly MlInferenceService $ml) {}

    /**
     * Validasi -> panggil model ML -> simpan hasil + activity log -> balas JSON.
     */
    public function store(PredictionRequest $request): JsonResponse
    {
        $data = $request->validated();
        $prediction = $this->ml->predict($request->mlFeatures());

        $daysLeft = (int) ($prediction['days_left'] ?? 0);
        $harvestDate = CarbonImmutable::parse($data['tanggal_input'] ?? now())
            ->addDays($daysLeft)
            ->toDateString();

        $record = Prediction::create([
            'user_id' => $request->user()?->id,
            'lokasi' => $data['lokasi'],
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
        ]);

        ActivityLog::record(
            'prediction.created',
            "Prediksi panen untuk {$record->lokasi}: {$record->days_left} hari lagi.",
            $record,
            ['days_left' => $record->days_left, 'harvest_date' => $record->harvest_date],
        );

        return (new PredictionResource($record))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Riwayat prediksi. Jika login -> milik user; jika tidak -> seluruhnya.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Prediction::query()
            ->when($request->user(), fn ($q) => $q->where('user_id', $request->user()->id))
            ->latest()
            ->limit((int) $request->integer('limit', 50));

        return PredictionResource::collection($query->get());
    }
}
