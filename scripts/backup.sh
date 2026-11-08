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
#   0 0 * * 6 root /usr/local/bin/backup.sh
#
# Las credenciales de B2 NO estan en este script: rclone las lee
# de su propia configuracion (~root/.config/rclone/rclone.conf
# o variables de entorno RCLONE_CONFIG_*).

set -o errexit
set -o pipefail

FECHA=$(date +%Y%m%d_%H%M%S)
DIR_BACKUP="/var/www/backups"
DIR_APP="/var/www/almacen"
BASE_DATOS="almacen_db"
RETENER_DIAS=28               # 4 semanas de backups
LOG="/var/log/backup_almacen.log"

# nombre del remote de rclone (cambiar para pruebas locales:
# con el remote "local-sim" guarda en /srv/nube-simulada)
REMOTO="b2-almacen"
BUCKET_DIR="almacen-backups"

# solo root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script hay que correrlo con sudo (necesita root)."
    exit 1
fi

echo "===== $(date '+%Y-%m-%d %H:%M:%S') - backup $FECHA =====" >> "$LOG"
mkdir -p "$DIR_BACKUP"

# ---------------------------------------------------------------
# 1) dump de la base de datos (sin contrasenia: root via socket)
# ---------------------------------------------------------------
BACKUP_DB="$DIR_BACKUP/db_${BASE_DATOS}_${FECHA}.sql.gz"
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
#    Si la nube no responde (por ej. claves vencidas) se anota en
#    el log pero el backup local ya quedo hecho.
# ---------------------------------------------------------------
if command -v rclone > /dev/null 2>&1; then
    if rclone lsd "${REMOTO}:" > /dev/null 2>&1; then
        rclone copy "$BACKUP_DB" "${REMOTO}:${BUCKET_DIR}" --transfers 4 >> "$LOG" 2>&1
        rclone copy "$BACKUP_APP" "${REMOTO}:${BUCKET_DIR}" --transfers 4 >> "$LOG" 2>&1
        echo ">> copia a ${REMOTO}:${BUCKET_DIR} OK" >> "$LOG"

        # retencion en la nube: borrar los que tienen mas de 4 semanas
        rclone delete "${REMOTO}:${BUCKET_DIR}" --min-age "${RETENER_DIAS}d" >> "$LOG" 2>&1
        RESTANTES=$(rclone lsf "${REMOTO}:${BUCKET_DIR}" | wc -l)
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
echo "Backup OK: $BACKUP_DB + $BACKUP_APP"
