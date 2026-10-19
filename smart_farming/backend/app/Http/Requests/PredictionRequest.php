<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class PredictionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'lokasi' => ['required', 'string', 'max:120'],
            'tanggal_input' => ['nullable', 'date'],
            'umur_hst' => ['required', 'numeric', 'between:1,45'],
            'suhu' => ['required', 'numeric', 'between:10,40'],
            'kelembapan' => ['required', 'numeric', 'between:30,100'],
            'tds' => ['required', 'numeric', 'between:200,1500'],
            'ph' => ['required', 'numeric', 'between:4,9'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'lokasi.required' => 'Lokasi tanam wajib diisi.',
            'umur_hst.between' => 'Umur tanaman harus antara 1 sampai 45 hari.',
            'suhu.between' => 'Suhu harus antara 10 sampai 40 derajat Celcius.',
            'kelembapan.between' => 'Kelembapan harus antara 30 sampai 100%.',
            'tds.between' => 'TDS harus antara 200 sampai 1500 ppm.',
            'ph.between' => 'pH harus antara 4 sampai 9.',
            '*.numeric' => 'Nilai :attribute harus berupa angka.',
            '*.required' => 'Field :attribute wajib diisi.',
        ];
    }

    /**
     * Hanya 5 variabel yang dikirim ke model ML.
     *
     * @return array<string, float>
     */
    public function mlFeatures(): array
    {
        return collect($this->only(['umur_hst', 'suhu', 'kelembapan', 'tds', 'ph']))
            ->map(fn ($v) => (float) $v)
            ->all();
    }
}
