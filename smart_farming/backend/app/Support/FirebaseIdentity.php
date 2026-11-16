<?php

namespace App\Support;

/**
 * Identitas petani hasil verifikasi ID token Firebase.
 *
 * Nilai ini TIDAK boleh berasal dari body/query request: uid adalah satu-satunya
 * kunci scoping data di seluruh API.
 */
final readonly class FirebaseIdentity
{
    public function __construct(
        public string $uid,
        public ?string $email = null,
        public ?string $name = null,
    ) {}
}
