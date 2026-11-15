<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('predictions', function (Blueprint $table) {
            $table->string('user_uid')->nullable()->after('user_id');
            $table->json('ml_result')->nullable()->after('meta');
            $table->index(['user_uid', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::table('predictions', function (Blueprint $table) {
            $table->dropIndex(['user_uid', 'created_at']);
            $table->dropColumn(['user_uid', 'ml_result']);
        });
    }
};
