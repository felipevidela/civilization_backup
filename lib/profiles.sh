# shellcheck shell=bash
# lib/profiles.sh — perfiles de instalación (survive ⊂ core ⊂ recovery ⊂ full) y extras.
#
# Cada recurso de packs.conf, manuals.conf y software.conf declara su perfil mínimo:
#   survive   vivir quince años sin red: agua, medicina, comida, huerta, sismo (≈55 GB)
#   core      survive + ciencia y matemáticas de base, educación, energía (≈63 GB)
#   recovery  core + oficios e industria: manufactura, materiales, computación (≈255 GB)
#   full      recovery + legado y cultura: video educativo, clásicos, humanidades (≈480 GB)
#   extra:X   solo si el usuario activa el extra X (--extra X)
# El perfil elegido se guarda en $ARCA_STATE_DIR/profile y los extras en $ARCA_STATE_DIR/extras.
# "15y" es alias de "survive".

ARCA_PERFIL="${ARCA_PERFIL:-}"
ARCA_EXTRAS="${ARCA_EXTRAS:-}"
PERFIL_POR_DEFECTO="full"

# Normaliza alias: 15y → survive.
perfil_normalizar() {
  case $1 in
    15y|15Y) echo survive ;; *) echo "$1" ;;
  esac
}

perfil_valido() {
  [[ $(perfil_normalizar "$1") =~ ^(survive|core|recovery|full)$ ]]
}

perfil_rango() {
  case $(perfil_normalizar "$1") in
    survive) echo 1 ;; core) echo 2 ;; recovery) echo 3 ;; full) echo 4 ;; *) echo 0 ;;
  esac
}

# Carga el perfil y los extras persistidos si no vienen por variable/argumento.
perfil_cargar() {
  local archivo="$ARCA_STATE_DIR/profile"
  if [[ -z $ARCA_PERFIL ]]; then
    if [[ -s $archivo ]]; then
      ARCA_PERFIL=$(head -1 "$archivo" | tr -d '[:space:]')
    else
      ARCA_PERFIL=$PERFIL_POR_DEFECTO
    fi
  fi
  perfil_valido "$ARCA_PERFIL" || die "Perfil inválido: '$ARCA_PERFIL' (survive, core, recovery o full)"
  ARCA_PERFIL=$(perfil_normalizar "$ARCA_PERFIL")
  if [[ -z $ARCA_EXTRAS && -s "$ARCA_STATE_DIR/extras" ]]; then
    ARCA_EXTRAS=$(tr '\n' ' ' < "$ARCA_STATE_DIR/extras")
  fi
  export ARCA_PERFIL ARCA_EXTRAS
}

perfil_guardar() {
  mkdir -p "$ARCA_STATE_DIR"
  echo "$ARCA_PERFIL" > "$ARCA_STATE_DIR/profile"
  tr ' ' '\n' <<< "$ARCA_EXTRAS" | sed '/^$/d' | sort -u > "$ARCA_STATE_DIR/extras"
}

# ¿Un extra está activado?
extra_activo() {
  local e
  for e in $ARCA_EXTRAS; do [[ $e == "$1" ]] && return 0; done
  return 1
}

# ¿Un recurso con perfil mínimo $1 entra en la instalación actual?
recurso_activo() {
  local minimo=$1
  case $minimo in
    extra:*) extra_activo "${minimo#extra:}" ;;
    *) (( $(perfil_rango "$minimo") > 0 && $(perfil_rango "$minimo") <= $(perfil_rango "$ARCA_PERFIL") )) ;;
  esac
}

# Lee los tres tokens de atributos de una línea: "perfil prioridad categoria resto..."
# Imprime "perfil<TAB>prioridad<TAB>categoria<TAB>resto". Sin atributos: full P2 general.
atributos_de_linea() {
  local linea=$1 p pr c resto
  # IFS propio: quien llama suele hacer "IFS=$'\t' read ... <<< $(atributos_de_linea ...)",
  # y ese IFS se hereda aquí y rompería la separación por espacios.
  local IFS=$' \t\n'
  read -r p pr c resto <<< "$linea"
  if [[ $p =~ ^(survive|core|recovery|full|extra:[a-z0-9-]+)$ && $pr =~ ^P[0-3]$ && -n $c && -n $resto ]]; then
    printf '%s\t%s\t%s\t%s\n' "$p" "$pr" "$c" "$resto"
  else
    printf 'full\tP2\tgeneral\t%s\n' "$linea"
  fi
}

# Nombre legible de una prioridad.
prioridad_nombre() {
  case $1 in
    P0) echo "P0 vivir 15 años" ;; P1) echo "P1 oficios" ;; P2) echo "P2 legado" ;; P3) echo "P3 cultura" ;; *) echo "$1" ;;
  esac
}
