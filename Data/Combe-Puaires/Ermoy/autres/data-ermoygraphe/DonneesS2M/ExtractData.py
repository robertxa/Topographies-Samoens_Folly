######!/usr/bin/env python
# -*- coding: utf-8 -*-

######
#   Scipt pour extraire de la base S2M les données neige et météo pour un massif donné et une station.
#   Les données doivent être téléchargées à partir de la base de données S2M : 
######


import xarray as xr
import numpy as np
import pandas as pd
import datetime
import os
import copy

# set the station to extract
station_ID = 74258002  # Samoens village
#station_ID = 74258400;  # Samoens 1600
# set the massif to extract
massif_number = 1   # Haute savoie, chablais
# set the begining of the timing
init_year = 2002
# set the end of the timing
end_year = 2007

# Altitude moyenne à considérer (en m) ; station elevation or every 300 m
Alt_extract = 2100
# Orientation moyenne de la zone à extraire (every 45°)
Orientation = 315.   # NW
# Pente à considérer : 0 = flat, or 20, or 40 = all slopes
Slope = 40

ro_rain = 1000                                                                # rain density [kg/m3]

################################################################
# transform the time boundaries into datetime objects
timelimits = (datetime.datetime(init_year, 1, 1), datetime.datetime(end_year, 12, 31))

################################################################
# Begin with the Massif Meteo files
print('1- Working on all_slopes/METEO files')
# open the file
files = os.listdir('alp_allslopes/meteo/')

# initialize the counter
i = 0
for file in files:
    print('\tWorking on file nb %s/%s' %(str(i+1), str(len(files))))
    # Open the file
    ncdata = xr.open_dataset('alp_allslopes/meteo/' + file)

    # import the data from the file
    time = ncdata.coords['time'].to_dataframe()['time'].values
    var_massif = ncdata.variables['massif_number'].data
    var_zs = ncdata.variables['ZS'].data                                      # Altitudes [m]
    var_slope = ncdata.variables['slope'].data                                # Pentes [°] : 0 = flat, or 20, or 40 = all slpes
    var_aspect = ncdata.variables['aspect'].data                              # Orientation [°] ; every 45°
    
    Tair = ncdata.variables['Tair'].data - 273.15                             # Température [°C]
    Rainf = ncdata.variables['Rainf'].data *(1/ro_rain)*1000*(60*60)          # Rainfall Rate [kg/m2/s] to [mm/h]
    Snowf = ncdata.variables['Snowf'].data  *(1/ro_rain)*1000*(60*60)         # Snowfall Rate [kg/m2/s] to [mm/h] WATER EQUIVILANT??????
    #IsoZero = ncdata.variables['isoZeroAltitude'].data                        # Iso 0°C Altitude [m] ; Comprendre la structure de cette donnée ! N'a pas la même taille
    #RainSnowLimit = ncdata.variables['rainSnowLimit'].data                    # Rain Snow Limit [m] ; Comprendre la structure de cette donnée ! N'a pas la même taille
    
    # Extract the right data form the right massif and the right slopes/orientation/altitude
    selection = np.squeeze(np.where((var_zs == Alt_extract)&(var_massif == massif_number)&(var_aspect == Orientation)&(var_slope == Slope)), axis=0)

    # build the Pandas dataframe and Concatenate with the previous dates
    Massifdftemp = pd.DataFrame(time, columns = ['Time'])
    Massifdftemp['Tair'] = Tair[:, selection]
    Massifdftemp['Rainf'] = Rainf[:, selection]
    Massifdftemp['Snowf'] = Snowf[:, selection]
    #Massifdf['isoZeroAltitude'] = IsoZero[:, selection]        # Comprendre la structure de cette donnée ! N'a pas la même taille
    #Massifdf['rainSnowLimit'] = RainSnowLimit[:, selection]    # Comprendre la structure de cette donnée ! N'a pas la même taille

    if i == 0:
        MassifdfMeteo = copy.copy(Massifdftemp)
    else:
        MassifdfMeteo = pd.merge(MassifdfMeteo, Massifdftemp, how = 'outer')
    
    # Increment the counter
    i += 1
    # clean memory
    ncdata.close()

# save the pandas dataframe as .csv file for exchanges with other programs
print('\tSaving...')
MassifdfMeteo.to_csv('Out/MassifdfMeteo.csv')
#MassifdfMeteo.close()


################################################################
# Continue with the Massif snow files
print('2- Working on all_slopes/PRO files')
# open the file
files = os.listdir('alp_allslopes/pro/')
i = 0
for file in files:
    print('\tWorking on file nb %s/%s' %(str(i+1), str(len(files))))
    # Open the file
    ncdata = xr.open_dataset('alp_allslopes/pro/' + file)

    # import the data from the file
    time = ncdata.coords['time'].to_dataframe()['time'].values
    var_massif = ncdata.variables['massif_num'].data
    var_zs = ncdata.variables['ZS'].data                                      # Altitudes [m]
    var_slope = ncdata.variables['slope'].data                                # Pentes [°] : 0 = flat, or 20, or 40 = all slpes
    var_aspect = ncdata.variables['aspect'].data                              # Orientation [°] ; every 45°
    
    TotSnowDepth = ncdata.variables['DSN_T_ISBA'].data                        # Total Snow Depth [m]
    WetSnowThick = ncdata.variables['WET_TH_ISBA'].data                       # Wet Snow Thickness [m]
    RefrozSnowThick = ncdata.variables['REFRZTH_ISBA'].data                   # Refrozen snow thickness [m]
    SnowMelt = ncdata.variables['SNOMLT_ISBA'].data                           # Snow melting flux [kg m-2 s-1]

    # Extract the right data form the right massif and the right slopes/orientation/altitude
    selection = np.squeeze(np.where((var_zs == Alt_extract)&(var_massif == massif_number)&(var_aspect == Orientation)&(var_slope == Slope)), axis=0)

    # build the Pandas dataframe and Concatenate with the previous dates
    # build the Pandas dataframe and Concatenate with the previous dates
    Massifdftemp = pd.DataFrame(time, columns = ['Time'])
    Massifdftemp['DSN_T_ISBA'] = TotSnowDepth[:, selection]
    Massifdftemp['WET_TH_ISBA'] = WetSnowThick[:, selection]
    Massifdftemp['REFRZTH_ISBA'] = RefrozSnowThick[:, selection]
    Massifdftemp['SNOMLT_ISBA'] = SnowMelt[:, selection]

    if i == 0:
        MassifdfSnow = copy.copy(Massifdftemp)
    else:
        MassifdfSnow = pd.merge(MassifdfSnow, Massifdftemp, how = 'outer')

    # Increment the counter
    i += 1
    # clean memory
    ncdata.close()

# save the pandas dataframe as .csv file for exchanges with other programs
print('\tSaving...')
MassifdfSnow.to_csv('Out/MassifdfSnow.csv')
#MassifdfSnow.close()



################################################################
# Finish with the station meteo files
print('3- Working on postes/METEO files')
# open the file
files = os.listdir('postes/meteo/')
i = 0
for file in files:
    print('\tWorking on file nb %s/%s' %(str(i+1), str(len(files))))
    # Open the file
    ncdata = xr.open_dataset('postes/meteo/' + file)

    # import the data from the file
    time = ncdata.coords['time'].to_dataframe()['time'].values
    var_station = ncdata.variables['station'].data
    var_zs = ncdata.variables['ZS'].data                                      # Altitudes [m]
    var_slope = ncdata.variables['slope'].data                                # Pentes [°] : 0 = flat, or 20, or 40 = all slpes
    var_aspect = ncdata.variables['aspect'].data                              # Orientation [°] ; every 45°

    Tair = ncdata.variables['Tair'].data - 273.15                             # Température [°C]
    Rainf = ncdata.variables['Rainf'].data *(1/ro_rain)*1000*(60*60)          # Rainfall Rate [kg/m2/s] to [mm/h]
    Snowf = ncdata.variables['Snowf'].data  *(1/ro_rain)*1000*(60*60)         # Snowfall Rate [kg/m2/s] to [mm/h] WATER EQUIVILANT??????

    # Extrat the right data form the right massif and the right slopes/orientation/altitude
    #selection = np.squeeze(np.where((var_zs == Alt_extract)&(var_station == station_ID)&(var_aspect == Orientation)&(var_slope == Slope)), axis=0)
    selection = np.squeeze(np.where(var_station == station_ID), axis=0)

    # build the Pandas dataframe and Concatenate with the previous dates
    # build the Pandas dataframe and Concatenate with the previous dates
    Stationdftemp = pd.DataFrame(time, columns = ['Time'])
    Stationdftemp['Tair'] = Tair[:, selection]
    Stationdftemp['Rainf'] = Rainf[:, selection]
    Stationdftemp['Snowf'] = Snowf[:, selection]

    if i == 0:
        StationdfMeteo = copy.copy(Stationdftemp)
    else:
        StationdfMeteo = pd.merge(StationdfMeteo, Stationdftemp, how = 'outer')

    # Increment the counter
    i += 1
    # clean memory
    ncdata.close()
# save the pandas dataframe as .csv file for exchanges with other programs
print('\tSaving...')
StationdfMeteo.to_csv('Out/StationdfMeteo.csv')




################################################################
# Continue with the station snow files
print('4- Working on postes/PRO files')
# open the file
files = os.listdir('postes/pro/')
i = 0
for file in files:
    print('\tWorking on file nb %s/%s' %(str(i+1), str(len(files))))
    # Open the file
    ncdata = xr.open_dataset('postes/pro/' + file)

    # import the data from the file
    time = ncdata.coords['time'].to_dataframe()['time'].values
    var_station = ncdata.variables['station'].data
    var_zs = ncdata.variables['ZS'].data                                      # Altitudes [m]
    var_slope = ncdata.variables['slope'].data                                # Pentes [°] : 0 = flat, or 20, or 40 = all slpes
    var_aspect = ncdata.variables['aspect'].data                              # Orientation [°] ; every 45°
    
    TotSnowDepth = ncdata.variables['DSN_T_ISBA'].data                        # Total Snow Depth [m]
    WetSnowThick = ncdata.variables['WET_TH_ISBA'].data                       # Wet Snow Thickness [m]
    RefrozSnowThick = ncdata.variables['REFRZTH_ISBA'].data                   # Refrozen snow thickness [m]
    SnowMelt = ncdata.variables['SNOMLT_ISBA'].data                           # Snow melting flux [kg m-2 s-1]

    # Extract the right data form the right massif and the right slopes/orientation/altitude
    #selection = np.squeeze(np.where((var_zs == Alt_extract)&(var_massif == massif_number)&(var_aspect == Orientation)&(var_slope == Slope)), axis=0)
    selection = np.squeeze(np.where(var_station == station_ID), axis=0)

    # build the Pandas dataframe and Concatenate with the previous dates
    # build the Pandas dataframe and Concatenate with the previous dates
    Stationdftemp = pd.DataFrame(time, columns = ['Time'])
    Stationdftemp['DSN_T_ISBA'] = TotSnowDepth[:, selection]
    Stationdftemp['WET_TH_ISBA'] = WetSnowThick[:, selection]
    Stationdftemp['REFRZTH_ISBA'] = RefrozSnowThick[:, selection]
    Stationdftemp['SNOMLT_ISBA'] = SnowMelt[:, selection]

    if i == 0:
        StationdfSnow = copy.copy(Stationdftemp)
    else:
        StationdfSnow = pd.merge(StationdfSnow, Stationdftemp, how = 'outer')

    # Increment the counter
    i += 1
    # clean memory
    ncdata.close()
# save the pandas dataframe as .csv file for exchanges with other programs
print('\tSaving...')
StationdfSnow.to_csv('Out/StationdfSnow.csv')


################################################################




################################################################
## Hydrologie
## Station de Saint Joire (V015501002) ; Attention, ce n'est pas sur le Giffre, mais faut tester pour voir si on arrive à avoir des tendances utiles pour les prédictions

## lire le CSV
#Hydrodb = pd.read_csv('Hydro_StJoire-2001_2007.csv', sep = ',', header = 0, usecols = ["Date (TU)","Valeur (en m)"])

## Transforme la première colonne en format datetime
##dt.datetime.fromisoformat('2002-01-01T06:01:00.000Z'[:-1] + '+00:00') # En a-t-on besoin ?





########### Donnees MeteoFrance
#meteoF = pd.read_csv('H_74_2000-2009.csv', sep = ';')
#meteoF = meteoF[meteoF['NUM_POSTE'] == station_ID].reset_index()

#meteoSamoens = meteoF[['NUM_POSTE', 'NOM_USUEL', 'LAT', 'LON', 'ALTI', 'AAAAMMJJHH', 'T', 'DG', 'NEIGETOT']]

#meteoSamoens['Date'] = pd.to_datetime(meteoSamoens['AAAAMMJJHH'], format = '%Y%m%d%H')


