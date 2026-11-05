<?php
// public/eliminar.php
// Baja de productos (DELETE del CRUD).
// Primero pide confirmacion (GET con el id) y despues
// borra de verdad solo cuando llega el POST con el token.

require_once __DIR__ . '/../includes/db.php';

$titulo_pagina = 'Eliminar producto';

// 1) valido el id que llega por GET
$id = $_GET['id'] ?? null;
if ($id === null || !ctype_digit((string) $id)) {
    $_SESSION['flash'] = ['tipo' => 'error', 'texto' => 'Id de producto invalido.'];
    header('Location: index.php');
    exit;
}
$id = (int) $id;

// 2) busco el producto para mostrar el nombre en la confirmacion
$stmt = mysqli_prepare($conexion, 'SELECT nombre FROM productos WHERE id = ?');
mysqli_stmt_bind_param($stmt, 'i', $id);
mysqli_stmt_execute($stmt);
$resultado = mysqli_stmt_get_result($stmt);

if (mysqli_num_rows($resultado) === 0) {
    $_SESSION['flash'] = ['tipo' => 'error', 'texto' => 'Ese producto no existe.'];
    header('Location: index.php');
    exit;
}
$producto = mysqli_fetch_assoc($resultado);
mysqli_free_result($resultado);

// 3) si confirmo, borro
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (verificar_token_csrf($_POST['token_csrf'] ?? '')) {
        $stmt = mysqli_prepare($conexion, 'DELETE FROM productos WHERE id = ?');
        mysqli_stmt_bind_param($stmt, 'i', $id);
        mysqli_stmt_execute($stmt);

        $_SESSION['flash'] = [
            'tipo' => 'ok',
            'texto' => 'Producto "' . $producto['nombre'] . '" eliminado.',
        ];
    } else {
        $_SESSION['flash'] = ['tipo' => 'error', 'texto' => 'Token de seguridad invalido.'];
    }
    header('Location: index.php');
    exit;
}

require __DIR__ . '/../includes/header.php';
?>

<h2>Eliminar producto</h2>

<p>Se va a eliminar este producto de la base de datos:</p>

<table>
    <tr><th>ID</th><th>Nombre</th></tr>
    <tr><td><?= escapar($id) ?></td><td><?= escapar($producto['nombre']) ?></td></tr>
</table>

<p>Esta accion no se puede deshacer. Confirmar?</p>

<form method="post" action="eliminar.php?id=<?= escapar($id) ?>"
      onsubmit="return confirm('Seguro que queres eliminar: <?= escapar($producto['nombre']) ?>?');">
    <input type="hidden" name="token_csrf" value="<?= escapar($_SESSION['token_csrf']) ?>">
    <button type="submit" class="btn-eliminar" style="border:none;cursor:pointer;padding:8px 16px;border-radius:4px;color:#fff;">
        Si, eliminar
    </button>
    <a class="btn" href="index.php">Cancelar</a>
</form>

<?php require __DIR__ . '/../includes/footer.php'; ?>
