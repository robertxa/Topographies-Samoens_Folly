%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Trac� des donn�es climatiques et de la hauteur d'eau dans l'Ermoy %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc ;
clear all;
close all

%% Ouverture du fichier des hauteurs d'eau dans l'Ermoy

load Data;
Date = datenum(Data(:,1:6));
Hauteur = Data(:,8);


%% Ouverture du fichier des donn�es m�t�os

%[num, txt]= xlsread('DonneeClimato.xls');
load RawData
%%
Annee = [RawData{:,1}]';
Mois = [RawData{:,2}]';
Jour = [RawData{:,3}]';
Heure = [RawData{:,4}]';

DateDonneeClimato = datenum(Annee, Mois, Jour, Heure, 0, 0);

NbrePoints = numel(DateDonneeClimato);
for NumPoint=1:NbrePoints
    Temperature(NumPoint) = sscanf(RawData{NumPoint,9} , '%e');

    pluie =  sscanf(RawData{NumPoint,16}, '%e');
    if isempty(pluie)
        Precipitation(NumPoint)=0;
        cumul3h(NumPoint)=0;
    else
        Precipitation(NumPoint)=pluie ;
        if isempty(findstr(RawData{NbrePoints,16}, '3h'))==0
            cumul3h(NumPoint)=1;
        else
            cumul3h(NumPoint)=0;
        end
    end
end


% Classement des donn�es par ordre chronologique
[DateDonneeClimato,IX] = sort(DateDonneeClimato);
Temperature=Temperature(IX);
Precipitation = Precipitation(IX);
cumul3h = cumul3h(IX);

% Correction des cumuls de precipitation toutes les 3 heures
for NumPoint = 3:NbrePoints 
    if cumul3h(NumPoint)==1
        if DateDonneeClimato(NumPoint)==Date(NumPoint-1)+ 1/24;
        Precipitation(NumPoint) = Precipitation(NumPoint) - Precipitation(NumPoint-1);
        end
        if DateDonneeClimato(NumPoint)==Date(NumPoint-2)+ 2/24;
        Precipitation(NumPoint) = Precipitation(NumPoint) - Precipitation(NumPoint-2);
        end     
    end
end

%% Graphiques
close all
figure(1)
hold on
plot(Date, Hauteur, 'g-');
plot(DateDonneeClimato, Temperature, 'r-');
plot(DateDonneeClimato, Precipitation, 'b-');
xlim([DateDonneeClimato(1), DateDonneeClimato(NbrePoints)])
ylim([-20 60]);
GraduationsPrincipales = datenum(2005, 1:12, 1, 0, 0, 0);
set(gca, 'XTick',GraduationsPrincipales, 'XTicklabel',datestr(GraduationsPrincipales,19) )
grid on
ylabel('Hauteur d''eau [m] - Temp�rature [�C] - Precipitation [mm]')
legend({'Hauteur d''eau','Temp�rature ', 'Pr�cipitation'})



%% A Développer %%%%
%

%% Traiter les données :
%	1) Calculer les vitesses (dérivée de la courbe initiale de l'Ermoygraphe) 
%       --> Donne les vitesses de crue et de d�crue en fonction de la hauteur d'eau 
%       --> Donne des infos sur les potentielles sorties à différentes altitudes / tailles des volumes noyés ?
%           Probablement que nous pouvons faire la simplification débit entrant proportionnel � pr�cipitations,
%           du moins en été. A réfléchir avec les différents graphiques
%	2) Calculer les points d'inflexions (Dérivée seconde de la courbe initiale de l'Ermoygraphe) 
%       --> Donne les points caractéristiques ?
%	3) Faire une transformée de Fourier de la courbe initiale de l'Ermoygraphe 
%       --> Donne les fréquences propres caractéristiques du r�seau.
%	4) Faire une transformée de Fourier sur les précipitations et les Températures 
%       --> A comparer avec le point 3)  Mets en évidence les relations entre 

