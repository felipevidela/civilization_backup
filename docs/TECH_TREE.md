# Árbol tecnológico

Qué depende de qué. Cada flecha es "hace falta lo anterior". Los enlaces apuntan a carpetas y
documentos de este disco (`/srv/respaldo/`) y a artículos de Wikipedia en Kiwix
(`http://localhost:8080`). Úsalo junto a [RECOVERY_ROADMAP.md](RECOVERY_ROADMAP.md), que
ordena lo mismo en el tiempo.

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
| Fuego y hornos | leña, carbón vegetal, arcilla | Kiwix: *Charcoal*, *Kiln*; [manuales/ingenieria/cd3wd/](../manuales/ingenieria/cd3wd/) (tecnología apropiada) |
| Cerámica, cal, vidrio, ladrillo | hornos de 900-1500 °C, arcilla, caliza, arena, sosa | [manuales/materiales/](../manuales/materiales/); Kiwix: *Lime kiln*, *Brick*, *Glass production* |
| Metalurgia | mena, carbón, fuelle, horno; luego alto horno y acero | [manuales/materiales/](../manuales/materiales/); Machinery's Handbook en [manuales/manufactura/](../manuales/manufactura/); Kiwix: *Bloomery*, *Blast furnace*, *Bessemer process* |
| Herramientas y forja | hierro, yunque, temple | [manuales/manufactura/](../manuales/manufactura/); Kiwix: *Blacksmith*, *Heat treating* |
| Máquinas-herramienta | acero, medición (metrología), tornillos de precisión | [manuales/manufactura/](../manuales/manufactura/) (torno, fresadora, tolerancias); [referencia/](../referencia/) (roscas, ajustes). **Es el nodo clave: una máquina que fabrica máquinas.** |
| Motores térmicos | caldera, cilindro, válvulas, lubricante | [manuales/energia/](../manuales/energia/); Carnot en [libros/fundacionales/](../libros/fundacionales/); Kiwix: *Steam engine*, *Internal combustion engine* |
| Electricidad | cobre, imanes o electroimanes, aislantes | [manuales/electricidad/](../manuales/electricidad/); Faraday y Maxwell en [libros/fundacionales/](../libros/fundacionales/); Kiwix: *Electric generator*, *Transformer*, *Lead–acid battery* |
| Telecomunicaciones | electricidad, antenas, válvulas o transistores | [manuales/telecomunicaciones/](../manuales/telecomunicaciones/) (TM 11-666 antenas, TM 11-665 transmisores); Stack Exchange *ham* |
| Electrónica | vidrio y vacío (válvulas); silicio purificado (transistores) | Shockley en [libros/fundacionales/](../libros/fundacionales/); Kiwix: *Vacuum tube*, *Transistor*, *Semiconductor device fabrication*; Stack Exchange *electronics* |
| Computación | electrónica, lógica, matemáticas | Turing, Von Neumann y Shannon en [libros/fundacionales/](../libros/fundacionales/); [software/source/](../software/source/) (código fuente fundamental); DevDocs y Stack Exchange técnicos (Kiwix) |
| Inteligencia artificial | computación, álgebra lineal, datos | [software/ia/LEEME.md](../software/ia/LEEME.md); [manuales/ia/](../manuales/ia/) |

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
| Suelo, semillas, riego | conocer el suelo, guardar semilla, agua | [manuales/agricultura/](../manuales/agricultura/); Kiwix: Appropedia, *Crop rotation*, *Seed saving*; Stack Exchange *gardening* |
| Animales y veterinaria | forraje, cercas, vacunas básicas | [manuales/agricultura/](../manuales/agricultura/); Kiwix: *Animal husbandry* |
| Conservación de alimentos | sal, azúcar, vinagre, calor, frío | [manuales/agricultura/](../manuales/agricultura/) (FAO); Kiwix: zimgit *food preparation*, *Canning* |
| Registros, contabilidad, propiedad | escritura, aritmética, acuerdo social | [manuales/instituciones/](../manuales/instituciones/); Kiwix: *Double-entry bookkeeping* |
| Educación | libros, maestros | [libros/openstax-es/](../libros/openstax-es/), LibreTexts y Wikibooks (Kiwix), Khan Academy y CrashCourse (perfil full) |

## 3. Del agua limpia a las instituciones

```
Agua potable ──► Saneamiento (letrinas, alcantarillado) ──► Salud pública ──► Menos mortalidad
                                                                                   │
                     Instituciones estables ◄── Crecimiento y confianza ◄──────────┘
```

| Nodo | Qué necesita | Dónde |
|---|---|---|
| Agua potable | fuente, filtro lento de arena, cloro o hervido | [manuales/agua/](../manuales/agua/) (OMS, MSF); Kiwix: zimgit *water*, *Slow sand filter* |
| Saneamiento | letrinas, distancia a pozos, jabón | [manuales/agua/](../manuales/agua/) (OMS saneamiento, MSF ingeniería sanitaria) |
| Medicina | agua, higiene, medicamentos esenciales | [manuales/medicina/austera/](../manuales/medicina/austera/) (Hesperian), [manuales/medicina/actual/](../manuales/medicina/actual/) (MSF, OMS), Wikipedia médica (Kiwix) |
| Salud pública | vacunas, epidemiología, registros | Jenner y Snow en [libros/fundacionales/](../libros/fundacionales/); OMS en [manuales/medicina/actual/](../manuales/medicina/actual/) |
| Instituciones | derecho, registros civiles, justicia, derechos | [manuales/instituciones/](../manuales/instituciones/); Declaración de Derechos Humanos y Hammurabi en [libros/fundacionales/](../libros/fundacionales/) |

## Cómo usar este árbol

1. Encuentra en qué nodo está tu comunidad (el [RECOVERY_ROADMAP.md](RECOVERY_ROADMAP.md) tiene una lista de comprobación por nivel).
2. Mira qué necesita el siguiente nodo y abre la carpeta indicada; el `LEEME` de cada carpeta dice qué archivo leer primero.
3. Cuando un manual asuma algo que no tienes ("compre un rodamiento"), vuelve un nodo atrás: casi todo lo industrial se fabricó primero a mano.
