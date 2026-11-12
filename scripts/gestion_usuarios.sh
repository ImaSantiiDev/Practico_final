#!/bin/bash
# scripts/gestion_usuarios.sh
# Menu para administrar los usuarios del sistema del almacen.
# Sirve para crear, bloquear, desbloquear y borrar usuarios y
# para agregarlos a los grupos del proyecto.
#
#   sudo /usr/local/bin/gestion_usuarios.sh

# solo root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script hay que correrlo con sudo (necesita root)."
    exit 1
fi

# grupos con los que trabaja este script
GRUPOS="administradores desarrolladores respaldos"

listar_usuarios() {
    echo ""
    echo "== Usuarios con grupo principal del proyecto =="
    for g in $GRUPOS; do
        echo "Grupo $g:"
        lid -g "$g" 2>/dev/null || echo "  (sin miembros)"
        echo ""
    done
    echo "== Ultimos usuarios creados =="
    getent passwd | tail -10
}

crear_usuario() {
    read -rp "Nombre del usuario nuevo: " USUARIO
    if [ -z "$USUARIO" ] || id "$USUARIO" > /dev/null 2>&1; then
        echo "ERROR: usuario vacio o ya existente."
        return
    fi
    echo "Grupos disponibles: $GRUPOS"
    read -rp "Grupo principal [desarrolladores]: " GRUPO
    GRUPO="${GRUPO:-desarrolladores}"
    if ! getent group "$GRUPO" > /dev/null; then
        echo "ERROR: el grupo $GRUPO no existe."
        return
    fi
    useradd -m -g "$GRUPO" -s /bin/bash "$USUARIO"
    passwd "$USUARIO"
    echo "OK: usuario $USUARIO creado con grupo $GRUPO (home en /home/$USUARIO)"
}

bloquear_usuario() {
    read -rp "Usuario a bloquear: " USUARIO
    if id "$USUARIO" > /dev/null 2>&1; then
        usermod -L "$USUARIO"
        echo "OK: usuario $USUARIO bloqueado (contrasenia deshabilitada)."
    else
        echo "ERROR: el usuario no existe."
    fi
}

desbloquear_usuario() {
    read -rp "Usuario a desbloquear: " USUARIO
    if id "$USUARIO" > /dev/null 2>&1; then
        usermod -U "$USUARIO"
        echo "OK: usuario $USUARIO desbloqueado."
    else
        echo "ERROR: el usuario no existe."
    fi
}

eliminar_usuario() {
    read -rp "Usuario a eliminar: " USUARIO
    if ! id "$USUARIO" > /dev/null 2>&1; then
        echo "ERROR: el usuario no existe."
        return
    fi
    read -rp "Borrar tambien su /home? [s/N]: " BORRAR_HOME
    if [[ "$BORRAR_HOME" == "s" || "$BORRAR_HOME" == "S" ]]; then
        userdel -r "$USUARIO"
    else
        userdel "$USUARIO"
    fi
    echo "OK: usuario $USUARIO eliminado."
}

agregar_a_grupo() {
    read -rp "Usuario: " USUARIO
    read -rp "Grupo (secundario): " GRUPO
    if id "$USUARIO" > /dev/null 2>&1 && getent group "$GRUPO" > /dev/null; then
        usermod -aG "$GRUPO" "$USUARIO"
        echo "OK: $USUARIO ahora tambien esta en $GRUPO."
    else
        echo "ERROR: el usuario o el grupo no existen."
    fi
}

while true; do
    echo ""
    echo "===== GESTION DE USUARIOS DEL ALMACEN ====="
    echo "1) Listar usuarios y grupos"
    echo "2) Crear usuario"
    echo "3) Bloquear usuario"
    echo "4) Desbloquear usuario"
    echo "5) Agregar usuario a un grupo"
    echo "6) Eliminar usuario"
    echo "0) Salir"
    read -rp "Opcion: " OPCION
    case "$OPCION" in
        1) listar_usuarios ;;
        2) crear_usuario ;;
        3) bloquear_usuario ;;
        4) desbloquear_usuario ;;
        5) agregar_a_grupo ;;
        6) eliminar_usuario ;;
        0) exit 0 ;;
        *) echo "Opcion invalida." ;;
    esac
done
