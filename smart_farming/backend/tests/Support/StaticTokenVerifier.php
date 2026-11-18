<?php

namespace Tests\Support;

use App\Contracts\FirebaseTokenVerifier;
use App\Exceptions\InvalidIdTokenException;
use App\Support\FirebaseIdentity;

/**
 * Verifier offline untuk test: memetakan string token -> identitas, tanpa
 * kredensial service account dan tanpa jaringan.
 */
final class StaticTokenVerifier implements FirebaseTokenVerifier
{
    /**
     * @param  array<string, FirebaseIdentity>  $identities
     */
    public function __construct(private readonly array $identities = []) {}

    public function verify(string $idToken): FirebaseIdentity
    {
        if (isset($this->identities[$idToken])) {
            return $this->identities[$idToken];
        }

        throw new InvalidIdTokenException("Token uji '{$idToken}' tidak dikenal.");
    }
}
