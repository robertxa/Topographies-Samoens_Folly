Base de données Topographiques des systèmes karstiques du massif du Folly (Samoëns, 74, France)
===============================================================================================

Overview
--------

Ce dépôt contient les données topographiques et les dessins associés des cavités du massif du Folly à Samoëns (74, France).
Cela concerne les systèmes du gouffre Jean-Bernard, du réseau de la Combe aux Puaires, des Avoudrues et du A21.
Elles ont été majoritairement produites par les spéléologues du club Vulcain de (Lyon, France) https://www.groupe-speleo-vulcain.com.
Ce dépôt est mis à jour à chaque fois qu'une nouvelle topographie est rajoutée à l'un des systèmes décrit dans cette base de données.

Si besoin, des templates pour Therion sont disponibles sur https://github.com/robertxa/Th-Config-Xav .

Un article sur cette base de données topographiques, publié dans l'Echo des Vulcain n°77, est accessible dans le dossier Docs/.

Description
-----------

Ce dépôt sauvegarde les données topographiques et de dessin. Ces fichiers sont pour les logiciels Visual Topo (données) et/ou Therion (data + dessins).

Uniquement les fichiers sources sont sauvegardés pour des raisons de taille ; j'ai aussi choisi de ne pas uploader ni les dessins dessinés à la main sur papier, ni les différents xvi issus de Therion :

	* les anciens fichiers .tro pour le logiciel Visual Topo
	
	* .thc, .th, .th2 et .thconfig pour le logiciel Therion
	
Cette base de données est hierarchisée en systèmes hydrologiques, puis par zone, puis par cavités, et enfin, pour les cavités importantes, par petits réseaux.
Pour obtenir les topographies en plan, coupe et/ou 3D de chaque élément, il faut compiler les différents fichiers Therion thconfig.
Pour obtenir les topographies en plan et/ou 3D de l'ensemble d'un système ou de la base de données, il faut compiler les fichiers Therion thconfig parents. Il n'est pas nécessaire d'avoir compilé chaque petite entité auparavant.

Aussi, cette base de données topographique est à la base de projets SIG, que ce soit pour la production de cartes propres, ou pour la mise en place d'une application portable sur appareils Android ou iOS. Pour générer ou mettre à jour les différents champs non produits directement par Therion, il faut lancer dans un Terminal le script shell Build-Samoens-SIG.sh. Il faut alors être un peu patient !
Ce script shell fait appel à des scripts Python, qui utilisent le module Fiona, Shapely et alive_progress qui sont à installer préalablement.

L'ensemble de ces topographies est publié et décrit dans les différents Echos des Vulcains, revue annuelle du club Vulcain disponible sur le site internet (https://www.groupe-speleo-vulcain.com/publications/echo-des-vulcains/). Les topographies compilées peuvent aussi être téléchargées sur les pages https://www.groupe-speleo-vulcain.com/explorations/explorations-a-samoens/topographies-du-synclinal-du-jean-bernard-samoens-france/ et https://www.groupe-speleo-vulcain.com/explorations/explorations-a-samoens/explorations-a-samoenstopographies-du-systeme-de-la-combe-aux-puaires/ .
Le scan des notes topographiques de terrain n'est pas inclus dans ce repository pour en limiter sa taille, mais tout est disponible sur demande.

Une convention a aussi été mise en place pour la gestion des points d'interrogation, avec la définition de différents champs :

	* le champ "Code" qui décrit le type de terminus. Il peut prendre les valeurs : 
	
		* A : il suffit d'y aller et de continuer, pas d'obstacles
		
		* D : Désobstruction nécessaire, 
		
		* E : Escalade nécessaire, 
		
		* P : Puits non descendu,
		
		* Q : non renseigné sur les topographies anciennes, c'est à voir/vérifier,
		
		* S : Siphon à plonger, 
		
		* T : Trémie à désobstruer
	
	* le champ "Cavite" qui donne le nom de la cavité en question,
	
	* le champ "Reseau" qui indique la partie de la cavité où se situe le point d'interrogation (pour pouvoir le retrouver plus rapidement sur les topographies),
	
	* le champ "CA" qui est rempli si présence de courant d'air, avec éventuellement des remarques/commentaires.

Licence
-------

L'ensemble de ces données est publié sous la licence libre Creative Commons Attribution-ShareAlike-NonCommercial (Attribution, partage à l'identique et non commerciale) :
	http://creativecommons.org/licenses/by-nc-sa/4.0/

Auteur de la base de données
----------------------------

Xavier Robert (xavier.robert@ird.fr)

How to cite
-----------

Robert, X., Base de données Topographiques des systèmes karstiques du massif du Folly (Samoëns, 74, France), https://github.com/robertxa/Topographies-Samoens_Folly , 2020. 

Contact
-------

Pour plus d'informations, contacter le club Vulcain (https://www.groupe-speleo-vulcain.com/contacts/)