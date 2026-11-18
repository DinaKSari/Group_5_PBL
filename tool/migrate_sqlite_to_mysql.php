<?php
/**
 * Salin data SQLite lama ke MySQL tanpa mengubah id / created_at / updated_at.
 * Jalankan dari folder smart_farming/backend:
 *   php ../tool/migrate_sqlite_to_mysql.php            # cek saja (dry-run)
 *   php ../tool/migrate_sqlite_to_mysql.php --apply    # salin datanya
 */

$apply = in_array('--apply', $argv, true);

$env = [];
foreach (file(__DIR__.'/../smart_farming/backend/.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
    if (! str_starts_with($line, '#') && str_contains($line, '=')) {
        [$k, $v] = explode('=', $line, 2);
        $env[trim($k)] = trim($v);
    }
}

$sqlitePath = __DIR__.'/../smart_farming/backend/storage/app/private/backup-sqlite-2026-11-16.sqlite';
if (! is_readable($sqlitePath)) {
    fwrite(STDERR, "Backup SQLite tidak ditemukan di: $sqlitePath\n");
    exit(1);
}

$src = new PDO('sqlite:'.realpath($sqlitePath));
$src->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$dst = new PDO(
    sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
        $env['DB_HOST'] ?? '127.0.0.1', $env['DB_PORT'] ?? '3306', $env['DB_DATABASE'] ?? 'smart_farming'),
    $env['DB_USERNAME'] ?? 'root',
    $env['DB_PASSWORD'] ?? ''
);
$dst->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$dst->exec('SET FOREIGN_KEY_CHECKS = 0');

// Driver session/cache sudah pindah ke file di .env, jadi isinya tidak ikut.
$skip = ['cache', 'cache_locks', 'sessions'];

$srcTables = $src->query("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
    ->fetchAll(PDO::FETCH_COLUMN);

$totalCopied = 0;
foreach ($srcTables as $table) {
    if (in_array($table, $skip, true)) {
        printf("%-28s LEWAT (ephemeral, driver-nya file)\n", $table);
        continue;
    }
    $dstExists = $dst->query(
        'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = '.
        $dst->quote($table)
    )->fetchColumn();
    if (! $dstExists) {
        printf("%-28s LEWAT (tabel tidak ada di MySQL)\n", $table);
        continue;
    }

    $srcCols = array_map(fn ($r) => $r['name'], $src->query("PRAGMA table_info({$table})")->fetchAll(PDO::FETCH_ASSOC));
    $dstCols = $dst->query(
        'SELECT column_name FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = '.
        $dst->quote($table).' ORDER BY ordinal_position'
    )->fetchAll(PDO::FETCH_COLUMN);
    $shared = array_values(array_intersect($srcCols, $dstCols));
    $skipped = array_values(array_diff($srcCols, $dstCols));

    $srcCount = (int) $src->query("SELECT COUNT(*) FROM \"{$table}\"")->fetchColumn();
    $dstCount = (int) $dst->query("SELECT COUNT(*) FROM `{$table}`")->fetchColumn();

    if ($srcCount === 0) {
        printf("%-28s kosong\n", $table);
        continue;
    }
    if ($dstCount > 0) {
        printf("%-28s LEWAT (MySQL sudah berisi %d baris)\n", $table, $dstCount);
        continue;
    }

    $quoted = implode('`, `', $shared);
    $bind = implode(', ', array_fill(0, count($shared), '?'));
    $insert = $dst->prepare("INSERT INTO `{$table}` (`{$quoted}`) VALUES ({$bind})");
    $select = $src->query('SELECT "'.implode('", "', $shared).'" FROM "'.$table.'"');

    $n = 0;
    if ($apply) {
        $dst->beginTransaction();
        while ($row = $select->fetch(PDO::FETCH_NUM)) {
            $values = array_map(fn ($v) => $v === null ? null : (is_bool($v) ? (int) $v : $v), $row);
            $insert->execute($values);
            $n++;
        }
        $dst->commit();

        $pk = $src->query("PRAGMA table_info({$table})")->fetchAll(PDO::FETCH_ASSOC);
        $pk = array_column(array_filter($pk, fn ($c) => ($c['pk'] ?? 0) > 0), 'name');
        if (count($pk) === 1 && $pk[0] === 'id') {
            $max = (int) $dst->query("SELECT COALESCE(MAX(`id`), 0) FROM `{$table}`")->fetchColumn();
            $dst->exec("ALTER TABLE `{$table}` MODIFY `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT");
            $dst->exec("ALTER TABLE `{$table}` AUTO_INCREMENT = ".($max + 1));
        }
    } else {
        $n = $srcCount;
    }

    $totalCopied += $n;
    printf(
        "%-28s %s %d baris (%d kolom)%s\n",
        $table,
        $apply ? 'SALIN' : 'AKAN',
        $n,
        count($shared),
        $skipped ? ' — kolom diabaikan: '.implode(', ', $skipped) : ''
    );
}

$dst->exec('SET FOREIGN_KEY_CHECKS = 1');
printf("\n%s — total %d baris.\n", $apply ? 'Selesai' : 'Dry-run', $totalCopied);
if (! $apply) {
    echo "Tambahkan --apply untuk benar-benar menyalin.\n";
}
