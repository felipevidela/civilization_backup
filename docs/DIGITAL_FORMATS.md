# Cómo interpretar el archivo digital

Para quien encuentre este disco sin el software que lo lee. Explica, de lo simple a lo complejo,
qué son los bits, cómo se codifican texto e imágenes, cómo se empaquetan archivos y cómo está
organizado un disco. Las especificaciones completas y oficiales están indicadas al final; este
texto es el mapa para llegar a ellas.

## 1. Bits, bytes y números
- Un **bit** es un valor de dos estados: 0 o 1 (tensión baja/alta, imán en un sentido u otro,
  hoyo o no en un disco óptico).
- Un **byte** son 8 bits: 256 valores posibles (0-255). Todo en este disco es una secuencia de
  bytes; el "formato" es solo el acuerdo sobre qué significan.
- **Binario**: cada posición vale una potencia de 2. `1011` = 8+0+2+1 = 11. **Hexadecimal**: un
  dígito (0-9, A-F) por cada 4 bits; `0xFF` = 255. Un byte se escribe con dos dígitos hex.
- **Endianness**: un número de varios bytes puede guardarse con el byte menos significativo
  primero (*little-endian*, lo normal en PC x86 y ARM) o el más significativo primero
  (*big-endian*, red e Internet). 258 = `0x0102` → little-endian `02 01`, big-endian `01 02`.
- Enteros con signo suelen usar complemento a dos; los reales, el formato IEEE 754 (32 o 64 bits:
  signo, exponente, mantisa).

## 2. Texto
- **ASCII** (1963): 7 bits, 128 códigos. 65 = `A`, 97 = `a`, 48 = `0`, 32 = espacio, 10 = salto
  de línea (LF), 13 = retorno de carro (CR). Los archivos `.txt` de este disco son ASCII o UTF-8.
- **UTF-8** (1992): codifica cualquier carácter Unicode con 1 a 4 bytes y es compatible con ASCII:
  los bytes 0-127 son ASCII; un carácter de 2 bytes empieza por `110xxxxx 10xxxxxx`, de 3 por
  `1110xxxx 10xxxxxx 10xxxxxx`, de 4 por `11110xxx ...`. Ejemplo: `ñ` = `C3 B1`, `€` = `E2 82 AC`.
  Para decodificar: cuenta los unos iniciales del primer byte; los bits marcados x, concatenados,
  dan el número Unicode; la tabla de números a caracteres está en Wikipedia (*Unicode*, *UTF-8*).
- Fin de línea: Unix `LF`, Windows `CR LF`.

## 3. Archivos de datos simples
- **TXT**: solo texto. **CSV**: texto con una fila por línea y campos separados por comas (o
  punto y coma); comillas dobles envuelven campos que contienen comas. **TSV**: separado por
  tabuladores (así es `MANIFEST.tsv`). **Markdown** (`.md`): texto plano con marcas ligeras
  (`# título`, `- lista`, `[enlace](ruta)`); legible sin procesar. **JSON**: texto con objetos
  `{"clave": valor}` y listas `[...]`; así son `zim.json` y `software.json`.

## 4. Documentos
- **PDF** (Adobe, 1993; norma ISO 32000): texto plano con objetos numerados (`1 0 obj ... endobj`),
  una tabla `xref` con las posiciones de cada objeto y un `trailer` al final. El contenido de cada
  página es un flujo (`stream`) normalmente comprimido con **deflate** (el mismo algoritmo de ZIP),
  con operadores de dibujo y texto. Un PDF "escaneado" es una imagen por página más, a veces,
  una capa de texto invisible (OCR). Herramientas: `pdftotext` (poppler), cualquier visor.
- **EPUB**: un archivo ZIP que contiene páginas XHTML, imágenes y un índice XML (`content.opf`).
  Descomprímelo y lee las páginas con cualquier navegador o editor de texto.
- **HTML**: texto con etiquetas `<p>`, `<h1>`, `<a href>`; legible en crudo.

## 5. Imágenes
- Una imagen es una rejilla de píxeles; cada píxel, uno (gris) o tres (RGB) valores de 0-255.
- **PNG**: cabecera `89 50 4E 47 0D 0A 1A 0A`, luego bloques (*chunks*) con longitud, tipo
  (`IHDR` tamaño y profundidad, `IDAT` datos comprimidos con deflate, `IEND`) y CRC. Sin pérdida.
- **JPEG**: bloques de 8×8 píxeles transformados (DCT), cuantizados y comprimidos (Huffman);
  con pérdida. Empieza por `FF D8`, termina en `FF D9`.
- **SVG**: dibujo vectorial en XML (texto).

## 6. Contenedores y compresión
- **ZIP**: cada archivo lleva una cabecera local (`50 4B 03 04`), datos (normalmente deflate) y al
  final un directorio central con nombres y posiciones. `.epub`, `.apk`, `.docx` son ZIP.
- **TAR**: concatenación de bloques de 512 bytes: cabecera con nombre, tamaño, permisos y fecha,
  seguida del contenido. Sin compresión; `.tar.gz` es un TAR comprimido con **gzip** (deflate),
  `.tar.xz` con LZMA. `bootstrap/arca-src.tar` es un TAR plano.
- **Deflate** (RFC 1951): LZ77 (referencias a texto repetido) + códigos de Huffman. Es el
  algoritmo de ZIP, gzip, PNG y los flujos de PDF; su especificación cabe en 15 páginas.
- **ZIM** (openZIM): contenedor de páginas web comprimidas con zstd o xz, con índice de títulos y
  de texto completo (Xapian). Se lee con `kiwix-serve` o cualquier lector Kiwix; las
  especificaciones están en `manuales/` y en `software/kiwix/` (fuentes de libzim en
  `software/source/` si el perfil las incluye).
- **.deb**: archivo `ar` con `control.tar` y `data.tar`. **AppImage**: ejecutable con un sistema
  de archivos SquashFS pegado. **.gguf**: pesos de un modelo de IA con cabecera de metadatos.

## 7. Discos, particiones y sistemas de archivos
- Un disco es una secuencia de **sectores** (512 o 4096 bytes). Una **tabla de particiones** al
  inicio divide el disco: **MBR** (sector 0, 4 entradas) o **GPT** (cabecera en el sector 1 más
  entradas de 128 bytes con GUID). Este disco usa GPT o MBR con una sola partición de datos.
- Un **sistema de archivos** organiza la partición en archivos y carpetas:
  - **FAT32/exFAT**: tabla de asignación (cadenas de clústeres) y entradas de directorio de 32
    bytes; sencillo, universal, sin permisos. Recomendado para discos que deban leerse en
    cualquier sistema.
  - **ext4** (Linux): superbloque, grupos de bloques, **inodos** (metadatos de cada archivo con
    punteros a sus bloques, en árboles de extents) y directorios como listas de nombres→inodo.
    El superbloque principal está en el byte 1024 de la partición; hay copias en varios grupos.
    Con solo un editor hexadecimal y la especificación se puede recuperar un archivo a mano.
- **Montar** es decirle al sistema operativo dónde exponer esa partición (`/srv/respaldo`).

## 8. Verificar que nada cambió: SHA-256
- Una **función hash** produce un resumen de 256 bits (64 caracteres hex) de cualquier archivo;
  un solo bit distinto cambia por completo el resumen y es impracticable fabricar dos archivos con
  el mismo. `MANIFEST.tsv` guarda el SHA-256 de cada archivo; `sha256sum archivo` lo recalcula.
- **PAR2** (`recovery/`): datos de paridad Reed-Solomon; con ellos se reconstruyen bloques
  dañados o archivos perdidos del núcleo hasta un 10 %.

## 9. Programas y sistema operativo
- Un programa ejecutable en Linux es un archivo **ELF** (cabecera `7F 45 4C 46`) con código
  máquina para una arquitectura (x86-64 en este PC). Los scripts (`.sh`, `.py`) son texto que
  interpreta otro programa (bash, python3).
- Con el código fuente (`software/source/`, `software/arca.git`) y un compilador (GCC, incluido en
  `software/deb/` y en fuentes) se pueden reconstruir los programas. El orden está en
  `software/ia/LEEME.md` y `RECOVERY_ROADMAP.md`, nivel 6.

## Especificaciones oficiales incluidas o referenciadas
| Formato | Dónde |
|---|---|
| UTF-8, ASCII, Unicode, deflate, PNG, JPEG, ZIP, TAR, ext4, FAT, GPT, SHA-2, ELF, PDF | Wikipedia (Kiwix) tiene artículos detallados con diagramas; los RFC 3629 (UTF-8), 1951 (deflate) y 1952 (gzip) están en `manuales/telecomunicaciones/rfc/` si el perfil los incluye o se descargan de rfc-editor.org |
| IP, TCP, ARP, HTTP | `manuales/telecomunicaciones/rfc/` |
| ZIM | openzim.org (wiki en Kiwix: *ZIM (file format)*) |
| SI, constantes | `referencia/` |
