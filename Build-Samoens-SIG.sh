#!/bin/sh

# fichier shell pour construire ou mettre à jour les shapefiles de la base de données topographiques de Samoëns. 
# Ne fonctionne qu'avec un OS utilisant un shell, comme MacOS X et systèmes Linux.

# Copyright (C) 2022 Xavier Robert <xavier.robert***@***ird.fr>
# This work is under the Creative Commons Attribution-ShareAlike-NonCommecial License:
#	<http://creativecommons.org/licenses/by-nc-sa/4.0/> 

echo '###########################################################################################'
echo 'Script pour générer ou mettre à jour les shapefiles pour le progjet GIS du karst de Samoëns'
echo '                         Ecrit par Xavier Robert, Octobre 2022                             '
echo '                                 Licence CC-by-nc-sa                                       '
echo '###########################################################################################'
echo ''
echo ''

# 1- Générer les shapefiles 3D des différentes topographies de tout le système
echo '    1- Construction des shapefiles 3D et des listes de cavités...'
echo '          Attention, cette étape est longue !!!'
therion SamoensGIS.thconfig
echo ''
# 2- Construire ou mettre à jour les shapefiles des entrées de cavités majeures
echo '    2- Travail sur les shapefiles des entrées de cavités majeures....'
cd Outputs/Lists/Therion-ShpEntrees
python pythEntrance.py
cd -
echo ''
# 3- Mise à jour des shapefiles stations3D pour rajouter les informations d'altitudes
echo '    3- Mise à jour des shapefiles stations3D (rajout des altitudes à la table attributaire)'
cd Outputs/3D/Folly-tot-3D
python pyStationsAltitude.py
cd -
echo ''
# 4- Mise à jour des shapefiles stations3D pour rajouter les informations d'altitudes
echo '    3- Découpe les shapefiles aires et lignes au regard de l Outline'
echo '         A faire manuellement ! tant que toutes les aires ne sont pas corrigées'
#cd Outputs/3D/Folly-tot-2D
#python CleanShp2d.py
#cd -
#echo ''

# 5- Mise à jour du projet QGis et du repository Merging Maps
echo '    5- Mise à jour du projet QGis et du repository Merging Maps...'
echo '         A faire manuellement !'
echo '         transformer les shp en g???'
echo ''

