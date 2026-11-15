<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SensorReading extends Model
{
    protected $fillable = [
        'user_uid',
        'lokasi',
        'umur_hst',
        'suhu',
        'kelembapan',
        'tds',
        'ph',
        'source',
    ];

    protected function casts(): array
    {
        return [
            'umur_hst' => 'float',
            'suhu' => 'float',
            'kelembapan' => 'float',
            'tds' => 'float',
            'ph' => 'float',
        ];
    }
}
