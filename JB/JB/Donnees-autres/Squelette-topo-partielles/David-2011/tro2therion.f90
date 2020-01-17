       program tro2therion

!---------------------------------------------------------!
!                                                         !
!                    Tro to Therion                       !
!                                                         !
!           Code to transform the .tro files              !
!            Visual Topo into files that can              !
!                  be used by Therion                     !
!                                                         !
!              Written by Xavier Robert                   !
!          Montreal, Canada, Avril-july 2010              !
!                                                         !
!---------------------------------------------------------!

! README !
! French below !
! Le français est un peu plus loin !
!
! ENGLISH :
! This code is to transform the .tro file from Visualtopo (http://vtopo.free.fr/)
! into files that can be read by Therion (http://therion.speleo.sk/).
! It reads .tro file and produce one .th file (file with survey data),
! and one thconfig file (file that is used to compile and build the survey with Therion).
!
! To use it, compile it with your prefered fortran compilor (gfortran is free)
! and just run it and answer intelligently to the questions ! That's all !
! REMARK: If you are using gfortran on a mac, chekc the compilation options. If you have an error
!         because of the tex commands, check in the thconfig if there is no \t or \c or \f missing.
!         If this is the case, compile with the option -fno-backslash to avoid the problem with backslash.
!
! A flag allows french or english outputs.
!
! I based my conversion on the french version 5.03 of Visualtopo files. If a previous
! version or a newest version is used, the numbering of the way to read the
! different lines of the .tro file could wrong and should probably to be change,
! Good luck ;-)
!
!
!
! TO DO LIST
! * to implement the other cases (sumps,...)
! * Find the nodes where the projection is inverted in order to draw a cool
!   projected map.
! * Change the variables in the input file ! We do not need iboucles or inew ! Remove it.
! * Put a flag to allow or not the comments before the lines. Just a boolean
! END TO DO LIST
!
!
! FRANCAIS :
! Ce code permet de transformer les fichiers .tro  de Visualtopo (http://vtopo.free.fr/)
! en fichiers lisibles par Therion (http://therion.speleo.sk/).
! Ce code lit le fichier .tro et produit un fichier .th (fichier contenant les données topo),
! et un fichier thconfig (qui est utilisé pour compiler et construire la topographie avec Therion).
!
! Pour l'utiliser, compiler le code source avec votre compilateur Fortran préféré (gfortran est libre),
! Executer l'application et répondez intelligeamment aux questions, c est tout !
! REMARQUE : si gfortran est utilisé sur un mac, vérifier les options de compilation. S'il y a une erreur
!         à cause des commandes tex, vérifier dnsa le thconfig si les \t ou \c ou \f ne manquent pas.
!         S'ils manquent, recompiler avec l'option -fno-backslashpour éviter les problèmes de backslash.
!

!
! Le code source est commenté uniquement en anglais. Mais, il est possible de changer la langue 
! des fichiers de sortie (Français ou Anglais) en modifiant la variable "french" dans le code source.
!
! j'ai basé la conversion sur les fichiers Visualtopo issus de la version française 5.03. 
! Si une version plus ancienne ou plus récente de Vtopo est utilisée, la numérotation de la lecture
! des differentes lignes du fichier .tro risque d'être erronée, et donc il faudra probablement
! modifier cette numérotation.
! Good luck ;-)
!
!
!
! COPYRIGHT
!Copyright (C) 2010 Xavier Robert <xavier.robert***@***ird.fr>
! This work is under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.html) :
! This program is free software; you can redistribute it and/or
! modify it under the terms of the GNU General Public License
! as published by the Free Software Foundation; either version 2
! of the License, or any later version.
!
! The way this program writes the thconfig file is based on the work done by
!   Roman Munuz and Martin Gerbaux that has these specifications :
!     "Copyright (C) 2006 Roman Muñoz <tatel@euskalnet.net> and
!             Martin Gerbaux <martin.gerbaux@wanadoo.fr>
!                   This work is under the GPLv2"
!


! REVISIONS
! 05/02/11 (Xavier Robert) : bug correction with topofil + Clino
! 08/02/11 (Xavier Robert) : Solve the problem with the backslash and make clean the "&"
!                            in the write commands (compilor g95 was giving errors during compilation)




! Variables declaration
       integer i,j,k,z
       integer ii, iread
       logical lrud, french, comments
       integer iout,iboucles,inew
       integer nfnme,nfnmeold
       character fnme*300,fnmeold*300,line*1024,cavename*300,entrance*300

       character dir*11,inc*3,std*3,param*7,cs*100,junkch*4,coordsyst*100
       character length*7,compass*11,clino*9,tunnel*18
       character azimangle*3,azimangleth*7,slopeangle*3,slopeangleth*7

       character pointfrom*11,pointto*11,fromcount*7,tocount*7
       character fromold*11,tocountold*7
       character etalon*5,azimcorr*7,slope*5
       real*4 datalenght,datadir,dataslope
       real*4 xcoord,ycoord,alt
       real*4 fromdepth,todepth,todepthold
       real*4 dataleft,dataright,dataup,datadown
       character inverse*3,yes*1

       real*4 junk
       real*4 pi
       parameter (pi=3.1415926)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Define if you have to read the input file input.txt
!    If iread=0, read the input file
!    If iread=1, read from sreen
       iread=1
!       iread=0
!
! Define if you want it in French or in English. To change, switch the comment sign (!)
!   * For French
!       french=.true.
!   * For English
       french =.false.
!
! Define if you want the comments or not in the output files To change, switch the sign (!)
!   * for comments (longer files)
!       comments =.true.
!   * No comments
       comments =.false.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
       
       
       if (iread.eq.0) then
!
! If you read the the input instructions from a file,
! this file has to contain in this order (you can comment lines with the $ sign) :
! * fnme = input file name
! * inew = input in new topo or not
!
!
! Read the input.txt file
!   Open the input.txt file
       open (11,file='input.txt',status='old')
!   Remove comments lines and blank lines
       open (12,status='scratch')
     1 read (11,'(a1024)',end=2) line
         if (line(1:1).ne.'$'.and. line(1:1).ne.' ') then
           if (scan(line,'$').ne.0) then
             do i=scan(line,'$'),1024
             line(i:i)=' '
             enddo
           endif
         k=1
           do j=1,1024
             if (line(j:j).eq.' '.or.line(j:j).eq.',') then
             if (j.ne.k) write (12,'(a)') line(k:j-1)
             k=j+1
             endif
           enddo
         endif
       goto 1
     2 close (11)
       rewind (12)

!    read fnme = input name
       do i=1,300
       fnme(i:i)=' '
       enddo
       read (12,*) fnme
       do i=1,300
       if(fnme(i:i).ne.' ') nfnme=i
       enddo
!    read inew
       read (12,*) inew
!    read fnmeold
       close (12)

! Read from screen
! 
! This is the best thing to do for common cavers.
      else
      if (french) then
      print*,'Entre le nom du fichier à convertir (sans l extension .tro' &
             // ' sans espaces) >'
      read*,fnme
      do i=1,300
       if(fnme(i:i).ne.' ') nfnme=i
      enddo
      print*,'Est-ce une nouvelle topographie ? >'
      print*,'(Si NON, alos aucun fichier thconfig n est produit.)'
      print*,'(o si c est une nouvelle topo, / n si la topo sera ajouté à une' &
             //' ancienne topo)'
      read*, yes
      if (yes.eq.'o') inew=1
      else
      ! If english
      print*,'Enter file name to convert (without the .tro extension' &
             //' and without any space) >'
      read*,fnme
      do i=1,300
       if(fnme(i:i).ne.' ') nfnme=i
      enddo
      print*,'Is it a new survey ? >'
      print*,'(If no, no thconfig file will be produced.)'
      print*,'(y if this is a new survey / n if you add it to an older survey)'
      read*, yes
      if (yes.eq.'y') inew=1
      end if
      end if
      
! Initialisation of some variables...
       do i=1,300
       cavename(i:i)=' '
       enddo
       do i=1,100
       cs(i:i)=' '
       coordsyst(i:i)=' '
       enddo
      xcoord=0.
      ycoord=0.
      alt=0.     

! open the .tro survey
       open (77,file=fnme(1:nfnme)//'.tro',status='old')  
              
       if (french) then
       print*,'Travail sur ',fnme(1:nfnme)//'.tro'     
       else
       print*,'Processing ',fnme(1:nfnme)//'.tro'     
       end if
       print*,' '
                            
! Pass trough the header
      read (77,'(a1024)') line      	 
      write (*,*) trim(line)
          ! if there is no cavename in the .tro file, replace it by the name of the file
          ! Xavier Robert (5/02/11)
          cavename=fnme
      do while (line(1:5).ne.'Param')
      	read (77,'(a1024)') line
        if (line(1:4).eq.'Trou') then        
         backspace (77)
         read(77,*) junkch,cavename,xcoord,ycoord,alt,cs
         cavename=trim(cavename)
!     Rewrite the coordinate system to be read by Therion
      ! French Lambert system. To find number of your system, see extern/proj4/nad/epsg file in the therion source distribution. You can add you own lines/systems
          if (trim(cs).eq.'LT1') coordsyst='EPSG:<27571>'                        !Lambert1
          if (trim(cs).eq.'LT2') coordsyst='EPSG:<27572>'                        !Lambert2
          if (trim(cs).eq.'LT3') coordsyst='EPSG:<27573>'                        !Lambert3
          if (trim(cs).eq.'LT4') coordsyst='EPSG:<27574>'                        !Lambert4                    
         end if
! Write line on sreen : to debug code
!      	 write (*,*) trim(line)
        if (line(1:6).eq.'Entree') then        
         backspace (77)
         read(77,*) junkch,entrance
         entrance=trim(entrance)
         if (entrance.eq.'') entrance=fnme  ! Xavier Robert (05/02/11)
        end if
       end do

! Open and write the .th header
!       open (88,file=fnme(1:nfnme)//'.th',status='new')                      ! OK
       open (88,file=fnme(1:nfnme)//'.th',status='unknown')                   ! OK
       write (88,*) 'encoding iso8859-2'                                      ! OK
       write (88,*) 'survey ',trim(fnme),' -title "',trim(cavename), &        ! OK
                    '" -entrance "'//trim(entrance)//'"'                      ! OK
       write (88,*) ' '                                                       ! OK

	   if (comments) then
       if (french) then
       write (88,*) '# Copier les 2 lignes suivantes dans le centerline' &
                     //' qui contient la station fixée.'                             
       else
       write (88,*) '# Copy the 2 following lines in the corresponding' &
                     //' centerline that contains the fixed station'      
       endif
       endif                       
       write (88,*)	'#cs ',trim(coordsyst) 
       write (88,*) '#fix '//trim(cavename),xcoord,ycoord,alt

     5 write (88,*) 'centerline'
     
       if (comments) then
       if (french) then
       write (88,*) '# Si le systeme de coordonnees n est pas le systeme' &
                    //' Lambert français, voir le Thbook et le fichier' &
                    //' extern/proj4/nad/epsg dans le dossier source de Therion'
       write (88,*) '# Si les coordonnees de l entree sont connues,' &
                  //' copier dans la centerline correspondante et decommenter' &
                  //' les 2 lignes suivantes :'
       else
       write (88,*) '# If your are not in the french Lambert system, ' &
                     //' To find number of your system, see' &
                     //' extern/proj4/nad/epsg file in the Therion' &
                     //' source distribution'
       write (88,*) '# If the entrance coordinates are known, uncomment and' &
                    //' copy in the corresponding centerline the next 2 lines:'
       endif
       endif


! Reset of all parameters read
       slope=' '

! Read sub-header param. Subdivise in function of the datatype.
       if (line(1:11).eq.'Param Topof') then                                     ! OK
        length='topofil'                                                         ! OK
        ! Modified by Xavier Robert, 05/02/11
        backspace (77)
        read(77,*) junkch,junkch,etalon,azimangleth,slope,slopeangleth, &
                   azimcorr,compass,clino,tunnel
!        if (slope.eq.'Prof') slope='Prof'
         if (slopeangleth.eq.'Gra') slopeangleth='grad'
         if (slopeangleth.eq.'Deg') slopeangleth='degrees'    
         if (slopeangleth.eq.'Degd') slopeangleth='degrees'    
        if (slope.eq.'Prof') length='Diving' 
        if (slope.eq.'Deniv') slope='Deniv'
        if (slope.eq.'Clino') slope='Clino'
        if (slope.eq.'Vulc') slope='Vulc'
        if (azimangleth.eq.'Gra') azimangleth='grad'                             ! OK
        if (azimangleth.eq.'Deg') azimangleth='degrees'    
        if (azimangleth.eq.'Degd') azimangleth='degrees'    
        if (compass.eq.'Dir') compass='compass'
        if (compass.eq.'Inv') compass='backcompass'
        if (clino.eq.'Dir') clino='clino'
        if (clino.eq.'Inv') clino='backclino'
        
!        if (clino.eq.'Dir') clino='depth'
!        if (clino.eq.'Inv') clino='backdepth'
        if (tunnel.eq.'Dir') tunnel='left right up down'
        if (tunnel.eq.'Inv') tunnel='right left up down'




!        etalon=line(13:17)                                                       ! OK
!        ! Check the angles units
!       	if (line(19:21).eq.'Gra') azimangleth='grad'                             ! OK
!       	if (line(19:21).eq.'Deg') azimangleth='degrees'                          ! OK
!!       	write (*,*) 'direction units ', azimangleth                          ! OK
        ! Check the direction of measures

!        if (line(33:46).eq.'Prof') then     ! line has to be numbered
!        if (line(23:27).eq.'Prof') then     ! line has to be numbered
!         z=0
!         if (line(32:32).eq.'-') z=1
!         azimcorr=line(32:37+z)  
!         slope='Prof'     
!!       write (*,*) 'Azimuth correction ', azimcorr
!         if (line(39+z:41+z).eq.'Dir') compass='compass'
!         if (line(39+z:41+z).eq.'Inv') compass='backcompass'
!!       write (*,*) 'compass ', compass
!         if (line(33+z:45+z).eq.'Dir') clino='depth'
!         if (line(33+z:45+z).eq.'Inv') clino='backdepth'
!!       write (*,*) 'clino ', clino
!         if (line(47+z:49+z).eq.'Dir') tunnel='left right up down'
!         if (line(47+z:49+z).eq.'Inv') tunnel='right left up down'
!!       write (*,*) 'LRUD ', tunnel

!        else if (line(23:27).eq.'Deniv') then       ! line has to be numbered
!         z=0
!         if (line(16:16).eq.'-') z=1
!         azimcorr=line(32:37+z)     ! -4 
!         slope='Deniv'
!        write (*,*) 'Azimuth correction ', azimcorr
!         if (line(40+z:42+z).eq.'Dir') compass='compass'
!         if (line(40+z:42+z).eq.'Inv') compass='backcompass'
!       write (*,*) 'compass ', compass
!         if (line(34+z:46+z).eq.'Dir') clino='depth'
!         if (line(34+z:46+z).eq.'Inv') clino='backdepth'
!       write (*,*) 'clino ', clino
!         if (line(48+z:50+z).eq.'Dir') tunnel='left right up down'
!         if (line(48+z:50+z).eq.'Inv') tunnel='right left up down'
!       write (*,*) 'LRUD ', tunnel
    
!        else if (line(23:27).eq.'Clino') then
!         z=0         
!         if (line(16:16).eq.'-') z=1
!         azimcorr=line(32:37+z)
!         slope='Clino'        
!       write (*,*) 'Azimuth correction ', azimcorr
!         if (line(29:31).eq.'Gra') slopeangleth='grad'
!         if (line(29:31).eq.'Deg') slopeangleth='degrees'       
!       write (*,*) 'slope units ', slopeangleth       
!         if (line(40+z:42+z).eq.'Dir') compass='compass'
!         if (line(40+z:42+z).eq.'Inv') compass='backcompass'     
!       write (*,*) 'compass ', compass
!         if (line(44+z:46+z).eq.'Dir') clino='clino'
!         if (line(44+z:46+z).eq.'Inv') clino='backclino'
!       write (*,*) 'clino ', clino       
!         if (line(48+z:50+z).eq.'Dir') tunnel='left right up down'
!         if (line(48+z:50+z).eq.'Inv') tunnel='right left up down'
!       write (*,*) 'LRUD ', tunnel
            
!        else                ! If this is with a normal clino/topof, Here, lines are good.
!         z=0
!         if (line(32:32).eq.'-') z=1
!         azimcorr=line(32:37+z)
!         slope='Vulc'
!         if (line(28:30).eq.'Gra') slopeangleth='grad'                           ! OK
!         if (line(28:30).eq.'Deg') slopeangleth='degrees'                        ! OK
!         if (line(39+z:41+z).eq.'Dir') compass='compass'                         ! OK
!         if (line(39+z:41+z).eq.'Inv') compass='backcompass'                     ! OK
!         if (line(43+z:45+z).eq.'Dir') clino='clino'                             ! OK
!         if (line(43+z:45+z).eq.'Inv') clino='backclino'                         ! OK
!         if (line(47+z:49+z).eq.'Dir') tunnel='left right up down'               ! OK
!         if (line(47+z:49+z).eq.'Inv') tunnel='right left up down'               ! OK

        
!        end if


        ! End of modification 05/02/11
        
        
        
       end if

       if (line(1:10).eq.'Param Deca') then
        length='normal'                                                          ! OK
        etalon='1'                                                               ! OK
        ! Check the angles units
       	if (line(12:14).eq.'Gra') azimangleth='grad'                             ! OK
       	if (line(12:14).eq.'Deg') azimangleth='degrees'                          ! OK
!       	if (line(12:14).eq.'Degd') azimangleth='degrees'                          ! OK
        ! Check the direction of measures

        if (line(16:19).eq.'Prof') then     ! line has to be numbered
         length='diving'                                                         ! OK
         z=0                                                                     ! OK
         if (line(21:21).eq.'-') z=1
         azimcorr=line(21:26+z)
         slope='Prof'
         slopeangleth='grad'       
!       write (*,*) 'Azimuth correction ', azimcorr
         if (line(28+z:30+z).eq.'Dir') compass='compass'
         if (line(28+z:30+z).eq.'Inv') compass='backcompass'
!       write (*,*) 'compass ', compass
         if (line(32+z:34+z).eq.'Dir') clino='depth'
         if (line(32+z:34+z).eq.'Inv') clino='backdepth'
!       write (*,*) 'clino ', clino
         if (line(36+z:38+z).eq.'Dir') tunnel='left right up down'
         if (line(36+z:38+z).eq.'Inv') tunnel='right left up down'
!       write (*,*) 'LRUD ', tunnel

        else if (line(16:20).eq.'Deniv') then       ! line has to be numbered
         z=0
        print*,'DENIV not yet implemented'
         if (line(22:22).eq.'-') z=1
         azimcorr=line(22:27+z)
         slopeangleth=azimangleth          
         slope='Deniv' 
         length='normal'
        write (*,*) 'Azimuth correction ', azimcorr
         if (line(29+z:31+z).eq.'Dir') compass='compass'
         if (line(29+z:31+z).eq.'Inv') compass='backcompass'
       write (*,*) 'compass ', compass
         if (line(33+z:35+z).eq.'Dir') clino='depth'
         if (line(33+z:35+z).eq.'Inv') clino='backdepth'
       write (*,*) 'clino ', clino
         if (line(37+z:39+z).eq.'Dir') tunnel='left right up down'
         if (line(37+z:39+z).eq.'Inv') tunnel='right left up down'
       write (*,*) 'LRUD ', tunnel
    
        else if (line(16:20).eq.'Clino') then                                    ! OK
         z=0                                                                     ! OK
         if (line(26:26).eq.'-') z=1                                             ! OK
         azimcorr=line(26:31+z)                                                  ! OK        
         slope='Clino'                                                           ! OK
         if (line(22:24).eq.'Gra') slopeangleth='grad'                           ! OK
         if (line(22:24).eq.'Deg') slopeangleth='degrees'                        ! OK
!         if (line(22:24).eq.'Degd') slopeangleth='degrees'                        ! OK
         if (line(33+z:35+z).eq.'Dir') compass='compass'                         ! OK
         if (line(33+z:35+z).eq.'Inv') compass='backcompass'                     ! OK
         if (line(37+z:39+z).eq.'Dir') clino='clino'                             ! OK
         if (line(37+z:39+z).eq.'Inv') clino='backclino'                         ! OK
         if (line(41+z:43+z).eq.'Dir') tunnel='left right up down'               ! OK
         if (line(41+z:43+z).eq.'Inv') tunnel='right left up down'               ! OK
 

            
        else                ! If this is with a normal clino/topof, Here, lines are good.
         z=0                                                                     ! OK
         if (line(25:25).eq.'-') z=1                                             ! OK
         azimcorr=line(25:30+z)                                                  ! OK
         slope='Vulc'                                                            ! OK
         if (line(21:23).eq.'Gra') slopeangleth='grad'                           ! OK
         if (line(21:23).eq.'Deg') slopeangleth='degrees'                        ! OK    
!         if (line(21:23).eq.'Degd') slopeangleth='degrees'                        ! OK    
         if (line(32+z:34+z).eq.'Dir') compass='compass'                         ! OK
         if (line(32+z:34+z).eq.'Inv') compass='backcompass'                     ! OK
         if (line(36+z:38+z).eq.'Dir') clino='clino'                             ! OK
         if (line(36+z:38+z).eq.'Inv') clino='backclino'                         ! OK   
         if (line(40+z:42+z).eq.'Dir') tunnel='left right up down'               ! OK
         if (line(40+z:42+z).eq.'Inv') tunnel='right left up down'               ! OK
        end if
       end if


! write what header file

       write (88,*) '#  date YYYY.MM.DD'                                         ! OK
       write (88,*) '  declination ', azimcorr, ' ', trim(azimangleth)           ! OK
       if (trim(length).eq.'topofil') write (88,*) '  calibrate counter 0 ', &   ! OK
                                                   trim(etalon)                  ! OK
       write (88,*) ' team "G.S. Vulcain"'                                       ! OK
	   if (comments) then
       write (88,*) '# (to be completed, add many lines as you need)'            ! OK
       endif
       write (88,*) '  units lenght meters'                                      ! OK
       write (88,*) '  units compass ', trim(azimangleth)                        ! OK
       write (88,*) '  units clino ', trim(slopeangleth)                         ! OK
       write (88,*) '# infer equates on'                                         ! OK
       write (88,*) '# infer plumbs on'                                          ! OK

! Write the way to give data, in regards to the style of measures 
       if (trim(length).eq.'topofil') then                                       ! OK
        write (88,*) ' units counter centimeters'                                ! OK
	    write (88,*) '  data ',trim(length), &                                   ! OK
	     ' from to fromcount tocount ', &                                        ! OK
         trim(compass), ' ', trim(clino), ' ', trim(tunnel)                      ! OK
       else if (trim(length).eq.'normal') then                                   ! OK
	    write (88,*) '  data ',trim(length),' from to length ', &                ! OK
        	trim(compass), ' ', trim(clino), ' ', trim(tunnel)                   ! OK
       else 
        write (88,*) ' units tape meters'                                        ! OK
        write (88,*) ' units depth meters'                                       ! OK
        write (88,*) ' data ',trim(length),' from to tape fromdepth todepth ', & ! OK   
        	trim(compass), ' ', trim(tunnel)                                     ! OK
        todepth=0.
!        write (*,*) todepth
       end if                                                                    ! OK
 
       i=1                                                                       ! OK
       read (77,'(a1024)',end=6) line                                            ! OK
       do while (line(1:1).eq.' ')                                               ! OK
        read (77,'(a1024)',end=6) line                                           ! OK
       end do                                                                    ! OK
       backspace (77)                                                            ! OK
       

! Begining of the stepping on the topographic sequence
!! Do until line not = "param"
       do while ((line(1:5).ne.'Param').or.(line(1:1).ne.'['))                   ! OK
! read data
! intialization LRUD : Sometimes, it does not exist in .tro.
       fromold=pointto                                                           ! OK

! If we are in the case of Denivelation data
       if (trim(slope).eq.'Deniv') length='Deniv'
       
! Test if LRUD exist or not in the .tro file. If one of them is missing,
!   None of them would be read, but are set at 0.
       dataleft=0.                                                               ! OK
       dataright=0.                                                              ! OK
       dataup=0.                                                                 ! OK
       datadown=0.                                                               ! OK
       lrud=.true.
       do j=45,100
        if (line(j:j).eq.'*') then
         lrud=.false.
        endif
       enddo
       
       if (lrud) then
       ! If you have to read the LRUD data
        ! In the case of survey made with tape/clino
        if (trim(length).eq.'normal') then                                       ! OK
          read (77,*) pointfrom, pointto, datalength,datadir,dataslope, &        ! OK
                    dataleft,dataright,dataup,datadown                           ! OK
        ! In the case of topofil mapping                            
        else if (trim(length).eq.'topofil') then                                 ! OK
          tocountold=tocount                                                     ! OK 
          read (77,*) pointfrom, pointto, fromcount,tocount,datadir, &            
                 dataslope,dataleft,dataright,dataup,datadown                    ! OK
           ! In the case of TOPOFIL, we have to complete 'fromcout(i)' with 'tocount(i-1)'           
           if (fromcount(1:1).eq.'*') fromcount=tocountold                       ! OK
        ! in the case of sumps.
        else if (trim(length).eq.'diving') then 
	      todepthold=todepth
	      read (77,*) pointfrom, pointto, datalength,datadir,todepth, &
	                dataleft,dataright,dataup,datadown
	      fromdepth=todepthold
	      
	    else
	    	length='normal'
	    	read (77,*) pointfrom, pointto, datalength,datadir,todepth, &
	                dataleft,dataright,dataup,datadown
            dataslope= 90-acos(todepth/datalength)*180./pi
            if (trim(slopeangleth).eq.'grad') dataslope=dataslope*100./90.
        end if
       else 
       ! If you do not have to read the LRUD data
        ! In the case of survey made with tape/clino
        if (trim(length).eq.'normal') then                                       ! OK
       	 write (*,*) trim(length)                                                ! OK
          read (77,*) pointfrom, pointto, datalength,datadir,dataslope           ! OK
        ! In the case of topofil mapping                            
        else if (trim(length).eq.'topofil') then                                 ! OK
          tocountold=tocount                                                     ! OK 
          read (77,*) pointfrom,pointto,fromcount,tocount,datadir,dataslope      ! OK
	      ! Correct the angle to be read by Therion. 
           if (fromcount(1:1).eq.'*') fromcount=tocountold                       ! OK
        ! in the case of sumps.
        else if (trim(length).eq.'diving') then 
	      todepthold=todepth                                                     ! OK
	      read (77,*) pointfrom, pointto, datalength,datadir,todepth             ! OK
	      fromdepth=todepthold	                                                 ! OK	  
	    else
	    	length='normal'
	    	read (77,*) pointfrom, pointto, datalength,datadir,todepth
            dataslope= 90.-acos(todepth/datalength)*180./pi
            if (trim(slopeangleth).eq.'grad') dataslope=dataslope*100./90.
        end if       
       end if
            
       ! Correct the angle to be read by Therion if measure made by TopoVulcain system. 
       if (trim(slope).eq.'Vulc') then
         if (trim(slopeangleth).eq.'degrees') then                               ! OK
           dataslope= 90.-dataslope                                              ! OK
         else                                                                    ! OK
            dataslope=100.-dataslope                                             ! OK
         end if
       end if                          
       
       
        
	! Remove the '*' from the 'from' point
        if (pointfrom(1:1).eq.'*') pointfrom=fromold                             ! OK
    ! If null length between 2 points with the same name.
    ! Be careful, we have to take care of that, and modify the file after the run if needed.
    	if (pointfrom.eq.pointto) then                                           ! OK
    	 pointto=trim(pointto)//'double'                                         ! OK
    	end if                                                                   ! OK
        
! Write in the Therion file :
       if (trim(length).eq.'normal') then
	    write (88,*) '  ', trim(pointfrom), ' ', trim(pointto), ' ', &           ! OK
	                 datalength,datadir, &                                       ! OK
	                 dataslope, dataleft,dataright,dataup,datadown               ! OK
       else if (trim(length).eq.'topofil') then                                  ! OK
	    write (88,*) '  ', trim(pointfrom), ' ', trim(pointto), ' ', &           ! OK
	                 trim(fromcount), ' ', trim(tocount), ' ', &                 ! OK
	               datadir, dataslope, dataleft, dataright, dataup, datadown     ! OK
       else
        if (datalength.ne.0.) then                                               ! OK         
	     write (88,*) '  ', trim(pointfrom), ' ', trim(pointto), ' ', &          ! OK
	                 datalength, fromdepth, todepth, datadir, &                  ! OK
	                 dataleft,dataright,dataup,datadown                          ! OK
       	end if 
       end if


! Regarder si visée inversée ou non pour la coupe
! Pour ça, il faut jouer avec la variable 'inverse', qui est égale à 'N I' ou 'I I'
! A FAIRE
!!!!!!!!!!
      	read (77,'(a1024)',end=6) line                                           ! OK
      	do while (line(1:1).eq.' ')                                              ! OK
      	 read (77,'(a1024)',end=6) line                                          ! OK
      	end do                                                                   ! OK
      	if (line(1:5).eq.'Param') exit                                           ! OK
! To debug code
!      	write (*,*) trim(line)                                                   ! OK
! Check if this is the end of the input file, exit if this is the case
        if (line(1:1).eq.'[') goto 6 ! exit                                      ! OK
        backspace (77) ! Go back to the beginning of the line                    ! OK
        i=i+1                                                                    ! OK
       end do                                                                    ! OK
       write (88,*) 'endcenterline'                                              ! OK
       write (88,*) ' '                                                          ! OK
       goto 5                                                                    ! OK
     6 close (77)                                                                ! OK
       write (88,*) 'endcenterline'                                              ! OK
       write (88,*) 'endsurvey'                                                  ! OK
       close (88)                                                                ! OK

       if (french) then
       print*,'Fichier ',fnme(1:nfnme)//'.th ecrit'
       else    
       print*,'File ',fnme(1:nfnme)//'.th writen'    
       end if

! Write the final file that merge the different files.
       if (inew.eq.1) then
!       open (99,file='thconfig',status='new')
       open (99,file='thconfig',status='unknown')
       if (french) then
       write (99,*) 'encoding utf-8'                                             ! OK
       write (99,*) ' '
       write (99,*) ' '
       write (99,*) '# File written by tro2therion.f90 (Xavier Robert) '
       write (99,*) '# Based on the work of Roman Muñoz <tatel@euskalnet.net>' &
                      //' and Martin Gerbaux <martin.gerbaux@wanadoo.fr> '
       write (99,*) ' '
       write (99,*) '# Copyright (C) 2010 Xavier Robert' &
                     //' <xavier.robert***@***ird.fr>'
       write (99,*) '# This work is under the GPLv2'
       write (99,*) ' '
       write (99,*) ' '
       
       if (comments) then
       write (99,*) '# 1-SOURCES '
       write (99,*) '# La ligne source specifie le fichier ou sont les' &
                      //' donnees topo'
       write (99,*) ' # (Au fichier "nomcavite.th" il faudra avoir une ligne' 
       write (99,*) ' # "input "nomcavite.th2" pour specifier le fichier' &
                     //' ou se trouvent'
       write (99,*) ' # les donnees du dessin, comme ça, ce fichier thconfig' &
                      //' appelera '
       write (99,*) ' # nomcavite.th" et a son tour, "nomcavite.th" appelera'
       write (99,*) ' # "nomcavite.th2")'
       endif
       
       write (99,*) 'source ', fnme(1:nfnme)//'.th'                              ! OK
       write (99,*) '#source ', fnme(1:nfnme)//'.th2'                              ! OK
       write (99,*) ' '
       
       if (comments) then
       write (99,*) '# 2-LAYOUT   '                                                       ! OK
!       write (99,*) ' '
       write (99,*) '# Debut de la definition du Layout "xviexport"'
       endif       
       write (99,*) 'layout xviexport'

       if (comments) then
       write (99,*) '  # echelle a laquelle on veut dessiner la topo'
       endif       
       write (99,*) '  scale 1 1000'
       
       if (comments) then
       write (99,*) '  # taille de la grille'
       endif
       write (99,*) '  grid-size 10 10 10 m'

       if (comments) then
       write (99,*) '  # mettre la grille en arrière plan'
       endif
       write (99,*) '  grid bottom'
       write (99,*) 'endlayout'
       
       if (comments) then
       write (99,*) '# fin de la définition du layout "xviexport" '
       endif
       write (99,*) ' '
       write (99,*) 'layout my_layout'    
       write (99,*) ' ' 
       
       if (comments) then      
       write (99,*) '  # Titre  '                                            
       endif
       write (99,*) '  doc-title "', fnme(1:nfnme),'"'
       
       if (comments) then
       write (99,*) '  # Auteur'
       endif       
       write (99,*) '  doc-author "Xavier Robert"'
       
       
       if (comments) then
       write (99,*) ' ' 
       write (99,*) '  # Pour faire la topo dans le system UTM  '
       write (99,*) '  # Decommenter la ligne, et remplacer xx par la zone UTM'
       endif       
       write (99,*) '  #cs UTMxx'
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # "base-scale" specifie l echelle auquel nous avons'
       write (99,*) '  # dessine nos croquis. Par defaut, c est 1/200.'
       write (99,*) '  # Si on a utilise une autre echelle, '
       write (99,*) '  # il faut enlever le "#" et specifier l echelle vraiment' 
       write (99,*) '  # employee, c est le cas apres avoir dessine la topo'
       write (99,*) '  # sur un cheminement exporte avec le layout "xviexport"'
       write (99,*) '  # (voir en bas)'              
       endif
       write (99,*) '  base-scale 1 1000'
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # "scale" : specification de l echelle,'
       write (99,*) '  # pour imprimer la topo. La combination entre scale' &
                       //' et base-scale'
       write (99,*) '  # controlle l epaisseur des lignes, rotation, etc,' &
                       //' convenable'
       write (99,*) '  # pour faire l amplification-reduction entre dessin et'
       write (99,*) '  # le resultat de l imprimante'
       write (99,*) '  # C est tres important s assurer que la configuration de'
       write (99,*) '  # l imprimante ne specifie pas l option "Fit in page"'
       write (99,*) '  # ou similaire, sinon, l echelle sera changee pendant'
       write (99,*) '  # l impression' 
       endif
       write (99,*) ' scale 1 1000'                                             
       
       if (comments) then
       write (99,*) ' '
       write (99,*) ' # Pour faire une rotation'
       endif
       write (99,*) ' #rotate 2.25'
             
       write (99,*) '# origin 12 22 0 m'                                        
       write (99,*) '# origin-label 100 K'                                      
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Une couleur de fond, 85% blanc = 15% noir'
       endif
       write (99,*) ' #color map-bg 85'
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Une couleur de topo (RVB)' 
       endif      
       write (99,*) ' color map-fg [100 100 80]'
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # la topo est transparente' &
                        //' (on peut voir les galeries sous-jacentes)'
       write (99,*) '  # Par defaut, donc, pas vraiment besoin de specifier'
       endif
       write (99,*) ' transparency on'                                          
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Pourcentage de transparence, marche seulement' &
                      //' si transparency est "on"'
       endif
       write (99,*) ' opacity 75'                                              
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Il faut s exprimer avec la langue de Voltaire...'
       endif
       write (99,*) ' language fr'                                              
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # echelle graphique 100 m ampleur'
       endif
       write (99,*) '  scale-bar 100 m'
       
       if (comments) then
       write (99,*) ' '      
       write (99,*) '  # Un commentaire a ajounter au titule,'
       endif
       write (99,*) ' map-comment "'//trim(cavename)//' plan, Samoëns, 74,' &
                      //' France"'        
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Afficher les statistiques d explo par équipe/nom.' &
                      //' C est lourd'
       write (99,*) '  # si la cavite est importante et qu il y a beaucoup' & 
                      //' d explorateurs'
       endif
       write (99,*) '  statistics explo off'
       write (99,*) ' # statistics explo-length off'                            
       
       if (comments) then
       write (99,*) '  # Afficher developpement et profondeur de la cavite'
       endif
       write (99,*) ' statistics topo-length off'                              
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Nous voulons une legende pour expliquer les' &
                       //' symboles. "on" imprimera'
       write (99,*) '  # seulement la legende des symboles dessines sur la' &
                       //' topo, si l on veut'
       write (99,*) '  # pour tous les symboles, utilises ou pas,' & 
                       //' il faut indiquer "all".'
       write (99,*) '  # "legend off" = pas de legende'
       endif
       write (99,*) ' legend on' 
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Par defaut, la legende est de 14 cm de largeur'
       endif
       write (99,*) '  #  legend-width 14 cm'
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Specification la position de la manchette : interieur'
       write (99,*) '  # occuppe par le titule, auteurs, etc. Nous pouvons' & 
                       //' indiquer'
       write (99,*) '  # les cordonnees du point de la topo ou l on veut' &
                       //' la manchette :'
       write (99,*) '  # 0 0, c est en bas, a gauche'
       write (99,*) '  # 100 100, c est en haut, a droite'
       write (99,*) '  # La manchette a des "points cardinaux" :' &
                        //' n, s, ne, sw, etc.'
       write (99,*) '  # Il faut specifier un de ces points '
       endif
       write (99,*) ' map-header 0 00 nw'                                       
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # arrière plan de la manchette'
       endif
       write (99,*) ' map-header-bg off'
      
       write (99,*) ' layers on'                                                 ! OK
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Options pour afficher le squelette topo,'
       write (99,*) '  # les points et le nom des stations topos'       
       endif
       write (99,*) ' symbol-hide line survey'
       write (99,*) ' #symbol-hide point station DO NOT WORK !'
       write (99,*) ' #debug station-names'               
       write (99,*) '  # Symbologie: UIS, ASF (Australie) CCNP (Etats Units) ou'
       write (99,*) '  # SKB (tchecoslovakia) '
       write (99,*) '  #symbol-set UIS'       
       write (99,*) ' symbol-assign point station:temporary SKBB'              
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Specifier qu il faut imprimer une grille'
       write (99,*) '  # au dessous de la topo  '     
       endif
       write (99,*) '# grid bottom'                                             
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Specifier le pas de la grille, ici 100x100x100 metres'
       write (99,*) '  # (Trois dimensions, oui, ça sert pour la coupe aussi) '      
       endif
       write (99,*) '# grid-size 100 100 100 m'                                 
       if (comments) then
       write (99,*) '  # Si nous ne voulons pas de grille :'
       endif
       write (99,*) '  grid off'  
                                                              
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Afficher un copyright'
       endif
       write (99,*) '  statistics copyright 2'
       
       if (comments) then
       write (99,*) ' '
       write (99,*) ' '
       write (99,*) '  # "size", c est pour l atlas. Ce sont les dimensions' &
                     //' du carre dont'
       write (99,*) '  # l interieur sera ocuppe par la partie de la topo' &
                     //' correspondant a'
       write (99,*) '  # chaqu une des pages. 15 x 20, ça va bien pour' &
                        //' imprimer en A4.'
       endif
       write (99,*) '#  size 15 20 cm'
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Dans l atlas, on superpose 1 cm de chaque page voisine'
       endif
       write (99,*) '  overlap 1 cm'
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Pour exclure des pages de l atlas :'       
       endif
       write (99,*) '# exclude-pages on 1,2,5'                                  
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # "page-setup" : pour map et pour atlas aussi.'
       write (99,*) '  # On specifie les dimensions de la feuille papier:' &
                       //' 21 X 29,7 (A4)'
       write (99,*) '  # la surface imprimable du papier, ce sont 17 X 28,2'
       write (99,*) '  # Alors, on indique une marge a gauche de 3 (21-17-1=3)'
       write (99,*) '  # et une marge en haut de 1,5 (29,7-27,2-1=1,5)'
       write (99,*) '  # en centimetres  '
       endif
       write (99,*) '# page-setup 21 29.7 17 27.2 3 1.5 cm  '
       
       write (99,*) ' '
       write (99,*) ' '
       write (99,*) ' '
       write (99,*) ' ######## Code Metapost pour modifier l aspect' &
                      //' des symboles ####### '              
       write (99,*) ' '
       write (99,*) '    # Modifier l aspect et les données des statistiques' &
                           //' de longueurs affichees'
       write (99,*) '  #code tex-map'
       write (99,*) '  #     \cavelength{1330\thinspace{}m} '
       write (99,*) '  #+ 150\\thinspace{}m estimes}'
       write (99,*) '  #     \cavedepth{243\thinspace{}m}'
       write (99,*) '  #   endcode  '
       write (99,*) ' '
       write (99,*) '    # Afficher un copyright'
       write (99,*) '  statistics copyright 2'
       write (99,*) ' '  
       write (99,*) '    # Taille des blocs : Modifier la taille des blocs' &
                         //' en fonction de la taille de la topo'
       write (99,*) 'code metapost'
       write (99,*) '  def a_blocks (expr p) ='
       write (99,*) '    T:=identity;'
       write (99,*) '    pickup PenC;'
       write (99,*) '    path q, qq; q = bbox p;'
       write (99,*) '    picture tmp_pic; '
       write (99,*) '    uu := max(u, (xpart urcorner q - xpart llcorner q)&
                        /100, (ypart urcorner q - ypart     llcorner q)/100);'
       write (99,*) '    tmp_pic := image('
       write (99,*) '      for i = xpart llcorner q step 1.0uu until xpart &
                            urcorner q:'
       write (99,*) '        for j = ypart llcorner q step 1.0uu until ypart &
                              urcorner q:'
       write (99,*) '          qq := punked (((-.3uu,-.3uu)--(.3uu,-.3uu)--&
                               (.3uu,.3uu)--(-.3uu,.3uu)--cycle) '
       write (99,*) '         randomized (uu/2))'
       write (99,*) '               rotated uniformdeviate(360)' 
       write (99,*) '               shifted ((i,j) randomized 1.0uu);'
       write (99,*) '    if xpart (p intersectiontimes qq) < 0:'
       write (99,*) '      thclean qq;'
       write (99,*) '      thdraw qq;'
       write (99,*) '    fi;'
       write (99,*) '        endfor;  '
       write (99,*) '      endfor;'
       write (99,*) '    );'
       write (99,*) '    clip tmp_pic to p;'
       write (99,*) '    draw tmp_pic;'
       write (99,*) '  enddef;'
       write (99,*) ' '
       write (99,*) ' '
       write (99,*) '# Metapost codes to change some aspects... '
              write (99,*) ' '
       write (99,*) '#  Pour changer l aspect du sable'
       write (99,*) 'def a_sands (expr p) ='
       write (99,*) '    T:=identity;'
       write (99,*) '    pickup PenC;'
       write (99,*) '    path q; q = bbox p;'
       write (99,*) '    picture tmp_pic;'
       write (99,*) '    tmp_pic := image('
       write (99,*) '      for i = xpart llcorner q step 0.1u until xpart &
                            urcorner q:'
       write (99,*) '        for j = ypart llcorner q step 0.1u until ypart &
                             urcorner q:'
       write (99,*) '          draw origin shifted ((i,j) randomized 0.1u) &
                                withpen PenC;'
       write (99,*) '        endfor;'
       write (99,*) '      endfor;'
       write (99,*) '    );'
       write (99,*) '    #clip tmp_pic to p;'
       write (99,*) '    draw tmp_pic;'
       write (99,*) '  enddef;'
       write (99,*) ' '
       write (99,*) '# Pour changer l aspect des pebbles'
       write (99,*) 'def a_pebbles_SKBB (expr p) ='
       write (99,*) '  T:=identity;'
       write (99,*) '  pickup PenC;'
       write (99,*) '  path q, qq; q = bbox p;'
       write (99,*) '  picture tmp_pic; '
       write (99,*) '  tmp_pic := image('
       write (99,*) '    for i = xpart llcorner q step .1u until xpart &
                          urcorner q:'
       write (99,*) '      for j = ypart llcorner q step .5u until ypart &
                            urcorner q:'
       write (99,*) '        qq := (superellipse((.07u,0),(0,.03u), &
                            (-.07u,0),(0,.-.03u),.75))'
       write (99,*) '%             randomized (u/25)'
       write (99,*) '             rotated uniformdeviate(360) '
       write (99,*) '             shifted ((i,j) randomized 0.27u);'
       write (99,*) '	if xpart (p intersectiontimes qq) < 0:'
       write (99,*) '	  thdraw qq;'
       write (99,*) '	fi;'
       write (99,*) '      endfor;  '
       write (99,*) '    endfor;'
       write (99,*) '  );'
       write (99,*) '  clip tmp_pic to p;'
       write (99,*) '  draw tmp_pic;'
       write (99,*) 'enddef;'
       write (99,*) ' '
       write (99,*) '# Pour changer l aspect des pentes'
       write (99,*) '   def l_slope (expr P,S)(text Q) = '
       write (99,*) ' %show Q;'
       write (99,*) 'T:=identity;'
       write (99,*) 'numeric dirs[];'
       write (99,*) 'numeric lengths[];'
       write (99,*) 'for i=Q:'
       write (99,*) '  dirs[redpart i]:=greenpart i;'
       write (99,*) '  lengths[redpart i]:=bluepart i;'
       write (99,*) 'endfor;  '
       write (99,*) 'li:=length(P); % last'
       write (99,*) 'alw_perpendicular:=true;'
       write (99,*) 'for i=0 upto li:'
       write (99,*) '  if unknown dirs[i]: dirs[i]:=-1; '
       write (99,*) '  else: '
       write (99,*) '    if dirs[i]>-1:'
       write (99,*) '      dirs[i]:=((90-dirs[i]) - angle(thdir(P,i))) mod 360;' 
       write (99,*) '      alw_perpendicular:=false;'
       write (99,*) '    fi;'
       write (99,*) '  fi;'
       write (99,*) '  if unknown lengths[i]: lengths[i]:=-1; fi;'
       write (99,*) 'endfor;'
       write (99,*) '  %for i=0 upto li: show dirs[i]; endfor;'
       write (99,*) 'ni:=0; % next'
       write (99,*) 'pi:=0; % previous'
       write (99,*) 'for i=0 upto li:'
       write (99,*) '  d:=dirs[i];'
       write (99,*) '  if d=-1:'
       write (99,*) '    if (i=0) or (i=li):'
       write (99,*) '      dirs[i] := angle(thdir(P,i) rotated 90) mod 360;'
       write (99,*) 'pi:=i;'
       write (99,*) '    else:'
       write (99,*) '      if ni<=i:'
       write (99,*) '  for j=i upto li:'
       write (99,*) '          ni:=j;'
       write (99,*) '    exitif dirs[j]>-1;'
       write (99,*) '  endfor;'
       write (99,*) 'fi;'
       write (99,*) 'w:=arclength(subpath(pi,i) of P) / '
       write (99,*) '   arclength(subpath(pi,ni) of P);'
       write (99,*) 'dirs[i]:=w[dirs[pi],dirs[ni]];'
       write (99,*) '   %        if (dirs[i]-angle(thdir(P,i))) mod 360>180:'
       write (99,*) '   %          dirs[i]:=w[dirs[ni],dirs[pi]];'
       write (99,*) '   %	  message("*******");'
       write (99,*) '   %        fi;'
       write (99,*) '   fi;'
       write (99,*) '  else:'
       write (99,*) '    pi:=i;'
       write (99,*) '  fi;'
       write (99,*) 'endfor;'
       write (99,*) '  %for i=0 upto li: show dirs[i]; endfor;'
       write (99,*) 'ni:=0; % next'
       write (99,*) 'pi:=0; % previous'
       write (99,*) 'for i=0 upto li:'
       write (99,*) '  l:=lengths[i];'
       write (99,*) '  if l=-1:'
       write (99,*) '    if (i=0) or (i=li):'
       write (99,*) '      lengths[i] := 1cm; % should never happen!'
       write (99,*) 'thwarning("slope width at the end point not specified");'
       write (99,*) 'pi:=i;'
       write (99,*) '    else:'
       write (99,*) '      if ni<=i:'
       write (99,*) '  for j=i+1 upto li:'
       write (99,*) '          ni:=j;'
       write (99,*) '    exitif lengths[j]>-1;'
       write (99,*) '  endfor;  '
       write (99,*) 'fi;'
       write (99,*) 'w:=arclength(subpath(pi,i) of P) /   '
       write (99,*) '   arclength(subpath(pi,ni) of P);'
       write (99,*) 'lengths[i]:=w[lengths[pi],lengths[ni]];'
       write (99,*) 'pi:=i;'
       write (99,*) '    fi;'
       write (99,*) '  else:'
       write (99,*) '    pi:=i;'
       write (99,*) '  fi;'
       write (99,*) 'endfor;'
       write (99,*) '  % for i=0 upto li: show lengths[i]; endfor;'
       write (99,*) 'T:=identity;'
       write (99,*) 'boolean par;'
       write (99,*) 'cas := 0.3u;'
       write (99,*) 'krok := 0.7u;'
       write (99,*) 'dlzka := (arclength P);'
       write (99,*) 'if dlzka>3u: dlzka:=dlzka-0.6u fi;'
       write (99,*) 'mojkrok:=adjust_step(dlzka,1.4u) / 5;'
       write (99,*) 'pickup PenD;'
       write (99,*) 'par := false;' 
       write (99,*) 'forever:'
       write (99,*) '  t := arctime cas of P;'
       write (99,*) '  if t mod 1>0:  % not a key point'
       write (99,*) '    w := (arclength(subpath(floor t,t) of P) / '
       write (99,*) '          arclength(subpath(floor t,ceiling t) of P));'
       write (99,*) '    if alw_perpendicular:'
       write (99,*) '      a := 90;'
       write (99,*) '    else:'
       write (99,*) '      a := w[dirs[floor t],dirs[ceiling t]];'
       write (99,*) '    fi;'
       write (99,*) '    l := w[lengths[floor t],lengths[ceiling t]];'
       write (99,*) '  else:'
       write (99,*) '    if alw_perpendicular:'
       write (99,*) '      a := 90;'
       write (99,*) '    else:'
       write (99,*) '      a:= dirs[t];'
       write (99,*) '    fi; '
       write (99,*) '    l:=lengths[t];'
       write (99,*) '  fi;    '
       write (99,*) '  a := a + angle(thdir(P,t));    '
       write (99,*) '  thdraw (point t of P) -- '
       write (99,*) '    ((point t of P) + if par: 0.333 * fi l' &
                         //' * unitvector(dir(a)));'
       write (99,*) '  cas := cas + mojkrok;'
       write (99,*) '  par := not par;'
       write (99,*) '  exitif cas > dlzka + .3u + (krok / 3);  % for rounding' &
                       //' errors'
       write (99,*) 'endfor;'
       write (99,*) 'if S = 1: pickup PenC; draw P fi;'
       write (99,*) '   %pickup pencircle scaled 3pt;'
       write (99,*) '   %for i=0 upto li: draw point i of P; endfor;'
       write (99,*) '  enddef; '
!       write (99,*) 'endcode'

       write (99,*) '# Pour changer la couleur de l aire Sump'
       write (99,*) '    def a_sump (expr p) ='
       write (99,*) '      T:=identity;'
       write (99,*) '      thfill p withcolor (0.0, 0.0, 0.3);'
       write (99,*) '    enddef;'
       write (99,*) ' '
       write (99,*) '# Pour changer la couleur de l aire Water    '
       write (99,*) '    def a_water (expr p) ='
       write (99,*) '      T:=identity;'
       write (99,*) '      thfill p withcolor (0.0, 0.0, 0.1);'
       write (99,*) '    enddef;'
       write (99,*) ' '
       write (99,*) '# Northarrow more funnier !'
       write (99,*) '   def s_northarrow (expr rot) ='
       write (99,*) '    begingroup'
       write (99,*) '     interim defaultscale:=0.7; % scale your north arrow' &
                          //' here'
       write (99,*) '      T:=identity scaled defaultscale rotated -rot;'
       write (99,*) '      interim linecap:=squared;'
       write (99,*) '        interim linejoin:=rounded;'
       write (99,*) '     thfill (-.5cm,-.1cm)--(0,2.5cm)--(.5cm,-.1cm)--cycle;'
       write (99,*) '      pickup pencircle scaled (0.08cm * defaultscale);'
       write (99,*) '      thdraw (0,0)--(0,-2.5cm);'
       write (99,*) '      pickup pencircle scaled (0.16cm * defaultscale);'
       write (99,*) '      p:=(0.4cm,0.6cm);'
       write (99,*) '      thdraw ((p--(p yscaled -1)--(p xscaled -1)--' &
                           //'(p scaled -1)) shifted (0,-1.0cm));'
       write (99,*) '      label.rt(thTEX("mg") scaled 1.6, (.6cm,-1.6cm)) transformed T;'
       write (99,*) '    endgroup;'
       write (99,*) '  enddef; '
       write (99,*) ' '
       write (99,*) '# Echelle'    
       write (99,*) 'def s_scalebar (expr l, units, txt) ='
       write (99,*) '    begingroup'
       write (99,*) '      interim warningcheck:=0;'
       write (99,*) '      tmpl:=l / Scale * cm * units / 2;'
       write (99,*) '      tmpx:=l / Scale * cm * units / 5;'
       write (99,*) '      tmph:=5bp; % bar height'
       write (99,*) '    endgroup;'
       write (99,*) '    pickup PenC;'
       write (99,*) '    draw (-tmpl,0)--(tmpl,0)--(tmpl,-tmph)--' &
                         //'(-tmpl,-tmph)--cycle;'
       write (99,*) '    p:=(0,0)--(tmpx,0)--(tmpx,-tmph)--(0,-tmph)--cycle;'
       write (99,*) '    for i:=-2.5 step 2 until 2:'
       write (99,*) '      fill p shifted (i * tmpx,0);'
       write (99,*) '    endfor;'
       write (99,*) '    begingroup'
       write (99,*) '      interim labeloffset:=3.5bp;'
       write (99,*) '      for i:=0 step (l/5) until (l-1):'
       write (99,*) '        tmpx:=tmpl * (i * 2 / l - 1);'
       write (99,*) '        label.bot(thTEX(decimal (i)),(tmpx,-tmph));'
       write (99,*) '      endfor;'
       write (99,*) '      label.bot(thTEX(decimal (l) & "\thinspace" & txt)' &
                           //',(tmpl,-tmph));'
       write (99,*) '      label.top(thTEX("Echelle 1 : " & decimal' &
                           //' (Scale*100)),(0,0));'
       write (99,*) '    endgroup;'
       write (99,*) '  enddef;    '
       write (99,*) ' '
       write (99,*) '## Couleur des fleches d eau (NOT WORKING YET !)'
       write (99,*) '#def p_water-flow (expr p) ='
       write (99,*) '#    pickup PenC;'
       write (99,*) '#    draw p withcolor (0.1, 0.2, 0.8);'
       write (99,*) '#  enddef;'
       write (99,*) ' '                       
       write (99,*) '# Titre          '               
       write (99,*) '    code tex-map'
       if (comments) then
       write (99,*) '   % Output map title as determined by Therion 5.3 is' &
                        //' stored in cavename. '
       write (99,*) '   % It will be empty if there are multiple maps' &
                        //' selected for any one projection'
       write (99,*) '   % AND there are multiple source surveys identified' &
                        //' in the thconfig file '
       write (99,*) '   % ie Therion can not infer a unique title from the' &
                        //' input data given.'
       write (99,*) '   % This code allows you to define an output map title' &
                      //' {cavename} if it happens to be empty'
       endif
       write (99,*) ' '                  
       write (99,*) '  \edef\temp{\the\cavename}   % cavename from Therion'   
       write (99,*) '  \edef\nostring{}            % empty string' 
       write (99,*) '  \ifx\temp\nostring          % test if cavename is empty'
       write (99,*) '        % if empty reassign cavename to describe' &
                     //' selected maps as a group'
       write (99,*) '		\cavename={',trim(cavename),'} 		'
       write (99,*) '  \else % if not empty keep the value set by therion,' &
                      //' or assign an override cavename here'
       write (99,*) '  \fi'
       write (99,*) '  endcode  ' 
       write (99,*) ' ' 
       write (99,*) '## Pour changer la longeur et la profondeur   '
       write (99,*) '# code tex-map'
       write (99,*) '#      \topoteam{Your team.}'
       write (99,*) '#      \cavelength{1000\thinspace{}ft}'
       write (99,*) '#      \cavedepth{300\thinspace{}m}'
       write (99,*) '#  endcode                 '                                
       write (99,*) ' '
       write (99,*) '## Pour modifier le Header'
       write (99,*) '#code tex-map  '
       write (99,*) '#    \cavename={Gouffre Jean-Bernard}'
       write (99,*) '#    \topotitle={Topographie par}'
       write (99,*) '#    \cartotitle={Dessin par}'
       write (99,*) '#    \explotitle={Exploration par}  '
       write (99,*) '#  endcode'
       write (99,*) ' '
       write (99,*) '# Pour mettre 2 headers     '
       write (99,*) '# code tex-map'
       write (99,*) '#    \def\maplayout{'
       write (99,*) '#      \legendbox{0}{100}{NW}{\northarrow\scalebar}'
       write (99,*) '#      \legendbox{100}{100}{NW}{\scalebar}'
       write (99,*) '#    }'
       write (99,*) '#  endcode'
       write (99,*) ' '          
       write (99,*) '# Pour dessiner un cadre autour de la topo   '
       write (99,*) 'code tex-map'
       write (99,*) '  \framethickness=0.5mm'
       write (99,*) 'endcode'
       write (99,*) ' '
       write (99,*) '######################### '              
       write (99,*) ' '      
       write (99,*) 'endlayout'                                                  ! OK
       write (99,*) ' '
       
       if (comments) then   
       write (99,*) '# 3-EXPORTS   '                                                             
       endif
       write (99,*) 'export map -fmt xvi -layout xviexport -o ', &               ! OK
                     fnme(1:nfnme)//'-map.xvi'                                   ! OK
       write (99,*) 'export map -projection extended -fmt xvi &
                     -layout xviexport -o ', &                                   ! OK
                     fnme(1:nfnme)//'-coupe.xvi'                                 ! OK

       write (99,*) ' '                     
       write (99,*) 'export map -o ', fnme(1:nfnme)//'-plan.pdf' &
                     //' -layout my_layout'                                          ! OK
       write (99,*) 'export map -projection extended -layout my_layout' &         
                    //' -o ', fnme(1:nfnme)//'-coupe.pdf'                            ! OK
       write (99,*) 'export model -o ', fnme(1:nfnme)//'.lox'                    ! OK
       write (99,*) ' '       
       write (99,*) '# Export des fichiers ESRI'
       write (99,*) '#export map -proj plan -fmt esri -o ', fnme(1:nfnme), &
                    ' -layout my_layout'
       write (99,*) ' '
       write (99,*) '# Export des fichiers kml'
       write (99,*) '#export map -proj plan -fmt kml -o ', &
                     fnme(1:nfnme)//'.kml -layout my_layout'


       print*,'Fichier thconfig ecrit'
       ! Else write in english
       else
       
       write (99,*) 'encoding utf-8'                                             
       write (99,*) ' '
       write (99,*) ' '
       write (99,*) '# File written by tro2therion.f90 (Xavier Robert) '
       write (99,*) '# Based on the work of Roman Muñoz <tatel@euskalnet.net>' &
                      //' and Martin Gerbaux <martin.gerbaux@wanadoo.fr> '
       write (99,*) ' '
       write (99,*) '# Copyright (C) 2010 Xavier Robert' &
                     //' <xavier.robert***@***ird.fr>'
       write (99,*) '# This work is under the GPLv2'
       write (99,*) ' '
       write (99,*) ' '
       
       if (comments) then
       write (99,*) '# 1-SOURCES '
       write (99,*) '# The source line specify the file where data are'
       write (99,*) ' # ("mycave.th" is the file with surveyed datail' 
       write (99,*) ' # "input "nomcavite.th2" specify the drawing file'
       endif
       write (99,*) 'source ', fnme(1:nfnme)//'.th'                             
       write (99,*) '#source ', fnme(1:nfnme)//'.th2'                           
       
       write (99,*) ' '
       
       if (comments) then
       write (99,*) '# 2-LAYOUT   '                                             
       write (99,*) ' '
       write (99,*) '# Beginning of the Layout definition for xvi export'
       endif
       
       write (99,*) 'layout xviexport'
       
       if (comments) then
       write (99,*) '  # Scale of drawing (default is 1:200)'
       endif
       
       write (99,*) '  scale 1 1000'
       
       if (comments) then
       write (99,*) '  # grid size'
       endif
       write (99,*) '  grid-size 10 10 10 m'
       if (comments) then
       write (99,*) '  # Grid on the background'
       endif
       write (99,*) '  grid bottom'
       write (99,*) 'endlayout'
       
       if (comments) then
       write (99,*) '# End of the definition layout "xviexport" '
       endif
       
       write (99,*) ' '
       write (99,*) ' '
       write (99,*) 'layout my_layout'    
       write (99,*) ' '    
       
       if (comments) then   
       write (99,*) '  # Title  '                                           
       endif
       write (99,*) '  doc-title "', fnme(1:nfnme),'"'
       if (comments) then
       write (99,*) '  # Autor'       
       endif
       write (99,*) '  doc-author "Xavier Robert"'
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # "base-scale" is the scale we use to draw the survey'
       write (99,*) '  #  (see xviexport layout). Defaut is 1/200.'
       write (99,*) '  # If we use an other scale,, we have to uncomment this '
       write (99,*) '  # line and specify the drwing scale' 
       endif
       write (99,*) '  base-scale 1 1000'
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # "scale" : Scale we want for the final output '
       write (99,*) '  # to print the topography'
       write (99,*) '  # Be careful with the printer configuration'
       write (99,*) '  # The option "Fit in page" or similar'
       write (99,*) '  # will change the scale of the printed topography'
       endif
       write (99,*) ' scale 1 1000'                                             
       
       if (comments) then
       write (99,*) ' '
       write (99,*) ' # To rotate the survey if needed'
       endif
       write (99,*) ' #rotate 2.25'
       write (99,*) '# origin 12 22 0 m'                                        
       write (99,*) '# origin-label 100 K'                                     
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Background color, 85% white = 15% black'
       endif
       write (99,*) ' #color map-bg 85'                                          
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Topography color [RVB]'       
       endif
       write (99,*) ' color map-fg [100 100 80]'
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # To impose transparency for the topography' &
                        //' (We can thus see the lower tunnels)'
       write (99,*) '  # Option on by default, so not necessary'
       endif
       write (99,*) ' transparency on'                                          
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Percentage of transparency, only if transparency = on'
       endif
       write (99,*) ' opacity 75'                                                
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # To speak the langage of Shakespear...'
       endif
       write (99,*) ' language en'                                              
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Length of the scale bar (Here, 100 m)'
       endif
       write (99,*) '  scale-bar 100 m'      
       
       if (comments) then 
       write (99,*) ' '
       write (99,*) '  # To add a comment in the header,'
       endif
       write (99,*) ' map-comment "'//trim(cavename)//' plan, Samoëns, 74,' &
                      //' France"'          
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Print exploration stats (team/name). it is heavy'
       write (99,*) '  # if the cave is long with lots of explorers'
       endif
       write (99,*) '  statistics explo off'
       write (99,*) ' # statistics explo-length on'                             
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Print length and depth'
       endif
       write (99,*) ' statistics topo-length on'                              
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Print a Legend for the symbols we use'
       write (99,*) '  # It is posible to print only the symbols we use (here),'
       write (99,*) '  # or all of them, used or not with "legend all".'
       write (99,*) '  # "legend off" = no legende'
       endif
       write (99,*) ' legend on'                                                
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Default width legend is 14 cm'
       endif
       write (99,*) '  #  legend-width 14 cm'
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Position of the Header (title, authors,...)'
       write (99,*) '  # We indicate the coordinates of the point where we' &
                       //' want it'
       write (99,*) '  # 0 0, is bottom left'
       write (99,*) '  # 100 100, is top right'
       write (99,*) '  # The header has cardinal points: n, s, ne, sw, etc.'
       write (99,*) '  # We have to specify one of these points'
       endif
       write (99,*) ' map-header 0 00 nw'                                       
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Header back ground'
       endif
       write (99,*) ' map-header-bg off'
       write (99,*) ' '
       write (99,*) ' layers on'                                                
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Options to print the legs of the survey,'
       write (99,*) '  # stations points and stations names'       
       endif
       write (99,*) ' symbol-hide line survey'
       write (99,*) ' #symbol-hide point station DO NOT WORK !'
       write (99,*) ' debug station-names'        
       write (99,*) ' '       
       write (99,*) '  # Symbology: UIS, ASF (Australia) CCNP (USA) or'
       write (99,*) '  # SKB (tchecoslovakia) '
       write (99,*) '  #symbol-set UIS'       
       write (99,*) ' symbol-assign point station:temporary SKBB'               
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # If we want a grid in background  '     
       endif
       write (99,*) '# grid bottom'                                             
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # Step of the grid'      
       endif
       write (99,*) '# grid-size 100 100 100 m'
       if (comments) then                                 
       write (99,*) '  # If we do not want any grid:'
       endif
       write (99,*) '  grid off'        
       
       if (comments) then
       write (99,*) ' '                                                 
       write (99,*) '  # Print a copyright'
       endif
       write (99,*) '  statistics copyright 2'
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # "size", this is for the atlas. It is the dimensions' &
                     //' of the square occupy by the part of the topography.'
       write (99,*) '  # 15 x 20, is right for A4 paper'
       endif
       write (99,*) '#  size 15 20 cm'
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # In the Atlas, we can overlap 1 cm of each' &
                         //' neighbour page'
       endif
       write (99,*) '  overlap 1 cm'
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # To exclude pages from the Atlas:'
       endif       
       write (99,*) '# exclude-pages on 1,2,5' 
       
       if (comments) then
       write (99,*) ' '
       write (99,*) '  # "page-setup" : for map and atlas.'
       write (99,*) '  # Specification of the size of the paper:' &
                       //' 21 X 29,7 (A4)'
       write (99,*) '  # The printable surface is 17 X 28,2'
       write (99,*) '  # so, if we want a left margin of 3 (21-17-1=3)'
       write (99,*) '  # and a top margin of 1,5 (29,7-27,2-1=1,5)'
       write (99,*) '  # in centimeters  '
       endif
       write (99,*) '  #page-setup 21 29.7 17 27.2 3 1.5 cm  '
       
       write (99,*) ' '
       write (99,*) ' '
       write (99,*) ' '
       write (99,*) ' ######## Code Metapost to modify symbols ####### '              
       write (99,*) ' '
       write (99,*) '    # Modify the aspect of statistics'
       write (99,*) '  #code tex-map'
       write (99,*) '  #     \cavelength{1330\thinspace{}m} '
       write (99,*) '  #+ 150\thinspace{}m estimated}'
       write (99,*) '  #     \cavedepth{243\thinspace{}m}'
       write (99,*) '  #   endcode  '
       write (99,*) ' '  
       write (99,*) '    # to change blocs size'
       write (99,*) 'code metapost'
       write (99,*) '  def a_blocks (expr p) ='
       write (99,*) '    T:=identity;'
       write (99,*) '    pickup PenC;'
       write (99,*) '    path q, qq; q = bbox p;'
       write (99,*) '    picture tmp_pic; '
       write (99,*) '    uu := max(u, (xpart urcorner q - xpart llcorner q)' &
                       //'/100, (ypart urcorner q - ypart     llcorner q)/100);'
       write (99,*) '    tmp_pic := image('
       write (99,*) '      for i = xpart llcorner q step 1.0uu until xpart' &
                            //' urcorner q:'
       write (99,*) '        for j = ypart llcorner q step 1.0uu until ypart' &
                              //' urcorner q:'
       write (99,*) '          qq := punked (((-.3uu,-.3uu)--(.3uu,-.3uu)--' &
                               //'(.3uu,.3uu)--(-.3uu,.3uu)--cycle) '
       write (99,*) '         randomized (uu/2))'
       write (99,*) '               rotated uniformdeviate(360)' 
       write (99,*) '               shifted ((i,j) randomized 1.0uu);'
       write (99,*) '    if xpart (p intersectiontimes qq) < 0:'
       write (99,*) '      thclean qq;'
       write (99,*) '      thdraw qq;'
       write (99,*) '    fi;'
       write (99,*) '        endfor;  '
       write (99,*) '      endfor;'
       write (99,*) '    );'
       write (99,*) '    clip tmp_pic to p;'
       write (99,*) '    draw tmp_pic;'
       write (99,*) '  enddef;'
       write (99,*) ' '
       write (99,*) '#  To change sand aspects'
       write (99,*) 'def a_sands (expr p) ='
       write (99,*) '    T:=identity;'
       write (99,*) '    pickup PenC;'
       write (99,*) '    path q; q = bbox p;'
       write (99,*) '    picture tmp_pic;'
       write (99,*) '    tmp_pic := image('
       write (99,*) '      for i = xpart llcorner q step 0.1u until xpart' &
                            //' urcorner q:'
       write (99,*) '        for j = ypart llcorner q step 0.1u until ypart' &
                             //' urcorner q:'
       write (99,*) '          draw origin shifted ((i,j) randomized 0.1u)' &
                               //'  withpen PenC;'
       write (99,*) '        endfor;'
       write (99,*) '      endfor;'
       write (99,*) '    );'
       write (99,*) '    #clip tmp_pic to p;'
       write (99,*) '    draw tmp_pic;'
       write (99,*) '  enddef;'
       write (99,*) ' '
       write (99,*) '# To change pebbles aspects'
       write (99,*) 'def a_pebbles_SKBB (expr p) ='
       write (99,*) '  T:=identity;'
       write (99,*) '  pickup PenC;'
       write (99,*) '  path q, qq; q = bbox p;'
       write (99,*) '  picture tmp_pic; '
       write (99,*) '  tmp_pic := image('
       write (99,*) '    for i = xpart llcorner q step .1u until xpart' &
                          //' urcorner q:'
       write (99,*) '      for j = ypart llcorner q step .5u until ypart' &
                            //' urcorner q:'
       write (99,*) '        qq := (superellipse((.07u,0),(0,.03u),' &
                            //'(-.07u,0),(0,.-.03u),.75))'
       write (99,*) '%             randomized (u/25)'
       write (99,*) '             rotated uniformdeviate(360) '
       write (99,*) '             shifted ((i,j) randomized 0.27u);'
       write (99,*) '	if xpart (p intersectiontimes qq) < 0:'
       write (99,*) '	  thdraw qq;'
       write (99,*) '	fi;'
       write (99,*) '      endfor;  '
       write (99,*) '    endfor;'
       write (99,*) '  );'
       write (99,*) '  clip tmp_pic to p;'
       write (99,*) '  draw tmp_pic;'
       write (99,*) 'enddef;'
       write (99,*) ' '
       write (99,*) '# To change slopes aspects'
       write (99,*) '   def l_slope (expr P,S)(text Q) = '
       write (99,*) ' %show Q;'
       write (99,*) 'T:=identity;'
       write (99,*) 'numeric dirs[];'
       write (99,*) 'numeric lengths[];'
       write (99,*) 'for i=Q:'
       write (99,*) '  dirs[redpart i]:=greenpart i;'
       write (99,*) '  lengths[redpart i]:=bluepart i;'
       write (99,*) 'endfor;  '
       write (99,*) 'li:=length(P); % last'
       write (99,*) 'alw_perpendicular:=true;'
       write (99,*) 'for i=0 upto li:'
       write (99,*) '  if unknown dirs[i]: dirs[i]:=-1; '
       write (99,*) '  else: '
       write (99,*) '    if dirs[i]>-1:'
       write (99,*) '      dirs[i]:=((90-dirs[i]) - angle(thdir(P,i))) mod 360;' 
       write (99,*) '      alw_perpendicular:=false;'
       write (99,*) '    fi;'
       write (99,*) '  fi;'
       write (99,*) '  if unknown lengths[i]: lengths[i]:=-1; fi;'
       write (99,*) 'endfor;'
       write (99,*) '  %for i=0 upto li: show dirs[i]; endfor;'
       write (99,*) 'ni:=0; % next'
       write (99,*) 'pi:=0; % previous'
       write (99,*) 'for i=0 upto li:'
       write (99,*) '  d:=dirs[i];'
       write (99,*) '  if d=-1:'
       write (99,*) '    if (i=0) or (i=li):'
       write (99,*) '      dirs[i] := angle(thdir(P,i) rotated 90) mod 360;'
       write (99,*) 'pi:=i;'
       write (99,*) '    else:'
       write (99,*) '      if ni<=i:'
       write (99,*) '  for j=i upto li:'
       write (99,*) '          ni:=j;'
       write (99,*) '    exitif dirs[j]>-1;'
       write (99,*) '  endfor;'
       write (99,*) 'fi;'
       write (99,*) 'w:=arclength(subpath(pi,i) of P) / '
       write (99,*) '   arclength(subpath(pi,ni) of P);'
       write (99,*) 'dirs[i]:=w[dirs[pi],dirs[ni]];'
       write (99,*) '   %        if (dirs[i]-angle(thdir(P,i))) mod 360>180:'
       write (99,*) '   %          dirs[i]:=w[dirs[ni],dirs[pi]];'
       write (99,*) '   %	  message("*******");'
       write (99,*) '   %        fi;'
       write (99,*) '   fi;'
       write (99,*) '  else:'
       write (99,*) '    pi:=i;'
       write (99,*) '  fi;'
       write (99,*) 'endfor;'
       write (99,*) '  %for i=0 upto li: show dirs[i]; endfor;'
       write (99,*) 'ni:=0; % next'
       write (99,*) 'pi:=0; % previous'
       write (99,*) 'for i=0 upto li:'
       write (99,*) '  l:=lengths[i];'
       write (99,*) '  if l=-1:'
       write (99,*) '    if (i=0) or (i=li):'
       write (99,*) '      lengths[i] := 1cm; % should never happen!'
       write (99,*) 'thwarning("slope width at the end point not specified");'
       write (99,*) 'pi:=i;'
       write (99,*) '    else:'
       write (99,*) '      if ni<=i:'
       write (99,*) '  for j=i+1 upto li:'
       write (99,*) '          ni:=j;'
       write (99,*) '    exitif lengths[j]>-1;'
       write (99,*) '  endfor;  '
       write (99,*) 'fi;'
       write (99,*) 'w:=arclength(subpath(pi,i) of P) /   '
       write (99,*) '   arclength(subpath(pi,ni) of P);'
       write (99,*) 'lengths[i]:=w[lengths[pi],lengths[ni]];'
       write (99,*) 'pi:=i;'
       write (99,*) '    fi;'
       write (99,*) '  else:'
       write (99,*) '    pi:=i;'
       write (99,*) '  fi;'
       write (99,*) 'endfor;'
       write (99,*) '  % for i=0 upto li: show lengths[i]; endfor;'
       write (99,*) 'T:=identity;'
       write (99,*) 'boolean par;'
       write (99,*) 'cas := 0.3u;'
       write (99,*) 'krok := 0.7u;'
       write (99,*) 'dlzka := (arclength P);'
       write (99,*) 'if dlzka>3u: dlzka:=dlzka-0.6u fi;'
       write (99,*) 'mojkrok:=adjust_step(dlzka,1.4u) / 5;'
       write (99,*) 'pickup PenD;'
       write (99,*) 'par := false;' 
       write (99,*) 'forever:'
       write (99,*) '  t := arctime cas of P;'
       write (99,*) '  if t mod 1>0:  % not a key point'
       write (99,*) '    w := (arclength(subpath(floor t,t) of P) / '
       write (99,*) '          arclength(subpath(floor t,ceiling t) of P));'
       write (99,*) '    if alw_perpendicular:'
       write (99,*) '      a := 90;'
       write (99,*) '    else:'
       write (99,*) '      a := w[dirs[floor t],dirs[ceiling t]];'
       write (99,*) '    fi;'
       write (99,*) '    l := w[lengths[floor t],lengths[ceiling t]];'
       write (99,*) '  else:'
       write (99,*) '    if alw_perpendicular:'
       write (99,*) '      a := 90;'
       write (99,*) '    else:'
       write (99,*) '      a:= dirs[t];'
       write (99,*) '    fi; '
       write (99,*) '    l:=lengths[t];'
       write (99,*) '  fi;    '
       write (99,*) '  a := a + angle(thdir(P,t));    '
       write (99,*) '  thdraw (point t of P) -- '
       write (99,*) '    ((point t of P) + if par: 0.333 * fi l' &
                         //' * unitvector(dir(a)));'
       write (99,*) '  cas := cas + mojkrok;'
       write (99,*) '  par := not par;'
       write (99,*) '  exitif cas > dlzka + .3u + (krok / 3);  % for rounding' &
                       //' errors'
       write (99,*) 'endfor;'
       write (99,*) 'if S = 1: pickup PenC; draw P fi;'
       write (99,*) '   %pickup pencircle scaled 3pt;'
       write (99,*) '   %for i=0 upto li: draw point i of P; endfor;'
       write (99,*) '  enddef; '
!       write (99,*) 'endcode'

       write (99,*) '# To change color of Sump'
       write (99,*) '    def a_sump (expr p) ='
       write (99,*) '      T:=identity;'
       write (99,*) '      thfill p withcolor (0.0, 0.0, 0.3);'
       write (99,*) '    enddef;'
       write (99,*) ' '
       write (99,*) '#To change color of Water area    '
       write (99,*) '    def a_water (expr p) ='
       write (99,*) '      T:=identity;'
       write (99,*) '      thfill p withcolor (0.0, 0.0, 1.0);'
       write (99,*) '    enddef;'
       write (99,*) ' '
       write (99,*) '# Northarrow more funnier !'
       write (99,*) '   def s_northarrow (expr rot) ='
       write (99,*) '    begingroup'
       write (99,*) '      interim defaultscale:=0.7; % scale your north' &
                           //' arrow here'
       write (99,*) '      T:=identity scaled defaultscale rotated -rot;'
       write (99,*) '      interim linecap:=squared;'
       write (99,*) '        interim linejoin:=rounded;'
       write (99,*) '     thfill (-.5cm,-.1cm)--(0,2.5cm)--(.5cm,-.1cm)--cycle;'
       write (99,*) '      pickup pencircle scaled (0.08cm * defaultscale);'
       write (99,*) '      thdraw (0,0)--(0,-2.5cm);'
       write (99,*) '      pickup pencircle scaled (0.16cm * defaultscale);'
       write (99,*) '      p:=(0.4cm,0.6cm);'
       write (99,*) '      thdraw ((p--(p yscaled -1)--(p xscaled -1)--'&
                           //'(p scaled -1)) shifted (0,-1.0cm));'
       write (99,*) '      label.rt(thTEX("mg") scaled 1.6, (.6cm,-1.6cm)) transformed T;'
       write (99,*) '    endgroup;'
       write (99,*) '  enddef; '  
       write (99,*) '# Echelle'    
       write (99,*) 'def s_scalebar (expr l, units, txt) ='
       write (99,*) '    begingroup'
       write (99,*) '      interim warningcheck:=0;'
       write (99,*) '      tmpl:=l / Scale * cm * units / 2;'
       write (99,*) '      tmpx:=l / Scale * cm * units / 5;'
       write (99,*) '      tmph:=5bp; % bar height'
       write (99,*) '    endgroup;'
       write (99,*) '    pickup PenC;'
       write (99,*) '    draw (-tmpl,0)--(tmpl,0)--(tmpl,-tmph)--'&
                         //'(-tmpl,-tmph)--cycle;'
       write (99,*) '    p:=(0,0)--(tmpx,0)--(tmpx,-tmph)--(0,-tmph)--cycle;'
       write (99,*) '    for i:=-2.5 step 2 until 2:'
       write (99,*) '      fill p shifted (i * tmpx,0);'
       write (99,*) '    endfor;'
       write (99,*) '    begingroup'
       write (99,*) '      interim labeloffset:=3.5bp;'
       write (99,*) '      for i:=0 step (l/5) until (l-1):'
       write (99,*) '        tmpx:=tmpl * (i * 2 / l - 1);'
       write (99,*) '        label.bot(thTEX(decimal (i)),(tmpx,-tmph));'
       write (99,*) '      endfor;'
       write (99,*) '      label.bot(thTEX(decimal (l) & "\thinspace" & txt)' &
                           //',(tmpl,-tmph));'
       write (99,*) '      label.top(thTEX("Echelle 1 : " & decimal' &
                           //' (Scale*100)),(0,0));'
       write (99,*) '    endgroup;'
       write (99,*) '  enddef;    '
       write (99,*) ' '
       write (99,*) '## To change the color of water-flow (NOT WORKING YET !)'
       write (99,*) '#def p_water-flow (expr p) ='
       write (99,*) '#    pickup PenC;'
       write (99,*) '#    draw p withcolor (0.1, 0.2, 0.8);'
       write (99,*) '#  enddef;'
       write (99,*) ' ' 
       
       write (99,*) '    code tex-map'
       if (comments) then                      
       write (99,*) '# To change the Title          '               
       write (99,*) '   % Output map title as determined by Therion 5.3 is' &
                        //' stored in cavename. '
       write (99,*) '   % It will be empty if there are multiple maps' &
                        //' selected for any one projection'
       write (99,*) '   % AND there are multiple source surveys identified' &
                        //' in the thconfig file '
       write (99,*) '   % ie Therion can not infer a unique title from the' &
                        //' input data given.'
       write (99,*) '   % This code allows you to define an output map title' &
                      //' {cavename} if it happens to be empty'   
       endif
101    format ('  \edef\temp{\the\cavename}   % cavename from Therion')
!       write (99,*) '  \edef\\temp{\\the\cavename}   % cavename from Therion'   
	   write (99,101)
       write (99,*) '  \edef\nostring{}            % empty string' 
       write (99,*) '  \ifx\temp\nostring          % test if cavename is empty'
       write (99,*) '        % if empty reassign cavename to describe' &
                     //' selected maps as a group'
       write (99,*) '		\cavename={', trim(cavename), '} 		'
       write (99,*) '  \else % if not empty keep the value set by therion,' &
                      //' or assign an override cavename here'
       write (99,*) '  \fi'
       write (99,*) '  endcode  ' 
       write (99,*) ' ' 
       write (99,*) '## to change length and depth written   '
       write (99,*) '# code tex-map'
       write (99,*) '#      \topoteam{Your team.}'
       write (99,*) '#      \cavelength{1000\thinspace{}ft}'
       write (99,*) '#      \cavedepth{300\thinspace{}m}'
       write (99,*) '#  endcode                 '                                
       write (99,*) ' '
       write (99,*) '## To modify the Header'
       write (99,*) '#code tex-map  '
       write (99,*) '#    \cavename={Gouffre Jean-Bernard}'
       write (99,*) '#    \\topotitle={Topography by}'
       write (99,*) '#    \cartotitle={Drawing by}'
       write (99,*) '#    \explotitle={Exploration by}  '
       write (99,*) '#  endcode'
       write (99,*) ' '
       write (99,*) '# To write 2 headers     '
       write (99,*) '# code tex-map'
       write (99,*) '#    \def\maplayout{'
       write (99,*) '#      \legendbox{0}{100}{NW}{\northarrow\scalebar}'
       write (99,*) '#      \legendbox{100}{100}{NW}{\scalebar}'
       write (99,*) '#    }'
       write (99,*) '#  endcode'
       write (99,*) ' '          
       write (99,*) '# To draw a line around the map   '
       write (99,*) 'code tex-map'
       write (99,*) '  \framethickness=0.5mm'
       write (99,*) 'endcode'
       write (99,*) ' '
       write (99,*) '######################### '              
       write (99,*) ' '      
       write (99,*) 'endlayout'                                                  ! OK
       write (99,*) ' '                                                          ! OK
       write (99,*) 'export map -fmt xvi -layout xviexport -o ', &               ! OK
                     fnme(1:nfnme)//'-map.xvi'                                   ! OK
       write (99,*) 'export map -projection extended -fmt xvi' &
                     //' -layout xviexport -o ', &                                   ! OK
                     fnme(1:nfnme)//'-coupe.xvi'                                 ! OK

       write (99,*) ' '                     
       write (99,*) 'export map -o ', fnme(1:nfnme)//'-plan.pdf' &
                     //' -layout my_layout'                                          ! OK
       write (99,*) 'export map -projection extended -layout my_layout' &         
                    //' -o ', fnme(1:nfnme)//'-coupe.pdf'                            ! OK
       write (99,*) 'export model -o ', fnme(1:nfnme)//'.lox'                    ! OK
       write (99,*) ' '       
       write (99,*) '# Export ESRI files'
       write (99,*) 'export map -proj plan -fmt esri -o ', fnme(1:nfnme), &
                    ' -layout my_layout'
       write (99,*) ' '
       write (99,*) '# Export kml files'
       write (99,*) 'export map -proj plan -fmt kml -o ', &
                     fnme(1:nfnme)//'.kml -layout my_layout'
       
       print*,'thconfig file writen'       
       end if
       close (99)
       else
        print*,'No thconfig file written'
       end if                                                                    ! OK
!question : New file or to add to an other file ?
! A ECRIRE

! END program
       end                                                                       ! OK 