# Política de contenido de ARCA

ARCA no busca "tener muchos datos". Busca que una comunidad futura pueda **encontrar, entender,
verificar y usar** el conocimiento necesario para pasar de la supervivencia a una civilización
técnica. Cada recurso ocupa espacio, tiempo de descarga y atención de quien lo lea; tiene que
ganárselo.

## La pregunta guía

> ¿Cuántos años de redescubrimiento tecnológico, científico, médico o institucional podría
> ahorrar este recurso?

Un manual de filtros lentos de arena ahorra epidemias. Un tratado de metrología ahorra décadas
de "máquinas que no encajan". Una colección de citas célebres ahorra poco. Los tres pueden estar,
pero no con la misma prioridad ni en el mismo perfil.

## Criterios (en orden)

1. **Valor civilizatorio.** ¿Enseña a hacer algo que reduce mortalidad, produce comida, agua,
   energía, herramientas, o transmite ciencia y matemáticas? P0 si es de vida o muerte; P1 si
   es un cuello de botella técnico; P2 si complementa; P3 si es cultural.
2. **Valor por gigabyte.** Texto y diagramas rinden cien veces más que video por byte. El video
   entra solo en `full` y cuando enseña algo que el texto no puede mostrar.
3. **Autoridad de la fuente.** Organismos (OMS, FAO, USDA, USGS, NASA, ejércitos, universidades)
   y textos originales antes que blogs. Fuentes revisadas antes que compilaciones anónimas.
4. **Durabilidad.** Conocimiento que no caduca (anatomía, termodinámica, metalurgia básica) vale
   más que el que cambia cada año. Lo que cambia (guías clínicas) se marca con fecha y se
   actualiza; lo histórico se etiqueta como histórico.
5. **Facilidad de interpretación.** Formatos abiertos y simples: ZIM, PDF con texto, TXT,
   Markdown, CSV, EPUB. Nada que exija un programa propietario o una red.
6. **Licencia.** Dominio público, Creative Commons, licencias libres o distribución explícita
   permitida. Si no se puede confirmar, el recurso no entra activo; queda como TODO documentado.
7. **Redundancia.** Si Wikipedia ya lo cubre igual de bien, no hace falta duplicarlo. Las
   copias deliberadas (varios manuales de agua) se justifican por autoridad o idioma.
8. **Relevancia para la recuperación.** Preferir procesos con materiales y herramientas
   alcanzables (cal, ladrillo, forja, plomo-ácido) a los que exigen una industria intacta.
9. **Actualización.** ¿Tiene una URL estable y un mecanismo para saber si hay versión nueva?
   Si no, se documenta la fecha de la copia.
10. **Riesgo.** ARCA es civil. No entran colecciones cuyo propósito sea armas, explosivos o
    agentes dañinos. El contenido científico legítimo con doble uso incidental no se censura,
    pero no se buscan ni se organizan instrucciones de daño.

## Perfiles

| Perfil | Tamaño aprox. | Qué contiene |
|---|---|---|
| **core** | ~60 GB | Medicina austera y actual, agua y saneamiento, alimentos, tecnología apropiada, reparación, Wikipedia en español, ciencia básica (LibreTexts), mapas regionales, software para leerlo todo, modelo de lenguaje pequeño. |
| **recovery** | ~255 GB | core + Wikipedia en inglés con imágenes, ingeniería, manufactura, energía, materiales, telecomunicaciones, computación (DevDocs, Stack Exchange técnicos, código fuente), libros universitarios, ISO de Ubuntu, modelo de lenguaje grande, kit de IA. |
| **full** | ~490 GB | recovery + historia, filosofía, literatura, textos fundacionales, enciclopedias clásicas, video educativo (Khan Academy, CrashCourse), Stack Exchange de humanidades y aficiones. |
| extras | opcionales | Gutenberg inglés completo (206 GB), Stack Overflow completo (107 GB), Wikipedia francés (50 GB). Se activan con `--extra`. |

`full` debe dejar al menos 150 GB libres en un disco de 1 TB para poder descargar versiones
nuevas antes de borrar las viejas.

## Prioridades y qué implican

- **P0**: se protege con PAR2 cuando es pequeño, va en `bootstrap/` si es documentación, y el
  asistente solo responde con fuentes en sus categorías críticas (medicina, agua).
- **P1**: entra en `recovery`; se indexa para búsqueda local.
- **P2**: entra en `full`; se indexa.
- **P3**: entra en `full` o en extras; puede quedar sin índice si el espacio aprieta.

## Cómo proponer un recurso

Añade una línea a `packs.conf` o `manuals.conf` con perfil, prioridad y categoría, verifica
la URL (`setup.sh --dry-run` la resuelve y muestra el tamaño real), indica la licencia si la
conoces y explica en el comentario qué problema resuelve. Si no puedes verificar la URL o la
licencia, déjala comentada con `TODO:` y el motivo.
