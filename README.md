# arca — servidor de conocimiento offline

**arca** instala y mantiene, en un PC con Ubuntu 24.04, una copia local de Wikipedia y otras
enciclopedias (archivos ZIM de Kiwix), manuales técnicos y médicos en PDF, mapas de Organic Maps,
el software necesario para reinstalar todo sin internet y un modelo de lenguaje local. El PC queda
como servidor de la red doméstica: cualquier teléfono o computador entra por `http://IP:8080`.

Está pensado para funcionar sin vigilancia: una sola orden instala todo aunque tarde días, se
reanuda solo si se corta, se actualiza cada mes y se copia a un disco externo con un comando.

## Requisitos

- Ubuntu 24.04 LTS recién instalado (Debian 12 funciona con aviso, sin probar).
- Un usuario normal con `sudo`. 8 GB de RAM bastan (el modelo de lenguaje usa ~5 GB).
- Dos discos, o uno grande con dos particiones:
  - `/` (ext4), sistema: un SSD de 256 GB va perfecto, o una partición de 40 GB.
  - `/srv/respaldo` (ext4 o exFAT), datos: 1 TB para el contenido por defecto; con 420 GB
    hay que recortar `packs.conf` (ver más abajo). **Debe estar montada** ahí: el instalador
    se niega a llenar la partición raíz.
- Internet. La instalación completa descarga ~725 GB; con una conexión de 100 Mbit/s son
  unas 17 horas de descarga pura, más lo que tarde el torrent en encontrar pares.

Particionado recomendado en el instalador de Ubuntu ("Instalación manual"): SSD → EFI de
512 MB y el resto ext4 en `/`; HDD de 1 TB → una partición ext4 en `/srv/respaldo`. Con un solo
disco de 500 GB: 40 GB ext4 en `/` y el resto ext4 en `/srv/respaldo`.

## Instalación

```bash
curl -fsSL https://raw.githubusercontent.com/felipevidela/civilization_backup/main/install.sh | sudo bash
```

Para ver primero qué haría y cuánto pesa, sin descargar nada:

```bash
curl -fsSL https://raw.githubusercontent.com/felipevidela/civilization_backup/main/install.sh | sudo bash -s -- --dry-run
```

`install.sh` clona el repositorio en `/opt/arca` y ejecuta `setup.sh`, que trabaja por fases:

| Fase | Qué hace |
|---|---|
| 0 | Verifica distro, sudo, red y montaje; calcula el espacio real consultando los servidores (+15 %) |
| 1 | Crea `/srv/respaldo/{zim,manuales,libros,mapas,software,personal,.arca}` |
| 2 | `apt install` kiwix-tools, aria2, calibre, keepassxc, gocryptfs, flatpak, rsync…; Flatpak Kiwix y Organic Maps |
| 3 | Descarga los ZIM de `packs.conf` (torrent con aria2, 3 a la vez, fallback HTTP, sha256) |
| 4 | Descarga los PDF y recursos de `manuals.conf` |
| 5 | Descarga los mapas `.mwm` de Organic Maps |
| 6 | Software de rescate: .deb con dependencias, AppImage, APK, ISO de Ubuntu, llama.cpp + modelo |
| 7 | Genera `library.xml` e instala `kiwix.service` en el puerto 8080 |
| 8 | Desactiva suspensión, ignora la tapa del portátil, escribe el estado en `/etc/motd`, abre el puerto en ufw |
| 9 | Instala el timer mensual de actualización |
| 10 | Genera `/srv/respaldo/README.txt` con el inventario |
| 11 | Muestra el resumen |

Cada fase terminada se anota en `/srv/respaldo/.arca/state`. Si se corta la luz o cierras la
terminal, vuelve a ejecutar `sudo /opt/arca/setup.sh`: salta lo hecho y reanuda las descargas a
medias. Otras opciones: `--from N` (repite desde la fase N) y `--only N`.

El log completo queda en `/opt/arca/logs/` y en `/srv/respaldo/.arca/arca.log`. Los recursos que
fallan no detienen la instalación: se anotan en `/srv/respaldo/.arca/failed.txt` y se reintentan
en la siguiente actualización.

## Qué contiene por defecto y cuánto pesa

Tamaños reales de septiembre de 2026 (los ZIM crecen con cada versión):

| Contenido | Tamaño |
|---|---|
| Wikipedia inglés con imágenes (`wikipedia_en_all_maxi`) | 115 GB |
| Wikipedia español con imágenes (`wikipedia_es_all_maxi`) | 38 GB |
| Khan Academy (videos de matemáticas y ciencia, versión 2023) | 168 GB |
| Wikipedia médica, mdwiki, guías zimgit (medicina, agua, comida, post-desastre) | 5 GB |
| LibreTexts (ingeniería, química, biología, física, matemáticas, medicina) | 7 GB |
| Project Gutenberg inglés (`gutenberg_en_all`) | 206 GB |
| Wiktionary EN/ES, Wikibooks EN/ES, Wikisource EN/ES, Gutenberg ES | 35 GB |
| iFixit, Appropedia, PhET | 4 GB |
| Stack Exchange (electrónica, bricolaje, física, matemáticas, química) | 15 GB |
| Stack Overflow completo (`stackoverflow.com_en_all`) | 107 GB |
| Manuales PDF (Hesperian, MSF, OMS, Gray's, Merck, CD3WD, Machinery's, NASA, FM, FAO, MIT OCW) | 2 GB |
| Mapas de Chile, Argentina, Perú y Bolivia | 1.6 GB |
| Software: .deb, AppImage, APK, ISO de Ubuntu 24.04, llama.cpp, modelo Qwen2.5-7B Q4_K_M | 13 GB |
| **Total aproximado** | **~725 GB** |

En un disco de 1 TB quedan unos 160 GB libres. Al actualizar, cada ZIM nuevo se descarga entero
antes de borrar el viejo, así que una versión nueva de Khan Academy (168 GB) no cabría hasta
liberar espacio; `update.sh` lo avisa y sigue con el resto. La fase 0 comprueba el espacio con
tamaños reales y, si no cabe, dice exactamente qué líneas de `packs.conf` comentar. Para un disco
de 420 GB: comenta `gutenberg_en_all`, `stackoverflow.com_en_all` y `khanacademy_en_all` o
cambia `wikipedia_en_all_maxi` por `wikipedia_en_all_nopic` (49 GB).

## Cómo editar `packs.conf`, `manuals.conf` y `software.conf`

Los tres archivos viven en `/opt/arca/` y se editan con cualquier editor (`sudo nano`). Las
líneas que empiezan con `#` están desactivadas. Tras editar, ejecuta `sudo /opt/arca/update.sh`.

- **`packs.conf`**: un ZIM por línea, `carpeta/prefijo` tal como aparece en
  <https://download.kiwix.org/zim/>. Ejemplo: `wikipedia/wikipedia_fr_all_maxi`. El script elige
  solo la fecha más reciente. Nombres que no existen en el servidor se anotan como error.
  Al final del archivo hay opciones desactivadas (Wikipedia inglés sin imágenes, Wikipedia francés).
- **`manuals.conf`**: `destino_relativo | url | descripción`. Admite URL directa, `ia://ITEM`
  (archive.org), `ocw://slug` (MIT OpenCourseWare) y `mirror://URL?max=N` (espejo HTML con wget).
  Si el destino termina en `/` es una carpeta.
- **`software.conf`**: `clave=valor`. Aquí se cambia el modelo de lenguaje (`LLM_MODEL_REPO`,
  `LLM_MODEL_FILE`, cualquier GGUF de Hugging Face), se desactiva la ISO o el LLM (`=0`) y se
  eligen los países de los mapas (`MAPAS_PAISES`).

Si al ampliar `packs.conf` deja de caber, `update.sh` lo dirá antes de descargar.

## Usar desde otros dispositivos

El estado y la IP aparecen al entrar por terminal (motd) y con `sudo /opt/arca/check.sh`.

- **Navegador** (cualquier dispositivo en la misma red): `http://IP-DEL-PC:8080`.
- **Kiwix Android** (`/srv/respaldo/software/kiwix/*.apk`): en la app, "Servidor remoto" con la
  misma URL, o copia al teléfono los ZIM pequeños (por ejemplo `wikipedia_en_medicine_maxi`).
- **Organic Maps** (`software/organicmaps/*.apk`): copia los `.mwm` de `/srv/respaldo/mapas/` a
  la carpeta de mapas de la app (Ajustes → Carpeta de mapas) o descárgalos desde la propia app.
- **Modelo de lenguaje**: `/srv/respaldo/software/llm/chat.sh` (terminal) o
  `chat.sh --server` para una interfaz web en `http://IP-DEL-PC:8081`.
- **Calibre**: abre Calibre y elige como biblioteca `/srv/respaldo/libros/`. Tus EPUB sin DRM van
  en `/srv/respaldo/libros/propios/`.

Para darle IP fija al servidor, resérvala en el router (DHCP estático) por su dirección MAC.

## Actualizar

```bash
sudo /opt/arca/update.sh --check     # qué hay nuevo y cuánto pesa, sin descargar
sudo /opt/arca/update.sh             # actualizar todo
sudo /opt/arca/update.sh --zim-only  # solo enciclopedias
sudo /opt/arca/update.sh --no-software
```

`update.sh` descarga la versión nueva de cada ZIM, la verifica y solo entonces borra la anterior:
el disco nunca se queda sin una versión funcional. Al terminar escribe un resumen en
`/opt/arca/logs/update-AAAAMMDD.log`.

El timer `arca-update.timer` lo ejecuta una vez al mes (si el PC estaba apagado, al siguiente
arranque). Para desactivarlo:

```bash
sudo systemctl disable --now arca-update.timer
```

y para volver a activarlo, `sudo systemctl enable --now arca-update.timer`.

## Respaldar a un disco externo

```bash
sudo /opt/arca/backup.sh /media/tu-usuario/DISCO-EXTERNO
sudo /opt/arca/backup.sh            # sin ruta: lista los discos montados y pide elegir
sudo /opt/arca/backup.sh /ruta --yes  # sin confirmación
```

Copia `/srv/respaldo/` completo con `rsync --delete` (lo borrado en origen se borra en destino),
muestra antes qué va a hacer y cuánto espacio necesita, y al terminar escribe `BACKUP-INFO.txt`
en el destino y hace `sync`. Con el contenido por defecto hace falta un disco externo de 1 TB
(ext4 o exFAT).

## Restaurar en un PC nuevo sin internet

Con el disco (o la copia externa) montado en `/srv/respaldo`:

1. Instala Ubuntu 24.04 desde `software/iso/ubuntu-24.04.*-desktop-amd64.iso` (grábala en un USB
   con `dd` o Balena Etcher).
2. Instala Kiwix y utilidades desde los .deb:
   `cd /srv/respaldo/software/deb && sudo dpkg -i *.deb; sudo apt-get -f install`.
   Alternativa sin dpkg: `software/kiwix/kiwix-tools_linux-x86_64-musl-*.tar.gz` trae
   `kiwix-serve` estático.
3. Restaura el repositorio y el servicio:
   ```bash
   sudo git clone /srv/respaldo/software/arca.git /opt/arca
   sudo /opt/arca/setup.sh --from 7
   ```
   (`git` viene en los .deb; si no lo tienes, `sudo cp -r` de un clon hecho en otro PC sirve igual).
4. Si no quieres servicio, lanza a mano:
   `kiwix-serve --library /srv/respaldo/library.xml --port 8080 --address 0.0.0.0`.

`/srv/respaldo/README.txt` repite estas instrucciones en texto plano, con el inventario y las
fechas de cada archivo, para que estén disponibles aunque solo tengas el disco.

## Agregar libros propios a Calibre

Copia tus EPUB o PDF sin DRM a `/srv/respaldo/libros/propios/`. En Calibre: menú "Biblioteca" →
"Cambiar/crear biblioteca" → `/srv/respaldo/libros`, y luego "Añadir libros" apuntando a esa
carpeta. Así los libros y la base de Calibre viajan en el mismo disco y entran en el respaldo.

## Recursos que hay que bajar a mano

Algunos recursos no tienen descarga automática estable; quedan documentados y comentados en
`manuals.conf`:

- **Hesperian en español** (*Donde no hay doctor*, *Donde no hay dentista*): descarga gratuita
  con formulario en <https://store.hesperian.org>. Cópialos a `/srv/respaldo/manuales/medicina/`.
  Las ediciones en inglés sí se descargan solas (copias en archive.org).
- **Feynman Lectures on Physics**: Caltech prohíbe hacer espejos del sitio y su CDN bloquea las
  descargas automáticas. Solo se puede leer en línea en <https://www.feynmanlectures.caltech.edu/>.
- **Standard Ebooks**: la descarga en lote requiere ser miembro del Patrons Circle. Con esa
  cuenta, baja los ZIP desde <https://standardebooks.org/bulk-downloads> a
  `/srv/respaldo/libros/standard-ebooks/`. Sin ella, la literatura está en los ZIM de Gutenberg.
- **LibreTexts y OpenStax**: LibreTexts se instala como ZIM oficial de Kiwix (más completo que
  un espejo HTML). OpenStax no existe en Kiwix; sus libros se pueden bajar en PDF desde
  <https://openstax.org/subjects> a `manuales/`.

## Solución de problemas

- **"No está montado /srv/respaldo"**: `lsblk` para ver la partición y añádela a `/etc/fstab`
  (`UUID=... /srv/respaldo ext4 defaults 0 2`), luego `sudo mount -a`.
- **"No cabe"**: comenta en `packs.conf` las líneas que indica el mensaje y relanza.
- **Una descarga falla o va muy lenta por torrent**: aria2 pasa solo a HTTP a los 10 minutos sin
  pares. Para forzar HTTP siempre: `sudo KIWIX_USE_TORRENT=0 /opt/arca/setup.sh`.
- **Se cortó la instalación**: vuelve a ejecutar `sudo /opt/arca/setup.sh`; continúa donde quedó.
- **kiwix no responde**: `sudo systemctl status kiwix`, `journalctl -u kiwix -n 50`. Si
  `library.xml` está corrupta, `sudo /opt/arca/setup.sh --only 7` la regenera.
- **No se ve desde otros dispositivos**: comprueba que están en la misma red, que el puerto 8080
  está abierto (`sudo ufw status`) y que la IP es la que muestra `check.sh`.
- **El modelo de lenguaje no arranca**: necesita ~5 GB de RAM libres. Cierra Calibre y el
  navegador, o elige un modelo más pequeño en `software.conf` (por ejemplo un Q4_K_M de 3B).
- **"Ya hay un proceso en ejecución"**: otro `setup.sh`/`update.sh` está corriendo (mira
  `ps aux | grep arca`). Si es un lock huérfano, el script lo detecta y lo reemplaza solo.
- **Errores pendientes**: `cat /srv/respaldo/.arca/failed.txt`; se reintentan con `update.sh`.

## Estructura del repositorio

```
install.sh      bootstrap para curl | sudo bash
setup.sh        instalación por fases (reanudable)
update.sh       actualización (la ejecuta el timer)
backup.sh       copia a disco externo
check.sh        estado e inventario
packs.conf      ZIM a descargar
manuals.conf    PDF y recursos sueltos
software.conf   software de rescate, mapas y LLM
lib/            log, espacio, estado/lock, descargas, kiwix, fases, README.txt, motd
systemd/        kiwix.service, arca-update.{service,timer}, arca-motd.service
```

## Licencia

MIT. Los contenidos descargados tienen cada uno su propia licencia (CC BY-SA en Wikipedia,
dominio público en archive.org, etc.); consulta la de cada fuente antes de redistribuirlos.
