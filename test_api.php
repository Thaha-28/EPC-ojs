<?php
// Test internal API call
require __DIR__ . '/lib/pkp/lib/vendor/autoload.php';
use PKP\config\Config;
chdir(__DIR__);
define('INDEX_FILE_LOCATION', __DIR__ . '/index.php');
require __DIR__ . '/lib/pkp/includes/bootstrap.php';
use APP\facades\Repo;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

$secret = Config::getVar('security', 'api_key_secret');
$user = Repo::user()->get(1);
$apiKey = $user->getData('apiKey');
$jwt = JWT::encode([$apiKey], $secret, 'HS256');
echo "Testing with JWT: $jwt\n";

// Try to decode as OJS does
$middleware = new \PKP\classes\middleware\DecodeApiTokenWithValidation();
try {
    // Simulate decoding
    $decoded = JWT::decode($jwt, new Key($secret, 'HS256'));
    echo "Decode OK: " . json_encode($decoded) . "\n";
    // Check user lookup
    $userFromToken = Repo::user()->getBySetting('apiKey', $decoded[0]);
    var_dump($userFromToken ? $userFromToken->getUsername() : 'not found');
} catch (Exception $e) {
    echo "Fail: " . $e->getMessage() . "\n";
}

// Try to call the issues API via internal request
$host = 'https://epc-ojs.onrender.com';
$ch = curl_init($host . '/index.php/epc/api/v1/issues');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ["Accept: application/json", "Authorization: Bearer $jwt"]);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
$res = curl_exec($ch);
$code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
echo "Internal curl code: $code\n";
echo "Body: " . substr($res, 0, 2000) . "\n";
curl_close($ch);
