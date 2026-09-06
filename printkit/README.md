# Print-kit: lo que hay que imprimir el día 1

Veinte fichas de una hoja cada una, en español llano, que se entienden sin computador. Son la
parte de ARCA que sobrevive al PC: el disco dura entre 5 y 8 años encendido; el papel guardado
seco dura décadas.

**Si no imprimiste esto, el proyecto no está terminado, aunque Kiwix funcione.**

## Cómo imprimir

```bash
cd /srv/respaldo/printkit/fichas
```

Las fichas son texto plano con formato Markdown: se imprimen desde cualquier editor, navegador o
procesador de texto. Sin herramientas extra, lo más simple es abrirlas y usar "Imprimir".

Con `pandoc` o `libreoffice` instalados sale más prolijo, pero **no lo esperes**: si hay que
elegir entre imprimir feo hoy o bonito nunca, imprime feo hoy.

Recomendaciones:

- **A4, doble cara**, letra de 11 o 12 puntos, márgenes anchos.
- Una ficha por hoja (o dos caras si van dos fichas del mismo tema).
- Papel más grueso para las fichas 01, 04, 05 y 13: son las que se mojan y se manosean.
- **Tres tacos separados**, no un solo mazo grapado:
  1. **Cuerpo**: fichas 04, 05, 06, 07, 14, 15.
  2. **Agua y comida**: fichas 01, 02, 03, 09, 10, 11, 16.
  3. **Casa y taller**: fichas 08, 12, 13, 17, 18, 19, 20.
- Escribe **la fecha a mano** en cada taco.
- Un juego completo guardado **fuera de la casa**, en bolsa plástica cerrada.

## Qué imprimir si queda poca tinta

Ver la ficha **19**: trae el orden exacto, de lo que salva vidas a lo que se puede perder.

## Qué NO son estas fichas

No son manuales. Cada una termina diciendo qué archivo del disco la reemplaza. Sirven para no
equivocarse en lo grueso, para acordarse de lo que ya se leyó y para que alguien que nunca usó
el PC pueda hacer algo útil.

Ninguna ficha inventa dosis ni protocolos médicos: cuando hace falta una cantidad exacta, remite
al manual de la OMS, de MSF, de Hesperian o del USDA que está en el disco.

## Archivos

- `fichas/01` a `fichas/20`: las fichas.
- `MANIFIESTO.tsv`: qué imprimir, cuántas hojas y cuántas copias.
- `START_HERE_PAPEL.txt`: la portada del archivo, para quien encuentre el disco sin saber qué es.
