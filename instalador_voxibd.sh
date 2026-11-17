#!/bin/bash
#Instala Asterisk + Python3 + PostgreSQL
set -e

ok()   { echo "[OK] $1"; }
fail() { echo "[ERROR] $1"; exit 1; }

#Comprobar que se ejecuta como root
[ "$EUID" -ne 0 ] && fail "Ejecútalo como root"
ok "Ejecutando como root"

#Actualizar el sistema
apt update && ok "Paquetes actualizados" || fail "apt update falló"

#Instalar Python3
apt -y install python3 && ok "python3 instalado" || fail "No se pudo instalar python3"

#Instalar PostgreSQL (incluye psql)
apt -y install postgresql && ok "PostgreSQL instalado" || fail "No se pudo instalar postgresql"
systemctl enable --now postgresql && ok "PostgreSQL arrancado" || fail "PostgreSQL no arrancó"

#Instalar Asterisk
apt -y install asterisk && ok "Asterisk instalado" || fail "No se pudo instalar asterisk (¿no está en los repositorios?)"
systemctl enable --now asterisk && ok "Asterisk arrancado" || fail "Asterisk no arrancó"

#Instalar Whisper.cpp
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

#Instalar Obsidian
snap install obsidian --classic && ok "Obsidian instalado" || fail "No se pudo instalar Obsidian"

#Verificación final
echo "Instalación terminada."
echo "  $(python3 --version)"
echo "  $(psql --version)"
echo "  $(asterisk -V)"
if [ -d /etc/whisper/whisper.cpp/ ]; then
  echo "  Whisper.cpp compilado en /etc/whisper/whisper.cpp/"
fi
echo "  Obsidian: $(snap list obsidian | awk 'NR==2 {print $2}')"


