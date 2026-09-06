# Fuentes y licencias

Cada recurso de ARCA declara, cuando se conoce, su origen (URL), versión, fecha y licencia.
Esa información vive en tres sitios:

1. `manuals.conf`: quinto campo `licencia` de cada línea (y la URL de origen en el tercero).
   `packs.conf`: la licencia de los ZIM de Wikimedia es CC BY-SA 4.0; Gutenberg, dominio
   público; Stack Exchange, CC BY-SA 4.0; el resto se marca `unknown` salvo que se indique.
2. `MANIFEST.tsv` en el disco: columnas `source`, `version`, `date`, `license` por archivo.
3. `docs/SOURCES_AND_LICENSES.md` **en el disco** (no este archivo): lo genera la fase 10 a partir
   del manifiesto con el resumen por licencia y por origen de lo realmente instalado.

Reglas: no se inventan licencias (`unknown` si no consta); no se incluye material cuya
redistribución sea claramente ilegal; los textos anteriores a 1929 se consideran de dominio
público en EE. UU.; las publicaciones del gobierno de EE. UU. (USDA, USGS, NASA, ejército,
marina, FEMA, NIST, NPS) son de dominio público; OMS y FAO publican bajo CC BY-NC-SA 3.0 IGO;
Natural Earth es dominio público; los RFC pertenecen al IETF Trust y se pueden copiar íntegros.
Ver [CONTENT_POLICY.md](CONTENT_POLICY.md).
