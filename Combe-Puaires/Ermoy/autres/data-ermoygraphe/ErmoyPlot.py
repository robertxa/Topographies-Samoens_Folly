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

from pandas import Series
from matplotlib import pyplot
from statsmodels.graphics.tsaplots import plot_pacf
import scipy.io as spio

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


ermoydata = spio.loadmat('DonneeErmoy-steph/Data.mat')
ermoyD = ermoydata['Data']
# Il y a 8 colonnes. 
#	Les colonnes 0-6 correspondent aux dates
#	La colonne 7 à la hauteur d'eau




series = Series.from_csv('daily-minimum-temperatures.csv', header=0)
plot_pacf(series, lags=50)
pyplot.show()




