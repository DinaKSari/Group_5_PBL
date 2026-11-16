<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeviceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_device_registration_records_activity_log(): void
    {
        $this->withFirebaseUser('uid-abc')->postJson('/api/devices', [
            'fcm_token' => 'tok-123',
            'platform' => 'android',
        ])
            ->assertStatus(201)
            ->assertJsonPath('message', 'Device terdaftar.');

        $this->assertDatabaseHas('activity_logs', ['event' => 'device.registered']);
    }

    public function test_device_registration_does_not_log_raw_fcm_token(): void
    {
        $this->withFirebaseUser('uid-abc')->postJson('/api/devices', [
            'fcm_token' => 'rahasia-token-yang-jangan-sampai-tercetak',
            'platform' => 'android',
        ])->assertStatus(201);

        $log = \App\Models\ActivityLog::where('event', 'device.registered')->firstOrFail();
        $properties = (array) $log->properties;

        $this->assertStringNotContainsString(
            'rahasia-token-yang-jangan-sampai-tercetak',
            json_encode($properties)
        );
        $this->assertArrayHasKey('fcm_token_fingerprint', $properties);
        $this->assertSame('uid-abc', $properties['user_uid']);
    }

    public function test_device_registration_requires_fcm_token(): void
    {
        $this->withFirebaseUser('uid-abc')->postJson('/api/devices', ['platform' => 'android'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['fcm_token']);
    }
}
