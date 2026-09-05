# shellcheck shell=bash
# lib/space.sh — chequeos de espacio en disco. Todo en bytes enteros.

# Bytes libres en la partición que contiene la ruta.
space_free_bytes() {
  local ruta=$1
  df -B1 --output=avail "$ruta" 2>/dev/null | tail -1 | tr -d ' '
}

# Bytes usados por una ruta (du).
space_used_bytes() {
  local ruta=$1
  [[ -e $ruta ]] || { echo 0; return; }
  du -sb "$ruta" 2>/dev/null | awk '{print $1}'
}

# Convierte bytes a formato legible (1.5 GB).
human() {
  local b=${1:-0}
  awk -v b="$b" 'BEGIN {
    split("B KB MB GB TB", u, " "); i = 1
    while (b >= 1024 && i < 5) { b /= 1024; i++ }
    if (i <= 2) printf "%d %s", b, u[i]; else printf "%.1f %s", b, u[i]
  }'
}

# Convierte "115G", "540M", "2.1G", "27K" (listados nginx) a bytes.
human_to_bytes() {
  local s=$1
  awk -v s="$s" 'BEGIN {
    n = s; sub(/[A-Za-z]+$/, "", n); u = s; sub(/^[0-9.]+/, "", u)
    m = 1
    if (u ~ /^[Kk]/) m = 1024
    else if (u ~ /^[Mm]/) m = 1024^2
    else if (u ~ /^[Gg]/) m = 1024^3
    else if (u ~ /^[Tt]/) m = 1024^4
    printf "%d", n * m
  }'
}

# Verifica que haya al menos $1 bytes libres en $2. Devuelve 1 y explica si no.
space_check() {
  local necesario=$1 ruta=${2:-/srv/respaldo}
  local libre
  libre=$(space_free_bytes "$ruta")
  if (( libre < necesario )); then
    log_error "Espacio insuficiente en $ruta: se necesitan $(human "$necesario"), hay $(human "$libre") libres (faltan $(human $((necesario - libre))))."
    return 1
  fi
  return 0
}
