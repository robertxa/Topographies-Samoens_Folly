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
import sys, os, copy
#from functools import wraps
#from alive_progress import alive_bar              # https://github.com/rsalmei/alive-progress	

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
    with fiona.open('outline2d.shp', 'r') as outlines:        
        
        #   Read the Areas shapefile
        with fiona.open('areas2d.shp', 'r') as areas:
            with fiona.open('areas2dInside.shp', 'w', crs=areas.crs, driver='ESRI Shapefile', schema=areas.schema) as areasInside:
                # 2- Validate the outline and Areas shapefile
                for rec in outlines:
                    rec2 = validate('outline2d.shp', rec)
                    # update correction --> To do ?
                    #if rec2 != rec:
                for rec in areas:
                    rec2 = validate('areas2d.shp', rec)
                    # update correction
                    #if rec2 != rec:

                for outline in outlines:
                    for area in areas:
                        # Initiate new record
                        areaInside = area
                        # check if the area crosses the outline
                        if Polygon(area['geometry']['coordinates'][0]).intersects(Polygon(outline['geometry']['coordinates'][0]))  and area['properties']['_SCRAP_ID'] == outline['properties']['_ID']:
                            # make the difference
                            junk = Polygon(area['geometry']['coordinates'][0]).intersection(Polygon(outline['geometry']['coordinates'][0]))
                            #areaInside = area - outline
                            # Save the difference if the areaInside is not null
                            if not junk.is_empty:
                                areaInside['geometry']['coordinates'][0] = list(junk.exterior.coords)
                                areasInside.write (areaInside)

        #   Read the Line Shapefile
        with fiona.open('lines2d.shp', 'r') as lines:
            with fiona.open('lines2dInside.shp', 'w', crs=lines.crs, driver='ESRI Shapefile', schema=lines.schema) as linesInside:
                with fiona.open('lines2dOutside.shp', 'w', crs=lines.crs, driver='ESRI Shapefile', schema=lines.schema) as linesOutside:
                    counter = 0
                    ids = []
                    for line in lines:
                        #   Make a new shapefile with all the features possibly outside of the outline,
                        #       and that are not to be omitted int the drawing : 
                        #           walls, text, doline, écoulement, clip = off
                        #   Make a new shapefile with only the lines that have 
                        #       to be inside the outline only
                        if line['properties']['_CLIP'] == 'off' or \
                           line['properties']['_TYPE'] in ['wall', 'text', 'label', 'water_flow', 'centerline']:
                            linesOutside.write (line)
                        else:
                            for outline in outlines:
                                # Initiate new record
                                lineInside = line
                                # check if the area crosses the outline
                                #print(line)
                                if LineString(line['geometry']['coordinates']).intersects(Polygon(outline['geometry']['coordinates'][0])) and line['properties']['_SCRAP_ID'] == outline['properties']['_ID']:
                                    # make the difference
                                    junk = LineString(line['geometry']['coordinates']).intersection(Polygon(outline['geometry']['coordinates'][0]))
                                    #areaInside = area - outline
                                    #if line['properties']['_TYPE'] == 'pit':
                                    #    print(line)
                                    #    print(list(junk.coords))

                                    # Save the difference if the lineInside is not null
                                    if not junk.is_empty:
                                        if junk.type == 'LineString':
                                            #lineInside['geometry']['coordinates'] = [junk.coords[0],junk.coords[1]]
                                            lineInside['geometry']['coordinates'] = list(junk.coords)
                                            linesInside.write (lineInside)
                                        elif junk.type == 'GeometryCollection':
                                            #print(junk)
                                            #lineInside['geometry']['coordinates'] = [junk[0].coords[0],junk[0].coords[1]]
                                            lineInside['geometry']['coordinates'] = list(junk[0].coords)
                                        elif junk.type == 'MultiLineString':
                                            print(line)
                                            junkx = []
                                            junky = []
                                            for i in range (len(junk)):
                                                #junkx.append(junk[i].coords[0])
                                                #junky.append(junk[i].coords[1])
                                                #lineInside['geometry']['coordinates'] = [junkx[0], junky[0]]
                                                junkx.append(list(junk[i].coords))
                                                #junky.append(junk[i].coords[1])
                                                
                                                #lineInside['geometry']['coordinates'] = [junk[i].coords[0],junk[i].coords[1]]
                                                #lineInside['id'] = lineInside['id'] + '_' + str(i)
                                                linesInside.write (lineInside)
                                        else:
                                            counter+=1
                                            ids.append(line['id'])
                                            
    if counter !=0:
        print('\x1b[32;1mWARNING:\x1b[0m %s lines have generated an error, these are the lines with "id" number(s):\n\t%s' %(str(counter), str(ids)))


    #5- End ?

    print('')
    print('Update areas and lines done.')
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

