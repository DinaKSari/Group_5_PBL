<?php

namespace App\Services\Firebase;

use App\Contracts\FirebaseTokenVerifier;
use App\Exceptions\FirebaseConfigMissingException;
use App\Exceptions\InvalidIdTokenException;
use App\Support\FirebaseIdentity;
use Kreait\Firebase\Contract\Auth as AuthContract;
use Kreait\Firebase\Factory;
use Throwable;

class KreaitTokenVerifier implements FirebaseTokenVerifier
{
    private ?AuthContract $auth = null;

    public function __construct(private readonly ?string $credentialsPath) {}

    public function verify(string $idToken): FirebaseIdentity
    {
        try {
            $token = $this->auth()->verifyIdToken($idToken);
        } catch (FirebaseConfigMissingException $e) {
            throw $e;
        } catch (Throwable $e) {
            throw new InvalidIdTokenException('ID token Firebase tidak valid atau kedaluwarsa.', previous: $e);
        }

        $uid = $token->claims()->get('sub');

        if (! is_string($uid) || $uid === '') {
            throw new InvalidIdTokenException('ID token tidak memuat klaim sub.');
        }

        return new FirebaseIdentity(
            uid: $uid,
            email: $this->claim($token->claims()->get('email')),
            name: $this->claim($token->claims()->get('name')),
        );
    }

    private function claim(mixed $value): ?string
    {
        return is_string($value) && $value !== '' ? $value : null;
    }

    private function auth(): AuthContract
    {
        if ($this->auth !== null) {
            return $this->auth;
        }

        $path = $this->credentialsPath === null ? '' : trim($this->credentialsPath);

        // Path relatif dibaca terhadap root aplikasi, supaya `artisan serve`,
        // queue worker, dan test punya perilaku yang sama.
        $isAbsolute = preg_match('#^([A-Za-z]:[\\\\/]|[\\\\/])#', $path) === 1;
        if ($path !== '' && ! $isAbsolute) {
            $path = base_path($path);
        }

        if ($path === '' || ! is_readable($path)) {
            throw new FirebaseConfigMissingException(
                'Kredensial Firebase tidak terbaca. Set FIREBASE_CREDENTIALS ke path service account JSON.'
            );
        }

        return $this->auth = (new Factory)->withServiceAccount($path)->createAuth();
    }
}
