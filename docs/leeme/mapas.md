# Mapas

- `*.mwm`: mapas detallados de Chile, Argentina, Perú y Bolivia más `World.mwm` y `WorldCoasts.mwm`
  (vista mundial) para **Organic Maps** (APK en `../software/organicmaps/`, Flatpak en Linux). Copia
  los `.mwm` a la carpeta de mapas de la app. Funcionan sin internet, con GPS, rutas y búsqueda.
- `mundo/`: datos abiertos de **Natural Earth** (dominio público): países, provincias, ciudades,
  costas, ríos, carreteras, puertos y aeropuertos a 1:10 000 000, y relieve en imagen TIFF.
  Son shapefiles (`.shp` + `.dbf` + `.prj`, formato documentado en Wikipedia) y en
  `natural_earth_vector.zip` también GeoPackage (SQLite). Se abren con QGIS (código en
  `../software/source/` si el perfil lo incluye), GDAL, o cualquier programa que lea shapefile; el
  `.dbf` de atributos se abre incluso con una hoja de cálculo.
- Para el resto del planeta calle por calle: OpenStreetMap (ODbL) desde la app Organic Maps con
  internet, o los extractos de Geofabrik (`--extra maps-world-detailed` no existe: pesan cientos de GB).
