######!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2020 Xavier Robert <xavier.robert@ird.fr>
# SPDX-License-Identifier: GPL-3.0-or-later


"""
##########################################################
#                                                        #  
#     Script to automatize plot of Therion databases     #
#                                                        #  
#                 By Xavier Robert                       #
#               Grenoble, february 2022                  #
#                                                        #  
##########################################################

Written by Xavier Robert, february 2022

xavier.robert@ird.fr

"""

# Do divisions with Reals, not with integers
# Must be at the beginning of the file
from __future__ import division

# Import Python modules
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import sqlite3
import sys, os, copy
import datetime
from alive_progress import alive_bar              # https://github.com/rsalmei/alive-progress	

#################################################################################################
def Rose(conn, graphpath, bins = 72):
	"""
	Plot a Rose diagram of the entire database

	Args:
		conn (sqlite_db): database sqlite
		graphpath (str): path and name of the graph to save
		bins (int, optional): bins for the plot. Defaults to 72.
	"""
	
	# Extract the right data
	df = pd.read_sql_query("select * from SHOT;", conn)

	# Built the histogram
	#h, e = np.histogram(df["BEARING"] * np.pi/180., weights = df["LENGTH"], bins = bins)
	# Pour enlever les visées verticales (et donc de bearing systématiquement à 0°...)
	h, e = np.histogram(df["BEARING"] * np.pi/180., weights = df["LENGTH"]* (90-np.abs(df["GRADIENT"]))/100, bins = bins)
	
	# Plot the rose diagram
	ax = plt.subplot(111, projection = "polar")
	ax.set_theta_zero_location("N")
	ax.set_theta_direction(-1)
	ax.bar(e[:-1], h, align = "edge", width = e[1]-e[0])
	
	# Save the rose diagram
	plt.savefig(graphpath + "-rose_diagram.pdf")
	# Close the graph
	plt.close(plt.figure(1))
	
	return

#################################################################################################
def Shot_lengths_histogram(conn, graphpath, bins = 72, log = None):
	"""
	Plot the histogram of the lengths of the shots for the entire database

	Args:
		conn (sqlite_db): database sqlite
		graphpath (str): path and name of the graph to save
		bins (int, optional): bins for the plot. Defaults to 72.
		log (str, optional): set it to 'log' to use a y-logscale. Defaults to None.
	"""
	
	# Extract the right data
	df = pd.read_sql_query("select * from SHOT;", conn)
	
	# plot the histogram
	plt.hist(df["LENGTH"], bins = bins)
	plt.xlabel("Longueur de visée (m)")
	plt.ylabel("Nombre")
	plt.xlim(0,50)
	
	# If log y-scale, set it
	if log:
		plt.yscale("log")
		
	# save
	plt.savefig(graphpath + "-shot_lengths_histogram.pdf")
	plt.close(plt.figure(1))
	
	return


#################################################################################################
def PlotExploYears(conn, graphpath, 
				   rangeyear = [1959, datetime.date.today().year], 
				   systems = None):
	"""
	

	Args:
		conn (sqlite_db): database sqlite
		graphpath (str): path and name of the graph to save
		rangeyear (np.array of integers, optional): 2 elements numpy array that gives the range of the years to analyse. Defaults to [1959, datetime.date.today().year].
		systems (list of str, optional): list of specific systems to plot if needed. Defaults to None.
	"""

	# define colors to use; You may add colors if needed
	colores = ['tab:blue', 'tab:red', 'tab:green', 'tab:orange', 'tab:purple', 
			   'tab:marron', 'tab:olive', 'tab:pink', 'tab:cyan']
	
	if systems:
		# Initiate variables
		somme = pd.DataFrame(columns = ['System', 'Year', 'Longueur'])
		# Loop on the systems and the years
		for system in systems:
			for date in range(rangeyear[0], rangeyear[1]):
				# Define SQL query
				lquery = "select sum(LENGTH) from CENTRELINE where SURVEY_ID in (select ID from SURVEY where FULL_NAME LIKE '%s%s%s') and TOPO_DATE between '%s-01-01' and '%s-12-31';" %(chr(37), str(system),chr(37), str(date), str(date))
				junk = pd.read_sql_query(lquery, conn)
				# Update the DataFrame line to line
				somme = somme.append({'System' : system,
								  'Year' : int(date),
							 	  'Longueur' : junk.to_numpy()[0][0]}, ignore_index = True)

		# plot the histogram since the first survey
		fig = plt.figure(1)
		ax1 = fig.add_subplot(111)
		
		fig2 = plt.figure(2)
		ax2 = fig2.add_subplot(111)
		
		# Extract the values for the first system
		sommesys = somme[somme['System'] == systems[0]]
		# Change None values to 0
		sommeplot = sommesys.fillna(0)
		# Remove the column with the names of the systems
		del sommeplot["System"]

		ax1.bar(sommeplot["Year"], 
		        sommeplot["Longueur"], 
				width = 0.5,
				color = colores[0],
				label = systems[0])
		ax2.bar(sommeplot["Year"], 
		        np.cumsum(sommeplot["Longueur"])/1000, 
				width = 0.5,
				color = colores[0],
				label = systems[0])
		
		# Skip the loop on systems if there is only one system requested --> stacked barplot not needed
		if len(systems) > 1:
			# Check if the number of colors is enough for the numer of systems
			if len(systems)>len(colores):
				raise NameError('\033[91mERROR:\033[00m Number of colors lower than the number of systems!\n\tedit the code to add colors in the list, or lower the number of systems to plot')
			# Copy the lenght column in an other column to trace of it
			sommeplot[systems[0]] = sommeplot["Longueur"]

			for system in systems[1:]:
				# Extract the length for the system
				temp = somme[somme['System'] == system]
				# Replace NaN values by 0 to avoid None values in the sums
				tempplot = temp.fillna(0)
				# Reset the indexes to permit the sum of the length per year
				tempplot.reset_index(inplace = True)
				
				del tempplot["System"]
				# Update the barplot
				ax1.bar(tempplot["Year"],
			    	    tempplot["Longueur"], 
						bottom = sommeplot["Longueur"], 
						width = 0.5,
						color = colores[systems.index(system)], 
						label = system)				

				# Print the cumulative barplot
				ax2.bar(tempplot["Year"], 
			    	    np.cumsum(tempplot["Longueur"])/1000, 
						bottom = np.cumsum(sommeplot["Longueur"])/1000, 
						width = 0.5,
						color = colores[systems.index(system)],  
						label = system)

				# Do the sum of the length, and write it in the length column
				sommeplot["Longueur"] = sommeplot["Longueur"] + tempplot["Longueur"]
				# Copy the length of the system in a new column
				sommeplot[systems[systems.index(system)]] = tempplot["Longueur"]
				

		# Plot mean line
		ax1.axhline(y = somme["Longueur"].mean(), color='red', linestyle='--', label = 'Moy. annuelle')
		ax1.set_xlabel("Année")
		ax1.set_ylabel("Longueur topographiée (m)")
		ax1.legend(loc = 'best')
		# Save the histogram
		fig.savefig(graphpath + "-ExploYear-Reseau.pdf")
		plt.close(plt.figure(1))

		# plot the cumulative histogram since the first survey
		ax2.set_xlabel("Année")
		ax2.set_ylabel("Longueur topographiée cumulée (km)")
		ax2.legend(loc = 'best')
		# Save the cumulative histogram
		fig2.savefig(graphpath + "-ExploYearCum-Reseau.pdf")
		plt.close(plt.figure(1))

	else:
		somme = pd.DataFrame(columns = ['Year', 'Longueur'])
		for date in range(rangeyear[0], rangeyear[1]):
			lquery = "select sum(LENGTH) from CENTRELINE where TOPO_DATE between '%s-01-01' and '%s-12-31';" %(str(date), str(date))	
			junk = pd.read_sql_query(lquery, conn)
			somme = somme.append({'Year' : int(date),
							 	  'Longueur' : junk.to_numpy()[0][0]}, ignore_index = True)

		# plot the histogram since the first survey
		plt.bar(somme["Year"], somme["Longueur"], width = 0.5)
		# plot mean
		plt.axhline(y = somme["Longueur"].mean(), color='red', linestyle='--', label = 'Moy. annuelle')
		plt.xlabel("Année")
		plt.ylabel("Longueur topographiée (m)")
		# Save the histogram
		plt.savefig(graphpath + "-ExploYear.pdf")
		plt.close(plt.figure(1))

		# plot the cumulative histogram since the first survey
		plt.bar(somme["Year"], np.cumsum(somme["Longueur"].fillna(0))/1000, width = 0.5)
		plt.xlabel("Année")
		plt.ylabel("Longueur topographiée cumulée (km)")
		# Save the cumulative histogram
		plt.savefig(graphpath + "-ExploYearCum.pdf")
		plt.close(plt.figure(1))

	return


#################################################################################################
def ExtratSummary(datadb, graphpath, rangeyear = [1959, datetime.date.today().year, 1]):
	# to build a table with, for each year :
	# 	- each centerline surveyed
	#	- Date of the survey
	#	- The network/cave/survey/system
	#	- length surveyed
	#	- length estimated
	#	- length duplicated
	#	- Persons who did the exploration/the survey
	# Need to be ordered by year, then by system, then by caves, and then by network if needed,

	# Needs to play with different queries to get right info and build the right table

	print('\t\tNot Implemented Yet...')

	# extract data
	# 	- each centerline surveyed
	#	- Date of the survey
	#	- The network/cave/survey/system
	#	- length surveyed, by centreline, with the sum by year for the last line of the given year, by system
	#	- length estimated, summed by year/day to avoid multiple lines for each explored cave ? --> Non disponible...
	#	- length duplicated
	#	- Persons who did the exploration/the survey
	# Need to be ordered by year, then by system, then by caves, and then by network if needed,
	# Build the query
	lquery = "test" # To build; do some test !
	
	#lquery = "select NAME, TOPO_DATE, LENGTH, DUPLICATE_LENGHT, NAME, SURNAME from SURVEY, CENTRELINE, TOPO, PERSON group by TOPO_DATE order by 1 desc;"
	#lquery = "select NAME, TOPO_DATE, LENGTH, NAME, SURNAME from SURVEY, CENTRELINE, TOPO, PERSON;"
	
	# Read the database
	#junk = pd.read_sql_query(lquery, conn)

	# Build the structure of the table
	# 1 line = 1 centreline
	# 1 Row = 1 field
	# Do a filter to choose to plot for a specific time-range with a specific bin ?
	#	--> Do a function to extract data ?
	# Do a filter to extract only a single system?

	# Do we need to use/build a dictionnary to write in the table 
	# only the first letters of the name of the people instead of the full names ?
	#	--> Smaller table, much easier to import in a text document ?
	# HEADERS
	# Date / Système / Cavité / Centreline Name / Topographes / L topo / L estimée / L dupliquée / 
	# 			Total JB topo (A la fin de chaque année) / Total JB Estimé (A la fin de chaque année) / 
	# 			Total CP topo (A la fin de chaque année) / Total CP estimé (A la fin de chaque année) / 
	# 			Total A21 topo (A la fin de chaque année) / Total A21 estimé (A la fin de chaque année) / 
	# 			Total AV topo (A la fin de chaque année) / Total AV estimé (A la fin de chaque année) 
	# DERNIEREs LIGNEs si tableau généré pour toute la période d'exploration des Vulcains
	# Total topo/estimé cumulé : sur le Jb, sur la CP, sur le A21, sur les AV et au total sur tout le massif (JB + CP + A21)

	# save the table
	#	Which format ? xlsx ? Pdf ? txt ? Html ?
	#		--> Xlsx OK
	#	sumtable.to_excel(graphpath + "-SummaryTable.xlsx", index = False)
	#		--> Pdf OK


	return
#
#

#################################################################################################
#################################################################################################

def PlotThStats(inputfile, graphfolder = "Graphs/", 
				graphprefix = None, 
				bins = 72, log = None, 
				rangeyear = None, 
				systems = None):
	"""
	Function to call all the other functions to plot the Therion database.
	Before to run this function, you need to change the encoding of the database with sqlite3.
		For a database.sql, in a terminal, run :
			sqlite3 database_new.sql
			sqlite> .read database.sql

	Args:
		inputfile (str): path and name of the sql database to analyse/plot
		graphfolder (str, optional): name of the folder wher we save the graphs. Defaults to "Graphs/".
		graphprefix (str, optional): prefix for the graphs' names. Defaults to None.
		bins (int, optional): bins for the plot. Defaults to 72.
		log (str, optional): set it to 'log' to use a y-logscale. Defaults to None.
		rangeyear (np.array of integers, optional): 2 elements numpy array that gives the range of the years to analyse. Defaults to None.
		systems (list of str, optional): list of specific systems to plot if needed. Defaults to None.

	Raises:
		NameError: error with the input file; see the description when the error is raised.
	"""
	
	print(' ')
	print(' ')
	print('******************************************')
	print('Program to plot Therion statistics')
	print('     Written by X. Robert, ISTerre')
	print('           February 2022      ')
	print('******************************************')
	
	# check if input file exists
	if not os.path.isfile(inputfile):
		raise NameError('\033[91mERROR:\033[00m File %s does not exist' %(str(inputfile)))
	# Test if the file is in the correct format; Otherwise, explain how to get rid of it
	try:
		df = pd.read_sql_query("select * from CENTRELINE;", sqlite3.connect(inputfile))
	except:
		raise NameError('\033[91mERROR:\033[00m The %s database is not a valid database...\n\tYou need to update its structure to a _new database:\n\tIn a terminal by typing:\n\t\tsqlite3 %s_new.sql\n\t\tsqlite> .read %s\n\n' %(inputfile, inputfile[:-4], inputfile))

	# Check if there is a folder to store the outputs
	print('\x1b[32;1m\nPlotting results...\x1b[0m')
	if not os.path.exists(graphfolder):
		print('\tMaking %s...' %(str(graphfolder)))
		os.mkdir(graphfolder)
	else:
		print('\t%s already exists...' %(str(graphfolder)))

	if not graphprefix: graphprefix = inputfile[:-4]
	graphpath = os.path.join(graphfolder, graphprefix)

	if systems:
		Nb = 6
	else:
		Nb = 5
	# Define the progress-bar
	with alive_bar(Nb, title = "\x1b[32;1m- Processing...\x1b[0m", length = 35) as bar:
		# Load the Therion database
		print('\tReading database')
		datadb = sqlite3.connect(inputfile)
		# Update the progress-bar
		bar()

		# Plot the Rose diagram
		print('\tPlotting Rose diagram')
		Rose(datadb, graphpath, bins)
		# Update the progress-bar
		bar()

		# Plot the shot lengths histogram
		print('\tPlotting lengths histogram')
		Shot_lengths_histogram(datadb, graphpath, bins, log)
		# Update the progress-bar
		bar()

		# Plot the length over years
		print('\tPlotting global survey evolution')
		PlotExploYears(datadb, graphpath, rangeyear = rangeyear)
		# Update the progress-bar
		bar()
		if systems:
			# Plot the length over years per karstic system
			print('\tPlotting survey evolution system by system')
			PlotExploYears(datadb, graphpath, rangeyear = rangeyear, systems = systems)
			# Update the progress-bar
			bar()

		# Extrat summary table
		print('\tExtract summary table')
		ExtratSummary(datadb, graphpath, rangeyear = [1959, datetime.date.today().year, 1])
		# Update the progress-bar
		bar()

	print('')
	print('')



if __name__ == u'__main__':	
	###################################################
	# initiate variables
	inputfile = 'TestJB.sql'
	#inputfile = 'TestCP7.sql'

	graphfolder = "Graphs/" 
	#graphprefix = None
	#bins = 144
	#log = "log"

	rangeyear = [1959, datetime.date.today().year]
	#rangeyear = None

	#systems = ['SynclinalJB.MassifFolly', 'SystemeCP.MassifFolly', 'SystemeA21.MassifFolly', 'SystemeAV.MassifFolly']
	systems = ['SynclinalJB', 'SystemeCP', 'SystemeA21', 'SystemeAV']
	#systems = None

	###################################################
	# Run the plots
	PlotThStats(inputfile, graphfolder = graphfolder, 
				rangeyear = rangeyear, systems = systems)
	# End...
