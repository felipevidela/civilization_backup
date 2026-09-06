# ARCA

Kit de quince años para vivir sin red. Archivo offline en español, pensado para una familia o un
pueblo chico del Cono Sur.

ARCA convierte un PC con Ubuntu 24.04 en la biblioteca y el servidor de conocimiento de un grupo
que se quedó sin internet, sin repuestos y sin hospital cerca. Se prioriza contra tres
escenarios concretos: **pandemia con alta mortalidad, invierno nuclear o volcánico, y tormenta
solar severa** ([docs/ESCENARIOS.md](docs/ESCENARIOS.md)). Qué trae: cómo potabilizar el agua, tratar
una herida, cultivar y guardar comida, levantar una letrina, reparar lo que hay y enseñarle un
oficio a un adolescente. Se consulta desde cualquier teléfono o computador de la casa en
`http://IP:8080`, sin internet.

Lo que decide qué entra, en este orden:

1. ¿Evita una muerte o una hambruna en los próximos 24 meses, aquí?
2. ¿Deja un oficio enseñable a un adolescente en tres años?
3. ¿Cabe en papel o en un USB, además del disco?
4. Solo después: ¿ahorra redescubrimiento técnico a largo plazo?

**El PC se va a morir.** Un disco duro encendido a diario dura de 5 a 8 años; la fuente y la
placa, de 8 a 15. Este archivo es una linterna de quince años, no una catedral. Lo único que
sobrevive de verdad es el papel que imprimas y lo que la gente aprenda: por eso lo primero que
hace ARCA es darte 23 fichas para imprimir ([`printkit/`](printkit/)), y por eso hay que
verificar y copiar el disco todos los años.

Reconstruir la civilización industrial es un subproducto, no la meta: vive en los perfiles
`recovery` y `full`, para cuando ya no se muera nadie. Ver
[docs/CONTENT_POLICY.md](docs/CONTENT_POLICY.md).

## Inicio rápido

Modo quince años, unos 55 GB:

```bash
curl -fsSL https://raw.githubusercontent.com/felipevidela/civilization_backup/main/install.sh | sudo bash -s -- --profile survive
```

Para ver antes qué haría y cuánto pesa, sin descargar nada, añade `--dry-run`. Para el archivo
completo con el legado industrial y cultural, `--profile full`.

Requisitos: Ubuntu 24.04 LTS, un usuario con `sudo`, 8 GB de RAM, un disco montado en
`/srv/respaldo` (ext4 o exFAT) e internet **durante la instalación**. La instalación tarda de
horas a días según el perfil y la conexión; conviene lanzarla dentro de `tmux`. Si se corta,
`sudo /opt/arca/setup.sh` continúa donde quedó.

## Lo primero: imprimir

```bash
ls /srv/respaldo/printkit/fichas/     # 23 fichas de una cara
cat /srv/respaldo/printkit/README.md  # cómo imprimirlas
```

Veintitrés fichas de una hoja cada una: agua, herida, letrina, diarrea, parto, jabón, conserva,
semilla, sismo, leña, gallinas, radio, cómo copiar y verificar este archivo, y una por cada
escenario (pandemia, invierno largo con ceniza, tormenta solar). Español llano, sin PC. Si no las
imprimiste, el proyecto todavía no está terminado aunque Kiwix funcione.

## Perfiles

| Perfil | Tamaño real (2026-09) | Contenido |
|---|---|---|
| `survive` (alias `15y`) | ~55 GB | Los quince años: medicina austera (Hesperian) y actual (MSF, OMS), agua y saneamiento, alimentos y conservas, huerta y semillas, animales de patio, sismo y clima, reparación, Wikipedia en español, Wikipedia médica, tecnología apropiada, mapas del país, referencia, modelo de lenguaje de 3B, print-kit. |
| `core` | ~63 GB | survive + ciencia y matemáticas de base (LibreTexts), diccionarios, material escolar, energía. |
| `recovery` | ~255 GB | core + oficios e industria: manufactura y metrología, materiales, electricidad, telecomunicaciones, construcción, instituciones, computación (DevDocs, Stack Exchange técnicos, código fuente), OpenStax, ISO de Ubuntu, modelo de 7B, kit de IA. |
| `full` (por defecto) | ~480 GB | recovery + legado y cultura: Khan Academy y CrashCourse, Wikisource, textos fundacionales, Britannica 1911, Harvard Classics, Biblioteca de Autores Españoles, Stack Exchange de humanidades. Deja ~400 GB libres en 1 TB. |
| extras | opcionales | `cono-sur` (Chile y vecinos), `literatura` (57 GB: toda la literatura de Gutenberg más obras hispanoamericanas), `gutenberg-full` (206 GB), `stackoverflow-full` (107 GB), `wikipedia-fr` (50 GB), `wikipedia-en-nopic` (49 GB): `--extra nombre`. |

`survive` ⊂ `core` ⊂ `recovery` ⊂ `full`: subir de perfil solo agrega, nunca quita. `full` sigue
siendo el valor por defecto para no romper instalaciones existentes; si empiezas de cero y el
disco es chico o el momento es malo, usa `survive`.

```bash
sudo /opt/arca/setup.sh --profile survive --extra cono-sur
sudo /opt/arca/setup.sh --profile full --extra gutenberg-full
```

El perfil se recuerda en `/srv/respaldo/.arca/profile`; `update.sh` lo respeta. Cambiar a un
perfil mayor descarga lo que falte; cambiar a uno menor no borra nada hasta ejecutar
`update.sh --prune`.

En un USB: `survive` sin la Wikipedia en español con imágenes (38 GB) baja a unos 17 GB y cabe
en un USB de 32 GB; completo necesita uno de 128 GB. Ver [docs/BOM_15Y.md](docs/BOM_15Y.md).

## Arquitectura

`setup.sh` ejecuta 12 fases reanudables (prerrequisitos y espacio, carpetas, paquetes, ZIM,
manuales, mapas, software, servicio Kiwix, sistema, timer, documentación e integridad,
resumen). Tres archivos deciden el contenido, cada línea con `perfil prioridad categoria`:

- `packs.conf`: ZIM de Kiwix (`carpeta/prefijo`, se resuelve la versión más reciente).
- `manuals.conf`: PDF, libros, datos y código fuente (`destino | url | descripción | licencia`,
  con esquemas `ia://`, `ocw://`, `openstax://`, `github://`, `kernel://`).
- `software.conf`: paquetes, modelos de lenguaje, mapas, opciones y `SOFT_PERFILES`.

Detalle completo en [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Qué hay en el disco

```
printkit/                             23 fichas para imprimir + START_HERE_PAPEL.txt
START_HERE.txt / _ES / _EN / .html    empieza aquí (legible sin ningún programa)
MANIFEST.tsv                          todos los archivos con sha256, origen, licencia y prioridad
zim/         enciclopedias y cursos (Kiwix)       manuales/   PDF por dominio, con LEEME en cada carpeta
libros/      textos fundacionales, clásicos, OpenStax        referencia/  unidades, constantes, tablas
mapas/       Organic Maps + Natural Earth          software/   instaladores, código fuente, IA
docs/        ESCENARIOS, ROADMAP, TECH_TREE, BOM_15Y, LOCAL   bootstrap/  mínimo para reabrir el archivo
recovery/    paridad PAR2 del núcleo crítico       personal/   tus archivos
```

Guías: [docs/ESCENARIOS.md](docs/ESCENARIOS.md) (qué abrir según lo que pase),
[docs/RECOVERY_ROADMAP.md](docs/RECOVERY_ROADMAP.md) (qué hacer la semana 1, el mes 1,
el año 1, el año 5, el año 15), [docs/BOM_15Y.md](docs/BOM_15Y.md) (qué comprar antes),
[docs/LOCAL.md](docs/LOCAL.md) (qué bajar a mano de tu país),
[docs/TECH_TREE.md](docs/TECH_TREE.md) (qué depende de qué),
[docs/CANON_LITERARIO.md](docs/CANON_LITERARIO.md) (qué leer y dónde está),
[docs/DIGITAL_FORMATS.md](docs/DIGITAL_FORMATS.md) (cómo interpretar los archivos).

## Usar

- **Navegador**: `http://IP-DEL-PC:8080` (la IP aparece al iniciar sesión). Kiwix Android y
  Organic Maps están en `software/`.
- **Buscar en PDF y documentos**: `arca-search "filtro lento de arena"` (índice SQLite FTS5 con
  página; `sudo arca-index` lo actualiza, `--ocr` para PDF escaneados si instalas ocrmypdf).
- **Preguntar a la IA con la biblioteca**: `/srv/respaldo/software/llm/preguntar.sh "¿cómo se
  hace jabón?"` combina Kiwix y el índice local y cita las fuentes. En medicina, agua y química
  solo responde con fuentes (`SOURCE_ONLY`); si no las hay, dice que no está en la biblioteca.
  En `survive` y `core` el modelo es el de 3B; el de 7B llega con `recovery`. `chat.sh` es el
  chat libre; `chat.sh --server` da una web en el puerto 8081.
  **La IA es un índice, no un médico**: para dosis, partos, venenos o agua, abre el PDF que cita.
- **Estado**: `sudo /opt/arca/check.sh` (perfil, disco, integridad, contenido por prioridad,
  índice, copias, servicios, errores).

## El disco se va a morir: qué hacer al respecto

Tres copias, dos medios, una fuera de la casa. Calendario mínimo:

| Cuándo | Qué |
|---|---|
| Mes 0 | Imprimir `printkit/`. Espejo a un disco externo. Copiar `survive` a un USB. |
| Cada mes | `sudo /opt/arca/check.sh` (mira errores y días desde el último scrub). |
| Cada 12 meses | `sudo /opt/arca/check.sh --scrub` completo y un snapshot nuevo. Reimprimir lo que se haya mojado o perdido. |
| Cada 5 años | Disco nuevo: copiar todo y verificar antes de jubilar el viejo. |

Para archivo frío usa HDD, no SSD: un SSD desconectado años pierde la carga de sus celdas.
El SSD sirve para `/`, no para la biblioteca guardada en un cajón.

## Integridad

```bash
sudo /opt/arca/check.sh --scrub         # sha256 de todo contra MANIFEST.tsv (offline, lento)
sudo /opt/arca/check.sh --scrub-quick   # solo existencia y tamaño
sudo /opt/arca/repair.sh --verify       # paridad PAR2 del núcleo crítico
sudo /opt/arca/repair.sh --repair       # repara (solo bajo petición)
```

El scrub no modifica nada; deja el informe en `.arca/scrub-FECHA.log`. Archivos sin hash
conocido se reportan como `UNVERIFIED`. Sin el sistema instalado: `sha256sum -c
bootstrap/SHA256SUMS` y `par2 verify -B /srv/respaldo recovery/bootstrap.par2`.

## Copias de seguridad

```bash
sudo /opt/arca/backup.sh --mirror /media/usuario/DISCO      # réplica exacta (propaga borrados)
sudo /opt/arca/backup.sh --snapshot /media/usuario/DISCO    # DISCO/arca-AAAA-MM-DD, hardlinks
```

Mirror replica el estado actual con `rsync --delete`. Snapshot conserva estados históricos:
cada carpeta es completa, lo que no cambió se enlaza a la anterior y no ocupa espacio; `ultimo`
apunta al más reciente; ningún snapshot anterior se modifica. Funciona en ext4 y exFAT.

## Actualizar

```bash
sudo /opt/arca/update.sh --check   # qué hay nuevo, cuánto pesa, qué está fuera del perfil
sudo /opt/arca/update.sh           # ZIM nuevos, manuales cambiados, software con release nueva
sudo /opt/arca/update.sh --prune   # lista lo que ya no pertenece al perfil y pide confirmación
```

Un ZIM nuevo se descarga entero y se verifica antes de borrar el viejo. Con
`MARGEN_ESPACIO_PCT=15` y `ZIM_BORRAR_VIEJO_SI_NO_CABE=0` (por defecto) nunca se queda sin una
versión funcional. El timer `arca-update.timer` corre cada mes;
`sudo systemctl disable --now arca-update.timer` lo detiene. Cuando ya no haya internet, el
timer no molesta: falla, lo anota y sigue.

## Restaurar

Con el disco montado en `/srv/respaldo` y sin internet: instala Ubuntu desde `software/iso/`,
`cd software/deb && sudo dpkg -i *.deb`, `tar xf bootstrap/arca-src.tar -C /opt` y
`sudo /opt/arca/setup.sh --profile <el tuyo> --from 7`. Sin nada instalado: el `kiwix-serve`
estático de `bootstrap/` sirve los ZIM desde cualquier Linux. Todo está en `START_HERE.txt` y,
en papel, en `printkit/START_HERE_PAPEL.txt`.

## Personalizar y proponer contenido

Edita `packs.conf`, `manuals.conf` o `software.conf` en `/opt/arca` y ejecuta
`sudo /opt/arca/update.sh`. Cada recurso lleva perfil, prioridad (P0 vivir 15 años, P1 oficios,
P2 legado, P3 cultura), categoría y licencia; `setup.sh --dry-run` resuelve la URL y muestra el
tamaño real antes de descargar. Criterios en [docs/CONTENT_POLICY.md](docs/CONTENT_POLICY.md);
procedencia en [docs/SOURCES_AND_LICENSES.md](docs/SOURCES_AND_LICENSES.md). Lo que tu zona
necesita y no se puede bajar solo está en [docs/LOCAL.md](docs/LOCAL.md). Recursos sin descarga
automática (Hesperian en español, Feynman, Standard Ebooks, Where There Is No Vet) están
documentados como TODO en `manuals.conf`.

## Migrar una instalación anterior

`setup.sh` reconoce el estado previo: mueve los manuales a las carpetas nuevas
(`manuales/medicina/actual`, `manuales/agua`, ...), registra en el manifiesto lo que ya
existe y marca como `extra` lo que no pertenece al perfil elegido. No borra nada por sí solo;
`update.sh --prune` muestra qué liberaría y pide confirmación (`--yes` para omitirla). Bajar de
`full` a `survive` no borra los 400 GB de legado hasta que lo pidas.

## Pruebas

`./tests/run.sh` (en Ubuntu, sin red ni root): sintaxis y shellcheck de todos los scripts,
perfiles, parseo, manifiesto, argumentos y un `--dry-run` con fixtures.

## Solución de problemas

- **No cabe**: elige un perfil menor, quita extras o comenta líneas; la fase 0 dice cuáles.
- **/srv/respaldo no está montado**: `lsblk`, añade la partición a `/etc/fstab`, `sudo mount -a`.
- **Kiwix no responde**: `sudo systemctl status kiwix`; `sudo /opt/arca/setup.sh --only 7`.
- **La IA va lenta o no arranca**: usa `--rapido`; necesita 3 GB (3B) o 6 GB (7B) de RAM libres.
- **Errores pendientes**: `cat /srv/respaldo/.arca/failed.txt`; se reintentan con `update.sh`.
- **Wi-Fi USB Realtek RTL8822BU cuelga el arranque**: desconéctalo para instalar; luego
  `sudo apt full-upgrade` o el driver `morrownr/88x2bu-20210702`.

## Licencia

MIT para los scripts. Cada contenido conserva su licencia (CC BY-SA en Wikimedia, dominio
público en archive.org y publicaciones del gobierno de EE. UU., CC BY-NC-SA en OMS y FAO);
consulta `MANIFEST.tsv` y `docs/SOURCES_AND_LICENSES.md` en el disco.
