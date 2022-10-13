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
#from shapely.geometry import Point, mapping
#from fiona import collection
#from fiona.crs import from_epsg
#{'init': 'epsg:3857', 'no_defs': True}

#import pandas as pd
#import matplotlib.pyplot as plt
#import sqlite3
import sys, os, copy
#import datetime
from alive_progress import alive_bar              # https://github.com/rsalmei/alive-progress	

#################################################################################################
#################################################################################################

def ThAddAltStations(inputfile):
	"""
	Function that read the station3d.shp, and produce a new shapefile
	  similar to station3d.shp, but also with the coordinates and altitude of each station

	Args:
		inputfile (str): path and name of the original station3d.shp
		

	Raises:
		NameError: error with the input file; see the description when the error is raised.
	"""
	
	print(' ')
	print('*************************************************')
	print('Program to add Alt, X and Y to shapefile stations')
	print('        Written by X. Robert, ISTerre')
	print('                October 2022      ')
	print('*************************************************')
	print(' ')
	
	outputdir = 'Entrances-shp'
	# check if input file exists
	if not os.path.isfile(inputfile):
		raise NameError('\033[91mERROR:\033[00m File %s does not exist' %(str(inputfile)))
							
	# Make a new shapefile instance
	with fiona.open(inputfile, 'r') as inputshp:
		# Créer le nouveau schéma des shapefiles
		newschema = inputshp.schema
		newschema['properties']['_ALT'] = 'str:4'
		newschema['properties']['_EASTING'] = 'float'
		newschema['properties']['_NORTHING'] = 'float'
		with fiona.open(inputfile[:-4] + 'Alt.shp', 'w', crs=inputshp.crs, driver='ESRI Shapefile', schema=newschema) as ouput:
			with alive_bar(len(inputshp), title = "\x1b[32;1m- Processing stations...\x1b[0m", length = 20) as bar:
				# do a loop on the stations
				for rec in inputshp:
					g = rec
					g['properties']['_ALT'] = str(round(float(rec['geometry']['coordinates'][2])))
					g['properties']['_EASTING'] = float(rec['geometry']['coordinates'][0])
					g['properties']['_NORTHING'] = float(rec['geometry']['coordinates'][1])

					# Write record
					ouput.write (g)
					# Update progress bar
					bar()
	print('')
	print('Update stations done.')
	print('')



if __name__ == u'__main__':	
	###################################################
	# initiate variables
	inputfile = 'stations3d.shp'
	#crs = 32632	# UTM32N

	###################################################
	# Run the transformation

	ThAddAltStations(inputfile)
	# End...
