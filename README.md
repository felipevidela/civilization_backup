# ARCA

Offline Civilization Recovery Archive. Archivo de recuperación de la civilización, fuera de línea.

ARCA instala y mantiene en un PC con Ubuntu 24.04 una biblioteca de hasta 1 TB con el mínimo
práctico de conocimiento, herramientas, software y documentación para que una comunidad pueda
pasar de la supervivencia y el saneamiento básico a la agricultura estable, la industria, la
electricidad, la ciencia y la computación. Todo funciona sin internet una vez instalado y se
consulta desde cualquier dispositivo de la red en `http://IP:8080`.

La pregunta que decide qué entra: *¿cuántos años de redescubrimiento técnico, científico, médico
o institucional ahorra este recurso?* ([docs/CONTENT_POLICY.md](docs/CONTENT_POLICY.md)).

## Inicio rápido

```bash
curl -fsSL https://raw.githubusercontent.com/felipevidela/civilization_backup/main/install.sh | sudo bash -s -- --profile recovery
```

Para ver primero qué haría y cuánto pesa, sin descargar nada:

```bash
curl -fsSL https://raw.githubusercontent.com/felipevidela/civilization_backup/main/install.sh | sudo bash -s -- --profile recovery --dry-run
```

Requisitos: Ubuntu 24.04 LTS, un usuario con `sudo`, 8 GB de RAM, un disco montado en
`/srv/respaldo` (ext4 o exFAT) e internet durante la instalación. Recomendado: SSD para `/` y
disco de 1 TB para `/srv/respaldo`. La instalación tarda de horas a días según el perfil y la
conexión; conviene lanzarla dentro de `tmux`. Si se corta, `sudo /opt/arca/setup.sh` continúa
donde quedó.

## Perfiles

| Perfil | Tamaño real (2026-09) | Contenido |
|---|---|---|
| `core` | ~63 GB | Medicina austera y actual (Hesperian, MSF, OMS), agua y saneamiento, agricultura y conservación de alimentos (FAO, USDA), tecnología apropiada, reparación, Wikipedia en español, Wikipedia médica, LibreTexts, manuales de taller esenciales (Navy Machinery Repairman, NEETS), mapas regionales y del mundo, software para leerlo todo, modelo de lenguaje pequeño, referencia (unidades, constantes, tabla periódica). |
| `recovery` | ~255 GB | core + Wikipedia en inglés con imágenes, manufactura, materiales, energía, electricidad, telecomunicaciones, construcción, instituciones, computación (DevDocs, Stack Exchange técnicos, código fuente fundamental), OpenStax, kit de IA, ISO de Ubuntu, modelo de lenguaje grande. |
| `full` (por defecto) | ~480 GB | recovery + Khan Academy y CrashCourse (video), Wikisource, Wikiquote, textos fundacionales, Britannica 1911, Harvard Classics, Biblioteca de Autores Españoles, Stack Exchange de humanidades. Deja ~400 GB libres en 1 TB. |
| extras | opcionales | `gutenberg-full` (206 GB), `stackoverflow-full` (107 GB), `wikipedia-fr` (50 GB), `wikipedia-en-nopic` (49 GB): `--extra nombre`. |

```bash
sudo /opt/arca/setup.sh --profile core
sudo /opt/arca/setup.sh --profile full --extra gutenberg-full
```

El perfil se recuerda en `/srv/respaldo/.arca/profile`; `update.sh` lo respeta. Cambiar a un
perfil mayor descarga lo que falte; cambiar a uno menor no borra nada hasta ejecutar
`update.sh --prune`.

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
START_HERE.txt / _ES / _EN / .html   empieza aquí (legible sin ningún programa)
MANIFEST.tsv                          todos los archivos con sha256, origen, licencia y prioridad
zim/         enciclopedias y cursos (Kiwix)       manuales/   PDF por dominio, con LEEME en cada carpeta
libros/      textos fundacionales, clásicos, OpenStax        referencia/  unidades, constantes, tablas
mapas/       Organic Maps + Natural Earth          software/   instaladores, código fuente, IA
docs/        TECH_TREE, RECOVERY_ROADMAP, DIGITAL_FORMATS    bootstrap/  mínimo para reabrir el archivo
recovery/    paridad PAR2 del núcleo crítico       personal/   tus archivos
```

Guías: [docs/TECH_TREE.md](docs/TECH_TREE.md) (qué depende de qué),
[docs/RECOVERY_ROADMAP.md](docs/RECOVERY_ROADMAP.md) (niveles 0-7),
[docs/DIGITAL_FORMATS.md](docs/DIGITAL_FORMATS.md) (cómo interpretar los archivos),
[docs/fundacionales.md](docs/fundacionales.md), [docs/ia-desde-cero.md](docs/ia-desde-cero.md).

## Usar

- **Navegador**: `http://IP-DEL-PC:8080` (la IP aparece al iniciar sesión). Kiwix Android y
  Organic Maps están en `software/`.
- **Buscar en PDF y documentos**: `arca-search "filtro lento de arena"` (índice SQLite FTS5 con
  página; `sudo arca-index` lo actualiza, `--ocr` para PDF escaneados si instalas ocrmypdf).
- **Preguntar a la IA con la biblioteca**: `/srv/respaldo/software/llm/preguntar.sh "¿cómo se
  hace jabón?"` combina Kiwix y el índice local y cita las fuentes. En medicina, agua y química
  solo responde con fuentes (`SOURCE_ONLY`); si no las hay, dice que no está en la biblioteca.
  `--rapido` usa el modelo de 3B. `chat.sh` es el chat libre; `chat.sh --server` da una web en el
  puerto 8081.
- **Estado**: `sudo /opt/arca/check.sh` (perfil, disco, integridad, contenido por prioridad,
  índice, copias, servicios, errores).

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
`sudo systemctl disable --now arca-update.timer` lo detiene.

## Restaurar

Con el disco montado en `/srv/respaldo` y sin internet: instala Ubuntu desde `software/iso/`,
`cd software/deb && sudo dpkg -i *.deb`, `tar xf bootstrap/arca-src.tar -C /opt` y
`sudo /opt/arca/setup.sh --profile <el tuyo> --from 7`. Sin nada instalado: el `kiwix-serve`
estático de `bootstrap/` sirve los ZIM desde cualquier Linux. Todo está en `START_HERE.txt`.

## Personalizar y proponer contenido

Edita `packs.conf`, `manuals.conf` o `software.conf` en `/opt/arca` y ejecuta
`sudo /opt/arca/update.sh`. Cada recurso lleva perfil, prioridad (P0 esencial, P1 muy
importante, P2 complementario, P3 cultural), categoría y licencia; `setup.sh --dry-run`
resuelve la URL y muestra el tamaño real antes de descargar. Criterios en
[docs/CONTENT_POLICY.md](docs/CONTENT_POLICY.md); procedencia en
[docs/SOURCES_AND_LICENSES.md](docs/SOURCES_AND_LICENSES.md). Recursos que no tienen descarga
automática (Hesperian en español, Feynman, Standard Ebooks, Where There Is No Vet) están
documentados como TODO en `manuals.conf`.

## Migrar una instalación anterior

`setup.sh` reconoce el estado previo: mueve los manuales a las carpetas nuevas
(`manuales/medicina/actual`, `manuales/agua`, ...), registra en el manifiesto lo que ya
existe y marca como `extra` lo que no pertenece al perfil elegido. No borra nada por sí solo;
`update.sh --prune` muestra qué liberaría y pide confirmación (`--yes` para omitirla).

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
