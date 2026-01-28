<?php
/**
 * Honeypot Strike Handler
 */
// Configuration
define('UNIQUE_KEY','monday-is-the-best'); // A passphrase MUST be set!
define('ADMIN_IP', '8.8.8.8'); // Replace with your IP
define('TEMPLATE_DIR', __DIR__ . '/tmp/templates-'.htmlspecialchars(UNIQUE_KEY));
# 24hrs. Increase if you want bots to be blocked even longer.
define('STRIKE_TIMEOUT', 86400); 

define('STRIKE_DIR', __DIR__ . '/tmp/honeypot-' . htmlspecialchars(UNIQUE_KEY));
define('LOG_FILE', htmlspecialchars(STRIKE_DIR) . '/' . htmlspecialchars(UNIQUE_KEY).'-honeypot.log');

# Set timezone to prevent fail2ban giving time mismatch errors.
date_default_timezone_set('UTC');

// Ensure directories exist
if (!is_dir(STRIKE_DIR)) mkdir(STRIKE_DIR, 0700, true);
$unique_folder = STRIKE_DIR . '/hp_' . md5(UNIQUE_KEY); 
if (!is_dir($unique_folder)) mkdir($unique_folder, 0700, true);
if (!is_dir(TEMPLATE_DIR)) mkdir(TEMPLATE_DIR, 0755, true);

// Get client info
$ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$ip = htmlspecialchars($ip,ENT_QUOTES,'UTF-8');
$path = $_SERVER['REQUEST_URI'] ?? 'unknown';
$path = htmlspecialchars($path,ENT_QUOTES,'UTF-8');
$user_agent = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';
$user_agent = htmlspecialchars($user_agent,ENT_QUOTES,'UTF-8');
$timestamp = date('Y-m-d H:i:s');

// Whitelist check
if ($ip === ADMIN_IP || $ip === '127.0.0.1' || $ip === '::1') {
    http_response_code(404);
    exit('Not Found');
}

// --- Reflected-ban / iframe protection ---
$sec_fetch_dest = $_SERVER['HTTP_SEC_FETCH_DEST'] ?? null;
$sec_fetch_mode = $_SERVER['HTTP_SEC_FETCH_MODE'] ?? null;

if ($sec_fetch_dest !== null || $sec_fetch_mode !== null) {
    // Browser sent Fetch Metadata, enforce intent
    $is_top_level = ($sec_fetch_dest === 'document' && $sec_fetch_mode === 'navigate');
    if (!$is_top_level) {
        // iframe/embed/etc: skip strikes
        $log_entry = sprintf(
            "[%s] IP: %s | Ignored browser embed | Path: %s | UA: %s\n",
            $timestamp,
            substr($ip, 0, 100),
            substr($path, 0, 100),
            substr($user_agent, 0, 100)
        );
        @file_put_contents(LOG_FILE, $log_entry, FILE_APPEND);

        showSilent($ip, $path, 0);
        exit();
    }
}
// If no Fetch Metadata, treat as scanner/Safari, count strikes

// --- Strike handling ---
$strike_file = $unique_folder . '/' . md5($ip) . '.txt';
$strikes = 0;
$last_strike = 0;

if (file_exists($strike_file)) {
    $data = @file_get_contents($strike_file);
    list($strikes, $last_strike) = explode('|', $data . '|0');
    $strikes = (int)$strikes;
    $last_strike = (int)$last_strike;

    if (time() - $last_strike > STRIKE_TIMEOUT) {
        $strikes = 0;
    }
}

$strikes++;
@file_put_contents($strike_file, $strikes . '|' . time());

$log_entry = sprintf(
    "[%s] IP: %s | Strike: %d | Path: %s | UA: %s\n",
    $timestamp,
    substr($ip, 0, 100),
    $strikes,
    substr($path, 0, 100),
    substr($user_agent, 0, 100)
);
@file_put_contents(LOG_FILE, $log_entry, FILE_APPEND);

// Response based on strikes
if ($strikes === 1) {
    showSilent($ip, $path, $strikes);
} elseif ($strikes === 2) {
    showWarning($ip, $path, $strikes);
} else {
    showBan($ip, $path, $strikes);
}

// --- Template rendering ---
function renderTemplate($file, array $vars = []) {
    if (!is_readable($file)) {
        http_response_code(500);
        exit('Template error');
    }

    $html = file_get_contents($file);

    foreach ($vars as $key => $value) {
        $html = str_replace('{{' . strtoupper($key) . '}}', htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8'), $html);
    }

    header('Content-Type: text/html; charset=utf-8');
    echo $html;
    exit;
}

function showSilent($ip, $path, $strikes) {
    http_response_code(404);
    renderTemplate(TEMPLATE_DIR . '/silent404.html');
}

function showWarning($ip, $path, $strikes) {
    http_response_code(403);
    renderTemplate(TEMPLATE_DIR . '/warning.html', ['strikes' => $strikes]);
}

function showBan($ip, $path, $strikes) {
    http_response_code(403);
    renderTemplate(TEMPLATE_DIR . '/ban.html', ['incident' => md5($ip . time())]);
}
?>

