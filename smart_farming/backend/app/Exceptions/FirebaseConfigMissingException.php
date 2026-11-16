<?php

namespace App\Exceptions;

use RuntimeException;

/**
 * Konfigurasi server kurang (credentials path kosong / file tidak terbaca).
 * Dibedakan dari token invalid agar client tidak logout massal karena kesalahan kita:
 * middleware membalas 503, bukan 401.
 */
final class FirebaseConfigMissingException extends RuntimeException {}
