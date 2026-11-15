<?php

namespace Tests\Feature;

use App\Models\Prediction;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class PredictionApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.flask.url' => 'http://127.0.0.1:5057']);
    }

    private function mlPayload(array $overrides = []): array
    {
        return array_merge([
            'days_left' => 25,
            'estimated_total_hst' => 45,
            'features_used' => ['umur_hst' => 20, 'suhu' => 23, 'kelembapan' => 75, 'tds' => 700, 'ph' => 6],
            'classification' => ['growth_stage' => 'Vegetatif (Pembesaran)', 'stage_id' => 1],
            'clustering' => ['cluster_id' => 2, 'profile' => ['description' => 'Kondisi Pertumbuhan Normal']],
        ], $overrides);
    }

    private function validPayload(array $overrides = []): array
    {
        return array_merge([
            'lokasi' => 'Greenhouse Blok A',
            'user_uid' => 'uid-abc',
            'tanggal_input' => '2026-11-12',
            'umur_hst' => 20,
            'suhu' => 23.0,
            'kelembapan' => 75,
            'tds' => 700,
            'ph' => 6.0,
        ], $overrides);
    }

    public function test_predict_returns_201_and_persists_prediction_and_sensor_reading(): void
    {
        Http::fake(fn () => Http::response($this->mlPayload(), 200));

        $response = $this->postJson('/api/predict', $this->validPayload());

        $response->assertStatus(201)
            ->assertJsonPath('days_left', 25)
            ->assertJsonPath('lokasi', 'Greenhouse Blok A')
            ->assertJsonPath('harvest_date', '2026-12-07')
            ->assertJsonStructure([
                'id', 'days_left', 'lokasi', 'harvest_date',
                'classification' => ['growth_stage', 'stage_id'],
                'clustering' => ['cluster_id', 'profile' => ['description']],
            ]);

        $this->assertDatabaseHas('predictions', [
            'user_uid' => 'uid-abc',
            'lokasi' => 'Greenhouse Blok A',
            'days_left' => 25,
        ]);

        $prediction = Prediction::first();
        $this->assertNotNull($prediction->ml_result);
        $this->assertSame(2, $prediction->ml_result['clustering']['cluster_id']);

        // store() otomatis menurunkan satu pembacaan sensor dari parameter prediksi
        $this->assertDatabaseHas('sensor_readings', [
            'user_uid' => 'uid-abc',
            'lokasi' => 'Greenhouse Blok A',
        ]);
    }

    public function test_predict_rejects_out_of_range_value(): void
    {
        Http::fake(fn () => Http::response($this->mlPayload(), 200));

        $this->postJson('/api/predict', $this->validPayload(['umur_hst' => 0]))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['umur_hst']);

        $this->assertDatabaseCount('predictions', 0);
    }

    public function test_predict_requires_all_ml_features(): void
    {
        $payload = $this->validPayload();
        unset($payload['suhu']);

        $this->postJson('/api/predict', $payload)
            ->assertStatus(422)
            ->assertJsonValidationErrors(['suhu']);
    }

    public function test_predict_returns_503_when_ml_service_unavailable(): void
    {
        Http::fake(['*' => Http::response('', 503)]);

        $this->postJson('/api/predict', $this->validPayload())
            ->assertStatus(503);

        $this->assertDatabaseCount('predictions', 0);
    }

    public function test_predictions_are_scoped_by_user_uid(): void
    {
        $this->makePrediction('uid-1', 'Blok Satu');
        $this->makePrediction('uid-2', 'Blok Dua');

        $response = $this->getJson('/api/predictions?user_uid=uid-1&limit=10');

        $response->assertStatus(200);
        $data = $response->json('data');
        $this->assertCount(1, $data);
        $this->assertSame('Blok Satu', $data[0]['lokasi']);
        $this->assertArrayHasKey('params', $data[0]);
    }

    private function makePrediction(string $uid, string $lokasi): Prediction
    {
        return Prediction::create([
            'user_uid' => $uid,
            'lokasi' => $lokasi,
            'tanggal_input' => '2026-11-12',
            'umur_hst' => 20,
            'suhu' => 23,
            'kelembapan' => 75,
            'tds' => 700,
            'ph' => 6,
            'days_left' => 25,
            'estimated_total_hst' => 45,
            'harvest_date' => '2026-12-07',
        ]);
    }
}
