######!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2023 Xavier Robert <xavier.robert@ird.fr>
# SPDX-License-Identifier: GPL-3.0-or-later


"""
###############################################################################
#                                                        	                  #  
# Script to automatize data push of Therion databases in Merging Maps project #
#                                                        	                  #  
#                 By Xavier Robert                       	                  #
#               Grenoble, october 2022                   	                  #
#                                                        	                  #  
###############################################################################

Written by Xavier Robert, june 2023

xavier.robert@ird.fr

"""

# Do divisions with Reals, not with integers
# Must be at the beginning of the file
from __future__ import division

# Import Python modules
#import numpy as np
#import fiona
#from shapely.geometry import Point, mapping
#from fiona.crs import from_epsg
import merging # merging Maps : https://merginmaps.com/docs/dev/integration/
#import Mergin.mergin as mergin 	# With QGIS plugin ?
import sys, os, copy
from alive_progress import alive_bar              # https://github.com/rsalmei/alive-progress	


#################################################################################################
#################################################################################################

def ThExtractEntrances(inputfile, pathshp, outpath, systems, caves, crs):
	"""
	Function to build a point shapefile with the entrances of the main caves,
	with the Easting/Northing/Altitude as attributs' table.

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
	

	return


#################################################################################################
if __name__ == u'__main__':	
	###################################################
	# initiate variables
	inputfile = 'Caves.txt'

	pathshp = '../../Outputs/SHP/therion/'

	outpath = '../../Outputs/SHP/GPKG/'

	systems = ['SynclinalJB', 'SystemeCP', 'SystemeA21', 'SystemeAV', 'SystemMirolda']

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
			 'SystemeA21' : ['A21', 'A22', 'A24'],
			 'SystemeAV' : ['AV8'],
			 'SystemMirolda' : ['CD11', 'VF3', 'F126', 'Jockers', 'Falaise', 'Fenêtre',
			 					"L'Amine Dada -FLT7"],
			#Mirolda_entrances = ['CD11', 'VF3 - Mirolda - Réseau Lucien Bouclier', 
			#			 'Gouffre de la Rondelle Jaune - F126', 'G. des Jockers',
			#			 'Entrée de la Falaise', 'Fenêtre']
			 'SystemeBossetan' : ["Antre d'Oddaz"]}


	crs = 32632	# UTM32N


	client = mergin.MerginClient(login='john', password='topsecret')
	


	###################################################
	# Run the extraction
	ThExtractEntrances(inputfile, pathshp, outpath, systems = systems, caves = caves, crs = crs)
	# End...
