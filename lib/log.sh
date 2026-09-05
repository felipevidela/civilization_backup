# shellcheck shell=bash
# lib/log.sh — registro a pantalla y a archivo con marca de tiempo.
#
# Uso:
#   source lib/log.sh
#   log_init setup            # abre /opt/arca/logs/setup-YYYYMMDD-HHMMSS.log
#   log_info "mensaje"        # pantalla + archivo
#   log_warn / log_error / log_ok
#   log_debug "detalle"       # solo archivo
#   log_cmd comando args...   # ejecuta y manda la salida solo al archivo

ARCA_LOG_DIR="${ARCA_LOG_DIR:-/opt/arca/logs}"
ARCA_LOG_COPY="${ARCA_LOG_COPY:-/srv/respaldo/.arca/arca.log}"
ARCA_LOG_FILE="${ARCA_LOG_FILE:-}"

if [[ -t 1 ]]; then
  _C_ROJO=$'\e[31m'; _C_VERDE=$'\e[32m'; _C_AMARILLO=$'\e[33m'; _C_AZUL=$'\e[34m'; _C_FIN=$'\e[0m'
else
  _C_ROJO=""; _C_VERDE=""; _C_AMARILLO=""; _C_AZUL=""; _C_FIN=""
fi

log_init() {
  local nombre=$1
  mkdir -p "$ARCA_LOG_DIR"
  ARCA_LOG_FILE="$ARCA_LOG_DIR/${nombre}-$(date +%Y%m%d-%H%M%S).log"
  : > "$ARCA_LOG_FILE"
  export ARCA_LOG_FILE
  log_debug "Inicio de $nombre (pid $$, usuario ${SUDO_USER:-$(id -un)})"
}

_log_archivo() {
  local nivel=$1; shift
  local linea
  linea="[$(date '+%Y-%m-%d %H:%M:%S')] [$nivel] $*"
  if [[ -n $ARCA_LOG_FILE ]]; then
    printf '%s\n' "$linea" >> "$ARCA_LOG_FILE" 2>/dev/null || true
  fi
  if [[ -n $ARCA_LOG_COPY && -d ${ARCA_LOG_COPY%/*} ]]; then
    printf '%s\n' "$linea" >> "$ARCA_LOG_COPY" 2>/dev/null || true
  fi
}

log_debug() { _log_archivo DEBUG "$*"; }
log_info()  { _log_archivo INFO "$*";  printf '%s\n' "$*"; }
log_ok()    { _log_archivo OK "$*";    printf '%s✔ %s%s\n' "$_C_VERDE" "$*" "$_C_FIN"; }
log_warn()  { _log_archivo AVISO "$*"; printf '%s⚠ %s%s\n' "$_C_AMARILLO" "$*" "$_C_FIN" >&2; }
log_error() { _log_archivo ERROR "$*"; printf '%s✖ %s%s\n' "$_C_ROJO" "$*" "$_C_FIN" >&2; }
log_titulo() {
  _log_archivo FASE "$*"
  printf '\n%s== %s ==%s\n' "$_C_AZUL" "$*" "$_C_FIN"
}

# Ejecuta un comando volcando stdout/stderr al archivo de log. Devuelve su código.
log_cmd() {
  log_debug "\$ $*"
  if [[ -n $ARCA_LOG_FILE ]]; then
    "$@" >> "$ARCA_LOG_FILE" 2>&1
  else
    "$@" > /dev/null 2>&1
  fi
}

# Aborta el script con mensaje de error.
die() {
  log_error "$*"
  exit 1
}
