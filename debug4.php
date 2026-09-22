<?php
chdir(__DIR__);
define('INDEX_FILE_LOCATION', __DIR__ . '/index.php');
$config = parse_ini_file(__DIR__ . '/config.inc.php', true);
echo "installed: ".json_encode($config['general']['installed'] ?? 'missing')."\n";
echo "base_url: ".json_encode($config['general']['base_url'] ?? 'missing')."\n";
echo "force_ssl: ".json_encode($config['security']['force_ssl'] ?? 'missing')."\n";
echo "force_login_ssl: ".json_encode($config['security']['force_login_ssl'] ?? 'missing')."\n";
echo "trust_x_forwarded_for: ".json_encode($config['general']['trust_x_forwarded_for'] ?? 'missing')."\n";
echo "allowed_hosts: ".json_encode($config['general']['allowed_hosts'] ?? 'missing')."\n";
