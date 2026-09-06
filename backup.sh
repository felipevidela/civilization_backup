#!/usr/bin/env bash
# backup.sh — copia /srv/respaldo a un disco externo con rsync.
#
# Uso: sudo ./backup.sh [--mirror | --snapshot] [/ruta/destino] [--yes]
#   --mirror    (por defecto) réplica exacta del estado actual en destino/ con --delete:
#               lo borrado en origen se borra en destino. Rápido y simple; un solo estado.
#   --snapshot  copia histórica en destino/arca-AAAA-MM-DD/ con hardlinks (--link-dest) a la
#               anterior: los archivos sin cambios no ocupan espacio extra; cada carpeta es un
#               estado completo que no se modifica después. destino/ultimo apunta a la reciente.
#   Sin ruta: lista los discos montados y pide elegir uno.
#   --yes: no pide confirmación.
set -euo pipefail

ARCA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESPALDO="${RESPALDO:-/srv/respaldo}"
ARCA_STATE_DIR="$RESPALDO/.arca"; ARCA_LOG_DIR="$ARCA_DIR/logs"; ARCA_LOG_COPY="$ARCA_STATE_DIR/arca.log"
export ARCA_STATE_DIR ARCA_LOG_DIR ARCA_LOG_COPY
for lib in log space; do
  # shellcheck disable=SC1090
  source "$ARCA_DIR/lib/$lib.sh"
done

DESTINO=""; SI=0; MODO=mirror
for a in "$@"; do
  case $a in
    --yes|-y) SI=1 ;;
    --mirror) MODO=mirror ;;
    --snapshot) MODO=snapshot ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) DESTINO=$a ;;
  esac
done
[[ $(id -u) -eq 0 ]] || die "Ejecuta con sudo."
mountpoint -q "$RESPALDO" || [[ ${ARCA_PERMITIR_SIN_MONTAJE:-0} == 1 ]] || die "$RESPALDO no está montado."
mkdir -p "$ARCA_LOG_DIR"
log_init backup

if [[ -z $DESTINO ]]; then
  echo "Discos montados (excluyendo el sistema y $RESPALDO):"
  mapfile -t opciones < <(findmnt -rno TARGET,FSTYPE,SIZE,AVAIL -t ext4,exfat,ntfs,ntfs3,vfat,xfs,btrfs \
    | grep -vE "^(/|/boot|/boot/efi|$RESPALDO|/var/snap|/snap)( |$)" | grep -vE '^/(proc|sys|dev|run)')
  (( ${#opciones[@]} )) || die "No hay discos externos montados. Conecta el disco y móntalo (o pásame la ruta)."
  i=1; for o in "${opciones[@]}"; do printf '  %d) %s\n' "$i" "$o"; i=$((i + 1)); done
  read -rp "Elige un número: " n
  if ! [[ $n =~ ^[0-9]+$ ]] || (( n < 1 || n > ${#opciones[@]} )); then die "Opción inválida."; fi
  DESTINO=$(awk '{print $1}' <<< "${opciones[$((n - 1))]}")
fi
DESTINO=${DESTINO%/}
[[ -d $DESTINO ]] || die "No existe el destino $DESTINO."
mountpoint -q "$DESTINO" || findmnt -no TARGET --target "$DESTINO" | grep -qv '^/$' || die "$DESTINO está en la partición raíz, no en un disco externo."

# --- Destino según modo ---
EXCLUIR=(--exclude '.arca/tmp/' --exclude '*.aria2' --exclude '*.part')
if [[ $MODO == snapshot ]]; then
  RAIZ=$DESTINO
  DESTINO="$RAIZ/arca-$(date +%Y-%m-%d)"
  LINK=()
  if [[ -d "$RAIZ/ultimo" || -L "$RAIZ/ultimo" ]]; then
    anterior=$(readlink -f "$RAIZ/ultimo")
    [[ -d $anterior && $anterior != "$DESTINO" ]] && LINK=(--link-dest="$anterior")
  fi
  mkdir -p "$DESTINO"
  RSYNC_MODO=("${LINK[@]}")
  echo "Modo SNAPSHOT: nueva carpeta $DESTINO${LINK:+ (sin cambios enlazados a ${anterior})}"
else
  RSYNC_MODO=(--delete)
  echo "Modo MIRROR: $DESTINO quedará idéntico a $RESPALDO (se borra lo que ya no exista en origen)"
fi

# --- Espacio ---
necesario=$(rsync -an "${RSYNC_MODO[@]}" "${EXCLUIR[@]}" --stats "$RESPALDO/" "$DESTINO/" | awk '/Total transferred file size/ {gsub(",", "", $5); print $5}')
libre=$(space_free_bytes "$DESTINO")
usado_origen=$(space_used_bytes "$RESPALDO")
echo
echo "Origen:   $RESPALDO ($(human "$usado_origen"))"
echo "Destino:  $DESTINO ($(human "$libre") libres)"
echo "A copiar: $(human "${necesario:-0}") (solo lo nuevo o cambiado)"
if (( ${necesario:-0} > libre )); then
  die "No cabe: faltan $(human $(( necesario - libre )))."
fi
echo
echo "Vista previa (primeras 25 diferencias):"
# "|| true": head cierra la tubería y con pipefail el script terminaría en silencio.
rsync -an "${RSYNC_MODO[@]}" "${EXCLUIR[@]}" --itemize-changes "$RESPALDO/" "$DESTINO/" | grep -v '^\.d' | head -25 | sed 's/^/  /' || true
echo
if (( ! SI )); then
  read -rp "¿Continuar con la copia a $DESTINO? [s/N] " r
  [[ $r =~ ^[sS]$ ]] || { echo "Cancelado."; exit 0; }
fi

# --- Copia ---
log_info "rsync $RESPALDO/ → $DESTINO/"
inicio=$(date +%s)
rsync -avh "${RSYNC_MODO[@]}" "${EXCLUIR[@]}" --info=progress2 \
  "$RESPALDO/" "$DESTINO/" 2>&1 | tee -a "$ARCA_LOG_FILE" | grep -E '^ |^sent|^total|error' || true
rc=${PIPESTATUS[0]}
(( rc == 0 || rc == 24 )) || die "rsync terminó con código $rc (ver $ARCA_LOG_FILE)."

sha=$(sha256sum "$ARCA_STATE_DIR/zim.json" 2>/dev/null | awk '{print $1}' || echo "sin zim.json")
cat > "$DESTINO/BACKUP-INFO.txt" <<TXT
Copia de seguridad de arca (modo: $MODO)
Fecha:            $(date -Is)
Origen:           $(hostname):$RESPALDO
Duración:         $(( ($(date +%s) - inicio) / 60 )) min
Tamaño:           $(human "$(space_used_bytes "$DESTINO")")
sha256(zim.json): $sha
Para restaurar: monta este disco en /srv/respaldo y sigue README.txt.
TXT
if [[ $MODO == snapshot ]]; then
  ln -sfn "$DESTINO" "$RAIZ/ultimo"
  printf '%s\n' "$(date -Is)" "$DESTINO" > "$ARCA_STATE_DIR/ultimo-snapshot"
  echo "Snapshots en $RAIZ: $(find "$RAIZ" -maxdepth 1 -name 'arca-*' -type d | wc -l). Para borrar uno antiguo: sudo rm -rf $RAIZ/arca-AAAA-MM-DD (los demás no se ven afectados)."
else
  printf '%s\n' "$(date -Is)" "$DESTINO" > "$ARCA_STATE_DIR/ultimo-mirror"
fi
sync
date -Is > "$ARCA_STATE_DIR/ultimo-backup"
echo "$DESTINO" >> "$ARCA_STATE_DIR/ultimo-backup"
log_ok "Copia completa en $DESTINO (BACKUP-INFO.txt escrito, sync hecho). Ya puedes desmontar: sudo umount ${RAIZ:-$DESTINO}"
