<?php

namespace App\Services;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Klien ke microservice ML Flask. Flask stateless: hanya menghitung estimasi.
 */
class MlInferenceService
{
    /**
     * @param  array<string, float>  $features
     * @return array<string, mixed>
     */
    public function predict(array $features): array
    {
        $url = rtrim((string) config('services.flask.url'), '/').'/predict';
        $timeout = (int) config('services.flask.timeout', 8);

        try {
            $response = Http::timeout($timeout)->asJson()->post($url, $features);
        } catch (ConnectionException $e) {
            throw new HttpException(503, 'Layanan prediksi ML tidak dapat dihubungi.');
        }

        if ($response->status() === 503) {
            throw new HttpException(503, 'Model ML belum siap. Jalankan pelatihan pada microservice Flask.');
        }

        if ($response->status() === 422) {
            $errors = $response->json('errors', ['Input ditolak oleh model.']);
            throw new HttpException(422, implode(' ', $errors));
        }

        if (! $response->successful()) {
            throw new HttpException(502, 'Microservice ML mengembalikan respons tak terduga.');
        }

        return $response->json();
    }
}
