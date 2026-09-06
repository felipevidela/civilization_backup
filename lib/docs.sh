# shellcheck shell=bash
# lib/docs.sh — documentación independiente del software: START_HERE (TXT ES/EN y HTML),
# copia de docs/ al disco y carpeta bootstrap/ con lo mínimo para volver a abrir el archivo.
# Requiere lib/log.sh, lib/space.sh, lib/profiles.sh cargados y RESPALDO/ARCA_DIR definidos.

_docs_inventario_breve() {
  local zims manuales mapas
  zims=$(find "$RESPALDO/zim" -maxdepth 1 -name '*.zim' 2>/dev/null | wc -l)
  manuales=$(find "$RESPALDO/manuales" "$RESPALDO/libros" -type f \( -name '*.pdf' -o -name '*.epub' -o -name '*.zip' \) 2>/dev/null | wc -l)
  mapas=$(find "$RESPALDO/mapas" -name '*.mwm' 2>/dev/null | wc -l)
  printf '%s|%s|%s' "$zims" "$manuales" "$mapas"
}

docs_start_here_es() {
  local inv; inv=$(_docs_inventario_breve)
  cat <<TXT
================================================================================
  ARCA — ARCHIVO DE RECUPERACIÓN DE LA CIVILIZACIÓN
  Perfil: ${ARCA_PERFIL:-?}   Generado: $(date '+%Y-%m-%d')   Total: $(du -sh "$RESPALDO" 2>/dev/null | awk '{print $1}')
  Versión en inglés: START_HERE_EN.txt
================================================================================

Este archivo está en texto plano a propósito: se puede leer con cualquier computador,
en cualquier sistema, sin programas especiales. Empieza aquí.

1. QUÉ ES ARCA
   Una biblioteca fuera de línea que reúne el conocimiento práctico para pasar de la
   supervivencia a una sociedad técnica: medicina, agua y saneamiento, agricultura,
   manufactura, materiales, energía, electricidad, construcción, telecomunicaciones,
   ciencia, matemáticas, computación e instituciones. Inventario actual:
   ${inv%%|*} enciclopedias y colecciones (ZIM), $(cut -d'|' -f2 <<< "$inv") manuales y libros (PDF/EPUB), ${inv##*|} mapas.

2. CÓMO ESTÁ ORGANIZADO (carpetas en la raíz de este disco)
   zim/          Wikipedia y decenas de colecciones. Se leen con Kiwix (ver punto 4).
   manuales/     PDF por dominio: medicina/ (actual, austera, referencia, historica),
                 agua/, agricultura/, manufactura/, materiales/, energia/, electricidad/,
                 construccion/, telecomunicaciones/, industria/, instituciones/,
                 supervivencia/, ingenieria/, ia/. Cada carpeta tiene un LEEME.
   libros/       textos fundacionales, enciclopedias clásicas, libros de texto, literatura.
   referencia/   unidades, constantes, tabla periódica, roscas, cables, tuberías (TXT/CSV/PDF).
   mapas/        mapas .mwm (Organic Maps) y datos geográficos abiertos en mapas/mundo/.
   software/     instaladores, código fuente, modelo de lenguaje, kit de IA.
   docs/         TECH_TREE.md (árbol tecnológico), RECOVERY_ROADMAP.md (niveles de
                 recuperación), DIGITAL_FORMATS.md (cómo interpretar archivos), ARCHITECTURE.md.
   bootstrap/    lo mínimo para volver a abrir este archivo si todo lo demás falla.
   recovery/     paridad PAR2 para reparar el núcleo crítico.
   MANIFEST.tsv  lista de todos los archivos con tamaño, sha256, origen, licencia y prioridad.
   README.txt    inventario detallado con versiones y fechas.

3. CÓMO MONTAR ESTE DISCO
   Linux:   sudo mkdir -p /srv/respaldo && lsblk && sudo mount /dev/sdX1 /srv/respaldo
   Windows: ext4 necesita un driver (por ejemplo "Ext2Fsd" o WSL); exFAT se abre directo.
   macOS:   exFAT se abre directo; ext4 necesita software adicional.
   Si no puedes montar nada, arranca un Linux desde software/iso/ (ver punto 6).

4. CÓMO ACCEDER A LOS CONTENIDOS
   a) Con el servidor instalado: abre http://IP-DEL-PC:8080 desde cualquier navegador de la
      red (la IP aparece al iniciar sesión en el PC). Busca en todas las enciclopedias a la vez.
   b) Sin servidor, en cualquier PC con Linux:
        tar xzf software/kiwix/kiwix-tools_linux-x86_64-musl-*.tar.gz -C /tmp
        /tmp/kiwix-tools_*/kiwix-serve --port 8080 zim/*.zim
      y abre http://localhost:8080.
   c) Windows/Linux de escritorio: software/kiwix/kiwix-desktop_*.appimage (Linux) o el
      instalador de Kiwix para Windows si lo tienes; abre los .zim desde el programa.
   d) Android: instala software/kiwix/*.apk y abre los .zim (los pequeños caben en el teléfono).
   e) PDF, TXT, CSV y EPUB se abren con cualquier lector; no necesitan Kiwix.

5. CÓMO VERIFICAR LA INTEGRIDAD
   MANIFEST.tsv lista cada archivo con su sha256. Para comprobar uno:
        sha256sum zim/wikipedia_es_all_maxi_2026-05.zim
   y compara con la columna sha256. Con el sistema instalado: sudo /opt/arca/check.sh --scrub
   comprueba todo y deja el informe en .arca/scrub-FECHA.log. bootstrap/SHA256SUMS cubre el
   núcleo mínimo: sha256sum -c bootstrap/SHA256SUMS. Si algo del núcleo está dañado,
   recovery/ contiene paridad PAR2: par2 verify -B /srv/respaldo recovery/bootstrap.par2
   y par2 repair para arreglarlo (programa "par2", incluido en software/deb/).

6. CÓMO RESTAURAR EL SISTEMA COMPLETO
   a) Instala Ubuntu 24.04 desde software/iso/ubuntu-24.04.*.iso (grábala en un USB).
   b) Monta este disco en /srv/respaldo.
   c) Instala Kiwix y utilidades sin internet: cd software/deb && sudo dpkg -i *.deb
   d) Recupera los scripts: tar xf bootstrap/arca-src.tar -C /opt   (deja /opt/arca)
      o sudo git clone software/arca.git /opt/arca
   e) sudo /opt/arca/setup.sh --profile ${ARCA_PERFIL:-full} --from 7
      Regenera la biblioteca, el servicio en el puerto 8080, el buscador local y estas guías.
      Las descargas (fases 3-6) se saltan solas porque los archivos ya están.

7. CÓMO NAVEGAR A MANO POR LAS CARPETAS
   Cada carpeta de manuales/ y libros/ tiene un LEEME que dice qué archivo leer primero y
   por qué importa. docs/RECOVERY_ROADMAP.md ordena todo por niveles (agua → comida →
   talleres → industria → electricidad → computación). docs/TECH_TREE.md muestra qué
   depende de qué. Para buscar una palabra en todos los PDF sin el sistema instalado:
        grep -ril "filtro lento de arena" manuales/     (solo PDF con capa de texto)
   Con el sistema: arca-search "filtro lento de arena".

8. SI KIWIX FALLA
   - El servicio: sudo systemctl restart kiwix ; journalctl -u kiwix
   - Regenerar la biblioteca: sudo /opt/arca/setup.sh --only 7
   - Sin nada instalado: usa el binario estático del punto 4b (no depende de Ubuntu).
   - Un .zim es un solo archivo; se puede copiar a otro PC o teléfono y abrirlo allí.
   - Si un .zim está corrupto (check.sh --scrub lo dirá), vuelve a descargarlo con
     update.sh o desde una copia de seguridad; los manuales PDF no dependen de Kiwix.

9. SI LA INTELIGENCIA ARTIFICIAL FALLA
   No es necesaria para nada: todo el conocimiento está en los ZIM y PDF. Para volver a
   probarla: software/llm/preguntar.sh --rapido (modelo pequeño, menos RAM). Si el binario
   no arranca en otro PC, recompila: cd software/llm/llama.cpp && cmake -B build &&
   cmake --build build -j. Requisitos: 3 GB de RAM libres (modelo pequeño) u 6 GB (grande).

================================================================================
  ÍNDICE CIVILIZATORIO — por dónde empezar según la situación
================================================================================
  00 — START HERE ............ este archivo; docs/RECOVERY_ROADMAP.md para el orden general
  01 — Primeras 72 horas ..... agua (hervir/clorar): manuales/agua/ · heridas y primeros
                               auxilios: manuales/supervivencia/fm-4-25.11-first-aid.pdf ·
                               refugio y señales: manuales/supervivencia/
  02 — Primer mes ............ letrinas y saneamiento: manuales/agua/ · higiene y
                               enfermedades: manuales/medicina/austera/ (Donde no hay doctor)
                               y manuales/medicina/actual/ (MSF) · conservar comida:
                               manuales/agricultura/
  03 — Primer año ............ sembrar: manuales/agricultura/ y Appropedia (Kiwix) · taller:
                               manuales/manufactura/ · escuela: libros/openstax-es/, Vikidia
  04 — Alimentos y agricultura manuales/agricultura/ · FAO · Stack Exchange gardening (Kiwix)
  05 — Agua y saneamiento .... manuales/agua/ · OMS y MSF · zimgit water (Kiwix)
  06 — Medicina .............. manuales/medicina/ (actual/ para tratar; austera/ sin recursos;
                               referencia/ anatomía; historica/ solo historia) · Wikipedia
                               médica (Kiwix)
  07 — Talleres y herramientas manuales/manufactura/ (metrología, torno, soldadura, forja) ·
                               referencia/ (roscas, tolerancias) · iFixit (Kiwix)
  08 — Electricidad .......... manuales/electricidad/ y manuales/energia/ · Stack Exchange
                               electronics (Kiwix)
  09 — Industria ............. manuales/materiales/ (hierro, acero, cemento, vidrio) ·
                               manuales/industria/ (química civil) · manuales/construccion/
  10 — Educación ............. libros/openstax-*/ · LibreTexts, Wikibooks, Wikiversity, Khan
                               Academy, CrashCourse (Kiwix) · libros/fundacionales/
  11 — Computación ........... software/source/ (código fuente) · docs/DIGITAL_FORMATS.md ·
                               DevDocs y Stack Exchange técnicos (Kiwix) · software/ia/
TXT
}

docs_start_here_en() {
  local inv; inv=$(_docs_inventario_breve)
  cat <<TXT
================================================================================
  ARCA — CIVILIZATION RECOVERY ARCHIVE
  Profile: ${ARCA_PERFIL:-?}   Generated: $(date '+%Y-%m-%d')   Total: $(du -sh "$RESPALDO" 2>/dev/null | awk '{print $1}')
  Spanish version: START_HERE_ES.txt
================================================================================

This file is deliberately plain text: any computer, any system, no special software.
Start here.

1. WHAT ARCA IS
   An offline library with the practical knowledge needed to go from survival to a
   technical society: medicine, water and sanitation, agriculture, manufacturing,
   materials, energy, electricity, construction, telecommunications, science, mathematics,
   computing and institutions. Current inventory: ${inv%%|*} encyclopedias and collections
   (ZIM), $(cut -d'|' -f2 <<< "$inv") manuals and books (PDF/EPUB), ${inv##*|} maps.

2. HOW IT IS ORGANIZED (folders at the root of this disk)
   zim/          Wikipedia and dozens of collections, read with Kiwix (see 4).
   manuales/     PDFs by domain: medicina/ (actual=current, austera=low-resource,
                 referencia, historica), agua/ (water), agricultura/, manufactura/,
                 materiales/, energia/, electricidad/, construccion/, telecomunicaciones/,
                 industria/, instituciones/, supervivencia/, ingenieria/, ia/. Each has a LEEME.
   libros/       foundational texts, classic encyclopedias, textbooks, literature.
   referencia/   units, constants, periodic table, threads, wire and pipe tables (TXT/CSV/PDF).
   mapas/        .mwm maps (Organic Maps) and open geographic data in mapas/mundo/.
   software/     installers, source code, language model, AI kit.
   docs/         TECH_TREE.md, RECOVERY_ROADMAP.md, DIGITAL_FORMATS.md, ARCHITECTURE.md.
   bootstrap/    the minimum needed to reopen this archive if everything else fails.
   recovery/     PAR2 parity to repair the critical core.
   MANIFEST.tsv  every file with size, sha256, source, license and priority.
   README.txt    detailed inventory with versions and dates. (Most guides are in Spanish;
                 Wikipedia, LibreTexts and the technical Stack Exchanges are in English.)

3. HOW TO MOUNT THIS DISK
   Linux:   sudo mkdir -p /srv/respaldo && lsblk && sudo mount /dev/sdX1 /srv/respaldo
   Windows: ext4 needs a driver (e.g. WSL); exFAT opens directly.
   macOS:   exFAT opens directly; ext4 needs extra software.
   If nothing mounts, boot Linux from software/iso/ (see 6).

4. HOW TO ACCESS THE CONTENT
   a) With the server installed: open http://PC-IP:8080 from any browser on the network.
   b) Without the server, on any Linux PC:
        tar xzf software/kiwix/kiwix-tools_linux-x86_64-musl-*.tar.gz -C /tmp
        /tmp/kiwix-tools_*/kiwix-serve --port 8080 zim/*.zim   → http://localhost:8080
   c) Desktop: software/kiwix/kiwix-desktop_*.appimage (Linux) opens .zim files directly.
   d) Android: install software/kiwix/*.apk and open the .zim files.
   e) PDF, TXT, CSV and EPUB open with any reader; no Kiwix needed.

5. HOW TO VERIFY INTEGRITY
   MANIFEST.tsv lists every file with its sha256:  sha256sum zim/<file>.zim  and compare.
   With the system installed: sudo /opt/arca/check.sh --scrub (report in .arca/scrub-DATE.log).
   bootstrap/SHA256SUMS covers the minimal core: sha256sum -c bootstrap/SHA256SUMS.
   recovery/ holds PAR2 parity for the core: par2 verify -B /srv/respaldo recovery/bootstrap.par2
   then par2 repair (the "par2" program is in software/deb/).

6. HOW TO RESTORE THE WHOLE SYSTEM
   a) Install Ubuntu 24.04 from software/iso/ubuntu-24.04.*.iso (write it to a USB stick).
   b) Mount this disk at /srv/respaldo.
   c) Install Kiwix and tools offline: cd software/deb && sudo dpkg -i *.deb
   d) Restore the scripts: tar xf bootstrap/arca-src.tar -C /opt  (creates /opt/arca)
      or sudo git clone software/arca.git /opt/arca
   e) sudo /opt/arca/setup.sh --profile ${ARCA_PERFIL:-full} --from 7
      Rebuilds the library, the port-8080 service, the local search index and these guides.
      Download phases (3-6) skip themselves because the files already exist.

7. HOW TO BROWSE THE FOLDERS BY HAND
   Every manuales/ and libros/ folder has a LEEME (read-me) saying what to read first and
   why. docs/RECOVERY_ROADMAP.md orders everything by level (water → food → workshops →
   industry → electricity → computing). docs/TECH_TREE.md shows what depends on what.
   To search a word across PDFs without the system: grep -ril "slow sand filter" manuales/
   With the system: arca-search "slow sand filter".

8. IF KIWIX FAILS
   - Service: sudo systemctl restart kiwix ; journalctl -u kiwix
   - Rebuild the library: sudo /opt/arca/setup.sh --only 7
   - Nothing installed: use the static binary from 4b (independent of Ubuntu).
   - A .zim is a single file: copy it to another PC or phone and open it there.
   - If a .zim is corrupt (check.sh --scrub reports it) re-download it with update.sh or
     restore it from a backup; the PDF manuals never depend on Kiwix.

9. IF THE AI FAILS
   It is not required for anything: all knowledge is in the ZIMs and PDFs. To retry:
   software/llm/preguntar.sh --rapido (small model, less RAM). If the binary does not run
   on another PC, rebuild: cd software/llm/llama.cpp && cmake -B build && cmake --build build -j
   Needs 3 GB of free RAM (small model) or 6 GB (large).

================================================================================
  CIVILIZATION INDEX — where to start depending on the situation
================================================================================
  00 — START HERE ............ this file; docs/RECOVERY_ROADMAP.md for the overall order
  01 — First 72 hours ........ water (boil/chlorinate): manuales/agua/ · wounds and first
                               aid: manuales/supervivencia/fm-4-25.11-first-aid.pdf ·
                               shelter and signals: manuales/supervivencia/
  02 — First month ........... latrines and sanitation: manuales/agua/ · hygiene and
                               disease: manuales/medicina/austera/ (Where There Is No Doctor)
                               and manuales/medicina/actual/ (MSF) · preserving food:
                               manuales/agricultura/
  03 — First year ............ planting: manuales/agricultura/ and Appropedia (Kiwix) ·
                               workshop: manuales/manufactura/ · school: libros/openstax-*/
  04 — Food and agriculture .. manuales/agricultura/ · FAO · Stack Exchange gardening (Kiwix)
  05 — Water and sanitation .. manuales/agua/ · WHO and MSF · zimgit water (Kiwix)
  06 — Medicine .............. manuales/medicina/ (actual/ to treat; austera/ without
                               resources; referencia/ anatomy; historica/ history only) ·
                               medical Wikipedia (Kiwix)
  07 — Workshops and tools ... manuales/manufactura/ (metrology, lathe, welding, forging) ·
                               referencia/ (threads, tolerances) · iFixit (Kiwix)
  08 — Electricity ........... manuales/electricidad/ and manuales/energia/ · Stack Exchange
                               electronics (Kiwix)
  09 — Industry .............. manuales/materiales/ (iron, steel, cement, glass) ·
                               manuales/industria/ (civil chemistry) · manuales/construccion/
  10 — Education ............. libros/openstax-*/ · LibreTexts, Wikibooks, Wikiversity, Khan
                               Academy, CrashCourse (Kiwix) · libros/fundacionales/
  11 — Computing ............. software/source/ (source code) · docs/DIGITAL_FORMATS.md ·
                               DevDocs and technical Stack Exchanges (Kiwix) · software/ia/
TXT
}

# Genera START_HERE*.txt, START_HERE.html y copia docs/ al disco.
docs_generar() {
  docs_start_here_es > "$RESPALDO/START_HERE_ES.txt"
  docs_start_here_en > "$RESPALDO/START_HERE_EN.txt"
  {
    echo "ARCA — Civilization Recovery Archive / Archivo de recuperación de la civilización"
    echo
    echo "Español: START_HERE_ES.txt        English: START_HERE_EN.txt        Navegador: START_HERE.html"
    echo
    cat "$RESPALDO/START_HERE_ES.txt"
  } > "$RESPALDO/START_HERE.txt"
  {
    echo '<!DOCTYPE html><html lang="es"><head><meta charset="utf-8"><title>ARCA — START HERE</title>'
    echo '<style>body{font-family:sans-serif;max-width:60em;margin:2em auto;padding:0 1em;line-height:1.4}pre{white-space:pre-wrap;font-family:monospace;background:#f6f6f6;padding:1em;border:1px solid #ddd}nav a{margin-right:1.5em}</style></head><body>'
    echo '<h1>ARCA — Civilization Recovery Archive</h1>'
    echo '<nav><a href="#es">Español</a><a href="#en">English</a><a href="docs/TECH_TREE.md">TECH_TREE.md</a><a href="docs/RECOVERY_ROADMAP.md">RECOVERY_ROADMAP.md</a><a href="MANIFEST.tsv">MANIFEST.tsv</a><a href="http://localhost:8080">Kiwix (localhost:8080)</a></nav>'
    echo '<h2 id="es">Español</h2><pre>'; sed 's/&/\&amp;/g; s/</\&lt;/g' "$RESPALDO/START_HERE_ES.txt"; echo '</pre>'
    echo '<h2 id="en">English</h2><pre>'; sed 's/&/\&amp;/g; s/</\&lt;/g' "$RESPALDO/START_HERE_EN.txt"; echo '</pre>'
    echo '</body></html>'
  } > "$RESPALDO/START_HERE.html"
  mkdir -p "$RESPALDO/docs"
  cp "$ARCA_DIR"/docs/*.md "$RESPALDO/docs/"
  chown_respaldo "$RESPALDO"/START_HERE* "$RESPALDO/docs"
}

# bootstrap/: lo mínimo para volver a abrir el archivo. Usa hardlinks cuando puede (mismo
# sistema de archivos) para no duplicar espacio.
bootstrap_generar() {
  local b="$RESPALDO/bootstrap" f
  mkdir -p "$b/docs"
  cp "$RESPALDO"/START_HERE*.txt "$RESPALDO/START_HERE.html" "$b/" 2>/dev/null || true
  cp "$ARCA_DIR"/docs/*.md "$b/docs/"
  [[ -s $MANIFEST_OUT ]] && cp "$MANIFEST_OUT" "$b/MANIFEST.tsv"
  # Código fuente de ARCA (sin .git ni logs).
  tar --transform "s#^$(basename "$ARCA_DIR")#arca#" -C "$(dirname "$ARCA_DIR")" --exclude='.git' --exclude='logs' \
    -cf "$b/arca-src.tar" "$(basename "$ARCA_DIR")" 2>/dev/null || log_warn "No se pudo empaquetar el código de ARCA en bootstrap/".
  # Kiwix estático y paquetes mínimos (hardlink o copia).
  for f in "$RESPALDO"/software/kiwix/kiwix-tools_linux-*.tar.gz; do
    [[ -f $f ]] && { ln -f "$f" "$b/$(basename "$f")" 2>/dev/null || cp "$f" "$b/"; }
  done
  mkdir -p "$b/deb"
  for f in "$RESPALDO"/software/deb/kiwix-tools_*.deb "$RESPALDO"/software/deb/par2_*.deb "$RESPALDO"/software/deb/libzim*.deb "$RESPALDO"/software/deb/libkiwix*.deb; do
    [[ -f $f ]] && { ln -f "$f" "$b/deb/$(basename "$f")" 2>/dev/null || cp "$f" "$b/deb/"; }
  done
  local iso; iso=$(find "$RESPALDO/software/iso" -name '*.iso' 2>/dev/null | head -1)
  cat > "$b/RESTAURAR.txt" <<TXT
BOOTSTRAP DE ARCA — lo mínimo para volver a abrir el archivo
Generado: $(date -Is)   Perfil: ${ARCA_PERFIL:-?}

Contenido de esta carpeta:
  START_HERE*.txt / .html   guías de inicio (español e inglés)
  docs/                     TECH_TREE, RECOVERY_ROADMAP, DIGITAL_FORMATS, ARCHITECTURE, CONTENT_POLICY
  MANIFEST.tsv              lista de todos los archivos del disco con sha256
  arca-src.tar              código fuente de ARCA (tar xf arca-src.tar -C /opt → /opt/arca)
  kiwix-tools_*.tar.gz      kiwix-serve estático para Linux x86_64 (no necesita instalar nada)
  deb/                      paquetes kiwix-tools y par2 para Ubuntu 24.04
  SHA256SUMS                hashes de esta carpeta: sha256sum -c SHA256SUMS

Ubuntu para reinstalar el sistema: ${iso:-(no incluida en este perfil; cualquier Ubuntu 24.04 sirve)}
$( [[ -n $iso ]] && echo "  sha256: $(json_get "$SOFTWARE_JSON" ubuntu_iso sha256 2>/dev/null || echo unknown)" )

Pasos mínimos para leer el archivo en un PC Linux cualquiera:
  1. Monta el disco:      sudo mount /dev/sdX1 /srv/respaldo
  2. Descomprime Kiwix:   tar xzf /srv/respaldo/bootstrap/kiwix-tools_*.tar.gz -C /tmp
  3. Sirve los ZIM:       /tmp/kiwix-tools_*/kiwix-serve --port 8080 /srv/respaldo/zim/*.zim
  4. Abre http://localhost:8080 en un navegador. Los PDF se abren con cualquier lector.
Para restaurar el sistema completo sigue START_HERE_ES.txt, punto 6.
TXT
  (cd "$b" && find . -type f ! -name 'SHA256SUMS*' -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS.tmp && mv SHA256SUMS.tmp SHA256SUMS)
  chown_respaldo "$b"
}

# Copia los LEEME por dominio (docs/leeme/*.md) a sus carpetas y genera referencia/tablas-basicas.txt.
leemes_instalar() {
  local f nombre destino
  for f in "$ARCA_DIR"/docs/leeme/*.md; do
    nombre=$(basename "$f" .md)
    case $nombre in
      medicina-historica) destino="$RESPALDO/manuales/medicina/historica" ;;
      referencia) destino="$RESPALDO/referencia" ;;
      mapas) destino="$RESPALDO/mapas" ;;
      codigo) destino="$RESPALDO/software/source" ;;
      *) destino="$RESPALDO/manuales/$nombre" ;;
    esac
    [[ -d $destino ]] || continue
    cp "$f" "$destino/LEEME.md"
  done
  [[ -d "$RESPALDO/libros/fundacionales" ]] && cp "$ARCA_DIR/docs/fundacionales.md" "$RESPALDO/libros/fundacionales/LEEME.md"
  [[ -d "$RESPALDO/referencia" ]] && referencia_tablas > "$RESPALDO/referencia/tablas-basicas.txt"
  # SOURCES.tsv: versión, origen, licencia y sha256 de cada tarball de código fuente (desde el registro del manifiesto).
  if [[ -d "$RESPALDO/software/source" && -s $MANIFEST_REG ]]; then
    { printf 'path\tversion\tsource\tlicense\tsha256\tsize\n'
      awk -F'\t' 'NR>1 && $1 ~ /^software\/source\// {print $1"\t"$5"\t"$4"\t"$8"\t"$3"\t"$2}' "$MANIFEST_REG" | sort; } > "$RESPALDO/software/source/SOURCES.tsv"
  fi
  return 0
}

# Tablas de referencia derivadas de definiciones exactas y fórmulas normalizadas (sin medidas).
referencia_tablas() {
  cat <<'TXT'
TABLAS BÁSICAS DE REFERENCIA (generadas por ARCA a partir de definiciones y fórmulas oficiales)

PREFIJOS SI
  quetta Q 1e30   ronna R 1e27   yotta Y 1e24   zetta Z 1e21   exa E 1e18   peta P 1e15
  tera T 1e12     giga G 1e9     mega M 1e6     kilo k 1e3     hecto h 1e2  deca da 1e1
  deci d 1e-1     centi c 1e-2   mili m 1e-3    micro µ 1e-6   nano n 1e-9  pico p 1e-12
  femto f 1e-15   atto a 1e-18   zepto z 1e-21  yocto y 1e-24  ronto r 1e-27 quecto q 1e-30

UNIDADES BASE SI (definiciones de 2019, ver bipm-si-brochure-9-en.pdf)
  segundo s (frecuencia del cesio-133: 9 192 631 770 Hz)   metro m (c = 299 792 458 m/s)
  kilogramo kg (h = 6.626 070 15e-34 J s)   amperio A (e = 1.602 176 634e-19 C)
  kelvin K (k = 1.380 649e-23 J/K)   mol (N_A = 6.022 140 76e23 1/mol)   candela cd (K_cd = 683 lm/W)

CONVERSIONES EXACTAS (por definición)
  1 pulgada = 25.4 mm          1 pie = 0.3048 m           1 yarda = 0.9144 m       1 milla = 1609.344 m
  1 libra (lb) = 0.453 592 37 kg   1 onza = 28.349 523 125 g   1 galón US = 3.785 411 784 L   1 galón UK = 4.546 09 L
  1 atm = 101 325 Pa           1 bar = 100 000 Pa          1 psi = 6 894.757 293 168 Pa (exacto: 4.448 221 615 260 5 N / (0.0254 m)^2)
  1 caloría (termoquímica) = 4.184 J   1 BTU (IT) = 1 055.055 852 62 J   1 kWh = 3 600 000 J   1 hp (mecánico) = 745.699 871 582 27 W
  °C = K - 273.15              °F = °C × 9/5 + 32          1 acre = 4 046.856 422 4 m²   1 hectárea = 10 000 m²

CALIBRES DE ALAMBRE AWG (ASTM B258): diámetro d_mm = 0.127 × 92^((36 − n)/39); sección = π d²/4
  AWG   diám (mm)   sección (mm²)
TXT
  local n
  for n in 0000 000 00 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 22 24 26 28 30; do
    awk -v n="$n" 'BEGIN{ m=n; if(n=="0000")m=-3; else if(n=="000")m=-2; else if(n=="00")m=-1; d=0.127*92^((36-m)/39); printf "  %-5s %9.3f   %9.3f\n", n, d, 3.14159265*d*d/4 }'
  done
  cat <<'TXT'

ROSCAS MÉTRICAS ISO, PASO GRUESO (ISO 261): designación M d × paso (mm)
  M1 0.25  M1.2 0.25  M1.6 0.35  M2 0.4   M2.5 0.45  M3 0.5   M4 0.7   M5 0.8   M6 1.0   M8 1.25
  M10 1.5  M12 1.75   M14 2.0   M16 2.0  M20 2.5   M24 3.0  M30 3.5  M36 4.0  M42 4.5  M48 5.0
  Broca para machuelo (aprox.): d − paso   (ej. M8×1.25 → broca de 6.8 mm; M10×1.5 → 8.5 mm)
  Ángulo del filete: 60°. Altura básica del filete H = 0.866 × paso.

VELOCIDAD DE CORTE (orientativa; ver Machinery Repairman y Machinery's Handbook)
  rpm = (velocidad de corte m/min × 1000) / (π × diámetro mm)
  Herramienta de acero rápido: acero suave 25-30 m/min · fundición 20 m/min · aluminio 90+ m/min · latón 60 m/min

AGUA
  Densidad ≈ 1000 kg/m³ (4 °C) · calor específico 4.18 kJ/(kg·K) · ebullición 100 °C a 101.325 kPa
  Presión hidrostática: 10 m de columna de agua ≈ 98 kPa ≈ 1 bar ≈ 14.2 psi
  Cloración de emergencia (OMS, ver manuales/agua/): objetivo 0.5 mg/L de cloro libre residual tras 30 min

TXT
}

# docs/SOURCES_AND_LICENSES.md en el disco: procedencia y licencias agrupadas, desde el manifiesto.
sources_licenses_generar() {
  local salida="$RESPALDO/docs/SOURCES_AND_LICENSES.md" origen="${MANIFEST_REG:-$MANIFEST_OUT}"
  [[ -s $origen ]] || return 0
  mkdir -p "$RESPALDO/docs"
  {
    echo "# Fuentes y licencias del contenido instalado"
    echo
    echo "Generado por ARCA el $(date '+%Y-%m-%d') a partir del registro del manifiesto (perfil ${ARCA_PERFIL:-?})."
    echo "Cada archivo conserva la licencia de su autor u organismo; 'unknown' significa que ARCA no pudo"
    echo "confirmarla (consulta el propio documento). Wikipedia y proyectos Wikimedia: CC BY-SA 4.0;"
    echo "archive.org: dominio público salvo indicación; OMS y FAO: CC BY-NC-SA 3.0 IGO; gobierno de"
    echo "EE. UU. (USDA, USGS, NASA, ejército, marina, FEMA, NIST): dominio público."
    echo
    echo "## Resumen por licencia"
    echo
    echo "| Licencia | Archivos | Tamaño |"
    echo "|---|---|---|"
    awk -F'\t' 'NR>1 && $12!="missing" {n[$8]++; b[$8]+=$2} END{for (l in n) printf "%s\t%d\t%d\n", l, n[l], b[l]}' "$origen" \
      | sort -t$'\t' -k3,3rn | while IFS=$'\t' read -r l n b; do printf '| %s | %d | %s |\n' "$l" "$n" "$(human "$b")"; done
    echo
    echo "## Resumen por origen"
    echo
    echo "| Origen (dominio) | Archivos |"
    echo "|---|---|"
    awk -F'\t' 'NR>1 && $12!="missing" {s=$4; sub(/^[a-z]+:\/\//,"",s); sub(/\/.*/,"",s); n[s]++} END{for (o in n) printf "%s\t%d\n", o, n[o]}' "$origen" \
      | sort -t$'\t' -k2,2rn | head -40 | while IFS=$'\t' read -r o n; do printf '| %s | %d |\n' "$o" "$n"; done
    echo
    echo "## Detalle"
    echo
    echo "La lista completa (ruta, tamaño, sha256, origen, versión, fecha, idioma, licencia, prioridad,"
    echo "categoría, perfil, estado) está en \`MANIFEST.tsv\` en la raíz del disco; se abre con cualquier"
    echo "editor de texto u hoja de cálculo."
  } > "$salida.tmp"
  mv "$salida.tmp" "$salida"
}
