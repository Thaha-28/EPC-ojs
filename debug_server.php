<?php
echo "SERVER:\n";
foreach ($_SERVER as $k => $v) {
    if (stripos($k, 'forward') !== false || stripos($k, 'https') !== false || stripos($k, 'proto') !== false || stripos($k, 'host') !== false) {
        echo "$k: $v\n";
    }
}
echo "\nHeaders:\n";
foreach (getallheaders() as $k => $v) {
    if (stripos($k, 'forward') !== false || stripos($k, 'proto') !== false) {
        echo "$k: $v\n";
    }
}
echo "\nConfig trust_x_forwarded_for: ";
require __DIR__ . '/lib/pkp/lib/vendor/autoload.php';
chdir(__DIR__);
define('INDEX_FILE_LOCATION', __DIR__ . '/index.php');
$config = parse_ini_file(__DIR__ . '/config.inc.php', true);
echo json_encode($config['general']['trust_x_forwarded_for'] ?? 'missing') . "\n";
echo "force_ssl: " . json_encode($config['security']['force_ssl'] ?? 'missing') . "\n";
echo "base_url: " . json_encode($config['general']['base_url'] ?? 'missing') . "\n";
