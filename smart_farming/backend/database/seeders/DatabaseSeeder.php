<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use RuntimeException;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Membuat/memperbarui satu akun admin Filament dari env.
     * Tidak ada kredensial default: seeder sengaja gagal kalau password kosong,
     * supaya `php artisan seed` di server tidak pernah meninggalkan akun 12345678.
     */
    public function run(): void
    {
        $email = config('auth.panel_admin.email');
        $password = config('auth.panel_admin.password');

        if (empty($email) || empty($password)) {
            throw new RuntimeException(
                'Seeder admin butuh ADMIN_EMAIL dan ADMIN_PASSWORD di .env '.
                '(lihat backend/.env.example). Tidak ada akun default yang dibuat.'
            );
        }

        if (strlen((string) $password) < 12) {
            throw new RuntimeException('ADMIN_PASSWORD minimal 12 karakter.');
        }

        User::updateOrCreate(
            ['email' => $email],
            [
                'name' => config('auth.panel_admin.name', 'admin'),
                'password' => Hash::make($password),
            ]
        );

        $this->command?->info("Admin {$email} siap (kata sandi dari env, tidak dicetak).");
    }
}
