<?php
/**
 * Honeypot Strike Handler
 */
// Configuration
define('UNIQUE_KEY','monday-is-the-best'); // A passphrase MUST be set!
define('ADMIN_IP', '8.8.8.8'); // Replace with your IP
define('TEMPLATE_DIR', __DIR__ . '/tmp/templates-'.htmlspecialchars(UNIQUE_KEY));
define('STRIKE_TIMEOUT', 30600);

define('STRIKE_DIR', __DIR__ . '/tmp/honeypot-' . htmlspecialchars(UNIQUE_KEY));
define('LOG_FILE', htmlspecialchars(STRIKE_DIR) . '/' . htmlspecialchars(UNIQUE_KEY).'-honeypot.log');

if (!is_dir(htmlspecialchars(STRIKE_DIR))) {
    mkdir(htmlspecialchars(STRIKE_DIR), 0700, true);
}

$unique_folder = htmlspecialchars(STRIKE_DIR) . '/hp_' . md5(UNIQUE_KEY); 

if (!is_dir($unique_folder)) {
    mkdir($unique_folder, 0700, true);
}

if (!is_dir(htmlspecialchars(TEMPLATE_DIR))) {
    mkdir(htmlspecialchars(TEMPLATE_DIR), 0700, true);
}

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

// Protect against reflected ban / induced ban attack.
// Detect if request is top-level navigation
$sec_fetch_dest = $_SERVER['HTTP_SEC_FETCH_DEST'] ?? '';
$sec_fetch_mode = $_SERVER['HTTP_SEC_FETCH_MODE'] ?? '';
$sec_fetch_site = $_SERVER['HTTP_SEC_FETCH_SITE'] ?? '';
$sec_fetch_user = $_SERVER['HTTP_SEC_FETCH_USER'] ?? '';

$is_top_level = ($sec_fetch_dest === 'document' && $sec_fetch_mode === 'navigate');

// Only count strikes for top-level requests
if (!$is_top_level) {
    // Optionally log it separately for analysis
    $log_entry = sprintf(
        "[%s] IP: %s | Skipped (possible iframe/embed attack) | Path: %s | UA: %s\n",
        $timestamp,
        substr($ip, 0, 100),
        substr($path, 0, 100),
        substr($user_agent, 0, 100)
    );
    @file_put_contents(LOG_FILE, $log_entry, FILE_APPEND);

    // Serve normal 404 silently
    showSilent($ip, $path, $strikes);
    exit();
}


// Get strike count
$strike_file = $unique_folder . '/' . md5($ip) . '.txt';
$strikes = 0;
$last_strike = 0;

if (file_exists($strike_file)) {
    $data = @file_get_contents($strike_file);
    list($strikes, $last_strike) = explode('|', $data . '|0');
    $strikes = (int)$strikes;
    $last_strike = (int)$last_strike;
    
    // Reset if expired
    if (time() - $last_strike > STRIKE_TIMEOUT) {
        $strikes = 0;
    }
}

// Increment strikes
$strikes++;
@file_put_contents($strike_file, $strikes . '|' . time());

// Log attempt
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
    // Strike 1: Silent 404
    showSilent($ip, $path, $strikes);
} elseif ($strikes === 2) {
    // Strike 2: Warning page
    showWarning($ip, $path, $strikes);
} else {
    // Strike 3+: Ban page (Fail2ban will catch this)
    showBan($ip, $path, $strikes);
}

function renderTemplate($file, array $vars = []) {
	
    if (!is_readable($file)) {
        http_response_code(500);
        exit('Template error');
    }

    $html = file_get_contents($file);

    foreach ($vars as $key => $value) {
        $html = str_replace(
            '{{' . strtoupper($key) . '}}',
            htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8'),
            $html
        );
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
    renderTemplate(
        TEMPLATE_DIR . '/warning.html',
        ['strikes' => $strikes]
    );
}

function showBan($ip, $path, $strikes) {
	http_response_code(403);
	renderTemplate(
		TEMPLATE_DIR . '/ban.html',
		['incident' => md5($ip . time())]
	);
}

?>
