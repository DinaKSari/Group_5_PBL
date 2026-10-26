<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Prediction extends Model
{
    protected $fillable = [
        'user_id',
        'lokasi',
        'tanggal_input',
        'umur_hst',
        'suhu',
        'kelembapan',
        'tds',
        'ph',
        'days_left',
        'estimated_total_hst',
        'harvest_date',
        'ml_model',
        'meta',
    ];

    protected function casts(): array
    {
        return [
            'tanggal_input' => 'date',
            'harvest_date' => 'date',
            'umur_hst' => 'float',
            'suhu' => 'float',
            'kelembapan' => 'float',
            'tds' => 'float',
            'ph' => 'float',
            'days_left' => 'integer',
            'estimated_total_hst' => 'integer',
            'meta' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function getIsReadyAttribute(): bool
    {
        return $this->days_left <= 0;
    }
}
