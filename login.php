<?php
require_once 'config.php';
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, 'Invalid request method.', [], 405);
}

$username = trim($_POST['username'] ?? '');
$password = $_POST['password'] ?? '';

if ($username === '' || $password === '') {
    sendResponse(false, 'Username and password are required.', [], 422);
}

$stmt = $pdo->prepare(
    'SELECT id, username, password_hash, first_name, last_name, email, phone, city, country, photo
     FROM users
     WHERE username = :username
     LIMIT 1'
);

$stmt->execute([
    ':username' => $username
]);

$user = $stmt->fetch();

if (!$user || !password_verify($password, $user['password_hash'])) {
    sendResponse(false, 'Invalid username or password.', [], 401);
}

session_regenerate_id(true);

$_SESSION['user_id'] = (int) $user['id'];
$_SESSION['username'] = $user['username'];

unset($user['password_hash']);

header("Location: dashboard.html");
exit();