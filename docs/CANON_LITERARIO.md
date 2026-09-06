# Qué leer y dónde está

Setenta mil libros sin índice son lo mismo que ninguno. Esta es la guía de lectura del archivo:
qué obras vale la pena tener, en qué carpeta o colección están, y qué hacer para encontrarlas.

Nada de esto es P0: es cultura, la última capa. Pero es la razón por la que vale la pena que
alguien siga vivo.

## Dónde está la literatura en el disco

| Fuente | Qué trae | Perfil | Cómo se abre |
|---|---|---|---|
| **Gutenberg en español** (`gutenberg_es_all`, 1.7 GB) | 892 libros en español: Galdós (62 títulos), Blasco Ibáñez (42), Baroja (25), Darío (23), Pardo Bazán (18), Valera, Pereda, Unamuno, Valle-Inclán, el *Quijote*, la *Celestina*, el *Lazarillo*, *Martín Fierro*, *Facundo*, *Ariel*, *Tradiciones peruanas* | `full` | Kiwix, `http://IP:8080` |
| **Biblioteca de Autores Españoles** (55 tomos PDF) | El Siglo de Oro completo: Lope, Calderón, Tirso, Quevedo, Góngora, Garcilaso, crónicas de Indias, romancero, mística | `full` | `libros/biblioteca-autores-espanoles/` |
| **Wikisource en español** (972 MB) | Textos fuente, poesía suelta, documentos, traducciones | `full` | Kiwix |
| **Harvard Classics** (51 volúmenes) | El canon universal de 1909: griegos, romanos, ingleses, alemanes, franceses, en inglés | `full` | `libros/harvard-classics/` |
| **Gutenberg literatura inglesa** (57 GB, clases P de la LCC) | Toda la literatura de Gutenberg: inglesa, estadounidense, ficción, clásica, rusa, germánica, romances traducidas | `--extra literatura` | Kiwix |
| **Gutenberg completo** (206 GB) | Lo anterior más ciencia, historia, religión, revistas y partituras | `--extra gutenberg-full` | Kiwix |
| **Literatura hispanoamericana del XIX** (9 obras, 182 MB) | Lo que le falta a Gutenberg en español | `full` | `libros/literatura-es/` |
| **Wikisource en inglés** (18 GB) | Textos fuente en inglés | `full` | Kiwix |
| **Britannica 1911** (30 tomos) | Artículos sobre casi todos estos autores, escritos por especialistas de la época | `full` | `libros/britannica-1911/` |

Para buscar: `arca-search "moby dick"` recorre los PDF; el buscador de Kiwix recorre los ZIM.

## Canon en español

**Edad Media y Renacimiento.** *Cantar de Mio Cid* (`libros/literatura-es/`, edición de Menéndez
Pidal) · Berceo · Juan Ruiz, *Libro de buen amor* · Jorge Manrique, *Coplas* · *La Celestina*
(Gutenberg ES) · Garcilaso (BAE) · Fray Luis de León y San Juan de la Cruz (BAE) · Santa Teresa
(BAE).

**Siglo de Oro.** Cervantes, *Don Quijote* y las *Novelas ejemplares* (Gutenberg ES) ·
*Lazarillo de Tormes* (Gutenberg ES) · Quevedo, *El Buscón* y los *Sueños* (Gutenberg ES y BAE) ·
Góngora, *Soledades* y *Polifemo* (`libros/literatura-es/gongora-obras-completas.pdf`) · Lope de
Vega, *Fuenteovejuna*, *El caballero de Olmedo* (BAE) · Calderón, *La vida es sueño*
(`libros/literatura-es/`) · Tirso, *El burlador de Sevilla* (BAE) · Gracián (BAE).

**Siglo XIX español.** Larra, *Artículos* · Espronceda · Bécquer, *Rimas y leyendas* · Zorrilla,
*Don Juan Tenorio* · Galdós, *Fortunata y Jacinta*, *Misericordia*, los *Episodios nacionales* ·
Clarín, *La Regenta* · Pardo Bazán, *Los pazos de Ulloa* · Valera, *Pepita Jiménez*. Casi todo en
Gutenberg ES.

**Generación del 98 y principios del XX.** Unamuno, *Niebla*, *San Manuel Bueno* · Baroja, *El
árbol de la ciencia* · Valle-Inclán, *Sonatas*, *Tirano Banderas* · Azorín · Machado, *Campos de
Castilla* · Blasco Ibáñez. Gutenberg ES tiene la mayoría.

**Hispanoamérica.** Sarmiento, *Facundo* (Gutenberg ES) · José Hernández, *Martín Fierro*
(Gutenberg ES) · Blest Gana, *Martín Rivas* (`libros/literatura-es/`) · Baldomero Lillo, *Sub
Terra* (`libros/literatura-es/`) · Pérez Rosales, *Recuerdos del pasado*
(`libros/literatura-es/`) · Mármol, *Amalia* (`libros/literatura-es/`) · Isaacs, *María*
(`libros/literatura-es/`) · Matto de Turner, *Aves sin nido* (`libros/literatura-es/`) · Ricardo
Palma, *Tradiciones peruanas* (Gutenberg ES) · Rubén Darío, *Azul*, *Prosas profanas* (Gutenberg
ES) · José Martí, *Versos sencillos* · Rodó, *Ariel* (Gutenberg ES) · Horacio Quiroga, *Cuentos
de amor, de locura y de muerte* (Gutenberg ES).

## Canon en inglés

Con `--extra literatura` (o `gutenberg-full`), en Kiwix:

**Poesía y teatro.** Shakespeare, obras completas · Chaucer, *Canterbury Tales* · Milton,
*Paradise Lost* · Donne · Blake · Wordsworth · Keats · Shelley · Byron · Tennyson · Browning ·
Whitman, *Leaves of Grass* · Emily Dickinson · Yeats · T. S. Eliot (parcial por derechos).

**Novela inglesa.** Defoe, *Robinson Crusoe* · Swift, *Gulliver* · Fielding · Sterne, *Tristram
Shandy* · Austen, las seis novelas · Mary Shelley, *Frankenstein* · las Brontë, *Jane Eyre* y
*Cumbres borrascosas* · Dickens, *Casa desolada*, *Grandes esperanzas*, *David Copperfield* ·
George Eliot, *Middlemarch* · Hardy · Stevenson · Conrad, *El corazón de las tinieblas* · Wilde ·
Joyce, *Ulises* y *Dublineses*.

**Novela estadounidense.** Hawthorne, *La letra escarlata* · Melville, *Moby Dick* · Twain,
*Huckleberry Finn* · Henry James · Edith Wharton · Stephen Crane · Jack London · Poe, cuentos y
poemas · Thoreau, *Walden* · Emerson.

**Clásicos griegos y latinos** (clase PA, y en español en Gutenberg y la BAE). Homero, *Ilíada* y
*Odisea* · Sófocles · Esquilo · Eurípides · Aristófanes · Heródoto · Tucídides · Platón ·
Aristóteles · Virgilio, *Eneida* · Ovidio · Séneca · Marco Aurelio · Plutarco.

**Traducidos al inglés** (clases PQ, PT, PG). Dante, *Divina Comedia* · Boccaccio · Montaigne ·
Rabelais · Molière · Voltaire · Balzac · Flaubert · Hugo · Zola · Dostoievski · Tolstói · Chéjov ·
Goethe, *Fausto* · Ibsen · Andersen.

## Lo que no está y por qué

Casi nada del siglo XX tardío: **derechos de autor**. En Chile una obra pasa a dominio público 70
años después de la muerte del autor, así que en 2026 todavía no están García Márquez (m. 2014),
Borges (m. 1986), Neruda (m. 1973), Mistral (m. 1957, entra en 2027), Rulfo, Cortázar, Bolaño,
ni la mayoría de los autores contemporáneos. Tampoco traducciones modernas de clásicos.

Si tienes esos libros en papel o comprados en EPUB sin DRM, cópialos a
`/srv/respaldo/libros/propios/`: se respaldan con todo lo demás y Calibre los indexa
(apunta la biblioteca de Calibre a `/srv/respaldo/libros/`).

## Cómo activar la literatura completa

```bash
sudo /opt/arca/setup.sh --profile full --extra literatura      # 57 GB, solo literatura
sudo /opt/arca/setup.sh --profile full --extra gutenberg-full  # 206 GB, Gutenberg entero
```

No actives los dos: `gutenberg-full` ya contiene todo lo de `literatura`. Las nueve obras
hispanoamericanas de `libros/literatura-es/` vienen con el perfil `full` en ambos casos, porque
no están en el Gutenberg inglés.
