# shellcheck shell=bash
# lib/phases.sh — fases de instalación. Las usan setup.sh y update.sh.
#
# Variables esperadas (las fija setup.sh/update.sh):
#   ARCA_DIR (repo), RESPALDO (/srv/respaldo), ARCA_STATE_DIR, ARCA_TMP, USUARIO,
#   PACKS_CONF, MANUALS_CONF, SOFTWARE_CONF, DRY_RUN (0/1), MODO_UPDATE (0/1)

ARCA_DIR="${ARCA_DIR:-/opt/arca}"
RESPALDO="${RESPALDO:-/srv/respaldo}"
PUERTO="${PUERTO:-8080}"
FAILED_TXT="$ARCA_STATE_DIR/failed.txt"
MANUALS_JSON="$ARCA_STATE_DIR/manuals.json"
SOFTWARE_JSON="$ARCA_STATE_DIR/software.json"
ZIM_DIR="$RESPALDO/zim"
MAX_DESCARGAS="${MAX_DESCARGAS:-3}"
MARGEN_PCT="${MARGEN_PCT:-15}"

# ---------------------------------------------------------------- utilidades

systemd_ok() {
  [[ -d /run/systemd/system ]] && command -v systemctl > /dev/null
}

json_init() { [[ -s $1 ]] || { mkdir -p "$(dirname "$1")"; echo '{}' > "$1"; }; }
json_get()  { [[ -s $1 ]] && jq -r --arg k "$2" --arg c "$3" '.[$k][$c] // empty' "$1"; }
json_set()  {
  local archivo=$1 clave=$2; shift 2
  json_init "$archivo"
  # Argumentos restantes: pares campo valor.
  # shellcheck disable=SC2016
  local filtro='.[$k] = (.[$k] // {})' args=(--arg k "$clave") i=0
  while (( $# >= 2 )); do
    args+=(--arg "c$i" "$1" --arg "v$i" "$2")
    filtro+=" | .[\$k][\$c$i] = \$v$i"
    i=$((i + 1)); shift 2
  done
  jq "${args[@]}" "$filtro" "$archivo" > "$archivo.tmp" && mv "$archivo.tmp" "$archivo"
}

failed_add() {
  local clave=$1 motivo=$2
  mkdir -p "$ARCA_STATE_DIR"
  touch "$FAILED_TXT"
  grep -vF "$clave | " "$FAILED_TXT" > "$FAILED_TXT.tmp" || true
  printf '%s | %s | %s\n' "$clave" "$motivo" "$(date -Is)" >> "$FAILED_TXT.tmp"
  mv "$FAILED_TXT.tmp" "$FAILED_TXT"
  log_error "FALLO: $clave — $motivo"
}

failed_del() {
  [[ -f $FAILED_TXT ]] || return 0
  grep -vF "$1 | " "$FAILED_TXT" > "$FAILED_TXT.tmp" || true
  mv "$FAILED_TXT.tmp" "$FAILED_TXT"
}

_trim() { sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' <<< "$1"; }

# Migración: si un manual ya estaba descargado en la ubicación antigua (antes de las carpetas
# medicina/actual, agua/, manufactura/, ...), se mueve a la nueva sin volver a bajarlo.
migrar_ruta_antigua() {
  local nuevo=$1 base antiguo carpeta
  [[ $nuevo == */ ]] && return 0
  base=$(basename "$nuevo")
  [[ -e "$RESPALDO/$nuevo" ]] && return 0
  for carpeta in manuales/medicina manuales/ingenieria manuales/supervivencia manuales/fisica; do
    antiguo="$RESPALDO/$carpeta/$base"
    if [[ -s $antiguo && "$carpeta/$base" != "$nuevo" ]]; then
      mkdir -p "$(dirname "$RESPALDO/$nuevo")"
      mv "$antiguo" "$RESPALDO/$nuevo"
      log_info "Migrado: $carpeta/$base → $nuevo"
      return 0
    fi
  done
}

# Lee manuals.conf: "perfil<TAB>prioridad<TAB>categoria<TAB>destino<TAB>url<TAB>descripción<TAB>licencia"
# por línea no comentada. Formato: "perfil prio cat | destino | url | desc [| licencia]";
# sin atributos ("destino | url | desc") se asume full P2 general.
manuals_read() {
  local c1 c2 c3 c4 c5 p pr cat d u desc lic
  sed -E '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$MANUALS_CONF" | while IFS='|' read -r c1 c2 c3 c4 c5; do
    c1=$(_trim "$c1"); c2=$(_trim "$c2"); c3=$(_trim "$c3"); c4=$(_trim "$c4"); c5=$(_trim "$c5")
    if [[ $c1 =~ ^(survive|core|recovery|full|extra:[a-z0-9-]+)[[:space:]]+P[0-3][[:space:]]+[a-z-]+$ ]]; then
      read -r p pr cat <<< "$c1"; d=$c2; u=$c3; desc=$c4; lic=$c5
    else
      p=full; pr=P2; cat=general; d=$c1; u=$c2; desc=$c3; lic=$c4
    fi
    [[ -n $d && -n $u ]] || continue
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$p" "$pr" "$cat" "$d" "$u" "$desc" "${lic:-unknown}"
  done
}

# ¿El software con clave $1 (deb, kiwix, organicmaps, mapas, iso, llm, llm7b, ia, repo, source)
# entra en el perfil actual? Se define en SOFT_PERFILES de software.conf.
soft_activo() {
  local clave=$1 par
  for par in ${SOFT_PERFILES:-}; do
    [[ ${par%%:*} == "$clave" ]] && { recurso_activo "${par#*:}"; return; }
  done
  return 0
}

software_load() {
  # shellcheck disable=SC1090
  source "$SOFTWARE_CONF"
}

chown_respaldo() {
  [[ -n ${USUARIO:-} ]] && chown -R "$USUARIO:$USUARIO" "$@" 2>/dev/null || true
}

ip_local() {
  hostname -I 2>/dev/null | awk '{print $1}'
}

# ---------------------------------------------------------------- estimación de espacio

# Imprime la tabla de estimar_pendiente en formato legible.
tabla_imprimir() {
  local t a b e pr cat p
  printf '\n%-8s %-3s %-13s %-56s %10s  %s\n' "TIPO" "PRI" "CATEGORÍA" "ARCHIVO" "TAMAÑO" "ESTADO"
  while IFS=$'\t' read -r t a b e pr cat p; do
    [[ -n $t ]] || continue
    printf '%-8s %-3s %-13s %-56s %10s  %s\n' "$t" "$pr" "${cat:0:13}" "${a:0:56}" "$(human "$b")" "$e"
  done <<< "$1"
}

# Imprime "tipo<TAB>nombre<TAB>bytes<TAB>estado<TAB>prioridad<TAB>categoria<TAB>perfil" por
# recurso del perfil activo (pendiente o instalado). Los inactivos no aparecen.
estimar_pendiente() {
  local p pr cat carpeta prefijo nombre bytes estado
  # ZIM
  while IFS=$'\t' read -r p pr cat carpeta prefijo; do
    recurso_activo "$p" || continue
    if ! nombre=$(kiwix_latest "$carpeta" "$prefijo"); then
      printf 'zim\t%s/%s\t0\tNO EXISTE en el servidor\t%s\t%s\t%s\n' "$carpeta" "$prefijo" "$pr" "$cat" "$p"; continue
    fi
    bytes=$(kiwix_listed_size "$carpeta" "$nombre" || echo 0)
    if zim_installed_ok "$prefijo" "$nombre" "$ZIM_DIR"; then estado=instalado; else estado=pendiente; fi
    printf 'zim\t%s\t%s\t%s\t%s\t%s\t%s\n' "$nombre" "$bytes" "$estado" "$pr" "$cat" "$p"
  done < <(packs_read "$PACKS_CONF")
  # Manuales
  local d u desc lic ruta
  while IFS=$'\t' read -r p pr cat d u desc lic; do
    recurso_activo "$p" || continue
    ruta="$RESPALDO/$d"
    if [[ $d == */ ]]; then
      [[ -n $(find "$ruta" -type f -print -quit 2>/dev/null) ]] && estado=instalado || estado=pendiente
    else
      [[ -s $ruta ]] && estado=instalado || estado=pendiente
    fi
    if [[ $estado == instalado ]]; then
      bytes=$(space_used_bytes "$ruta")
    else
      bytes=$(fetch_resource_size "$u" 2>/dev/null || echo 0)
    fi
    [[ $d == */ ]] && d="$d${u##*/}"
    printf 'manual\t%s\t%s\t%s\t%s\t%s\t%s\n' "$d" "$bytes" "$estado" "$pr" "$cat" "$p"
  done < <(manuals_read)
  # Mapas
  software_load
  if [[ ${MAPAS:-1} == 1 ]] && soft_activo mapas; then
    local id s
    while IFS=$'\t' read -r id s; do
      [[ -s "$RESPALDO/mapas/$id.mwm" ]] && estado=instalado || estado=pendiente
      printf 'mapa\t%s.mwm\t%s\t%s\tP0\tmapas\tcore\n' "$id" "$s" "$estado"
    done < <(mapas_regiones)
  fi
  # Software
  local dir_soft="$RESPALDO/software"
  if [[ ${UBUNTU_ISO:-1} == 1 ]] && soft_activo iso; then
    local iso; iso=$(iso_ultima_linea | awk '{print $2}' | tr -d '*')
    if [[ -n $iso ]]; then
      [[ -s "$dir_soft/iso/$iso" ]] && estado=instalado || estado=pendiente
      bytes=$(fetch_size "$UBUNTU_ISO_URL_BASE/$iso" 2>/dev/null || echo 6500000000)
      printf 'software\t%s\t%s\t%s\tP1\tsoftware\trecovery\n' "$iso" "$bytes" "$estado"
    fi
  fi
  if [[ ${LLM_ENABLED:-1} == 1 ]] && soft_activo llm; then
    local m
    if soft_activo llm7b; then
      m=$(hf_modelo_info 2>/dev/null || true)
      bytes=${m%%$'\t'*}; [[ $bytes =~ ^[0-9]+$ ]] || bytes=4700000000
      [[ -s "$dir_soft/llm/modelos/$LLM_MODEL_FILE" ]] && estado=instalado || estado=pendiente
      printf 'software\t%s\t%s\t%s\tP1\tia\trecovery\n' "$LLM_MODEL_FILE" "$bytes" "$estado"
    fi
    if [[ -n ${LLM_RAPIDO_FILE:-} ]]; then
      m=$(hf_modelo_info "${LLM_RAPIDO_REPO:-$LLM_MODEL_REPO}" "$LLM_RAPIDO_FILE" 2>/dev/null || true)
      bytes=${m%%$'\t'*}; [[ $bytes =~ ^[0-9]+$ ]] || bytes=2000000000
      [[ -s "$dir_soft/llm/modelos/$LLM_RAPIDO_FILE" ]] && estado=instalado || estado=pendiente
      printf 'software\t%s\t%s\t%s\tP1\tia\tcore\n' "$LLM_RAPIDO_FILE" "$bytes" "$estado"
    fi
    [[ -x "$dir_soft/llm/llama.cpp/build/bin/llama-cli" ]] && estado=instalado || estado=pendiente
    printf 'software\tllama.cpp (fuentes+binarios)\t800000000\t%s\tP1\tia\tcore\n' "$estado"
  fi
  if [[ ${IA_ENABLED:-1} == 1 ]] && soft_activo ia; then
    [[ -d "$dir_soft/ia/codigo" ]] && estado=instalado || estado=pendiente
    printf 'software\tIA desde cero (código + ruedas Python)\t400000000\t%s\tP1\tia\trecovery\n' "$estado"
  fi
  [[ -d "$dir_soft/deb" ]] && estado=instalado || estado=pendiente
  printf 'software\tpaquetes .deb con dependencias\t1500000000\t%s\tP0\tsoftware\tcore\n' "$estado"
  printf 'software\tAppImage, APKs, kiwix-tools\t450000000\t%s\tP0\tsoftware\tcore\n' "$([[ -d $dir_soft/kiwix ]] && echo instalado || echo pendiente)"
}

# Recursos de packs/manuals que NO entran en el perfil actual: "tipo<TAB>nombre<TAB>perfil<TAB>tamaño_aprox".
listar_desactivados() {
  local p pr cat carpeta prefijo d u desc lic linea
  while IFS=$'\t' read -r p pr cat carpeta prefijo; do
    recurso_activo "$p" && continue
    linea=$(grep -F -m1 "$carpeta/$prefijo" "$PACKS_CONF" | sed -E 's/.*#[[:space:]]*//' || true)
    printf 'zim\t%s\t%s\t%s\n' "$prefijo" "$p" "${linea:-?}"
  done < <(packs_read "$PACKS_CONF")
  while IFS=$'\t' read -r p pr cat d u desc lic; do
    recurso_activo "$p" && continue
    printf 'manual\t%s\t%s\t%s\n' "$d" "$p" "$desc"
  done < <(manuals_read)
}

# Resumen del ensayo/fase 0 a partir de la tabla de estimar_pendiente.
resumen_estimacion() {
  local tabla=$1 libre=$2
  local pendiente instalado necesario
  pendiente=$(awk -F'\t' '$4=="pendiente"{s+=$3} END{printf "%d", s}' <<< "$tabla")
  instalado=$(awk -F'\t' '$4=="instalado"{s+=$3} END{printf "%d", s}' <<< "$tabla")
  necesario=$(( pendiente + pendiente * MARGEN_PCT / 100 ))
  echo
  echo "Perfil: $ARCA_PERFIL${ARCA_EXTRAS:+  (extras: $ARCA_EXTRAS)}"
  echo "Contenido del perfil por prioridad (instalado + pendiente):"
  local pr
  for pr in P0 P1 P2 P3; do
    printf '  %-22s %10s\n' "$(prioridad_nombre "$pr")" "$(human "$(awk -F'\t' -v p="$pr" '$5==p{s+=$3} END{printf "%d", s}' <<< "$tabla")")"
  done
  echo "Recursos más pesados:"
  # "|| true": head cierra la tubería y sort fallaría por SIGPIPE con pipefail.
  sort -t$'\t' -k3,3rn <<< "$tabla" | head -8 | while IFS=$'\t' read -r _ n b e _; do printf '  %-62s %10s  %s\n' "${n:0:62}" "$(human "$b")" "$e"; done || true
  printf '\nYa en disco: %s   Pendiente de descargar: %s   Con %d%% de margen: %s\n' \
    "$(human "$instalado")" "$(human "$pendiente")" "$MARGEN_PCT" "$(human "$necesario")"
  if (( libre >= pendiente )); then
    printf 'Libre ahora en %s: %s   Libre estimado tras instalar: %s\n' "$RESPALDO" "$(human "$libre")" "$(human $(( libre - pendiente )))"
  else
    printf 'Libre ahora en %s: %s   Faltarían %s incluso sin margen\n' "$RESPALDO" "$(human "$libre")" "$(human $(( pendiente - libre )))"
  fi
  local des; des=$(listar_desactivados)
  if [[ -n $des ]]; then
    echo
    echo "Fuera de este perfil ($(grep -c . <<< "$des") recursos; se activan con --profile mayor o --extra <nombre>):"
    grep -P '\textra:' <<< "$des" | while IFS=$'\t' read -r t n p info; do printf '  --extra %-20s %-45s %s\n' "${p#extra:}" "$n" "${info:0:50}"; done
    grep -vP '\textra:' <<< "$des" | awk -F'\t' '{c[$3]++} END{for (k in c) printf "  perfil %-9s %d recursos\n", k, c[k]}'
  fi
}

# ---------------------------------------------------------------- fase 0

fase_0() {
  log_titulo "Fase 0: prerrequisitos"
  [[ $(id -u) -eq 0 ]] || die "setup.sh debe ejecutarse con sudo."
  [[ -n ${USUARIO:-} ]] || die "SUDO_USER no está definido: ejecuta con sudo desde tu usuario normal, no como root directo."
  id "$USUARIO" > /dev/null 2>&1 || die "El usuario $USUARIO no existe."

  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-}:${VERSION_ID:-}" in
    ubuntu:24.04) log_ok "Ubuntu 24.04 LTS" ;;
    debian:12)    log_warn "Debian 12: no probado, se continúa." ;;
    *) die "Sistema no soportado: ${PRETTY_NAME:-?}. Se requiere Ubuntu 24.04." ;;
  esac

  curl -fsSI --connect-timeout 15 --max-time 30 "https://download.kiwix.org/" > /dev/null 2>&1 \
    || die "Sin conexión a download.kiwix.org."
  log_ok "Conexión a download.kiwix.org"

  [[ -d $RESPALDO ]] || die "$RESPALDO no existe. Crea la partición y móntala ahí (ver README)."
  if ! mountpoint -q "$RESPALDO"; then
    if [[ ${ARCA_PERMITIR_SIN_MONTAJE:-0} == 1 ]]; then
      log_warn "$RESPALDO no es un punto de montaje (permitido por ARCA_PERMITIR_SIN_MONTAJE=1)."
    else
      die "$RESPALDO no está montado. Todo se guardaría en la partición raíz. Monta la partición de datos ahí o exporta ARCA_PERMITIR_SIN_MONTAJE=1 si sabes lo que haces."
    fi
  fi
  local fs; fs=$(findmnt -no FSTYPE --target "$RESPALDO" 2>/dev/null || echo "?")
  case $fs in
    ext4|exfat) log_ok "$RESPALDO montado ($fs)" ;;
    *) log_warn "$RESPALDO tiene sistema de archivos '$fs' (esperado ext4 o exFAT). Se continúa." ;;
  esac

  mkdir -p "$ARCA_STATE_DIR" "$ARCA_TMP"
  software_load
  MARGEN_PCT=${MARGEN_ESPACIO_PCT:-$MARGEN_PCT}
  kiwix_cache_clear
  log_info "Calculando el espacio necesario del perfil '$ARCA_PERFIL' (consulta tamaños reales al servidor, puede tardar unos minutos)..."
  local tabla; tabla=$(estimar_pendiente)
  local pendiente
  pendiente=$(awk -F'\t' '$4=="pendiente"{s+=$3} END{printf "%d", s}' <<< "$tabla")
  local necesario=$(( pendiente + pendiente * MARGEN_PCT / 100 ))
  local libre; libre=$(space_free_bytes "$RESPALDO")

  tabla_imprimir "$tabla"
  resumen_estimacion "$tabla" "$libre"

  grep -q 'NO EXISTE' <<< "$tabla" && log_warn "Hay entradas de packs.conf que no existen en el servidor (ver tabla); se omitirán."

  if (( necesario > libre )); then
    local deficit=$(( necesario - libre ))
    log_error "No cabe: faltan $(human "$deficit")."
    echo "Elige un perfil menor (--profile recovery / core), quita extras, o comenta en $PACKS_CONF alguna de estas líneas hasta liberar $(human "$deficit"):"
    awk -F'\t' '$1=="zim" && $4=="pendiente"{print $3"\t"$2}' <<< "$tabla" | sort -rn | head -8 \
      | while IFS=$'\t' read -r b n; do printf '   %-60s %s\n' "$n" "$(human "$b")"; done || true
    return 1
  fi
  log_ok "Espacio suficiente."
}

# ---------------------------------------------------------------- fase 1

fase_1() {
  log_titulo "Fase 1: estructura de carpetas"
  local d
  for d in zim manuales libros libros/propios mapas software personal referencia docs bootstrap recovery .arca .arca/tmp; do
    mkdir -p "$RESPALDO/$d"
  done
  mkdir -p "$ARCA_DIR/logs"
  # En ext4 el 5 % del disco queda reservado para root por defecto; en un disco de datos
  # de 1 TB son ~45 GB perdidos. Se baja al 1 %.
  local dev fs
  dev=$(findmnt -no SOURCE --target "$RESPALDO" 2>/dev/null || true)
  fs=$(findmnt -no FSTYPE --target "$RESPALDO" 2>/dev/null || true)
  if [[ $fs == ext4 && $dev == /dev/* ]] && command -v tune2fs > /dev/null; then
    local reservado
    reservado=$(tune2fs -l "$dev" 2>/dev/null | awk -F: '/Reserved block count/ {gsub(/ /,"",$2); print $2}')
    local total; total=$(tune2fs -l "$dev" 2>/dev/null | awk -F: '/^Block count/ {gsub(/ /,"",$2); print $2}')
    if [[ $reservado =~ ^[0-9]+$ && $total =~ ^[0-9]+$ ]] && (( reservado * 100 / total > 1 )); then
      if tune2fs -m 1 "$dev" > /dev/null 2>&1; then
        log_ok "Bloques reservados de ext4 en $dev bajados del $(( reservado * 100 / total )) % al 1 %."
      else
        log_warn "No se pudo ajustar tune2fs -m 1 en $dev; se continúa."
      fi
    fi
  fi
  if [[ ! -f "$RESPALDO/libros/propios/LEEME.txt" ]]; then
    cat > "$RESPALDO/libros/propios/LEEME.txt" <<'TXT'
Carpeta para tus propios libros (EPUB/PDF sin DRM).
Cópialos aquí y ábrelos con Calibre apuntando la biblioteca a /srv/respaldo/libros/
(Calibre > Cambiar biblioteca > /srv/respaldo/libros). backup.sh los incluye.
TXT
  fi
  chown_respaldo "$RESPALDO"
  log_ok "Carpetas creadas en $RESPALDO (propietario $USUARIO)."
}

# ---------------------------------------------------------------- fase 2

fase_2() {
  log_titulo "Fase 2: paquetes"
  export DEBIAN_FRONTEND=noninteractive
  log_info "apt-get update..."
  log_cmd apt-get update -qq || log_warn "apt-get update terminó con errores; se intenta instalar igual."
  local paquetes=(kiwix-tools zim-tools aria2 calibre keepassxc gocryptfs flatpak rsync jq curl wget
                  build-essential cmake git dpkg-dev python3 python3-pip python3-venv tmux par2 poppler-utils)
  log_info "apt-get install ${paquetes[*]} (puede tardar varios minutos)..."
  log_cmd apt-get install -y -qq -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold "${paquetes[@]}" \
    || die "Falló apt-get install. Revisa el log: $ARCA_LOG_FILE"
  log_ok "Paquetes apt instalados."

  if command -v flatpak > /dev/null; then
    log_info "Flatpak: org.kiwix.desktop y app.organicmaps.desktop..."
    log_cmd flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
    local app
    for app in org.kiwix.desktop app.organicmaps.desktop; do
      if log_cmd flatpak install -y --noninteractive flathub "$app"; then
        log_ok "Flatpak $app"
      else
        failed_add "flatpak:$app" "no se pudo instalar (¿sin entorno gráfico o sin flathub?)"
      fi
    done
  fi
}

# ---------------------------------------------------------------- fase 3

# Trabajo de descarga de un ZIM (se ejecuta en segundo plano). Escribe el resultado en $5.
_zim_job() {
  local carpeta=$1 prefijo=$2 nombre=$3 dir=$4 resultado=$5
  local bytes sha
  bytes=$(kiwix_size "$carpeta" "$nombre" || kiwix_listed_size "$carpeta" "$nombre" || echo 0)
  if ! space_check $(( bytes + bytes / 20 )) "$RESPALDO"; then
    # Opción ZIM_BORRAR_VIEJO_SI_NO_CABE (software.conf): si la versión nueva no cabe junto
    # a la vieja, borra la vieja primero. El ZIM queda ausente mientras dura la descarga.
    local viejo; viejo=$(zim_json_get "$prefijo" archivo || true)
    if [[ ${ZIM_BORRAR_VIEJO_SI_NO_CABE:-0} == 1 && -n $viejo && -s "$dir/$viejo" && $viejo != "$nombre" ]]; then
      log_warn "No cabe $nombre junto a $viejo; se borra la versión anterior antes de descargar (ZIM_BORRAR_VIEJO_SI_NO_CABE=1)."
      rm -f "$dir/$viejo"
      if ! space_check $(( bytes + bytes / 20 )) "$RESPALDO"; then
        echo "FAIL sin espacio para $nombre ($(human "$bytes")) ni tras borrar $viejo" > "$resultado"; return 0
      fi
    else
      echo "FAIL sin espacio para $nombre ($(human "$bytes"))" > "$resultado"; return 0
    fi
  fi
  log_info "Descargando $nombre ($(human "$bytes"))..."
  if sha=$(kiwix_download "$carpeta" "$nombre" "$dir"); then
    echo "OK $sha $(stat -c %s "$dir/$nombre")" > "$resultado"
  else
    echo "FAIL descarga o verificación fallida de $nombre" > "$resultado"
  fi
}

fase_3() {
  log_titulo "Fase 3: ZIM de Kiwix"
  mkdir -p "$ZIM_DIR" "$ARCA_TMP/zim"
  software_load
  zim_json_init
  kiwix_cache_clear
  local p pr cat carpeta prefijo nombre pendientes=() ya=0 fuera=0
  while IFS=$'\t' read -r p pr cat carpeta prefijo; do
    recurso_activo "$p" || { fuera=$((fuera + 1)); continue; }
    if ! nombre=$(kiwix_latest "$carpeta" "$prefijo"); then
      failed_add "zim:$carpeta/$prefijo" "no existe en download.kiwix.org/zim/$carpeta/"; continue
    fi
    if zim_installed_ok "$prefijo" "$nombre" "$ZIM_DIR"; then
      ya=$((ya + 1)); continue
    fi
    pendientes+=("$carpeta"$'\t'"$prefijo"$'\t'"$nombre")
  done < <(packs_read "$PACKS_CONF")
  log_info "Perfil $ARCA_PERFIL: $ya ZIM ya al día, ${#pendientes[@]} por descargar (máximo $MAX_DESCARGAS a la vez), $fuera fuera del perfil."

  local p res
  for p in "${pendientes[@]}"; do
    IFS=$'\t' read -r carpeta prefijo nombre <<< "$p"
    res="$ARCA_TMP/zim/$nombre.result"; rm -f "$res"
    while (( $(jobs -rp | wc -l) >= MAX_DESCARGAS )); do wait -n || true; done
    _zim_job "$carpeta" "$prefijo" "$nombre" "$ZIM_DIR" "$res" &
  done
  wait

  local estado sha bytes
  for p in "${pendientes[@]}"; do
    IFS=$'\t' read -r carpeta prefijo nombre <<< "$p"
    res="$ARCA_TMP/zim/$nombre.result"
    read -r estado sha bytes < "$res" 2>/dev/null || { estado=FAIL; sha="sin resultado"; }
    if [[ $estado == OK ]]; then
      kiwix_prune_old "$ZIM_DIR" "$prefijo" "$nombre"
      zim_json_set "$prefijo" "$nombre" "$sha" "$bytes"
      failed_del "zim:$carpeta/$prefijo"
      log_ok "$nombre verificado ($(human "$bytes"))."
    else
      failed_add "zim:$carpeta/$prefijo" "$(cut -d' ' -f2- "$res" 2>/dev/null || echo "$sha")"
      # Si la versión registrada ya no está en disco (borrada para hacer sitio), se quita del inventario.
      local reg; reg=$(zim_json_get "$prefijo" archivo || true)
      [[ -n $reg && ! -s "$ZIM_DIR/$reg" ]] && zim_json_del "$prefijo"
    fi
    rm -f "$res"
  done
  chown_respaldo "$ZIM_DIR" "$ZIM_JSON"
}

# ---------------------------------------------------------------- fase 4

fase_4() {
  log_titulo "Fase 4: manuales y recursos"
  json_init "$MANUALS_JSON"
  local p pr cat d u desc lic ruta clave bytes existe remoto
  while IFS=$'\t' read -r p pr cat d u desc lic; do
    recurso_activo "$p" || continue
    ruta="$RESPALDO/$d"; clave="manual:$d"
    migrar_ruta_antigua "$d"
    [[ $d == */ ]] && clave="manual:$d${u##*/}"
    if [[ $d == */ ]]; then
      existe=0; [[ -n $(find "$ruta" -type f -print -quit 2>/dev/null) ]] && existe=1
    else
      existe=0; [[ -s $ruta ]] && existe=1
    fi
    if (( existe )); then
      if [[ ${MODO_UPDATE:-0} == 1 && $d != */ ]]; then
        remoto=$(fetch_resource_size "$u" 2>/dev/null || echo "")
        if [[ -n $remoto && $remoto != "$(json_get "$MANUALS_JSON" "$u" bytes)" ]]; then
          log_info "Cambió de tamaño en el servidor: $d (se vuelve a descargar)."
          mv "$ruta" "$ruta.anterior"
        else
          continue
        fi
      else
        continue
      fi
    fi
    log_info "Descargando: $desc → $d"
    if bytes=$(fetch_resource "$u" "$ruta"); then
      rm -f "$ruta.anterior"
      json_set "$MANUALS_JSON" "$u" destino "$d" bytes "$bytes" fecha "$(date -Is)"
      failed_del "$clave"
      log_ok "$d ($(human "$bytes"))"
    else
      [[ -f $ruta.anterior ]] && mv "$ruta.anterior" "$ruta"
      failed_add "$clave" "no se pudo descargar $u"
    fi
  done < <(manuals_read)
  # Índices comentados (LEEME) por carpeta y tablas de referencia.
  leemes_instalar
  chown_respaldo "$RESPALDO/manuales" "$RESPALDO/libros" "$RESPALDO/referencia" "$MANUALS_JSON"
}

# ---------------------------------------------------------------- fase 5

mapas_countries_json() {
  local cache="$ARCA_TMP/countries.json"
  [[ -s $cache ]] || _curl -o "$cache" "https://raw.githubusercontent.com/organicmaps/organicmaps/master/data/countries.json" || return 1
  cat "$cache"
}

mapas_version() { mapas_countries_json | jq -r '.v'; }

# Regiones (hojas) de los países configurados: "id<TAB>bytes".
mapas_regiones() {
  local pais filtro=""
  for pais in ${MAPAS_PAISES:-}; do filtro+="${filtro:+ or }(.id == \"$pais\" or (.id | startswith(\"${pais}_\")))"; done
  [[ -n $filtro ]] || return 0
  mapas_countries_json | jq -r "[.. | objects | select(.id? and .s?) | select($filtro or .id == \"World\" or .id == \"WorldCoasts\")] | .[] | [.id, .s] | @tsv"
}

mapas_servidor() {
  local s
  s=$(_curl "https://meta.omaps.app/maps" 2>/dev/null | jq -r '.[0] // empty' 2>/dev/null || true)
  echo "${s:-https://cdn-us1.organicmaps.app/}"
}

fase_5() {
  log_titulo "Fase 5: mapas de Organic Maps"
  software_load
  if [[ ${MAPAS:-1} != 1 ]] || ! soft_activo mapas; then log_info "Mapas desactivados (software.conf o perfil)."; return 0; fi
  local dir="$RESPALDO/mapas" v servidor id s dest
  mkdir -p "$dir"
  v=$(mapas_version) || { failed_add "mapas" "no se pudo leer countries.json"; return 0; }
  servidor=$(mapas_servidor)
  log_info "Versión de mapas $v, servidor $servidor, países: $MAPAS_PAISES"
  while IFS=$'\t' read -r id s; do
    dest="$dir/$id.mwm"
    if [[ -s $dest && $(stat -c %s "$dest") == "$s" && $(cat "$dir/VERSION.txt" 2>/dev/null) == "$v" ]]; then continue; fi
    space_check $(( s + s / 20 )) "$RESPALDO" || { failed_add "mapa:$id" "sin espacio"; continue; }
    log_info "Descargando $id.mwm ($(human "$s"))..."
    rm -f "$dest.nuevo"
    if fetch_file "${servidor%/}/maps/$v/$id.mwm" "$dest.nuevo" && [[ $(stat -c %s "$dest.nuevo") == "$s" ]]; then
      mv "$dest.nuevo" "$dest"; failed_del "mapa:$id"
    else
      rm -f "$dest.nuevo"; failed_add "mapa:$id" "descarga incompleta desde $servidor"
    fi
  done < <(mapas_regiones)
  echo "$v" > "$dir/VERSION.txt"
  cat > "$dir/LEEME.txt" <<TXT
Mapas de Organic Maps (versión $v) para: $MAPAS_PAISES
Para usarlos en el teléfono: instala Organic Maps (APK en software/organicmaps/) y copia
los .mwm a Android/data/app.organicmaps/files/ (o la carpeta que indique la app en Ajustes >
Carpeta de mapas). En Linux: Flatpak app.organicmaps.desktop, carpeta ~/.var/app/app.organicmaps.desktop/data/.
También puedes bajarlos desde la app (Descargar mapas) si tienes internet.
TXT
  chown_respaldo "$dir"
  log_ok "Mapas listos en $dir."
}

# ---------------------------------------------------------------- fase 6

iso_ultima_linea() {
  _curl "$UBUNTU_ISO_URL_BASE/SHA256SUMS" 2>/dev/null | grep "$UBUNTU_ISO_PATRON" | sort -k2 -V | tail -1
}

# Info de un modelo en Hugging Face: "bytes<TAB>sha256". Argumentos: repo archivo.
hf_modelo_info() {
  local repo=${1:-$LLM_MODEL_REPO} archivo=${2:-$LLM_MODEL_FILE}
  _curl "https://huggingface.co/api/models/$repo/tree/main" \
    | jq -r --arg f "$archivo" '.[] | select(.path==$f) | [.size, (.lfs.oid // "")] | @tsv'
}

# Descarga y verifica un GGUF de Hugging Face en $3. Argumentos: repo archivo dir.
_soft_llm_modelo() {
  local repo=$1 archivo=$2 dir=$3 info bytes sha modelo="$3/$2"
  [[ -s $modelo ]] && return 0
  info=$(hf_modelo_info "$repo" "$archivo") || true
  IFS=$'\t' read -r bytes sha <<< "$info"
  [[ $bytes =~ ^[0-9]+$ ]] || { failed_add "software:modelo:$archivo" "no se encontró en $repo"; return 0; }
  space_check $(( bytes + bytes / 20 )) "$RESPALDO" || { failed_add "software:modelo:$archivo" "sin espacio"; return 0; }
  log_info "Modelo $archivo ($(human "$bytes")) desde Hugging Face..."
  if fetch_file "https://huggingface.co/$repo/resolve/main/$archivo" "$modelo" \
     && { [[ -z $sha ]] || fetch_verify_sha256 "$modelo" "$sha"; }; then
    json_set "$SOFTWARE_JSON" "modelo:$archivo" archivo "$archivo" repo "$repo" sha256 "${sha:-sin hash}" fecha "$(date -Is)"
    failed_del "software:modelo:$archivo"
  else
    rm -f "$modelo"; failed_add "software:modelo:$archivo" "descarga o sha256 fallido"
  fi
}

_soft_deb() {
  local dir="$RESPALDO/software/deb"
  mkdir -p "$dir"
  log_info "Descargando .deb con dependencias: $DEB_PAQUETES"
  local lista
  # shellcheck disable=SC2086
  lista=$(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks \
            --no-replaces --no-enhances -i $DEB_PAQUETES 2>/dev/null | grep -E '^[a-z0-9]' | sort -u)
  local n=0 p
  for p in $lista; do
    if (cd "$dir" && apt-get download "$p" > /dev/null 2>&1); then n=$((n + 1)); else log_debug "sin .deb para $p"; fi
  done
  (cd "$dir" && dpkg-scanpackages --multiversion . /dev/null 2>/dev/null | gzip -9 > Packages.gz) || true
  cat > "$dir/LEEME.txt" <<'TXT'
Paquetes .deb (con dependencias) para instalar Kiwix y utilidades sin internet en Ubuntu 24.04:
  sudo dpkg -i *.deb  ||  sudo apt-get -f install
O como repositorio local:
  echo "deb [trusted=yes] file:/srv/respaldo/software/deb ./" | sudo tee /etc/apt/sources.list.d/arca.list
  sudo apt-get update && sudo apt-get install kiwix-tools aria2 calibre keepassxc gocryptfs rsync
TXT
  log_ok "$n paquetes .deb en $dir ($(human "$(space_used_bytes "$dir")"))."
}

_soft_kiwix() {
  local dir="$RESPALDO/software/kiwix" listado nombre
  mkdir -p "$dir"
  if [[ ${KIWIX_DESKTOP:-1} == 1 ]]; then
    listado=$(_curl "https://download.kiwix.org/release/kiwix-desktop/") || true
    nombre=$(grep -oE 'href="kiwix-desktop_x86_64_[0-9.]+\.appimage"' <<< "$listado" | sed 's/href="//;s/"//' | sort -V | tail -1)
    if [[ -n $nombre ]]; then
      if [[ ! -s "$dir/$nombre" ]]; then
        log_info "Kiwix Desktop AppImage: $nombre"
        if fetch_file "https://download.kiwix.org/release/kiwix-desktop/$nombre" "$dir/$nombre" \
           && [[ $(_curl "https://download.kiwix.org/release/kiwix-desktop/$nombre.md5" | awk '{print $1}') == "$(md5sum "$dir/$nombre" | awk '{print $1}')" ]]; then
          chmod +x "$dir/$nombre"; find "$dir" -name 'kiwix-desktop_*.appimage' ! -name "$nombre" -delete
          json_set "$SOFTWARE_JSON" kiwix_desktop archivo "$nombre" fecha "$(date -Is)"; failed_del "software:kiwix-desktop"
        else
          rm -f "$dir/$nombre"; failed_add "software:kiwix-desktop" "descarga o md5 fallido"
        fi
      fi
    else
      failed_add "software:kiwix-desktop" "no se encontró AppImage en el listado"
    fi
  fi
  if [[ ${KIWIX_TOOLS_BIN:-1} == 1 ]]; then
    listado=$(_curl "https://download.kiwix.org/release/kiwix-tools/") || true
    nombre=$(grep -oE 'href="kiwix-tools_linux-x86_64-musl-[0-9.]+\.tar\.gz"' <<< "$listado" | sed 's/href="//;s/"//' | sort -V | tail -1)
    if [[ -n $nombre && ! -s "$dir/$nombre" ]]; then
      log_info "kiwix-tools binario: $nombre"
      if fetch_file "https://download.kiwix.org/release/kiwix-tools/$nombre" "$dir/$nombre"; then
        find "$dir" -name 'kiwix-tools_linux-*.tar.gz' ! -name "$nombre" -delete
        json_set "$SOFTWARE_JSON" kiwix_tools archivo "$nombre" fecha "$(date -Is)"; failed_del "software:kiwix-tools"
      else failed_add "software:kiwix-tools" "descarga fallida"; fi
    fi
  fi
  if [[ ${KIWIX_ANDROID:-1} == 1 ]]; then
    local info tag url
    info=$(fetch_github_asset kiwix/kiwix-android "${KIWIX_ANDROID_ABI:-arm64-v8a}-standalone\\.apk$") || true
    IFS=$'\t' read -r tag nombre _ url <<< "$info"
    if [[ -n $nombre ]]; then
      if [[ ! -s "$dir/$nombre" ]]; then
        log_info "Kiwix Android $tag: $nombre"
        if fetch_file "$url" "$dir/$nombre"; then
          find "$dir" -name '*-standalone.apk' ! -name "$nombre" -delete
          json_set "$SOFTWARE_JSON" kiwix_android version "$tag" archivo "$nombre" fecha "$(date -Is)"; failed_del "software:kiwix-android"
        else failed_add "software:kiwix-android" "descarga fallida"; fi
      fi
    else failed_add "software:kiwix-android" "no se encontró APK en GitHub"; fi
  fi
}

_soft_organicmaps() {
  [[ ${ORGANICMAPS_APK:-1} == 1 ]] && soft_activo organicmaps || return 0
  local dir="$RESPALDO/software/organicmaps" info tag nombre url
  mkdir -p "$dir"
  info=$(fetch_github_asset organicmaps/organicmaps 'web-release\.apk$') || true
  IFS=$'\t' read -r tag nombre _ url <<< "$info"
  [[ -n $nombre ]] || { failed_add "software:organicmaps" "no se encontró APK en GitHub"; return 0; }
  [[ -s "$dir/$nombre" ]] && return 0
  log_info "Organic Maps $tag: $nombre"
  if fetch_file "$url" "$dir/$nombre" && fetch_verify_sha256 "$dir/$nombre" "$(_curl "$url.sha256sum" | awk '{print $1}')"; then
    find "$dir" -name 'OrganicMaps-*.apk' ! -name "$nombre" -delete
    json_set "$SOFTWARE_JSON" organicmaps version "$tag" archivo "$nombre" fecha "$(date -Is)"; failed_del "software:organicmaps"
  else
    rm -f "$dir/$nombre"; failed_add "software:organicmaps" "descarga o sha256 fallido"
  fi
}

_soft_iso() {
  [[ ${UBUNTU_ISO:-1} == 1 ]] && soft_activo iso || return 0
  local dir="$RESPALDO/software/iso" linea sha nombre bytes
  mkdir -p "$dir"
  linea=$(iso_ultima_linea)
  [[ -n $linea ]] || { failed_add "software:ubuntu-iso" "no se pudo leer SHA256SUMS"; return 0; }
  sha=${linea%% *}; nombre=$(awk '{print $2}' <<< "$linea" | tr -d '*')
  [[ -s "$dir/$nombre" ]] && return 0
  bytes=$(fetch_size "$UBUNTU_ISO_URL_BASE/$nombre" || echo 6500000000)
  space_check $(( bytes + bytes / 20 )) "$RESPALDO" || { failed_add "software:ubuntu-iso" "sin espacio"; return 0; }
  log_info "ISO Ubuntu: $nombre ($(human "$bytes"))"
  if fetch_file "$UBUNTU_ISO_URL_BASE/$nombre" "$dir/$nombre" && fetch_verify_sha256 "$dir/$nombre" "$sha"; then
    find "$dir" -name 'ubuntu-*.iso' ! -name "$nombre" -delete
    echo "$linea" > "$dir/SHA256SUMS"
    json_set "$SOFTWARE_JSON" ubuntu_iso archivo "$nombre" sha256 "$sha" fecha "$(date -Is)"; failed_del "software:ubuntu-iso"
  else
    rm -f "$dir/$nombre"; failed_add "software:ubuntu-iso" "descarga o sha256 fallido"
  fi
}

_soft_llm() {
  if [[ ${LLM_ENABLED:-1} != 1 ]] || ! soft_activo llm; then log_info "LLM desactivado (software.conf o perfil)."; return 0; fi
  local dir="$RESPALDO/software/llm" src ref
  mkdir -p "$dir/modelos"
  src="$dir/llama.cpp"
  ref=${LLAMACPP_REF:-$(fetch_github_tag ggml-org/llama.cpp)}
  [[ -n $ref && $ref != null ]] || ref="master"
  if [[ ! -x "$src/build/bin/llama-cli" || $(json_get "$SOFTWARE_JSON" llamacpp version) != "$ref" ]]; then
    log_info "llama.cpp $ref: clonando y compilando para CPU (tarda 10-30 min)..."
    rm -rf "$src"
    if log_cmd git clone --depth 1 --branch "$ref" "$LLAMACPP_REPO" "$src" \
       && log_cmd cmake -S "$src" -B "$src/build" -DCMAKE_BUILD_TYPE=Release -DLLAMA_CURL=OFF \
       && log_cmd cmake --build "$src/build" --config Release -j "$(nproc)" --target llama-cli llama-server; then
      json_set "$SOFTWARE_JSON" llamacpp version "$ref" fecha "$(date -Is)"; failed_del "software:llama.cpp"
      log_ok "llama.cpp compilado en $src/build/bin/"
    else
      failed_add "software:llama.cpp" "clonado o compilación fallida (ver log)"
    fi
  fi
  soft_activo llm7b && _soft_llm_modelo "$LLM_MODEL_REPO" "$LLM_MODEL_FILE" "$dir/modelos"
  [[ -n ${LLM_RAPIDO_FILE:-} ]] && _soft_llm_modelo "${LLM_RAPIDO_REPO:-$LLM_MODEL_REPO}" "$LLM_RAPIDO_FILE" "$dir/modelos"
  cat > "$dir/chat.sh" <<CHAT
#!/usr/bin/env bash
# Chat local con el modelo (CPU).
# Uso: ./chat.sh [--rapido]            chat en la terminal (--rapido usa el modelo de 3B)
#      ./chat.sh [--rapido] --server   API y web en http://IP:8081
set -euo pipefail
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
MODELO="\$DIR/modelos/$LLM_MODEL_FILE"
[[ -s "\$MODELO" ]] || MODELO="\$DIR/modelos/${LLM_RAPIDO_FILE:-$LLM_MODEL_FILE}"
if [[ "\${1:-}" == "--rapido" ]]; then MODELO="\$DIR/modelos/${LLM_RAPIDO_FILE:-$LLM_MODEL_FILE}"; shift; fi
[[ -s "\$MODELO" ]] || { echo "No está el modelo: \$MODELO"; exit 1; }
HILOS="\$(nproc)"
if [[ "\${1:-}" == "--server" ]]; then
  exec "\$DIR/llama.cpp/build/bin/llama-server" -m "\$MODELO" -c ${LLM_CONTEXTO:-4096} -t "\$HILOS" --host 0.0.0.0 --port 8081
fi
exec "\$DIR/llama.cpp/build/bin/llama-cli" -m "\$MODELO" -c ${LLM_CONTEXTO:-4096} -t "\$HILOS" -cnv --color -p "Eres un asistente útil. Responde en el idioma del usuario."
CHAT
  chmod +x "$dir/chat.sh"
  if [[ ${LLM_PREGUNTAR:-1} == 1 ]]; then
    cp "$ARCA_DIR/llm/preguntar.py" "$dir/preguntar.py"
    cat > "$dir/preguntar.sh" <<PREG
#!/usr/bin/env bash
# Chat con la biblioteca: busca en Kiwix (puerto $PUERTO) y responde con el modelo local.
# Uso: ./preguntar.sh [--rapido]                   interactivo (--rapido usa el modelo de 3B)
#      ./preguntar.sh [--rapido] "¿cómo se hace jabón?"
set -euo pipefail
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
MODELO="\$DIR/modelos/$LLM_MODEL_FILE"
[[ -s "\$MODELO" ]] || MODELO="\$DIR/modelos/${LLM_RAPIDO_FILE:-$LLM_MODEL_FILE}"
if [[ "\${1:-}" == "--rapido" ]]; then MODELO="\$DIR/modelos/${LLM_RAPIDO_FILE:-$LLM_MODEL_FILE}"; shift; fi
export ARCA_KIWIX_URL="\${ARCA_KIWIX_URL:-http://localhost:$PUERTO}"
export ARCA_LLAMA_URL="\${ARCA_LLAMA_URL:-http://localhost:8081}"
export ARCA_MODELO="\$MODELO"
export ARCA_LLAMA_BIN="\$DIR/llama.cpp/build/bin/llama-server"
export ARCA_CONTEXTO="\${ARCA_CONTEXTO:-${LLM_CONTEXTO:-4096}}"
export ARCA_RESPALDO="$RESPALDO"
export ARCA_SEARCH_DB="\${ARCA_SEARCH_DB:-$ARCA_STATE_DIR/search.db}"
exec python3 "\$DIR/preguntar.py" "\$@"
PREG
    chmod +x "$dir/preguntar.sh"
  fi
}

# Cómo crear una IA desde cero: guía, código de referencia y ruedas de Python.
_soft_ia() {
  [[ ${IA_ENABLED:-1} == 1 ]] && soft_activo ia || return 0
  local dir="$RESPALDO/software/ia" repo nombre
  mkdir -p "$dir/codigo" "$dir/wheels"
  cp "$ARCA_DIR/docs/ia-desde-cero.md" "$dir/LEEME.md"
  for repo in ${IA_REPOS:-}; do
    nombre=${repo#*/}
    if [[ -d "$dir/codigo/$nombre/.git" ]]; then
      log_cmd git -C "$dir/codigo/$nombre" pull -q --ff-only || log_warn "No se pudo actualizar $repo"
    else
      log_info "Clonando $repo..."
      if log_cmd git clone -q "https://github.com/$repo.git" "$dir/codigo/$nombre"; then
        failed_del "software:ia:$repo"
      else
        rm -rf "$dir/codigo/$nombre"; failed_add "software:ia:$repo" "clonado fallido"
      fi
    fi
  done
  if [[ -n ${IA_WHEELS:-} ]] && command -v pip3 > /dev/null; then
    if [[ -z $(find "$dir/wheels" -name 'torch-*.whl' -print -quit 2>/dev/null) ]]; then
      log_info "Descargando ruedas de Python (CPU, x86_64): $IA_WHEELS"
      # shellcheck disable=SC2086
      if log_cmd pip3 download $IA_WHEELS --dest "$dir/wheels" --index-url https://download.pytorch.org/whl/cpu \
           --extra-index-url https://pypi.org/simple --platform manylinux_2_28_x86_64 --platform manylinux2014_x86_64 \
           --python-version 3.12 --only-binary=:all:; then
        failed_del "software:ia:wheels"
      else
        failed_add "software:ia:wheels" "pip download fallido"
      fi
    fi
    cat > "$dir/wheels/LEEME.txt" <<'TXT'
Ruedas de Python (CPU, x86_64, Python 3.12) para instalar sin internet en Ubuntu 24.04:
  python3 -m venv ~/ia && source ~/ia/bin/activate
  pip install --no-index --find-links /srv/respaldo/software/ia/wheels torch numpy tiktoken
TXT
  fi
  cat > "$dir/LEEME-codigo.txt" <<'TXT'
Código de referencia (clones completos con historial):
  micrograd         motor de gradientes en 100 líneas (Karpathy)
  minbpe            tokenizador BPE (Karpathy)
  nanoGPT           GPT-2 en ~300 líneas de PyTorch (Karpathy)
  llm.c             entrenar GPT-2 en C puro, CPU o GPU (Karpathy)
  LLMs-from-scratch código del libro "Build a Large Language Model (From Scratch)" (Raschka)
  ggml              librería numérica de llama.cpp
Empieza por LEEME.md.
TXT
}

_soft_mirror_repo() {
  [[ ${REPO_MIRROR:-1} == 1 ]] && soft_activo repo || return 0
  local dest="$RESPALDO/software/arca.git"
  if ! git -C "$ARCA_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    log_warn "$ARCA_DIR no es un repositorio git; no se crea la copia software/arca.git."
    return 0
  fi
  if [[ -d $dest ]]; then
    log_cmd git -C "$dest" fetch -q --all --prune || true
    failed_del "software:arca.git"
  elif log_cmd git clone -q --mirror "$ARCA_DIR" "$dest"; then
    failed_del "software:arca.git"
  else
    failed_add "software:arca.git" "clonado fallido"
  fi
}

fase_6() {
  log_titulo "Fase 6: software de rescate"
  software_load
  json_init "$SOFTWARE_JSON"
  mkdir -p "$RESPALDO/software"
  _soft_deb
  _soft_kiwix
  _soft_organicmaps
  _soft_iso
  _soft_llm
  _soft_ia
  _soft_mirror_repo
  chown_respaldo "$RESPALDO/software" "$SOFTWARE_JSON"
  log_ok "Software de rescate en $RESPALDO/software."
}

# ---------------------------------------------------------------- fase 7

fase_7() {
  log_titulo "Fase 7: biblioteca y servicio kiwix"
  local lib="$RESPALDO/library.xml" z n=0
  rm -f "$lib"
  for z in "$ZIM_DIR"/*.zim; do
    [[ -f $z && ! -f $z.aria2 ]] || continue
    if log_cmd kiwix-manage "$lib" add "$z"; then n=$((n + 1)); else log_warn "kiwix-manage rechazó $z"; fi
  done
  chown_respaldo "$lib"
  log_ok "library.xml regenerada con $n ZIM."

  if ! systemd_ok; then
    log_warn "systemd no está disponible (¿contenedor?). No se instala kiwix.service; lanza a mano: kiwix-serve --library $lib --port $PUERTO --address 0.0.0.0"
    return 0
  fi
  sed "s/__USUARIO__/$USUARIO/g" "$ARCA_DIR/systemd/kiwix.service" > /etc/systemd/system/kiwix.service
  systemctl daemon-reload
  systemctl enable -q kiwix.service
  systemctl restart kiwix.service
  sleep 3
  if curl -sf --max-time 10 "http://localhost:$PUERTO/" > /dev/null; then
    log_ok "kiwix-serve responde en http://$(ip_local):$PUERTO"
  else
    log_error "kiwix-serve no responde en el puerto $PUERTO. Revisa: journalctl -u kiwix"
    return 1
  fi
}

# ---------------------------------------------------------------- fase 8

fase_8() {
  log_titulo "Fase 8: configuración del sistema"
  if ! systemd_ok; then log_warn "Sin systemd: se omite la configuración de energía y motd."; return 0; fi
  systemctl mask -q sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null || true
  log_ok "Suspensión e hibernación desactivadas."
  if ls /sys/class/power_supply/BAT* > /dev/null 2>&1 || [[ -d /proc/acpi/button/lid ]]; then
    mkdir -p /etc/systemd/logind.conf.d
    printf '[Login]\nHandleLidSwitch=ignore\nHandleLidSwitchExternalPower=ignore\nHandleLidSwitchDocked=ignore\n' \
      > /etc/systemd/logind.conf.d/arca.conf
    systemctl restart systemd-logind 2>/dev/null || true
    log_ok "Laptop detectada: cerrar la tapa no suspende."
  fi
  cp "$ARCA_DIR/systemd/arca-motd.service" /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable -q arca-motd.service
  "$ARCA_DIR/lib/motd.sh" || true
  # Sin "| grep -q": ufw seguiría escribiendo tras cerrarse la tubería y el if fallaría en silencio.
  if command -v ufw > /dev/null && [[ $(ufw status 2>/dev/null || true) == *"Status: active"* ]]; then
    ufw allow "$PUERTO/tcp" > /dev/null && log_ok "Puerto $PUERTO abierto en ufw."
  fi
}

# ---------------------------------------------------------------- fase 9

fase_9() {
  log_titulo "Fase 9: timer de actualización mensual"
  if ! systemd_ok; then log_warn "Sin systemd: se omite el timer."; return 0; fi
  cp "$ARCA_DIR/systemd/arca-update.service" "$ARCA_DIR/systemd/arca-update.timer" /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable -q --now arca-update.timer
  log_ok "arca-update.timer activo (mensual, Persistent=true). Desactivar: sudo systemctl disable --now arca-update.timer"
}

# ---------------------------------------------------------------- fase 10

fase_10() {
  log_titulo "Fase 10: documentación, manifiesto, bootstrap y paridad"
  readme_generar
  docs_generar
  # El chat con la biblioteca se actualiza con el repo aunque la fase 6 no vuelva a correr.
  [[ -f "$RESPALDO/software/llm/preguntar.py" ]] && cp "$ARCA_DIR/llm/preguntar.py" "$RESPALDO/software/llm/preguntar.py"
  log_ok "README.txt, START_HERE (ES/EN/HTML) y docs/ generados."
  log_info "Actualizando el manifiesto (hashea solo archivos nuevos o cambiados; puede tardar unos minutos)..."
  manifest_rebuild
  leemes_instalar
  sources_licenses_generar
  manifest_add docs/SOURCES_AND_LICENSES.md "ARCA (generado)" "$(date +%Y-%m-%d)" es MIT P0 documentacion core 2>/dev/null || true
  manifest_generate
  log_ok "MANIFEST.tsv: $(awk 'END{print NR-1}' "$MANIFEST_OUT") entradas."
  bootstrap_generar
  log_ok "bootstrap/ regenerado ($(human "$(space_used_bytes "$RESPALDO/bootstrap")"))."
  if command -v pdftotext > /dev/null; then
    log_info "Indexando PDF y documentos para la búsqueda local (arca-search)..."
    if python3 "$ARCA_DIR/lib/arca_index.py" build --root "$RESPALDO" --db "$ARCA_STATE_DIR/search.db" 2>> "$ARCA_LOG_FILE"; then
      log_ok "Índice de búsqueda: $(python3 "$ARCA_DIR/lib/arca_index.py" stats --db "$ARCA_STATE_DIR/search.db" | head -1)"
    else
      log_warn "El índice de búsqueda terminó con errores (ver log)."
    fi
  else
    log_warn "pdftotext no está instalado; sin índice de búsqueda local (sudo apt install poppler-utils)."
  fi
  ln -sf "$ARCA_DIR/bin/arca-search" /usr/local/bin/arca-search 2>/dev/null || true
  ln -sf "$ARCA_DIR/bin/arca-index" /usr/local/bin/arca-index 2>/dev/null || true
  if command -v par2 > /dev/null; then
    "$ARCA_DIR/repair.sh" --create || log_warn "La paridad PAR2 terminó con avisos (ver log)."
  else
    log_warn "par2 no está instalado; sin paridad PAR2 (sudo apt install par2)."
  fi
  date -Is > "$ARCA_STATE_DIR/ultima-actualizacion"
  chown_respaldo "$RESPALDO/README.txt" "$ARCA_STATE_DIR" "$RESPALDO/recovery"
  systemd_ok && "$ARCA_DIR/lib/motd.sh" 2>/dev/null || true
}

# ---------------------------------------------------------------- fase 11

fase_11() {
  log_titulo "Fase 11: resumen"
  local ip; ip=$(ip_local)
  echo "  Acceso:        http://${ip:-IP-DEL-PC}:$PUERTO"
  echo "  Disco:         $(df -h --output=used,avail "$RESPALDO" | tail -1 | awk '{printf "usado %s, libre %s", $1, $2}')"
  echo "  ZIM:           $(find "$ZIM_DIR" -maxdepth 1 -name '*.zim' 2>/dev/null | wc -l) archivos"
  if [[ -s $FAILED_TXT ]]; then
    echo "  Errores pendientes ($FAILED_TXT):"
    sed 's/^/     - /' "$FAILED_TXT"
    echo "  Se reintentan con: sudo $ARCA_DIR/update.sh"
  else
    echo "  Errores:       ninguno"
  fi
  echo "  Log completo:  $ARCA_LOG_FILE"
  echo
  echo "  Recuerda hacer una copia al disco externo: sudo $ARCA_DIR/backup.sh /media/$USUARIO/DISCO"
}


# ---------------------------------------------------------------- poda de recursos fuera del perfil

# Lista lo instalado que no pertenece al perfil ni a los extras activos: "tipo<TAB>ruta<TAB>bytes<TAB>motivo".
listar_fuera_de_perfil() {
  local p pr cat carpeta prefijo archivo d u desc lic f
  # ZIM registrados en zim.json
  if [[ -s $ZIM_JSON ]]; then
    while IFS=$'\t' read -r prefijo archivo; do
      [[ -s "$ZIM_DIR/$archivo" ]] || continue
      local linea; linea=$(packs_read "$PACKS_CONF" | awk -F'\t' -v x="$prefijo" '$5==x {print; exit}')
      if [[ -z $linea ]]; then
        printf 'zim\tzim/%s\t%s\tya no está en packs.conf\n' "$archivo" "$(stat -c %s "$ZIM_DIR/$archivo")"
      else
        p=${linea%%$'\t'*}
        recurso_activo "$p" || printf 'zim\tzim/%s\t%s\tperfil %s\n' "$archivo" "$(stat -c %s "$ZIM_DIR/$archivo")" "$p"
      fi
    done < <(jq -r 'to_entries[] | "\(.key)\t\(.value.archivo)"' "$ZIM_JSON")
  fi
  # ZIM en disco sin registro
  for f in "$ZIM_DIR"/*.zim; do
    [[ -f $f ]] || continue
    jq -e --arg a "$(basename "$f")" 'to_entries[] | select(.value.archivo==$a)' "$ZIM_JSON" > /dev/null 2>&1 \
      || printf 'zim\tzim/%s\t%s\tsin registro en zim.json\n' "$(basename "$f")" "$(stat -c %s "$f")"
  done
  # Manuales y libros
  while IFS=$'\t' read -r p pr cat d u desc lic; do
    recurso_activo "$p" && continue
    if [[ $d == */ ]]; then
      [[ -n $(find "$RESPALDO/$d" -type f -print -quit 2>/dev/null) ]] && printf 'manual\t%s\t%s\tperfil %s\n' "$d" "$(space_used_bytes "$RESPALDO/$d")" "$p"
    else
      [[ -s "$RESPALDO/$d" ]] && printf 'manual\t%s\t%s\tperfil %s\n' "$d" "$(stat -c %s "$RESPALDO/$d")" "$p"
    fi
  done < <(manuals_read)
  # Software por perfil
  software_load
  soft_activo iso || for f in "$RESPALDO"/software/iso/*.iso; do [[ -f $f ]] && printf 'software\tsoftware/iso/%s\t%s\tperfil recovery\n' "$(basename "$f")" "$(stat -c %s "$f")"; done
  soft_activo llm7b || { f="$RESPALDO/software/llm/modelos/$LLM_MODEL_FILE"; [[ -f $f ]] && printf 'software\tsoftware/llm/modelos/%s\t%s\tperfil recovery\n' "$LLM_MODEL_FILE" "$(stat -c %s "$f")"; }
  return 0
}

# Borra lo listado por listar_fuera_de_perfil (tras confirmación, salvo --yes). Devuelve 0.
podar_fuera_de_perfil() {
  local si=${1:-0} lista total=0 t ruta bytes motivo
  lista=$(listar_fuera_de_perfil)
  if [[ -z $lista ]]; then log_ok "No hay recursos instalados fuera del perfil $ARCA_PERFIL."; return 0; fi
  echo "Recursos instalados que NO pertenecen al perfil $ARCA_PERFIL${ARCA_EXTRAS:+ ni a los extras ($ARCA_EXTRAS)}:"
  while IFS=$'\t' read -r t ruta bytes motivo; do
    printf '  %-8s %-70s %10s  %s\n' "$t" "${ruta:0:70}" "$(human "$bytes")" "$motivo"
    total=$((total + bytes))
  done <<< "$lista"
  echo "Se recuperarían $(human "$total")."
  if (( ! si )); then
    read -rp "¿Borrar estos $(grep -c . <<< "$lista") recursos? [s/N] " r
    [[ $r =~ ^[sS]$ ]] || { echo "No se borra nada."; return 0; }
  fi
  local hubo_zim=0
  while IFS=$'\t' read -r t ruta bytes motivo; do
    rm -rf "${RESPALDO:?}/$ruta"
    manifest_del "$ruta"
    if [[ $t == zim ]]; then
      hubo_zim=1
      local pref; pref=$(jq -r --arg a "$(basename "$ruta")" 'first(to_entries[] | select(.value.archivo==$a) | .key) // empty' "$ZIM_JSON" 2>/dev/null || true)
      [[ -n $pref ]] && zim_json_del "$pref"
    fi
    log_info "Borrado: $ruta ($(human "$bytes"))"
  done <<< "$lista"
  (( hubo_zim )) && fase_7
  log_ok "Poda completa: $(human "$total") liberados."
}
