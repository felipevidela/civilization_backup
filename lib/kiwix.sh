# shellcheck shell=bash
# lib/kiwix.sh — resolver la versión más reciente de un ZIM, descargarlo y verificarlo.
#
# Los ZIM viven en https://download.kiwix.org/zim/<carpeta>/<prefijo>_YYYY-MM[a-z].zim
# (la raíz /zim/ redirige a hub.kiwix.org, pero cada carpeta sirve un listado nginx
# tras redirigir a lb.download.kiwix.org). Cada ZIM tiene .sha256, .torrent y .magnet.
#
# Requiere lib/log.sh, lib/space.sh y lib/fetch.sh cargados.

KIWIX_BASE="${KIWIX_BASE:-https://download.kiwix.org/zim}"
ZIM_JSON="${ZIM_JSON:-${ARCA_STATE_DIR:-/srv/respaldo/.arca}/zim.json}"

# Listado HTML de una carpeta, con caché en disco durante la ejecución.
kiwix_listing() {
  local carpeta=$1 cache
  mkdir -p "$ARCA_TMP"
  cache="$ARCA_TMP/kiwix_listing_${carpeta//\//_}.html"
  if [[ ! -s $cache ]]; then
    _curl "$KIWIX_BASE/$carpeta/" > "$cache.tmp" || { rm -f "$cache.tmp"; return 1; }
    mv "$cache.tmp" "$cache"
  fi
  cat "$cache"
}

kiwix_cache_clear() {
  rm -f "${ARCA_TMP:?}"/kiwix_listing_*.html 2>/dev/null || true
}

# Escapa un prefijo para usarlo en una expresión regular extendida.
_kiwix_re() {
  sed -E 's/[.[\*^$+?(){}|]/\\&/g' <<< "$1"
}

# Nombre del ZIM más reciente para carpeta/prefijo (por fecha YYYY-MM y sufijo).
kiwix_latest() {
  local carpeta=$1 prefijo=$2 re nombre
  re="$(_kiwix_re "$prefijo")_[0-9]{4}-[0-9]{2}[a-z]?\\.zim"
  nombre=$(kiwix_listing "$carpeta" | grep -oE "href=\"${re}\"" | sed 's/^href="//;s/"$//' | sort | tail -1)
  [[ -n $nombre ]] || return 1
  echo "$nombre"
}

# Fecha YYYY-MM de un nombre de ZIM.
kiwix_fecha() {
  sed -E 's/.*_([0-9]{4}-[0-9]{2})[a-z]?\.zim$/\1/' <<< "$1"
}

kiwix_url() {
  echo "$KIWIX_BASE/$1/$2"
}

# Tamaño aproximado según el listado ("115G" → bytes). Rápido, sin HEAD.
kiwix_listed_size() {
  local carpeta=$1 nombre=$2 s
  s=$(kiwix_listing "$carpeta" | grep -F "href=\"$nombre\"" | sed 's/<[^>]*>//g' | awk '{print $NF}')
  [[ -n $s ]] || return 1
  human_to_bytes "$s"
}

# Tamaño exacto (Content-Length) siguiendo redirecciones al mirror.
kiwix_size() {
  fetch_size "$(kiwix_url "$1" "$2")"
}

# Hash sha256 publicado por Kiwix.
kiwix_sha256_remote() {
  _curl "$(kiwix_url "$1" "$2").sha256" | awk '{print $1}'
}

# Verifica un ZIM local contra el hash publicado. Imprime el hash si es correcto.
kiwix_verify() {
  local carpeta=$1 nombre=$2 dir=$3 esperado
  esperado=$(kiwix_sha256_remote "$carpeta" "$nombre") || return 1
  [[ $esperado =~ ^[0-9a-f]{64}$ ]] || { log_error "No se pudo leer el .sha256 de $nombre"; return 1; }
  fetch_verify_sha256 "$dir/$nombre" "$esperado" || return 1
  echo "$esperado"
}

# Descarga por torrent con aria2c; devuelve 1 si falla o no hay pares en 10 minutos.
_kiwix_download_torrent() {
  local carpeta=$1 nombre=$2 dir=$3 torrent
  torrent="$ARCA_TMP/$nombre.torrent"
  _curl -o "$torrent" "$(kiwix_url "$carpeta" "$nombre").torrent" || return 1
  aria2c --seed-time=0 --continue=true --max-connection-per-server=8 --split=8 \
    --file-allocation=none --dir="$dir" --bt-stop-timeout=600 --bt-tracker-connect-timeout=30 \
    --bt-max-peers=60 --enable-dht=true --summary-interval=60 --console-log-level=warn \
    --user-agent="$ARCA_UA" --quiet="${ARIA2_QUIET:-false}" "$torrent"
}

# Descarga HTTP directa con aria2c (8 conexiones), reanudable.
_kiwix_download_http() {
  local carpeta=$1 nombre=$2 dir=$3
  aria2c --continue=true --max-connection-per-server=8 --split=8 --min-split-size=20M \
    --file-allocation=none --dir="$dir" --out="$nombre" --max-tries=5 --retry-wait=30 \
    --timeout=60 --connect-timeout=30 --summary-interval=60 --console-log-level=warn \
    --user-agent="$ARCA_UA" --quiet="${ARIA2_QUIET:-false}" "$(kiwix_url "$carpeta" "$nombre")"
}

# Descarga y verifica un ZIM. Intenta torrent, luego HTTP; si el sha256 falla, borra y
# reintenta una vez por HTTP. Imprime el sha256 al terminar bien.
kiwix_download() {
  local carpeta=$1 nombre=$2 dir=$3
  local intento hash
  mkdir -p "$dir" "$ARCA_TMP"
  for intento in 1 2; do
    if [[ ! -f "$dir/$nombre.aria2" && -s "$dir/$nombre" ]]; then
      log_debug "$nombre ya está completo en disco; solo se verifica."
    elif (( intento == 1 )) && [[ ${KIWIX_USE_TORRENT:-1} == 1 ]] && _kiwix_download_torrent "$carpeta" "$nombre" "$dir"; then
      log_debug "$nombre descargado por torrent."
    else
      log_debug "$nombre: torrent no disponible o sin pares; descarga HTTP directa."
      rm -f "$dir/$nombre" "$dir/$nombre.aria2"
      _kiwix_download_http "$carpeta" "$nombre" "$dir" || { log_warn "Falló la descarga HTTP de $nombre (intento $intento)."; continue; }
    fi
    if hash=$(kiwix_verify "$carpeta" "$nombre" "$dir"); then
      rm -f "$ARCA_TMP/$nombre.torrent" "$dir/$nombre.aria2"
      echo "$hash"
      return 0
    fi
    log_warn "Verificación fallida de $nombre (intento $intento); se borra y se reintenta."
    rm -f "$dir/$nombre" "$dir/$nombre.aria2"
  done
  return 1
}

# Borra versiones anteriores del mismo prefijo, conservando el archivo indicado.
# Solo debe llamarse después de una verificación correcta.
kiwix_prune_old() {
  local dir=$1 prefijo=$2 conservar=$3 f re
  re="^$(_kiwix_re "$prefijo")_[0-9]{4}-[0-9]{2}[a-z]?\\.zim$"
  for f in "$dir/${prefijo}_"*.zim; do
    [[ -f $f ]] || continue
    [[ $(basename "$f") =~ $re ]] || continue
    [[ $(basename "$f") == "$conservar" ]] && continue
    log_info "Borrando versión anterior: $(basename "$f")"
    rm -f "$f" "$f.aria2"
  done
}

# --- Registro zim.json: {"prefijo": {"archivo","sha256","fecha","bytes","verificado_en"}} ---

zim_json_init() {
  [[ -s $ZIM_JSON ]] || { mkdir -p "$(dirname "$ZIM_JSON")"; echo '{}' > "$ZIM_JSON"; }
}

zim_json_get() {
  local prefijo=$1 campo=$2
  [[ -s $ZIM_JSON ]] || return 1
  jq -r --arg p "$prefijo" --arg c "$campo" '.[$p][$c] // empty' "$ZIM_JSON"
}

zim_json_set() {
  local prefijo=$1 archivo=$2 sha=$3 bytes=$4
  zim_json_init
  jq --arg p "$prefijo" --arg a "$archivo" --arg s "$sha" --arg f "$(kiwix_fecha "$archivo")" \
     --argjson b "$bytes" --arg t "$(date -Is)" \
     '.[$p] = {archivo: $a, sha256: $s, fecha: $f, bytes: $b, verificado_en: $t}' \
     "$ZIM_JSON" > "$ZIM_JSON.tmp" && mv "$ZIM_JSON.tmp" "$ZIM_JSON"
}

zim_json_del() {
  local prefijo=$1
  [[ -s $ZIM_JSON ]] || return 0
  jq --arg p "$prefijo" 'del(.[$p])' "$ZIM_JSON" > "$ZIM_JSON.tmp" && mv "$ZIM_JSON.tmp" "$ZIM_JSON"
}

# ¿El ZIM registrado para el prefijo está presente, completo y coincide con el nombre?
zim_installed_ok() {
  local prefijo=$1 nombre=$2 dir=$3 bytes
  [[ $(zim_json_get "$prefijo" archivo) == "$nombre" ]] || return 1
  [[ -s "$dir/$nombre" && ! -f "$dir/$nombre.aria2" ]] || return 1
  bytes=$(zim_json_get "$prefijo" bytes)
  [[ $(stat -c %s "$dir/$nombre") == "$bytes" ]]
}

# Lee packs.conf: imprime "carpeta<TAB>prefijo" por línea activa.
packs_read() {
  local archivo=$1
  sed -E 's/#.*$//; s/[[:space:]]+$//; /^[[:space:]]*$/d' "$archivo" | while read -r linea; do
    [[ $linea == */* ]] || continue
    printf '%s\t%s\n' "${linea%%/*}" "${linea#*/}"
  done
}
