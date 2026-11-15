<?php

namespace Tests\Feature;

use App\Models\SensorReading;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SensorApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_sensor_store_creates_reading_with_defaults(): void
    {
        $this->postJson('/api/sensor', [
            'umur_hst' => 10,
            'suhu' => 22,
            'kelembapan' => 60,
            'tds' => 500,
            'ph' => 6.2,
        ])
            ->assertStatus(201)
            ->assertJsonPath('data.lokasi', 'Kebun')
            ->assertJsonPath('data.source', 'manual');

        $this->assertDatabaseHas('sensor_readings', ['ph' => 6.2, 'lokasi' => 'Kebun']);
    }

    public function test_sensor_store_rejects_out_of_range(): void
    {
        $this->postJson('/api/sensor', [
            'umur_hst' => 10,
            'suhu' => 22,
            'kelembapan' => 60,
            'tds' => 500,
            'ph' => 10, // di atas maksimum 9
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['ph']);
    }

    public function test_sensor_latest_is_null_when_no_data(): void
    {
        $this->getJson('/api/sensor/latest?user_uid=uid-kosong')
            ->assertStatus(200)
            ->assertJsonPath('data', null)
            ->assertJsonPath('message', 'Belum ada data sensor.');
    }

    public function test_sensor_latest_returns_most_recent_for_user(): void
    {
        $lama = SensorReading::create($this->reading('uid-a', 'Blok Lama'));
        $baru = SensorReading::create($this->reading('uid-a', 'Blok Baru'));
        SensorReading::create($this->reading('uid-b', 'Blok Orang Lain'));

        // pastikan ordering: bacaan lama dibuat lebih tua dari yang baru
        SensorReading::whereKey($lama->id)->update(['created_at' => now()->subDay()]);

        $response = $this->getJson('/api/sensor/latest?user_uid=uid-a');

        $response->assertStatus(200)
            ->assertJsonPath('data.id', $baru->id)
            ->assertJsonPath('data.lokasi', 'Blok Baru');
    }

    private function reading(string $uid, string $lokasi): array
    {
        return [
            'user_uid' => $uid,
            'lokasi' => $lokasi,
            'umur_hst' => 15,
            'suhu' => 24,
            'kelembapan' => 70,
            'tds' => 650,
            'ph' => 6.0,
            'source' => 'manual',
        ];
    }
}
