# Código fuente fundamental

Tarballs de versiones estables para reconstruir una cadena de herramientas completa sin
internet. `SOURCES.tsv` lista versión, URL de origen, licencia y sha256 de cada uno.

Orden de reconstrucción (con un compilador ya existente, por ejemplo el GCC de `../deb/`):
1. `binutils/` (ensamblador y enlazador) → `gcc/` con sus dependencias `gmp`, `mpfr`, `mpc`.
2. Una libc: `glibc/` (completa) o `musl/` (mínima y sencilla de compilar).
3. `make/`, `bash/`, `coreutils/`, `gnu-tools/` (grep, sed, awk, tar, gzip, bison, flex, texinfo).
4. `linux/` (núcleo) y `busybox/` (todo Unix en un binario): con esto arranca un sistema mínimo.
   `alpine/` es un Linux completo ya construido (musl + busybox) para arrancar desde USB.
5. `libs/` (zlib, xz, zstd, ncurses, readline, libffi), `openssl/`, `openssh/`, `curl/`.
6. Lenguajes y datos: `python/`, `lua/`, `sqlite/`, `postgresql/`, `git/`, `editores/`, `cmake/`.
7. `kiwix/` (libzim y kiwix-tools) para volver a leer este archivo; `qemu/` para emular máquinas;
   `llvm/` como segundo compilador; `freertos/` y `arduino/` para microcontroladores;
   `kicad/` para diseñar circuitos.

Cada tarball trae su `README`/`INSTALL`. Sin ningún compilador previo, el camino es el que
describe Wikipedia en *Bootstrapping (compilers)*: un compilador de C mínimo escrito a mano (o
en ensamblador) compila `musl` y un GCC antiguo, y ese GCC compila el actual.
