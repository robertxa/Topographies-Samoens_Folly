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
import pandas as pd
import sys, os, copy, shutil
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
def cutareas(pathshp, outlines, outputspath):

    print('Working with areas...')
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
    areas = gpd.read_file(pathshp + 'areas2d.shp', driver = 'ESRI shapefile')

    # Extract the intersections between outlines and lines
    # be careful, for this operation, geopandas needs to work with rtree and not pygeos
    #   --> uninstall pygeos and install rtree
    try:
        areasIN = areas.overlay(outlines, how = 'intersection')
    except:
        print('ERROR: 1) uninstall pygeos and install rtree\n\t2) check your polygons validity')
        
    # Removes inner lines that have different id and scrap_id
    areasIN = areasIN[areasIN['_SCRAP_ID'] == areasIN ['_ID']]

    # Save output
    #areasIN.to_file("areas2dMasekd.gpkg", driver = "GPKG", encoding = 'utf8')
    #areasIN.to_file(pathshp[:-8] + "areas2dMasekd.gpkg", driver = "GPKG")
    areasIN.to_file(outputspath + "areas2dMasekd.gpkg", driver = "GPKG")

    return

#################################################################################################
def cutLines(pathshp, outlines, outputspath):

    print('Working with lines...')
    #   Read the Line Shapefile
    lines = gpd.read_file(pathshp + 'lines2d.shp', driver = 'ESRI shapefile')
    # Extract lines that are not masked by the outline
    linesOUT = pd.concat((lines[lines['_TYPE'] == 'centerline'],
                           lines[lines['_TYPE'] == 'water_flow'],
                           lines[lines['_TYPE'] == 'label'],
                           lines[lines['_CLIP'] == 'off']),
                           ignore_index=True)

    # Extract lines will be masked by the outline
    linesIN = lines[lines['_CLIP'] != 'off']
    linesIN = linesIN[linesIN['_TYPE'] != 'centerline']
    linesIN = linesIN[linesIN['_TYPE'] != 'water_flow']
    linesIN = linesIN[linesIN['_TYPE'] != 'label']

    # Extract the intersections between outlines and lines
    # be careful, for this operation, geopandas needs to work with rtree and not pygeos
    #   --> uninstall pygeos and install rtree
    try:
        linesIN = linesIN.overlay(outlines, how = 'intersection', keep_geom_type=True)
    except:
        print('\033[91mERROR: 1\033[00m) uninstall pygeos and install rtree\n\t2) check your polygons validity')
        linesIN = linesIN.overlay(outlines, how = 'intersection', keep_geom_type=True)

    # Removes inner lines that have different id and scrap_id
    linesIN = linesIN[linesIN['_SCRAP_ID'] == linesIN ['_ID']]

    # Merge the IN and OUT database 
    linesTOT = pd.concat((linesOUT, linesIN),
                           ignore_index=True)

    # Save output
    #linesTOT.to_file("lines2dMasekd.gpkg", driver="GPKG", encoding = 'utf8')
    #linesTOT.to_file(pathshp[:-8] + "lines2dMasekd.gpkg", driver="GPKG")
    linesTOT.to_file(outputspath + "lines2dMasekd.gpkg", driver="GPKG")

    return

#################################################################################################
def AddAltPoint(pathshp, outputspath):

    print('Working with points...')

    # Definition des altitudes des entrées supérieures des réseaux à plusieurs entrées
    EntreeSupp = {'JB'     : 2333,  # Entrée C37
                  'CP'     : 2136,  # Entrée CP16
                  'LP9'    : 2299,  # Entrée LP9
                  'CP6'    : 2182,  # Entrée CP53
                  'CP62'   : 1960,  # Entrée CP62
                  'A21'    : 1797,  # Entrée A21
                  'Mirolda': 2330   # Entrée Jockers
                  }
    # Définition des noms de réseau
    RNames = {'JB'     : 'Gouffre Jean Bernard',
              'CP'     : 'Réseau de la Combe aux Puaires',
              'LP9'    : 'LP9 - CP39',
              'CP6'    : 'CP6 - CP53',
              'CP62'   : 'CP62 - CP63',
              'A21'    : 'A21 -A24',
              'Mirolda': 'Réseau Lucien-Bouclier - Mirolda'  
              }
    # Open the text file with the coordinates of the caves
    #f = open('../../Lists/Therion-ShpEntrees/Caves.txt', 'r').readlines() 
    f = open(pathshp + 'Caves.txt', 'r').readlines() 

    # Make a new shapefile instance
    with fiona.open(pathshp + 'points2d.shp', 'r') as inputshp:
        # Créer le nouveau schéma des shapefiles
        newschema = inputshp.schema
        newschema['properties']['_CAVE'] = 'str'
        newschema['properties']['_SYSTEM'] = 'str'
        newschema['properties']['_ALT'] = 'str:4'
        newschema['properties']['_DEPTH'] = 'float'
        newschema['properties']['_EASTING'] = 'float'
        newschema['properties']['_NORTHING'] = 'float'
        # Open the output shapefile
        #with fiona.open(inputfile[:-4] + 'Alt.shp', 'w', crs=inputshp.crs, driver='ESRI Shapefile', schema=newschema) as ouput:
        #with fiona.open('points2dAlt.gpkg', 'w', crs=inputshp.crs, driver='GPKG', schema=newschema, encoding = 'utf8') as ouput:
        #with fiona.open(pathshp[:-8] + 'points2dAlt.gpkg', 'w', crs=inputshp.crs, driver='GPKG', schema=newschema) as ouput:
        with fiona.open(outputspath + 'points2dAlt.gpkg', 'w', crs=inputshp.crs, driver='GPKG', schema=newschema) as ouput:
            with alive_bar(len(inputshp), title = "\x1b[32;1m- Processing stations...\x1b[0m", length = 20) as bar:
                # do a loop on the stations
                for rec in inputshp:
                    # Copy the schema from the input data
                    g = rec
                    g['properties']['_CAVE'] = ''
                    g['properties']['_SYSTEM'] = ''
                    g['properties']['_DEPTH'] = ''

                    # Add Alt, Estaing, Northing
                    g['properties']['_ALT'] = str(round(float(rec['geometry']['coordinates'][2])))
                    g['properties']['_EASTING'] = float(rec['geometry']['coordinates'][0])
                    g['properties']['_NORTHING'] = float(rec['geometry']['coordinates'][1])

                    if rec['properties']['_TYPE'] == 'station' and rec['properties']['_STSURVEY'] != None:
                        # Find system
                        system = rec['properties']['_STSURVEY'].split('.')[-2]
                        if system == 'SynclinalJB':
                    	    system = 'Système du Jean-Bernard'
                        if system == 'SystemeCP':
                    	    system = 'Système de la Combe aux Puaires'
                        if system == 'SystemeAV':
                    	    system = 'Système des Avoudrues'
                        if system == 'SystemeA21':
                    	    system = 'Système du A21'
                        if system == 'SystemeMirolda':
                    	    system = 'Système du Criou - Mirolda'
                        if system == 'SystemeBossetan':
                    	    system = 'Système de Bossetan'
                        if system == 'Sources':
                    	    system = 'Résurgences'
                        if system == 'Tuet':
                    	    system = 'Système du Tuet'
                        g['properties']['_SYSTEM'] = system					
                    
                        # Find Cave
                        xxx = rec['properties']['_STSURVEY'].split('.')
                        while len(xxx) < 4:
                    	    xxx.append('junk')
                        if 'trous' in xxx[0] or system == 'Résurgences' or 'sources' in xxx[0]:
                    	    g['properties']['_CAVE'] = rec['properties']['_STNAME']
                    	    g['properties']['_DEPTH'] = 0
                    
                        elif 'eauxfroides' in xxx[-3]:
                    	    g['properties']['_CAVE'] = 'Résurgence des Eaux Froides'
                    	    g['properties']['_DEPTH'] = 0

                        elif 'tuet' in xxx[-4]:
                    	    g['properties']['_CAVE'] = 'Tuet'
                    	    g['properties']['_DEPTH'] = 0

                        elif 'ReseauCP' in xxx[-4]:
                    	    g['properties']['_CAVE'] = RNames['CP']
                    	    g['properties']['_DEPTH'] = EntreeSupp['CP'] - float(rec['geometry']['coordinates'][2])
                    
                        elif 'LP9' in xxx[-4]:
                    	    g['properties']['_CAVE'] = RNames['LP9']
                    	    g['properties']['_DEPTH'] = EntreeSupp['LP9'] - float(rec['geometry']['coordinates'][2])
                    
                        elif 'CP6' in xxx[-4]:
                    	    g['properties']['_CAVE'] = RNames['CP6']
                    	    g['properties']['_DEPTH'] = EntreeSupp['CP6'] - float(rec['geometry']['coordinates'][2])
                    
                        elif 'CP62' in xxx[-4]:
                    	    g['properties']['_CAVE'] = RNames['CP62']
                    	    g['properties']['_DEPTH'] = EntreeSupp['CP62'] - float(rec['geometry']['coordinates'][2])
                    
                        elif xxx[-3] == 'Jean-Bernard':
                            #g['properties']['_CAVE'] = rec['properties']['_STSURVEY'].split('.')[-3]
                            g['properties']['_CAVE'] = RNames['JB']
                            g['properties']['_DEPTH'] = EntreeSupp['JB'] - float(rec['geometry']['coordinates'][2])
                    
                        elif 'A21' in xxx[-4]:
                    	    g['properties']['_CAVE'] = RNames['A21']
                    	    g['properties']['_DEPTH'] = EntreeSupp['A21'] - float(rec['geometry']['coordinates'][2])

                        elif 'Mirolda' in xxx[-3]:
                    	    g['properties']['_CAVE'] = RNames['Mirolda']
                    	    g['properties']['_DEPTH'] = EntreeSupp['Mirolda'] - float(rec['geometry']['coordinates'][2])

                        else:
                            g['properties']['_CAVE'] = xxx[-4]
                            if g['properties']['_CAVE'] == 'A22':
                                g['properties']['_CAVE'] = 'A(V)22'
                            #g['properties']['_DEPTH'] = 0
                            # Trouver l'altitude de l'entrée !!!!
                            for line in f:
                                if g['properties']['_CAVE'] in line and line.split('\t')[6] != '\n':
                                    altmax = float(line.split('\t')[6])
                            g['properties']['_DEPTH'] = altmax - float(rec['geometry']['coordinates'][2])					
                    
                    # Write record
                    ouput.write (g)
                    # Update progress bar
                    bar()
    return


#################################################################################################
def shp2gpkg(pathshp, outputspath):

    files = ['outline2d', 'shots3d', 'walls3d']

    print('shp2gpkg : ', files)
    with alive_bar(len(files), title = "\x1b[32;1m- Processing shp2pkg...\x1b[0m", length = 20) as bar:
        for fname in files :
            if fname == 'walls3d':
                print('shp2gpkg does not support walls3d files...\n\t I am only copying the shp file into the right folder')
                #shutil.copy2(pathshp + fname + '.shp', pathshp[:-8] + fname + '.shp')
                shutil.copy2(pathshp + fname + '.shp', outputspath + fname + '.shp')
                #pass
                #input = gpd.read_file(fname + '.shp', layer = 'walls3d', driver = 'ESRI shapefile')
                #input.to_file(fname + ".gpkg", driver="GPKG", encoding = 'utf8')
                #with fiona.open(fname + '.shp', 'r') as inputshp:
                #    with fiona.open(fname + '.gpkg', 'w', crs=inputshp.crs, driver='GPKG', schema=inputshp.schema, encoding = 'utf8') as ouput:
                #        for rec in inputshp:
                #            # Write record
                #            ouput.write (g)
            else:
                input = gpd.read_file(pathshp + fname + '.shp', driver = 'ESRI shapefile')
                #input.to_file(fname + ".gpkg", driver="GPKG", encoding = 'utf8')
                #input.to_file(pathshp[:-8] + fname + ".gpkg", driver="GPKG")
                input.to_file(outputspath + fname + ".gpkg", driver="GPKG")
            #input.to_file(fname + ".gpkg", driver="GPKG")
            #update bar
            bar()

    return

#################################################################################################
def ThCutAreas(pathshp, outputspath):

    print(' ')
    print('****************************************************************')
    print('Program to cut areas and lines that are intersecting the outline')
    print('        Written by X. Robert, ISTerre')
    print('                October 2022      ')
    print('****************************************************************')
    print(' ')

    # Check if areas, lines and outline shapefiles exists...
    for fname in ['outline2d', 'lines2d', 'areas2d', 
                  'shots3d','walls3d']:
        if not os.path.isfile(pathshp + fname + '.shp'):
            raise NameError('\033[91mERROR:\033[00m File %s does not exist' %(str(pathshp + fname + '.shp')))
    # Check if Outputs path exists
    if not os.path.exists(outputspath):
        print ('\033[91mWARNING:\033[00m ' + outputspath + ' does not exist, I am creating it...')
        os.mkdir(outputspath)

    #1- Read the outline shapefile
    #with fiona.open('outline2d.shp', 'r') as outlines:
    print ('Reading ' + pathshp + 'outline2d.shp ...') 
    outlines = gpd.read_file(pathshp + 'outline2d.shp', driver = 'ESRI shapefile')

    #with alive_bar(3, title = "\x1b[32;1m- Processing lines...\x1b[0m", length = 20) as bar:
    # Change SHP to gpkg
    print ('Changing .shp to .gpkg...')
    shp2gpkg(pathshp, outputspath)

    # Work with points
    print ('Add alt to points station...')
    AddAltPoint(pathshp, outputspath)
    #bar()

    # Work with lines
    print ('Cuting lines...')
    cutLines(pathshp, outlines, outputspath)
    #bar()

    # Work with areas
    print ('Cuting areas...')
    cutareas(pathshp, outlines, outputspath)
    #bar()
    

    #5- End ?

    print('')
    print('Update point, areas and lines done.')
    print('')

######################################################################################################
if __name__ == u'__main__':	
	###################################################
    # initiate variables
    inputfile = 'stations3d.shp'
    #pathshp = '../../Outputs/SHP/therion/'
    pathshp = 'Criou/'
    outputspath = 'GPKG/'
    ###################################################
    # Run the transformation
    ThCutAreas(pathshp, outputspath)
    # End...

