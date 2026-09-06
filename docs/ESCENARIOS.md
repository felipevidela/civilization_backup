# Los tres escenarios

ARCA no se prepara para "un colapso" en abstracto. Se prepara para tres cosas concretas que ya
pasaron o casi pasaron, y que cambian qué manual abres primero. Los tres comparten el mismo
núcleo (agua, comida, salud, calor, organización), que es lo que trae el perfil `survive`.

---

## 1. Pandemia con alta mortalidad

**Qué cambia.** No falta electricidad ni comida el primer mes: falta gente. Mueren quienes saben
operar cosas, los hospitales dejan de recibir, la cadena de suministro se corta por ausentismo.
El peligro se concentra en el contagio, en el cuidado de los enfermos en casa y en qué se hace
con los muertos.

**Qué abrir, en orden:**

1. `manuales/medicina/actual/oms-managing-epidemics-2023.pdf`: qué es cada enfermedad grave,
   cómo se transmite, qué corta la cadena.
2. `manuales/medicina/actual/oms-prevencion-infecciones-nosocomiales-es.pdf` y
   `oms-control-infecciones-establecimientos-salud.pdf`: aislamiento, lavado de manos, EPP,
   limpieza, residuos. Vale igual para una casa que para un hospital.
3. `manuales/medicina/actual/oms-manejo-clinico-covid-es.pdf`: cuadro respiratorio grave,
   posición, oxígeno, cuándo empeora.
4. `manuales/medicina/actual/oms-manejo-seguro-de-cadaveres-es.pdf`: el punto que nadie prepara
   y que provoca más contagios y más daño moral.
5. `manuales/agua/` completo: en toda epidemia el agua y el saneamiento hacen la mitad del
   trabajo.
6. Fichas de papel 04 (diarrea), 07 (fiebre), 14 (botiquín).

**Lo que hay que decidir antes, no durante:** quién cuida a los enfermos (siempre la misma
persona, con la misma ropa), dónde se aísla, cómo se recibe algo de afuera, cómo se entierra.

**Lo que no sirve:** buscar el antibiótico correcto por internet o preguntarle al modelo. Sin
diagnóstico no hay tratamiento; los manuales traen los algoritmos.

---

## 2. Invierno nuclear o volcánico

**Qué cambia.** Años de frío, menos luz y cosechas perdidas. En el caso nuclear se suma lluvia
radiactiva las primeras semanas. El problema no es la explosión: es el segundo y el tercer
invierno sin cosecha.

**Primeras 72 horas (solo caso nuclear):**

- `manuales/supervivencia/nuclear-war-survival-skills-kearny-1987.pdf` (Oak Ridge National
  Laboratory, dominio público). Es **protección civil**: refugio improvisado, tiempo de
  permanencia, ventilación, agua, medición. La regla que salva es simple: masa entre tú y la
  ceniza, y quedarse dentro los primeros días, cuando la radiación decae más rápido.
- `manuales/supervivencia/ornl-expedient-fallout-shelter-construction.pdf`: cómo se hace con
  tierra, puertas y madera, en horas.
- `manuales/supervivencia/radiological-monitoring-civil-defense-1963.pdf`: medir sin equipo
  moderno; sin medición, todo es adivinar.

**Los años siguientes (vale igual para invierno volcánico):**

- **Guardar lo que hay ahora**: `manuales/agricultura/usda-home-storage-vegetables-fruits-1955.pdf`
  (bodega fresca sin electricidad) y `usda-complete-guide-home-canning-2015.pdf`.
- **Cultivar con poca luz y poco calor**: ciclos cortos, invernadero y protección del viento;
  papa, nabo, col, cebolla y ajo aguantan lo que el tomate no.
- **Comida sin sol**: `manuales/agricultura/usda-mushroom-growing-1915.pdf`. Los hongos crecen
  en oscuridad con paja y estiércol; es la fuente de proteína más rápida cuando el campo falla.
- **Calor sin matarse**: ficha 12. En invierno largo la primera causa de muerte doméstica es el
  monóxido, no el frío.
- **Semilla**: ficha 11. Un año sin cosecha se aguanta si hay semilla; sin semilla, no.

**Lo que no vas a poder hacer:** agricultura normal. Planifica dos temporadas malas seguidas.

---

## 3. Tormenta solar severa (tipo Carrington)

**Qué cambia.** No muere nadie por la tormenta: muere gente por lo que deja de funcionar. La red
eléctrica de un continente puede caer meses porque los transformadores grandes tardan un año en
fabricarse. El conocimiento sigue intacto, pero deja de ser accesible.

**Referencia:** `manuales/telecomunicaciones/nws-service-assessment-space-weather-2003.pdf`
(informe oficial del NWS sobre las tormentas de 2003: qué falló, cuánto duró). En Kiwix, busca
*Carrington Event* y *geomagnetically induced current*.

**Qué protege de verdad:**

1. **Papel.** El print-kit impreso es inmune. Ver ficha 19.
2. **Copias desconectadas.** Un disco o USB guardado sin conectar, en una caja metálica cerrada,
   sobrevive a lo que le pase a la red. Los datos no se borran por el campo magnético de una
   tormenta solar; lo que mata a los equipos es la sobretensión por los cables. **Desconectar es
   la protección, no el metal.**
3. **Un equipo de repuesto guardado desenchufado**: un portátil viejo con la batería fuera vale
   más que cualquier blindaje.
4. **12 V y baterías** (ver `docs/BOM_15Y.md`): si vuelve el sol pero no la red, sigues leyendo
   el archivo.
5. **Radio a pilas**: la AM y la onda corta vuelven antes que internet.

**Lo que hay que hacer hoy, en diez minutos:** imprimir el print-kit, tener una copia del disco
desconectada, y anotar en papel las direcciones y frecuencias importantes.

---

## Lo que comparten los tres

| Necesidad | Escenario 1 | Escenario 2 | Escenario 3 |
|---|---|---|---|
| Agua tratada | crítica | crítica | crítica |
| Comida guardada | 2 a 6 meses | 2 a 3 años | 1 a 6 meses |
| Salud sin hospital | el centro del problema | importante | importante |
| Calor y refugio | normal | el centro del problema | normal |
| Información sin red | importante | importante | el centro del problema |
| Organización del grupo | crítica | crítica | crítica |

Por eso `survive` es un solo perfil y no tres: lo que cambia entre escenarios es el orden en que
se abren los manuales, no cuáles hacen falta.
