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
from fiona.crs import from_epsg
import sys, os, copy
from alive_progress import alive_bar              # https://github.com/rsalmei/alive-progress	


#################################################################################################
#################################################################################################

def ThExtractEntrances(inputfile, pathshp, outpath, systems, caves, crs):
	"""
	Function to build a point shapefile with the entrances of the main caves,
	with the Easting/Northing/Altitude as attributs' table.

	Args:
		inputfile (str)       : path and name of the sql database to analyse/plot
		pathshp (str)         : path where the shp produced by Therion are stored
		outpath (str)         : path where to copy the gpkg files
		systems (list of str) : Cave systems to consider
		caves (dictionnary)   : Names of main caves for each cave system
		crs (integer)         : ESPG code of the coordinates' system
		
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
	if not os.path.isfile(pathshp + inputfile):
		raise NameError('\033[91mERROR:\033[00m File %s does not exist' %(str(pathshp + inputfile)))
	if not os.path.exists(outpath):
		print ('\033[91mWARNING:\033[00m ' + outpath + ' does not exist, I am creating it...')
		os.mkdir(outpath)
	
	# open the input file
	f = open(pathshp + inputfile, 'r').readlines()
	for line in f:
		if 'Gouffre Jean Bernard' in line:	
			develJB = line.split('\t')[1]
			denivJB = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredJB = line.split('\t')[3]
			else:
				exploredJB = 0
		elif line.split()[0] == 'C14':
			develC14 = line.split('\t')[1]
			denivC14 = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredC14 = line.split('\t')[3]
			else:
				exploredC14 = 0
		elif line.split()[0] == 'C74':
			develC74 = line.split('\t')[1]
			denivC74 = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredC74 = line.split('\t')[3]
			else:
				exploredC74 = 0
		#elif 'CH3' in line:
		elif line.split()[0] == 'CH3':
			develCH3 = line.split('\t')[1]
			denivCH3 = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredCH3 = line.split('\t')[3]
			else:
				exploredCH3 = 0
		elif line.split()[0] == 'CH17':
			develCH17 = line.split('\t')[1]
			denivCH17 = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredCH17 = line.split('\t')[3]
			else:
				exploredCH17 = 0
		elif line.split()[0] == 'D11':
			develD11 = line.split('\t')[1]
			denivD11 = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredD11 = line.split('\t')[3]
			else:
				exploredD11 = 0
		elif line.split()[0] == 'D33':
			develD33 = line.split('\t')[1]
			denivD33 = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredD33 = line.split('\t')[3]
			else:
				exploredD33 = 0
		#elif 'Réseau de la Combe aux Puaires' in line:
		elif 'Réseau de la Combe au Puaires<br>CP07 - CP12 - CP14 - CP16 - CP19b' in line:
			develCP = line.split('\t')[1]
			denivCP = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredCP = line.split('\t')[3]
			else:
				exploredCP = 0
		elif line.split()[0] == 'BA6':
			develBA6 = line.split('\t')[1]
			denivBA6 = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredBA6 = line.split('\t')[3]
			else:
				exploredBA6 = 0
		elif line.split()[0] == 'CP3':
			develCP3 = line.split('\t')[1]
			denivCP3 = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredCP3 = line.split('\t')[3]
			else:
				exploredCP3 = 0
		elif line.split()[0] == 'CP6' and line.split()[2] == 'CP53':
			develCP6 = line.split('\t')[1]
			denivCP6 = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredCP6 = line.split('\t')[3]
			else:
				exploredCP6 = 0
		elif line.split()[0] == 'CP17':
			develCP17 = line.split('\t')[1]
			denivCP17 = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredCP17 = line.split('\t')[3]
			else:
				exploredCP17 = 0
		elif line.split()[0] == 'CP32':
			develCP32 = line.split('\t')[1]
			denivCP32 = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredCP32 = line.split('\t')[3]
			else:
				exploredCP32 = 0
		#elif 'LP9 - CP39' in line and 'LP9 - CP39' in line:
		elif 'LP9' in line and 'CP39' in line:
			develLP9 = line.split('\t')[1]
			denivLP9 = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredLP9 = line.split('\t')[3]
			else:
				exploredLP9 = 0
		elif "Grotte de l'Ermoy" in line:
			develErmoy = line.split('\t')[1]
			denivErmoy = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredErmoy = line.split('\t')[3]
			else:
				exploredErmoy = 0
		elif 'Réseau A21 - A24' in line:
			develA21 = line.split('\t')[1]
			denivA21 = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredA21 = line.split('\t')[3]
			else:
				exploredA21 = 0
		elif 'Gouffre Mirolda - Réseau Lucien Bouclier' in line:
			develMirolda = line.split('\t')[1]
			denivMirolda = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredMirolda = line.split('\t')[3]
			else:
				exploredMirolda = 0
		elif 'AntreOddaz' in line:
			develOddaz = line.split('\t')[1]
			denivOddaz = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredOddaz = line.split('\t')[3]
			else:
				exploredOddaz = 0
		# Now, get the data for each entire system
		elif 'Réseau du Jean-Bernard' in line:
			develsJB = line.split('\t')[1]
			denivsJB = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredsJB = line.split('\t')[3]
			else:
				exploredsJB = 0
		elif 'Système de la Combe aux Puaires' in line:
			develsCP = line.split('\t')[1]
			denivsCP = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredsCP = line.split('\t')[3]
			else:
				exploredsCP = 0
		elif 'Système des Avoudrues' in line:
			develsAV = line.split('\t')[1]
			denivsAV = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredsAV = line.split('\t')[3]
			else:
				exploredsAV = 0
		elif 'Système du A21' in line:
			develsA = line.split('\t')[1]
			denivsA = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredsA = line.split('\t')[3]
			else:
				exploredsA = 0
		elif 'Système du Mirolda - Lucien Bouclier' in line:
			develsCriou = line.split('\t')[1]
			denivsCriou = line.split('\t')[2]
			if line.split('\t')[3] != '':
				exploredsCriou = line.split('\t')[3]
			else:
				exploredsCriou = 0

	cavesinfo = {'JB' : {'Nom'     : 'Gouffre Jean Bernard',
						'System'  : 'Système du Jean Bernard', 
						'Devel'   : develJB,
						'Explored': exploredJB,
						'Deniv'   : denivJB,
						'Point'   : [328917,5107359]},	#crs = 32632	# UTM32N
				'C14' : {'Nom'    : 'Gouffre C14',
						'System'  : 'Système du Jean Bernard', 
						'Devel'   : develC14,
						'Explored': exploredC14,
						'Deniv'   : denivC14,
						'Point'   : [329771, 5108401]},	#crs = 32632	# UTM32N
				'C74' : {'Nom'    : 'Gouffre C74',
						'System'  : 'Système du Jean Bernard', 
						'Devel'   : develC74,
						'Explored': exploredC74,
						'Deniv'   : denivC74,
						'Point'   : [330128, 5108363]},	#crs = 32632	# UTM32N
				'CH17' : {'Nom'     : 'Gouffre CH17',
						'System'  : 'Système du Jean Bernard', 
						'Devel'   : develCH17,
						'Explored': exploredCH17,
						'Deniv'   : denivCH17,
						'Point'   : [330832, 5108363]},	#crs = 32632	# UTM32N
				'CH3' : {'Nom'    : 'Gouffre CH3',
						'System'  : 'Système du Jean Bernard', 
						'Devel'   : develCH3,
						'Explored': exploredCH3,
						'Deniv'   : denivCH3,
						'Point'   : [330544, 5107569]},	#crs = 32632	# UTM32N
				'D11' : {'Nom'    : 'Gouffre D11',
						'System'  : 'Système du Jean Bernard', 
						'Devel'   : develD11,
						'Explored': exploredD11,
						'Deniv'   : denivD11,
						'Point'   : [329584, 5108185]},	#crs = 32632	# UTM32N
				'D33' : {'Nom'    : 'Gouffre D33',
						'System'  : 'Système du Jean Bernard', 
						'Devel'   : develD33,
						'Explored': exploredD33,
						'Deniv'   : denivD33,
						'Point'   : [329386, 5108204]},	#crs = 32632	# UTM32N
				'CP' : {'Nom'     : 'Réseau de la Combe aux Puaires',
						'System'  : 'Système de la Combe aux Puaires', 
						'Devel'   : develCP,
						'Explored': exploredCP,
						'Deniv'   : denivCP,
						'Point'   : [330447, 5108711]},	#crs = 32632	# UTM32N
				'BA6' : {'Nom'    : 'Gouffre BA6',
						'System'  : 'Système de la Combe aux Puaires', 
						'Devel'   : develBA6,
						'Explored': exploredBA6,
						'Deniv'   : denivBA6,
						'Point'   : [327762, 5107885]},	#crs = 32632	# UTM32N
				'CP3': {'Nom'     : 'Gouffre CP3',
						'System'  : 'Système de la Combe aux Puaires', 
						'Devel'   : develCP3,
						'Explored': exploredCP3,
						'Deniv'   : denivCP3,
						'Point'   : [330438, 5109565]},	#crs = 32632	# UTM32N
				'CP6': {'Nom'     : 'Gouffre CP6 - CP53',
						'System'  : 'Système de la Combe aux Puaires', 
						'Devel'   : develCP,
						'Explored': exploredCP,
						'Deniv'   : denivCP,
						'Point'   : [329912, 5109725]},	#crs = 32632	# UTM32N
				'CP17': {'Nom'     : 'Gouffre CP17',
						'System'  : 'Système de la Combe aux Puaires', 
						'Devel'   : develCP17,
						'Explored': exploredCP17,
						'Deniv'   : denivCP17,
						'Point'   : [329696, 5109405]},	#crs = 32632	# UTM32N
				'CP32': {'Nom'     : 'Gouffre CP32',
						'System'  : 'Système de la Combe aux Puaires', 
						'Devel'   : develCP32,
						'Explored': exploredCP32,
						'Deniv'   : denivCP32,
						'Point'   : [329368, 5108758]},	#crs = 32632	# UTM32N
				'LP9': {'Nom'     : 'Gouffre LP9 - CP39',
						'System'  : 'Système de la Combe aux Puaires', 
						'Devel'   : develLP9,
						'Explored': exploredLP9,
						'Deniv'   : denivLP9,
						'Point'   : [330081, 5109086]},	#crs = 32632	# UTM32N
				'Ermoy': {'Nom'   : "Grotte de l'Ermoy",
						'System'  : 'Système de la Combe aux Puaires', 
						'Devel'   : develErmoy,
						'Explored': exploredErmoy,
						'Deniv'   : denivErmoy,
						'Point'   : [326692, 5107669]},	#crs = 32632	# UTM32N
				'A21': {'Nom'     : 'Gouffre A21 - A24',
						'System'  : 'Système du A21', 
						'Devel'   : develA21,
						'Explored': exploredA21,
						'Deniv'   : denivA21,
						'Point'   : [328542, 5108119]},	#crs = 32632	# UTM32N
				'Mirolda': {'Nom' : 'Gouffre Mirolda - Réseau Lucien Bouclier',
						'System'  : 'Système du Criou', 
						'Devel'   : develMirolda,
						'Explored': exploredMirolda,
						'Deniv'   : denivMirolda,
						'Point'   : [328410, 5106383]},	#crs = 32632	# UTM32N
				'AOddaz': {'Nom'     : "Antre d'Oddaz",
						   'System'  : 'Système du Tuet', 
						   'Devel'   : develOddaz,
						   'Explored': exploredOddaz,
						   'Deniv'   : denivOddaz,
						   'Point'   : [327265, 5109190]}	#crs = 32632	# UTM32N
				}

	systsinfo = {'JB' : {'Nom'     : 'Système du Jean Bernard',
						'System'  : 'Système du Jean Bernard', 
						'Devel'   : develsJB,
						'Explored': exploredsJB,
						'Deniv'   : denivsJB,
						#'Point'   : [328750, 5107082]},	#crs = 32632	# UTM32N
						'Point'   : [328750, 5107265]},	#crs = 32632	# UTM32N
				'CP' : {'Nom'     : 'Système de la Combe aux Puaires',
						'System'  : 'Système de la Combe aux Puaires', 
						'Devel'   : develsCP,
						'Explored': exploredsCP,
						'Deniv'   : denivsCP,
						'Point'   : [327827, 5108791]},	#crs = 32632	# UTM32N}
				'AV' : {'Nom'     : 'Système des Avoudrues',
						'System'  : 'Système des Avoudrues', 
						'Devel'   : develsAV,
						'Explored': exploredsAV,
						'Deniv'   : denivsAV,
						'Point'   : [331299, 5107449]},	#crs = 32632	# UTM32N}
				'A'  : {'Nom'     : 'Système du A21',
						'System'  : 'Système du A21', 
						'Devel'   : develsA,
						'Explored': exploredsA,
						'Deniv'   : denivsA,
						'Point'   : [328560, 5108128]},	#crs = 32632	# UTM32N}
				'Criou':{'Nom'    : 'Système du Mirolda - Lucien Bouclier',
						'System'  : 'Système du Criou', 
						'Devel'   : develsCriou,
						'Explored': exploredsCriou,
						'Deniv'   : denivsCriou,
						'Point'   : [327980, 5105701]}	#crs = 32632	# UTM32N}
				}

	# Créer le schéma des shapefiles
	schema = { 'geometry': 'Point', 'properties': { 'LocationID': 'str',
													'Nom': 'str',
													'Reseau': 'str',
													'System': 'str', 
													'Easting' : 'float', 
													'Northing': 'float',
													'Altitude' : 'float',
													'Devel': 'float',
													'Explored': 'float',
													'Deniv': 'float'}}
							
	JB_entrances = ['V4', 'V4bis', 'V6', 'V6b', 'V6ter', 'V15', 'J14', 'V11', 'A14','B19', 'B21', 'B22', 'C37']
	CPres_entrances = ['CP7', 'CP12', 'CP14', 'CP16', 'CP19b']
	CP6_entrances = ['CP6', 'CP53']
	LP9_entrances = ['LP9a', 'CP39']
	A21_entrances = ['A(V)21', 'A24']
	Mirolda_entrances = ['CD11', 'VF3 - Mirolda - Réseau Lucien Bouclier', 
						 'Gouffre de la Rondelle Jaune - F126', 'G. des Jockers',
						 'Entrée de la Falaise', 'Fenêtre']

	with alive_bar(len(systems), title = "\x1b[32;1m- Processing Entrances...\x1b[0m", length = 20) as bar:
		# For each system
		for system in systems:
			print('\tCavités présentes dans le shapefile : %s' %(caves[system]))
			shpout = outpath + system + '-Entrances.gpkg'

			# Make a new shapefile instance
			#with fiona.open(shpout, 'w',crs=from_epsg(crs), driver='ESRI Shapefile', schema=schema) as ouput:
			#with fiona.open(shpout, 'w',crs=from_epsg(crs), driver='GPKG', schema=schema, encoding = 'utf8') as ouput:
			with fiona.open(shpout, 'w',crs=from_epsg(crs), driver='GPKG', schema=schema) as ouput:
				# Find the line corresponding to each big cave
				for cave in caves[system]:
					for line in f:
						if cave == line.split()[0] and (line.split('\t')[5]) != '':
							if cave in JB_entrances:
								#cavename = cave + ' - Jean-Bernard'
								reseau = 'Jean Bernard'
								devel = float(develJB)
								deniv = float(denivJB)
								explored = float(exploredJB)
							elif cave in CPres_entrances:
								#cavename = cave + ' - Réseau CP'
								reseau = 'Combe aux Puaires'
								devel = float(develCP)
								deniv = float(denivCP)
								explored = float(exploredCP)
							elif cave in CP6_entrances:
								#cavename = cave + ' - LP9-CP39'
								reseau : 'CP6 - CP53'
								devel = float(develCP6)
								deniv = float(develCP6)
								explored = float(exploredCP6)
							elif cave in LP9_entrances:
								#cavename = cave + ' - LP9-CP39'
								reseau : 'LP9 - CP39'
								devel = float(develLP9)
								deniv = float(develLP9)
								explored = float(exploredLP9)
							elif cave in A21_entrances:
								#cavename = cave + ' - A21-A24'
								reseau = 'A21 - A24'
								devel = float(develA21)
								deniv = float(denivA21)
								explored = float(exploredA21)
							elif cave in Mirolda_entrances:
								#cavename = cave + ' - Mirolda'
								reseau = 'Mirolda - Lucien Bouclier'
								devel = float(develMirolda)
								deniv = float(denivMirolda)
								explored = float(exploredMirolda)
							else:
								#cavename = cave
								reseau = ''
								devel = float(line.split('\t')[1])
								deniv = float(line.split('\t')[2])
								if line.split('\t')[3] != '':
									explored = float(line.split('\t')[3])
								else:
									explored = 0

							# Extract coordinates, alt, length, depth
							point = Point(float(line.split('\t')[4]), float(line.split('\t')[5]))
							prop = {'LocationID': cave,
									'Nom': cave, 
									'Reseau': reseau,
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
		
	# Make a shapefile with the systems caracteristics
	shpout = outpath + 'BigCaves-info.gpkg'
				
	# Créer le schéma des shapefiles
	Newschema = { 'geometry': 'Point', 
				  'properties': { 'LocationID': 'str',
								  'Nom': 'str',
								  'System': 'str', 
								  'Devel': 'float',
								  'Explored': 'float',
								  'Deniv': 'float'}}
	# Make a new shapefile instance
	#with fiona.open(shpout, 'w',crs=from_epsg(crs), driver='GPKG', schema=Newschema, encoding = 'utf8') as ouput:
	with fiona.open(shpout, 'w',crs=from_epsg(crs), driver='GPKG', schema=Newschema) as ouput:
		# Find the line corresponding to each big cave
		for cave in list(cavesinfo.keys()):
			# Extract coordinates, alt, length, depth
			#point = Point(float(line.split('\t')[4]), float(line.split('\t')[5]))
			point = Point(cavesinfo[cave]['Point'][0], cavesinfo[cave]['Point'][1])
			prop = {'LocationID': cavesinfo[cave]['Nom'],
					'Nom': cavesinfo[cave]['Nom'], 
					'System': cavesinfo[cave]['System'],
					'Devel': float(cavesinfo[cave]['Devel']),
					'Deniv': float(cavesinfo[cave]['Deniv']),
					'Explored': float(cavesinfo[cave]['Explored'])}
					
			# write Name, alt, length, depth in the shapefile as a new attribute
			ouput.write ({'geometry':mapping(point),'properties': prop})
			
	# Make a new shapefile instance
	shpout = outpath + 'Systems-info.gpkg'
	#with fiona.open(shpout, 'w',crs=from_epsg(crs), driver='GPKG', schema=Newschema, encoding = 'utf8') as ouput:
	with fiona.open(shpout, 'w',crs=from_epsg(crs), driver='GPKG', schema=Newschema) as ouput:
		# Find the line corresponding to each big cave
		for system in list(systsinfo.keys()):
			# Extract coordinates, alt, length, depth
			#point = Point(float(line.split('\t')[4]), float(line.split('\t')[5]))
			point = Point(systsinfo[system]['Point'][0], systsinfo[system]['Point'][1])
			prop = {'LocationID': systsinfo[system]['Nom'],
					'Nom': systsinfo[system]['Nom'], 
					'System': systsinfo[system]['System'],
					'Devel': float(systsinfo[system]['Devel']),
					'Deniv': float(systsinfo[system]['Deniv']),
					'Explored': float(systsinfo[system]['Explored'])}
					
			# write Name, alt, length, depth in the shapefile as a new attribute
			ouput.write ({'geometry':mapping(point),'properties': prop})

	print('')
	print('')

	return


#################################################################################################
if __name__ == u'__main__':	
	###################################################
	# initiate variables
	inputfile = 'Caves.txt'

	pathshp = '../../Outputs/SHP/therion/'

	outpath = '../../Outputs/SHP/GPKG/'

	systems = ['SynclinalJB', 'SystemeCP', 'SystemeA21', 'SystemeAV', 'SystemMirolda']

	caves = {'SynclinalJB' : ['V4', 'V4bis', 'V6', 'V6b', 'V6ter', 'J14', 'V11', "V15",
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
			 					"L'Amine Dada - FLT7"],
			#Mirolda_entrances = ['CD11', 'VF3 - Mirolda - Réseau Lucien Bouclier', 
			#			 'Gouffre de la Rondelle Jaune - F126', 'G. des Jockers',
			#			 'Entrée de la Falaise', 'Fenêtre']
			 'SystemeBossetan' : ["Antre d'Oddaz"]}


	crs = 32632	# UTM32N

	###################################################
	# Run the extraction
	ThExtractEntrances(inputfile, pathshp, outpath, systems = systems, caves = caves, crs = crs)
	# End...
