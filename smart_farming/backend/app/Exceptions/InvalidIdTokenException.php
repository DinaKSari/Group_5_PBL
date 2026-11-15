<?php

namespace App\Exceptions;

use RuntimeException;

/**
 * Token tidak dapat dipercaya: 401 untuk pemanggil, dan jangan pernah jatuh
 * ke 500 karena pesan/error Firebase bisa membocorkan konfigurasi internal.
 */
final class InvalidIdTokenException extends RuntimeException {}
