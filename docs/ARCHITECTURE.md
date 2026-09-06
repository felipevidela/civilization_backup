# Arquitectura de ARCA

## Visión

ARCA es un conjunto de scripts Bash (más dos programas Python de biblioteca estándar) que
construyen y mantienen un archivo de conocimiento fuera de línea en `/srv/respaldo`. No hay
servicios en la nube ni bases de datos externas: el estado son archivos de texto y JSON en
`/srv/respaldo/.arca/`, el índice de búsqueda es un SQLite, y todo se puede regenerar.

La misión manda sobre el diseño: el objetivo son **quince años sin red para un grupo local**, no
recuperar la tecnología de 2026. De ahí tres decisiones que atraviesan todo el código:

1. **El print-kit es parte del producto, no documentación.** La fase 10 copia `printkit/` al
   disco y a `bootstrap/`, y `check.sh` avisa si falta. El papel es la única copia que no
   depende de que el PC arranque.
2. **El disco es perecible.** El manifiesto con sha256, el scrub, la paridad PAR2 y los dos
   modos de copia existen porque el soporte falla en 5 a 8 años, no por prolijidad.
3. **El asistente es un índice.** Los modos `SOURCE_ONLY` en medicina, agua y química existen
   para que nadie tome una dosis inventada por un modelo de 3B.

```
install.sh ──► clona /opt/arca ──► setup.sh --profile P ──► fases 0..11 (lib/phases.sh)
                                        │
   packs.conf  manuals.conf  software.conf   (qué; con perfil, prioridad, categoría, licencia)
        │            │            │
   lib/kiwix.sh  lib/fetch.sh  lib/phases.sh  (cómo: torrent/HTTP, sha256, esquemas ia://, ocw://,
                                              openstax://, github://, kernel://, mirror://)
        │
   /srv/respaldo/{zim,manuales,libros,referencia,mapas,software,docs,bootstrap,recovery}
        │
   lib/manifest.sh ──► MANIFEST.tsv ──► check.sh --scrub · repair.sh (PAR2) · backup.sh
   lib/docs.sh     ──► START_HERE, docs/, bootstrap/, LEEME por carpeta, referencia/tablas
   lib/arca_index.py ─► .arca/search.db ──► arca-search · llm/preguntar.py (+ kiwix-serve)
```

## Fases (`lib/phases.sh`, orquestadas por `setup.sh`)

| Fase | Función | Idempotencia |
|---|---|---|
| 0 | `fase_0`: distro, root, `SUDO_USER`, red, montaje de `/srv/respaldo`, estimación de espacio del perfil con tamaños reales (listado de Kiwix, HEAD/Range, APIs) + `MARGEN_ESPACIO_PCT` | no marca si falla |
| 1 | carpetas, `chown`, `tune2fs -m 1` en ext4 | sí |
| 2 | apt (kiwix-tools, zim-tools, aria2, par2, poppler-utils, sqlite3, python3, calibre…) y Flatpak | sí |
| 3 | ZIM: resolver versión, descargar (torrent → HTTP), sha256, borrar versión anterior, `zim.json`; 3 en paralelo | salta los verificados |
| 4 | manuales y libros por esquema; migración de rutas antiguas; LEEME por carpeta; `referencia/tablas-basicas.txt`; `manuals.json`; `failed.txt` | salta los existentes |
| 5 | mapas Organic Maps (`countries.json` + `meta.omaps.app`) incluidos `World` y `WorldCoasts` | por tamaño y versión |
| 6 | software: .deb con dependencias, kiwix estático/AppImage/APK, Organic Maps APK, ISO, llama.cpp + modelos GGUF, `chat.sh`, `preguntar.sh`, kit IA, espejo del repo | por versión en `software.json` |
| 7 | `library.xml`, `kiwix.service` (puerto 8080), comprobación HTTP | regenera |
| 8 | sin suspensión, tapa del portátil, motd, ufw | sí |
| 9 | `arca-update.timer` mensual | sí |
| 10 | README.txt, START_HERE (ES/EN/HTML), docs/, manifiesto (`manifest_rebuild` + `manifest_generate`), `bootstrap/`, PAR2 (`repair.sh --create`), índice de búsqueda, `SOURCES.tsv` | regenera (hashea solo lo nuevo) |
| 11 | resumen en pantalla | siempre |

Las fases 0-9 se anotan en `.arca/state` (`fase_N OK fecha`); `--from N` borra marcas desde N,
`--only N` ejecuta una. Un fallo de un recurso no detiene la fase: va a `.arca/failed.txt` y se
reintenta en la siguiente ejecución. `update.sh` reutiliza las fases 3, 4 (solo si cambió el
tamaño remoto), 5, 6 (solo con release nueva), 7 y 10.

## Sistema de archivos

```
/srv/respaldo/
  START_HERE.txt, START_HERE_ES.txt, START_HERE_EN.txt, START_HERE.html, README.txt, MANIFEST.tsv
  zim/            *.zim (Kiwix)                 library.xml en la raíz
  manuales/       medicina/{actual,austera,referencia,historica}, agua, agricultura, manufactura,
                  materiales, industria, energia, electricidad, telecomunicaciones, construccion,
                  instituciones, supervivencia, ingenieria, fisica, ia  (cada una con LEEME.md)
  libros/         fundacionales, britannica-1911, harvard-classics, biblioteca-autores-espanoles,
                  openstax-es, openstax-en, propios
  referencia/     constantes, tabla periódica, SI, tablas-basicas.txt
  mapas/          *.mwm (Organic Maps), mundo/ (Natural Earth)
  software/       deb, kiwix, organicmaps, iso, llm/{llama.cpp,modelos,chat.sh,preguntar.sh},
                  ia/{codigo,wheels,LEEME.md}, source/ (tarballs + SOURCES.tsv), arca.git
  docs/           copia de docs/ del repo (TECH_TREE, RECOVERY_ROADMAP, DIGITAL_FORMATS, ...)
  bootstrap/      mínimo para reabrir el archivo (guías, MANIFEST, arca-src.tar, kiwix estático, .deb, SHA256SUMS)
  recovery/       paridad PAR2 (10 %) de bootstrap, docs, referencia y manuales P0
  personal/       libre
  .arca/          state, profile, extras, zim.json, manuals.json, software.json, manifest.tsv (registro),
                  search.db, failed.txt, arca.log, scrub-FECHA.log, ultimo-*, tmp/
```

## Perfiles y atributos (`lib/profiles.sh`)

Cada línea de `packs.conf` y `manuals.conf` empieza por `perfil prioridad categoria`.
`perfil` es el mínimo que incluye el recurso (`survive` ⊂ `core` ⊂ `recovery` ⊂ `full`) o
`extra:<nombre>` (solo con `--extra`). `SOFT_PERFILES` en `software.conf` hace lo mismo para los
bloques de software. El perfil y los extras elegidos se guardan en `.arca/profile` y
`.arca/extras`; todos los scripts los leen con `perfil_cargar`. Las líneas sin atributos valen
`full P2 general`, así que un `manuals.conf` viejo sigue funcionando.

`survive` se implementó como **rango 1**, desplazando `core` a 2, `recovery` a 3 y `full` a 4.
Se eligió así, y no como `--extra survive` sobre `core`, porque mantiene una sola jerarquía
lineal: ninguna línea existente cambió de perfil, `recurso_activo` sigue siendo una comparación
de enteros y `--profile survive` describe una instalación completa y coherente, no un recorte.
`15y` es alias y se normaliza en `perfil_cargar` (`perfil_normalizar`).

La prioridad decide qué se protege con PAR2 (P0 pequeño), qué va en `bootstrap/`, el orden de
impresión del print-kit y cómo responde el asistente; la categoría decide la carpeta, el LEEME y
el modo del asistente (SOURCE_ONLY en `medicina`, `agua`, `industria`). Desde el reenfoque a
quince años, P0 significa "vivir el año 1", P1 "oficio enseñable", P2 "legado industrial" y P3
"cultura": por eso manufactura y electricidad, que eran P0, ahora son P1.

El extra `cono-sur` agrega material de la FAO en español para América Latina. Lo que solo existe
en sitios que bloquean la descarga automática (SHOA, SENAPRED, SERNAGEOMIN, IGM, MINVU) no se
inventa: queda como `TODO:` en `manuals.conf` y explicado en `docs/LOCAL.md`, para bajarlo a
mano a `personal/local/`.

## Descargas (`lib/fetch.sh`, `lib/kiwix.sh`)

- ZIM: listado de `download.kiwix.org/zim/<carpeta>/` (caché por ejecución), regex exacta
  `<prefijo>_YYYY-MM[a-z]?.zim`, tamaño real por HEAD, `.torrent` con aria2 (`--seed-time=0`,
  `--bt-stop-timeout=600`) y fallback HTTP, `.sha256` oficial; solo tras verificar se borra la
  versión anterior y se escribe `zim.json`.
- Otros: `fetch_file` (aria2 o curl, 3 intentos con backoff, `.part` y renombrado), `fetch_size`
  (HEAD → GET con Range → descarga corta), esquemas `ia://` (metadatos de archive.org, PDF
  original o derivado), `ocw://`, `openstax://en|es`, `github://repo/REGEX`, `kernel://longterm`,
  `mirror://`.
- Espacio: `space_check` antes de cada descarga grande; la fase 0 suma todo el perfil.

## Manifiesto e integridad

`lib/manifest.sh` mantiene `.arca/manifest.tsv` (una fila por archivo con `mtime` para no
rehashear) y genera `MANIFEST.tsv` (12 columnas abiertas; `unknown` cuando no hay dato;
`status` ok/missing/size-mismatch/unregistered). Los ZIM llevan el sha256 de Kiwix; el resto se
hashea al registrarlo (≤ 8 GB). `check.sh --scrub` recorre MANIFEST.tsv offline y escribe
`.arca/scrub-FECHA.log` sin modificar nada; `repair.sh` crea/verifica/repara PAR2 en `recovery/`
solo para conjuntos pequeños y críticos.

## Copias

`backup.sh --mirror` replica con `rsync --delete`; `--snapshot` crea `destino/arca-AAAA-MM-DD`
con `rsync --link-dest` a la anterior (hardlinks: lo que no cambia no ocupa) y actualiza el
enlace `ultimo`. Ambos excluyen temporales y escriben `BACKUP-INFO.txt`; `.arca/ultimo-mirror`
y `.arca/ultimo-snapshot` alimentan a `check.sh`.

## Print-kit y documentación generada (`lib/docs.sh`)

`printkit/` vive en el repositorio (20 fichas Markdown de una cara, `MANIFIESTO.tsv` y
`START_HERE_PAPEL.txt`) y la fase 10 lo copia tal cual al disco y a `bootstrap/`. No se descarga
nada: es contenido propio, revisado para no inventar dosis ni protocolos; cada ficha remite al
manual de la OMS, MSF, Hesperian o USDA que la respalda.

`docs_generar` produce `START_HERE.txt`, `_ES`, `_EN` y `.html`. Desde el reenfoque, las
primeras líneas del START_HERE son seis acciones concretas (agua, herida, letrina, imprimir,
copiar y verificar, y no confiar en la IA para dosis), antes de cualquier explicación.

## Búsqueda e IA

`lib/arca_index.py build` recorre `manuales/`, `libros/`, `referencia/`, `docs/` y START_HERE:
PDF por página (`pdftotext`, separador `\f`), EPUB por capítulo, TXT/MD/HTML por bloques de
~2000 caracteres; tabla `docs` + FTS5 `chunks` (`unicode61`, sin diacríticos, BM25). Los PDF sin
capa de texto quedan marcados (`needs_ocr`) para `arca-index --ocr` (ocrmypdf, opcional).
`llm/preguntar.py` consulta el índice y Kiwix (`/search?format=xml&books.filter.lang=`), arma el
contexto con etiquetas `[n] título (archivo — página p)`, elige el modo y llama a `llama-server`
(API OpenAI, `/v1/chat/completions` en streaming), arrancándolo si hace falta.

### Pendiente, decidido no hacer ahora

- **RAG semántico (embeddings)**: la búsqueda es BM25 sobre FTS5 y alcanza para consultas
  concretas. Un índice vectorial mejoraría las preguntas vagas, pero agrega dependencias
  pesadas, tiempo de indexado y RAM en un equipo de 8 GB. No ahora.
- **OCR masivo**: se detectan los PDF sin capa de texto y se marcan; el OCR es manual
  (`arca-index --ocr` con ocrmypdf) porque tarda horas por documento.

## Recuperación y migración

- `printkit/` impreso permite actuar sin ningún computador. Es el primer nivel de recuperación.
- `bootstrap/` + `recovery/` + `START_HERE` permiten reabrir el archivo con un Linux cualquiera.
- Instalaciones anteriores a los perfiles: `setup.sh` mueve los manuales a las carpetas nuevas
  (`migrar_ruta_antigua`), el manifiesto marca lo no registrado, y `update.sh --prune` lista lo
  que ya no pertenece al perfil y solo lo borra con confirmación.
- `tests/run.sh` valida sin red ni root: sintaxis, shellcheck, perfiles, parseo, kiwix con
  listado en caché, manifiesto, CLI y un `--dry-run` con fixtures.
