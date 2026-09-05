#!/usr/bin/env bash
# lib/motd.sh — escribe en /etc/motd la IP local, el estado de kiwix y el espacio libre.
# Lo ejecuta arca-motd.service al arrancar; también sirve a mano: sudo /opt/arca/lib/motd.sh
set -euo pipefail

RESPALDO="${RESPALDO:-/srv/respaldo}"
ip=$(hostname -I 2>/dev/null | awk '{print $1}')
[[ -n $ip ]] || ip="(sin red)"

if systemctl is-active --quiet kiwix.service 2>/dev/null; then
  kiwix="activo"
else
  kiwix="INACTIVO (sudo systemctl start kiwix)"
fi

if mountpoint -q "$RESPALDO" 2>/dev/null; then
  espacio=$(df -h --output=used,avail,pcent "$RESPALDO" | tail -1 | awk '{printf "usado %s, libre %s (%s)", $1, $2, $3}')
else
  espacio="¡$RESPALDO NO ESTÁ MONTADO!"
fi

zims=$(find "$RESPALDO/zim" -maxdepth 1 -name '*.zim' 2>/dev/null | wc -l)
ultima=$(cat "$RESPALDO/.arca/ultima-actualizacion" 2>/dev/null || echo "nunca")

cat > /etc/motd <<MOTD

  ╔══════════════════════════════════════════════════════════════╗
  ║  arca — servidor de conocimiento offline                     ║
  ╚══════════════════════════════════════════════════════════════╝
  Acceso desde otros dispositivos:  http://${ip}:8080
  Servicio kiwix:                   ${kiwix}
  Disco ${RESPALDO}:            ${espacio}
  ZIM instalados: ${zims}   Última actualización: ${ultima}
  Estado detallado: sudo /opt/arca/check.sh   Respaldo: sudo /opt/arca/backup.sh /ruta

MOTD
