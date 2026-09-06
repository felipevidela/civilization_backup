# Cómo crear una inteligencia artificial desde cero

> **Legado, no año 0.** Nada de esto hace falta para sobrevivir los primeros quince años: está
> guardado por si una generación futura tiene comida, electricidad y tiempo. Si estás en la
> semana 1, esto no es lo que necesitas leer (ver `docs/RECOVERY_ROADMAP.md`).

Guía de ruta para reconstruir, con lo que hay en este disco, un modelo de lenguaje como el
que trae arca. Todo lo citado está en `/srv/respaldo/`: los libros y artículos en
`manuales/ia/`, el código en `software/ia/codigo/`, las librerías de Python en
`software/ia/wheels/`, y la teoría de fondo en los ZIM (Wikipedia, LibreTexts, OpenStax,
Stack Exchange de IA, estadística y ciencia de datos, DevDocs de Python/NumPy/PyTorch).

## Idea central

Un modelo de lenguaje es una función con miles de millones de parámetros que, dado un texto,
predice el siguiente fragmento de palabra. Se entrena ajustando esos parámetros para que
acierte sobre una cantidad enorme de texto (Wikipedia, libros, código). Tres ingredientes:
matemáticas (álgebra lineal, cálculo, probabilidad), un algoritmo (retropropagación con
descenso de gradiente sobre una red "transformer") y cómputo (muchas multiplicaciones de
matrices; sin GPU se puede entrenar un modelo pequeño, no uno grande).

## Etapas y dónde está cada cosa

1. **Matemáticas necesarias.** `manuales/ia/mml-mathematics-for-machine-learning.pdf`
   (Deisenroth, Faisal, Ong). Refuerzo: OpenStax Cálculo (3 vol., en español) y
   Estadística en `libros/openstax-es/`; LibreTexts Math (ZIM).
2. **Programar.** Python: ZIM `devdocs_en_python`, `devdocs_en_numpy`. Instalación sin
   internet de NumPy y PyTorch (CPU, x86_64): `pip install --no-index --find-links
   /srv/respaldo/software/ia/wheels torch numpy tiktoken`. Alternativa sin Python: C
   (`devdocs_en_c`, `devdocs_en_gcc`).
3. **Redes neuronales y retropropagación.** `software/ia/codigo/micrograd` (Karpathy): un
   motor de gradientes automático en 100 líneas de Python; entenderlo es entender el 80 %.
   Teoría: `manuales/ia/rumelhart-1986-backpropagation.pdf` (artículo original),
   `manuales/ia/fleuret-little-book-of-deep-learning.pdf` (corto),
   `manuales/ia/prince-understanding-deep-learning.pdf` y `manuales/ia/d2l-dive-into-deep-learning.pdf`
   (completos, con código).
4. **Tokenización.** El texto se corta en fragmentos (tokens) con "byte-pair encoding":
   `software/ia/codigo/minbpe` (Karpathy). Artículo: `manuales/ia/word2vec-2013.pdf` para
   entender las representaciones de palabras.
5. **El transformer.** `manuales/ia/attention-is-all-you-need-2017.pdf` es el artículo que
   define la arquitectura de todos los modelos actuales. `manuales/ia/bahdanau-2014-attention.pdf`
   es el origen de la atención. Explicación paso a paso con código:
   `software/ia/codigo/LLMs-from-scratch` (Raschka) y `software/ia/codigo/nanoGPT`
   (un GPT-2 completo en ~300 líneas de PyTorch).
6. **Entrenar un modelo real sin GPU.** `software/ia/codigo/llm.c` (Karpathy) entrena GPT-2
   en C puro sobre CPU; su README explica cómo preparar los datos. Corpus: cualquier texto en
   español o inglés. Para extraer texto de los ZIM: `zim-dump` (paquete `zim-tools`, en
   `software/deb/`) o el servidor Kiwix. Con un PC de 8 GB se entrena un modelo de decenas
   de millones de parámetros en días; sirve para aprender, no para competir con el de 7B.
7. **Escalar.** Qué pasa al aumentar datos y parámetros: `manuales/ia/scaling-laws-2020.pdf`
   y `manuales/ia/chinchilla-2022.pdf`. Modelos abiertos documentados: `manuales/ia/llama-2023.pdf`,
   `manuales/ia/llama3-2024.pdf`, `manuales/ia/qwen2.5-2024.pdf`, `manuales/ia/gpt3-2020.pdf`.
8. **Convertirlo en asistente.** Un modelo base solo completa texto. Para que siga
   instrucciones: ajuste con ejemplos y preferencias humanas, `manuales/ia/instructgpt-rlhf-2022.pdf`
   y `manuales/ia/dpo-2023.pdf`. Ajuste barato de un modelo grande: `manuales/ia/lora-2021.pdf`.
9. **Ejecutarlo en cualquier PC.** `software/llm/llama.cpp` (fuentes y binarios) carga
   modelos cuantizados a 4 bits en CPU; `software/ia/codigo/ggml` es la librería numérica
   que lo sustenta. El modelo `software/llm/modelos/*.gguf` es el resultado final de todo
   este proceso, listo para usar con `software/llm/chat.sh` o `preguntar.sh`.

## Trucos que aparecen en el camino

- Optimizador Adam: `manuales/ia/adam-2014.pdf`. Normalización por lotes:
  `manuales/ia/batchnorm-2015.pdf`. Dropout: `manuales/ia/dropout-2012.pdf`. Redes
  residuales: `manuales/ia/resnet-2015.pdf`. Modelos de imagen: `manuales/ia/alexnet-2012.pdf`,
  `manuales/ia/diffusion-2020.pdf`. Lenguaje natural clásico: `manuales/ia/jurafsky-speech-and-language-processing.pdf`.
- Orden recomendado si empiezas de cero: 1 → 3 (micrograd) → 4 → 5 (nanoGPT) → 6 (llm.c).
  Con eso ya has construido y entrenado un modelo de lenguaje por tu cuenta.

## Lo que este disco no puede dar

Cómputo. Un modelo de 7 000 millones de parámetros como el incluido se entrenó con miles de
GPUs durante semanas. Con CPU se reproducen las ideas a escala pequeña; para la escala
grande hace falta fabricar o conseguir aceleradores. El conocimiento para fabricar chips
está en Wikipedia y LibreTexts, pero es una industria entera, no un taller.
