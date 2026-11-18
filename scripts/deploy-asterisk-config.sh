#!/bin/bash
#Aplica toda la configuracion de asterisk
set -e

# Rutas
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$PROJECT_DIR/config/asterisk"
DESTINATION="/etc/asterisk"
BACKUP="/var/backups/voxibd/asterisk/$(date +%Y%m%d_%H%M%S)"

#Archivos que se desplegarán
FILES=(
    "extensions.conf"
    "pjsip.conf"
    "rtp.conf"
    "manager.conf"
    "ari.conf"
    "modules.conf"
)

echo "======================================"
echo "      VOXIBD - ASTERISK DEPLOY"
echo "======================================"

# Comprobar permisos
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Ejecuta el script con sudo."
    exit 1
fi

# Comprobar que Asterisk está instalado
if ! command -v asterisk &> /dev/null; then
    echo "ERROR: Asterisk no está instalado."
    exit 1
fi

# Crear copia de seguridad
mkdir -p "$BACKUP"

COPIED=0

for FILE in "${FILES[@]}"; do

    ORIGIN="$SOURCE/$FILE"
    TARGET="$DESTINATION/$FILE"

    # Comprobar que existe y tiene contenido
    if [ ! -s "$ORIGIN" ]; then
        echo "[OMITIDO] $FILE: no existe o está vacío."
        continue
    fi

    # Guardar configuración anterior
    if [ -f "$TARGET" ]; then
        cp -a "$TARGET" "$BACKUP/"
    fi

    # Aplicar nueva configuración
    install -o asterisk -g asterisk -m 640 "$ORIGIN" "$TARGET"

    echo "[OK] $FILE aplicado correctamente."

    COPIED=$((COPIED + 1))

done

# Comprobar si se ha copiado algún archivo
if [ "$COPIED" -eq 0 ]; then
    echo "ERROR: No hay configuraciones válidas para desplegar."
    exit 1
fi

# Recargar configuración de Asterisk
echo ""
echo "Recargando Asterisk..."

asterisk -rx "core reload"

echo ""
echo "======================================"
echo "Configuración aplicada correctamente."
echo "Archivos desplegados: $COPIED"
echo "Copia de seguridad: $BACKUP"
echo "======================================"
