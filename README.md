# Practico_final - Almacen de Productos

Trabajo practico final de infraestructura de sistemas: una maquina
Ubuntu 22.04 LTS (Desktop) con un servidor web Apache2 + PHP + MariaDB
que corre una aplicacion de gestion de almacen de productos (CRUD
completo), con usuarios y grupos del sistema, respaldos locales y
externos (Backblaze B2 con rclone) y despliegue desde GitHub.

El codigo de la aplicacion esta en este repositorio y se despliega en
la maquina con el script `scripts/deploy.sh` desde la rama `main`.

## Estructura

```
public/       -> paginas PHP (DocumentRoot del VirtualHost de Apache)
includes/     -> conexion a la base y cabeceras comunes (fuera del DocumentRoot)
config/       -> configuracion de la base (config.php NO se sube)
sql/          -> esquema y datos de prueba
scripts/      -> deploy.sh, backup.sh, restore.sh, gestion_usuarios.sh
```

## Aplicacion

La aplicacion es un CRUD de productos con categorias:

- `public/index.php`   -> lista los productos (JOIN con categorias)
- `public/crear.php`   -> alta con validaciones del lado del servidor
- `public/editar.php`  -> edicion de un producto por id
- `public/eliminar.php`-> baja con confirmacion y token CSRF

Todas las consultas usan prepared statements de mysqli y los formularios
guardan un token CSRF por sesion.

## Base de datos

```sql
-- en la maquina, cargar con: sudo mysql < sql/schema.sql
--                        sudo mysql almacen_db < sql/datos_demo.sql
CREATE DATABASE almacen_db ...
CREATE TABLE categorias (id, nombre, descripcion);
CREATE TABLE productos  (id, nombre, descripcion, precio, cantidad, categoria_id, ...);
```

El usuario de la aplicacion (`almacen_user`) solo tiene permisos de
SELECT, INSERT, UPDATE y DELETE sobre `almacen_db`.

## Instalacion en la maquina (resumen)

1. Instalar Apache2, PHP (php-mysql, php-mbstring), MariaDB y Git.
2. Clonar este repositorio en `/var/www/almacen` con el usuario `webadmin`.
3. Copiar `config/config.example.php` a `config/config.php` y completar
   la contrasenia de la base. El archivo no se sube a GitHub.
4. Cargar el esquema y los datos de demo.
5. Crear el VirtualHost `miproyecto.com` apuntando a
   `/var/www/almacen/public` y agregar el dominio a `/etc/hosts`.
6. Dejar los scripts en `/usr/local/bin` (el deploy lo hace solo).
7. Cron del backup (sabado 00:00): `0 0 * * 6 /usr/local/bin/backup.sh`

## Nota sobre las credenciales

- La contrasenia de la base de datos vive en `config/config.php`, que
  esta en el `.gitignore`, asi que nunca se sube al repositorio. En el
  repo solo esta `config/config.example.php` como plantilla.
- Las credenciales de Backblaze B2 viven en `/etc/almacen/env-b2`
  (archivo de solo root, fuera del repositorio) y se cargan como
  variables de entorno (`B2_KEY_ID`, `B2_APPLICATION_KEY`, `B2_BUCKET`).
  Ni el backup.sh ni ningun archivo de este repo las contiene.
