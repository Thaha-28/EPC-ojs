<?php
echo "raw config lines:\n";
$lines = file(__DIR__ . '/config.inc.php');
foreach ($lines as $i => $line) {
    if (stripos($line, 'allowed_hosts') !== false || stripos($line, 'base_url') !== false || stripos($line, 'force_ssl') !== false || stripos($line, 'trust_x_forwarded') !== false || stripos($line, 'installed') !== false) {
        echo ($i+1) . ": " . $line;
    }
}
echo "\nparsed:\n";
$config = parse_ini_file(__DIR__ . '/config.inc.php', true);
echo "installed: " . json_encode($config['general']['installed'] ?? 'missing') . "\n";
echo "base_url: " . json_encode($config['general']['base_url'] ?? 'missing') . "\n";
echo "allowed_hosts: " . json_encode($config['general']['allowed_hosts'] ?? 'missing') . "\n";
echo "trust_x_forwarded_for: " . json_encode($config['general']['trust_x_forwarded_for'] ?? 'missing') . "\n";
echo "force_ssl: " . json_encode($config['security']['force_ssl'] ?? 'missing') . "\n";
