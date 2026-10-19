<?php

namespace App\Filament\Resources\Predictions\Tables;

use App\Models\Prediction;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Table;

class PredictionsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('lokasi')->label('Lokasi')->searchable()->wrap(),
                TextColumn::make('days_left')
                    ->label('Hari Lagi')
                    ->badge()
                    ->getStateUsing(fn (Prediction $record): string => $record->is_ready ? 'Siap Panen' : "{$record->days_left} hari")
                    ->color(fn (Prediction $record): string => $record->is_ready ? 'success' : 'warning'),
                TextColumn::make('harvest_date')->label('Estimasi Panen')->date('d M Y'),
                TextColumn::make('umur_hst')->label('Umur')->suffix(' hst'),
                TextColumn::make('suhu')->label('Suhu')->suffix(' °C'),
                TextColumn::make('kelembapan')->label('RH')->suffix(' %')->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('tds')->label('TDS')->suffix(' ppm')->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('ph')->label('pH')->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('created_at')->label('Disimpan')->dateTime()->since()->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Filter::make('ready')
                    ->label('Hanya siap panen')
                    ->query(fn ($query) => $query->where('days_left', '<=', 0)),
            ])
            ->recordActions([
                ViewAction::make(),
                DeleteAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ])
            ->emptyStateHeading('Belum ada prediksi');
    }
}
