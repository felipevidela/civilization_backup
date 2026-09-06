# Política de contenido de ARCA

ARCA no busca "tener muchos datos". Busca que una familia o un pueblo chico, sin red y sin
repuestos, **encuentre, entienda y use** lo que necesita para vivir los próximos quince años.
Cada recurso ocupa espacio, tiempo de descarga y atención de quien lo lea; tiene que ganárselo.

El horizonte no es 2026 recuperado: es que en el año 15 la gente siga viva, comiendo, con agua
limpia y con oficios que se puedan enseñar. Lo demás es subproducto.

## La pregunta guía

Cuatro preguntas, en este orden. La primera que responda "sí" decide la prioridad:

1. **¿Evita una muerte o una hambruna en los próximos 24 meses, aquí?** → P0.
2. **¿Deja un oficio enseñable a un adolescente en tres años?** → P1.
3. **¿Cabe en papel o en un USB de 64 GB, además del disco?** → sube de prioridad; lo que solo
   existe en el disco grande depende de un aparato que se va a morir.
4. **¿Ahorra redescubrimiento técnico a largo plazo?** → P2 o P3, legado.

Un manual de filtro lento de arena responde que sí a la primera. Un tratado de metrología
responde a la segunda. La Britannica de 1911 responde a la cuarta. Las tres pueden estar, con
distinta prioridad y en distinto perfil.

## El disco se va a morir; escríbelo en la primera página

| Componente | Vida útil realista |
|---|---|
| HDD encendido a diario | 5 a 8 años |
| HDD apagado, verificado y rotado | 5 a 15 años |
| SSD apagado sin alimentar | pierde carga; no sirve como archivo frío |
| Fuente y placa del PC | 8 a 15 años |

El archivo digital es una linterna que dura quince años, no una catedral. Lo que de verdad
sobrevive es el papel P0 (`printkit/`) y lo que la gente ya aprendió. Todo el contenido digital
se elige sabiendo eso: si algo solo puede vivir en el disco, se acepta; si puede pasar a papel o
a una cabeza, se prioriza que pase.

## No-goals

- **No** restaurar el nivel tecnológico de 2026.
- **No** entrenar un modelo de lenguaje nuevo ni reconstruir una fábrica de chips.
- **No** suponer que hay bibliotecas físicas, hospitales o ferreterías al alcance el día 1.
- **No** material cuyo propósito sea armas, explosivos o agentes dañinos. El contenido
  científico legítimo con doble uso incidental no se censura, pero no se busca ni se organiza.

## Prioridades

| | Qué es | Horizonte | Ejemplos |
|---|---|---|---|
| **P0** | Vivir los primeros 15 años aquí | semana 1 a año 15 | agua potable, letrinas, heridas, partos, diarrea, conservar comida, huerta, sismo, jabón, leña sin intoxicarse |
| **P1** | Oficios enseñables, años 3 a 15 | año 1 en adelante | taller y metrología, forja, electricidad básica, radio, construcción, veterinaria, matemáticas y ciencia de nivel escuela |
| **P2** | Legado: reconstruir tecnología | si sobra gente y tiempo | manufactura avanzada, química industrial, código fuente, computación, cadena de herramientas |
| **P3** | Cultura e historia | cuando ya no se muere nadie | literatura, filosofía, enciclopedias clásicas, video educativo |

P0 se imprime, se copia a USB y se protege con PAR2. P3 vive en el disco grande y se pierde sin
drama si el disco muere.

## Criterios (en orden, para decidir empates)

1. **Utilidad local en 24 meses.** ¿Alguien lo va a abrir con las manos sucias y un problema
   concreto? Prefiere el manual con dibujos al tratado.
2. **Idioma.** Español primero para P0 y P1: en una emergencia nadie traduce. El inglés se
   acepta cuando no hay equivalente (NEETS, Machinery Repairman) y se anota en el LEEME.
3. **Valor por gigabyte.** Texto y diagramas rinden cien veces más que video. El video entra
   solo en `full`.
4. **Autoridad de la fuente.** Organismos (OMS, FAO, USDA, USGS, ejércitos, universidades) y
   textos originales antes que blogs.
5. **Durabilidad.** Lo que no caduca (anatomía, termodinámica, metalurgia) vale más que lo que
   cambia cada año. Las guías clínicas llevan fecha; lo histórico se etiqueta como histórico.
6. **Facilidad de interpretación.** Formatos abiertos: ZIM, PDF con texto, TXT, Markdown, CSV,
   EPUB. Nada que exija un programa propietario o una red.
7. **Licencia.** Dominio público, Creative Commons o distribución explícita. Si no se puede
   confirmar, no entra activo: queda comentado con `TODO:` y el motivo.
8. **Redundancia.** Si Wikipedia lo cubre igual de bien, no se duplica. Las copias deliberadas
   (varios manuales de agua) se justifican por autoridad o idioma.
9. **Materiales alcanzables.** Prefiere procesos con cal, ladrillo, forja y plomo-ácido a los
   que exigen una industria intacta.
10. **Actualización.** ¿Hay URL estable para saber si salió versión nueva? Si no, se anota la
    fecha de la copia.

## Perfiles

| Perfil | Tamaño real | Para qué |
|---|---|---|
| **`survive`** (alias `15y`) | ~55 GB | Los quince años. Medicina austera y actual, agua y saneamiento, alimentos, huerta, sismo, reparación, Wikipedia en español, tecnología apropiada, mapas del país, modelo de lenguaje de 3B, print-kit. Cabe con holgura en un disco de 128 GB. |
| **`core`** | ~63 GB | survive + ciencia básica (LibreTexts), educación, diccionarios, energía. |
| **`recovery`** | ~255 GB | core + oficios e industria: manufactura, materiales, electricidad, telecomunicaciones, construcción, computación, código fuente, OpenStax, ISO de Ubuntu, modelo de 7B, kit de IA. |
| **`full`** | ~480 GB | recovery + legado y cultura: Khan Academy, CrashCourse, Wikisource, textos fundacionales, Britannica, Harvard Classics, Stack Exchange de humanidades. |
| extras | opcionales | `cono-sur` (Chile y vecinos), `gutenberg-full`, `stackoverflow-full`, `wikipedia-fr`, `wikipedia-en-nopic`. |

`full` debe dejar al menos 150 GB libres en un disco de 1 TB para poder descargar versiones
nuevas antes de borrar las viejas.

### La variante USB

`survive` sin `wikipedia_es_all_maxi` (38 GB) baja a unos 17 GB y cabe en un USB de 32 GB; con
la Wikipedia en español necesita uno de 128 GB. Esa es la copia que se lleva alguien que se va
del pueblo. Se documenta en `docs/BOM_15Y.md`; no es un perfil aparte para no multiplicar
combinaciones que después nadie prueba.

## Cómo proponer un recurso

Añade una línea a `packs.conf` o `manuals.conf` con perfil, prioridad y categoría, verifica la
URL (`setup.sh --dry-run` la resuelve y muestra el tamaño real), indica la licencia si la
conoces y explica en el comentario qué problema resuelve. Si no puedes verificar la URL o la
licencia, déjala comentada con `TODO:` y el motivo.

Antes de agregar algo grande, pregúntate qué sacarías para que quepa. Si la respuesta es "nada,
igual cabe", es que va a `full` y no a `survive`.
