%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% RÈcupÈration des donnÈes mÈtÈos %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% AdaptÈ au site http://www.meteociel.fr au 06/01/2011 %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% StÈphane Lips - G.S. Vulcain %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Première Ètape : téléchargement des fichiers sur http://www.meteociel.fr
%% grâce au logiciel Kapere
% 1- Telechargement du logiciel Kapere (logiciel libre) : http://kapere.downloadaces.com/
% 2- Utiliser la fonction téléchargement par lots ("Outils/Divers/Telechargement par lot" ou "Crt+B")
% 3- Rentrer la caractéristique des URLs (à modifier en fonction de la station)
%   exemple d'URL :
%   http://www.meteociel.fr/temps-reel/obs_villes.php?code2=7469&jour2=5&mois2=0&annee2=2005&envoyer=OK
%   caractéristique :
%    texte: 'http://www.meteociel.fr/temps-reel/obs_villes.php?code2=7469&jour2='
%    suite numérique: 1 à 31
%    texte: '&mois2='
%    suite numérique: 0 à 11
%    texte: '&annee2='
%    suite numérique: 2003 à 2010
%    texte: '&envoyer=OK'
% 4- Cliquer sur ok
% 5- Sur la page "Télécharger avec Kapere"
%    choisir le nom du fichier
%    décocher "Exécuter en fin de téléchargement"
%    cocher "Utiliser les mÍmes paramètres"
%    cliquier sur ok



%% Deuxième étape : lancement du script Matlab
% Copier le present .m dans le dossier avec les fichiers php
% Note : si certains fichiers PHP sont différents des autres (absence de 
% Tableau par exemple), il se peut qu'il fasse planter le programme :
% Tapez 'FilesNames{NumFichier}' dans l'espace de commande aprés l'erreur pour obtenir le nom du fichier
% supprimer le ou renommer alors l'extension de ce fichier pour qu'il ne soit pas lu par Matlab.

clear all ; close all ; clc


%% Ouverture des fichiers et lectures des données

% Liste des fichiers
dirOutput = dir('*.php');
FilesNames =  {dirOutput.name}';
NbreFichiers = numel(FilesNames);

NumPoint = 0;
for NumFichier = 1: 2513;%NbreFichiers;
    % Ouverture du fichier
    NumFichier
    fid = fopen(FilesNames{NumFichier});
    
    %Scan de l'ensemble des lignes du fichier en question
    stop =0;
    NumLigne=0;
    while 1    
        tline = fgetl(fid); % lecture de la ligne

        if isempty(findstr(tline, 'Heure'))==0  % Trouve la première ligne du tableau contenant les données
            stop =1;
        end

        Ind = findstr(tline, ' <tr>');          % Trouve la position de la première ligne du tableau
        
        if (stop ==1)&isempty(Ind)==0;
            
            % Capture la date de l'enregistrement
            if NumLigne == 0;
                IndDate = findstr(tline, '<option selected value');
                Jour = sscanf(tline(IndDate(2)+23:IndDate(2)+24) , '%d');
                Mois = sscanf(tline(IndDate(3)+23:IndDate(3)+24) , '%d')+1;
                Annee = sscanf(tline(IndDate(4)+23:IndDate(4)+26) , '%d');
            end

            NumLigne=NumLigne+1;
            tline = tline(Ind:numel(tline));     % Supprime le début de la ligne
            
            % séparation des cellules, suppression des balises à l'intérieur des cellules
            IndDebut = findstr(tline, '<td');   % Trouve le début de chaque cellule
            Indfin = findstr(tline, '</td>');   % Trouve la fin de chaque cellule
            
            for i =1:numel(Indfin)
                data{i}=tline(IndDebut(i):Indfin(i)-1);
                remain = data{i};
                while true
                    [str, remain] = strtok(remain, '<>');
                    if isempty( findstr(str, 'td'))&isempty( findstr(str, 'div'))
                    	break;  
                    end
                end
                str = strrep(str, '&nbsp;', '');
                str = strrep(str, '&nbsp', '');
                str = strrep(str, 'aucune', '0');
                Tableau{NumLigne,i} = str;
            end


            % Assignation des valeurs aux variables
            Heure = sscanf(Tableau{NumLigne,1} , '%d');
            NumPoint = NumPoint+1;
            Date(NumPoint)  = datenum(Annee, Mois, Jour, Heure, 0, 0);
            Temperature(NumPoint) = sscanf(Tableau{NumLigne,5} , '%e');
            pluie =  sscanf(Tableau{NumLigne,12}, '%e');
            if isempty(pluie)
                Precipitation(NumPoint)=0;
                cumul3h(NumPoint)=0;
            else
                Precipitation(NumPoint)=pluie ;
                if isempty(findstr(Tableau{NumLigne,12}, '3h'))==0
                    cumul3h(NumPoint)=1;
                else
                    cumul3h(NumPoint)=0;
                end            
            end
            
            % Sauvegarde des données brutes            
            RawData{NumPoint,1}=Annee;
            RawData{NumPoint,2}=Mois;
            RawData{NumPoint,3}=Jour;
            RawData{NumPoint,4}=Heure;
            for i = [1:8 10:12]
            	RawData{NumPoint,4+i}=Tableau{NumLigne,i};
            end

        elseif (stop ==1)&isempty(Ind)==1;   % Trouve la fin du tableau et clot la boucle
            break
        end
    end
    fclose(fid);
end
NbrePoint = NumPoint;

% Classement des données par ordre chronologique
[Date,IX] = sort(Date);
Temperature=Temperature(IX);
Precipitation = Precipitation(IX);
cumul3h = cumul3h(IX);
Precipitationold = Precipitation;

% Correction des cumuls de precipitation toutes les 3 heures
for NumPoint = 3:NbrePoint 
    if cumul3h(NumPoint)==1
        if Date(NumPoint)==Date(NumPoint-1)+ 1/24;
        	Precipitation(NumPoint) = Precipitation(NumPoint) - Precipitation(NumPoint-1);
        end
        if Date(NumPoint)==Date(NumPoint-2)+ 2/24;
        	Precipitation(NumPoint) = Precipitation(NumPoint) - Precipitation(NumPoint-2);
        end     
    end
end

%% Graphiques
figure(1000)
subplot(2,1,1)
plot(Date, Temperature, 'r-')
datetick('x',19, 'keeplimits')

subplot(2,1,2)
plot(Date, Precipitation, 'b-')
datetick('x',19, 'keeplimits')

%% Sauvegarde des données brutes dans un fichier Excel
save('RawData','RawData')
%csvwrite('DonneeClimato.xls', RawData)
%xlswrite('DonneeClimato.xls', RawData)
