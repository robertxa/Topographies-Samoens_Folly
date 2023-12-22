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
#from fiona.crs import from_epsg
import sys, os, copy
from alive_progress import alive_bar              # https://github.com/rsalmei/alive-progress	


#################################################################################################
#################################################################################################

def ThExtractEntrances(inputfile, pathshp, outpath, systems, caves, entrees_reseaux, crs, cavesinfo, systsinfo):
	"""
	Function to build a point shapefile with the entrances of the main caves,
	with the Easting/Northing/Altitude as attributs' table.

	Args:
		inputfile (str)       : path and name of the sql database to analyse/plot
		pathshp (str)         : path where the shp produced by Therion are stored
		outpath (str)         : path where to copy the gpkg files
		systems (list of str) : Cave systems to consider
		caves (dictionnary)   : Names of main caves for each cave system
		crs (str)             : ESPG code of the coordinates' system; e.g. crs= epsg:32632
		
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

	##################### QUESTIONS ###########################
	# 1) Pour que le code soit transportable, il faut virer les instances spécifiques du coeur du code, 
	# et les transférer dans l'appel à la fonction.
	# Il faut donc un dictionnaire global "Entrances", 
	# qui va contenir les dictionnaires des entrées de chaque grosse cavité.
	
	# 2) Pour chaque cavité, il faut :
	# 	- si la cavité est une entrée d'un réseau à entrées multiple, donner la spéléométrie du réseau
	# 	- Sinon, trouver et donner la spéléométrie de la cavité
	# 	- Pour chaque entrée quelqu'elle soit, trouver et donner les coordonnées
	#
	# 	Ca peut peut-être se faire en construisant un tableau, chaque ligne étant une cavité, et ayant pour colonnes :
	#		- le nom de la cavité
	#		- le nom du système
	#		- La cavité appartient à un réseau à multiples entrées ? --> Boolean
	#		- Le dével de la cavité ou du système
	#		- La profondeur de la cavité ou du système
	#		- Les coordonnées de la cavité
	#	Et tout ça préalablement à la construction du shp --> on le fait ensuite en iterrant sur les lignes du tableau

	##################### QUESTIONS ###########################
	JB_entrances = ['V4', 'V4bis', 'V6', 'V6b', 'V6ter', 'V15', 'J14', 'V11', 'A14','B19', 'B21', 'B22', 'C37']
	CPres_entrances = ['CP7', 'CP12', 'CP14', 'CP16', 'CP19b']
	CP6_entrances = ['CP6', 'CP53']
	LP9_entrances = ['LP9a', 'CP39']
	A21_entrances = ['A(V)21', 'A24']
	#Mirolda_entrances = ['CD11', 'VF3 - Mirolda - Réseau Lucien Bouclier', 
	#					 'Gouffre de la Rondelle Jaune - F126', 'G. des Jockers',
	#					 'Entrée de la Falaise', 'Fenêtre']
	Mirolda_entrances = ['CD11', 'Gouffre VF3 - Réseau Lucien Bouclier', 
						 'Gouffre de la Rondelle Jaune - F126', 'G. des Jockers',
						 'Entrée de la Falaise', 'Fenêtre']

	# check if input file exists
	if not os.path.isfile(pathshp + inputfile):
		raise NameError('\033[91mERROR:\033[00m File %s does not exist' %(str(pathshp + inputfile)))
	if not os.path.exists(outpath):
		print ('\033[91mWARNING:\033[00m ' + outpath + ' does not exist, I am creating it...')
		os.mkdir(outpath)
	
	# open the input file
	f = open(pathshp + inputfile, 'r').readlines()
	for line in f:
		# first, complete cavesinfo dictionnary
		for item in cavesinfo.keys():
			#if item == 'MV' and 'Gouffre des Morts-Vivants' in line: print(cavesinfo[item]['Nom'], line)
			#if cavesinfo[item]['Nom'].strip() in line:
			if item in sum(list(caves.values()), []):
				cavesinfo[item]['Devel'] = line.split('\t')[1]
				cavesinfo[item]['Deniv'] = line.split('\t')[2]
				if line.split('\t')[3] != '':
					cavesinfo[item]['Explored'] = line.split('\t')[3]
				else:
					cavesinfo[item]['Explored'] = 0
			else:
				if cavesinfo[item]['Nom'] in line.split('\t')[0]:
					cavesinfo[item]['Devel'] = line.split('\t')[1]
					cavesinfo[item]['Deniv'] = line.split('\t')[2]
					if line.split('\t')[3] != '':
						cavesinfo[item]['Explored'] = line.split('\t')[3]
					else:
						cavesinfo[item]['Explored'] = 0
				
		for item in caves.values():
			for cavename in item:
				if line.split()[0] == cavename and cavename not in (JB_entrances + CPres_entrances + CP6_entrances + LP9_entrances + A21_entrances + Mirolda_entrances):
					cavesinfo[cavename]['Devel'] = line.split('\t')[1]
					cavesinfo[cavename]['Deniv'] = line.split('\t')[2]
					if line.split('\t')[3] != '':
						cavesinfo[cavename]['Explored'] = line.split('\t')[3]
					else:
						cavesinfo[cavename]['Explored'] = 0
					#if cavename == 'CP6':
					#	print(cavename, line, line.find(cavename))

		# Now, get the data for each entire system
		for item in systsinfo.keys():
			if systsinfo[item]['Nom'] in line:
				systsinfo[item]['Devel']   = line.split('\t')[1]
				systsinfo[item]['Deniv']   = line.split('\t')[2]
			if line.split('\t')[3] != '':
				systsinfo[item]['Explored'] = line.split('\t')[3]
			else:
				systsinfo[item]['Explored'] = 0

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

	with alive_bar(len(systems), title = "\x1b[32;1m- Processing Entrances...\x1b[0m", length = 20) as bar:
		# For each system
		for system in systems:
			print('\tCavités présentes dans le shapefile : %s' %(caves[system]))
			shpout = outpath + system + '-Entrances.gpkg'

			# Make a new shapefile instance
			with fiona.open(shpout, 'w',crs=crs, driver='GPKG', schema=schema, encoding = 'utf8') as output:
				# Find the line corresponding to each big cave
				for cave in caves[system]:
					for line in f:
						if cave == line.split()[0] and (line.split('\t')[5]) != '':		
							if cave in JB_entrances:
								reseau = 'Jean Bernard'
								item = 'JB'
							elif cave in CPres_entrances:
								reseau = 'Combe aux Puaires'
								item = 'CP'
							elif cave in CP6_entrances:
								reseau : 'CP6 - CP53'
								item = 'CP6'
							elif cave in LP9_entrances:
								reseau : 'LP9 - CP39'
								item = 'LP9'
							elif cave in A21_entrances:
								reseau = 'A21 - A24'
								item = 'A21'
							elif cave in Mirolda_entrances:
								reseau = 'Mirolda - Lucien Bouclier'
								item = 'Mirolda'
							else:
								item =''
								reseau = ''
								devel = float(line.split('\t')[1])
								deniv = float(line.split('\t')[2])
								if line.split('\t')[3] != '':
									explored = float(line.split('\t')[3])
								else:
									explored = 0

							if item != '':
								print(item, cave, line, line.split('\t')[5])
								devel = float(cavesinfo[item]['Devel'])
								deniv = float(cavesinfo[item]['Deniv'])
								explored = float(cavesinfo[item]['Explored'])
						
							# elif(line.split('\t')[1]) != '' and (line.split('\t')[5]) == '':		
							# 	if cave in JB_entrances:
							# 		reseau = 'Jean Bernard'
							# 		item = 'JB'
							# 	elif cave in CPres_entrances:
							# 		reseau = 'Combe aux Puaires'
							# 		item = 'CP'
							# 	elif cave in CP6_entrances:
							# 		reseau : 'CP6 - CP53'
							# 		item = 'CP6'
							# 	elif cave in LP9_entrances:
							# 		reseau : 'LP9 - CP39'
							# 		item = 'LP9'
							# 	elif cave in A21_entrances:
							# 		reseau = 'A21 - A24'
							# 		item = 'A21'
							# 	elif cave in Mirolda_entrances:
							# 		reseau = 'Mirolda - Lucien Bouclier'
							# 		item = 'Mirolda'
							# 	else:
							# 		item =''
							# 		reseau = ''
							# 		devel = float(line.split('\t')[1])
							# 		deniv = float(line.split('\t')[2])
							# 		if line.split('\t')[3] != '':
							# 			explored = float(line.split('\t')[3])
							# 		else:
							# 			explored = 0

							# 	if item != '':
							# 		print(item, cave, line, line.split('\t')[5])
							# 		devel = float(cavesinfo[item]['Devel'])
							# 		deniv = float(cavesinfo[item]['Deniv'])
							# 		explored = float(cavesinfo[item]['Explored'])

							# Extract coordinates, alt, length, depth
							print(cave, line)
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
							output.write ({'geometry':mapping(point),'properties': prop})
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
	with fiona.open(shpout, 'w',crs=crs, driver='GPKG', schema=Newschema, encoding = 'utf8') as output:
		# Find the line corresponding to each big cave
		for cave in list(cavesinfo.keys()):
			# Extract coordinates, alt, length, depth
			#point = Point(float(line.split('\t')[4]), float(line.split('\t')[5]))
			point = Point(cavesinfo[cave]['Point'][0], cavesinfo[cave]['Point'][1])
			#print(cave, cavesinfo[cave])
			prop = {'LocationID': cavesinfo[cave]['Nom'],
					'Nom': cavesinfo[cave]['Nom'], 
					'System': cavesinfo[cave]['System'],
					'Devel': float(cavesinfo[cave]['Devel']),
					'Deniv': float(cavesinfo[cave]['Deniv']),
					'Explored': float(cavesinfo[cave]['Explored'])}
					
			# write Name, alt, length, depth in the shapefile as a new attribute
			output.write ({'geometry':mapping(point),'properties': prop})
			
	# Make a new shapefile instance
	shpout = outpath + 'Systems-info.gpkg'
	with fiona.open(shpout, 'w',crs=crs, driver='GPKG', schema=Newschema, encoding = 'utf8') as output:
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
			output.write ({'geometry':mapping(point),'properties': prop})

	print('')
	print('')

	return


#################################################################################################
#################################################################################################
if __name__ == u'__main__':	
	###################################################
	###### User must change the values of the variables here to adapt the script to their system #######
	# initiate variables
	# inputfile: name of the .txt file build by Therion where caves' info are stored
	inputfile = 'Caves.txt'
	# pathshp: path where are stored the shapefiles output by Therion
	pathshp = '../../Outputs/SHP/therion/'
	# outpath: path where we will store the new shapefiles produced by this script
	outpath = '../../Outputs/SHP/GPKG/'
	# systems: list of the karstic systems to work on; 
	# 		   theses names are the names used in the Therion survey definition
	systems = ['SynclinalJB', 'SystemeCP', 'SystemeA21', 'SystemeAV', 'SystemMirolda']

	# entrees_reseaux: list of all the entrances of a multi-entrances cave
	entrees_reseaux = {'JB'         : ['V4', 'V4bis', 'V6', 'V6b', 'V6ter', 'V15', 'J14', 'V11', 
									   'A14','B19', 'B21', 'B22', 'C37'],
					   'CP'         : ['CP7', 'CP12', 'CP14', 'CP16', 'CP19b'],
					   'CP6 - CP53' : ['CP6', 'CP53'],
					   'LP9 - CP39' : ['LP9a', 'CP39'],
					   'A21 - A24'  : ['A(V)21', 'A24'],
						#Mirolda_entrances = ['CD11', 'VF3 - Mirolda - Réseau Lucien Bouclier', 
						#					 'Gouffre de la Rondelle Jaune - F126', 'G. des Jockers',
						#					 'Entrée de la Falaise', 'Fenêtre']
					   'Mirolda'    : ['CD11', 'Gouffre VF3 - Réseau Lucien Bouclier', 
						 			   'Gouffre de la Rondelle Jaune - F126', 'G. des Jockers',
									   'Entrée de la Falaise', 'Fenêtre']
					  }
	
	# caves: for each system defined in the Therion structure, names of the entrances to extract
	caves = {'SynclinalJB' : ['V4', 'V4bis', 'V6', 'V6b', 'V6ter', 'J14', 'V11', "V15",
							  'A14',
							  'B19', 'B21', 'B22',
							  'D11', 'D33',
							  #'C14', 'C24', 'C31', 'C37', 'C74',
							  'C14', 'C37', 'C74',
							  #'CH3', 'CH17', 'CH24'],
							  'CH3', 'CH17'],
			 'SystemeCP' : ['CP12', 'CP14', 'CP16', 'CP19b', 'CP21', 'CP17',
			 				#'CP1', 'CP3', 'CP6', 'CP53', 'CP7', 'CP19', 'CP32',
							'CP1', 'CP3', 'CP6', 'CP53', 'CP7', 'CP32', 
							'BA06',
							'Ermoy',
							#'LP2', 'LP19', 'LP23',
							#'T35',
			 				'LP9a', 'CP39',
							'DR09'],
			 'SystemeA21' : ['A21', 'A22', 'A24'],
			 'SystemeAV' : ['AV8'],
			 'SystemMirolda' : ['CD11', 'Gouffre VF3 - Réseau Lucien Bouclier', 'F126', 'Jockers', 'Falaise', 'Fenêtre',
			 					"L'Amine Dada - FLT7", "Gouffre des Morts-Vivants - FLT5"],
			#Mirolda_entrances = ['CD11', 'VF3 - Mirolda - Réseau Lucien Bouclier', 
			#			 'Gouffre de la Rondelle Jaune - F126', 'G. des Jockers',
			#			 'Entrée de la Falaise', 'Fenêtre']
			 'SystemeBossetan' : ["Antre d'Oddaz"]}

	# crs: projected coordinates system to use for the new shapefiles
	crs = 'epsg:32632'	# UTM32N
				
	# cavesinfo: for each cave, what and where to plot infos
	#			 If a cave has multiple entrances, the name should be the same 
	# 			 	than the keys of the entrees_reseaux dictionnary
	############## C'EST UN PEU REDONDANT AVEC LES DICTIONNAIRES caves & entrees_reseaux.  N'Y A-T-IL PAS MOYEN DE SIMPLIFIER ?
	cavesinfo = {'JB' : {'Nom'    : 'Gouffre Jean Bernard',
						'System'  : 'Système du Jean Bernard', 
						'Point'   : [328917,5107359]},	#crs = 32632	# UTM32N
				'C14' : {'Nom'    : 'Gouffre C14',
						'System'  : 'Système du Jean Bernard', 
						'Point'   : [329771, 5108401]},	#crs = 32632	# UTM32N
				'C74' : {'Nom'    : 'Gouffre C74',
						'System'  : 'Système du Jean Bernard', 
						'Point'   : [330128, 5108363]},	#crs = 32632	# UTM32N
				'CH17' : {'Nom'   : 'Gouffre CH17',
						'System'  : 'Système du Jean Bernard', 
						'Point'   : [330832, 5108363]},	#crs = 32632	# UTM32N
				'CH3' : {'Nom'    : 'Gouffre CH3',
						'System'  : 'Système du Jean Bernard', 
						'Point'   : [330544, 5107569]},	#crs = 32632	# UTM32N
				'D11' : {'Nom'    : 'Gouffre D11',
						'System'  : 'Système du Jean Bernard', 
						'Point'   : [329584, 5108185]},	#crs = 32632	# UTM32N
				'D33' : {'Nom'    : 'Gouffre D33',
						'System'  : 'Système du Jean Bernard', 
						'Point'   : [329386, 5108204]},	#crs = 32632	# UTM32N
				'CP' : {'Nom'     : 'Combe aux Puaires',
						'System'  : 'Système de la Combe aux Puaires', 
						'Point'   : [330447, 5108711]},	#crs = 32632	# UTM32N
				'BA06' : {'Nom'    : 'Gouffre BA6',
						'System'  : 'Système de la Combe aux Puaires', 
						'Point'   : [327762, 5107885]},	#crs = 32632	# UTM32N
				'CP3': {'Nom'     : 'Gouffre CP3',
						'System'  : 'Système de la Combe aux Puaires', 
						'Point'   : [330438, 5109565]},	#crs = 32632	# UTM32N
				'CP6 - CP53': {'Nom'     : 'CP6 - CP53',
						       'System'  : 'Système de la Combe aux Puaires', 
						       'Point'   : [329912, 5109725]},	#crs = 32632	# UTM32N
				'CP17': {'Nom'    : 'Gouffre CP17',
						'System'  : 'Système de la Combe aux Puaires', 
						'Point'   : [329696, 5109405]},	#crs = 32632	# UTM32N
				'CP21': {'Nom'    : 'Gouffre CP21',
						'System'  : 'Système de la Combe aux Puaires', 
						'Point'   : [329351, 5109169]},	#crs = 32632	# UTM32N
				'CP32': {'Nom'    : 'Gouffre CP32',
						'System'  : 'Système de la Combe aux Puaires', 
						'Point'   : [329368, 5108758]},	#crs = 32632	# UTM32N
				'LP9 - CP39': {'Nom'     : 'LP9 - CP39',
						       'System'  : 'Système de la Combe aux Puaires', 
						       'Point'   : [330081, 5109086]},	#crs = 32632	# UTM32N
				'Ermoy': {'Nom'   : "Grotte de l'Ermoy",
						'System'  : 'Système de la Combe aux Puaires', 
						'Point'   : [326692, 5107669]},	#crs = 32632	# UTM32N
				'A21 - A24': {'Nom'     : 'Réseau A21 - A24',
						      'System'  : 'Système du A21', 
						      'Point'   : [328542, 5108119]},	#crs = 32632	# UTM32N
				'A22': {'Nom'     : 'A22',
						'System'  : 'Système du A21', 
						'Point'   : [328372, 5108018]},	#crs = 32632	# UTM32N
				'AV8': {'Nom'     : 'AV8',
						'System'  : 'Système des Avoudrues', 
						'Point'   : [331396, 5107739]},	#crs = 32632	# UTM32N
				'Mirolda': {'Nom' : 'Gouffre Mirolda - Réseau Lucien Bouclier',
						    'System'  : 'Système du Criou', 
						    'Point'   : [328410, 5106383]},	#crs = 32632	# UTM32N
				'MV': {'Nom'      : 'Gouffre des Morts-Vivants',
						'System'  : 'Système du Criou', 
						'Point'   : [328663, 5105646]},	#crs = 32632	# UTM32N
				'AOddaz': {'Nom'     : "AntreOddaz",
						   'System'  : 'Système du Tuet', 
						   'Point'   : [327265, 5109190]}	#crs = 32632	# UTM32N
				}
	# systinfo: for each system, what and where to plot infos
	systsinfo = {'JB' : {'Nom'     : 'Réseau du Jean Bernard',
						'System'  : 'Système du Jean Bernard', 
						#'Point'   : [328750, 5107082]},	#crs = 32632	# UTM32N
						'Point'   : [328750, 5107265]},	#crs = 32632	# UTM32N
				'CP' : {'Nom'     : 'Système de la Combe aux Puaires',
						'System'  : 'Système de la Combe aux Puaires', 
						'Point'   : [327827, 5108791]},	#crs = 32632	# UTM32N}
				'AV' : {'Nom'     : 'Système des Avoudrues',
						'System'  : 'Système des Avoudrues', 
						'Point'   : [331299, 5107449]},	#crs = 32632	# UTM32N}
				'A'  : {'Nom'     : 'Système du A21',
						'System'  : 'Système du A21', 
						'Point'   : [328560, 5108128]},	#crs = 32632	# UTM32N}
				'Criou':{'Nom'    : 'Système du Mirolda - Lucien Bouclier',
						'System'  : 'Système du Criou', 
						'Point'   : [327980, 5105701]}	#crs = 32632	# UTM32N}
				}
	###### END of User's changes #######

	###################################################
	# Run the extraction
	ThExtractEntrances(inputfile, pathshp, outpath, 
					   systems = systems, caves = caves, entrees_reseaux = entrees_reseaux,
					   crs = crs, cavesinfo = cavesinfo, systsinfo = systsinfo)
	# End...
