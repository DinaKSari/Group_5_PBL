<?php

namespace Tests;

use App\Contracts\FirebaseTokenVerifier;
use App\Support\FirebaseIdentity;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Tests\Support\StaticTokenVerifier;

abstract class TestCase extends BaseTestCase
{
    /**
     * Autentikasi request sebagai user Firebase tertentu, tanpa jaringan.
     */
    protected function withFirebaseUser(string $uid, ?string $email = null, ?string $name = null): static
    {
        $this->app->bind(
            FirebaseTokenVerifier::class,
            fn () => new StaticTokenVerifier([
                "test-token-{$uid}" => new FirebaseIdentity($uid, $email, $name),
            ])
        );

        return $this->withHeader('Authorization', "Bearer test-token-{$uid}");
    }
}
