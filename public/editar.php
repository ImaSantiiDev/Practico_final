<?php
// public/editar.php
// Formulario de edicion de productos (UPDATE del CRUD).
// Recibe el id por GET y valida que el producto exista.

require_once __DIR__ . '/../includes/db.php';

$titulo_pagina = 'Editar producto';
$errores = [];

// 1) valido el id que llega por GET
$id = $_GET['id'] ?? null;
if ($id === null || !ctype_digit((string) $id)) {
    $_SESSION['flash'] = ['tipo' => 'error', 'texto' => 'Id de producto invalido.'];
    header('Location: index.php');
    exit;
}
$id = (int) $id;

// 2) busco el producto
$stmt = mysqli_prepare($conexion,
    'SELECT nombre, descripcion, precio, cantidad, categoria_id FROM productos WHERE id = ?');
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

// guardo el nombre original para el mensaje
$nombre_original = $producto['nombre'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // 3) token CSRF
    if (!verificar_token_csrf($_POST['token_csrf'] ?? '')) {
        $errores[] = 'Token de seguridad invalido, intentelo de nuevo.';
    }

    // 4) leo los datos nuevos
    $producto['nombre']      = trim($_POST['nombre'] ?? '');
    $producto['descripcion'] = trim($_POST['descripcion'] ?? '');
    $producto['precio']      = str_replace(',', '.', trim($_POST['precio'] ?? ''));
    $producto['cantidad']   = trim($_POST['cantidad'] ?? '');
    $producto['categoria_id'] = $_POST['categoria_id'] ?? '';

    // 5) validaciones (las mismas que en crear.php)
    if ($producto['nombre'] === '') {
        $errores[] = 'El nombre es obligatorio.';
    } elseif (mb_strlen($producto['nombre']) > 100) {
        $errores[] = 'El nombre no puede pasar de 100 caracteres.';
    }
    if (!is_numeric($producto['precio']) || $producto['precio'] === '') {
        $errores[] = 'El precio tiene que ser un numero (ej: 1500.50).';
    } elseif ((float) $producto['precio'] < 0) {
        $errores[] = 'El precio no puede ser negativo.';
    }
    if ($producto['cantidad'] !== '' && !ctype_digit($producto['cantidad'])) {
        $errores[] = 'La cantidad tiene que ser un numero entero sin decimales.';
    }
    if ($producto['categoria_id'] !== '' && !ctype_digit((string) $producto['categoria_id'])) {
        $errores[] = 'La categoria elegida no es valida.';
    }

    // 6) si esta todo bien, actualizo
    if (empty($errores)) {
        $stmt = mysqli_prepare($conexion,
            'UPDATE productos
             SET nombre = ?, descripcion = ?, precio = ?, cantidad = ?, categoria_id = ?
             WHERE id = ?');
        $cat_id = ($producto['categoria_id'] === '') ? null : (int) $producto['categoria_id'];
        $precio = (float) $producto['precio'];
        $cant   = (int) ($producto['cantidad'] === '' ? 0 : $producto['cantidad']);
        mysqli_stmt_bind_param($stmt, 'ssdiii',
            $producto['nombre'], $producto['descripcion'], $precio, $cant, $cat_id, $id);

        if (mysqli_stmt_execute($stmt)) {
            $_SESSION['flash'] = [
                'tipo' => 'ok',
                'texto' => 'Producto "' . $producto['nombre'] . '" actualizado.',
            ];
            header('Location: index.php');
            exit;
        } else {
            $errores[] = 'Error al actualizar en la base de datos.';
        }
    }
}

$categorias = listar_categorias($conexion);
require __DIR__ . '/../includes/header.php';
?>

<h2>Editar producto #<?= escapar($id) ?></h2>

<?php if (!empty($errores)): ?>
<div class="errores">
    <ul>
        <?php foreach ($errores as $e): ?>
            <li><?= escapar($e) ?></li>
        <?php endforeach; ?>
    </ul>
</div>
<?php endif; ?>

<form method="post" action="editar.php?id=<?= escapar($id) ?>">
    <input type="hidden" name="token_csrf" value="<?= escapar($_SESSION['token_csrf']) ?>">

    <dl>
        <dt><label for="nombre">Nombre *</label></dt>
        <dd><input type="text" id="nombre" name="nombre" maxlength="100"
                   value="<?= escapar($producto['nombre']) ?>"></dd>

        <dt><label for="descripcion">Descripcion</label></dt>
        <dd><textarea id="descripcion" name="descripcion" rows="3"><?= escapar($producto['descripcion']) ?></textarea></dd>

        <dt><label for="precio">Precio *</label></dt>
        <dd><input type="text" id="precio" name="precio" placeholder="1500.50"
                   value="<?= escapar($producto['precio']) ?>"></dd>

        <dt><label for="cantidad">Cantidad</label></dt>
        <dd><input type="number" id="cantidad" name="cantidad" min="0"
                   value="<?= escapar($producto['cantidad']) ?>"></dd>

        <dt><label for="categoria_id">Categoria</label></dt>
        <dd>
            <select id="categoria_id" name="categoria_id">
                <option value="">(sin categoria)</option>
                <?php foreach ($categorias as $cat): ?>
                    <option value="<?= (int) $cat['id'] ?>"
                        <?= ((string) $producto['categoria_id'] === (string) $cat['id']) ? 'selected' : '' ?>>
                        <?= escapar($cat['nombre']) ?>
                    </option>
                <?php endforeach; ?>
            </select>
        </dd>
    </dl>

    <button type="submit" class="btn">Guardar cambios</button>
    <a class="btn" href="index.php">Cancelar</a>
</form>

<?php require __DIR__ . '/../includes/footer.php'; ?>
