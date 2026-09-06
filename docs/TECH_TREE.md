# Árbol tecnológico

Qué depende de qué. Cada flecha es "hace falta lo anterior". Los enlaces apuntan a carpetas y
documentos de este disco (`/srv/respaldo/`) y a artículos de Wikipedia en Kiwix
(`http://localhost:8080`). Úsalo junto a [RECOVERY_ROADMAP.md](RECOVERY_ROADMAP.md), que
ordena lo mismo en el tiempo.

**Horizonte de cada nodo:**

- **[0-15]** hace falta en los primeros quince años: agua, comida, salud, calor, taller básico,
  electricidad mínima, radio. Es lo que cubren los perfiles `survive` y `core`.
- **[legado]** solo tiene sentido cuando el grupo ya no se muere de nada evitable: metalurgia
  avanzada, química industrial, electrónica, computación, IA. Vive en `recovery` y `full`.

Casi nadie va a llegar a los nodos de legado, y está bien: están guardados por si alguien puede.
Lo que se usa todos los días es la primera mitad de cada rama.

## 1. De la energía a la información

```
Fuego ──► Cerámica ──► Hornos ──► Metalurgia (cobre, bronce, hierro) ──► Herramientas de acero
                                                                           │
                       Máquinas-herramienta (torno, fresadora, taladro) ◄──┘
                                    │
          ┌─────────────────────────┼──────────────────────────┐
          ▼                         ▼                          ▼
   Máquinas de vapor        Motores de combustión        Generadores y motores eléctricos
          │                         │                          │
          └──────────► Electricidad (redes, baterías, transformadores) ◄─┘
                                    │
                    ┌───────────────┼──────────────────┐
                    ▼               ▼                  ▼
              Telégrafo/radio   Electrónica (válvulas → transistores → circuitos integrados)
                                                        │
                                                   Computación ──► Redes ──► Inteligencia artificial
```

| Nodo | Qué necesita | Dónde está el conocimiento |
|---|---|---|
| **[0-15]** Fuego y hornos | leña, carbón vegetal, arcilla | Kiwix: *Charcoal*, *Kiln*; [manuales/ingenieria/cd3wd/](../manuales/ingenieria/cd3wd/) (tecnología apropiada) |
| **[0-15]** Cerámica, cal, vidrio, ladrillo | hornos de 900-1500 °C, arcilla, caliza, arena, sosa | [manuales/materiales/](../manuales/materiales/); Kiwix: *Lime kiln*, *Brick*, *Glass production* |
| **[legado]** Metalurgia | mena, carbón, fuelle, horno; luego alto horno y acero | [manuales/materiales/](../manuales/materiales/); Machinery's Handbook en [manuales/manufactura/](../manuales/manufactura/); Kiwix: *Bloomery*, *Blast furnace*, *Bessemer process* |
| **[0-15]** Herramientas y forja | hierro, yunque, temple | [manuales/manufactura/](../manuales/manufactura/); Kiwix: *Blacksmith*, *Heat treating* |
| **[legado]** Máquinas-herramienta | acero, medición (metrología), tornillos de precisión | [manuales/manufactura/](../manuales/manufactura/) (torno, fresadora, tolerancias); [referencia/](../referencia/) (roscas, ajustes). **Es el nodo clave: una máquina que fabrica máquinas.** |
| **[legado]** Motores térmicos | caldera, cilindro, válvulas, lubricante | [manuales/energia/](../manuales/energia/); Carnot en [libros/fundacionales/](../libros/fundacionales/); Kiwix: *Steam engine*, *Internal combustion engine* |
| **[0-15]** Electricidad (mantener y reparar lo que hay; generar poco) | cobre, imanes o electroimanes, aislantes | [manuales/electricidad/](../manuales/electricidad/); Faraday y Maxwell en [libros/fundacionales/](../libros/fundacionales/); Kiwix: *Electric generator*, *Transformer*, *Lead–acid battery* |
| **[0-15]** Telecomunicaciones (escuchar y hablar por radio) | electricidad, antenas, válvulas o transistores | [manuales/telecomunicaciones/](../manuales/telecomunicaciones/) (TM 11-666 antenas, TM 11-665 transmisores); Stack Exchange *ham* |
| **[legado]** Electrónica | vidrio y vacío (válvulas); silicio purificado (transistores) | Shockley en [libros/fundacionales/](../libros/fundacionales/); Kiwix: *Vacuum tube*, *Transistor*, *Semiconductor device fabrication*; Stack Exchange *electronics* |
| **[legado]** Computación | electrónica, lógica, matemáticas | Turing, Von Neumann y Shannon en [libros/fundacionales/](../libros/fundacionales/); [software/source/](../software/source/) (código fuente fundamental); DevDocs y Stack Exchange técnicos (Kiwix) |
| **[legado]** Inteligencia artificial | computación, álgebra lineal, datos | [software/ia/LEEME.md](../software/ia/LEEME.md); [manuales/ia/](../manuales/ia/) |

## 2. De la comida a las ciudades

```
Agricultura ──► Excedente de alimentos ──► Almacenamiento (granos, conservas) ──► Especialización del trabajo
                                                                                        │
                                              Ciudades ◄── Comercio y registros ◄───────┘
                                                 │
                                       Industria y educación
```

| Nodo | Qué necesita | Dónde |
|---|---|---|
| **[0-15]** Suelo, semillas, riego | conocer el suelo, guardar semilla, agua | [manuales/agricultura/](../manuales/agricultura/); Kiwix: Appropedia, *Crop rotation*, *Seed saving*; Stack Exchange *gardening* |
| **[0-15]** Animales y veterinaria | forraje, cercas, vacunas básicas | [manuales/agricultura/](../manuales/agricultura/); Kiwix: *Animal husbandry* |
| **[0-15]** Conservación de alimentos | sal, azúcar, vinagre, calor, frío | [manuales/agricultura/](../manuales/agricultura/) (FAO); Kiwix: zimgit *food preparation*, *Canning* |
| **[0-15]** Registros, contabilidad, propiedad | escritura, aritmética, acuerdo social | [manuales/instituciones/](../manuales/instituciones/); Kiwix: *Double-entry bookkeeping* |
| **[0-15]** Educación | libros, maestros | [libros/openstax-es/](../libros/openstax-es/), LibreTexts y Wikibooks (Kiwix), Khan Academy y CrashCourse (perfil full) |

## 3. Del agua limpia a las instituciones

```
Agua potable ──► Saneamiento (letrinas, alcantarillado) ──► Salud pública ──► Menos mortalidad
                                                                                   │
                     Instituciones estables ◄── Crecimiento y confianza ◄──────────┘
```

| Nodo | Qué necesita | Dónde |
|---|---|---|
| **[0-15]** Agua potable | fuente, filtro lento de arena, cloro o hervido | [manuales/agua/](../manuales/agua/) (OMS, MSF); Kiwix: zimgit *water*, *Slow sand filter* |
| **[0-15]** Saneamiento | letrinas, distancia a pozos, jabón | [manuales/agua/](../manuales/agua/) (OMS saneamiento, MSF ingeniería sanitaria) |
| **[0-15]** Medicina | agua, higiene, medicamentos esenciales | [manuales/medicina/austera/](../manuales/medicina/austera/) (Hesperian), [manuales/medicina/actual/](../manuales/medicina/actual/) (MSF, OMS), Wikipedia médica (Kiwix) |
| **[0-15]** Salud pública | vacunas, epidemiología, registros | Jenner y Snow en [libros/fundacionales/](../libros/fundacionales/); OMS en [manuales/medicina/actual/](../manuales/medicina/actual/) |
| **[0-15]** Instituciones | derecho, registros civiles, justicia, derechos | [manuales/instituciones/](../manuales/instituciones/); Declaración de Derechos Humanos y Hammurabi en [libros/fundacionales/](../libros/fundacionales/) |

## Cómo usar este árbol

**Empieza por la rama 3 (agua, saneamiento, salud) y la rama 2 (comida), no por la 1.** La rama
del fuego a la computación es la que más ilusión hace y la que menos vidas salva el primer año.

1. Encuentra en qué nodo está tu comunidad (el [RECOVERY_ROADMAP.md](RECOVERY_ROADMAP.md) tiene una lista de comprobación por nivel).
2. Mira qué necesita el siguiente nodo y abre la carpeta indicada; el `LEEME` de cada carpeta dice qué archivo leer primero.
3. Cuando un manual asuma algo que no tienes ("compre un rodamiento"), vuelve un nodo atrás: casi todo lo industrial se fabricó primero a mano.
