<?php
session_start();

header('Content-Type: application/json');

function sendResponse($success, $message, $data = [], $status = 200)
{
    http_response_code($status);

    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data' => $data
    ]);

    exit;
}
