<?php
// Debug OJS install and DB
chdir(__DIR__);
define('INDEX_FILE_LOCATION', __DIR__ . '/index.php');
$config = parse_ini_file(__DIR__ . '/config.inc.php', true);
echo "installed: " . ($config['general']['installed'] ?? 'not set') . "\n";
echo "base_url: " . ($config['general']['base_url'] ?? 'not set') . "\n";
echo "db driver: " . ($config['database']['driver'] ?? 'not set') . "\n";
echo "db host: " . ($config['database']['host'] ?? 'not set') . "\n";
echo "db name: " . ($config['database']['name'] ?? 'not set') . "\n";
echo "db user: " . ($config['database']['username'] ?? 'not set') . "\n";
echo "allowed_hosts: " . ($config['general']['allowed_hosts'] ?? 'not set') . "\n";

// Try DB connection via same method as PKPContainer
require __DIR__ . '/lib/pkp/lib/vendor/autoload.php';
require __DIR__ . '/lib/pkp/includes/bootstrap.php';
use Illuminate\Support\Facades\DB;
try {
    $journals = DB::table('journals')->get();
    echo "journals count: " . count($journals) . "\n";
    foreach ($journals as $j) {
        print_r((array)$j);
    }
    $issues = DB::table('issues')->get();
    echo "issues count: " . count($issues) . "\n";
    $users = DB::table('users')->select('user_id','username')->get();
    echo "users:\n";
    foreach ($users as $u) print_r((array)$u);
} catch (Exception $e) {
    echo "DB error: " . $e->getMessage() . "\n";
}
