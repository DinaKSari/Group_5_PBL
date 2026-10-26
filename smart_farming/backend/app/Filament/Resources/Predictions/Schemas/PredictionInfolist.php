<?php

namespace App\Filament\Resources\Predictions\Schemas;

use App\Models\Prediction;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Schema;

class PredictionInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextEntry::make('lokasi')->label('Lokasi Tanam'),
                TextEntry::make('tanggal_input')->label('Tanggal Input')->date('d M Y'),
                TextEntry::make('days_left')
                    ->label('Status')
                    ->badge()
                    ->getStateUsing(fn (Prediction $r): string => $r->is_ready ? 'Siap Panen' : "{$r->days_left} hari lagi")
                    ->color(fn (Prediction $r): string => $r->is_ready ? 'success' : 'warning'),
                TextEntry::make('harvest_date')->label('Estimasi Tanggal Panen')->date('l, d M Y'),
                TextEntry::make('estimated_total_hst')->label('Total Siklus (HST)'),
                TextEntry::make('umur_hst')->label('Umur')->suffix(' hari'),
                TextEntry::make('suhu')->label('Suhu')->suffix(' °C'),
                TextEntry::make('kelembapan')->label('Kelembapan')->suffix(' %'),
                TextEntry::make('tds')->label('TDS')->suffix(' ppm'),
                TextEntry::make('ph')->label('pH'),
                TextEntry::make('created_at')->label('Disimpan')->dateTime(),
            ]);
    }
}
