#!/bin/bash
# scripts/restore.sh
# Restaura la aplicacion y/o la base de datos desde un backup.
#
#   sudo restore.sh /var/www/backups/db_almacen_20261107_000000.sql.gz
#   sudo restore.sh /var/www/backups/app_almacen_20261107_000000.tar.gz
#
# Con --nube primero baja el archivo desde Backblaze B2 y
# despues restaura desde lo que bajo:
#
#   sudo restore.sh --nube db_almacen_20261107_000000.sql.gz
#
# Antes de restaurar la aplicacion hace una copia de seguridad
# de lo que hay ahora mismo en /var/www/almacen por las dudas.

set -o errexit
set -o pipefail

DIR_BACKUP="/var/www/backups"
DIR_APP="/var/www/almacen"
BASE_DATOS="almacen_db"
REMOTO="b2-almacen"
BUCKET_DIR="almacen-backups"

if [ "$(id -u)" -ne 0 ]; then
    echo "Este script hay que correrlo con sudo (necesita root)."
    exit 1
fi

# se puede pasar --nube para bajarlo primero de B2
FUENTE=""
if [ "$1" = "--nube" ]; then
    ARCHIVO_NUBE="$2"
    DESTINO="/tmp/${ARCHIVO_NUBE}"
    echo ">> bajando $ARCHIVO_NUBE desde ${REMOTO}:${BUCKET_DIR}"
    rclone copy "${REMOTO}:${BUCKET_DIR}/${ARCHIVO_NUBE}" /tmp --transfers 4
    FUENTE="$DESTINO"
    shift 2
else
    FUENTE="$1"
fi

if [ -z "$FUENTE" ] || [ ! -f "$FUENTE" ]; then
    echo "USO:"
    echo "  sudo restore.sh <archivo-de-backup>"
    echo "  sudo restore.sh --nube <nombre-de-archivo-en-la-nube>"
    echo ""
    echo "Backups locales en $DIR_BACKUP:"
    ls -1 "$DIR_BACKUP" 2>/dev/null || echo "  (no hay)"
    exit 1
fi

# ---------------------------------------------------------------
# 1) dump de la base de datos
# ---------------------------------------------------------------
if [[ "$FUENTE" == db_*.sql.gz ]]; then
    echo ">> restaurando la base de datos $BASE_DATOS desde $(basename "$FUENTE")"
    gunzip -c "$FUENTE" | mysql "$BASE_DATOS"
    echo ">> base de datos restaurada"
    mysql -e "SELECT COUNT(*) AS productos FROM $BASE_DATOS.productos;"

# ---------------------------------------------------------------
# 2) archivos de la aplicacion
# ---------------------------------------------------------------
elif [[ "$FUENTE" == app_*.tar.gz ]]; then
    echo ">> guardando copia de la version actual en /tmp"
    if [ -d "$DIR_APP" ]; then
        tar -czf "/tmp/app_actual_$(date +%Y%m%d_%H%M%S).tar.gz" \
            --exclude="$DIR_APP/.git" -C "$(dirname "$DIR_APP")" "$(basename "$DIR_APP")"
    fi
    echo ">> restaurando archivos de la aplicacion desde $(basename "$FUENTE")"
    tar -xzf "$FUENTE" -C "$(dirname "$DIR_APP")"
    chown -R webadmin:desarrolladores "$DIR_APP"
    find "$DIR_APP" -type d -exec chmod 2775 {} \;
    find "$DIR_APP" -type f -exec chmod 0664 {} \;
    echo ">> aplicacion restaurada en $DIR_APP"

else
    echo "ERROR: no se reconoce el tipo de archivo: $FUENTE"
    echo "Tiene que ser db_*.sql.gz o app_*.tar.gz"
    exit 1
fi

echo "Listo. Se recomienda probar la aplicacion en http://miproyecto.com"
