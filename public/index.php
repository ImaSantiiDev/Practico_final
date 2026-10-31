<?php
// public/index.php
// Listado de todos los productos del almacen (READ del CRUD).

require_once __DIR__ . '/../includes/db.php';

$titulo_pagina = 'Listado de productos';

// consulto los productos con el nombre de su categoria (JOIN)
$sql = 'SELECT p.id, p.nombre, p.descripcion, p.precio, p.cantidad,
               p.categoria_id, c.nombre AS categoria
        FROM productos p
        LEFT JOIN categorias c ON c.id = p.categoria_id
        ORDER BY p.id DESC';

$resultado = mysqli_query($conexion, $sql);
$total = mysqli_num_rows($resultado);

require __DIR__ . '/../includes/header.php';
?>

<h2>Productos del almacen (<?= escapar($total) ?>)</h2>

<?php if ($total == 0): ?>
    <p class="vacio">Todavia no hay productos cargados.<br>
       Se pueden agregar desde <a href="crear.php">Agregar producto</a>.</p>
<?php else: ?>
<table>
    <tr>
        <th>ID</th>
        <th>Nombre</th>
        <th>Categoria</th>
        <th>Precio</th>
        <th>Cantidad</th>
        <th class="acciones">Acciones</th>
    </tr>
    <?php while ($prod = mysqli_fetch_assoc($resultado)): ?>
    <tr>
        <td><?= escapar($prod['id']) ?></td>
        <td>
            <?= escapar($prod['nombre']) ?><br>
            <small><?= escapar($prod['descripcion']) ?></small>
        </td>
        <td><?= escapar($prod['categoria'] ?? '(sin categoria)') ?></td>
        <td>$ <?= number_format($prod['precio'], 2, ',', '.') ?></td>
        <td><?= escapar($prod['cantidad']) ?></td>
        <td class="acciones">
            <a class="btn-editar"  href="editar.php?id=<?= (int) $prod['id'] ?>">Editar</a>
            <a class="btn-eliminar" href="eliminar.php?id=<?= (int) $prod['id'] ?>">Eliminar</a>
        </td>
    </tr>
    <?php endwhile; ?>
</table>
<?php endif; ?>

<?php
mysqli_free_result($resultado);
require __DIR__ . '/../includes/footer.php';
