# shellcheck shell=bash
# lib/profiles.sh — perfiles de instalación (core ⊂ recovery ⊂ full) y extras opcionales.
#
# Cada recurso de packs.conf, manuals.conf y software.conf declara su perfil mínimo:
#   core      conocimiento esencial (≈60 GB)
#   recovery  core + ciencia, ingeniería, manufactura, energía, computación (≈255 GB)
#   full      recovery + cultura, historia, video educativo, colecciones (≈490 GB)
#   extra:X   solo si el usuario activa el extra X (--extra X)
# El perfil elegido se guarda en $ARCA_STATE_DIR/profile y los extras en $ARCA_STATE_DIR/extras.

ARCA_PERFIL="${ARCA_PERFIL:-}"
ARCA_EXTRAS="${ARCA_EXTRAS:-}"
PERFIL_POR_DEFECTO="full"

perfil_valido() {
  [[ $1 =~ ^(core|recovery|full)$ ]]
}

perfil_rango() {
  case $1 in
    core) echo 1 ;; recovery) echo 2 ;; full) echo 3 ;; *) echo 0 ;;
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
  perfil_valido "$ARCA_PERFIL" || die "Perfil inválido: '$ARCA_PERFIL' (core, recovery o full)"
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
  read -r p pr c resto <<< "$linea"
  if [[ $p =~ ^(core|recovery|full|extra:[a-z0-9-]+)$ && $pr =~ ^P[0-3]$ && -n $c && -n $resto ]]; then
    printf '%s\t%s\t%s\t%s\n' "$p" "$pr" "$c" "$resto"
  else
    printf 'full\tP2\tgeneral\t%s\n' "$linea"
  fi
}

# Nombre legible de una prioridad.
prioridad_nombre() {
  case $1 in
    P0) echo "P0 esencial" ;; P1) echo "P1 muy importante" ;; P2) echo "P2 complementario" ;; P3) echo "P3 cultural/opcional" ;; *) echo "$1" ;;
  esac
}
