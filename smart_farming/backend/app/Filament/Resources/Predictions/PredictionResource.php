<?php

namespace App\Filament\Resources\Predictions;

use App\Filament\Resources\Predictions\Pages\CreatePrediction;
use App\Filament\Resources\Predictions\Pages\EditPrediction;
use App\Filament\Resources\Predictions\Pages\ListPredictions;
use App\Filament\Resources\Predictions\Pages\ViewPrediction;
use App\Filament\Resources\Predictions\Schemas\PredictionForm;
use App\Filament\Resources\Predictions\Schemas\PredictionInfolist;
use App\Filament\Resources\Predictions\Tables\PredictionsTable;
use App\Models\Prediction;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class PredictionResource extends Resource
{
    protected static ?string $model = Prediction::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedRectangleStack;

    protected static ?string $recordTitleAttribute = 'lokasi';

    protected static ?string $navigationLabel = 'Riwayat Prediksi';

    protected static string|\UnitEnum|null $navigationGroup = 'Smart Farming';

    protected static ?string $modelLabel = 'Prediksi Panen';

    public static function form(Schema $schema): Schema
    {
        return PredictionForm::configure($schema);
    }

    public static function infolist(Schema $schema): Schema
    {
        return PredictionInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return PredictionsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListPredictions::route('/'),
            'view' => ViewPrediction::route('/{record}'),
        ];
    }
}
