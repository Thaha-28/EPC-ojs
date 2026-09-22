<?php
chdir(__DIR__);
define('INDEX_FILE_LOCATION', __DIR__ . '/index.php');
$config = parse_ini_file(__DIR__ . '/config.inc.php', true);
echo "installed: " . json_encode($config['general']['installed'] ?? 'missing') . "\n";
echo "base_url: " . json_encode($config['general']['base_url'] ?? 'missing') . "\n";
echo "trust_x_forwarded_for: " . json_encode($config['general']['trust_x_forwarded_for'] ?? 'missing') . "\n";
echo "force_ssl: " . json_encode($config['security']['force_ssl'] ?? 'missing') . "\n";
echo "db host: " . json_encode($config['database']['host'] ?? 'missing') . "\n";
echo "db name: " . json_encode($config['database']['name'] ?? 'missing') . "\n";
require __DIR__ . '/lib/pkp/lib/vendor/autoload.php';
require __DIR__ . '/lib/pkp/includes/bootstrap.php';
use Illuminate\Support\Facades\DB;
try {
    $c = DB::table('journals')->count();
    echo "journals: $c\n";
    $j = DB::table('journals')->first();
    print_r((array)$j);
} catch (Exception $e) { echo "DB err: " . $e->getMessage() . "\n"; }
