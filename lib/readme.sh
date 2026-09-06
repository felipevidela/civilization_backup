# shellcheck shell=bash
# lib/readme.sh — genera /srv/respaldo/README.txt (texto plano, sin dependencias).
# Lo llaman la fase 10 de setup.sh y update.sh.

readme_generar() {
  local salida="$RESPALDO/README.txt"
  local zim_json="${ZIM_JSON:-$ARCA_STATE_DIR/zim.json}"
  local soft_json="${SOFTWARE_JSON:-$ARCA_STATE_DIR/software.json}"
  local fecha; fecha=$(date '+%Y-%m-%d %H:%M')
  local total; total=$(du -sh "$RESPALDO" 2>/dev/null | awk '{print $1}')
  {
    cat <<TXT
================================================================================
  ARCA — SERVIDOR DE CONOCIMIENTO OFFLINE
  Última actualización: $fecha     Tamaño total: ${total:-?}
================================================================================

QUÉ ES ESTO
-----------
Este disco contiene una copia offline de Wikipedia y otras enciclopedias (archivos
ZIM de Kiwix), manuales técnicos y médicos en PDF, mapas, software para volver a
instalar todo sin internet y un modelo de lenguaje local. Lo genera y mantiene el
proyecto "arca" (https://github.com/felipevidela/civilization_backup), cuya copia
está en software/arca.git.

Carpetas:
  zim/         enciclopedias y cursos (ZIM). Se leen con Kiwix.
  manuales/    PDF de medicina, ingeniería, física y supervivencia.
  libros/      literatura (EPUB). libros/propios/ es para tus libros.
  mapas/       mapas .mwm de Organic Maps.
  software/    instaladores: .deb, AppImage, APK, ISO de Ubuntu, llama.cpp y modelo.
  personal/    carpeta libre para tus documentos.
  .arca/       estado interno (inventario zim.json, registro, errores).

INVENTARIO DE ZIM
-----------------
TXT
    if [[ -s $zim_json ]]; then
      jq -r 'to_entries[] | "\(.value.archivo)\t\(.value.fecha)\t\(.value.bytes)\t\(.value.sha256)"' "$zim_json" | sort \
        | while IFS=$'\t' read -r a f b s; do printf '  %-58s %-8s %10s  sha256:%.12s…\n' "$a" "$f" "$(human "$b")" "$s"; done
    else
      echo "  (sin ZIM registrados)"
    fi
    cat <<'TXT'

MANUALES Y LIBROS
-----------------
TXT
    find "$RESPALDO/manuales" "$RESPALDO/libros" -type f ! -name 'LEEME.txt' ! -name '*.part' 2>/dev/null | sort \
      | while read -r f; do printf '  %-70s %10s\n' "${f#"$RESPALDO"/}" "$(human "$(stat -c %s "$f")")"; done
    cat <<TXT

MAPAS (Organic Maps, versión $(cat "$RESPALDO/mapas/VERSION.txt" 2>/dev/null || echo '?'))
-----
TXT
    find "$RESPALDO/mapas" -name '*.mwm' 2>/dev/null | sort | while read -r f; do printf '  %-40s %10s\n' "$(basename "$f")" "$(human "$(stat -c %s "$f")")"; done
    cat <<'TXT'

SOFTWARE
--------
TXT
    if [[ -s $soft_json ]]; then
      jq -r 'to_entries[] | "  \(.key): \(.value.archivo // .value.version // "-") \(if .value.version and .value.archivo then "(" + .value.version + ")" else "" end)"' "$soft_json"
    fi
    echo "  software/deb/: $(find "$RESPALDO/software/deb" -name '*.deb' 2>/dev/null | wc -l) paquetes .deb para Ubuntu 24.04"
    cat <<'TXT'

CÓMO MONTAR ESTE DISCO EN OTRO PC (Linux)
-----------------------------------------
  sudo mkdir -p /srv/respaldo
  lsblk                                   # identifica el disco, p. ej. /dev/sdb1
  sudo mount /dev/sdb1 /srv/respaldo      # ext4 o exFAT se montan solos
En Windows/macOS un disco ext4 necesita un driver; exFAT se lee directamente.

CÓMO INSTALAR KIWIX SIN INTERNET
--------------------------------
Opción A (Ubuntu 24.04, paquetes .deb):
  cd /srv/respaldo/software/deb && sudo dpkg -i *.deb ; sudo apt-get -f install
Opción B (cualquier Linux x86_64, binario estático):
  tar xzf /srv/respaldo/software/kiwix/kiwix-tools_linux-x86_64-musl-*.tar.gz -C /tmp
  (dentro está kiwix-serve, kiwix-manage, kiwix-search)
Opción C (escritorio): software/kiwix/kiwix-desktop_x86_64_*.appimage (chmod +x y ejecutar).
Android: software/kiwix/*.apk (Kiwix) y software/organicmaps/*.apk (mapas).

CÓMO LANZAR KIWIX-SERVE A MANO
------------------------------
  kiwix-manage /srv/respaldo/library.xml add /srv/respaldo/zim/*.zim   # solo si no existe library.xml
  kiwix-serve --library /srv/respaldo/library.xml --port 8080 --address 0.0.0.0
Luego abre http://IP-DEL-PC:8080 desde cualquier navegador de la red.

CÓMO USAR EL MODELO DE LENGUAJE LOCAL
-------------------------------------
  /srv/respaldo/software/llm/preguntar.sh         # chat que busca en la biblioteca y cita fuentes
  /srv/respaldo/software/llm/chat.sh              # chat libre en la terminal (CPU, ~5 GB RAM)
  /srv/respaldo/software/llm/chat.sh --server     # API HTTP en http://IP:8081 (interfaz web incluida)
Cómo construir una IA desde cero: /srv/respaldo/software/ia/LEEME.md
Si el binario no funciona en otro PC, recompila: cd software/llm/llama.cpp && cmake -B build && cmake --build build -j

CÓMO RESTAURAR TODO EN UN PC NUEVO
----------------------------------
Con internet:
  curl -fsSL https://raw.githubusercontent.com/felipevidela/civilization_backup/main/install.sh | sudo bash
Sin internet (desde la copia local del repo):
  sudo git clone /srv/respaldo/software/arca.git /opt/arca
  sudo /opt/arca/setup.sh --from 7     # regenera library.xml, servicio, sistema y README
  (las fases 3-6 necesitan internet; con el disco ya lleno se saltan solas al detectar los archivos)

MÁS AYUDA
---------
  sudo /opt/arca/check.sh      estado, inventario y versiones disponibles
  sudo /opt/arca/update.sh     actualizar (también corre solo cada mes)
  sudo /opt/arca/backup.sh /ruta/al/disco/externo
  Errores pendientes: /srv/respaldo/.arca/failed.txt
TXT
  } > "$salida.tmp"
  mv "$salida.tmp" "$salida"
}
