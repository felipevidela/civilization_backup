#!/usr/bin/env bash
# update.sh — actualización periódica: ZIM nuevos, manuales que cambiaron, software con
# release nueva, library.xml, servicio y README.txt. Lo ejecuta arca-update.timer.
#
# Uso: sudo ./update.sh [--check] [--zim-only] [--no-software]
#   --check         solo informa qué hay nuevo y cuánto pesa; no descarga
#   --zim-only      solo fase 3 (ZIM) + biblioteca + README
#   --no-software   todo menos la fase 6 (software)
#
# Nunca deja el disco sin una versión funcional: descarga la nueva, verifica, borra la vieja.
set -euo pipefail

ARCA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESPALDO="${RESPALDO:-/srv/respaldo}"
CHECK=0; ZIM_ONLY=0; NO_SOFTWARE=0
while (( $# )); do
  case $1 in
    --check) CHECK=1 ;;
    --zim-only) ZIM_ONLY=1 ;;
    --no-software) NO_SOFTWARE=1 ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Argumento desconocido: $1" >&2; exit 1 ;;
  esac
  shift
done

[[ $(id -u) -eq 0 ]] || { echo "Ejecuta con sudo." >&2; exit 1; }
ARCA_STATE_DIR="$RESPALDO/.arca"; ARCA_TMP="$ARCA_STATE_DIR/tmp"
ARCA_LOG_DIR="$ARCA_DIR/logs"; ARCA_LOG_COPY="$ARCA_STATE_DIR/arca.log"
USUARIO="${ARCA_USER:-${SUDO_USER:-}}"
PACKS_CONF="${PACKS_CONF:-$ARCA_DIR/packs.conf}"
MANUALS_CONF="${MANUALS_CONF:-$ARCA_DIR/manuals.conf}"
SOFTWARE_CONF="${SOFTWARE_CONF:-$ARCA_DIR/software.conf}"
DRY_RUN=0; MODO_UPDATE=1
export ARCA_DIR RESPALDO ARCA_STATE_DIR ARCA_TMP ARCA_LOG_DIR ARCA_LOG_COPY USUARIO PACKS_CONF MANUALS_CONF SOFTWARE_CONF DRY_RUN MODO_UPDATE

for lib in log space state profiles fetch kiwix readme phases; do
  # shellcheck disable=SC1090
  source "$ARCA_DIR/lib/$lib.sh"
done
perfil_cargar
# Si el timer lo lanza (sin SUDO_USER), usa el propietario de /srv/respaldo/zim.
[[ -n $USUARIO ]] || USUARIO=$(stat -c %U "$RESPALDO/zim" 2>/dev/null || echo root)
export USUARIO

mkdir -p "$ARCA_STATE_DIR" "$ARCA_TMP" "$ARCA_LOG_DIR"
log_init update
mountpoint -q "$RESPALDO" || [[ ${ARCA_PERMITIR_SIN_MONTAJE:-0} == 1 ]] || die "$RESPALDO no está montado."
curl -fsSI --connect-timeout 15 --max-time 30 "https://download.kiwix.org/" > /dev/null 2>&1 || die "Sin conexión a download.kiwix.org."

# ---------------------------------------------------------------- --check
if (( CHECK )); then
  log_titulo "Novedades disponibles (sin descargar)"
  kiwix_cache_clear
  total=0
  echo "  Perfil: $ARCA_PERFIL${ARCA_EXTRAS:+ (extras: $ARCA_EXTRAS)}"
  while IFS=$'\t' read -r p _ _ carpeta prefijo; do
    recurso_activo "$p" || continue
    nombre=$(kiwix_latest "$carpeta" "$prefijo" 2>/dev/null) || { printf '  %-55s NO EXISTE en el servidor\n' "$carpeta/$prefijo"; continue; }
    actual=$(zim_json_get "$prefijo" archivo || true)
    if [[ $actual == "$nombre" ]] && zim_installed_ok "$prefijo" "$nombre" "$ZIM_DIR"; then
      printf '  %-55s al día (%s)\n' "$prefijo" "$(kiwix_fecha "$nombre")"
    else
      b=$(kiwix_listed_size "$carpeta" "$nombre" || echo 0); total=$((total + b))
      printf '  %-55s NUEVO %s (%s) — instalado: %s\n' "$prefijo" "$(kiwix_fecha "$nombre")" "$(human "$b")" "${actual:-ninguno}"
    fi
  done < <(packs_read "$PACKS_CONF")
  n=0
  while IFS=$'\t' read -r p _ _ d u _; do
    recurso_activo "$p" || continue
    [[ $d == */ ]] && continue
    [[ -s "$RESPALDO/$d" ]] || { printf '  %-55s manual pendiente\n' "$d"; n=$((n + 1)); continue; }
    r=$(fetch_resource_size "$u" 2>/dev/null || echo ""); g=$(json_get "$MANUALS_JSON" "$u" bytes || true)
    [[ -n $r && -n $g && $r != "$g" ]] && { printf '  %-55s manual cambió de tamaño (%s → %s)\n' "$d" "$(human "$g")" "$(human "$r")"; total=$((total + r)); }
  done < <(manuals_read)
  software_load
  for par in "kiwix_android:kiwix/kiwix-android" "organicmaps:organicmaps/organicmaps" "llamacpp:ggml-org/llama.cpp"; do
    clave=${par%%:*}; repo=${par#*:}
    [[ $clave == llamacpp && ${LLM_ENABLED:-1} != 1 ]] && continue
    t=$(fetch_github_tag "$repo" 2>/dev/null || echo "?"); v=$(json_get "$SOFTWARE_JSON" "$clave" version || true)
    [[ $t != "${v:-}" ]] && printf '  %-55s release nueva %s (instalada: %s)\n' "$repo" "$t" "${v:-ninguna}"
  done
  echo
  echo "  Descarga estimada de ZIM/manuales nuevos: $(human "$total")   Libre: $(human "$(space_free_bytes "$RESPALDO")")"
  [[ -s $FAILED_TXT ]] && { echo "  Errores pendientes:"; sed 's/^/     - /' "$FAILED_TXT"; }
  exit 0
fi

# ---------------------------------------------------------------- actualización real
lock_acquire update || exit 1
inicio=$(date +%s)
libre_antes=$(space_free_bytes "$RESPALDO")
zim_antes=$(jq -c '.' "$ZIM_JSON" 2>/dev/null || echo '{}')
fallos_antes=$(cat "$FAILED_TXT" 2>/dev/null || true)

fase_3
if (( ! ZIM_ONLY )); then
  fase_4
  fase_5
  (( NO_SOFTWARE )) || fase_6
fi
fase_7 || log_warn "La fase 7 terminó con errores (ver log)."
fase_10

# ---------------------------------------------------------------- resumen
resumen="$ARCA_LOG_DIR/update-$(date +%Y%m%d).log"
{
  echo "arca update — $(date '+%Y-%m-%d %H:%M') — duración $(( ($(date +%s) - inicio) / 60 )) min"
  echo
  echo "ZIM cambiados:"
  jq -r --argjson antes "$zim_antes" 'to_entries[] | select($antes[.key].archivo != .value.archivo) | "  \(.key): \($antes[.key].archivo // "ninguno") → \(.value.archivo) (\(.value.bytes) bytes)"' "$ZIM_JSON" 2>/dev/null || true
  echo "Espacio: antes $(human "$libre_antes") libres, ahora $(human "$(space_free_bytes "$RESPALDO")") libres."
  echo "Errores pendientes:"
  if [[ -s $FAILED_TXT ]]; then sed 's/^/  - /' "$FAILED_TXT"; else echo "  ninguno"; fi
  if [[ -n $fallos_antes && ! -s $FAILED_TXT ]]; then echo "  (se resolvieron los fallos anteriores)"; fi
  echo "Log completo: $ARCA_LOG_FILE"
} | tee -a "$resumen"
echo
echo "Recuerda actualizar la copia externa: sudo $ARCA_DIR/backup.sh /ruta/al/disco"
"$ARCA_DIR/lib/motd.sh" 2>/dev/null || true
