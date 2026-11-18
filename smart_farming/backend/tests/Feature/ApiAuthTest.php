<?php

namespace Tests\Feature;

use App\Contracts\FirebaseTokenVerifier;
use App\Services\Firebase\KreaitTokenVerifier;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Gerbang autentikasi: tidak ada endpoint data yang melayani permintaan tanpa
 * ID token Firebase yang tervalidasi.
 */
class ApiAuthTest extends TestCase
{
    use RefreshDatabase;

    /**
     * @return array<string, array{0: string, 1: string}>
     */
    public static function protectedEndpoints(): array
    {
        return [
            'POST /api/predict' => ['postJson', '/api/predict'],
            'GET /api/predictions' => ['getJson', '/api/predictions'],
            'POST /api/sensor' => ['postJson', '/api/sensor'],
            'GET /api/sensor/latest' => ['getJson', '/api/sensor/latest'],
            'POST /api/devices' => ['postJson', '/api/devices'],
        ];
    }

    #[\PHPUnit\Framework\Attributes\DataProvider('protectedEndpoints')]
    public function test_endpoints_reject_request_without_token(string $method, string $url): void
    {
        $this->{$method}($url)->assertStatus(401);
    }

    public function test_endpoints_reject_token_that_is_not_verifiable(): void
    {
        // StaticTokenVerifier terdaftar dari helper withFirebaseUser; token lain unknown.
        $this->withFirebaseUser('uid-abc')->getJson('/api/predictions')->assertStatus(200);

        $this->withHeader('Authorization', 'Bearer token-palsu')
            ->getJson('/api/predictions')
            ->assertStatus(401);
    }

    public function test_missing_credentials_fail_closed_as_503_not_as_unauthenticated_access(): void
    {
        config(['services.firebase.credentials' => null]);
        $this->app->bind(FirebaseTokenVerifier::class, fn () => new KreaitTokenVerifier(null));

        $this->withHeader('Authorization', 'Bearer apa-adanya')
            ->getJson('/api/predictions')
            ->assertStatus(503);

        $this->assertDatabaseCount('predictions', 0);
    }

    public function test_identity_from_token_cannot_be_overridden_by_query_parameters(): void
    {
        $this->makeReading('uid-owner');

        // uid-pretender meniru milik uid-owner lewat query string.
        $this->withFirebaseUser('uid-pretender')->getJson('/api/sensor/latest?user_uid=uid-owner')
            ->assertStatus(200)
            ->assertJsonPath('data', null);

        $this->withFirebaseUser('uid-owner')->getJson('/api/sensor/latest')
            ->assertStatus(200)
            ->assertJsonPath('data.lokasi', 'Blok Pemilik');
    }

    private function makeReading(string $uid): void
    {
        \App\Models\SensorReading::create([
            'user_uid' => $uid,
            'lokasi' => 'Blok Pemilik',
            'umur_hst' => 12,
            'suhu' => 25,
            'kelembapan' => 65,
            'tds' => 600,
            'ph' => 6.4,
            'source' => 'manual',
        ]);
    }
}
