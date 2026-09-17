# Python sripts to enhance Therion Shapefile outputs

Set of python scripts to enhance Therion Shapefile outputs to be used more easylly through QGIS and Merging Maps app.

## Usage

### pythEntrance.py

```
usage: python pythEntrance.py
```

Create a shapefile for the main entrances of a cave system, with coordinates, altitude and speleometry extracted from a text-list build by Therion.
It also creates two to other new shapefiles that synthetize main caves and main systems speleometry

You may edit pythEntrance.py to change the caves' data you may want in the shapefile (modify dictionnaries systems and caves).

Before to run this script, you must build the text-list with Therion.

### pyStationsAltitude.py

```
usage: python pyStationsAltitude.py
```

Create a new shapefile with all the stations 3D, with their geometry as attribut table. It uses the stations3d.shp built by Therion.

Before to run this script, you must build the stations3d.shp with Therion.

### CleanShp2d.py

```
usage: python CleanShp2d.py
```

Create new shapefiles of lines and areas, but with only the info inside the cave outline if the option -clip is set to on or null, except for centerlines and label lines. It uses the files outline2d.shp, lines2d.shp and areas2d.shp built by Therion.

Before to run this script, you must build the files outline2d.shp, lines2d.shp and areas2d.shp with Therion.


## Licence

THis script is under the open-source licence Creative Commons Attribution-ShareAlike-NonCommercial:
	http://creativecommons.org/licenses/by-nc-sa/4.0/

## Author

Xavier Robert (xavier.robert@ird.fr)
