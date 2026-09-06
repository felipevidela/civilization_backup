#!/usr/bin/env bash
# install.sh — bootstrap mínimo de arca para ejecutar con:
#   curl -fsSL https://raw.githubusercontent.com/felipevidela/civilization_backup/main/install.sh | sudo bash
#
# Verifica distro, root e internet; instala git y curl; clona (o actualiza) el repo en
# /opt/arca y ejecuta setup.sh con los argumentos recibidos:
#   curl -fsSL .../install.sh | sudo bash -s -- --profile recovery
#   curl -fsSL .../install.sh | sudo bash -s -- --profile core --dry-run
# Perfiles: core (≈60 GB), recovery (≈255 GB), full (≈480 GB, por defecto); extras con --extra.
#
# Todo va dentro de main() para que una descarga cortada a medias no ejecute nada.
set -euo pipefail

ARCA_REPO_URL="${ARCA_REPO_URL:-https://github.com/felipevidela/civilization_backup.git}"
ARCA_BRANCH="${ARCA_BRANCH:-main}"
ARCA_DIR="${ARCA_DIR:-/opt/arca}"

main() {
  echo "== arca: instalador =="

  if [[ $(id -u) -ne 0 ]]; then
    echo "Este instalador necesita root. Ejecuta: curl -fsSL ... | sudo bash" >&2
    exit 1
  fi

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}:${VERSION_ID:-}" in
      ubuntu:24.04) echo "Sistema: Ubuntu 24.04 LTS" ;;
      debian:12)    echo "AVISO: Debian 12 no está probado; se continúa bajo tu responsabilidad." ;;
      *) echo "Sistema no soportado: ${PRETTY_NAME:-desconocido}. Se requiere Ubuntu 24.04 (o Debian 12 con aviso)." >&2; exit 1 ;;
    esac
  else
    echo "No se pudo leer /etc/os-release." >&2
    exit 1
  fi

  if ! curl -fsSI --connect-timeout 15 --max-time 30 https://github.com > /dev/null 2>&1; then
    echo "Sin conexión a internet (no se alcanza github.com)." >&2
    exit 1
  fi

  local faltan=()
  command -v git  > /dev/null || faltan+=(git)
  command -v curl > /dev/null || faltan+=(curl)
  if (( ${#faltan[@]} > 0 )); then
    echo "Instalando ${faltan[*]}..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq "${faltan[@]}"
  fi

  if [[ -d $ARCA_DIR/.git ]]; then
    echo "Actualizando $ARCA_DIR..."
    git -C "$ARCA_DIR" fetch -q origin "$ARCA_BRANCH"
    git -C "$ARCA_DIR" reset -q --hard "origin/$ARCA_BRANCH"
  else
    echo "Clonando $ARCA_REPO_URL en $ARCA_DIR..."
    git clone -q --branch "$ARCA_BRANCH" "$ARCA_REPO_URL" "$ARCA_DIR"
  fi
  chmod +x "$ARCA_DIR"/*.sh "$ARCA_DIR"/lib/motd.sh

  echo "Lanzando setup.sh $*"
  exec "$ARCA_DIR/setup.sh" "$@"
}

main "$@"
