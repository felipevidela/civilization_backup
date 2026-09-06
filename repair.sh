#!/usr/bin/env bash
# repair.sh — redundancia PAR2 para el núcleo crítico de ARCA (bootstrap, documentación,
# manuales esenciales pequeños, referencia). Los archivos de paridad viven en
# /srv/respaldo/recovery/ y permiten reconstruir hasta un 10 % de daño por bloque.
#
# Uso: sudo ./repair.sh --create    genera o actualiza la paridad (lo hace setup/update)
#      sudo ./repair.sh --verify    comprueba el núcleo crítico contra la paridad
#      sudo ./repair.sh --repair    repara archivos dañados (solo bajo petición explícita)
#      sudo ./repair.sh --info      qué está protegido y cuánto ocupa
set -euo pipefail

ARCA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESPALDO="${RESPALDO:-/srv/respaldo}"
ARCA_STATE_DIR="$RESPALDO/.arca"; ARCA_LOG_DIR="$ARCA_DIR/logs"; ARCA_LOG_COPY="$ARCA_STATE_DIR/arca.log"
export ARCA_STATE_DIR ARCA_LOG_DIR ARCA_LOG_COPY
for lib in log space; do
  # shellcheck disable=SC1090
  source "$ARCA_DIR/lib/$lib.sh"
done
RECOVERY="$RESPALDO/recovery"
REDUNDANCIA="${PAR2_REDUNDANCIA:-10}"
# Conjuntos protegidos: nombre → carpeta (relativa a /srv/respaldo). Solo material pequeño y crítico.
CONJUNTOS="bootstrap:bootstrap docs:docs referencia:referencia medicina-austera:manuales/medicina/austera medicina-actual:manuales/medicina/actual agua:manuales/agua supervivencia:manuales/supervivencia"
MAX_BYTES_CONJUNTO=$((1024 * 1024 * 1024))   # 1 GB por conjunto; más grande no se protege

modo=${1:---info}
[[ $modo =~ ^--(create|verify|repair|info)$ ]] || { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
[[ $(id -u) -eq 0 || $modo == --info ]] || die "Ejecuta con sudo."
command -v par2 > /dev/null || die "Falta par2: sudo apt install par2 (o desde software/deb/)."
mkdir -p "$RECOVERY" "$ARCA_LOG_DIR"
log_init repair

rc_total=0
for par in $CONJUNTOS; do
  nombre=${par%%:*}; carpeta="$RESPALDO/${par#*:}"
  [[ -d $carpeta ]] || continue
  bytes=$(space_used_bytes "$carpeta")
  if (( bytes > MAX_BYTES_CONJUNTO )); then log_warn "$nombre pesa $(human "$bytes"); se omite (límite $(human "$MAX_BYTES_CONJUNTO"))."; continue; fi
  base="$RECOVERY/$nombre.par2"
  case $modo in
    --info)
      if [[ -f $base ]]; then
        printf '  %-18s %8s protegidos, paridad %8s (%s)\n' "$nombre" "$(human "$bytes")" "$(human "$(du -cb "$RECOVERY/$nombre".*par2 | tail -1 | awk '{print $1}')")" "$(date -r "$base" +%Y-%m-%d)"
      else
        printf '  %-18s %8s sin paridad (ejecuta --create)\n' "$nombre" "$(human "$bytes")"
      fi ;;
    --create)
      # Se regenera si algún archivo es más nuevo que la paridad.
      if [[ -f $base && -z $(find "$carpeta" -type f -newer "$base" -print -quit) ]]; then
        log_debug "$nombre: paridad al día."; continue
      fi
      log_info "Generando paridad $REDUNDANCIA % para $nombre ($(human "$bytes"))..."
      rm -f "$RECOVERY/$nombre".*par2
      # -B fija la base de rutas para que los par2 sean relativos a /srv/respaldo.
      if log_cmd par2 create -q -R -r"$REDUNDANCIA" -n1 -B "$RESPALDO" "$base" "$carpeta"; then
        log_ok "$nombre protegido."
      else
        log_error "par2 create falló para $nombre"; rc_total=1
      fi ;;
    --verify|--repair)
      [[ -f $base ]] || { log_warn "$nombre: sin paridad."; continue; }
      if par2 verify -q -B "$RESPALDO" "$base" >> "$ARCA_LOG_FILE" 2>&1; then
        log_ok "$nombre: íntegro."
      elif [[ $modo == --repair ]]; then
        log_warn "$nombre: dañado; reparando..."
        if par2 repair -B "$RESPALDO" "$base" >> "$ARCA_LOG_FILE" 2>&1; then log_ok "$nombre: reparado."; else log_error "$nombre: no se pudo reparar (daño mayor que la redundancia)."; rc_total=1; fi
      else
        log_error "$nombre: DAÑADO o incompleto. Repara con: sudo $ARCA_DIR/repair.sh --repair"; rc_total=1
      fi ;;
  esac
done
[[ $modo == --info ]] && echo "  Paridad en $RECOVERY ($(human "$(space_used_bytes "$RECOVERY")"))."
[[ $modo == --verify ]] && date -Is > "$ARCA_STATE_DIR/ultimo-par2-verify"
exit $rc_total
