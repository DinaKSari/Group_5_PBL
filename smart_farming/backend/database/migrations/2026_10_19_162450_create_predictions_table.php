<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('predictions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('lokasi');
            $table->date('tanggal_input')->nullable();
            $table->decimal('umur_hst', 5, 2);
            $table->decimal('suhu', 5, 2);
            $table->decimal('kelembapan', 5, 2);
            $table->decimal('tds', 6, 2);
            $table->decimal('ph', 4, 2);
            $table->unsignedInteger('days_left');
            $table->unsignedInteger('estimated_total_hst');
            $table->date('harvest_date');
            $table->string('ml_model')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('predictions');
    }
};
