#!/bin/bash
# scripts/deploy.sh
# Actualiza la aplicacion del almacen con los ultimos cambios
# de la rama main de GitHub. Se ejecuta con sudo.
#
#   sudo /usr/local/bin/deploy.sh
#
# La configuracion de la base de datos (config/config.php) NO
# esta en el repositorio, asi que el deploy no la toca.

set -o errexit
set -o pipefail

APLICACION="/var/www/almacen"
LOG="/var/log/deploy_almacen.log"
RAMA="main"

# solo root (o con sudo) puede correr esto
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script hay que correrlo con sudo (necesita root)."
    exit 1
fi

echo "===== $(date '+%Y-%m-%d %H:%M:%S') - deploy desde GitHub =====" >> "$LOG"

# el repositorio tiene que existir
if [ ! -d "$APLICACION/.git" ]; then
    echo "ERROR: no existe el repositorio en $APLICACION" | tee -a "$LOG"
    exit 1
fi

cd "$APLICACION"

# 1) bajar los ultimos cambios de la rama main
echo ">> git fetch origin $RAMA" >> "$LOG"
sudo -u webadmin git fetch origin "$RAMA" >> "$LOG" 2>&1

# 2) dejar el arbol de trabajo exactamente igual a origin/main
#    (esto descarta cualquier cambio local en los archivos)
echo ">> git reset --hard origin/$RAMA" >> "$LOG"
sudo -u webadmin git reset --hard "origin/$RAMA" >> "$LOG" 2>&1

# 3) sacar archivos que hayan quedado sin versionar (menos los ignorados,
#    o sea que config/config.php se conserva)
echo ">> git clean -fd" >> "$LOG"
sudo -u webadmin git clean -fd >> "$LOG" 2>&1

# 4) verificar que la configuracion este presente
if [ ! -f "$APLICACION/config/config.php" ]; then
    echo "ERROR: falta config/config.php (copiarlo de config.example.php)" | tee -a "$LOG"
    exit 1
fi

# 5) permisos: el dueno es webadmin, el grupo desarrolladores
#    (setgid en los directorios para que lo nuevo herede el grupo)
echo ">> arreglando permisos" >> "$LOG"
chown -R webadmin:desarrolladores "$APLICACION" >> "$LOG" 2>&1
find "$APLICACION" -type d -exec chmod 2775 {} \; >> "$LOG" 2>&1
find "$APLICACION" -type f -exec chmod 0664 {} \; >> "$LOG" 2>&1

# commit que quedo instalado
INSTALADO=$(sudo -u webadmin git log -1 --format='%h %s')
echo ">> instalado: $INSTALADO" >> "$LOG"
echo "Deploy OK - $INSTALADO"
