# Lista de materiales para quince años

Sin esto, el servidor es un ladrillo. El orden es de mayor a menor consecuencia si falta.
Los precios cambian y no se ponen aquí; lo que importa es la lista y el porqué.

## 1. Papel y tinta (lo primero, aunque parezca lo último)

| Qué | Cuánto | Por qué |
|---|---|---|
| Impresora láser (mejor que de tinta) | 1 | El tóner no se seca en el cartucho; la tinta sí. Una láser vieja imprime miles de hojas y no se arruina si pasa un año apagada. |
| Resma de papel | 3 a 5 | Print-kit, capítulos clave, registros, calendarios. El papel es el único medio que no depende de electricidad. |
| Tóner o cartuchos de repuesto | 2 | Se compran ahora, no cuando se acabe. |
| Bolsas plásticas con cierre y una caja estanca | varias | El papel se pierde por humedad, no por uso. |
| Lápiz de mina y cuaderno de tapa dura | varios | Los registros de siembra, salud y radio se llevan a mano. |

## 2. El PC y sus discos

| Qué | Cuánto | Por qué |
|---|---|---|
| PC de bajo consumo (mini PC, portátil viejo, i3 o mejor, 8 GB de RAM) | 1 | Un equipo de escritorio grande consume el triple para el mismo trabajo. Un portátil trae batería y pantalla incorporadas. |
| Disco duro (HDD) para la biblioteca | 2 (uno en uso, uno de copia) | El HDD es el medio de archivo frío razonable. El SSD desconectado años pierde datos. |
| SSD para el sistema | 1 | Arranque y respuesta; no guarda la biblioteca. |
| Pendrives de 128 GB | 3 | Perfil `survive` completo. Uno en la casa, uno donde un vecino, uno en la mochila. |
| Caja o adaptador USB para disco | 1 | Para conectar el disco de copia a cualquier equipo. |
| Impresora, teclado y ratón de repuesto | si se puede | Un teclado muerto deja el archivo inaccesible. |

Un disco es una copia, no un archivo: ver el calendario del README y la ficha 18 del print-kit.

## 3. Energía

| Qué | Cuánto | Por qué |
|---|---|---|
| Panel solar de 100 W o más | 1 a 2 | Con 100 W se carga una batería chica y se corre el PC unas horas al día. |
| Regulador de carga | 1 | Sin él la batería se arruina en meses. |
| Batería de ciclo profundo 12 V | 1 a 2 | Las de auto no toleran descargas profundas repetidas. |
| Inversor 12 V a 220 V, onda pura, 300 a 600 W | 1 | Para el PC y la impresora. La onda modificada daña algunas fuentes. |
| Cargador 12 V para el portátil (sin inversor) | 1 | Alimentar directo en 12 V ahorra un 15 a 20 % de pérdidas. |
| Multímetro | 1 | Sin medir no se diagnostica nada eléctrico. |
| Pilas recargables AA/AAA y cargador | 8 a 16 | Radio, linternas, medidores. |
| Linternas y frontales | 1 por persona | Trabajar de noche. |
| Wattímetro de enchufe | 1 | Para saber de verdad cuánto consume tu equipo (ver abajo). |

### Presupuesto energético honesto

No copies números de internet: **mídelo con un wattímetro** en tu propio equipo. Órdenes de
magnitud típicos, para planificar antes de medir:

| Situación | Consumo aproximado |
|---|---|
| Mini PC o portátil en reposo, Kiwix sirviendo páginas | decenas de vatios |
| El mismo equipo con el modelo de 3B respondiendo | sube mientras dura la respuesta, vuelve al reposo |
| El mismo equipo con el modelo de 7B respondiendo | sube más y **durante más tiempo**, porque tarda más |
| Descargas o indexado masivo | como el caso anterior, sostenido durante horas |

Consecuencia práctica: el modelo grande no gasta "más por respuesta" solo por ser grande, gasta
más **porque tarda tres veces más**. Con energía escasa, usa `preguntar.sh --rapido` y apaga el
equipo entre consultas. Un PC encendido las 24 horas para atender tres preguntas al día es el
mayor derroche del sistema: enciéndelo cuando se use.

## 4. Agua, salud y comida (lo que hace que el resto importe)

| Qué | Por qué |
|---|---|
| Cloro (hipoclorito) sin perfume, y frascos oscuros | Potabilizar. Pierde fuerza con el tiempo y el calor: rotarlo. |
| Filtro de agua doméstico y repuestos | Mientras se construye el filtro lento de arena. |
| Bidones y estanque para agua | 4 litros por persona y día, tres días mínimo. |
| Sales de rehidratación oral, sal, azúcar | Lo que más vidas salva por gramo. |
| Botiquín (ficha 14) | Gasas, vendas, tijera, pinzas, termómetro, guantes, jabón. |
| Jabón, y soda cáustica para fabricarlo | Ficha 08. |
| Semillas de polinización abierta, no híbridas | Ficha 11. Compradas ahora, guardadas frías y secas. |
| Sal en cantidad | Conservar carne y pescado. |
| Herramientas de mano: pala, azadón, hacha, serrucho, lima, alicate, llaves | No dependen de electricidad ni de repuestos. |
| Clavos, alambre, cuerda, lona, cinta | Reparar todo lo demás. |

## 5. Comunicación

| Qué | Por qué |
|---|---|
| Radio AM/FM/onda corta a pilas o manivela | Saber qué pasa afuera. AM de noche llega lejos. |
| Handies VHF/UHF (un par) | Coordinar dentro del pueblo o el valle. |
| Equipo de radioaficionado HF, si hay alguien dispuesto a aprender | Hablar a cientos de kilómetros sin infraestructura. |
| Silbato por persona, espejo de señales | Ficha 17. |

## 6. La copia en USB

El perfil `survive` completo entra en un pendrive de 128 GB. Sin la Wikipedia en español con
imágenes (38 GB) baja a unos 17 GB y cabe en uno de 32 GB, conservando medicina, agua,
alimentos, huerta, referencia y el print-kit.

```bash
# copia completa del perfil survive
sudo /opt/arca/backup.sh --mirror /media/TU_USUARIO/USB

# copia mínima sin las enciclopedias grandes
cp -a /srv/respaldo/printkit /srv/respaldo/START_HERE*.txt /srv/respaldo/MANIFEST.tsv \
      /srv/respaldo/manuales /srv/respaldo/referencia /srv/respaldo/docs \
      /srv/respaldo/bootstrap /media/TU_USUARIO/USB/
```

Verifica después con `sha256sum -c bootstrap/SHA256SUMS` dentro del USB. Un pendrive sin
verificar no es una copia: es una ilusión.

## 7. Lo que no se compra

Gente que sepa. El kit sirve si alguien lee los manuales **antes** de necesitarlos y le enseña a
otro. Un adolescente que pasa un invierno leyendo el manual de electricidad vale más que
cualquier repuesto de esta lista.
