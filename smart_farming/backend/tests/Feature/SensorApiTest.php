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
        $this->withFirebaseUser('uid-a')->postJson('/api/sensor', [
            'umur_hst' => 10,
            'suhu' => 22,
            'kelembapan' => 60,
            'tds' => 500,
            'ph' => 6.2,
        ])
            ->assertStatus(201)
            ->assertJsonPath('data.lokasi', 'Kebun')
            ->assertJsonPath('data.source', 'manual');

        $this->assertDatabaseHas('sensor_readings', [
            'user_uid' => 'uid-a',
            'ph' => 6.2,
            'lokasi' => 'Kebun',
        ]);
    }

    public function test_sensor_store_ignores_user_uid_from_body(): void
    {
        $this->withFirebaseUser('uid-a')->postJson('/api/sensor', [
            'umur_hst' => 10,
            'suhu' => 22,
            'kelembapan' => 60,
            'tds' => 500,
            'ph' => 6.2,
            'user_uid' => 'uid-punya-user-lain',
        ])->assertStatus(201);

        $this->assertDatabaseMissing('sensor_readings', ['user_uid' => 'uid-punya-user-lain']);
    }

    public function test_sensor_store_rejects_out_of_range(): void
    {
        $this->withFirebaseUser('uid-a')->postJson('/api/sensor', [
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
        $this->withFirebaseUser('uid-kosong')
            ->getJson('/api/sensor/latest')
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

        $this->withFirebaseUser('uid-a')->getJson('/api/sensor/latest')
            ->assertStatus(200)
            ->assertJsonPath('data.id', $baru->id)
            ->assertJsonPath('data.lokasi', 'Blok Baru');
    }

    public function test_query_user_uid_cannot_read_another_users_reading(): void
    {
        SensorReading::create($this->reading('uid-a', 'Blok Satu'));

        $this->withFirebaseUser('uid-b')->getJson('/api/sensor/latest?user_uid=uid-a')
            ->assertStatus(200)
            ->assertJsonPath('data', null);
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
