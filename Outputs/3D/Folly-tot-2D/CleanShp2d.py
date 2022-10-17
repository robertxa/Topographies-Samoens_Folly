######!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2020 Xavier Robert <xavier.robert@ird.fr>
# SPDX-License-Identifier: GPL-3.0-or-later


"""
#############################################################
#                                                        	#  
# Script to automatize data extraction of Therion databases #
#                                                        	#  
#                 By Xavier Robert                       	#
#               Grenoble, october 2022                   	#
#                                                        	#  
#############################################################

Written by Xavier Robert, octobert 2022

xavier.robert@ird.fr

"""

# Do divisions with Reals, not with integers
# Must be at the beginning of the file
from __future__ import division

# Import Python modules
#import numpy as np
import fiona
import shapely
from shapely.geometry import Polygon, LineString
import geopandas as gpd
import sys, os, copy
#from functools import wraps
from alive_progress import alive_bar              # https://github.com/rsalmei/alive-progress	

###### TO DO #####

#	- 

##### End TO DO #####

#################################################################################################
#################################################################################################

#def validate(func):
    # """
    # Function to validate areas topology.
    # From https://shapely.readthedocs.io/en/latest/manual.html

    # Args:
    #     func (_type_): _description_

    # Raises:
    #     TopologicalError: Error of topology 
    #                         - area does not close
    #                         - inner ring
    #                         - boundaries intersects


    # Returns:
    #     _type_: _description_
    # """
    # @wraps(func)
    # def wrapper(*args, **kwargs):
    #     ob = func(*args, **kwargs)
    #     if not ob.is_valid:
    #         raise TopologicalError(
    #             "Given arguments do not determine a valid geometric object")
    #     return ob
    # return wrapper


def validate(inputfile, rec):

    rec2 = rec
    #print(rec['geometry']['coordinates'][0])   # il y a visiblement un soucis avec le nombre de []

    if not Polygon(rec['geometry']['coordinates'][0]).is_valid:
        print('Problem in %s geometry' %(inputfile))
        print('%s is not a valid geometric object' %(rec['properties']['_ID']))
        raise TopologicalError('\033[91mERROR:\033[00m Correction does not work...\n%s is not a valid geometric object\n\t The error is: %s' %(str(rec['properties']['_ID']), shapely.validation.explain_validity(rec)))
        #print('We try to correct it')
        #rec2b = shapely.validation.make_valid(Polygon(rec['geometry']['coordinates'][0]))
        # Check à améliorer, il faut que ce soit un Polygon, et non un MultiPolygon...
        #if not rec2b.is_valid:
        #    raise TopologicalError('ERROR: Correction failed...\n%s is not a valid geometric object\n\t The error is: %s' %(str(rec['properties']['_ID']), shapely.validation.explain_validity(rec)))
        #else:
        #    rec2['geometry']['coordinates'][0] = list(rec2b.exterior.coords)

    # Find where there is the error if possible  
    #Diagnostics
    #validation.explain_validity(ob):
    #Returns a string explaining the validity or invalidity of the object.
    #The messages may or may not have a representation of a problem point that can be parsed out.
    #coords = [(0, 0), (0, 2), (1, 1), (2, 2), (2, 0), (1, 1), (0, 0)]
    #p = Polygon(coords)
    #from shapely.validation import explain_validity
    #shapely.validation.explain_validity(p)
    #'Ring Self-intersection[1 1]'
    #shapely.validation.make_valid(ob)
    #Returns a valid representation of the geometry, if it is invalid. If it is valid, the input geometry will be returned.

    #In many cases, in order to create a valid geometry, the input geometry must be split into multiple parts or multiple geometries. If the geometry must be split into multiple parts of the same geometry type, then a multi-part geometry (e.g. a MultiPolygon) will be returned. if the geometry must be split into multiple parts of different types, then a GeometryCollection will be returned.
    #For example, this operation on a geometry with a bow-tie structure:
    #from shapely.validation import make_valid
    #coords = [(0, 0), (0, 2), (1, 1), (2, 2), (2, 0), (1, 1), (0, 0)]
    #p = Polygon(coords)
    #make_valid(p)
    #<MULTIPOLYGON (((1 1, 0 0, 0 2, 1 1)), ((2 0, 1 1, 2 2, 2 0)))>
    #Yields a MultiPolygon with two parts, and sometimes area + line:

    return rec2

#################################################################################################
def cutareas(outlines):

    # 2- Validate the outline and Areas shapefile
    #for rec in outlines:
    #    rec2 = validate('outline2d.shp', rec)
    #    # update correction --> To do ?
    #    #if rec2 != rec:
    #for rec in areas:
    #    rec2 = validate('areas2d.shp', rec)
    #    # update correction
    #    #if rec2 != rec:

    #   Read the Line Shapefile
    areas = gpd.read_file('areas2d.shp', driver = 'ESRI shapefile')

    # Extract the intersections between outlines and lines
    areasIN = areas.overlay(outlines, how = 'intersection')

    # Removes inner lines that have different id and scrap_id
    areasIN = areasIN[areasIN['_SCRAP_ID'] == areasIN ['_ID']]

    # Save output
    areasIN.to_file("areas2dMasekd.gpkg", driver = "GPKG")

    return

#################################################################################################
def cutLines(outlines):
    #   Read the Line Shapefile
    lines = gpd.read_file('lines2d.shp', driver = 'ESRI shapefile')
    # Extract lines that are not masked by the outline
    linesOUT = lines[lines['_TYPE'] == 'centerline']. \
                append(lines[lines['_TYPE'] == 'water_flow']).\
                append(lines[lines['_TYPE'] == 'label']).\
                append(lines[lines['_CLIP'] == 'off'])
    # Extract lines will be masked by the outline
    linesIN = lines[lines['_CLIP'] != 'off']
    linesIN = linesIN[linesIN['_TYPE'] != 'centerline']
    linesIN = linesIN[linesIN['_TYPE'] != 'water_flow']
    linesIN = linesIN[linesIN['_TYPE'] != 'label']

    # Extract the intersections between outlines and lines
    linesIN = linesIN.overlay(outlines, how = 'intersection')

    # Removes inner lines that have different id and scrap_id
    linesIN = linesIN[linesIN['_SCRAP_ID'] == linesIN ['_ID']]

    # Merge the IN and OUT database 
    linesTOT = linesOUT.append(linesIN)

    # Save output
    linesTOT.to_file("lines2dMasekd.gpkg", driver="GPKG")

    return

def AddAltPoint():

    # Make a new shapefile instance
	with fiona.open('points2d.shp', 'r') as inputshp:
		# Créer le nouveau schéma des shapefiles
		newschema = inputshp.schema
		#newschema['properties']['_CAVE'] = 'str'
		#newschema['properties']['_SYSTEM'] = 'str'
		newschema['properties']['_ALT'] = 'str:4'
		#newschema['properties']['_DEPTH'] = 'float'
		newschema['properties']['_EASTING'] = 'float'
		newschema['properties']['_NORTHING'] = 'float'
		# Open the output shapefile
		#with fiona.open(inputfile[:-4] + 'Alt.shp', 'w', crs=inputshp.crs, driver='ESRI Shapefile', schema=newschema) as ouput:
		with fiona.open('points2dAlt.gpkg', 'w', crs=inputshp.crs, driver='GPKG', schema=newschema) as ouput:
			with alive_bar(len(inputshp), title = "\x1b[32;1m- Processing stations...\x1b[0m", length = 20) as bar2:
				# do a loop on the stations
				for rec in inputshp:
					# Copy the schema from the input data
					g = rec
					# Add Alt, Estaing, Northing
					g['properties']['_ALT'] = str(round(float(rec['geometry']['coordinates'][2])))
					g['properties']['_EASTING'] = float(rec['geometry']['coordinates'][0])
					g['properties']['_NORTHING'] = float(rec['geometry']['coordinates'][1])
					# Find system
					#system = rec['properties']['_SURVEY'].split('.')[-2]
					#if system == 'SynclinalJB':
					#	system = 'Système du Jean-Bernard'
					#if system == 'SystemeCP':
					#	system = 'Système de la Combe aux Puaires'
					#if system == 'SystemeAV':
					#	system = 'Système des Avoudrues'
					#if system == 'SystemeA21':
					#	system = 'Système du A21'
					#if system == 'SystemeMirolda':
					#	system = 'Système du Criou - Mirolda'
					#if system == 'SystemeBossetan':
					#	system = 'Système de Bossetan'
					#if system == 'Sources':
					#	system = 'Résurgences'
					#g['properties']['_SYSTEM'] = system					
					
					# Find Cave
					#xxx = rec['properties']['_SURVEY'].split('.')
					#while len(xxx) < 4:
					#	xxx.append('junk')
					#if 'trous' in xxx[0] or system == 'Résurgences':
					#	g['properties']['_CAVE'] = rec['properties']['_NAME']
					#	g['properties']['_DEPTH'] = 0
					
					#elif 'eauxfroides' in xxx[-3]:
					#	g['properties']['_CAVE'] = 'Résurgence des Eaux Froides'
					#	g['properties']['_DEPTH'] = 0

					#elif 'ReseauCP' in xxx[-4]:
					#	g['properties']['_CAVE'] = 'Réseau de la Combe aux Puaires'
					#	g['properties']['_DEPTH'] = 2136 - float(rec['geometry']['coordinates'][2])
					
					#elif 'LP9' in xxx[-4]:
					#	g['properties']['_CAVE'] = 'LP9 - CP39'
					#	g['properties']['_DEPTH'] = 2299 - float(rec['geometry']['coordinates'][2])
					
					#elif 'CP6' in xxx[-4]:
					#	g['properties']['_CAVE'] = 'CP6 - CP53'
					#	g['properties']['_DEPTH'] = 2182 - float(rec['geometry']['coordinates'][2])
					
					#elif xxx[-3] == 'Jean-Bernard':
					#	g['properties']['_CAVE'] = rec['properties']['_SURVEY'].split('.')[-3]
					#	g['properties']['_DEPTH'] = 2333 - float(rec['geometry']['coordinates'][2])
					
					#elif 'A21' in xxx[-4]:
					#	g['properties']['_CAVE'] = 'A21 - A24'
					#	g['properties']['_DEPTH'] = 1797 - float(rec['geometry']['coordinates'][2])
					
					#else:
					#	g['properties']['_CAVE'] = xxx[-4]
					#	if g['properties']['_CAVE'] == 'A22':
					#		g['properties']['_CAVE'] = 'A(V)22'
					#	#g['properties']['_DEPTH'] = 0
					#	# Trouver l'altitude de l'entrée !!!!
					#	for line in f:
					#		if g['properties']['_CAVE'] in line and line.split('\t')[6] != '\n':
					#			altmax = float(line.split('\t')[6])
					#	g['properties']['_DEPTH'] = altmax - float(rec['geometry']['coordinates'][2])					

					# Write record
					ouput.write (g)
					# Update progress bar
					bar2()
	print('')
	print('Update stations done.')
	print('')
    

#################################################################################################
def ThCutAreas():

    print(' ')
    print('****************************************************************')
    print('Program to cut areas and lines that are intersecting the outline')
    print('        Written by X. Robert, ISTerre')
    print('                October 2022      ')
    print('****************************************************************')
    print(' ')

    # Check if areas, lines and outline shapefiles exists...
    for fname in ['outline2d.shp', 'lines2d.shp', 'areas2d.shp']:
        if not os.path.isfile(fname):
            raise NameError('\033[91mERROR:\033[00m File %s does not exist' %(str(fname)))

    #1- Read the outline shapefile
    #with fiona.open('outline2d.shp', 'r') as outlines:
    outlines = gpd.read_file('outline2d.shp', driver = 'ESRI shapefile')
    with alive_bar(3, title = "\x1b[32;1m- Processing lines...\x1b[0m", length = 20) as bar:
        # Work with points
        AddAltPoint()
        bar()
        # Work with areas
        cutareas(outlines)
        bar()
        # Work with lines
        cutLines(outlines)
        bar()

    #5- End ?

    print('')
    print('Update point, areas and lines done.')
    print('')

######################################################################################################
if __name__ == u'__main__':	
	###################################################
	# initiate variables
	inputfile = 'stations3d.shp'
	###################################################
	# Run the transformation
	ThCutAreas()
	# End...

