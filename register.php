<?php
require_once 'config.php';
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, 'Invalid request method.', [], 405);
}

$username = trim($_POST['username'] ?? '');
$password = $_POST['password'] ?? '';
$firstName = trim($_POST['first_name'] ?? '');
$lastName = trim($_POST['last_name'] ?? '');
$email = trim($_POST['email'] ?? '');
$phone = trim($_POST['phone'] ?? '');
$city = trim($_POST['city'] ?? '');
$country = trim($_POST['country'] ?? '');
$additionalInfo = trim($_POST['additional_info'] ?? '');

if (
    $username === '' ||
    $password === '' ||
    $firstName === '' ||
    $lastName === '' ||
    $email === ''
) {
    sendResponse(false, 'Username, password, first name, last name and email are required.', [], 422);
}

if (!preg_match('/^[A-Za-z0-9_]{3,50}$/', $username)) {
    sendResponse(false, 'Invalid username.', [], 422);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    sendResponse(false, 'Invalid email address.', [], 422);
}

if (strlen($password) < 8) {
    sendResponse(false, 'Password must contain at least 8 characters.', [], 422);
}

$check = $pdo->prepare(
    'SELECT id FROM users WHERE username = :username OR email = :email LIMIT 1'
);

$check->execute([
    ':username' => $username,
    ':email' => $email
]);

if ($check->fetch()) {
    sendResponse(false, 'Username or email already exists.', [], 409);
}

$passwordHash = password_hash($password, PASSWORD_DEFAULT);

$photoName = null;

if (isset($_FILES['photo']) && $_FILES['photo']['error'] !== UPLOAD_ERR_NO_FILE) {
    if ($_FILES['photo']['error'] !== UPLOAD_ERR_OK) {
        sendResponse(false, 'Photo upload failed.', [], 422);
    }

    if ($_FILES['photo']['size'] > 2 * 1024 * 1024) {
        sendResponse(false, 'Photo must be smaller than 2 MB.', [], 422);
    }

    $allowedTypes = [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp'
    ];

    $mime = mime_content_type($_FILES['photo']['tmp_name']);

    if (!isset($allowedTypes[$mime])) {
        sendResponse(false, 'Only JPG, PNG and WEBP photos are allowed.', [], 422);
    }

    $photoName = bin2hex(random_bytes(16)) . '.' . $allowedTypes[$mime];

    $uploadDirectory = dirname(__DIR__) . '/uploads/';

    if (!is_dir($uploadDirectory)) {
        mkdir($uploadDirectory, 0755, true);
    }

    if (!move_uploaded_file(
        $_FILES['photo']['tmp_name'],
        $uploadDirectory . $photoName
    )) {
        sendResponse(false, 'Could not save profile photo.', [], 500);
    }
}

$stmt = $pdo->prepare(
    'INSERT INTO users
    (username, password_hash, first_name, last_name, email, phone, city, country, additional_info, photo)
    VALUES
    (:username, :password_hash, :first_name, :last_name, :email, :phone, :city, :country, :additional_info, :photo)'
);

$stmt->execute([
    ':username' => $username,
    ':password_hash' => $passwordHash,
    ':first_name' => $firstName,
    ':last_name' => $lastName,
    ':email' => $email,
    ':phone' => $phone ?: null,
    ':city' => $city ?: null,
    ':country' => $country ?: null,
    ':additional_info' => $additionalInfo ?: null,
    ':photo' => $photoName
]);

$userId = (int) $pdo->lastInsertId();

session_regenerate_id(true);
$_SESSION['user_id'] = $userId;
$_SESSION['username'] = $username;

sendResponse(true, 'Registration successful.', [
    'user_id' => $userId,
    'username' => $username,
    'first_name' => $firstName,
    'last_name' => $lastName
], 201);
