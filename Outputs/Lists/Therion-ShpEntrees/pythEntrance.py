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
from shapely.geometry import Point, mapping
#from fiona import collection
from fiona.crs import from_epsg
#{'init': 'epsg:3857', 'no_defs': True}

#import pandas as pd
#import matplotlib.pyplot as plt
#import sqlite3
import sys, os, copy
#import datetime
from alive_progress import alive_bar              # https://github.com/rsalmei/alive-progress	

#################################################################################################
#################################################################################################

def ThExtractEntrances(inputfile, systems, caves, crs):
	"""
	Function to ...

	Args:
		inputfile (str): path and name of the sql database to analyse/plot
		

	Raises:
		NameError: error with the input file; see the description when the error is raised.
	"""
	
	print(' ')
	print('******************************************')
	print('Program to extract Therion entrances')
	print('     Written by X. Robert, ISTerre')
	print('           October 2022      ')
	print('******************************************')
	print(' ')
	
	outputdir = 'Entrances-shp'
	# check if input file exists
	if not os.path.isfile(inputfile):
		raise NameError('\033[91mERROR:\033[00m File %s does not exist' %(str(inputfile)))
	
	# open the input file
	f = open(inputfile, 'r').readlines()
	for line in f:
		if 'Gouffre Jean Bernard' in line:
			develJB = line.split('\t')[1]
			denivJB = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredJB = line.split('\t')[3]
			else:
				exploredJB = 0
		elif 'Réseau de la Combe aux Puaires' in line:
			develCP = line.split('\t')[1]
			denivCP = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredCP = line.split('\t')[3]
			else:
				exploredCP = 0
		elif 'LP9 - CP39' in line:
			develLP9 = line.split('\t')[1]
			denivCLP9 = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredLP9 = line.split('\t')[3]
			else:
				exploredLP9 = 0
		elif 'Réseau A21 - A24' in line:
			develA21 = line.split('\t')[1]
			denivA21 = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredA21 = line.split('\t')[3]
			else:
				exploredA21 = 0

	# Create the output folder
	if not os.path.exists(outputdir):
		os.mkdir(outputdir)

	# Créer le schéma des shapefiles
	schema = { 'geometry': 'Point', 'properties': { 'LocationID': 'str',
													'Nom': 'str',
													'System': 'str', 
													'Easting' : 'float', 
													'Northing': 'float',
													'Altitude' : 'float',
													#'Devel': 'str',
													#'Explored': 'str',
													#'Deniv': 'str'
													'Devel': 'float',
													'Explored': 'float',
													'Deniv': 'float'}}
							
	JB_entrances = ['V4', 'V4bis', 'V6', 'V6b', 'V6ter', 'J14', 'V11', 'A14','B19', 'B21', 'B22', 'C37']
	CPres_entrances = ['CP12', 'CP14', 'CP16', 'CP19b']
	LP9_entrances = ['LP9a', 'CP39']
	A21_entrances = ['A21', 'A24']

	with alive_bar(len(systems), title = "\x1b[32;1m- Processing shapefiles...\x1b[0m", length = 35) as bar:
		# For each system
		for system in systems:
			print('\tCavités présentes dans le shapefile : %s' %(caves[system]))
			# Create the output folder
			if not os.path.exists(outputdir + "/" + system):
				os.mkdir(outputdir + "/" + system)
			shpout = outputdir + "/" + system + '/' + system + '-Entrances.shp'

			# Make a new shapefile instance
			with fiona.open(shpout, 'w',crs=from_epsg(crs), driver='ESRI Shapefile', schema=schema) as ouput:
				# Find the line corresponding to each big cave
				for cave in caves[system]:
					for line in f:
						if cave == line.split()[0] and (line.split('\t')[5]) != '':
							if cave in JB_entrances:
								cavename = cave + ' - Jean-Bernard'
								devel = float(develJB)
								deniv = float(denivJB)
								explored = float(exploredJB)
							elif cave in CPres_entrances:
								cavename = cave + ' - Réseau CP'
								devel = float(develCP)
								deniv = float(denivCP)
								explored = float(exploredCP)
							elif cave in LP9_entrances:
								cavename = cave + ' - LP9-CP39'
								devel = float(develLP9)
								deniv = float(develLP9)
								explored = float(exploredLP9)
							elif cave in A21_entrances:
								cavename = cave + ' - A21-A24'
								devel = float(develA21)
								deniv = float(denivA21)
								explored = float(exploredA21)
							else:
								cavename = cave
								devel = float(line.split('\t')[1])
								deniv = float(line.split('\t')[2])
								if line.split('\t')[3] != '':
									explored = float(line.split('\t')[3])
								else:
									explored = 0

							# Extract coordinates, alt, length, depth
							point = Point(float(line.split('\t')[4]), float(line.split('\t')[5]))
							prop = {'LocationID': cavename,
									'Nom': cavename, 
									'System': system,
									'Easting': float(line.split('\t')[4]), 
									'Northing': float(line.split('\t')[5]),
									'Altitude': float(line.split('\t')[6]),
									'Devel': devel,
									'Deniv': deniv,
									'Explored': explored}
							# write Name, alt, length, depth in the shapefile as a new attribute
							ouput.write ({'geometry':mapping(point),'properties': prop})
			# Update the progress-bar
			bar()

	print('')
	print('')



if __name__ == u'__main__':	
	###################################################
	# initiate variables
	inputfile = 'Caves.txt'

	systems = ['SynclinalJB', 'SystemeCP', 'SystemeA21', 'SystemeAV']

	caves = {'SynclinalJB' : ['V4', 'V4bis', 'V6', 'V6b', 'V6ter', 'J14', 'V11', 
							  'A14',
							  'B19', 'B21', 'B22',
							  'D11', 'D33',
							  'C14', 'C24', 'C31', 'C37', 'C74',
							  'CH3', 'CH17', 'CH24'],
			 'SystemeCP' : ['CP12', 'CP14', 'CP16', 'CP19b', 'CP21', 'CP17',
			 				'CP1', 'CP3', 'CP6', 'CP53', 'CP7', 'CP19', 'CP32', 
							'BA06',
							'Ermoy',
							'LP2', 'LP19', 'LP23',
							'T35',
			 				'LP9a', 'CP39',
							'DR09'],
							# Remarques : le CP1 ne possède qu'une entrée dans le fichier topo... A revoir !
			 'SystemeA21' : ['A21', 'A22', 'A24'],
			 'SystemeAV' : ['AV8'],
			 'SystemeMirolda' : ['CD11', 'VF3', 'F126', 'Jockers', 'Falaise'],
			 'SystemeBossetan' : ["Antre d'Oddaz"]}


	crs = 32632	# UTM32N

	###################################################
	# Run the extraction
	ThExtractEntrances(inputfile, systems = systems, caves = caves, crs = crs)
	# End...
