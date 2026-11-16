#!/bin/bash
# instalar_asterisk.sh - Instala Asterisk + Python3 + PostgreSQL
set -e

ok()   { echo "[OK] $1"; }
fail() { echo "[ERROR] $1"; exit 1; }

# 1. Comprobar que se ejecuta como root
[ "$EUID" -ne 0 ] && fail "Ejecútalo como root"
ok "Ejecutando como root"

# 2. Actualizar el sistema
apt update && ok "Paquetes actualizados" || fail "apt update falló"

# 3. Instalar Python3
apt -y install python3 && ok "python3 instalado" || fail "No se pudo instalar python3"

# 4. Instalar PostgreSQL (incluye psql)
apt -y install postgresql && ok "PostgreSQL instalado" || fail "No se pudo instalar postgresql"
systemctl enable --now postgresql && ok "PostgreSQL arrancado" || fail "PostgreSQL no arrancó"

# 5. Instalar Asterisk
apt -y install asterisk && ok "Asterisk instalado" || fail "No se pudo instalar asterisk (¿no está en los repositorios?)"
systemctl enable --now asterisk && ok "Asterisk arrancado" || fail "Asterisk no arrancó"

#6. Instalar Whisper.cpp
apt install -y git build-essential cmake ffmpeg && ok "Dependencias de Whisper.cpp instaladas" || fail "No se pudieron instalar las dependencias de Whisper.cpp"
if [ -d /etc/whisper/whisper.cpp/ ]; then
    ok "Whisper.cpp ya está compilado"
else
    mkdir -p /etc/whisper
    cd /etc/whisper
    git clone https://github.com/ggml-org/whisper.cpp.git
    cd /etc/whisper/whisper.cpp
    cmake -B build
    cmake --build build --config Release -j8
    bash ./models/download-ggml-model.sh small
fi



# 6. Verificación final
for check in "python3:command -v python3" \
             "Whisper.cpp:/etc/whisper/whisper.cpp/build/bin/whisper-cli --help" \
             "psql:command -v psql" \
             "asterisk:command -v asterisk" \
             "servicio postgresql activo:systemctl is-active --quiet postgresql" \
             "servicio asterisk activo:systemctl is-active --quiet asterisk"; do
  desc="${check%%:*}"; cmd="${check#*:}"
  if eval "$cmd" >/dev/null 2>&1; then ok "$desc"; else echo "[AVISO] $desc: NO verificado"; fi
done

echo "Instalación terminada."
echo "  $(python3 --version)"
echo "  $(psql --version)"
echo "  $(asterisk -V)"
if [ -d /etc/whisper/whisper.cpp/ ]; then
  echo "  Whisper.cpp compilado en /etc/whisper/whisper.cpp/"
fi
