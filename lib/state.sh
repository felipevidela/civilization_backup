# shellcheck shell=bash
# lib/state.sh — registro de fases completadas y lock de proceso.
#
# Estado en $ARCA_STATE_DIR/state, una línea por fase: "fase_3 OK 2026-09-05T10:00:00"
# Lock en $ARCA_STATE_DIR/<nombre>.lock con el PID del proceso.

ARCA_STATE_DIR="${ARCA_STATE_DIR:-/srv/respaldo/.arca}"
ARCA_STATE_FILE="$ARCA_STATE_DIR/state"
ARCA_LOCK_FILE=""

state_init() {
  mkdir -p "$ARCA_STATE_DIR"
  touch "$ARCA_STATE_FILE"
}

# ¿La fase ya está marcada como completada?
state_done() {
  local fase=$1
  [[ -f $ARCA_STATE_FILE ]] && grep -q "^${fase} OK" "$ARCA_STATE_FILE"
}

# Marca la fase como completada (idempotente).
state_mark() {
  local fase=$1
  state_init
  grep -v "^${fase} " "$ARCA_STATE_FILE" > "$ARCA_STATE_FILE.tmp" 2>/dev/null || true
  printf '%s OK %s\n' "$fase" "$(date -Is)" >> "$ARCA_STATE_FILE.tmp"
  mv "$ARCA_STATE_FILE.tmp" "$ARCA_STATE_FILE"
}

# Borra la marca de una fase.
state_unmark() {
  local fase=$1
  [[ -f $ARCA_STATE_FILE ]] || return 0
  grep -v "^${fase} " "$ARCA_STATE_FILE" > "$ARCA_STATE_FILE.tmp" || true
  mv "$ARCA_STATE_FILE.tmp" "$ARCA_STATE_FILE"
}

# Borra las marcas desde la fase N en adelante (para --from N).
state_clear_from() {
  local desde=$1 n
  for n in $(seq "$desde" 11); do state_unmark "fase_$n"; done
}

# Guarda un valor arbitrario (clave=valor) en $ARCA_STATE_DIR/vars.
state_set_var() {
  local clave=$1 valor=$2 archivo="$ARCA_STATE_DIR/vars"
  state_init
  touch "$archivo"
  grep -v "^${clave}=" "$archivo" > "$archivo.tmp" || true
  printf '%s=%s\n' "$clave" "$valor" >> "$archivo.tmp"
  mv "$archivo.tmp" "$archivo"
}

state_get_var() {
  local clave=$1 archivo="$ARCA_STATE_DIR/vars"
  [[ -f $archivo ]] || return 0
  grep "^${clave}=" "$archivo" | tail -1 | cut -d= -f2-
}

# Adquiere el lock; falla si otro proceso vivo lo tiene.
lock_acquire() {
  local nombre=$1
  state_init
  ARCA_LOCK_FILE="$ARCA_STATE_DIR/${nombre}.lock"
  if [[ -f $ARCA_LOCK_FILE ]]; then
    local pid
    pid=$(cat "$ARCA_LOCK_FILE" 2>/dev/null || true)
    if [[ -n $pid ]] && kill -0 "$pid" 2>/dev/null; then
      log_error "Ya hay un proceso $nombre en ejecución (pid $pid). Lock: $ARCA_LOCK_FILE"
      return 1
    fi
    log_warn "Lock huérfano de $nombre (pid $pid ya no existe); se reemplaza."
  fi
  echo $$ > "$ARCA_LOCK_FILE"
  trap 'lock_cleanup' EXIT
  trap 'log_warn "Interrumpido (SIGINT)"; exit 130' INT
  trap 'log_warn "Terminado (SIGTERM)"; exit 143' TERM
}

# Limpia el lock y termina los procesos hijos (aria2c, wget) para dejar estado consistente.
# Las descargas parciales (.aria2 / .part) se conservan: se reanudan en la siguiente corrida.
lock_cleanup() {
  local hijos
  hijos=$(jobs -p 2>/dev/null || true)
  if [[ -n $hijos ]]; then
    # shellcheck disable=SC2086
    kill $hijos 2>/dev/null || true
    sleep 1
    # shellcheck disable=SC2086
    kill -9 $hijos 2>/dev/null || true
  fi
  if [[ -n $ARCA_LOCK_FILE && -f $ARCA_LOCK_FILE ]] && [[ $(cat "$ARCA_LOCK_FILE" 2>/dev/null) == "$$" ]]; then
    rm -f "$ARCA_LOCK_FILE"
  fi
}
