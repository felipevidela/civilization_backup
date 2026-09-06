# 18 · COPIAR ESTE ARCHIVO A UN USB Y VERIFICARLO

**Cuándo usarla:** el mes 0 y cada año. Un solo disco es un archivo que ya empezó a morirse.
Tres copias, dos medios distintos, una fuera de la casa.

## Copiar

Con el USB o disco externo montado (aparece su ruta con `lsblk`):

```
sudo /opt/arca/backup.sh --mirror /media/TU_USUARIO/DISCO
```

Réplica exacta. Para guardar además el estado de este año sin borrar el del año pasado:

```
sudo /opt/arca/backup.sh --snapshot /media/TU_USUARIO/DISCO
```

Si el USB es chico, copia solo lo esencial:

```
cp -a /srv/respaldo/printkit /srv/respaldo/START_HERE*.txt /srv/respaldo/MANIFEST.tsv \
      /srv/respaldo/manuales /srv/respaldo/docs /srv/respaldo/bootstrap /media/.../DISCO/
```

## Verificar (sin esto, la copia no vale)

En el disco original:

```
sudo /opt/arca/check.sh --scrub
```

Compara cada archivo con su huella sha256 en `MANIFEST.tsv`. El informe queda en
`.arca/scrub-FECHA.log`. `corrupt=0 missing=0` es lo que buscas.

En cualquier PC con Linux, sin ARCA instalado, para verificar el núcleo mínimo:

```
cd /media/.../DISCO/bootstrap && sha256sum -c SHA256SUMS
```

Un solo archivo, a mano:

```
sha256sum archivo.pdf
```

y comparar con la columna `sha256` de `MANIFEST.tsv` (se abre con cualquier editor de texto).

## Si algo salió mal

`recovery/` guarda paridad PAR2 del núcleo crítico:

```
sudo /opt/arca/repair.sh --verify
sudo /opt/arca/repair.sh --repair
```

Si un archivo grande está dañado y hay otra copia sana, cópialo de vuelta desde ahí.

## Calendario mínimo

Mes 0: imprimir el print-kit, espejo a disco externo, USB con lo esencial. Cada mes:
`check.sh`. Cada año: `--scrub` completo y snapshot. Cada 5 años: disco nuevo.
