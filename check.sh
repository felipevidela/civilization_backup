#!/usr/bin/env bash
# check.sh — estado del sistema, inventario e integridad.
#
# Uso: sudo ./check.sh [--offline]        estado general
#      sudo ./check.sh --scrub            verifica sha256 de todo lo listado en MANIFEST.tsv (lento, offline)
#      sudo ./check.sh --scrub-quick      solo comprueba existencia y tamaño (rápido)
#      sudo ./check.sh --repair-info      qué protege la paridad PAR2 y su estado
#   --offline  no consulta versiones nuevas en el servidor de Kiwix
set -euo pipefail

ARCA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESPALDO="${RESPALDO:-/srv/respaldo}"
ARCA_STATE_DIR="$RESPALDO/.arca"; ARCA_TMP="${TMPDIR:-/tmp}/arca-check.$$"; ARCA_LOG_COPY=""
PACKS_CONF="${PACKS_CONF:-$ARCA_DIR/packs.conf}"
OFFLINE=0; MODO=estado
case ${1:-} in
  --offline) OFFLINE=1 ;;
  --scrub) MODO=scrub ;;
  --scrub-quick) MODO=scrub-quick ;;
  --repair-info) exec "$ARCA_DIR/repair.sh" --info ;;
  -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac
export ARCA_STATE_DIR ARCA_TMP ARCA_LOG_COPY RESPALDO
for lib in log space profiles fetch kiwix manifest; do
  # shellcheck disable=SC1090
  source "$ARCA_DIR/lib/$lib.sh"
done
perfil_cargar

# ---------------------------------------------------------------- scrub
if [[ $MODO == scrub || $MODO == scrub-quick ]]; then
  [[ $(id -u) -eq 0 ]] || die "Ejecuta con sudo."
  [[ -s $MANIFEST_OUT ]] || die "No existe $MANIFEST_OUT. Genera el manifiesto con: sudo $ARCA_DIR/setup.sh --only 10"
  informe="$ARCA_STATE_DIR/scrub-$(date +%Y%m%d).log"
  total=$(awk 'END{print NR-1}' "$MANIFEST_OUT")
  bytes_total=$(awk -F'\t' 'NR>1 && $3!="unknown" && $12!="missing" {s+=$2} END{printf "%d", s}' "$MANIFEST_OUT")
  echo "Scrub $MODO de $total entradas ($(human "$bytes_total") con hash). Informe: $informe"
  ok=0; corrupt=0; missing=0; unverified=0; mismatch=0; n=0; hechos=0; inicio=$(date +%s)
  {
    echo "# scrub $MODO $(date -Is) perfil=$ARCA_PERFIL"
    echo -e "estado\tpath\tdetalle"
  } > "$informe"
  while IFS=$'\t' read -r rel size sha _ _ _ _ _ _ _ _ _; do
    n=$((n + 1)); abs="$RESPALDO/$rel"
    if [[ ! -e $abs ]]; then
      missing=$((missing + 1)); printf 'MISSING\t%s\t\n' "$rel" >> "$informe"; continue
    fi
    if [[ -d $abs ]]; then ok=$((ok + 1)); continue; fi
    real=$(stat -c %s "$abs")
    if [[ $real != "$size" && $size != unknown ]]; then
      mismatch=$((mismatch + 1)); printf 'SIZE-MISMATCH\t%s\tesperado %s, real %s\n' "$rel" "$size" "$real" >> "$informe"; continue
    fi
    if [[ $sha == unknown || $MODO == scrub-quick ]]; then
      unverified=$((unverified + 1)); [[ $sha == unknown ]] && printf 'UNVERIFIED\t%s\tsin sha256 registrado\n' "$rel" >> "$informe"; continue
    fi
    calc=$(sha256sum "$abs" | awk '{print $1}')
    hechos=$((hechos + real))
    if [[ $calc == "$sha" ]]; then ok=$((ok + 1)); else corrupt=$((corrupt + 1)); printf 'CORRUPT\t%s\tsha256 esperado %s, real %s\n' "$rel" "$sha" "$calc" >> "$informe"; fi
    printf '\r  %d/%d  %s verificados  (%d corruptos, %d faltantes)   ' "$n" "$total" "$(human "$hechos")" "$corrupt" "$missing"
  done < <(tail -n +2 "$MANIFEST_OUT")
  echo
  resumen="ok=$ok corrupt=$corrupt missing=$missing size-mismatch=$mismatch unverified=$unverified duracion=$(( ($(date +%s) - inicio) / 60 ))min"
  echo "# resumen $resumen" >> "$informe"
  printf '%s\n%s\n' "$(date -Is)" "$resumen" > "$ARCA_STATE_DIR/ultimo-scrub"
  echo "Resultado: $resumen"
  (( corrupt + missing + mismatch > 0 )) && { echo "Detalle:"; grep -vE '^(#|ok|UNVERIFIED)' "$informe" | head -40 | sed 's/^/  /'; echo "Nada se ha modificado. Para reponer un archivo: update.sh (vuelve a descargar lo que falte o no coincida) o repair.sh --repair (núcleo crítico)."; }
  exit $(( corrupt + missing + mismatch > 0 ? 1 : 0 ))
fi
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
