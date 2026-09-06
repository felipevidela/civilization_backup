# shellcheck shell=bash
# lib/manifest.sh — manifiesto universal de ARCA.
#
# Registro incremental: $ARCA_STATE_DIR/manifest.tsv (una fila por archivo o carpeta, con
# columna extra "mtime" para no recalcular hashes). Salida abierta y regenerable:
# $RESPALDO/MANIFEST.tsv con las columnas
#   path size sha256 source version date language license priority category profile status
# Valores desconocidos se escriben como "unknown". status: ok | missing | size-mismatch | unregistered.
# Los ZIM traen sha256 de Kiwix; el resto de archivos se hashea al registrarlos (hasta
# MANIFEST_MAX_HASH_BYTES, por defecto 8 GB); carpetas y archivos mayores quedan "unknown".

MANIFEST_REG="${MANIFEST_REG:-${ARCA_STATE_DIR:-/srv/respaldo/.arca}/manifest.tsv}"
MANIFEST_OUT="${MANIFEST_OUT:-${RESPALDO:-/srv/respaldo}/MANIFEST.tsv}"
MANIFEST_MAX_HASH_BYTES="${MANIFEST_MAX_HASH_BYTES:-8589934592}"
MANIFEST_COLS="path	size	sha256	source	version	date	language	license	priority	category	profile	status"

manifest_init() {
  [[ -s $MANIFEST_REG ]] || { mkdir -p "$(dirname "$MANIFEST_REG")"; printf '%s\tmtime\n' "$MANIFEST_COLS" > "$MANIFEST_REG"; }
}

# Sanea un campo: sin tabuladores ni saltos; vacío → unknown.
_mf_campo() {
  local v=${1:-}
  v=${v//$'\t'/ }; v=${v//$'\n'/ }
  [[ -n $v ]] && printf '%s' "$v" || printf 'unknown'
}

# Registra (o actualiza) un archivo o carpeta.
# Uso: manifest_add ruta_relativa source version language license priority category profile [sha256]
# Si sha256 se omite y es un archivo ≤ MANIFEST_MAX_HASH_BYTES, se calcula; si el registro ya
# tiene el mismo tamaño y mtime, se conserva el hash anterior sin recalcular.
manifest_add() {
  local rel=$1 source=$2 version=$3 lang=$4 lic=$5 prio=$6 cat=$7 perfil=$8 sha=${9:-}
  local abs="$RESPALDO/$rel" size mtime prev
  manifest_init
  [[ -e $abs ]] || return 1
  if [[ -d $abs ]]; then
    size=$(space_used_bytes "$abs"); mtime=0; sha=${sha:-unknown}
  else
    size=$(stat -c %s "$abs"); mtime=$(stat -c %Y "$abs")
    if [[ -z $sha ]]; then
      prev=$(awk -F'\t' -v p="$rel" -v s="$size" -v m="$mtime" '$1==p && $2==s && $13==m {print $3}' "$MANIFEST_REG" | head -1)
      if [[ -n $prev && $prev != unknown ]]; then
        sha=$prev
      elif (( size <= MANIFEST_MAX_HASH_BYTES )); then
        sha=$(sha256sum "$abs" | awk '{print $1}')
      else
        sha=unknown
      fi
    fi
  fi
  local fila
  fila=$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    "$rel" "$size" "$(_mf_campo "$sha")" "$(_mf_campo "$source")" "$(_mf_campo "$version")" "$(date +%Y-%m-%d)" \
    "$(_mf_campo "$lang")" "$(_mf_campo "$lic")" "$(_mf_campo "$prio")" "$(_mf_campo "$cat")" "$(_mf_campo "$perfil")" "ok" "$mtime")
  { head -1 "$MANIFEST_REG"; awk -F'\t' -v p="$rel" 'NR>1 && $1!=p' "$MANIFEST_REG"; printf '%s\n' "$fila"; } > "$MANIFEST_REG.tmp"
  mv "$MANIFEST_REG.tmp" "$MANIFEST_REG"
}

# Registra todos los archivos de una carpeta (uno por uno, con hash).
manifest_add_dir() {
  local rel=$1; shift
  local f
  while IFS= read -r -d '' f; do
    manifest_add "${f#"$RESPALDO"/}" "$@"
  done < <(find "$RESPALDO/$rel" -type f ! -name '*.part' ! -name '*.aria2' -print0 2>/dev/null)
}

manifest_del() {
  [[ -s $MANIFEST_REG ]] || return 0
  { head -1 "$MANIFEST_REG"; awk -F'\t' -v p="$1" 'NR>1 && $1!=p' "$MANIFEST_REG"; } > "$MANIFEST_REG.tmp"
  mv "$MANIFEST_REG.tmp" "$MANIFEST_REG"
}

# Idioma a partir del nombre (ZIM: _en_/_es_/_mul_; manuales: sufijo -es / -en / palabras clave).
manifest_idioma() {
  local n=$1
  case $n in
    *_es_*|*-es.pdf|*_es.pdf|*"español"*|*openstax-es*|*autores-espanoles*) echo es ;;
    *_en_*|*-en.pdf|*_en.pdf|*openstax-en*) echo en ;;
    *_mul_*) echo mul ;;
    *_fr_*) echo fr ;;
    *) echo unknown ;;
  esac
}

# Licencia conocida por origen (solo las seguras; el resto unknown).
manifest_licencia_zim() {
  case $1 in
    wikipedia|wiktionary|wikibooks|wikisource|wikiversity|wikiquote|vikidia) echo "CC-BY-SA-4.0" ;;
    wikispecies|other) [[ $2 == wikispecies* ]] && echo "CC-BY-SA-4.0" || echo unknown ;;
    gutenberg) echo "public-domain (Project Gutenberg)" ;;
    stack_exchange) echo "CC-BY-SA-4.0" ;;
    phet) echo "CC-BY-4.0" ;;
    libretexts) echo "CC-BY-NC-SA-4.0 (mayoría; ver cada libro)" ;;
    devdocs) echo "varias (ver cada proyecto)" ;;
    *) echo unknown ;;
  esac
}

# Reconstruye el registro a partir de los inventarios y de lo que hay en disco.
# Idempotente; solo hashea archivos nuevos o cambiados.
manifest_rebuild() {
  manifest_init
  local p pr cat carpeta prefijo archivo sha fecha lang
  # ZIM (hash conocido de Kiwix)
  while IFS=$'\t' read -r p pr cat carpeta prefijo; do
    archivo=$(zim_json_get "$prefijo" archivo 2>/dev/null || true)
    [[ -n $archivo && -s "$ZIM_DIR/$archivo" ]] || continue
    sha=$(zim_json_get "$prefijo" sha256); fecha=$(zim_json_get "$prefijo" fecha)
    manifest_add "zim/$archivo" "$KIWIX_BASE/$carpeta/$archivo" "$fecha" "$(manifest_idioma "$archivo")" \
      "$(manifest_licencia_zim "$carpeta" "$prefijo")" "$pr" "$cat" "$p" "$sha"
  done < <(packs_read "$PACKS_CONF")
  # Manuales y libros
  local d u lic
  while IFS=$'\t' read -r p pr cat d u _ lic; do
    if [[ $d == */ ]]; then
      [[ -d "$RESPALDO/$d" ]] && manifest_add_dir "${d%/}" "$u" unknown "$(manifest_idioma "$d")" "$lic" "$pr" "$cat" "$p"
    else
      [[ -s "$RESPALDO/$d" ]] && manifest_add "$d" "$u" unknown "$(manifest_idioma "$d")" "$lic" "$pr" "$cat" "$p"
    fi
  done < <(manuals_read)
  # Mapas
  local v f
  v=$(cat "$RESPALDO/mapas/VERSION.txt" 2>/dev/null || echo unknown)
  for f in "$RESPALDO"/mapas/*.mwm; do
    [[ -f $f ]] && manifest_add "mapas/$(basename "$f")" "https://cdn-us1.organicmaps.app/maps/$v/$(basename "$f")" "$v" mul "Organic Maps Binary Data License" P0 mapas core
  done
  # Software
  local dir="$RESPALDO/software"
  [[ -d $dir/deb ]] && manifest_add_dir software/deb "apt (Ubuntu 24.04)" unknown unknown "varias (paquetes Debian/Ubuntu)" P0 software core
  [[ -d $dir/kiwix ]] && manifest_add_dir software/kiwix "https://download.kiwix.org/release/ y GitHub kiwix" unknown mul "GPL-3.0" P0 software core
  [[ -d $dir/organicmaps ]] && manifest_add_dir software/organicmaps "https://github.com/organicmaps/organicmaps/releases" "$(json_get "$SOFTWARE_JSON" organicmaps version || true)" mul "Apache-2.0" P0 software core
  for f in "$dir"/iso/*.iso; do
    [[ -f $f ]] && manifest_add "software/iso/$(basename "$f")" "${UBUNTU_ISO_URL_BASE:-https://releases.ubuntu.com/24.04}" "$(basename "$f" .iso)" mul "varias (Ubuntu)" P1 software recovery "$(json_get "$SOFTWARE_JSON" ubuntu_iso sha256 || true)"
  done
  for f in "$dir"/llm/modelos/*.gguf; do
    [[ -f $f ]] || continue
    local base; base=$(basename "$f")
    manifest_add "software/llm/modelos/$base" "https://huggingface.co/$(json_get "$SOFTWARE_JSON" "modelo:$base" repo || echo unknown)" unknown mul "Apache-2.0 (Qwen2.5)" P1 ia core "$(json_get "$SOFTWARE_JSON" "modelo:$base" sha256 || true)"
  done
  [[ -d $dir/llm/llama.cpp ]] && manifest_add software/llm/llama.cpp "${LLAMACPP_REPO:-https://github.com/ggml-org/llama.cpp}" "$(json_get "$SOFTWARE_JSON" llamacpp version || true)" en "MIT" P1 ia core
  local r
  for r in "$dir"/ia/codigo/*/; do
    [[ -d $r ]] && manifest_add "software/ia/codigo/$(basename "$r")" "https://github.com/$(git -C "$r" remote get-url origin 2>/dev/null | sed -E 's#.*github.com/##; s#\.git$##')" "$(git -C "$r" rev-parse --short HEAD 2>/dev/null || echo unknown)" en unknown P1 ia recovery
  done
  [[ -d $dir/ia/wheels ]] && manifest_add_dir software/ia/wheels "https://download.pytorch.org/whl/cpu y PyPI" unknown en "BSD-3-Clause (PyTorch) y otras" P1 ia recovery
  for r in "$dir"/source/*/; do
    [[ -d $r ]] && manifest_add_dir "software/source/$(basename "$r")" "ver software/source/$(basename "$r")/ORIGEN.txt" unknown en unknown P1 computacion recovery
  done
  [[ -d $dir/arca.git ]] && manifest_add software/arca.git "https://github.com/felipevidela/civilization_backup" "$(git -C "$dir/arca.git" rev-parse --short HEAD 2>/dev/null || echo unknown)" es MIT P0 software core
  # Referencia, documentación y bootstrap
  [[ -d "$RESPALDO/referencia" ]] && manifest_add_dir referencia "ver referencia/LEEME.md" unknown mul unknown P0 referencia core
  [[ -d "$RESPALDO/docs" ]] && manifest_add_dir docs "ARCA (docs/ del repositorio)" unknown mul MIT P0 documentacion core
  local doc
  for doc in README.txt START_HERE.txt START_HERE_ES.txt START_HERE_EN.txt START_HERE.html library.xml mapas/VERSION.txt; do
    [[ -s "$RESPALDO/$doc" ]] && manifest_add "$doc" "ARCA (generado)" "$(date +%Y-%m-%d)" mul MIT P0 documentacion core
  done
  while IFS= read -r -d '' doc; do
    manifest_add "${doc#"$RESPALDO"/}" "ARCA (generado)" unknown es MIT P0 documentacion core
  done < <(find "$RESPALDO" -maxdepth 4 \( -name 'LEEME*.txt' -o -name 'LEEME*.md' \) ! -path '*/bootstrap/*' ! -path '*/.arca/*' -print0 2>/dev/null)
}

# Genera MANIFEST.tsv: registro + archivos presentes no registrados + faltantes.
manifest_generate() {
  manifest_init
  local tmp="$MANIFEST_OUT.tmp"
  {
    printf '%s\n' "$MANIFEST_COLS"
    # Registrados: comprobar existencia y tamaño.
    awk -F'\t' 'NR>1' "$MANIFEST_REG" | while IFS=$'\t' read -r rel size sha src ver fecha lang lic pr cat perfil _ _; do
      local estado=ok abs="$RESPALDO/$rel"
      if [[ ! -e $abs ]]; then estado=missing
      elif [[ -f $abs && $(stat -c %s "$abs") != "$size" ]]; then estado="size-mismatch"
      fi
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$rel" "$size" "$sha" "$src" "$ver" "$fecha" "$lang" "$lic" "$pr" "$cat" "$perfil" "$estado"
    done
    # No registrados (excepto estado interno, temporales y carpetas ya registradas como conjunto).
    local f rel
    while IFS= read -r -d '' f; do
      rel=${f#"$RESPALDO"/}
      case $rel in .arca/*|*.part|*.aria2|*.tmp|MANIFEST.tsv|recovery/*|bootstrap/*|lost+found/*|software/llm/llama.cpp/*|software/ia/codigo/*|software/arca.git/*|software/source/*) continue ;; esac
      awk -F'\t' -v p="$rel" 'NR>1 && $1==p {f=1} END{exit !f}' "$MANIFEST_REG" && continue
      printf '%s\t%s\tunknown\tunknown\tunknown\tunknown\tunknown\tunknown\tunknown\tunknown\tunknown\tunregistered\n' "$rel" "$(stat -c %s "$f")"
    done < <(find "$RESPALDO" -type f -print0 2>/dev/null)
  } | { read -r cab; echo "$cab"; sort -t$'\t' -k1,1; } > "$tmp"
  mv "$tmp" "$MANIFEST_OUT"
  chown_respaldo "$MANIFEST_OUT" 2>/dev/null || true
}

# Resumen: "prioridad<TAB>bytes" y contadores de estado.
manifest_resumen() {
  [[ -s $MANIFEST_OUT ]] || return 1
  awk -F'\t' 'NR>1 && $12!="missing" {b[$9]+=$2; n[$12]++} END{
    for (p in b) printf "size\t%s\t%d\n", p, b[p]
    for (s in n) printf "status\t%s\t%d\n", s, n[s]
    printf "total\t%d\n", NR-1 }' "$MANIFEST_OUT"
}
