<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PredictionResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'lokasi' => $this->lokasi,
            'tanggal_input' => optional($this->tanggal_input)->toDateString(),
            'harvest_date' => optional($this->harvest_date)->toDateString(),
            'days_left' => $this->days_left,
            'estimated_total_hst' => $this->estimated_total_hst,
            'ready' => $this->is_ready,
            'params' => [
                'umur_hst' => $this->umur_hst,
                'suhu' => $this->suhu,
                'kelembapan' => $this->kelembapan,
                'tds' => $this->tds,
                'ph' => $this->ph,
            ],
            'created_at' => optional($this->created_at)->toIso8601String(),
        ];
    }
}
