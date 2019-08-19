Template LaTeX pour mettre en forme la base de données spéléologiques de Samoëns
================================================================================

Ce template LaTeX permet d'exporter la base de données spéléologiques des Systèmes du Folly à Samoëns au format pdf, en imprimant une fiche par cavité explorée.


Installation
-------

Il suffit de compiler l'ensemble du projet LaTeX (BD_Samoens.tex) avec pdflatex : 

.. code-block:: bash

	pdflatex BD_Samoens.tex
	
	pdflatex BD_Samoens.tex
	
Les fichiers classe et style sont respectivement les fichiers ``BD_gix.cls`` et ``stylexrobert.sty`.
Ce dernier est à modifier dépendemment du système d'exploitation utilisé :
	+ Pour un Mac, utiliser la ligne ``\usepackage[applemac]{inputenc}`` et commenter (``%`` en début de ligne) la ligne ``\usepackage[T1]{fontenc}``.
	+ Pour un PC, utiliser la ligne ``\usepackage[T1]{fontenc}`` et commenter (``%`` en début de ligne) la ligne ``\usepackage[applemac]{inputenc}``.

Le dernier point important est que les figures doivent être en .jpg ou .png et non en .gif.

Usage
-----

Au niveau structure, il faut respecter l'architecture :
	+ Un fichier de style .sty qui permet de gérer le style des différentes pages, et de chaque fiche cavité
	+ Un fichier de classe qui définit une classe de document
	+ Un fichier .tex maître qui définit la structure globale de l’inventaire pdf, et qui appelle les fichiers .tex de chaque chapitre (CP, JB, AV, A21).
	+ Chaque fichier .tex de chapitre va appeler un fichier .tex pour chaque fiche de trou (i.e. CP1.tex, CP2.tex,...)

Chaque fichier .tex est commenté.
			
Outputs
-------

Fichier pdf contenant l'ensemble des cavités explorées (et de la base de données) par zone et sous forme de fiches cavités.


Licence
-------

This package is licenced with `CCby-nc-sa <https://creativecommons.org/licenses/by-nc-sa/3.0/>`_
