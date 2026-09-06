# Hoja de ruta de recuperación

Niveles, no fechas: cada comunidad avanza a su ritmo y varios niveles conviven. Cada nivel dice
qué asegurar antes de pasar al siguiente y dónde está en este disco lo necesario. Las rutas son
relativas a `/srv/respaldo/`; "Kiwix" es `http://IP-DEL-PC:8080`.

## Nivel 0 — Supervivencia (primeras 72 horas)
Objetivo: nadie muere por algo evitable.
- Agua: hervir 1 minuto o clorar; nunca beber de fuentes dudosas sin tratar. → `manuales/agua/` (OMS agua potable), Kiwix zimgit *water*.
- Heridas, hemorragias, fracturas, quemaduras. → `manuales/supervivencia/fm-4-25.11-first-aid.pdf`, `manuales/medicina/austera/` (*Where There Is No Doctor*).
- Refugio, frío y calor, señales. → `manuales/supervivencia/` (FM 21-76), Kiwix zimgit *post-disaster*.
- Organizar personas: quién sabe qué, turnos, inventario. → `START_HERE.txt`.

## Nivel 1 — Asentamiento estable (primer mes)
Objetivo: agua segura permanente, letrinas, comida asegurada para semanas, enfermos atendidos.
- Filtro lento de arena y cloración; letrinas a más de 30 m y aguas abajo de los pozos. → `manuales/agua/` (MSF ingeniería sanitaria, OMS saneamiento).
- Higiene, jabón, control de vectores. → `manuales/medicina/actual/` (MSF guía clínica), Kiwix *Soap*.
- Alimentos: conservar lo que hay (secado, salado, ahumado). → `manuales/agricultura/` (FAO conservación), Kiwix zimgit *food preparation*.
- Energía mínima: leña eficiente, velas, pilas; radio para escuchar. → `manuales/energia/`, `manuales/telecomunicaciones/`.
- Registro de nacimientos, muertes, acuerdos. → `manuales/instituciones/`.

## Nivel 2 — Agricultura y talleres (primer año)
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

## Lista de comprobación rápida
| Pregunta | Si la respuesta es no, estás en |
|---|---|
| ¿Todos beben agua tratada? | Nivel 0 |
| ¿Hay letrinas y comida para un mes? | Nivel 1 |
| ¿Hay cosecha propia y un taller que repara? | Nivel 2 |
| ¿Se produce hierro, cal y ladrillo? | Nivel 3 |
| ¿Hay electricidad y radio? | Nivel 4 |
| ¿Hay química industrial y motores propios? | Nivel 5 |
| ¿Se fabrican y programan computadores? | Nivel 6 |
