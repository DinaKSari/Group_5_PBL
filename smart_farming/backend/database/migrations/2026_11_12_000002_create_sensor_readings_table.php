<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sensor_readings', function (Blueprint $table) {
            $table->id();
            $table->string('user_uid')->nullable();
            $table->string('lokasi')->nullable();
            $table->decimal('umur_hst', 5, 2);
            $table->decimal('suhu', 5, 2);
            $table->decimal('kelembapan', 5, 2);
            $table->decimal('tds', 6, 2);
            $table->decimal('ph', 4, 2);
            $table->string('source')->default('manual');
            $table->timestamps();

            $table->index(['user_uid', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sensor_readings');
    }
};
