<?php
// includes/db.php
// Conexion a la base de datos y funciones comunes de la aplicacion.
// Este archivo vive FUERA del DocumentRoot (public/) asi que nunca
// se puede pedir por HTTP desde el navegador.

require_once __DIR__ . '/../config/config.php';

$conexion = mysqli_connect(DB_SERVIDOR, DB_USUARIO, DB_PASSWORD, DB_BASE);

if (!$conexion) {
    // si no se puede conectar mostramos el error y cortamos
    die('No se pudo conectar a la base de datos: ' . mysqli_connect_error());
}

mysqli_set_charset($conexion, 'utf8mb4');

// sesion para el token CSRF de los formularios
if (session_status() === PHP_SESSION_NONE) {
    session_start();
    if (empty($_SESSION['token_csrf'])) {
        $_SESSION['token_csrf'] = bin2hex(random_bytes(16));
    }
}

/**
 * Verifica que el token CSRF del formulario sea el correcto.
 * Se usa para que nadie pueda enviar formularios desde afuera.
 */
function verificar_token_csrf($token)
{
    return isset($_SESSION['token_csrf'])
        && is_string($token)
        && hash_equals($_SESSION['token_csrf'], $token);
}

/**
 * Escapa texto para imprimirlo en HTML sin romper nada.
 */
function escapar($texto)
{
    return htmlspecialchars((string) $texto, ENT_QUOTES, 'UTF-8');
}

/**
 * Devuelve el mensaje de exito o error guardado en la sesion
 * (viene de crear.php, editar.php o eliminar.php despues de
 * un redirect) y lo limpia para la proxima pagina.
 */
function mensaje_flash()
{
    if (isset($_SESSION['flash'])) {
        $msj = $_SESSION['flash'];
        unset($_SESSION['flash']);
        return $msj;
    }
    return null;
}

/**
 * Devuelve la lista de categorias para llenar el <select> del formulario.
 */
function listar_categorias($conexion)
{
    $categorias = [];
    $resultado = mysqli_query($conexion, 'SELECT id, nombre FROM categorias ORDER BY nombre');
    if ($resultado) {
        while ($fila = mysqli_fetch_assoc($resultado)) {
            $categorias[] = $fila;
        }
        mysqli_free_result($resultado);
    }
    return $categorias;
}
