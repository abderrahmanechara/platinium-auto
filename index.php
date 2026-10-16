<?php

try {
    $pdo = require __DIR__ . '/config/database.php';

    $requete = $pdo->query('SELECT COUNT(*) FROM categories');
    $nombreCategories = (int) $requete->fetchColumn();

    echo 'Connexion réussie à Platinium Auto.<br>';
    echo 'Nombre de catégories : ' . $nombreCategories;
}  catch (PDOException $erreur) {
    http_response_code(500);

    echo 'Code SQLSTATE : '
        . htmlspecialchars((string) $erreur->getCode())
        . '<br>';

    echo 'Code MySQL : '
        . htmlspecialchars((string) ($erreur->errorInfo[1] ?? 'indisponible'));
}'Connexion ou requête impossible. Vérifie la configuration locale.';


