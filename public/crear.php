<?php
// public/crear.php
// Formulario de alta de productos (CREATE del CRUD).
// Valida los datos del lado del servidor y usa prepared statements.

require_once __DIR__ . '/../includes/db.php';

$titulo_pagina = 'Agregar producto';
$errores = [];

$producto = [
    'nombre'      => '',
    'descripcion'  => '',
    'precio'       => '',
    'cantidad'     => '',
    'categoria_id' => '',
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // 1) token CSRF
    if (!verificar_token_csrf($_POST['token_csrf'] ?? '')) {
        $errores[] = 'Token de seguridad invalido, intentelo de nuevo.';
    }

    // 2) leo y limpio lo que llego por POST
    $producto['nombre']      = trim($_POST['nombre'] ?? '');
    $producto['descripcion'] = trim($_POST['descripcion'] ?? '');
    $producto['precio']      = str_replace(',', '.', trim($_POST['precio'] ?? ''));
    $producto['cantidad']     = trim($_POST['cantidad'] ?? '');
    $producto['categoria_id'] = $_POST['categoria_id'] ?? '';

    // 3) validaciones
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

    if ($producto['cantidad'] !== '' && (!ctype_digit($producto['cantidad']))) {
        $errores[] = 'La cantidad tiene que ser un numero entero sin decimales.';
    }

    if ($producto['categoria_id'] !== '' && !ctype_digit((string) $producto['categoria_id'])) {
        $errores[] = 'La categoria elegida no es valida.';
    }

    // 4) si todo esta bien, inserto
    if (empty($errores)) {
        $stmt = mysqli_prepare(
            $conexion,
            'INSERT INTO productos (nombre, descripcion, precio, cantidad, categoria_id)
             VALUES (?, ?, ?, ?, ?)'
        );
        $cat_id = ($producto['categoria_id'] === '') ? null : (int) $producto['categoria_id'];
        $precio = (float) $producto['precio'];
        $cant   = (int) ($producto['cantidad'] === '' ? 0 : $producto['cantidad']);
        mysqli_stmt_bind_param($stmt, 'ssdii',
            $producto['nombre'], $producto['descripcion'], $precio, $cant, $cat_id);

        if (mysqli_stmt_execute($stmt)) {
            $_SESSION['flash'] = [
                'tipo' => 'ok',
                'texto' => 'Producto "' . $producto['nombre'] . '" agregado correctamente.',
            ];
            header('Location: index.php');
            exit;
        } else {
            $errores[] = 'Error al guardar en la base de datos.';
        }
    }
}

$categorias = listar_categorias($conexion);
require __DIR__ . '/../includes/header.php';
?>

<h2>Agregar producto</h2>

<?php if (!empty($errores)): ?>
<div class="errores">
    <ul>
        <?php foreach ($errores as $e): ?>
            <li><?= escapar($e) ?></li>
        <?php endforeach; ?>
    </ul>
</div>
<?php endif; ?>

<form method="post" action="crear.php">
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

    <button type="submit" class="btn">Guardar producto</button>
    <a class="btn" href="index.php">Cancelar</a>
</form>

<?php require __DIR__ . '/../includes/footer.php'; ?>
