# Lo local: lo que ARCA no puede bajar por ti

ARCA trae el conocimiento general. Lo que decide si tu familia come y sobrevive **este año, en
tu cerro**, es local: cuándo hiela en tu valle, dónde está la falla geológica, hasta dónde llegó
el agua el último tsunami, qué se da bien en tu suelo. Eso hay que juntarlo **hoy, que hay
internet**, y guardarlo en `personal/local/`.

Esta es una plantilla. Rellénala tú: nadie más sabe tu zona.

## Regla

Guarda todo en `/srv/respaldo/personal/local/` (esa carpeta se respalda y se incluye en el
espejo, pero no se borra ni se toca en las actualizaciones). Un archivo por tema, con nombre
claro y fecha:

```
personal/local/2026-09_mapa-inundacion-comuna.pdf
personal/local/2026-09_calendario-siembra-valle-central.md
personal/local/2026-09_pozos-y-vertientes-cercanas.md
```

Después de agregar cosas: `sudo arca-index` para que `arca-search` y el asistente las
encuentren, y `sudo /opt/arca/setup.sh --only 10` para que entren en `MANIFEST.tsv`.

## Chile

Los sitios oficiales cambian de dirección y muchos bloquean las descargas automáticas, así que
esto **se baja a mano desde el navegador**. No hay línea en `manuals.conf` para ellos.

| Qué | Dónde | Por qué |
|---|---|---|
| **Carta de inundación por tsunami de tu comuna** | SHOA (shoa.cl) y SENAPRED (senapred.cl) | Ficha 13. Saber la cota segura antes, no durante. |
| **Plan comunal de emergencia y vías de evacuación** | Municipalidad y SENAPRED | Dónde se junta la gente, dónde está el albergue. |
| **Mapas de peligro volcánico y de remoción en masa** | SERNAGEOMIN (sernageomin.cl) | Si vives cerca de un volcán o de una quebrada. |
| **Cartas topográficas 1:50.000 de tu zona** | IGM (igm.cl) | Curvas de nivel, esteros, caminos. Complementa Organic Maps. |
| **Derechos de agua, pozos y caudales** | DGA (dga.mop.gob.cl) | Dónde hay agua subterránea y a qué profundidad. |
| **Suelos y capacidad de uso** | CIREN (bibliotecadigital.ciren.cl) | Qué se puede sembrar en tu predio. |
| **Fichas técnicas de cultivos por región** | INIA (inia.cl) | Variedades, fechas de siembra, plagas locales de verdad. |
| **Normativa de construcción sísmica (NCh 433)** | INN / MINVU | Si vas a construir. La norma es de pago; los manuales de autoconstrucción del MINVU no. |
| **Guías de autoconstrucción y reparación post-sismo** | MINVU (minvu.gob.cl) | Reparar una casa dañada sin empeorarla. |
| **Calendario de vacunación y red de salud rural** | MINSAL | Qué existía y dónde estaba el consultorio. |

También conviene guardar, en papel y en digital: números de teléfono de vecinos, croquis del
pueblo con pozos y estanques, y quién sabe hacer qué (el que suelda, la que atiende partos, el
que tiene tractor).

## Argentina, Perú, Bolivia

Mismo criterio, otras siglas. Busca el equivalente y anótalo aquí:

| Qué | Argentina | Perú | Bolivia |
|---|---|---|---|
| Emergencias y evacuación | Defensa Civil provincial | INDECI | VIDECI |
| Geología y volcanes | SEGEMAR | INGEMMET | SERGEOMIN |
| Cartografía | IGN | IGN | IGM |
| Agua | INA / autoridad provincial | ANA | SENARI / SENAMHI |
| Suelos y cultivos | INTA | INIA | INIAF |
| Clima | SMN | SENAMHI | SENAMHI |

## El calendario agrícola: llénalo tú

Es lo más valioso y lo único que ARCA no puede traer. Copia esta tabla a
`personal/local/calendario-siembra.md` y complétala con lo que sepan los vecinos viejos:

```
Zona: ______________  Altura: ______ m  Primera helada: ______  Última helada: ______

Cultivo      Siembra      Trasplante   Cosecha      Notas (variedad, riego, plagas)
papa         ...          ...          ...
poroto       ...          ...          ...
maíz         ...          ...          ...
zapallo      ...          ...          ...
acelga       ...          ...          ...
cebolla      ...          ...          ...
ajo          ...          ...          ...
trigo        ...          ...          ...
```

Referencia general por macrozona chilena, para empezar y corregir con la experiencia local:

- **Norte y altiplano**: heladas todo el año en altura, agua escasa; cultivos resistentes
  (quinua, papa amarga, ajo), riego por surco, protección contra el viento.
- **Valle central (mediterráneo)**: siembras de primavera y otoño, verano seco; el problema es
  el agua de enero a marzo, no el frío.
- **Sur lluvioso**: exceso de agua y menos sol; drenaje, invernadero para tomate y pimiento,
  papas y avena rinden.
- **Patagonia y altura**: temporada corta, viento; invernadero casi obligatorio, cultivos de
  ciclo corto y guardado largo (papa, ajo, cebolla).

## Lo que ARCA sí trae y sirve para todo el Cono Sur

- `manuales/agricultura/`: FAO en español (compostaje, huertas, conservación de frutas y
  hortalizas, suelos, riego, aves, apicultura), USDA (conservas, suelos, veterinaria).
- Con `--extra cono-sur`: manuales de la FAO específicos de América Latina (huerto familiar,
  semillas de hortalizas, conservación de suelo y agua en zona seca).
- `mapas/`: Organic Maps de Chile, Argentina, Perú y Bolivia, más el mapa mundial y los datos de
  Natural Earth (costas, ríos, caminos principales, ciudades).
- Kiwix: Wikipedia en español tiene artículo de casi todas las comunas, ríos y volcanes.

## Cómo agregar más mapas de Organic Maps

Edita `MAPAS_PAISES` en `/opt/arca/software.conf` (por ejemplo, para agregar Uruguay y Paraguay):

```
MAPAS_PAISES="Chile Argentina Peru Bolivia Uruguay Paraguay"
```

y ejecuta `sudo /opt/arca/setup.sh --only 5`. Los nombres exactos de cada región salen de
`countries.json` de Organic Maps; el script baja todas las que empiecen por el país.
