# Practico_final - Almacen de Productos

Trabajo practico final de infraestructura de sistemas: una maquina
Ubuntu 22.04 LTS con un servidor web Apache2 + PHP + MariaDB que corre
una aplicacion de gestion de almacen de productos (CRUD completo).

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

## Nota sobre las credenciales

La contrasenia de la base de datos vive en `config/config.php`, que
esta en el `.gitignore`, asi que nunca se sube al repositorio. En el
repo solo esta `config/config.example.php` como plantilla.
