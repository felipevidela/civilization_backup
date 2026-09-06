# Hoja de ruta: los primeros quince años

Dos escalas. Primero **S0 a S15**, que es lo que de verdad va a pasar: la semana 1, el mes 1, el
año 1, el año 5 y el año 15 de un grupo concreto en un lugar concreto. Después, como apéndice,
los **niveles 0 a 7** de reconstrucción industrial, que solo importan si sobra gente y tiempo.

Las rutas son relativas a `/srv/respaldo/`; "Kiwix" es `http://IP-DEL-PC:8080`; "ficha N" es
`printkit/fichas/`.

---

## S0 · Semana 1: que no muera nadie por algo evitable

**Meta:** agua tratada, heridas atendidas, refugio, y saber quién es quién.

| Hacer | Dónde |
|---|---|
| Tratar toda el agua: hervir 1 minuto (3 sobre 2.000 m) o clorar y esperar 30 min | ficha 01, `manuales/agua/` |
| Heridas, hemorragias, fracturas, quemaduras | ficha 05, `manuales/supervivencia/fm-4-25.11-first-aid.pdf` |
| Diarrea: suero de rehidratación desde la primera deposición líquida | ficha 04 |
| Refugio, abrigo, fuego seguro (nada de brasero adentro) | fichas 12 y 13, `manuales/supervivencia/` |
| Contar personas: quién sabe qué, quién está enfermo, quién falta | cuaderno |
| Inventario de comida y agua, y racionarla desde el día 1, no cuando se acabe | cuaderno |
| **Imprimir el print-kit mientras haya luz e impresora** | `printkit/README.md` |

**Trampa habitual:** gastar la semana 1 en tecnología (paneles, radio, el servidor) mientras
alguien toma agua sin tratar.

## S1 · Mes 1: dejar de improvisar

**Meta:** agua segura permanente, letrinas, comida para semanas, un lugar donde se atiende a los
enfermos.

| Hacer | Dónde |
|---|---|
| Letrinas a más de 30 m de pozos y aguas abajo; lavado de manos con jabón | ficha 03, `manuales/agua/oms-guias-saneamiento-salud-es.pdf` |
| Empezar el filtro lento de arena (tarda 2-3 semanas en madurar) | ficha 02, `manuales/agua/oms-slow-sand-filtration-huisman-wood-1974.pdf` |
| Conservar lo que hay: secar, salar, ahumar. Cuidado con el botulismo al envasar | ficha 09, `manuales/agricultura/usda-complete-guide-home-canning-2015.pdf` |
| Sembrar lo primero, aunque sea poco y mal: los tiempos no esperan | ficha 10, `manuales/agricultura/` |
| Jabón: si no se compra, se fabrica | ficha 08, `manuales/industria/soap-making-manual-1922.pdf` |
| Botiquín y quién lo administra; leer los capítulos **antes** de necesitarlos | ficha 14, `manuales/medicina/` |
| Radio: escuchar a horas fijas y anotar | ficha 17 |
| Copia del disco a otro medio y verificación | ficha 18, `backup.sh --mirror` |
| Registro civil casero: nacimientos, muertes, acuerdos, deudas | `manuales/instituciones/` |

## S2 · Año 1: comer de lo propio

**Meta:** una cosecha completa, animales, un taller que repara, una escuela.

| Hacer | Dónde |
|---|---|
| Huerta en serio: rotación, compost, riego, plagas | `manuales/agricultura/`, Appropedia y Stack Exchange *gardening* en Kiwix |
| **Guardar semilla de la primera cosecha** (sin esto, no hay año 2) | ficha 11 |
| Gallinas y, si se puede, cabras: proteína y abono | ficha 16, `manuales/agricultura/fao-small-scale-poultry-production.pdf` |
| Veterinaria básica: animales enfermos aislados, no comidos | `manuales/agricultura/usda-keeping-livestock-healthy-1942.pdf` |
| Taller: afilar, soldar o remachar, reparar herramientas | `manuales/manufactura/`, iFixit en Kiwix |
| Escuela: leer, escribir, aritmética. Vikidia y Wikibooks en español | Kiwix, `libros/openstax-es/` |
| Salud materna: quién atiende partos y con qué manual | ficha 06, `manuales/medicina/austera/hesperian-a-book-for-midwives.pdf` |
| Calendario agrícola propio, escrito | `docs/LOCAL.md` |

## S3 · Años 2 a 5: oficios y repuestos

**Meta:** que el grupo produzca lo que consume y que alguien joven sepa cada oficio.

- **Electricidad**: mantener el panel y la batería, reparar cableado, entender un multímetro.
  `manuales/electricidad/neets/` (24 módulos, de corriente continua a antenas).
- **Metal y madera**: forja, fundición sencilla, carpintería, medición con tolerancias.
  `manuales/manufactura/`, `referencia/tablas-basicas.txt`.
- **Construcción**: reparar techos, cimientos, drenaje, sismo. `manuales/construccion/`.
- **Materiales**: cal, ladrillo, carbón vegetal, jabón, papel. `manuales/materiales/`,
  `manuales/industria/`.
- **Salud**: formar a alguien más; la persona que sabe curar no puede ser una sola.
- **Institución**: reglas escritas para el agua, la tierra y los conflictos.
  `manuales/instituciones/roberts-rules-of-order-1915.pdf`.
- **Enseñar**: cada oficio con un aprendiz. Un oficio en una sola cabeza se pierde con una gripe.

**El disco a los 5 años:** ya vale menos que las cabezas y el papel. Cámbialo por uno nuevo
mientras todavía se pueda copiar (ficha 18).

## S4 · Años 5 a 15: que sobreviva el conocimiento, no el aparato

**Meta:** que el archivo deje de ser imprescindible.

- Copiar lo importante a papel y a cuadernos propios, con las correcciones de la experiencia
  local. Un cuaderno con lo que funcionó en tu valle vale más que el PDF del que salió.
- Repetir el ciclo de verificación y copia cada año, aunque nadie lo pida (`check.sh --scrub`).
- Mantener un equipo que lea el disco: repuestos, una fuente, un teclado. Sin eso, el archivo
  existe pero no se abre.
- Enseñar a leer los manuales: la biblioteca es inútil si solo una persona sabe buscar.
- Cuando el hardware falle definitivamente: lo que quede en papel y en la gente **es** el
  archivo. Ese era el plan desde el principio.

### Lista de comprobación rápida

| Pregunta | Si la respuesta es no, estás en |
|---|---|
| ¿Todos beben agua tratada? | S0 |
| ¿Hay letrinas y comida para un mes? | S1 |
| ¿Hubo cosecha propia y se guardó semilla? | S2 |
| ¿Cada oficio tiene al menos dos personas que lo saben? | S3 |
| ¿Hay copia verificada del disco y papel impreso este año? | S4 |

---

# Apéndice: reconstrucción industrial (niveles 0 a 7)

Esto ya no es sobrevivir: es volver a fabricar. Solo tiene sentido cuando el grupo tiene
excedente de comida y de gente. Niveles, no fechas; varios conviven.

## Nivel 0 — Supervivencia (ver S0, arriba)
Objetivo: nadie muere por algo evitable.
- Agua: hervir 1 minuto o clorar; nunca beber de fuentes dudosas sin tratar. → `manuales/agua/` (OMS agua potable), Kiwix zimgit *water*.
- Heridas, hemorragias, fracturas, quemaduras. → `manuales/supervivencia/fm-4-25.11-first-aid.pdf`, `manuales/medicina/austera/` (*Where There Is No Doctor*).
- Refugio, frío y calor, señales. → `manuales/supervivencia/` (FM 21-76), Kiwix zimgit *post-disaster*.
- Organizar personas: quién sabe qué, turnos, inventario. → `START_HERE.txt`.

## Nivel 1 — Asentamiento estable (ver S1)
Objetivo: agua segura permanente, letrinas, comida asegurada para semanas, enfermos atendidos.
- Filtro lento de arena y cloración; letrinas a más de 30 m y aguas abajo de los pozos. → `manuales/agua/` (MSF ingeniería sanitaria, OMS saneamiento).
- Higiene, jabón, control de vectores. → `manuales/medicina/actual/` (MSF guía clínica), Kiwix *Soap*.
- Alimentos: conservar lo que hay (secado, salado, ahumado). → `manuales/agricultura/` (FAO conservación), Kiwix zimgit *food preparation*.
- Energía mínima: leña eficiente, velas, pilas; radio para escuchar. → `manuales/energia/`, `manuales/telecomunicaciones/`.
- Registro de nacimientos, muertes, acuerdos. → `manuales/instituciones/`.

## Nivel 2 — Agricultura y talleres (ver S2)
Objetivo: cosecha propia, animales, taller que repara y fabrica herramientas simples.
- Suelo, compost, rotación, semillas guardadas, riego. → `manuales/agricultura/`, Kiwix Appropedia y *gardening*.
- Aves, cabras, apicultura, veterinaria básica. → `manuales/agricultura/`.
- Forja, carpintería, reparación. → `manuales/manufactura/`, Kiwix iFixit, Stack Exchange *woodworking*.
- Escuela: leer, escribir, aritmética; enciclopedia para niños. → Vikidia y Wikibooks (Kiwix), `libros/openstax-es/`.
- Salud: medicamentos esenciales, obstetricia, vacunas si hay cadena de frío. → `manuales/medicina/actual/` (OMS lista de medicamentos, MSF obstetricia).

## Nivel 3 — Industria básica
Objetivo: producir materiales: cal, ladrillo, vidrio, hierro, acero, cemento, papel, jabón, fertilizante.
- Hornos, cal, cerámica, ladrillo. → `manuales/materiales/`, `manuales/construccion/`.
- Metalurgia: horno de reducción, forja, temple, fundición. → `manuales/materiales/`, `manuales/manufactura/` (Machinery's Handbook).
- Máquinas-herramienta: metrología, torno, fresadora. **Prioridad máxima: con ellas se fabrica todo lo demás.** → `manuales/manufactura/`, `referencia/` (roscas, tolerancias).
- Motores térmicos y bombas. → `manuales/energia/`, Kiwix *Steam engine*.
- Construcción: cimentaciones, techos, puentes sencillos, topografía. → `manuales/construccion/`.

## Nivel 4 — Electricidad y telecomunicaciones
Objetivo: generación local, baterías, motores, radio bidireccional.
- Generadores y motores (imanes, bobinas), transformadores, redes pequeñas, protección. → `manuales/electricidad/`, Faraday y Maxwell en `libros/fundacionales/`.
- Hidráulica, eólica, solar si quedan paneles; plomo-ácido. → `manuales/energia/`, Kiwix Energypedia.
- Telégrafo, radio AM y onda corta, antenas. → `manuales/telecomunicaciones/` (TM 11-666, TM 11-665), Stack Exchange *ham*.

## Nivel 5 — Industria avanzada
Objetivo: química industrial civil, acero de calidad, maquinaria de precisión, transporte.
- Ácidos, álcalis, fertilizantes, lubricantes, pinturas. → `manuales/industria/`, Kiwix *Haber process*, *Contact process*, LibreTexts Química.
- Metalurgia avanzada y tratamientos térmicos. → `manuales/materiales/` (NASA), `manuales/manufactura/`.
- Motores de combustión, vehículos, carreteras. → `manuales/energia/`, `manuales/construccion/`, Stack Exchange *mechanics*.

## Nivel 6 — Computación
Objetivo: volver a fabricar y programar computadores.
- Electrónica: válvulas, luego transistores; circuitos. → `libros/fundacionales/` (Shockley), Stack Exchange *electronics*, *arduino*, *raspberrypi*.
- Lógica y arquitectura. → Turing, Von Neumann, Shannon en `libros/fundacionales/`.
- Software desde el código fuente: compilador, sistema operativo, bases de datos. → `software/source/`, DevDocs (Kiwix), `docs/DIGITAL_FORMATS.md`.
- Este propio archivo: `bootstrap/` explica cómo volver a abrirlo con lo mínimo.

## Nivel 7 — Ciencia y tecnología avanzada
Objetivo: investigación propia, medicina moderna, energía a gran escala, inteligencia artificial.
- Ciencia completa: Wikipedia EN/ES, LibreTexts, OpenStax, Stack Exchange de física, química, matemáticas.
- Medicina moderna: MSF, OMS, Wikipedia médica; anatomía de referencia.
- IA: `software/ia/LEEME.md`, `manuales/ia/`, el modelo local en `software/llm/`.
- Energía nuclear, aeroespacial, semiconductores: la física está en Wikipedia y los textos fundacionales; la industria hay que reconstruirla nivel a nivel.

## Lista de comprobación industrial
| Pregunta | Si la respuesta es no, estás en |
|---|---|
| ¿Todos beben agua tratada? | Nivel 0 |
| ¿Hay letrinas y comida para un mes? | Nivel 1 |
| ¿Hay cosecha propia y un taller que repara? | Nivel 2 |
| ¿Se produce hierro, cal y ladrillo? | Nivel 3 |
| ¿Hay electricidad y radio? | Nivel 4 |
| ¿Hay química industrial y motores propios? | Nivel 5 |
| ¿Se fabrican y programan computadores? | Nivel 6 |
