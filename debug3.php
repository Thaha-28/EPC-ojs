<?php
chdir(__DIR__);
define('INDEX_FILE_LOCATION', __DIR__ . '/index.php');
$config = parse_ini_file(__DIR__ . '/config.inc.php', true);
echo "installed: ".json_encode($config['general']['installed'] ?? 'missing')."\n";
echo "base_url: ".json_encode($config['general']['base_url'] ?? 'missing')."\n";
echo "host: ".json_encode($config['database']['host'] ?? 'missing')."\n";
echo "name: ".json_encode($config['database']['name'] ?? 'missing')."\n";
require __DIR__ . '/lib/pkp/lib/vendor/autoload.php';
require __DIR__ . '/lib/pkp/includes/bootstrap.php';
use Illuminate\Support\Facades\DB;
try {
    echo "journals: ".DB::table('journals')->count()."\n";
    foreach(DB::table('journals')->get() as $j) print_r((array)$j);
    echo "issues: ".DB::table('issues')->count()."\n";
} catch(Exception $e){ echo "err: ".$e->getMessage()."\n"; }
