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
import sys, os, copy
from alive_progress import alive_bar              # https://github.com/rsalmei/alive-progress	

###### TO DO #####

#	- 

##### End TO DO #####

#################################################################################################
#################################################################################################

def ThAddAltStations(pathshp, inputfile, outpath):
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
	
	# check if input file exists
	if not os.path.isfile(pathshp + inputfile):
		raise NameError('\033[91mERROR:\033[00m File %s does not exist' %(str(pathshp + inputfile)))
	if not os.path.exists(outpath):
		print ('\033[91mWARNING:\033[00m ' + outpath + ' does not exist, I am creating it...')
		os.mkdir(outpath)

	# Open the text file with the coordinates of the caves
	#f = open('../../Lists/Therion-ShpEntrees/Caves.txt', 'r').readlines()
	f = open(pathshp + 'Caves.txt', 'r').readlines() 
							
	# Make a new shapefile instance
	with fiona.open(pathshp + inputfile, 'r') as inputshp:
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
		with fiona.open(outpath + inputfile[:-4] + 'Alt.gpkg', 'w', crs=inputshp.crs, driver='GPKG', schema=newschema) as ouput:
			with alive_bar(len(inputshp), title = "\x1b[32;1m- Processing stations...\x1b[0m", length = 20) as bar:
				# do a loop on the stations
				for rec in inputshp:
					# Copy the schema from the input data
					g = rec
					# Add Alt, Estaing, Northing
					g['properties']['_ALT'] = str(round(float(rec['geometry']['coordinates'][2])))
					g['properties']['_EASTING'] = float(rec['geometry']['coordinates'][0])
					g['properties']['_NORTHING'] = float(rec['geometry']['coordinates'][1])
					# Find system
					system = rec['properties']['_SURVEY'].split('.')[-2]
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
					g['properties']['_SYSTEM'] = system					
					
					# Find Cave
					xxx = rec['properties']['_SURVEY'].split('.')
					while len(xxx) < 4:
						xxx.append('junk')
					if 'trous' in xxx[0] or system == 'Résurgences':
						g['properties']['_CAVE'] = rec['properties']['_NAME']
						g['properties']['_DEPTH'] = 0
					
					elif 'eauxfroides' in xxx[-3]:
						g['properties']['_CAVE'] = 'Résurgence des Eaux Froides'
						g['properties']['_DEPTH'] = 0

					elif 'ReseauCP' in xxx[-4]:
						g['properties']['_CAVE'] = 'Réseau de la Combe aux Puaires'
						g['properties']['_DEPTH'] = 2136 - float(rec['geometry']['coordinates'][2])
					
					elif 'LP9' in xxx[-4]:
						g['properties']['_CAVE'] = 'LP9 - CP39'
						g['properties']['_DEPTH'] = 2299 - float(rec['geometry']['coordinates'][2])
					
					elif 'CP6' in xxx[-4]:
						g['properties']['_CAVE'] = 'CP6 - CP53'
						g['properties']['_DEPTH'] = 2182 - float(rec['geometry']['coordinates'][2])
					
					elif xxx[-3] == 'Jean-Bernard':
						g['properties']['_CAVE'] = rec['properties']['_SURVEY'].split('.')[-3]
						g['properties']['_DEPTH'] = 2333 - float(rec['geometry']['coordinates'][2])
					
					elif xxx[-3] == 'Mirolda':
						g['properties']['_CAVE'] = rec['properties']['_SURVEY'].split('.')[-3]
						g['properties']['_DEPTH'] = 2330 - float(rec['geometry']['coordinates'][2])
					
					elif 'A21' in xxx[-4]:
						g['properties']['_CAVE'] = 'A21 - A24'
						g['properties']['_DEPTH'] = 1797 - float(rec['geometry']['coordinates'][2])
					
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
	print('')
	print('Update stations done.')
	print('')

######################################################################################################
if __name__ == u'__main__':	
	###################################################
	# initiate variables
	inputfile = 'stations3d.shp'
	pathshp = '../../Outputs/SHP/therion/'
	outpath = '../../Outputs/SHP/GPKG/'
	###################################################
	# Run the transformation
	ThAddAltStations(pathshp, inputfile, outpath)
	# End...
