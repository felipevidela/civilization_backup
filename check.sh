#!/usr/bin/env bash
# check.sh — estado del sistema e inventario.
#
# Uso: sudo ./check.sh [--offline]
#   --offline  no consulta versiones nuevas en el servidor de Kiwix
set -euo pipefail

ARCA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESPALDO="${RESPALDO:-/srv/respaldo}"
ARCA_STATE_DIR="$RESPALDO/.arca"; ARCA_TMP="${TMPDIR:-/tmp}/arca-check.$$"; ARCA_LOG_COPY=""
PACKS_CONF="${PACKS_CONF:-$ARCA_DIR/packs.conf}"
OFFLINE=0; [[ ${1:-} == --offline ]] && OFFLINE=1
export ARCA_STATE_DIR ARCA_TMP ARCA_LOG_COPY
for lib in log space profiles fetch kiwix; do
  # shellcheck disable=SC1090
  source "$ARCA_DIR/lib/$lib.sh"
done
perfil_cargar
mkdir -p "$ARCA_TMP"; trap 'rm -rf "$ARCA_TMP"' EXIT
PUERTO=8080
ip=$(hostname -I 2>/dev/null | awk '{print $1}')

echo "== arca: estado =="
if systemctl is-active --quiet kiwix.service 2>/dev/null; then
  echo "  kiwix.service:    activo desde $(systemctl show kiwix.service -p ActiveEnterTimestamp --value 2>/dev/null)"
else
  echo "  kiwix.service:    INACTIVO"
fi
if curl -sf --max-time 5 "http://localhost:$PUERTO/" > /dev/null 2>&1; then
  echo "  Puerto $PUERTO:      responde → http://${ip:-IP}:$PUERTO"
else
  echo "  Puerto $PUERTO:      sin respuesta"
fi
if systemctl is-enabled --quiet arca-update.timer 2>/dev/null; then
  echo "  Timer mensual:    activo (próxima: $(systemctl show arca-update.timer -p NextElapseUSecRealtime --value 2>/dev/null))"
else
  echo "  Timer mensual:    desactivado"
fi
echo "  Última actualización: $(cat "$ARCA_STATE_DIR/ultima-actualizacion" 2>/dev/null || echo nunca)"
echo "  Último backup:        $(head -1 "$ARCA_STATE_DIR/ultimo-backup" 2>/dev/null || echo nunca) $(sed -n 2p "$ARCA_STATE_DIR/ultimo-backup" 2>/dev/null)"

echo
echo "== Espacio en $RESPALDO =="
if mountpoint -q "$RESPALDO"; then
  df -h --output=size,used,avail,pcent "$RESPALDO" | tail -1 | awk '{printf "  total %s, usado %s, libre %s (%s)\n", $1, $2, $3, $4}'
  for d in zim manuales libros mapas software personal; do
    [[ -d "$RESPALDO/$d" ]] && printf '  %-12s %8s\n' "$d/" "$(du -sh "$RESPALDO/$d" 2>/dev/null | awk '{print $1}')"
  done
else
  echo "  ¡NO ESTÁ MONTADO!"
fi

echo
echo "== ZIM del perfil $ARCA_PERFIL (instalado / disponible en el servidor) =="
(( OFFLINE )) || kiwix_cache_clear
while IFS=$'\t' read -r p _ _ carpeta prefijo; do
  recurso_activo "$p" || continue
  inst=$(zim_json_get "$prefijo" archivo 2>/dev/null || true)
  finst="-"; [[ -n $inst ]] && finst=$(kiwix_fecha "$inst")
  if (( OFFLINE )); then
    printf '  %-52s %-8s\n' "$prefijo" "$finst"
  else
    if nuevo=$(kiwix_latest "$carpeta" "$prefijo" 2>/dev/null); then
      fnuevo=$(kiwix_fecha "$nuevo")
      if [[ $nuevo == "$inst" ]]; then est="al día"; else est="NUEVA $fnuevo ($(human "$(kiwix_listed_size "$carpeta" "$nuevo" || echo 0)"))"; fi
    else
      est="no existe en el servidor"
    fi
    printf '  %-52s %-8s %s\n' "$prefijo" "$finst" "$est"
  fi
done < <(packs_read "$PACKS_CONF")
extra=$(find "$RESPALDO/zim" -maxdepth 1 -name '*.aria2' 2>/dev/null | wc -l)
(( extra )) && echo "  Descargas a medias: $extra (se reanudan con update.sh)"

echo
if [[ -s "$ARCA_STATE_DIR/failed.txt" ]]; then
  echo "== Errores pendientes (se reintentan con update.sh) =="
  sed 's/^/  - /' "$ARCA_STATE_DIR/failed.txt"
else
  echo "== Sin errores pendientes =="
fi
