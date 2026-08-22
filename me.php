<?php
require_once 'config.php';
require_once 'db.php';

if (!isset($_SESSION['user_id'])) {
    sendResponse(false, 'Not logged in.', [], 401);
}

$stmt = $pdo->prepare(
    'SELECT id, username, first_name, last_name, email, phone, city, country,
            additional_info, photo, created_at
     FROM users
     WHERE id = :id
     LIMIT 1'
);

$stmt->execute([
    ':id' => $_SESSION['user_id']
]);

$user = $stmt->fetch();

if (!$user) {
    session_destroy();
    sendResponse(false, 'User not found.', [], 401);
}

sendResponse(true, 'User is logged in.', [
    'user' => $user
]);
