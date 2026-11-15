<?php

namespace App\Contracts;

use App\Exceptions\FirebaseConfigMissingException;
use App\Exceptions\InvalidIdTokenException;
use App\Support\FirebaseIdentity;

/**
 * Memisahkan middleware dari implementasi Kreait supaya test bisa memverifikasi
 * token tanpa kredensial service account dan tanpa jaringan.
 */
interface FirebaseTokenVerifier
{
    /**
     * @throws InvalidIdTokenException token salah, kedaluwarsa, atau bukan ID token Firebase
     * @throws FirebaseConfigMissingException kredensial service account belum dipasang
     */
    public function verify(string $idToken): FirebaseIdentity;
}
