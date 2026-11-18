<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Resend, Postmark, AWS, and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'flask' => [
        'url' => env('FLASK_ML_BASE_URL', 'http://127.0.0.1:5000'),
        'timeout' => (int) env('FLASK_ML_TIMEOUT', 8),
        // Rahasia bersama: Flask menolak panggilan tanpa header X-ML-Token yang
        // sama. Kosong = Flask menolak semuanya (lihat ML/api/app.py).
        'secret' => env('FLASK_ML_SHARED_SECRET', ''),
    ],

    /*
    |--------------------------------------------------------------------------
    | Firebase (verifikasi ID token user API)
    |--------------------------------------------------------------------------
    |
    | credentials = path ABSOLUT atau relatif dari aplikasi ke service account JSON.
    | File-nya TIDAK boleh masuk git; simpan di storage/app/private/.
    |
    */

    'firebase' => [
        'credentials' => env('FIREBASE_CREDENTIALS'),
        'project_id' => env('FIREBASE_PROJECT_ID'),
    ],

];
