######!/usr/bin/env python
# -*- coding: utf-8 -*-
###################################
#                                 #
#       Plot Ermoy Data           #
#       by Xavier Robert          #
#           Sept 2026             #
#                                 #
###################################

import numpy as np
import pandas as pd
from pandas.plotting import autocorrelation_plot
#from pandas import Series
import matplotlib.pyplot as plt
#import matplotlib.dates as mdates
#from matplotlib.dates import DateFormatter
#from statsmodels.graphics.tsaplots import plot_pacf
import scipy.io as spio
import datetime

# Altitude de l'Ermoygraphe (m)
Alti = 790.0
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
# Remove unused columns
Ermoydf = Ermoydf.drop(['year', 'month', 'day', 'hour', 'minute', 'second', 'NaN'], axis = 1)
Ermoydf['seuil'] = seuil
Ermoydf['seuilAlt'] = seuil + Alti
Ermoydf['AltiE'] = Ermoydf['height'] + Alti

# Remove the year 2001:
Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64) > 2001]

# Set Datetime as index
Ermoydf = Ermoydf.set_index('Datetime')
# Calcul les vitesses de montée et de descente de l'eau en m/h pour chaque pas de temps de la base de données
Ermoydf['time_diff'] = Ermoydf.index.to_series().diff().dt.total_seconds()/60/60
Ermoydf['rate/h'] = Ermoydf['height'].diff() / Ermoydf['time_diff']
# set the index as a column
Ermoydf = Ermoydf.reset_index()

###############################################
# Print the height of the water
print("\tPlot des hauteurs d'eau par année...")
fig1, ax1 = plt.subplots(6, 1, figsize=(18, 10))

for i in range (1, len(annee)):
    print('\t\tSous-graphique %s/%s' %(str(i), str(len(annee)-1)))
    ax1[i-1].plot(Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['Datetime'], 
        Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['height'], 
        label = "Altitude de l'eau (" + str(annee[i]) + ")")
        #label = "Altitude de l'eau (m)")
    # Ajout de l'indication du seuil d'ennoiement
    ax1[i-1].plot(Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['Datetime'], 
        Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['seuil'], 
        color ='r', alpha = 0.5, label = 'seuil = +%s m' %(str(seuil)))
    # Ajout des hauteurs qui permmettent de passer (vert) ou non (bleu)
    ax1[i-1].fill_between(x = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['Datetime'],
                    y1 = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['height'],
                    y2 = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['seuil'],
                    where = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['height'] > float((seuil)),
                    color = 'b', alpha = 0.05, label = "siphons fermés")
    ax1[i-1].fill_between(x = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['Datetime'],
                        y1 = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['height'],
                        y2 = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['seuil'],
                        where = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['height'] < float((seuil)),
                        color = 'g', alpha = 0.1, label = "siphons ouverts")
    ax1[i-1].set_xlim(datetime.datetime(annee[i], 1, 1), datetime.datetime(annee[i], 12, 31))
    ax1[i-1].legend(loc = 'best')

# Calculate global min and max for y-axis (sales)  
y_min = Ermoydf['height'].min()  # Minimum sales value  
y_max = Ermoydf['height'].max()  # Maximum sales value
# Add a small buffer to y-limits for readability  
y_buffer = (y_max - y_min) * 0.05  # 5% buffer  
y_min -= y_buffer  
y_max += y_buffer
# Apply uniform y-limits to all subplots  
for ax in ax1:  
    ax.set_ylim(y_min, y_max)  # Same y-scale for all
    ax.set_xlabel(" ", fontsize=10)  # X-label for all  
    ax.grid(True, alpha = 0.5)
fig1.autofmt_xdate()
# common axis labels
fig1.supxlabel('Date')
fig1.supylabel('Water height (m)')
#plt.legend(loc = 'best')

plt.tight_layout()
#plt.show()
fig1.savefig('Graphs/Ermoygraphe_Hauteur _Eau.pdf')



# load the Meteo mat files
rawmat = spio.loadmat('RawData.mat')
meteo = rawmat['RawData']
### Structure :
# Il y a 6 colonnes
#	colonne 0 = Année
#	colonne 1 = mois
#   colonne 2 = jour
#	colonne 3 = heure
#	colonne 4 = 
# 	colonne 5 = 

# Faux, il y a 16 colonnes :
#Année : array([[2003]], dtype=uint16),     ARRAY 2 0
#Mois : array([[1]], dtype=uint8),          ARRAY 2 1
#Jour : array([[1]], dtype=uint8),          ARRAY 2 2 
#Heure : array([[22]], dtype=uint8),        ARRAY 2 3
#Heure : array(['22 h'], dtype='<U4'),      ARRAY 1 4

#?? : array([], dtype='<U1'),      ARRAY 1  5
#?? : array(['  '], dtype='<U2'),       ARRAY 1 6
# ?? : array([], dtype='<U1'),      ARRAY 1

#Temperature : array(['2.3 °C'], dtype='<U6'),       ARRAY 1
#Humidity : array(['100% '], dtype='<U5'),      ARRAY 1

######?? : array(['2.3 '], dtype='<U4'),       ARRAY 1

#Temperature : array(['1.5 °C'], dtype='<U6'),      ARRAY 1

######?? : array([], shape=(1, 0), dtype=float64),      ARRAY 1

#VitesseVent : array(['4 km/h '], dtype='<U7'),       ARRAY 1

######?? : array([' '], dtype='<U1'),      ARRAY 1

#Precipitations : array([' 4.0 mm (sur 3h)'], dtype='<U16')]      ARRAY 1

#### Regarder PDD : positive degre day

#MeteoData = np.array((meteo.shape[0], 10))
#Y=[]
#M=[]
#D=[]
#H=[]
timerec = []

Temp1 = []
Hum = []
Temp2 = []
Temp3 = []
VitesseVent = []
Precip = []


for i in range (0, meteo.shape[0]):
    print(i, "/", meteo.shape[0])
    # Faire directement un Datetime object
    timerec.append(datetime.datetime(meteo[i][0][0][0], meteo[i][1][0][0], meteo[i][2][0][0], meteo[i][3][0][0]))
    Temp1.append(float(meteo[i][8][0].split()[0]))
    if meteo[i][9][0] != ' ':
        Hum.append(float(meteo[i][9][0][:-1]))
    else:
        Hum.append(np.nan)
    Temp2.append(float(meteo[i][10][0].split()[0]))
    Temp3.append(float(meteo[i][11][0].split()[0]))
    #VitesseVent.append(meteo[i][13][0])
    if len(meteo[i][15][0].split()) > 1 and 'img' not in meteo[i][15][0]:
        Precip.append(float(meteo[i][15][0].split()[0]))
    elif 'img' in meteo[i][15][0]:
        Precip.append(np.nan)
    else:
        Precip.append(np.nan)

    
    
    #for j in [0,1,2,3]:
    #    MeteoData[i][j] = meteo[i][j][0][0]
    #for j in range [8,9,10,11,13,15]:
    #    MeteoData[i][j] = meteo[i][j][0]

# Create the meteo pandas dataframe
meteodf = pd.DataFrame(list(zip(pd.to_datetime(timerec, errors = 'coerce'), Temp1, Hum, Temp2, Temp3, Precip)),
                        columns=["Date", "Temperature 1", "Humidity", "Temperature 2", "Temperature 3", "Precipitations"])

## move np array to pandas
#meteodf = pd.DataFrame(meteo, columns = ['year', 'month', 'day', 'hour', 'hour_str', 
#                                        'minute??', 'second??', 'NaN ?', 
#                                        'Temperature', 'Humidity', 
#                                        'Tmax', 'Tmin',
#                                        'NaN ??', 'Wind', 'NaN ???', 'Precipitations'])

## change type of the first 6 columns to int
#for item in ['year', 'month', 'day', 'hour']:
#    ### RERRROR car le type de chaque cell est une imbrication de np.array --> Il faut supprimer cette imbrication
#    meteodf[item] = pd.to_numeric(meteodf[item], errors = 'coerce')
#    #meteodf = meteodf.dropna(subset = [item])
#    #if item not in ['hour_str', 'minute??', 'second??', 'NaN ?', 'Temperature', 'Humidity', 'Tmax', 'Tmin', 'NaN ??', 'Wind', 'NaN ???', 'Precipitations'] :
#    #    meteodf[item] = meteodf[item].astype(int)
#    #    meteodf[item] = meteodf[item].astype(str)
#meteodf['Datetime'] = pd.to_datetime(str(meteodf['year']) + '-' + str(meteodf['month']) + '-' + str(meteodf['day']) + ' ' + str(meteodf['hour']) + ':00:00',
#                                errors = 'coerce')


# Set Datetime as index
meteodf = meteodf.set_index('Date')
# set the index as a column
meteodf = meteodf.reset_index()



########################
# Plot avec les données météoFrance
station_ID = 74258002 # Samoens

meteoF = pd.read_csv('H_74_2000-2009.csv', sep = ';')
meteoF = meteoF[meteoF['NUM_POSTE'] == station_ID].reset_index()

meteoSamoens = meteoF[['NUM_POSTE', 'NOM_USUEL', 'LAT', 'LON', 'ALTI', 'AAAAMMJJHH', 'T', 'DG', 'NEIGETOT']]

meteoSamoens['Date'] = pd.to_datetime(meteoSamoens['AAAAMMJJHH'], format = '%Y%m%d%H')

fig1, ax1 = plt.subplots(6, 1, figsize=(18, 10))

for i in range (1, len(annee)):
    Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]].plot(x = 'Datetime', y = 'height', 
                                                                                   ax = ax1[i-1],
                                                                                   label = "Water height (" + str(annee[i]) + ")")
    meteoSamoens[meteoSamoens['Date'].dt.strftime("%Y").astype(np.int64)==annee[i]].plot(x = 'Date', y = 'T', ax = ax1[i-1],
                                                                                            color = 'r', label = 'Temp. ' + str(annee[i]) + ' (°C)')
    ax1[i-1].set_xlim(datetime.datetime(annee[i], 1, 1), datetime.datetime(annee[i], 12, 31))
    ax1[i-1].hlines(y = seuil, xmin = datetime.datetime(annee[i], 1, 1), xmax = datetime.datetime(annee[i], 12, 31),
                    linestyles='solid', color ='r', alpha = 0.5, label = 'seuil =%s' %(str(seuil)))
    ax1[i-1].fill_between(x = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['Datetime'],
                            y1 = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['height'],
                            y2 = np.ones(Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['Datetime'].shape[0]) * seuil,
                            where = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==annee[i]]['height'] > seuil,
                            color = 'b', alpha = 0.05)

# Calculate global min and max for y-axis (sales)  
y_min = Ermoydf['height'].min()  # Minimum sales value  
y_max = Ermoydf['height'].max()  # Maximum sales value
# Add a small buffer to y-limits for readability  
y_buffer = (y_max - y_min) * 0.05  # 5% buffer  
y_min -= y_buffer  
y_max += y_buffer
# Apply uniform y-limits to all subplots  
for ax in ax1:  
    ax.set_ylim(y_min, y_max)  # Same y-scale for all
    ax.set_xlabel(" ", fontsize=10)  # X-label for all  
    ax.grid(True, alpha = 0.5)
fig1.autofmt_xdate()
# common axis labels
fig1.supxlabel('Date')
fig1.supylabel('Water height (m)')

plt.tight_layout()
plt.show()
fig1.savefig('Graphs/Ermoygraphe_Hauteur_Eau+T.pdf')



###############################################################################
# Plote uniquement l'année 2006 qui est la plus complète et représentatitve pour utiliser sur la coupe développée :
fig, ax = plt.subplots(figsize = (18, 6))
# Ajout des données d'Altitude de l'eau
ax.plot(Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==2006]['Datetime'], 
        Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==2006]['AltiE'], 
        label = "Altitude de l'eau (" + str(2006) + ")")
# Ajout de l'indication du seuil d'ennoiement
ax.plot(Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==2006]['Datetime'], 
        Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==2006]['seuilAlt'], 
        color ='r', alpha = 0.5, label = 'seuil = %s m' %(str(seuil+Alti)))
# Ajout des hauteurs qui permmettent de passer (vert) ou non (bleu)
ax.fill_between(x = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==2006]['Datetime'],
                    y1 = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==2006]['AltiE'],
                    y2 = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==2006]['seuilAlt'],
                    where = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==2006]['AltiE'] > float((seuil+Alti)),
                    color = 'b', alpha = 0.05, label = "siphons fermés")
ax.fill_between(x = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==2006]['Datetime'],
                        y1 = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==2006]['AltiE'],
                        y2 = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==2006]['seuilAlt'],
                        where = Ermoydf[Ermoydf['Datetime'].dt.strftime("%Y").astype(np.int64)==2006]['AltiE'] < float((seuil+Alti)),
                        color = 'g', alpha = 0.1, label = "siphons ouverts")

# Ajout des données de température :
#meteoSamoens[meteoSamoens['Date'].dt.strftime("%Y").astype(np.int64)==2006].plot(x = 'Date', y = 'T', ax = ax,
#                                                                                        color = 'r', label = 'Temp. ' + str(2006) + ' (°C)')

ax.set_xlim(datetime.datetime(2006, 1, 1), datetime.datetime(2006, 12, 31))
# Calculate global min and max for y-axis (sales)  
y_min = Ermoydf['AltiE'].min()  # Minimum sales value  
y_max = Ermoydf['AltiE'].max()  # Maximum sales value
# Add a small buffer to y-limits for readability  
y_buffer = (y_max - y_min) * 0.05  # 5% buffer  
y_min -= y_buffer  
y_max += y_buffer
# Apply uniform y-limits to all subplots  
ax.set_ylim(y_min, y_max)  # Same y-scale for all
ax.set_xlabel("Date", fontsize=10)  # X-label for all  
ax.set_ylabel("Altitude du niveau d'eau (m)", fontsize=10)
ax.grid(True, alpha = 0.5)
plt.legend(loc = 'best')

plt.tight_layout()
#plt.show()
fig1.savefig('Graphs/Ermoygraphe_Altitude_Eau.pdf')
###############################################################################




# Plot autocorrelogram --> lags in days
#   https://stackoverflow.com/questions/643699/how-can-i-use-numpy-correlate-to-do-autocorrelation
# or with pandas ? https://blog.finxter.com/pandas-plotting-autocorrelation/
# Plot le diagramme d'autocorrelation.
# Questions : faut-il reconstruire une série temporelle avec un interval = minute / heure ?
print ("\tPlot le graphique d'autocorrelation...")
plt.figure()
ax = autocorrelation_plot(Ermoydf.set_index('Datetime')['height'])
ax.set_xlim([0, 7400])
ax.set_ylim([0,1])
# Save the plot
plt.savefig('Graphs/Ermoy_autocorrel.pdf')



# Plot les vitesses de décrues (vitesses négatives) en fonction de la hauteur d'eau dans le réseau
print ("\tPlot les vitesses de décrue...")
Ermoydf['time_diff_h'] = Ermoydf['Datetime'].diff().dt.total_seconds()/60/60
plt.figure()
ax = Ermoydf[Ermoydf[Ermoydf.time_diff_h < 2] & Ermoydf['height'] > 2].plot('height', 'rate/h', 'scatter')
ax.set_ylim(0,-4)
#plt.show()
# Save the plot
plt.savefig('Graphs/Ermoy_decrue.pdf')



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


