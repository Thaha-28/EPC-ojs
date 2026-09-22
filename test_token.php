<?php
// Debug token generation
require __DIR__ . '/lib/pkp/lib/vendor/autoload.php';
use PKP\config\Config;
chdir(__DIR__);
define('INDEX_FILE_LOCATION', __DIR__ . '/index.php');
require __DIR__ . '/lib/pkp/includes/bootstrap.php';
use APP\facades\Repo;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

$secret = Config::getVar('security', 'api_key_secret');
echo "SECRET: " . $secret . "\n";
echo "SECRET len: " . strlen($secret) . "\n";

$user = Repo::user()->get(1);
if (!$user) { echo "No user 1\n"; exit; }
$apiKey = $user->getData('apiKey');
$enabled = $user->getData('apiKeyEnabled');
echo "apiKey: $apiKey\n";
echo "enabled: $enabled\n";

$jwt = JWT::encode([$apiKey], $secret, 'HS256');
echo "JWT: $jwt\n";

try {
    $decoded = JWT::decode($jwt, new Key($secret, 'HS256'));
    echo "Decode OK: " . json_encode($decoded) . "\n";
} catch (Exception $e) {
    echo "Decode fail: " . $e->getMessage() . "\n";
}

// Also test with the Vercel token
$vercelJwt = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.WyI4ODcyNzYwOTg5ZmIwNjcyOGYwYjk5MTQ2Y2JjYmZjNTViYTE1MTIzZWM4ODk1OTdmZTM2ZmJhZjYwMzljOWYwIl0.CS2bkpiGiOCGW2j0TupVVkf-KbLZphXQfzVMAZajvDI';
echo "VERCEL JWT: $vercelJwt\n";
try {
    $d2 = JWT::decode($vercelJwt, new Key($secret, 'HS256'));
    echo "Vercel decode OK: " . json_encode($d2) . "\n";
} catch (Exception $e) {
    echo "Vercel decode fail: " . $e->getMessage() . "\n";
}

// Check DB for apiKey
$mysqli = new mysqli();
echo "Done\n";
