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
from __future__ import division
from __future__ import absolute_import
from __future__ import print_function

import pandas as pd
from pandas import Series
from matplotlib import pyplot
from statsmodels.graphics.tsaplots import plot_pacf
import scipy.io as spio
import datetime

# load the mat files
rawmat = spio.loadmat('RawData.mat')
meteo = rawmat['RawData']
# Il y a 6 colonnes
#	colonne 0 = Année
#	colonne 1 = mois
#   colonne 2 = jour
#	colonne 3 = heure
#	colonne 4 = 
# 	colonne 5 = 

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
df = pd.DataFrame(ermoyD, columns = ['year', 'month', 'day', 'hour', 'minute', 'second', 'NaN', 'height'])
# change type of the first 6 columns to int
for item in ['year', 'month', 'day', 'hour', 'minute', 'second']:
    df[item] = pd.to_numeric(df[item], errors = 'coerce')
    df = df.dropna(subset = [item])
    if item != 'height':
        df[item] = df[item].astype(int)
        df[item] = df[item].astype(str)
df['Datetime'] = pd.to_datetime(df['year'] + '-' + df['month'] + '-' + df['day'] + ' ' + df['hour'] + ':' + df['minute'] + ':' + df['second'],
                                errors = 'coerce')
# Set Datetime as index
df = df.set_index('Datetime')
# Remove unused columns
df = df.drop(['year', 'month', 'day', 'hour', 'minute', 'second', 'NaN'], axis = 1)


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



