<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeviceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_device_registration_records_activity_log(): void
    {
        $this->postJson('/api/devices', [
            'fcm_token' => 'tok-123',
            'platform' => 'android',
            'user_uid' => 'uid-abc',
        ])
            ->assertStatus(201)
            ->assertJsonPath('message', 'Device terdaftar.');

        $this->assertDatabaseHas('activity_logs', ['event' => 'device.registered']);
    }

    public function test_device_registration_requires_fcm_token(): void
    {
        $this->postJson('/api/devices', ['platform' => 'android'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['fcm_token']);
    }
}
