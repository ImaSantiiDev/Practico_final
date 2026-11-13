#!/bin/bash
# scripts/backup.sh
# Respaldo de la aplicacion y de la base de datos del almacen.
#
#   - Copia de los archivos de /var/www/almacen (sin .git)
#   - Dump completo de la base almacen_db comprimido con gzip
#   - Copia externa con rclone (Backblaze B2)
#   - Borra los backups de mas de 4 semanas (28 dias) para no
#     llenar el disco ni el almacenamiento de la nube
#
# En el cron del sistema esta asi (sabado a la hora 00:00):
#   0 0 * * 6 /usr/local/bin/backup.sh
#
# Las credenciales de B2 NO estan en este script: se cargan de
# /etc/almacen/env-b2 (archivo de solo root con variables de
# entorno: B2_KEY_ID, B2_APPLICATION_KEY y B2_BUCKET).

set -o errexit
set -o pipefail

FECHA=$(date +%Y%m%d_%H%M%S)
DIR_BACKUP="/var/www/backups"
DIR_APP="/var/www/almacen"
BASE_DATOS="almacen_db"
RETENER_DIAS=28               # 4 semanas de backups
LOG="/var/log/backup_almacen.log"

# remote de rclone: por defecto el de Backblaze B2; para probar
# sin nube se puede lanzar con RCLONE_REMOTE=localsim
REMOTO="${RCLONE_REMOTE:-b2almacen}"

# ---------------------------------------------------------------
# 1) dump de la base de datos (sin contrasenia: root via socket)
# ---------------------------------------------------------------
echo "===== $(date '+%Y-%m-%d %H:%M:%S') - backup $FECHA =====" >> "$LOG"
mkdir -p "$DIR_BACKUP"

BACKUP_DB="$DIR_BACKUP/db_almacen_${FECHA}.sql.gz"
if mysqldump "$BASE_DATOS" 2>> "$LOG" | gzip > "$BACKUP_DB"; then
    echo ">> base de datos OK: $(basename "$BACKUP_DB") ($(du -h "$BACKUP_DB" | cut -f1))" >> "$LOG"
else
    echo ">> ERROR en el dump de la base de datos" >> "$LOG"
    exit 2
fi

# ---------------------------------------------------------------
# 2) archivos de la aplicacion (sin .git para no inflar el tar)
# ---------------------------------------------------------------
BACKUP_APP="$DIR_BACKUP/app_almacen_${FECHA}.tar.gz"
tar -czf "$BACKUP_APP" --exclude="$DIR_APP/.git" -C "$(dirname "$DIR_APP")" "$(basename "$DIR_APP")" 2>> "$LOG"
echo ">> aplicacion OK: $(basename "$BACKUP_APP") ($(du -h "$BACKUP_APP" | cut -f1))" >> "$LOG"

# ---------------------------------------------------------------
# 3) copia externa con rclone (Backblaze B2)
#    Las claves se leen del archivo de entorno /etc/almacen/env-b2
#    Si la nube no responde (por ej. claves vencidas) se anota en
#    el log pero el backup local ya quedo hecho.
# ---------------------------------------------------------------
set -a
. /etc/almacen/env-b2 2> /dev/null || true
set +a
RUTA_REMOTA="${B2_BUCKET:-almacen-backups}"

if command -v rclone > /dev/null 2>&1; then
    if rclone lsd "${REMOTO}:" > /dev/null 2>&1; then
        rclone copy "$BACKUP_DB" "${REMOTO}:${RUTA_REMOTA}" --transfers 4 >> "$LOG" 2>&1
        rclone copy "$BACKUP_APP" "${REMOTO}:${RUTA_REMOTA}" --transfers 4 >> "$LOG" 2>&1
        echo ">> copia a ${REMOTO}:${RUTA_REMOTA} OK" >> "$LOG"

        # retencion en la nube: borrar los que tienen mas de 4 semanas
        rclone delete "${REMOTO}:${RUTA_REMOTA}" --min-age "${RETENER_DIAS}d" >> "$LOG" 2>&1
        RESTANTES=$(rclone lsf "${REMOTO}:${RUTA_REMOTA}" | wc -l)
        echo ">> en la nube quedan $RESTANTES archivos (retencion ${RETENER_DIAS} dias)" >> "$LOG"
    else
        echo ">> AVISO: no se pudo conectar a ${REMOTO} (backup local OK)" >> "$LOG"
    fi
else
    echo ">> AVISO: rclone no esta instalado (backup local OK)" >> "$LOG"
fi

# ---------------------------------------------------------------
# 4) retencion local: borrar backups de mas de 4 semanas
# ---------------------------------------------------------------
find "$DIR_BACKUP" -name '*.gz' -type f -mtime "+${RETENER_DIAS}" -exec rm -f {} \; 2>> "$LOG"
echo ">> backup terminado" >> "$LOG"
echo "Backup OK: $(basename "$BACKUP_DB") + $(basename "$BACKUP_APP")"
