% =========================================================================
% CLASSE LaTeX POUR LA REDACTION DE L'INVENTAIRE SPELEOLOGIQUE DE SAMOENS
% 
% par Xavier Robert
%
% NŽcessite au moins un fichier de style

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{these_gix}[2017/12/10 Classe pour la BD Samoens]

%% Chargement de la classe book, avec transfert d'options
\PassOptionsToClass{a4paper}{book}	% Utiliser du papier A4
\PassOptionsToClass{9pt}{book}	% Taille de la police
\PassOptionsToClass{twoside}{book}	% On veut du recto-verso
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}
\DeclareOption*{}
\ProcessOptions
\LoadClass{book}

% ============================================================================
% CHARGEMENT DE LA FEUILLE DE STYLE CHOISIE
	\RequirePackage{stylexrobert}
