######!/usr/bin/env python
# -*- coding: utf-8 -*-
###################################
#                                 #
#       Plot Ermoy Data           #
#       by Xavier Robert          #
#           Jan 2019              #
#                                 #
###################################


# Do divisions with Reals, not with integers
# Must be at the beginning of the file
#from __future__ import division
#from __future__ import absolute_import
#from __future__ import print_function

import pandas as pd
#from pandas import Series
#from matplotlib import pyplot
import matplotlib.pyplot as plt
#import matplotlib.dates as mdates
#from matplotlib.dates import DateFormatter
#from statsmodels.graphics.tsaplots import plot_pacf
import scipy.io as spio
import datetime

# hauteur d'eau (en m) au dessus de laquelle les siphons temporaires ne passent pas
seuil = 5
# define the year range of the record
annee =[2001, 2002, 2003, 2004, 2005, 2006, 2007]

###################################
# Read data from ErmoyGraph
ermoydata = spio.loadmat('DonneeErmoy-steph/Data.mat')
ermoyD = ermoydata['Data']
# Il y a 8 colonnes. 
#	Les colonnes 0-6 correspondent aux dates
#       Colonne 1 = année
#       Colonne 2 = mois
#       Colonne 3 = jour
#       Colonne 4 = heure
#       Colonne 5 = min
#       Colonne 6 = sec
#       Colonne 7 = ??? --> Only NaN
#	La colonne 8 à la hauteur d'eau
# Remove the column 7 that contains only NaN
#ermoyD = np.delete(ermoyD, 6, 1)

# move np array to pandas
Ermoydf = pd.DataFrame(ermoyD, columns = ['year', 'month', 'day', 'hour', 'minute', 'second', 'NaN', 'height'])
# change type of the first 6 columns to int
for item in ['year', 'month', 'day', 'hour', 'minute', 'second']:
    Ermoydf[item] = pd.to_numeric(Ermoydf[item], errors = 'coerce')
    Ermoydf = Ermoydf.dropna(subset = [item])
    if item != 'height':
        Ermoydf[item] = Ermoydf[item].astype(int)
        Ermoydf[item] = Ermoydf[item].astype(str)
Ermoydf['Datetime'] = pd.to_datetime(Ermoydf['year'] + '-' + Ermoydf['month'] + '-' + Ermoydf['day'] + ' ' + Ermoydf['hour'] + ':' + Ermoydf['minute'] + ':' + Ermoydf['second'],
                                errors = 'coerce')
# Set Datetime as index
Ermoydf = Ermoydf.set_index('Datetime')
# Remove unused columns
Ermoydf = Ermoydf.drop(['year', 'month', 'day', 'hour', 'minute', 'second', 'NaN'], axis = 1)
# set the index as a column
Ermoydf = Ermoydf.reset_index()

###############################################
# Print the height of the water
fig1, ax1 = plt.subplots(6, 1, figsize=(18, 10))

for i in range (1, len(annee)):
    Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]].plot(x = 'Datetime', y = 'height', 
                                                                                   ax = ax1[i-1],
                                                                                   label = "Water height (" + str(annee[i]) + ")")
    ax1[i-1].set_xlim(datetime.datetime(annee[i], 1, 1), datetime.datetime(annee[i], 12, 31))
    ax1[i-1].hlines(y = seuil, xmin = datetime.datetime(annee[i], 1, 1), xmax = datetime.datetime(annee[i], 12, 31),
                    linestyles='solid', color ='r', alpha = 0.5)

# Calculate global min and max for y-axis (sales)  
y_min = Ermoydf['height'].min()  # Minimum sales value  
y_max = Ermoydf['height'].max()  # Maximum sales value
# Add a small buffer to y-limits for readability  
y_buffer = (y_max - y_min) * 0.05  # 5% buffer  
y_min -= y_buffer  
y_max += y_buffer
# Apply uniform y-limits to all subplots  
#date_form = DateFormatter("%m-%d")
#years = mdates.YearLocator()   # every year
#months = mdates.MonthLocator()  # every month
#yearsFmt = mdates.DateFormatter('%M')
#print (date_form)
for ax in ax1:  
    ax.set_ylim(y_min, y_max)  # Same y-scale for all
    ax.set_xlabel(" ", fontsize=10)  # X-label for all  
    #ax.xaxis.set_major_formatter(mdates.ConciseDateFormatter(ax.xaxis.get_major_locator()))
    #ax.xaxis.set_major_formatter(date_form)
    #ax.xaxis.set_major_locator(months)
    #ax.xaxis.set_major_formatter(yearsFmt)
    #ax.xaxis.set_minor_locator(months)
    ax.grid(True, alpha = 0.5)

fig1.autofmt_xdate()
    
# common axis labels
fig1.supxlabel('Date')
fig1.supylabel('Water height (m)')

plt.tight_layout()

plt.show()
fig1.savefig('Graphs/Ermoygraphe_Hauteru_Eau.pdf')



# load the Meteo mat files
rawmat = spio.loadmat('RawData.mat')
meteo = rawmat['RawData']
# Il y a 6 colonnes
#	colonne 0 = Année
#	colonne 1 = mois
#   colonne 2 = jour
#	colonne 3 = heure
#	colonne 4 = 
# 	colonne 5 = 


#Année : array([[2003]], dtype=uint16), 
#Mois : array([[1]], dtype=uint8),
#Jour : array([[1]], dtype=uint8), 
#Heure : array([[22]], dtype=uint8),
#Heure : array(['22 h'], dtype='<U4'), 
#?? : array([], dtype='<U1'),
#?? : array(['  '], dtype='<U2'), 
# ?? : array([], dtype='<U1'),
#Temperature : array(['2.3 °C'], dtype='<U6'), 
#Humidity : array(['100% '], dtype='<U5'),
#?? : array(['2.3 '], dtype='<U4'), 
#Temperature : array(['1.5 °C'], dtype='<U6'),
#?? : array([], shape=(1, 0), dtype=float64),
#VitesseVent : array(['4 km/h '], dtype='<U7'), 
#?? : array([' '], dtype='<U1'),
#Precipitations : array([' 4.0 mm (sur 3h)'], dtype='<U16')]

# move np array to pandas
meteodf = pd.DataFrame(meteo, columns = ['year', 'month', 'day', 'hour', 'hour_str', 
                                        'minute??', 'second??', 'NaN ?', 
                                        'Temperature', 'Humidity', 
                                        'Tmax', 'Tmin',
                                        'NaN ??', 'Wind', 'NaN ???', 'Precipitations'])
# change type of the first 6 columns to int
for item in ['year', 'month', 'day', 'hour']:
    meteodf[item] = pd.to_numeric(meteodf[item], errors = 'coerce')
    #meteodf = meteodf.dropna(subset = [item])
    #if item not in ['hour_str', 'minute??', 'second??', 'NaN ?', 'Temperature', 'Humidity', 'Tmax', 'Tmin', 'NaN ??', 'Wind', 'NaN ???', 'Precipitations'] :
    #    meteodf[item] = meteodf[item].astype(int)
    #    meteodf[item] = meteodf[item].astype(str)
meteodf['Datetime'] = pd.to_datetime(str(meteodf['year']) + '-' + str(meteodf['month']) + '-' + str(meteodf['day']) + ' ' + str(meteodf['hour']) + ':00:00',
                                errors = 'coerce')
# Set Datetime as index
meteodf = meteodf.set_index('Datetime')
# Remove unused columns
meteodf = meteodf.drop(['year', 'month', 'day', 'hour','hour_str'], axis = 1)
# set the index as a column
meteodf = meteodf.reset_index()





#series = Series.from_csv('daily-minimum-temperatures.csv', header=0)
#plot_pacf(series, lags=50)
#pyplot.show()



# Plot autocorrelogram --> lags in days
#   https://stackoverflow.com/questions/643699/how-can-i-use-numpy-correlate-to-do-autocorrelation

# plot autocorrelogram with statsmodels
#from statsmodels.tsa import stattools
#autocorr = stattools.acf(ermoyD[])
#from statsmodels.graphics import tsaplots
#fig = tsaplots.plot_acf(x, lags=10)
# or with pandas ? https://blog.finxter.com/pandas-plotting-autocorrelation/
#import pandas as pd
from pandas.plotting import autocorrelation_plot
# Build the pd dataframe
#dataframe = pd.DataFrame(income_vs_expenditure_timeseries)
#dataframe["Date"] = dataframe["Date"].astype("datetime64")
#dataframe = dataframe.set_index("Date")
# do the autocorrelation plot
autocorrelation_plot(dataframe)
# Save the plot
#plt.savefig('autocorrel.pdf')



# Calculer :
#   - la vitesse de montée de l'eau en fonction de la hauteur d'eau
#   - les vitesses de baisse de l'eau en fonction de la hauteur d'eau
#   - Estimer la quantité d'eau drainée par le karst en calculant l'aire drainée à partir de QGIS --> Il faut bien déterminer ce qui est drainé par le karst et ce qui ne l'est pas
#   - Estimer pour chaque épisode de pluie le volume d'eau absorbé par le karst
#   - Estimer le volume du karst noyé avec l'approximation de 2 milieu poreux avec une fuite différente
#   - Estimer la longueur de conduits à explorer ? (fonction des sections spécifiques, à faire pour de petites sections [1 m2], pour des moyennes sections [4*4 = 16 m2], et pour de grandes sections [10%10 = 100 m2])
#   - Estimer volume de la zone noyée ?
#   - Comparer avec les enregistrement piezzométriques de la vallée du Giffre ? Est-ce qu'il existe des données ? Qui les as ? Comment y accéder ? --> Voir avec Le Dav ? La mairie de Samoëns ?
#   - 


