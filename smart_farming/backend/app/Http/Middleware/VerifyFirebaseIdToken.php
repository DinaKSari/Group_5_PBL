<?php

namespace App\Http\Middleware;

use App\Contracts\FirebaseTokenVerifier;
use App\Exceptions\FirebaseConfigMissingException;
use App\Exceptions\InvalidIdTokenException;
use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

/**
 * Satu-satunya sumber identitas user di API.
 *
 * ID token Firebase divalidasi di server; uid hasil verifikasi yang dipakai untuk
 * scoping data, BUKAN parameter user_uid dari client.
 */
class VerifyFirebaseIdToken
{
    public function __construct(private readonly FirebaseTokenVerifier $verifier) {}

    public function handle(Request $request, Closure $next): Response
    {
        $idToken = $request->bearerToken();

        if (empty($idToken)) {
            return $this->deny('Sesi tidak valid: token autentikasi tidak dikirim.', 401);
        }

        try {
            $identity = $this->verifier->verify($idToken);
        } catch (InvalidIdTokenException $e) {
            $cause = $e->getPrevious();
            $reason = $cause?->getMessage() ?? 'No verifier detail available.';
            $reason = preg_replace(
                '/[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}/',
                '[REDACTED_TOKEN]',
                $reason,
            );
            Log::warning('Firebase ID token rejected.', [
                'path' => $request->path(),
                'cause' => $cause ? class_basename($cause) : null,
                'reason' => mb_substr($reason, 0, 240),
            ]);

            return $this->deny('Sesi tidak valid, silakan masuk kembali.', 401);
        } catch (FirebaseConfigMissingException $e) {
            // Konfigurasi server yang bermasalah: 503 agar client tidak logout massal.
            report($e);

            return $this->deny('Autentikasi server belum terkonfigurasi.', 503);
        }

        $request->attributes->set('firebase_identity', $identity);

        return $next($request);
    }

    private function deny(string $message, int $status): JsonResponse
    {
        return response()->json(['message' => $message], $status);
    }
}
