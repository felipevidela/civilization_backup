#!/usr/bin/env bash
# setup.sh — instalación completa de arca por fases, reanudable.
#
# Uso: sudo ./setup.sh [--profile core|recovery|full] [--extra NOMBRE]... [--dry-run] [--from N] [--only N]
#   --profile P  perfil de instalación: core (≈60 GB), recovery (≈255 GB) o full (≈490 GB, por defecto).
#                Se recuerda en /srv/respaldo/.arca/profile; sin --profile se reutiliza el guardado.
#   --extra X    activa un extra opcional (gutenberg-full, stackoverflow-full, wikipedia-fr...). Repetible.
#   --dry-run    muestra qué haría y cuánto pesaría, sin descargar ni instalar
#   --from N     vuelve a ejecutar desde la fase N (borra las marcas de N en adelante)
#   --only N     ejecuta solo la fase N
#
# Cada fase completada se anota en /srv/respaldo/.arca/state; al relanzar se saltan.
# Fases: 0 prerrequisitos, 1 estructura, 2 paquetes, 3 ZIM, 4 manuales, 5 mapas,
#        6 software, 7 biblioteca+servicio, 8 sistema, 9 timer, 10 README, 11 resumen.
set -euo pipefail

ARCA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESPALDO="${RESPALDO:-/srv/respaldo}"
DRY_RUN=0; DESDE=""; SOLO=""; ARCA_PERFIL="${ARCA_PERFIL:-}"; ARCA_EXTRAS="${ARCA_EXTRAS:-}"

uso() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
while (( $# )); do
  case $1 in
    --dry-run) DRY_RUN=1 ;;
    --profile) ARCA_PERFIL=${2:-}; shift ;;
    --profile=*) ARCA_PERFIL=${1#--profile=} ;;
    --extra) ARCA_EXTRAS="$ARCA_EXTRAS ${2:-}"; shift ;;
    --extra=*) ARCA_EXTRAS="$ARCA_EXTRAS ${1#--extra=}" ;;
    --from) DESDE=${2:-}; shift ;;
    --only) SOLO=${2:-}; shift ;;
    -h|--help) uso ;;
    *) echo "Argumento desconocido: $1" >&2; uso 1 ;;
  esac
  shift
done
for v in "$DESDE" "$SOLO"; do
  [[ -z $v || $v =~ ^([0-9]|1[01])$ ]] || { echo "Fase inválida: $v (0-11)" >&2; exit 1; }
done

USUARIO="${ARCA_USER:-${SUDO_USER:-}}"
if (( DRY_RUN )) && [[ $(id -u) -ne 0 ]]; then
  # Sin root, el ensayo usa /tmp para caché y log.
  ARCA_STATE_DIR="/tmp/arca-dry-run"; ARCA_LOG_DIR="/tmp/arca-dry-run/logs"; ARCA_LOG_COPY=""
  USUARIO="${USUARIO:-$(id -un)}"
else
  ARCA_STATE_DIR="$RESPALDO/.arca"; ARCA_LOG_DIR="$ARCA_DIR/logs"; ARCA_LOG_COPY="$ARCA_STATE_DIR/arca.log"
fi
ARCA_TMP="$ARCA_STATE_DIR/tmp"
PACKS_CONF="${PACKS_CONF:-$ARCA_DIR/packs.conf}"
MANUALS_CONF="${MANUALS_CONF:-$ARCA_DIR/manuals.conf}"
SOFTWARE_CONF="${SOFTWARE_CONF:-$ARCA_DIR/software.conf}"
MODO_UPDATE=0
export ARCA_DIR RESPALDO ARCA_STATE_DIR ARCA_TMP ARCA_LOG_DIR ARCA_LOG_COPY USUARIO PACKS_CONF MANUALS_CONF SOFTWARE_CONF DRY_RUN MODO_UPDATE

for lib in log space state profiles fetch kiwix readme phases; do
  # shellcheck disable=SC1090
  source "$ARCA_DIR/lib/$lib.sh"
done

mkdir -p "$ARCA_STATE_DIR" "$ARCA_TMP" "$ARCA_LOG_DIR"
log_init setup
[[ -f $PACKS_CONF ]] || die "No existe $PACKS_CONF"
perfil_cargar
(( DRY_RUN )) || perfil_guardar

if (( DRY_RUN )); then
  log_titulo "ENSAYO (--dry-run): no se descarga ni se instala nada"
  [[ $(id -u) -eq 0 ]] || log_warn "Sin root: se omiten las comprobaciones de sudo y montaje."
  if [[ $(id -u) -eq 0 ]]; then
    fase_0 || exit 1
  else
    # Solo la estimación de espacio.
    software_load; MARGEN_PCT=${MARGEN_ESPACIO_PCT:-$MARGEN_PCT}
    kiwix_cache_clear
    tabla=$(estimar_pendiente)
    tabla_imprimir "$tabla"
    resumen_estimacion "$tabla" "$(space_free_bytes "$RESPALDO" || echo 0)"
  fi
  echo
  echo "Fases que se ejecutarían: 1 estructura, 2 paquetes apt/flatpak, 3 ZIM (aria2/torrent), 4 manuales,"
  echo "5 mapas, 6 software (.deb, AppImage, APK, ISO, llama.cpp+modelo), 7 library.xml + kiwix.service,"
  echo "8 energía/motd/ufw, 9 timer mensual, 10 README.txt, 11 resumen."
  exit 0
fi

lock_acquire setup || exit 1
[[ -n $DESDE ]] && { state_clear_from "$DESDE"; log_info "Marcas borradas desde la fase $DESDE."; }

ejecutar_fase() {
  local n=$1
  if [[ -n $SOLO && $SOLO != "$n" ]]; then return 0; fi
  if (( n <= 9 )) && [[ -z $SOLO ]] && state_done "fase_$n"; then
    log_info "Fase $n ya completada; se salta."
    return 0
  fi
  local inicio; inicio=$(date +%s)
  if "fase_$n"; then
    (( n <= 9 )) && state_mark "fase_$n"
    log_debug "Fase $n terminada en $(( $(date +%s) - inicio )) s."
  else
    die "La fase $n falló. Corrige el problema y relanza: sudo $ARCA_DIR/setup.sh (continúa donde quedó)"
  fi
}

log_info "arca setup — perfil $ARCA_PERFIL${ARCA_EXTRAS:+ + extras:$ARCA_EXTRAS}, usuario $USUARIO, datos en $RESPALDO, log $ARCA_LOG_FILE"
for n in 0 1 2 3 4 5 6 7 8 9 10 11; do ejecutar_fase "$n"; done
log_ok "Instalación completa."
