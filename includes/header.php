<?php
// includes/header.php
// Cabecera comun para todas las paginas de la aplicacion.
$titulo_pagina = $titulo_pagina ?? 'Almacen de Productos';
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= escapar($titulo_pagina) ?> - Almacen de Productos</title>
    <link rel="stylesheet" href="estilos.css">
</head>
<body>
<header>
    <h1><a href="index.php">Almacen de Productos</a></h1>
    <nav>
        <a href="index.php">Ver productos</a>
        <a href="crear.php">Agregar producto</a>
    </nav>
</header>
<main>
<?php
// mensaje de exito o error despues de un alta, edicion o baja
$flash = mensaje_flash();
if ($flash !== null) {
    $clase = ($flash['tipo'] === 'ok') ? 'mensaje-ok' : 'mensaje-error';
    echo '<div class="' . $clase . '">' . escapar($flash['texto']) . '</div>';
}
?>
