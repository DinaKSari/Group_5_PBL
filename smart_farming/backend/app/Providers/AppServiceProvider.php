<?php

namespace App\Providers;

use App\Contracts\FirebaseTokenVerifier;
use App\Services\Firebase\KreaitTokenVerifier;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(
            FirebaseTokenVerifier::class,
            fn () => new KreaitTokenVerifier(config('services.firebase.credentials'))
        );
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
