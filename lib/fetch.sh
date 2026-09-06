# shellcheck shell=bash
# lib/fetch.sh — descargas genéricas con reintentos y resolución de esquemas.
#
# Esquemas admitidos en manuals.conf:
#   https://host/archivo.pdf          descarga directa
#   ia://ITEM                          todos los PDF originales del ítem de archive.org
#   ia://ITEM/archivo.pdf              un archivo concreto del ítem
#   ocw://slug-del-curso               ZIP completo del curso en MIT OpenCourseWare
#   mirror://https://sitio/ruta/?max=N  espejo HTML con wget, límite N GB
#   openstax://en | openstax://es      todos los libros de texto OpenStax en PDF (inglés o español)
#   github://usuario/repo/REGEX        asset de la última release de GitHub que cumpla la REGEX
#   kernel://longterm | kernel://stable  último núcleo Linux de esa serie (kernel.org)
#
# Requiere lib/log.sh y lib/space.sh cargados.

ARCA_UA="${ARCA_UA:-Mozilla/5.0 (X11; Linux x86_64) arca/1.0 (+https://github.com/felipevidela/civilization_backup)}"
ARCA_TMP="${ARCA_TMP:-/srv/respaldo/.arca/tmp}"
FETCH_BACKOFF=(10 60 300)

# curl con opciones comunes (silencioso, sigue redirecciones, reintenta).
_curl() {
  curl -fsSL --connect-timeout 20 --max-time "${CURL_MAX_TIME:-120}" --retry 2 --retry-delay 5 -A "$ARCA_UA" "$@"
}

# Tamaño en bytes de una URL. Primero HEAD; si el servidor no lo informa
# (IRIS de la OMS devuelve 500 a HEAD), pide el primer byte y lee Content-Range.
fetch_size() {
  local url=$1 n cab
  # Solo el último bloque de cabeceras (la respuesta final tras las redirecciones).
  cab=$(curl -sIL --connect-timeout 20 --max-time 60 -A "$ARCA_UA" "$url" 2>/dev/null \
        | tr -d '\r' | awk 'BEGIN{RS=""} {b=$0} END{print b}')
  if grep -qE '^HTTP/[0-9.]+ 2' <<< "$cab"; then
    n=$(grep -i '^content-length:' <<< "$cab" | tail -1 | awk '{print $2}')
  fi
  if [[ -z ${n:-} || $n == 0 ]]; then
    cab=$(curl -sL --connect-timeout 20 --max-time 60 -A "$ARCA_UA" -r 0-0 -o /dev/null -D - "$url" 2>/dev/null \
          | tr -d '\r' | awk 'BEGIN{RS=""} {b=$0} END{print b}')
    n=$(grep -i '^content-range:' <<< "$cab" | tail -1 | sed 's#.*/##')
  fi
  if [[ -z ${n:-} || $n == 0 ]]; then
    # Servidores sin Content-Length ni Range (texto en chunked): se descarga entero si es pequeño.
    n=$(curl -sL --connect-timeout 20 --max-time 60 --max-filesize 20000000 -A "$ARCA_UA" -o /dev/null -w '%{size_download}' "$url" 2>/dev/null)
  fi
  if [[ ${n:-} =~ ^[0-9]+$ ]] && (( n > 0 )); then
    echo "$n"
    return 0
  fi
  return 1
}

# Descarga un archivo a un destino, con 3 intentos y backoff. Escribe en
# destino.part y renombra al terminar. Reanuda descargas parciales.
fetch_file() {
  local url=$1 destino=$2
  local dir base intento rc
  dir=$(dirname "$destino"); base=$(basename "$destino")
  mkdir -p "$dir"
  if [[ -s $destino ]]; then
    log_debug "Ya existe $destino; se omite."
    return 0
  fi
  for intento in 1 2 3; do
    log_debug "Descargando ($intento/3): $url"
    if command -v aria2c > /dev/null; then
      aria2c --continue=true --max-connection-per-server=4 --split=4 --min-split-size=20M \
        --file-allocation=none --dir="$dir" --out="$base.part" --user-agent="$ARCA_UA" \
        --connect-timeout=30 --timeout=60 --max-tries=3 --retry-wait=10 \
        --summary-interval=60 --console-log-level=warn --allow-overwrite=true \
        --auto-file-renaming=false --quiet="${ARIA2_QUIET:-false}" "$url" && rc=0 || rc=$?
    else
      curl -L -C - --connect-timeout 30 --retry 3 --retry-delay 10 -A "$ARCA_UA" \
        -o "$destino.part" "$url" && rc=0 || rc=$?
    fi
    if (( rc == 0 )) && [[ -s $destino.part ]]; then
      mv "$destino.part" "$destino"
      log_debug "OK: $destino ($(human "$(stat -c %s "$destino")"))"
      return 0
    fi
    log_warn "Fallo al descargar $url (intento $intento, código $rc)."
    (( intento < 3 )) && sleep "${FETCH_BACKOFF[$((intento - 1))]}"
  done
  return 1
}

# Verifica el sha256 de un archivo contra un hash esperado.
fetch_verify_sha256() {
  local archivo=$1 esperado=$2 real
  real=$(sha256sum "$archivo" | awk '{print $1}')
  if [[ $real == "$esperado" ]]; then
    return 0
  fi
  log_error "SHA256 incorrecto en $archivo: esperado $esperado, obtenido $real"
  return 1
}

# Última release de GitHub: imprime "tag<TAB>nombre<TAB>tamaño<TAB>url" del asset que
# coincida con la expresión regular. Sin token: 60 peticiones/hora bastan.
fetch_github_asset() {
  local repo=$1 regex=$2
  _curl -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$repo/releases/latest" \
    | jq -r --arg re "$regex" '.tag_name as $t | .assets[] | select(.name|test($re)) | [$t, .name, .size, .browser_download_url] | @tsv' \
    | head -1
}

# Tag de la última release de GitHub.
fetch_github_tag() {
  local repo=$1
  _curl -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$repo/releases/latest" | jq -r '.tag_name'
}

# Archivos de un ítem de archive.org: imprime "nombre<TAB>bytes<TAB>url" por línea.
# Sin nombre de archivo: los PDF subidos ("original"); si no hay, los PDF generados
# por archive.org a partir del escaneo ("derivative"). Excluye _text.pdf y _bw.pdf.
fetch_ia_files() {
  local item=$1 archivo=${2:-}
  local meta lista
  # Algunos ítems traen caracteres de control en los metadatos; se eliminan para jq.
  meta=$(_curl "https://archive.org/metadata/$item" | tr -d '\000-\010\013\014\016-\037') || return 1
  if [[ -n $archivo ]]; then
    printf '%s\t%s\t%s\n' "$archivo" \
      "$(jq -r --arg f "$archivo" '.files[] | select(.name==$f) | .size // 0' <<< "$meta")" \
      "https://archive.org/download/$item/$archivo"
    return 0
  fi
  lista=$(jq -r --arg item "$item" '
    [ .files[]
      | select(.name | test("\\.pdf$"; "i"))
      | select(.name | test("_(text|bw)\\.pdf$"; "i") | not) ] as $pdfs
    | ([ $pdfs[] | select((.source // "original") == "original") ]) as $orig
    | (if ($orig | length) > 0 then $orig else $pdfs end)[]
    | [.name, (.size // 0), ("https://archive.org/download/" + $item + "/" + .name)] | @tsv' <<< "$meta")
  [[ -n $lista ]] || return 1
  printf '%s\n' "$lista"
}

# URL del ZIP completo de un curso de MIT OpenCourseWare.
fetch_ocw_zip() {
  local slug=$1
  _curl "https://ocw.mit.edu/courses/$slug/download" | grep -o 'https://ocw.mit.edu/courses/[^"]*\.zip' | head -1
}

# Libros de texto OpenStax con PDF: imprime "título<TAB>url" por línea. Idioma en|es.
fetch_openstax_list() {
  local idioma=${1:-en} url
  if [[ $idioma == es ]]; then
    url="https://openstax.org/apps/cms/api/v2/pages/?type=books.Book&locale=es&limit=300&fields=title,book_state,high_resolution_pdf_url,pdf_url"
    _curl "$url" | jq -r '.items[] | select(.book_state=="live") | (.high_resolution_pdf_url // .pdf_url // "") as $u | select($u != "") | [.title, $u] | @tsv'
  else
    url="https://openstax.org/apps/cms/api/books"
    _curl "$url" | jq -r '.books[] | select(.book_state=="live") | (.high_resolution_pdf_url // .pdf_url // "") as $u | select($u != "") | [.title, $u] | @tsv'
  fi | sort -u -t$'\t' -k2,2
}

# URL del tarball del núcleo Linux más reciente de una serie (longterm|stable).
fetch_kernel_url() {
  local serie=${1:-longterm}
  _curl "https://www.kernel.org/releases.json" | jq -r --arg m "$serie" '[.releases[] | select(.moniker==$m)][0].source // empty'
}

# Tamaño estimado de un recurso de manuals.conf (según esquema).
fetch_resource_size() {
  local url=$1 total=0 n
  case $url in
    ia://*)
      local rest=${url#ia://} item archivo
      item=${rest%%/*}; archivo=""; [[ $rest == */* ]] && archivo=${rest#*/}
      while IFS=$'\t' read -r _ n _; do total=$((total + ${n:-0})); done < <(fetch_ia_files "$item" "$archivo")
      echo "$total" ;;
    ocw://*)
      local z; z=$(fetch_ocw_zip "${url#ocw://}") || return 1
      fetch_size "$z" ;;
    mirror://*)
      local max=${url##*max=}; [[ $max == "$url" ]] && max=1
      echo $(( max * 1024 * 1024 * 1024 )) ;;
    openstax://*)
      while IFS=$'\t' read -r _ u; do n=$(fetch_size "$u" 2>/dev/null || echo 0); total=$((total + n)); done < <(fetch_openstax_list "${url#openstax://}")
      echo "$total" ;;
    github://*)
      local rest=${url#github://} repo re
      repo=$(cut -d/ -f1-2 <<< "$rest"); re=${rest#"$repo"/}
      fetch_github_asset "$repo" "$re" | cut -f3 ;;
    kernel://*)
      local k; k=$(fetch_kernel_url "${url#kernel://}") || return 1
      [[ -n $k ]] && fetch_size "$k" ;;
    *)
      fetch_size "$url" ;;
  esac
}

# Espejo HTML con wget limitado al dominio y a un máximo de GB.
fetch_mirror() {
  local url=$1 dir=$2 max_gb=${3:-1}
  local host
  host=$(sed -E 's#^https?://([^/]+).*#\1#' <<< "$url")
  mkdir -p "$dir"
  wget --mirror --convert-links --page-requisites --no-parent --domains="$host" \
    --quota="${max_gb}g" --directory-prefix="$dir" --no-verbose --user-agent="$ARCA_UA" \
    --timeout=60 --tries=3 --wait=1 --random-wait \
    ${ARCA_LOG_FILE:+--append-output="$ARCA_LOG_FILE"} "$url"
  local rc=$?
  # wget devuelve 8 con errores de servidor en páginas sueltas; se acepta si hay contenido.
  if (( rc == 0 || rc == 8 )) && [[ -n $(find "$dir" -type f -print -quit) ]]; then
    return 0
  fi
  return "$rc"
}

# Descarga un recurso de manuals.conf a su destino (archivo o carpeta si termina en /).
# Imprime los bytes descargados. Devuelve 1 si algo falló.
fetch_resource() {
  local url=$1 destino=$2
  local rc=0 total=0
  case $url in
    ia://*)
      local rest=${url#ia://} item archivo nombre n u
      item=${rest%%/*}; archivo=""; [[ $rest == */* ]] && archivo=${rest#*/}
      local dir=$destino
      [[ $destino == */ ]] || dir=$(dirname "$destino")
      while IFS=$'\t' read -r nombre n u; do
        [[ -n $nombre ]] || continue
        local dest
        if [[ $destino == */ ]]; then dest="$destino$(basename "$nombre")"; else dest=$destino; fi
        if fetch_file "$u" "$dest"; then total=$((total + n)); else rc=1; fi
      done < <(fetch_ia_files "$item" "$archivo")
      mkdir -p "$dir" ;;
    ocw://*)
      local z; z=$(fetch_ocw_zip "${url#ocw://}") || { log_error "No se encontró el ZIP de OCW para ${url#ocw://}"; return 1; }
      local dest=$destino
      [[ $destino == */ ]] && dest="$destino$(basename "$z")"
      if fetch_file "$z" "$dest"; then total=$(stat -c %s "$dest"); else rc=1; fi ;;
    mirror://*)
      local u=${url#mirror://} max=1
      if [[ $u == *\?max=* ]]; then max=${u##*max=}; u=${u%\?max=*}; fi
      if fetch_mirror "$u" "$destino" "$max"; then total=$(space_used_bytes "$destino"); else rc=1; fi ;;
    github://*)
      local rest=${url#github://} repo re info nombre u dest
      repo=$(cut -d/ -f1-2 <<< "$rest"); re=${rest#"$repo"/}
      info=$(fetch_github_asset "$repo" "$re") || true
      IFS=$'\t' read -r _ nombre _ u <<< "$info"
      [[ -n $u ]] || { log_error "No hay asset que cumpla '$re' en la última release de $repo"; echo 0; return 1; }
      dest=$destino; [[ $destino == */ ]] && dest="$destino$nombre"
      if fetch_file "$u" "$dest"; then total=$(stat -c %s "$dest"); else rc=1; fi ;;
    kernel://*)
      local k dest
      k=$(fetch_kernel_url "${url#kernel://}") || true
      [[ -n $k ]] || { log_error "No se pudo leer kernel.org/releases.json"; echo 0; return 1; }
      dest=$destino; [[ $destino == */ ]] && dest="$destino$(basename "$k")"
      if fetch_file "$k" "$dest"; then total=$(stat -c %s "$dest"); find "$(dirname "$dest")" -maxdepth 1 -name 'linux-*.tar.xz' ! -name "$(basename "$k")" -delete; else rc=1; fi ;;
    openstax://*)
      local titulo u dest n=0
      mkdir -p "$destino"
      while IFS=$'\t' read -r titulo u; do
        [[ -n $u ]] || continue
        dest="${destino%/}/$(basename "${u%%\?*}")"
        if fetch_file "$u" "$dest"; then total=$((total + $(stat -c %s "$dest"))); n=$((n + 1)); else rc=1; log_warn "OpenStax: falló $titulo"; fi
      done < <(fetch_openstax_list "${url#openstax://}")
      (( n > 0 )) || rc=1 ;;
    *)
      local dest=$destino
      [[ $destino == */ ]] && dest="$destino$(basename "${url%%\?*}")"
      if fetch_file "$url" "$dest"; then total=$(stat -c %s "$dest"); else rc=1; fi ;;
  esac
  echo "$total"
  return "$rc"
}
