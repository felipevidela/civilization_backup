#!/usr/bin/env bash
# tests/run.sh — pruebas de ARCA sin red ni root (bash puro). Pensadas para Ubuntu 24.04.
# Uso: ./tests/run.sh        (devuelve 0 si todo pasa)
# shellcheck disable=SC2015,SC2155  # en las pruebas "cond && ok || fail" es intencional
# Nota: no usar "func | grep -q" con pipefail: grep cierra la tubería y la función falla por SIGPIPE.
set -uo pipefail
ARCA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP=$(mktemp -d); trap 'rm -rf "$TMP" /tmp/arca-dry-run-test' EXIT
PASA=0; FALLA=0
ok()   { PASA=$((PASA + 1)); echo "  ✔ $1"; }
fail() { FALLA=$((FALLA + 1)); echo "  ✖ $1"; [[ -n ${2:-} ]] && echo "      $2"; }
check() { local nombre=$1; shift; if "$@" > "$TMP/out" 2>&1; then ok "$nombre"; else fail "$nombre" "$(tail -3 "$TMP/out" | tr '\n' ' ')"; fi; }

echo "== Sintaxis (bash -n) y shellcheck =="
for f in "$ARCA_DIR"/*.sh "$ARCA_DIR"/lib/*.sh "$ARCA_DIR"/bin/*; do
  check "bash -n $(basename "$f")" bash -n "$f"
done
if command -v shellcheck > /dev/null; then
  check "shellcheck" shellcheck -x -s bash "$ARCA_DIR"/*.sh "$ARCA_DIR"/lib/*.sh "$ARCA_DIR"/bin/*
else
  echo "  (shellcheck no instalado; omitido)"
fi
if command -v python3 > /dev/null; then
  check "python: arca_index.py compila" python3 -m py_compile "$ARCA_DIR/lib/arca_index.py"
  check "python: preguntar.py compila" python3 -m py_compile "$ARCA_DIR/llm/preguntar.py"
else
  echo "  (python3 no instalado; omitido)"
fi

# Entorno aislado para las librerías.
export RESPALDO="$TMP/respaldo" ARCA_STATE_DIR="$TMP/respaldo/.arca" ARCA_TMP="$TMP/respaldo/.arca/tmp"
export ARCA_LOG_DIR="$TMP/logs" ARCA_LOG_COPY="" USUARIO="$(id -un)"
export PACKS_CONF="$ARCA_DIR/tests/fixtures/packs.conf" MANUALS_CONF="$ARCA_DIR/tests/fixtures/manuals.conf" SOFTWARE_CONF="$ARCA_DIR/software.conf"
mkdir -p "$ARCA_STATE_DIR" "$ARCA_TMP" "$ARCA_LOG_DIR" "$RESPALDO/zim" "$RESPALDO/manuales/agua"
for lib in log space state profiles fetch kiwix manifest docs phases; do
  # shellcheck disable=SC1090
  source "$ARCA_DIR/lib/$lib.sh"
done
log_init tests > /dev/null

echo "== Espacio y unidades =="
[[ $(human 1536) == "1 KB" ]] && ok "human 1536 → 1 KB (enteros hasta KB)" || fail "human 1536" "$(human 1536)"
[[ $(human 3729369590) == "3.5 GB" ]] && ok "human 3.5 GB" || fail "human GB" "$(human 3729369590)"
[[ $(human_to_bytes 115G) == 123480309760 ]] && ok "human_to_bytes 115G" || fail "human_to_bytes 115G" "$(human_to_bytes 115G)"
[[ $(human_to_bytes 540M) == 566231040 ]] && ok "human_to_bytes 540M" || fail "human_to_bytes 540M" "$(human_to_bytes 540M)"

echo "== Perfiles =="
ARCA_PERFIL=core ARCA_EXTRAS=""
recurso_activo core && ! recurso_activo recovery && ! recurso_activo full && ok "core incluye solo core" || fail "core"
ARCA_PERFIL=recovery
recurso_activo core && recurso_activo recovery && ! recurso_activo full && ok "recovery incluye core y recovery" || fail "recovery"
ARCA_PERFIL=full
recurso_activo full && ! recurso_activo extra:gutenberg-full && ok "full no incluye extras" || fail "full/extras"
ARCA_EXTRAS="gutenberg-full"
recurso_activo extra:gutenberg-full && ! recurso_activo extra:otro && ok "--extra activa solo ese extra" || fail "extra"
[[ $(atributos_de_linea "core P0 medicina wikipedia/wikipedia_en_medicine_maxi") == $'core\tP0\tmedicina\twikipedia/wikipedia_en_medicine_maxi' ]] && ok "atributos_de_linea con atributos" || fail "atributos_de_linea"
[[ $(atributos_de_linea "wikipedia/wikipedia_es_all_mini") == $'full\tP2\tgeneral\twikipedia/wikipedia_es_all_mini' ]] && ok "atributos_de_linea sin atributos → full P2 general" || fail "atributos_de_linea default"
ARCA_PERFIL=""; ARCA_EXTRAS=""
perfil_cargar; [[ $ARCA_PERFIL == full ]] && ok "perfil por defecto = full" || fail "perfil por defecto" "$ARCA_PERFIL"
ARCA_PERFIL=core ARCA_EXTRAS="a b"; perfil_guardar; ARCA_PERFIL=""; ARCA_EXTRAS=""; perfil_cargar
[[ $ARCA_PERFIL == core && $ARCA_EXTRAS == *a* && $ARCA_EXTRAS == *b* ]] && ok "perfil y extras persistidos en .arca/" || fail "persistencia" "$ARCA_PERFIL / $ARCA_EXTRAS"

echo "== Parseo de configuración =="
n=$(packs_read "$PACKS_CONF" | wc -l); [[ $n == 5 ]] && ok "packs_read: 5 líneas activas (comentarios y vacías fuera)" || fail "packs_read" "$n"
grep -q $'extra:gutenberg-full\tP3\tcultura\tgutenberg\tgutenberg_en_all' <<< "$(packs_read "$PACKS_CONF")" && ok "packs_read: extra con carpeta/prefijo" || fail "packs_read extra"
n=$(manuals_read | wc -l); [[ $n == 4 ]] && ok "manuals_read: 4 líneas" || fail "manuals_read" "$n"
MR=$(manuals_read)
grep -q $'core\tP0\tagua\tmanuales/agua/prueba.txt\tfile://' <<< "$MR" && ok "manuals_read: atributos y destino" || fail "manuals_read atributos"
grep -q $'full\tP2\tgeneral\tmanuales/x.pdf\thttps://e/x.pdf\tsin atributos\tunknown' <<< "$MR" && ok "manuals_read: línea antigua → full P2 general, licencia unknown" || fail "manuals_read legado"
grep -q $'MIT$' <<< "$MR" && ok "manuals_read: licencia en 5.º campo" || fail "manuals_read licencia"
ARCA_PERFIL=core; n=0; while IFS=$'\t' read -r p _ _ _ _; do recurso_activo "$p" && n=$((n + 1)); done < <(packs_read "$PACKS_CONF"); [[ $n == 2 ]] && ok "core selecciona 2 de 5 ZIM" || fail "selección core" "$n"
ARCA_PERFIL=full; n=0; while IFS=$'\t' read -r p _ _ _ _; do recurso_activo "$p" && n=$((n + 1)); done < <(packs_read "$PACKS_CONF"); [[ $n == 4 ]] && ok "full selecciona 4 de 5 ZIM (sin extra)" || fail "selección full" "$n"
software_load; [[ $(perfil_rango "$ARCA_PERFIL") -gt 0 ]] && soft_activo iso && ok "SOFT_PERFILES: iso en full" || fail "soft_activo"
ARCA_PERFIL=core; soft_activo iso && fail "SOFT_PERFILES: iso no debería entrar en core" || ok "SOFT_PERFILES: iso fuera de core"

echo "== Kiwix (listado local en caché) =="
cp "$ARCA_DIR/tests/fixtures/listing_wikipedia.html" "$ARCA_TMP/kiwix_listing_wikipedia.html"
[[ $(kiwix_latest wikipedia wikipedia_es_all_mini) == wikipedia_es_all_mini_2026-08.zim ]] && ok "kiwix_latest elige la fecha mayor" || fail "kiwix_latest" "$(kiwix_latest wikipedia wikipedia_es_all_mini)"
[[ $(kiwix_latest wikipedia wikipedia_es_all) == "" ]] && ok "kiwix_latest no confunde prefijos (es_all vs es_all_mini)" || fail "kiwix_latest prefijo"
[[ $(kiwix_latest wikipedia proofwiki_en_all_maxi) == proofwiki_en_all_maxi_2026-07f.zim ]] && ok "kiwix_latest acepta sufijo de letra" || fail "sufijo" "$(kiwix_latest wikipedia proofwiki_en_all_maxi)"
[[ $(kiwix_listed_size wikipedia wikipedia_es_all_mini_2026-08.zim) == 3758096384 ]] && ok "kiwix_listed_size 3.5G" || fail "listed_size" "$(kiwix_listed_size wikipedia wikipedia_es_all_mini_2026-08.zim)"
[[ $(kiwix_fecha wikipedia_es_all_mini_2026-08.zim) == 2026-08 ]] && ok "kiwix_fecha" || fail "kiwix_fecha"
zim_json_set wikipedia_es_all_mini wikipedia_es_all_mini_2026-08.zim abc 123
[[ $(zim_json_get wikipedia_es_all_mini fecha) == 2026-08 ]] && ok "zim.json escribe y lee" || fail "zim.json"

echo "== Manifiesto =="
echo "hola" > "$RESPALDO/manuales/agua/prueba.txt"
manifest_add manuales/agua/prueba.txt "file://prueba" 1.0 es MIT P0 agua core
sha=$(sha256sum "$RESPALDO/manuales/agua/prueba.txt" | awk '{print $1}')
grep -q "manuales/agua/prueba.txt	5	$sha	file://prueba	1.0	" "$MANIFEST_REG" && ok "manifest_add calcula sha256 y registra" || fail "manifest_add" "$(tail -1 "$MANIFEST_REG")"
echo "otro" > "$RESPALDO/manuales/agua/huerfano.txt"
manifest_generate
grep -q $'manuales/agua/huerfano.txt\t5\tunknown' "$MANIFEST_OUT" && grep -q 'unregistered' "$MANIFEST_OUT" && ok "manifest_generate marca no registrados" || fail "manifest_generate unregistered"
rm "$RESPALDO/manuales/agua/prueba.txt"; manifest_generate
grep -q $'manuales/agua/prueba.txt\t.*\tmissing$' "$MANIFEST_OUT" && ok "manifest_generate marca faltantes" || fail "manifest_generate missing"
head -1 "$MANIFEST_OUT" | grep -q '^path	size	sha256	source	version	date	language	license	priority	category	profile	status$' && ok "MANIFEST.tsv: 12 columnas" || fail "columnas"

echo "== Argumentos de línea de órdenes =="
"$ARCA_DIR/setup.sh" --help > "$TMP/out" 2>&1 && grep -q -- '--profile' "$TMP/out" && ok "setup.sh --help" || fail "setup.sh --help"
"$ARCA_DIR/setup.sh" --profile malo --dry-run > "$TMP/out" 2>&1; grep -q 'Perfil inválido' "$TMP/out" && ok "setup.sh rechaza perfil inválido" || fail "perfil inválido" "$(tail -2 "$TMP/out")"
"$ARCA_DIR/setup.sh" --from 99 > "$TMP/out" 2>&1; grep -q 'Fase inválida' "$TMP/out" && ok "setup.sh rechaza fase inválida" || fail "fase inválida"
"$ARCA_DIR/update.sh" --help > "$TMP/out" 2>&1 && grep -q -- '--prune' "$TMP/out" && ok "update.sh --help" || fail "update.sh --help"
"$ARCA_DIR/backup.sh" --help > "$TMP/out" 2>&1 && grep -q -- '--snapshot' "$TMP/out" && ok "backup.sh --help" || fail "backup.sh --help"
"$ARCA_DIR/check.sh" --help > "$TMP/out" 2>&1 && grep -q -- '--scrub' "$TMP/out" && ok "check.sh --help" || fail "check.sh --help"

echo "== Ensayo (--dry-run) sin red, sin root =="
# El ensayo sin root usa /tmp/arca-dry-run; se precarga el listado de Kiwix y se usan URL file://.
rm -rf /tmp/arca-dry-run; mkdir -p /tmp/arca-dry-run/tmp
cp "$ARCA_DIR/tests/fixtures/listing_wikipedia.html" /tmp/arca-dry-run/tmp/kiwix_listing_wikipedia.html
sed "s#file://FIXTURES#file://$ARCA_DIR/tests/fixtures#" "$ARCA_DIR/tests/fixtures/manuals.conf" > "$TMP/manuals-dry.conf"
sed -e 's/^MAPAS=1/MAPAS=0/' -e 's/^UBUNTU_ISO=1/UBUNTU_ISO=0/' -e 's/^LLM_ENABLED=1/LLM_ENABLED=0/' -e 's/^IA_ENABLED=1/IA_ENABLED=0/' "$ARCA_DIR/software.conf" > "$TMP/software-dry.conf"
if [[ $(id -u) -eq 0 ]]; then
  echo "  (se ejecuta como root: el ensayo completo necesita red; omitido)"
else
  PACKS_CONF="$PACKS_CONF" MANUALS_CONF="$TMP/manuals-dry.conf" SOFTWARE_CONF="$TMP/software-dry.conf" RESPALDO="$RESPALDO" \
    "$ARCA_DIR/setup.sh" --dry-run --profile core > "$TMP/dry" 2>&1
  grep -q '^Perfil: core' "$TMP/dry" && ok "dry-run muestra el perfil" || fail "dry-run perfil" "$(tail -5 "$TMP/dry")"
  grep -q 'wikipedia_es_all_mini_2026-08.zim' "$TMP/dry" && ok "dry-run resuelve el ZIM desde el listado" || fail "dry-run zim"
  grep -q 'P0 esencial' "$TMP/dry" && grep -q 'Recursos más pesados' "$TMP/dry" && ok "dry-run muestra prioridades y recursos pesados" || fail "dry-run resumen"
  grep -q 'gutenberg-full' "$TMP/dry" && ok "dry-run lista extras desactivados" || fail "dry-run extras"
  grep -q 'Fases que se ejecutarían' "$TMP/dry" && ok "dry-run termina sin descargar" || fail "dry-run fin"
  [[ -z $(find "$RESPALDO/zim" -type f) ]] && ok "dry-run no descargó nada" || fail "dry-run descargó"
fi

echo
echo "Resultado: $PASA correctas, $FALLA fallidas"
(( FALLA == 0 ))
