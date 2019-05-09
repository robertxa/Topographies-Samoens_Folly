Scale:=10.00;
MagDecl:=1.88;
GridConv:=1.60;
BaseScale:=10.00;
color HelpSymbolColor;
HelpSymbolColor := (0.8, 0.8, 0.8);
background:=(1.00000,1.00000,0.80000);
verbatimtex \input th_enc.tex etex;
%% therion source code
%%
%% therion.mp
%%
%% This file defines low-level MetaPost macros and variables required
%% for generation of map symbols
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: therion.mp,v $
%% $Revision: 1.3 $
%%
%% Copyright (C) 2000-2003 Martin Budaj
%%
%% Some macros are adapted from MPATTERN package of P. Bolek
%%
%% Some macros are used from MetaFun package of H. Hagen
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

%    This file defines low level macros used for map signatures in Therion.
%    Before loading this file set `Scale' variable to numeric value
%    representing denominator of the scale ratio. Internal variable 
%    `prologues' is set to 1 by this file. This module loads also 
%    symbol libraries.


tracingstats:=1;
prologues:=0;

if known Background: background:=Background fi;
%TrueScale:=Scale;

% @VARIABLE
% symbol_scale --
%
% <I>internal numeric</I>; in map symbol definitions used for scaling
% in <A HREF="#T">T</A> transformation; recommended
% values are 1 or 2.

%newinternal symbol_scale;
%symbol_scale := 1;

% @VARIABLE
% fill_only --
%
% <I>boolean</I>, used in <A HREF="#thdraw">thdraw</A> and
% <A HREF="#thpattfill">thpattfill</A> commands. When set to false, it has 
% no effect, when it is true, it supresses all drawing 
% commands with exception of <I>thpermanentfill</I>, so that only filled 
% areas are drawn

boolean fill_only, horiz_labels, transparency;
fill_only := false;
horiz_labels:=true;
transparency:=false;

string ATTR__id, ATTR__survey, ATTR__scrap, NorthDir;
boolean ATTR__scrap_centerline;
picture ATTR__text;
numeric ATTR__height;
boolean ATTR__elevation;
ATTR__scrap_centerline := false;
ATTR__height:=0;
ATTR__elevation:=false;

boolean ATTR__shotflag_splay;
ATTR__shotflag_splay:=false;
boolean ATTR__shotflag_duplicate;
ATTR__shotflag_duplicate:=false;
boolean ATTR__shotflag_approx;
ATTR__shotflag_approx:=false;
boolean ATTR__stationflag_splay;
ATTR__stationflag_splay:=false;


color label_fill_color, label_fill_color_tmp;
label_fill_color := (1.0, 1.0, 1.0);
def push_label_fill_color(expr r,g,b) =
  label_fill_color_tmp := label_fill_color;
  label_fill_color := (r,g,b);
enddef;
def pop_label_fill_color =
  label_fill_color := label_fill_color_tmp;
enddef;
def process_filledlabel(expr cent, rot) =
  begingroup;
    interim bboxmargin:=2.0bp;
    q:=((bbox lab) smoothed 2) rotatedaround (cent, rot);
    fill q withcolor label_fill_color;
    draw lab rotatedaround (cent, rot);
    write_circ_bbox(q);  % without corners smoothing it was enough to use
                         % write_bbox(q);
  endgroup;
enddef;




numeric area_border_errors;
area_border_errors = 0;

% @VARIABLE
% last_write --
%
% <I>numeric</I>; charcode of last figure which contained 
% <A HREF="#write_bbox">write_bbox</A> macro; this value is used by
% <A HREF="#close_file">close_file</A> macro. Initially set to -1.

numeric last_write;
last_write = -1;

% @VARIABLE
% strut_string --
%
% <I>string</I> containing combination of the "highest" and "lowest" character
% in used font; it's used by <A HREF="">free_text</A> macro.

%string strut_string;
%strut_string = "(È";

% @VARIABLE
% file_name --
%
% <I>string</I>, name of file, where <I>write_bbox</I> macro writes
% text clipping path

% @VARIABLE
% s ch --
%
% <I>string</I>, temporary string/char variables

string s, ch, file_name, bg_name, clip_name, lang, diff_pos, diff_neg,
     current_scrap, current_src;

% @VARIABLE
% u v w --
%
% <I>internal numeric variables</I> used as basic length units for drawing;
% they are set by <A HREF="#initialize">initialize</A> macro.
% <UL> <LI><I>u</I> -- normal unit decreasing with increasing scale
%      <LI><I>v</I> -- like <I>u</I>, but can increase drammaticaly
%            when some limit is encountered (to get effects like logarithmic
%            scale)
%      <LI><I>w</I> -- nearly constant at all scales
% </UL>

% @VARIABLE
% legend_scale --
%
% <I>numeric</I>, length of the longer side of signatures' legend box

newinternal legend_scale, u,v,w;

% @VARIABLE
% lab Lab --
%
% <I>picture</I>, in which are saved typeset labels

picture lab, Lab;

% @VARIABLE
% T --
%
% <I>transformation</I>, defines transformation function for transforming 
% every argument of <A HREF="#thdraw>thdraw</A> and <A HREF="#thfill>thfill</A>
% macros

transform T;

% @VARIABLE
% p,q --
%
% <I>path</I>, for saving temporary paths

path p,q;

% @MACRO
% initialize --
%
% initializes basic length units <A HREF="#u">(u,v,w)</A> and pens used 
% in map symbols according to scale. Five circular pens are defined:
% <UL><LI>PenA -- thick; for outlines
%    <LI>PenB, PenC -- thinner; for pits, symbols etc.
%    <LI>PenD -- thinnest; for fine details
%    <LI>PenX -- extra thick; not recommended for use
% </UL>

def fonts_setup (expr t,s,m,l,h) =
  write "\def\updown#1#2{\vbox{" &
        "\offinterlineskip" &
        "\setbox100=\hbox{#1}" &
        "\setbox101=\hbox{#2}" &
        "\ifnum\wd100>\wd101\hsize=\wd100\else\hsize=\wd101\fi" &
        "\centerline{\box100}\vskip4pt" &
        "\centerline{\box101}}}" &
        "\def\thlabel{\thnormalsize}" &
        "\def\thremark{\thsmallsize\si}" &
        "\def\thcomment{\thsmallsize}" &
        "\def\thentrance{\thsmallsize}" &
        "\def\thaltitude{\thsmallsize}" &
        "\def\thstationname{\thsmallsize}" &
        "\def\thdate{\thsmallsize}" &
        "\def\thheight{\thsmallsize}" &
        "\def\thheightpos{+\ignorespaces}" &
        "\def\thheightneg{-\ignorespaces}" &
        "\def\thframed{\thsmallsize}" &
        "\def\thwallaltitude{\thtinysize}"
  to "mptexpre.tex";
  write "\def\thtinysize{\size[" & decimal max(optical_zoom*t,0) & "]}" & 
        "\def\thsmallsize{\size[" & decimal max(optical_zoom*s,0) & "]}" & 
        "\def\thnormalsize{\size[" & decimal max(optical_zoom*m,0) & "]}" & 
        "\def\thlargesize{\size[" & decimal max(optical_zoom*l,0) & "]}" & 
        "\def\thhugesize{\size[" & decimal max(optical_zoom*h,0) & "]}" 
  to "mptexpre.tex";
  write EOF to "mptexpre.tex";
enddef;

def initialize (expr sc) =

  if unknown BaseScale: BaseScale = sc; fi;
  optical_zoom := BaseScale/sc;

    if BaseScale <= 1:                   % 1:100
        u:=14bp; v:=14bp; w:=12bp;
        fonts_setup(8,10,12,16,24);
    elseif BaseScale <= 2:               % 1:200
        u:=12bp; v:=12bp; w:=12bp;
        fonts_setup(7,8,10,14,20);
    elseif BaseScale <= 5:               % 1:500
        u:=10bp; v:=10bp; w:=12bp;
        fonts_setup(6,7,8,10,14);
    else:
        u:=7bp; v:=14bp; w:=10bp;
        fonts_setup(5,6,7,8,10);
    fi;
    
    u := optical_zoom * u;
    v := optical_zoom * v;
    w := optical_zoom * w;

    defaultscale := 0.8 * optical_zoom;

    def PenA = pencircle scaled (u/10) enddef;
    def PenB = pencircle scaled (0.7*u/10) enddef;
    def PenC = pencircle scaled (0.5*u/10) enddef;
    def PenD = pencircle scaled (0.35*u/10) enddef;
    def PenX = pencircle scaled (1.2*u/10) enddef;
    
    legend_scale := 3.14*u;
enddef;

% macro is expanded, we have to know all dimensions and pens before reading
% mpattern macros

initialize(Scale);

vardef thTEX primary s =
  write "verbatimtex \input th_enc.tex etex" to "mptextmp.mp";
  write "btex \mainfont "&s&" etex" to "mptextmp.mp";
  write EOF to "mptextmp.mp";
  scantokens "input mptextmp"
enddef;

% @MACRO
% inscale --
%
% zooms objects to scale specified in legend_scale variable (used in legend
% typesetting)

def inscale = 
    xscaled legend_scale yscaled (0.618*legend_scale)
enddef;

% @MACRO
% draw_legend_box --
%
% draws a legend bounding box and resets drawoptions() options 

def draw_legend_box =
    clip currentpicture to unitsquare inscale;
    drawoptions();
    pickup PenB;
    draw unitsquare inscale;
enddef;

def clean_legend_box =
  unfill unitsquare inscale;
enddef;

def legend_point (expr name) =
%  if substring (2,9) of name = "station":
%    scantokens(name)((0.5,0.5) inscale);
%  else:
    scantokens(name)((0.5,0.5) inscale,0,1,(0,0));
%  fi;
  draw_legend_box;
enddef;

def legend_line (expr name) =
  scantokens(name)((((-0.3,.5)..(.3,.7)..(.5,.3)..{dir 80}(1.3,.9)) inscale) 
                randomized 3mm);
  draw_legend_box;
enddef;

% legend_label
% legend_area
% legend_random

% @MACRO
% roundone --
%
% rounds <I>numeric value</I> to one decimal point

vardef roundone(expr n) =
%    round(10*n)/10
  n
enddef;

% @MACRO
% process_label --
%
% draws a label saved in <I>lab</I> picture variable and calls 
% <A HREF="#write_bbox">write_bbox</A> macro.


def process_label (expr cent, rot) =
  begingroup;
    interim bboxmargin:=0.8bp;
    q:=((bbox lab) smoothed 2) rotatedaround (cent, rot);
    draw lab rotatedaround (cent, rot);
    write_circ_bbox(q);  % without corners smoothing it was enough to use
                         % write_bbox(q);
  endgroup;
enddef;

% @MACRO
% process_uplabel --
%
% draws a label into semicircular box and writes clipping path to a file

def process_uplabel =
  begingroup;
    interim bboxmargin := 0.8 bp;
    q:=bbox lab;
  endgroup;
    alef:=.8-.02*(xpart lrcorner q - xpart llcorner q);
%    show alef;
    q:=alef[llcorner q,ulcorner q]{up} .. {down}alef[lrcorner q, urcorner q] --
        lrcorner q -- llcorner q -- cycle;
    draw lab;
    draw q;
    q:=reverse q;
    write_circ_bbox(q);
enddef;

% @MACRO
% process_downlabel --
%
% draws a label into down oriented semicircular box and writes
% clipping path to a file

def process_downlabel =
  begingroup;
    interim bboxmargin := 0.8 bp;
    q:=bbox lab;
  endgroup;
    alef:=1-(.8-.02*(xpart lrcorner q - xpart llcorner q));
    q:=alef[llcorner q,ulcorner q]{down} .. 
        {up}alef[lrcorner q, urcorner q] --
        urcorner q -- ulcorner q -- cycle;
    draw lab;
    draw q;
    write_circ_bbox(q);
enddef;

% @MACRO
% process_updownlabel --
%
% draws a label splitted into down and up oriented semicircular boxes and 
% writes clipping path to a file

def process_updownlabel =
  begingroup;
    interim bboxmargin := 0.8 bp;
    p:=bbox lab;
  endgroup;
    leftside:=xpart llcorner p;
    rightside:=xpart lrcorner p;
    draw (xpart llcorner p,.5[ypart llcorner p,ypart ulcorner p]) -- 
         (xpart lrcorner p,.5[ypart llcorner p,ypart ulcorner p]);
    alef:=1.05-.02*(xpart lrcorner p - xpart llcorner p);
%    alef:=.8-.02*(rightside-leftside);
    p:=alef[(leftside, ypart llcorner p),(leftside, ypart ulcorner p)]{up} .. 
       {down}alef[(rightside, ypart lrcorner p), (rightside, ypart urcorner p)]
        -- alef[(rightside, ypart urcorner p), (rightside, ypart lrcorner p)]{down}
        .. {up}alef[(leftside, ypart ulcorner p),(leftside, ypart llcorner p)]
        -- cycle;
%    p:=alef[llcorner p,ulcorner p]{up} .. {down}alef[lrcorner p, urcorner p] --
%        aleff[llcorner p,ulcorner p]{down} .. 
%        {up}aleff[lrcorner p, urcorner p] -- cycle;
    draw lab;
    draw p;
    p:=reverse p;
    write_circ_bbox(p);
enddef;

def process_updownlabel_OLD =
    p:=bbox lab;
    q:=bbox Lab;
    leftside:=min(xpart llcorner p, xpart ulcorner q);
    rightside:=max(xpart lrcorner p, xpart urcorner q);
    draw .5[(leftside, ypart llcorner p),(leftside, ypart ulcorner q)] -- 
         .5[(rightside,ypart lrcorner p),(rightside,ypart urcorner q)];
    alef:=.8-.02*(rightside-leftside);
    q:=alef[(leftside, ypart llcorner p),(leftside, ypart ulcorner p)]{up} .. 
       {down}alef[(rightside, ypart lrcorner p), (rightside, ypart urcorner p)]
        -- alef[(rightside, ypart urcorner q), (rightside, ypart lrcorner q)]{down}
        .. {up}alef[(leftside, ypart ulcorner q),(leftside, ypart llcorner q)]
        -- cycle;
    draw lab;
    draw Lab;
    draw q;
    q:=reverse q;
    write_circ_bbox(q);
enddef;

% @MACRO
% process_boxedlabel --
%
% draws a label into circular box and writes
% clipping path to a file

def process_boxedlabel =
    q:=bbox lab;
    draw lab;
    draw q;
    write_bbox(q);
enddef;

% @MACRO
% process_circledlabel --
%
% draws a label into circular box and writes
% clipping path to a file

def process_circledlabel =
  begingroup;
    interim bboxmargin := 0.4 bp;
    q:=bbox lab;
  endgroup;
    q:=point 0 of q .. point 1 of q .. point 2 of q .. point 3 of q .. cycle;
    draw lab;
    draw q;
    write_circ_bbox(q);
enddef;


% @MACRO
% write_bbox --
%
% Arguments:
%   <I>path</I> variable -- rectangular bounding box of a label;
%   assumptions: path is cyclic, counterclockwise oriented, with four points,
%   composed from linear segments;
%   see general <A HREF="#write_circ_bbox">write_circ_bbox</A> macro
% Results:
%   one file per figure which uses labels with a clipping path in pseudo-pdf 
%   format

def write_bbox (expr q) =
    file_name := jobname & "." & decimal(charcode) & "bbox";
    for i:=4 downto 0:
        s  :=  decimal(roundone(xpart point i of q)) & " " 
             & decimal(roundone(ypart point i of q)) 
             & if i=4: " m " else: " l" fi;
        write s to file_name;
    endfor;
    last_write := charcode;
enddef;

% @MACRO
% write_circ_bbox --
%
% Arguments:
%   <I>path</I> variable, only assumption is that <I>path</I> is cyclic
%   and counterclockwise oriented.
% Results:
%   one file per figure which uses labels with a clipping path in pseudo-pdf 
%   format

def write_circ_bbox expr q =
    file_name := jobname & "." & decimal(charcode) & "bbox";
    tmp:=length q;
    s :=  decimal(roundone(xpart point tmp of q)) & " " 
             & decimal(roundone(ypart point tmp of q)) & " m";
    write s to file_name;
    for i:=tmp downto 1:
        s :=  decimal(roundone(xpart precontrol i of q)) & " " 
             & decimal(roundone(ypart precontrol i of q)) & " "
             & decimal(roundone(xpart postcontrol i-1 of q)) & " " 
             & decimal(roundone(ypart postcontrol i-1 of q)) & " "
             & decimal(roundone(xpart point i-1 of q)) & " " 
             & decimal(roundone(ypart point i-1 of q)) & " c";
        write s to file_name;
    endfor;
    last_write := charcode;
enddef;

% @MACRO
% close_file --
%
% closes file with a clipping path; it's invoked by <I>endchar</I> macro

def close_file =
    if last_write=charcode:
        write EOF to jobname & "." & decimal(charcode) & "bbox";
    fi;
enddef;

% endchar should run close_file macro

extra_endfig := "close_file;";

% @MACRO
% thdraw --
%
% like plain MetaPost's <I>draw</I>, but draws a <I>path</I> transformed
% (rotated, scaled, shifted) to scrap's coordinates according T variable.
% (If <I>fill_only=false</I>)

def thdrawoptions(text t) =
  def _thop_ = t enddef
enddef;
thdrawoptions();

def thdraw expr p = 
  if not fill_only:
    addto currentpicture 
    if picture p: 
      also (p transformed T)
    else:
      doublepath (p transformed T) withpen currentpen 
    fi  
    _thop_  _op_
  else:
    addto currentpicture also nullpicture
  fi
enddef;

% @MACRO
% thfill --
%
% fills a <I>path</I> transformed
% (rotated, scaled, shifted) to scrap's coordinates according T variable.
% Filled areas are clipped (like most 
% other lines and points) with a clipping path around text labels.


def thfill expr c = 
    addto currentpicture contour (c transformed T) _thop_ _op_ 
enddef;

def thfilldraw expr c =
  if not fill_only:
    addto currentpicture contour (c transformed T) withpen currentpen _thop_ _op_ 
  else:
    addto currentpicture contour (c transformed T) _thop_ _op_ 
  fi
enddef;

def thunfill expr c = 
    thfill c withcolor background 
enddef;

def thundraw expr p = 
    thdraw p withcolor background 
enddef;

def thunfilldraw expr c = 
    thfilldraw c withcolor background 
enddef;

def thclean expr c =
  if transparency:
    thfill c withtransparentcolor tr_bg
  else:
    thunfill c
  fi;
enddef;

def thPatternFill (expr Path, Pattern) =
  T:=identity;
  thclean Path;
  thfill Path withpattern Pattern;
enddef;

%def thLegendPatternFill (expr Path, Pattern) =
%  T:=identity;
%  thfill Path withpattern Pattern;
%enddef;

% for drawarrow:

def _finarr text t =
  thdraw _apth t;
  thfilldraw arrowhead _apth  t
enddef;

% @MACRO
% thpermanentfill --
%
% Fills specified area with a solid color; this area is not affected by 
% text clipping path

%def thpermanentfill expr c = 
%    addto currentpicture contour (c transformed T) _thop_ _op_
%enddef;

let thpermanentfill = thfill;


primarydef p aligned al=
  p shifted (xpart al * xpart U, ypart al * ypart U)
enddef;

% macros for drawing scraps in upper and lower levels; filled lower scraps 
% require special treatment (MetaPost doesn't support non-continuous paths).
% We can't use one file for both, while PDF XObject has to be explicitely 
% filled or stroked. Second macro writes also pseudo-pdf code of a clipping 
% path for given scrap

boolean drawnext;
drawnext:=true;

def draw_upscrap (expr isout)(text t) =
  path q;
  for i=t:
    if (numeric i):
      if (i=1): drawnext:=true; else: drawnext:=false; fi;
    else:
      if drawnext: draw i withpen PenD; fi;
      if not known q: q:=i; else: q:=q -- i; fi;
    fi;
  endfor;
  if not cycle q: q:=q -- cycle; fi;
  if turningnumber q = 0: 
      thwarning("scrap outline intersects itself"); 
  fi;
  if isout=1:
    if turningnumber q > 0: q := reverse q; fi;
  else:
    if turningnumber q < 0: q := reverse q; fi;
  fi;
  addto bgfill contour q;
enddef;

% following macro writes noncontinuous PostScript path directly to EPS file
% (filled background and clipping path)

picture bgfill;
bgfill:=nullpicture;

def draw_downscrap =
  bg_name := jobname & "." & decimal(charcode) & "bg";
  clip_name := jobname & "." & decimal(charcode) & "clip";
  write "%!PS" to bg_name;
  write "%%BoundingBox: " & 
     decimal floor xpart llcorner bgfill & " " &
     decimal floor ypart llcorner bgfill & " " &
     decimal ceiling xpart urcorner bgfill & " " &
     decimal ceiling ypart urcorner bgfill 
     to bg_name;
  write "%%Page: 1 1" to bg_name;
  write "newpath" to bg_name;
  for qq within bgfill:
    q := pathpart qq;
    tmp:=length q;
    s := decimal(roundone(xpart point tmp of q)) & " " 
             & decimal(roundone(ypart point tmp of q)) & " m";
    write s & "oveto" to bg_name;
    write s to clip_name;
    for i:=tmp downto 1:
        s :=  decimal(roundone(xpart precontrol i of q)) & " " 
             & decimal(roundone(ypart precontrol i of q)) & " "
             & decimal(roundone(xpart postcontrol i-1 of q)) & " " 
             & decimal(roundone(ypart postcontrol i-1 of q)) & " "
             & decimal(roundone(xpart point i-1 of q)) & " " 
             & decimal(roundone(ypart point i-1 of q)) & " c";
        write s & "urveto" to bg_name;
        write s to clip_name;
    endfor;
  endfor;
  write "closepath fill" to bg_name;
  write "showpage" to bg_name;
  write "%%EOF" to bg_name;
  write EOF to bg_name;
  write EOF to clip_name;
  bgfill:=nullpicture;
enddef;



vardef buildcycle(text ll) =
  save ta_, tb_, k_, i_, pp_; path pp_[];
  k_=0;
  for q=ll: pp_[incr k_]=q; endfor
  i_=k_;
  for i=1 upto k_:
    (ta_[i], length pp_[i_]-tb_[i_]) =
      pp_[i] intersectiontimes reverse pp_[i_];
    if ta_[i]<0:
      message("[Error: area borders "& area_border[i] &" and "& 
         area_border[i_] &" don't intersect in scrap " & current_scrap &
         " (file " & current_src & ")]");
      area_border_errors := area_border_errors + 1;
    fi
    i_ := i;
  endfor
  for i=1 upto k_: subpath (ta_[i],tb_[i]) of pp_[i] .. endfor
    cycle
enddef;

vardef unitvector primary z = 
  if (z<>(0,0)):
    z/abs z 
  else:
    hide(thwarning("strange path"))
    (0,epsilon)
  fi
enddef;

def thwarning (expr m) = 
  message("[Warning: " & m & " in scrap " & current_scrap & "]");
enddef;

def check_area_borders = 
  if area_border_errors > 0:
  fi;
enddef;

%%%%%%%%%%%% Map symbols management %%%%%%%%%%%%%%%%%%%

def mapsymbol (expr name, set, warning) = 
  string s, stype, lname, ID;
  stype = substring (0,1) of name;
  lname = name & "_" & set;
  ID := "ID_" & lname;
  if (known scantokens ID):
    if stype = "a":
      s = "def " & name & " = scantokens(" & ditto & lname & ditto & ") enddef;";
    else:
      s = "let " & name & " = " & lname & ";";
    fi;
    scantokens s;
  elseif warning:  
    message("[Warning: undefined symbol `" & lname & "']");
  fi;
enddef;

%def hidesymbol (expr name) =
%  string s, stype;
%  stype = substring (0,1) of name;
%  if stype = "a":
%    s = "def " & name & " = scantokens(" & ditto & "a_empty" & ditto & ") enddef;";
%  else:
%    s = "vardef " & name & "@# (text t) = enddef;";
%  fi;
%  scantokens s;
%  write name to "missed.dat";
%enddef;

def initsymbol (expr name) =
  s := "ID_" & name & " = 1";
  scantokens s;
enddef;

%%%

% comment out groups in order to use 'save ATTR_*' appropriately

def beginfig(expr c) =
%  begingroup
  charcode:=c;
  clearxy; clearit; clearpen;
  pickup defaultpen;
  drawoptions();
  scantokens extra_beginfig;
  
  save smartll, smartur; 
  pair smartll[], smartur[]; 
  smart_count := 0;
enddef;

def endfig =
  scantokens extra_endfig;
  shipit;
%  endgroup
enddef;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% P. Bolek's MPATTERN package adapted and simplified for Therion
% (with the same user interface except of patterncolor)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

string Pname_, PXYsteps_;
string Pmatrix_;

numeric Pnum_; Pnum_=0;

def PmakeBB_=
   PBBox_ := "[" & decimal Plft_ & " " & decimal Plow_ & " "
   & decimal Prt_ & " " & decimal Pup_ & "]";
enddef;

def Psteps_=
   PXYsteps_ := decimal
     if unknown PXStep_: (Prt_-Plft_) else: PXStep_ fi 
   & ":" & decimal
     if unknown PYStep_: (Pup_-Plow_) else: PYStep_ fi;
enddef;
   
vardef Pfindbounds_=
   Plow_ = ypart (llcorner currentpicture);
   Plft_ = xpart (llcorner currentpicture);
   Pup_ = ypart (urcorner currentpicture);
   Prt_ = xpart (urcorner currentpicture);
   PmakeBB_;
enddef;

def PmakePattern_(expr name)=
  write decimal (Pnum_*epsilon) & ":"
    & jobname & "." & decimal charcode & ":"
    & PBBox_ & ":"
    & PXYsteps_ & ":"
    & Pmatrix_ 
  to "patterns.dat"
enddef;

% User interface macros

vardef patternbbox(expr a)(text b)=
   save Pi_, Pz_;
   numeric Pi_, Pz_[];
   if pair a:
      Plft_:=min(xpart(a),xpart(b)); Plow_:=min(ypart(a),ypart(b));
      Prt_:=max(xpart(a),xpart(b));  Pup_:=max(ypart(a),ypart(b));
   else:
      Pi_=1;
      for t=b:
	 Pz_[Pi_]=t;
	 Pi_:=Pi_+1;
      endfor;
      Plft_:=min(a,Pz_2);   Plow_:=min(Pz_1,Pz_3);
      Prt_:=max(a,Pz_2); Pup_:=max(Pz_1,Pz_3);
   fi;
   PmakeBB_;
enddef;

def beginpattern(suffix name)=
  numeric PXStep_, PYStep_;
  numeric Plow_, Plft_, Pup_, Prt_;
  string PBBox_;
  Pmatrix_:="[1 0 0 1 0 0]";
  Pname_:=str name;
  Pnum_:=Pnum_+1;
  beginfig(Pnum_+4000);
enddef;

def endpattern=
  if unknown PBBox_:
     Pfindbounds_;
  fi;
  endfig;
  Psteps_;
  PmakePattern_(Pname_);
  scantokens(Pname_ & "=Pnum_;");
enddef;

picture pattpict;
color patterncolor_;
patterncolor_ := black;

primarydef p withpattern s=
  if known s:

    hide(pattpict := image(draw (0,0)--(10,10));
      for i within pattpict:
        patterncolor_ := (redpart i, greenpart i, bluepart i);
      endfor;)

    p withcolor (epsilon, 10*epsilon, s*epsilon)
    if known mpversion:
      if scantokens(mpversion)>=1.000: 
        withprescript(decimal redpart   patterncolor_ & " " &
                      decimal greenpart patterncolor_ & " " &
                      decimal bluepart  patterncolor_ & " THsetpatterncolor")
      fi;
    fi;
  else:
    p withcolor (1,0,0);
    message("Warning: undefined pattern ignored");
  fi;  
enddef;
   
def patterntransform expr t=
   Pmatrix_ := "[" & decimal xxpart t
              & " " & decimal yxpart t
              & " " & decimal xypart t
              & " " & decimal yypart t
              & " " & decimal xpart t
              & " " & decimal ypart t & "]";
enddef;

def patternxstep expr t=
   PXStep_ = t;
enddef;

def patternystep expr t=
   PYStep_ = t;
enddef;

def patternstep text t=
   if pair t:
      PXStep_ = xpart t;
      PYStep_ = ypart t;
   else:
      (PXStep_,PYStep_)=t;
   fi;
enddef;

def patterncolor expr t=
  message("Warning: patterncolor not supported in Therion");
enddef;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% end of pattern macros
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% transparent rgb colors

numeric RGBnum; RGBnum=0;
string RGBname;

def def_transparent_rgb (suffix name)(expr r, g, b) =
  RGBnum := RGBnum+1;
  RGBname := str name;
  write decimal (RGBnum*epsilon) & ":"
    & decimal r & " "
    & decimal g & " "
    & decimal b 
  to "rgbcolors.dat";
  scantokens(RGBname & ":=RGBnum;");
enddef;

primarydef p withtransparentcolor s=
   p withcolor (epsilon, 12*epsilon, s*epsilon);
enddef;

def_transparent_rgb(tr_white, 1, 1, 1);
def_transparent_rgb(tr_blue, 0, 0, 1);
def_transparent_rgb(tr_black, 0, 0, 0);
def_transparent_rgb(tr_bg, 
               redpart background, greenpart background, bluepart background);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% some useful macros from H. Hagen's MetaFun package
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

vardef paired (expr d) =
  if pair d : d else : (d,d) fi
enddef ;

primarydef p randomshifted s = 
  begingroup ; save ss ; pair ss ; ss := paired(s) ; 
  p shifted (-.5xpart ss + uniformdeviate xpart ss,
             -.5ypart ss + uniformdeviate ypart ss) 
  endgroup 
enddef ; 

primarydef p randomized s =
  (if path p : 
    for i=0 upto length(p)-1 :
      ((point       i    of p) randomshifted s) .. controls 
      ((postcontrol i    of p) randomshifted s) and 
      ((precontrol (i+1) of p) randomshifted s) .. 
    endfor 
    if cycle p : 
      cycle 
    else :
      ((point length(p) of p) randomshifted s) 
    fi
  elseif pair p :
    p randomshifted s  
  elseif color p :
    if color s : 
      (uniformdeviate redpart   s * redpart   p,
       uniformdeviate greenpart s * greenpart p,
       uniformdeviate bluepart  s * bluepart  p)  
    elseif pair s : 
      ((xpart s + uniformdeviate (ypart s - xpart s)) * p)  
    else :  
      (uniformdeviate s * p)  
    fi 
  else :
    p + uniformdeviate s  
  fi)  
enddef ; 

primarydef p llmoved d =
  ((llcorner p) shifted (-xpart paired(d),-ypart paired(d)))
enddef ;

primarydef p lrmoved d =
  ((lrcorner p) shifted (+xpart paired(d),-ypart paired(d)))
enddef ;

primarydef p urmoved d =
  ((urcorner p) shifted (+xpart paired(d),+ypart paired(d)))
enddef ;

primarydef p ulmoved d =
  ((ulcorner p) shifted (-xpart paired(d),+ypart paired(d)))
enddef ;

primarydef p smoothed d =
  (p llmoved (-xpart paired(d),0) -- p lrmoved (-xpart paired(d),0) {right} .. 
   p lrmoved (0,-ypart paired(d)) -- p urmoved (0,-ypart paired(d)) {up}    .. 
   p urmoved (-xpart paired(d),0) -- p ulmoved (-xpart paired(d),0) {left}  ..
   p ulmoved (0,-ypart paired(d)) -- p llmoved (0,-ypart paired(d)) {down}  .. cycle) 
enddef ;

vardef punked primary p = 
  (point 0 of p for i=1 upto length(p)-1 : -- point i of p endfor 
   if cycle p : -- cycle else : -- point length(p) of p fi)  
enddef ;  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% end of MetaFun macros
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% we input map symbol definitions




%%%%% INPUT thPoint %%%%%


%% therion source code
%%
%% This file defines macros for point map symbols
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thPoint.mp,v $
%% $Revision: 1.8 $
%%
%% Copyright (C) 2000-2004 Martin Budaj
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

pair U;

def p_stalactite_UIS(expr pos,theta,sc,al) =
    U:=(.15u, .4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
    thdraw (0,.15u) -- (.15u,.4u);
enddef;

def p_stalagmite_UIS(expr pos,theta,sc,al) =
    U:=(.15u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
    thdraw (0,-.15u) -- (.15u,-.4u);
enddef;

def p_pillar_UIS(expr pos,theta,sc,al) =
    U:=(.15u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,.15u)--(0,-.15u);
    thdraw (-.15u,-.4u)--(0,-.15u)--(.15u,-.4u);
    thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
enddef;

def p_curtain_UIS(expr pos,theta,sc,al) =
    U:=(.15u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
    thdraw (0,.15u)--(0,0){dir 180}..(-.12u,-.11u)..{dir 0}(0,-.22u)--(0,-.4u);
enddef;

def p_helictite_UIS(expr pos,theta,sc,al) =
    U:=(.2u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,.4u)--(0,-.4u);
    p := (-.2u,.4u)---(-.2u,.1u){down}..{dir -10}(-.1u,0.02u)---origin;
    thdraw p;
    thdraw p reflectedabout (origin,(0,u)) reflectedabout (origin,(u,0));
enddef;

def p_sodastraw_UIS(expr pos,theta,sc,al) =
    U:=(.5u,.25u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,.2u)--(.5u,.2u);
    pickup PenD;
    thdraw (-.4u,.2u)--(-.4u,0);
    thdraw (-.12u,.2u)--(-.12u,-.25u);
    thdraw (.02u,.2u)--(.02u,-.1u);
    thdraw (.23u,.2u)--(.23u,-.19u);
    thdraw (.35u,.2u)--(.35u,-.15u);
enddef;

def p_crystal_UIS (expr pos,theta,sc,al)=
    U:=(.35u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := ((-.35*u,0)--(.35*u,0));
    thdraw p;
    thdraw p rotated (60);
    thdraw p rotated (120);
enddef;

def p_flowstone_UIS (expr pos,theta,sc,al)=
    U:=(.45u,.1u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := ((-.15*u,0)--(.15*u,0));
    thdraw p shifted (.3u,-.1u);
    thdraw p shifted (-.3u,-.1u);
    thdraw p shifted (0,.1u);
enddef;

def p_moonmilk_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.2u){up}..{dir -60}(-.18u,-.105u){dir 80}..
        {dir-80}(.18u,-.105u){dir 60}..{down}(.5u,-.2u);
enddef;

def p_wallcalcite_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.2u,-.2u)--(0,.1u)--(.2u,-.2u);
enddef;

def p_popcorn_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.2u)--(.5u,-.2u);
    pickup PenD;
    thdraw (-.3u,-.2u)--(-.3u,.1u);
    thdraw (0,-.2u)--(0,.1u);
    thdraw (.3u,-.2u)--(.3u,.1u);
    thfill fullcircle scaled .2u shifted (-.3u,.1u);
    thfill fullcircle scaled .2u shifted (0,.1u);
    thfill fullcircle scaled .2u shifted (.3u,.1u);
enddef;

def p_disk_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.2u,-.3u)--origin--(.2u,-.3u);
    p:=fullcircle scaled .3u shifted (0,.15u);
    thclean p;
    thdraw p;
enddef;

def p_gypsum_NSS (expr pos,theta,sc,al)=
    U:=(.25u,.25u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.25u,0)--(.25u,0);
    thdraw (0,-.25u)--(0,.25u);
enddef;

def p_aragonite_NSS (expr pos,theta,sc,al)=
    U:=(.3u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-.4u)--(0,.3u);
    thdraw (0,-.1u){dir 40}..{dir 5}(.3u,.08u);
    thdraw (0,-.1u){dir 140}..{dir 175}(-.3u,.08u);
    thdraw (0,.2u){dir 30}..{dir 5}(.25u,.3u);
    thdraw (0,.2u){dir 150}..{dir 175}(-.25u,.3u);
enddef;


def p_cavepearl_SKBB (expr pos,theta,sc,al)=
    U:=(.25u,.25u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=fullcircle scaled .25u shifted (0,.16u);
    thdraw p;
    thdraw p rotated 120;
    thdraw p rotated 240;
enddef;

def p_gypsumflower_NSS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
%    thdraw (.2u,0){left}..(0,.2u)..(.25u,.35u)..(.5u,0)..
%        (.1u,-.3u)..{dir 125}(-.5u,.2u);
    thdraw (.18u,0){left}..(0,.15u)..(.2u,.3u)..(.4u,0)..
        (.15u,-.28u)..{dir 120}(-.4u,.15u);
enddef;

def p_rimstonepool_ASF (expr pos,theta,sc,al)=
    U:=(.4u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := (-.4u,.2u){dir -70}..{dir 70}(.4u,.2u);
    thfill buildcycle(p,((.5u,.1u)--(-.5u,.1u)));
    thdraw p;
enddef;

def p_rimstonedam_ASF (expr pos,theta,sc,al)=
    U:=(.4u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,.2u){dir -70}..{dir 70}(.4u,.2u);
enddef;

def p_anastomosis_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.4u,-.2u)--(-.3u,-.3u)--(0,.3u)--(.1u,.2u);
    thdraw p;
    thdraw p shifted (.3u,0);
enddef;

def p_karren_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.3u){dir -85}..{dir 85}(-.32u,-.3u)..(-.28u,.3u){dir 85}..
        {dir -85}(-.12u,.3u)..(-.08u,-.3u){dir-85}..{dir 85}(.08u,-.3u)..
        {dir85}(.12u,.3u)..(.28u,.3u){dir -85}..(.32u,-.3u){dir -85}..
        {dir 85}(.5u,-.3u);
enddef;

def p_scallop_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-.4u){dir 125}..{dir 105}(-.2u,.1u){up}..
        {down}(.2u,.1u){dir -105}...{dir -125}(0,-.4u);
enddef;

def p_flute_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,.2u)--(.5u,.2u);
    thdraw (-.3u,.2u){dir -70}..{dir 70}(.3u,.2u);
enddef;

def p_raft_NSS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,.2u){dir -80}..(-.3u,-.2u)..origin..(.3u,.2u)..
        {dir -80}(.5u,-.2u);
enddef;

def p_raftcone_NSS (expr pos,theta,sc,al)=
    U:=(.3u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.4u)--(0,.4u)--(.3u,-.4u);
enddef;

def p_spring_SKBB (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,.2u){down}..(0,-.2u)..{up}(.3u,.2u);
enddef;

def p_sink_SKBB (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,-.2u){up}..(0,.2u)..{down}(.3u,-.2u);
enddef;

def p_narrowend_UIS (expr pos,theta,sc,al)=
    U:=(.1u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.1u,-.4u)--(-.1u,.4u);
    thdraw (.1u,-.4u)--(.1u,.4u);
enddef;

def p_lowend_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.1u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,-.1u)--(.4u,-.1u);
    thdraw (-.4u,.1u)--(.4u,.1u);
enddef;

def p_lowend_NSS (expr pos,theta,sc,al)=
    U:=(.4u,0);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,0)--(.4u,0);
enddef;

def p_flowstonechoke_NSS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.4u,-.4u){right}..{dir120}(-.2u,-.2u){dir -20}..{up}(0,0);
    thdraw p;
    thdraw p shifted (0,.2u);
    thdraw p reflectedabout (origin,down);
    thdraw p reflectedabout (origin,down) shifted (0,.2u);
enddef;

def p_breakdownchoke_NSS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.1u)--(-.15u,.05u)--(-.48u,.2u)--cycle;
    thdraw (-.2u,-.2u)--(.15u,-.18u)--(-.08u,.14u)--cycle;
    thdraw (.1u,0)--(.4u,-.1u)--(.5u,.2u)--(.1u,.2u)--cycle;
enddef;

def p_bedrock_ASF (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,0)--(.5u,0);
    thdraw (-.3u,0)--(-.3u,.2u);
    thdraw (.3u,0)--(.3u,-.2u);
enddef;

def p_sand_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenB;
    thdraw (0,.2u);
    thdraw (0,.2u) rotated 120;
    thdraw (0,.2u) rotated 240;
enddef;

def p_clay_SKBB (expr pos,theta,sc,al) =
    U:=(.3u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,0){up}..origin{down}..{up}(0.3u,0);
enddef;

def p_pebbles_UIS (expr pos,theta,sc,al)=
    U:=(.45u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=superellipse((.2u,0),(0,.1u),(-.2u,0),(0,.-.1u),.75);
    thdraw p rotated 20 shifted (0,.25u);
    thdraw p rotated -37 shifted (.25u,-.25u);
    thdraw p rotated -62 shifted (-.25u,-.25u);
enddef;

def p_debris_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.4u)--(0,-.22u)--(-.4u,-.1u)--cycle;
    thdraw (.2u,-.4u)--(.4u,-.1u)--(.1u,-.1u)--cycle;
    thdraw (-.1u,0)--(.2u,.3u)--(-.2u,.3u)--cycle;
enddef;

def p_blocks_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.5u)--(.3u,-.4u)--(-.17u,.2u)--cycle;
    thdraw (.25u,-.25u)--(.5u,-.15u)--(.3u,.5u)--(-.1u,.5u)--cycle;
    thdraw (-.27u,0)--(-.1u,.3u)--(-.5u,.35u)--cycle;
    pickup PenD;
    thdraw (-.5u,-.5u)--(-.1u,-.2u)--(-.17u,.2u);
    thdraw (-.1u,-.2u)--(.3u,-.4u);
    thdraw (.25u,-.25u)--(.3u,0)--(.2u,.2u)--(-.1u,.5u);
    thdraw (.3u,.5u)--(.2u,.2u);
    thdraw (.5u,-.15u)--(.3u,0);
enddef;

def p_water_UIS (expr pos,theta,sc,al)=
    U:=(.425u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenD;
    p:=fullcircle xscaled (.85u) yscaled (.6u);
    thfill p withpattern pattern_water_UIS;
    thdraw p;
enddef;

def p_ice_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := (0,.05u)--(0,.35u);
    thdraw p;
    thdraw p shifted (-.25u,-.3u);
    thdraw p shifted (.25u,-.3u);
    p := (-0.15u,.2u)--(0.15u,.2u);
    thdraw p;
    thdraw p shifted (-.25u,-.3u);
    thdraw p shifted (.25u,-.3u);
enddef;

def p_snow_SKBB (expr pos,theta,sc,al)=
    U:=(.35u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := origin--(0,.25*u);
    q := ((0,.35u)--(0,0.25u)--(0.1u,0.25u)) rotatedaround ((0,0.25u),45);
    thdraw p;
    thdraw p rotated (60);
    thdraw p rotated (120);
    thdraw p rotated (180);
    thdraw p rotated (240);
    thdraw p rotated (300);
    thdraw q;
    thdraw q rotated (60);
    thdraw q rotated (120);
    thdraw q rotated (180);
    thdraw q rotated (240);
    thdraw q rotated (300);
enddef;


def p_archeomaterial_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := fullcircle scaled .8u; 
    thdraw (-.5u,-.5u)--origin cutbefore p;
    thdraw (-.5u,.5u)--origin cutbefore p;
    thdraw origin--(.4u,0);
    thdraw p;
enddef;

def p_paleomaterial_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thfill (-.4u,-.2u)..(-.2u,-.08u)---(-.1u,.05u)---(0,.2u)..(-.03u,.4u)..
        (.2u,.3u)..(.35u,.25u)..(.2u,.2u)---origin---(-.1u,-.17u)..
        (-.08u,-.25u){dir -120}..(-.3u,-.23u)
        ..cycle;
enddef;

def p_guano_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,.2u){dir 40}..{down}(0,-.35u){up}..{dir-40}(.4u,.2u);
enddef;

def p_vegetabledebris_ASF (expr pos,theta,sc,al)=
    U:=(.38u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.3u)--(0,.3u);
    thdraw (0,-.3u)--(.3u,.3u);
    thdraw (-.25u,.13u)--(.38u,.13u);
    thdraw (-.38u,-.13u)--(.25u,-.13u);
enddef;

def p_root_ASF (expr pos,theta,sc,al)=
    U:=(.1u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.1u,-.5u)--(-.1u,.5u);
    p:=(-.1u,-.3u)--(.1u,-.5u);
    thdraw p;
    thdraw p shifted (0,.2u);
    thdraw p shifted (0,.4u);
enddef;

def p_entrance_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thfill (-.2u,-.5u)--(0,.5u)--(.2u,-.5u)--cycle;
enddef;

def p_waterflow_paleo_UIS (expr pos,theta,sc,al)=
    U:=(.2u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-u)--(0,u);
    thdraw halfcircle scaled .4u shifted (0,-.4u);
    p:=(-.15u,.6u)--(0,u)--(.15u,.6u)--cycle;
    thfill p;
    thdraw p;
enddef;

def p_gradient_UIS (expr pos,theta,sc,al)=
    U:=(.15u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-u)--(0,u);
    p:=(-.15u,.6u)--(0,u)--(.15u,.6u)--cycle;
    thfill p;
    thdraw p;
enddef;

def p_gradient_BCRA (expr pos,theta,sc,al)=
    U:=(.25u,0.7u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thfill (-.25u,-0.7u)--(0,.7u)--(.25u,-.7u)--cycle;
enddef;

% by Philip Schuchardt
def p_gradient_NSS (expr pos,theta,sc,al) =
  U:=(.7u, .6u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;

  thdraw (-.3u, -.5u) -- (-.7u, -.2u);
  thdraw (-.2u, -.4u) -- (-.4u, .3u);
  thdraw (0u, -.3u) -- (0u, .6u);
  thdraw (.3u, -.5u) -- (.7u, -.2u);
  thdraw (.2u, -.4u) -- (.4u, .3u);
enddef;

def p_waterflow_permanent_UIS (expr pos,theta,sc,al)=
    U:=(.15u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(0,.5u){down}..(.12u,.3u)..(-.15u,.15u)..(.13u,0)..
        (-.08u,-.2u)..{down}(0,-.5u);
    p:=p rotated 180;
    thdraw p;
    thdrawoptions();
    oldahlength:=ahlength; ahlength:=2.5pt*optical_zoom;
    thdraw arrowhead p;
    thfill arrowhead p;
    ahlength:=oldahlength;
enddef;

def p_waterflow_intermittent_UIS (expr pos,theta,sc,al)=
  thdrawoptions(dashed evenly scaled (.5 * optical_zoom));
  p_waterflow_permanent_UIS (pos,theta,sc,al);
  thdrawoptions();
enddef;

def p_airdraught_UIS (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,u)--(0,-0.8u);
	p:=(-.2u,.65u){dir 20}..{dir 90}(0,u);
	thdraw p;
	thdraw p reflectedabout (origin,(0,u));
	for i:=1 upto round(3+2*mlog(sc)/mlog 2):
	  thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
	endfor;
enddef;

def p_airdraught_winter_UIS (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,u)--(0,-0.8u);
  p:=(-.2u,.65u){dir 20}..{dir 90}(0,u);
  thdraw p;
  thdraw p reflectedabout (origin,(0,u));
  for i:=1 upto round(3+2*mlog(sc)/mlog 2):
    thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
  endfor;
  thclean fullcircle scaled 0.6u shifted (0,0.05u);
  thdraw (-0.1732u,-0.05u) -- (0.1732u,0.15u);
  thdraw (0.1732u,-0.05u) -- (-0.1732u,0.15u);
  thdraw (0,-0.15u) -- (0,0.25u);
enddef;

def p_airdraught_summer_UIS (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,u)--(0,-0.8u);
  p:=(-.2u,.65u){dir 20}..{dir 90}(0,u);
  thdraw p;
  thdraw p reflectedabout (origin,(0,u));
  for i:=1 upto round(3+2*mlog(sc)/mlog 2):
    thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
  endfor;
  thclean fullcircle scaled 0.6u shifted (0,0.05u);
  thdraw (-0.1732u,-0.05u) -- (0.1732u,0.15u);
  thdraw (0.1732u,-0.05u) -- (-0.1732u,0.15u);
  thdraw (0,-0.15u) -- (0,0.25u);
  thclean fullcircle scaled 0.3u shifted (0,0.05u);
  thdraw fullcircle scaled 0.2u shifted (0,0.05u);
enddef;


def p_station_fixed_ASF (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    pair z;
    z:=(0,.2u);
    thclean z -- (z rotated 120) -- (z rotated 240) -- cycle;
    thdraw z -- (z rotated 120) -- (z rotated 240) -- cycle;
    thdraw origin;
enddef;

def p_station_painted_SKBB (expr pos)=
    T:=identity shifted pos;
    pickup PenC;
    thclean fullcircle scaled 0.25u;
    thdraw fullcircle scaled 0.25u;
enddef;

def p_station_natural_ASF (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    thclean fullcircle scaled .3u;
    thdraw fullcircle scaled .3u;
    thdraw origin;
enddef;

def p_station_temporary_ASF (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    p:=(-.2u,0)--(.2u,0);
    thdraw p;
    thdraw p rotated 90;
    thclean fullcircle scaled .16u;
    pickup PenC;
    thdraw origin;
enddef;

let p_station_temporary_SKBB = p_station_painted_SKBB;

def p_steps_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.3u,.3u)--(-.3u,.1u)--(-.1u,.1u)--(-.1u,-.1u)--
           (.1u,-.1u)--(.1u,-.3u)--(.3u,-.3u);
enddef;

def p_fixedladder_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.15u,-.4u)--(-.15u,.4u);
    thdraw (.15u,-.4u)--(.15u,.4u);
    thdraw (-.15u,0)--(.15u,0);
    thdraw (-.15u,.2u)--(.15u,.2u);
    thdraw (-.15u,-.2u)--(.15u,-.2u);
enddef;

def p_ropeladder_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (.1u,-.4u)..(.2u,-.2u)..(.1u,.2u)..(.2u,.4u);
    thdraw (-.2u,-.4u)..(-.1u,-.2u)..(-.2u,.2u)..(-.1u,.4u);
    thdraw (-.2u,.2u)--(.1u,.2u);
    thdraw (-.15u,0)--(.15u,0);
    thdraw (-.1u,-.2u)--(.2u,-.2u);
enddef;

def p_bridge_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.3u,.2u)--(-.2u,.1u)--(.2u,.1u)--(.3u,.2u);
    thdraw (-.3u,-.2u)--(-.2u,-.1u)--(.2u,-.1u)--(.3u,-.2u);
enddef;

def p_noequipment_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    thfill (0,-.1u)--(-.05u,.3u)--(.05u,.3u)--cycle;
    thdraw (0,-.2u) withpen PenX;
enddef;

def p_anchor_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    thdraw fullcircle scaled .2u shifted (0.2u,0) withpen PenC;
    begingroup;
      interim linecap:=butt;
      thdraw (-.3u,0)--(.1u,0) withpen PenA;
    endgroup;
    thdraw (.1u,-.4u)--(.1u,.4u) withpen PenD;
enddef;

def p_traverse_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.25u,.05u)..(0,-.08u)..(.25u,.05u);
    pickup pencircle scaled .18u;
    thdraw (-.25u,.05u);
    thdraw (.25u,.05u);
enddef;

def p_rope_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.2u,.2u)..origin..(.1u,.1u)--(.1u,-.4u);
    pickup pencircle scaled .18u;
    thdraw (-.2u,.2u);
    thdraw (.1u,.1u);
enddef;

def p_camp_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .5u);
    T:=identity aligned al shifted pos;
    pickup PenC;
    thdraw (-.4u,-.4u)--(0,.5u)--(.4u,-.4u)--cycle;
    pickup PenD;
    thdraw (0,-.4u)--(0,.5u);
enddef;


def p_dig_UIS (expr pos,r,s,al) = 
    U:=(.4u, .5u);
    T:=identity aligned al shifted pos;
    thfill ((-.075u,-.5u){down} .. {up}(0.075u, -.5u) -- (0.075u, .15u) -- (0.3u, 0.15u) -- (0.3u, 0.5u) --
    (-.3u, .5u) -- (-.3u, .15u) -- (-.075u, .15u) -- cycle) rotated 45;
enddef;

def p_continuation_UIS(expr pos,theta,sc,al) =
  U:=(.15u,.3u);
  T:=identity aligned al shifted pos;
  pickup PenC;
  thdraw (-.1u,.2u){up}..{down}(.1u,.2u)..{down}(0,-.05u);
  pickup PenX;
  thdraw (0,-.2u);
enddef;

def p_station_SKBB(expr pos,mark,txt)(text flags) =
  T:=identity shifted pos;

  if mark=4: p_station_fixed(pos)
  elseif mark=3: p_station_natural(pos)
  elseif mark=2: p_station_painted(pos)
  elseif mark=1: p_station_temporary(pos)
  fi;
  
  path path_cave;
  path_cave = (-.3u,-.25u) -- (-.2u,-.25u){dir 135} .. (0, .25u) .. {dir 225}(.2u,-.25u) -- (.3u,-.25u);
  for i=flags:
    pickup PenX;
    if i="entrance":
%      thfill fullcircle scaled 1 cm withtransparentcolor tr_blue;
      thdraw path_cave;
%      p_label.urt(txt,pos+(0.4u,0),0,0);
      if not numeric txt:
        p_smartlabel(txt,pos);
      fi;
    elseif i="sink":
      thdraw path_cave cutbefore ((-u,0)--(u,0)) cutafter ((-u,0)--(u,0));
      pickup PenA;
      thdraw (0,-.45u) -- (0,.05u) withcolor blue;
      thdraw (-.15u,-.02u) -- (0,.05u) -- (.15u,-.02u) withcolor blue;
    elseif i="spring":
      thdraw path_cave cutbefore ((-u,0)--(u,0)) cutafter ((-u,0)--(u,0));
      pickup PenA;
      thdraw (0,-.45u) -- (0,.05u) withcolor blue;
      thdraw (-.15u,-.38u) -- (0,-.45u) -- (.15u,-.38u) withcolor blue;
    elseif i="doline":
      thdraw (-.5u,.05u){down}..(0,-0.6u)..{up}(.5u,.05u);
    elseif i="dig":
      thdraw (-.5u,.25u) -- (-.35u,.25u)--(-.23u,-.25u)--(.23u,-.25u)--(.35u,.25u)--(.5u,.25u);
    elseif substring(0,11) of i = "air-draught":
      pickup PenB;
      thdraw ((0,.11u){dir-120} ..{dir-70}(0,0) .. {dir-120}(0,-.11u));
      thdraw ((0,.11u){dir-120} ..{dir-70}(0,0) .. {dir-120}(0,-.11u)) shifted (.11u,0);
      thdraw ((0,.11u){dir-120} ..{dir-70}(0,0) .. {dir-120}(0,-.11u)) shifted (-.11u,0);
    elseif i="continuation":
      if picture(txt):
        picture ATTR__text;
        ATTR__text := txt;
      fi;
      begingroup;
        save T; transform T;
        p_continuation(pos+(0,.25u),0,1,(0,1));
      endgroup;
      if picture(txt):
        save ATTR__text;
      fi;
    elseif i="arch":
      thdraw (-.5u,-.25u)--(-.5u,.25u)--(.5u,.25u)--(.5u,-.25u)..(0,.2u)..cycle;
      thfill (-.5u,-.25u)--(-.5u,.25u)--(.5u,.25u)--(.5u,-.25u)..(0,.2u)..cycle;
    elseif i="overhang":
      thdraw (.2u,-.25u)--(-.2u,-.25u){up}..{right}(.2u,.25u);
    fi;
  endfor;
%  thdraw (0,0) withpen PenX withcolor red;
enddef;

def p_debug (expr col, pen, pos)=
    T:=identity shifted pos;
    thdraw origin withpen pencircle 
      scaled if pen=0: 2pt 
                 else: 4pt fi 
      withcolor if col=-2: (1,.85,0)
           elseif col=-1: black 
           elseif col=0: red 
           else: blue fi;
enddef;


def p_u(expr pos,theta,sc,al) =
  T:=identity shifted pos;
  thdraw origin withpen pencircle scaled 4pt withcolor red;
enddef;

def p_handrail_SKBB(expr pos,theta,sc,al) =
    tmph := 1 / Scale * 72 / 2.54;  % 1 m height
    U:=(.1u, tmph);
    pickup PenC;
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thdraw (0,0) -- (0,tmph);
    thdraw (0,tmph) withpen pencircle scaled .25u;    
enddef;

def p_viaferrata_SKBB(expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.15u,.15u)--(-.15u,.1u)--(.15u,.1u)--(.15u,.15u);
    thdraw (-.15u,-.05u)--(-.15u,-.1u)--(.15u,-.1u)--(.15u,-.05u);
enddef;

def p_stalagmites_UIS(expr pos,theta,sc,al) =
    U:=(.3u, .2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    for i=-1 upto 1:
        T:=identity aligned al rotated theta scaled (sc * 0.7) shifted (pos + (i * .3u, 0));
        thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
        thdraw (0,-.15u) -- (.15u,-.4u);
    endfor;
enddef;

def p_stalactites_UIS(expr pos,theta,sc,al) =
    U:=(.3u, .2u);
    pickup PenC;
    for i=-1 upto 1:
        T:=identity aligned al rotated theta scaled (sc * 0.7) shifted (pos + (i * .3u, 0));
        thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
        thdraw (0,.15u) -- (.15u,.4u);
    endfor;
enddef;

def p_gradient_SKBB (expr pos,theta,sc,al)=
    U:=(.3u,.6u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.6u)--(-.3u,.6u);
    thdraw (0,-.6u)--(0,-0.2u);
    thdraw (.3u,-.6u)--(.3u,.6u);
enddef;

def p_pillars_UIS(expr pos,theta,sc,al) =
    U:=(.3u, .2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    for i=-1 upto 1:
        T:=identity aligned al rotated theta scaled (sc * 0.7) shifted (pos + (i * .3u, 0));
        thdraw (0,.15u)--(0,-.15u);
        thdraw (-.15u,-.4u)--(0,-.15u)--(.15u,-.4u);
        thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
    endfor;
enddef;





%%%%% ENDINPUT thPoint %%%%%





%%%%% INPUT thLine %%%%%


%% therion source code
%%
%% This file defines macros for line symbols
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thLine.mp,v $
%% $Revision: 1.4 $
%%
%% Copyright (C) 2000 Martin Budaj
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

% some definitions

% adjust step according to the length of the path; return at least two steps

vardef adjust_step (expr len, s) =
  if s <= len/2: len / (floor(len / s))
  else: len/2 fi
enddef;

def mark_(expr p,t,l) =
  thdraw (point t of p) --
          ((point t of p) + l * unitvector(thdir(p,t) rotated 90));
enddef;

vardef thdir (expr p,t) =    % 1 * epsilon caused problems in scales < 1:1000
                             % n * epsilon is enough for scale 1:(n*1000)
  if arclength(p)=0:
    hide(thwarning("unable to determine direction on zero-length path"))
    (0,1)
  else:
%  ((direction t-100*epsilon of p) + (direction t+100*epsilon of p)) / 2
   postcontrol (t+1000*epsilon) of p - precontrol (t-1000*epsilon) of p
%  direction t of p
  fi
enddef;

% walls:

def l_wall_bedrock_UIS (expr P) = 
  T:=identity;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_sand_SKBB (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.1u);
  pickup PenB;  
  forever:
    t := arctime cas of P;
    thdraw ((point t of P) + (uniformdeviate 1) * .4u 
            * unitvector(thdir(P,t) rotated -90));
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
  pickup PenA;  
  thdraw P;
enddef;

def l_wall_pebbles_SKBB (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .35u);
  pickup PenC;
  q:=superellipse((.2u,0),(0,.1u),(-.2u,0),(0,.-.1u),.75);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q randomized (u/20) rotated (angle(thdir(P,t)) + (normaldeviate*40)) shifted point t of P;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

def l_wall_clay_SKBB (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .5u);
  pickup PenC;
  q := (-0.15u,0){up}..{down}origin..{up}(0.15u,0);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
  pickup PenA;  
  thdraw P;
enddef;

def l_wall_debris_SKBB (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .4u);
  pickup PenC;
%  q := ((-.1u,-.15u)--(.2,.03u)--(-.2u,.15u)--cycle) scaled 1.5;
  q := ((-.2u,-.1u)--(.2u,-.1u)--(0,.2u)--cycle) scaled 1.1;
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q randomized (u/10) rotated uniformdeviate (360) shifted point t of P;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

def l_wall_blocks_SKBB (expr P) = 
%  pickup PenD;
%  draw P withcolor red;

  T:=identity;
  cas := 0;
  dlzka := arclength P;
if dlzka > 0:
  mojkrok:=adjust_step(dlzka, 1.5u);
  pickup PenA;
  forever:
    t1 := arctime (cas + mojkrok*1/10) of P;
    t2 := arctime (cas + mojkrok*9/10) of P;
    q := ((point t1 of P) + .4u * unitvector(thdir(P,t1) rotated -90)) --
         (subpath (t1,t2) of P) --
         ((point t2 of P) + .4u * unitvector(thdir(P,t2) rotated -90));
    thdraw q randomized (u/6);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
fi;
enddef;

def l_wall_ice_SKBB (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .5u);
  pickup PenC;
  p := (-.1u,0)--(.1u,0);
  q := (0,-.1u)--(0,.1u);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw p shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    thdraw q shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
  pickup PenA;  
  thdraw P;
enddef;

def l_wall_underlying_UIS (expr P) = 
  T:=identity;
  pickup PenA;
  thdraw P dashed evenly scaled optical_zoom;
enddef;

def l_wall_unsurveyed_SKBB (expr P) = 
  T:=identity;
  pickup PenC;
  thdraw P;
enddef;

def l_wall_presumed_UIS (expr P) = 
  T:=identity;
  pickup PenA;
  thdraw P dashed evenly scaled (2*optical_zoom);
enddef;

% other line symbols

def l_pit_UIS (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.25u);
  pickup PenD;  
  forever:
    t := arctime cas of P;
    mark_ (P,t,0.2u);
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
  pickup PenC;  
  thdraw P;
enddef;

let l_floorstep_UIS = l_pit_UIS;

def l_overhang_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.3u);
  pickup PenC;
  t1:=0;
  forever:
    t := arctime (cas + mojkrok/2) of P;
    t2 := arctime (cas + mojkrok) of P;
    thfill (subpath (t1,t2) of P) -- 
      ((point t of P) + .3u * unitvector(thdir(P,t) rotated 90)) -- 
      cycle;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
    t1:=t2;
  endfor;
  thdraw P;
enddef;


def l_chimney_UIS (expr P) = 
  T:=identity;
  pickup PenC;
  thdraw P dashed evenly scaled optical_zoom;
enddef;

def l_ceilingstep_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);
  pickup PenC;
  forever:
    t1 := arctime (cas + mojkrok*1/5) of P;
    t  := arctime (cas + mojkrok/2) of P;
    t2 := arctime (cas + mojkrok*4/5) of P;
    thdraw (subpath (t1,t2) of P);
    mark_ (P,t,0.2u);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

def l_ceilingmeander_SKBB (expr P) =
  pair Pp;
  pair Pd;
  pair Pv;
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);
  pickup PenC;
  forever:
    t  := arctime (cas + mojkrok/2) of P;
    Pp := (point t of P);
    Pd := unitvector(thdir(P,t));
    Pv := Pd rotated 90;
    thdraw (Pp + 0.1u * Pv) --
          (Pp + 0.2u * Pv);
    thdraw (Pp + 0.2u * Pv + 0.2u * Pd) --
          (Pp + 0.2u * Pv - 0.2u * Pd);
    thdraw (Pp - 0.1u * Pv) --
          (Pp - 0.2u * Pv);
    thdraw (Pp - 0.2u * Pv + 0.2u * Pd) --
          (Pp - 0.2u * Pv - 0.2u * Pd);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;


%Bruce Mutton 2012.06.16 uses general code for l_ceilingmeander_SKBB defined in therion source code by Martin Budaj 5.3.9
% but ticks on outside (rock) side of lines 
def l_ceilingmeander_UIS (expr P) =
  pair Pp;
  pair Pd;
  pair Pv;
  T:=identity;
  cas := 0;                           % cursor to step along path
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);  % symbol length nudged to be multiple of path length
  pickup PenC;
  forever:
    t  := arctime (cas + mojkrok/2) of P;
    Pp := (point t of P);
    Pd := unitvector(thdir(P,t));
    Pv := Pd rotated 90;
    thdraw (Pp + 0.2u * Pv) --
          (Pp + 0.3u * Pv);              % add 0.1u to each moves ticks outside
    thdraw (Pp + 0.2u * Pv + 0.2u * Pd) --
          (Pp + 0.2u * Pv - 0.2u * Pd);  
    thdraw (Pp - 0.2u * Pv) --
          (Pp - 0.3u * Pv);              % subtract 0.1u to each moves ticks outside
    thdraw (Pp - 0.2u * Pv + 0.2u * Pd) --
          (Pp - 0.2u * Pv - 0.2u * Pd); 
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3);  % for rounding errors
  endfor;
enddef;

let l_ceilingmeander_NZSS = l_ceilingmeander_UIS;

%Bruce Mutton 2012.06.16 uses general code for l_ceilingstep_SKBB defined in therion source code by Martin Budaj 5.3.9
% but ticks on righthand (rock) side of line 
def l_ceilingstep_UIS (expr P) =
  T:=identity;
  cas := 0;                            % cursor to step along path
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);   % symbol length nudged to be multiple of path length
  pickup PenC;
  forever:
    t1 := arctime (cas + mojkrok*1/5) of P;
    t  := arctime (cas + mojkrok/2) of P;
    t2 := arctime (cas + mojkrok*4/5) of P;
    thdraw (subpath (t1,t2) of P);
    mark_ (P,t,-0.2u);                  % change sign to -0.2u
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

let l_ceilingstep_NZSS = l_ceilingstep_UIS;

%Bruce Mutton 2012.06.10 uses general code for l_pit_UIS defined in therion source code by Martin Budaj 5.3.9
% dots on righthand (rock) side of line spaced 0.2u, 0.2u same as floor-step ticks
def l_chimney_NZSS (expr P) = 
	T:=identity;
	cas := 0;                            % cursor to step along path
	dlzka := arclength P;
	mojkrok:=adjust_step(dlzka, 0.25u);  % symbol length nudged to be multiple of path length
	q:= (0.20u,-0.20u) -- (0.21u,-0.21u);         % dot

	pickup PenC;  %2nd thinnest pen
	forever:
	  t := arctime cas of P;
	thdraw q rotated angle(thdir(P,t)) shifted (point t of P ); % draw dots
	cas := cas + mojkrok;
	  exitif cas > dlzka + (mojkrok / 3); % for rounding errors
	endfor;
	pickup PenB;   %2nd thickest pen
	thdraw P;      %continuous line
enddef;

%Bruce Mutton 2010.06.20 uses general code and adjust_step defined in therion source code by Martin Budaj
%for Therion 5.3.8
def l_wall_presumed_NZSS (expr P) =
	T:=identity;
	cas := 0;                                 % cursor to step along path
	dlzka := arclength P;
	mojkrok:=adjust_step(dlzka, 1.5u);        % symbol length nudged to be multiple of path length
	q  := (-0.2u,-0.4u)--(0,0)--(0.2u,-0.4u); % define v shape 
	forever:
	  t1 := arctime (cas + mojkrok*1/5) of P;
	  t  := arctime (cas + mojkrok/2) of P;
	  t2 := arctime (cas + mojkrok*4/5) of P;
		pickup PenA;                          % thick
	thdraw (subpath (t1,t2) of P);          % dash
	  pickup PenC;                          % thin
	  thdraw q rotated angle(thdir(P,t)) shifted (point t of P ); % v shape

	  cas := cas + mojkrok;
	  exitif cas > dlzka - (2*mojkrok/3);     % for rounding errors
	endfor;
enddef;

def l_floormeander_SKBB (expr P) =
  pair Pp;
  pair Pd;
  pair Pv;
  pair PPp;
  pair PPd;
  pair PPv;

  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.25u);
  pickup PenC;
  forever:
    t := arctime cas of P;
    Pp := (point t of P);
    Pd := unitvector(thdir(P,t));
    Pv := Pd rotated 90;
    thdraw (Pp + 0.1u * Pv) --
          (Pp + 0.2u * Pv);
    thdraw (Pp - 0.1u * Pv) --
          (Pp - 0.2u * Pv);
    if cas > 0:
      thdraw (PPp + 0.2u * PPv) --
          (Pp + 0.2u * Pv);
      thdraw (PPp - 0.2u * PPv) --
          (Pp - 0.2u * Pv);
    fi;
    PPp := Pp;
    PPd := Pd;
    PPv := Pv;
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
enddef;    

boolean alw_perpendicular;

def l_slope_SKBB (expr P,S)(text Q) = 
%show Q;
  T:=identity;
  numeric dirs[];
  numeric lengths[];
  for i=Q:
    dirs[redpart i]:=greenpart i;
    lengths[redpart i]:=bluepart i;
  endfor;  


  li:=length(P); % last

  alw_perpendicular:=true;

  for i=0 upto li:
    if unknown dirs[i]: dirs[i]:=-1; 
    else: 
      if dirs[i]>-1:
        dirs[i]:=((90-dirs[i]) - angle(thdir(P,i))) mod 360; 
        alw_perpendicular:=false;
      fi;
    fi;
    if unknown lengths[i]: lengths[i]:=-1; fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    d:=dirs[i];
    if d=-1:
      if (i=0) or (i=li):
        dirs[i] := angle(thdir(P,i) rotated 90) mod 360;
	pi:=i;
      else:
        if ni<=i:
	  for j=i upto li:
            ni:=j;
	    exitif dirs[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) / 
	   arclength(subpath(pi,ni) of P);
	dirs[i]:=w[dirs[pi],dirs[ni]];
%        if (dirs[i]-angle(thdir(P,i))) mod 360>180:
%          dirs[i]:=w[dirs[ni],dirs[pi]];
%	  message("*******");
%        fi;
     fi;
    else:
      pi:=i;
    fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    l:=lengths[i];
    if l=-1:
      if (i=0) or (i=li):
        lengths[i] := 1cm; % should never happen!
	thwarning("slope width at the end point not specified");
	pi:=i;
      else:
        if ni<=i:
	  for j=i+1 upto li:
            ni:=j;
	    exitif lengths[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) / 
	   arclength(subpath(pi,ni) of P);
	lengths[i]:=w[lengths[pi],lengths[ni]];
	pi:=i;
      fi;
    else:
      pi:=i;
    fi;
  endfor;

% for i=0 upto li: show lengths[i]; endfor;

  T:=identity;
  boolean par;
  offset:=0;
  dlzka := (arclength P);
  if dlzka>3u: 
    offset := 0.3u;
  elseif dlzka>u:
    offset := 0.1u;
  fi;
  dlzka:=dlzka-2offset;
  cas := offset;
  mojkrok:=adjust_step(dlzka,1.4u) / 2;
  pickup PenD;
  par := false; 
  forever:
    t := arctime cas of P;
    if t mod 1>0:  % not a key point
      w := (arclength(subpath(floor t,t) of P) / 
            arclength(subpath(floor t,ceiling t) of P));
      if alw_perpendicular:
        a := 90;
      else:
        a := w[dirs[floor t],dirs[ceiling t]];
      fi;
      l := w[lengths[floor t],lengths[ceiling t]];
    else:
      if alw_perpendicular:
        a := 90;
      else:
        a:= dirs[t];
      fi; 
      l:=lengths[t];
    fi;
    
    a := a + angle(thdir(P,t));
    
    thdraw (point t of P) -- 
      ((point t of P) + if par: 0.333 * fi l * unitvector(dir(a)));
    cas := cas + mojkrok;
    par := not par;
    exitif cas > dlzka + offset + 0.1mm;  % for rounding errors
  endfor;
  if S = 1: pickup PenC; draw P fi;
%pickup pencircle scaled 3pt;
%for i=0 upto li: draw point i of P; endfor;
enddef;


def l_slope_BCRA (expr P,S)(text Q) = 
%show Q;
  T:=identity;
  numeric dirs[];
  numeric lengths[];
  for i=Q:
    dirs[redpart i]:=greenpart i;
    lengths[redpart i]:=bluepart i;
  endfor;  


  li:=length(P); % last

  alw_perpendicular:=true;

  for i=0 upto li:
    if unknown dirs[i]: dirs[i]:=-1; 
    else: 
      if dirs[i]>-1:
        dirs[i]:=((90-dirs[i]) - angle(thdir(P,i))) mod 360; 
        alw_perpendicular:=false;
      fi;
    fi;
    if unknown lengths[i]: lengths[i]:=-1; fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    d:=dirs[i];
    if d=-1:
      if (i=0) or (i=li):
        dirs[i] := angle(thdir(P,i) rotated 90) mod 360;
	pi:=i;
      else:
        if ni<=i:
	  for j=i upto li:
            ni:=j;
	    exitif dirs[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) / 
	   arclength(subpath(pi,ni) of P);
	dirs[i]:=w[dirs[pi],dirs[ni]];
%        if (dirs[i]-angle(thdir(P,i))) mod 360>180:
%          dirs[i]:=w[dirs[ni],dirs[pi]];
%	  message("*******");
%        fi;
     fi;
    else:
      pi:=i;
    fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    l:=lengths[i];
    if l=-1:
      if (i=0) or (i=li):
        lengths[i] := 1cm; % should never happen!
	thwarning("slope width at the end point not specified");
	pi:=i;
      else:
        if ni<=i:
	  for j=i+1 upto li:
            ni:=j;
	    exitif lengths[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) / 
	   arclength(subpath(pi,ni) of P);
	lengths[i]:=w[lengths[pi],lengths[ni]];
	pi:=i;
      fi;
    else:
      pi:=i;
    fi;
  endfor;

% for i=0 upto li: show lengths[i]; endfor;

  T:=identity;
  boolean par;
  offset:=0;
  dlzka := (arclength P);
  if dlzka>3u: 
    offset := 0.3u;
  elseif dlzka>u:
    offset := 0.1u;
  fi;
  dlzka:=dlzka-2offset;
  cas := offset;
  mojkrok:=adjust_step(dlzka,1.4u) / 2;
  pickup PenD;
  par := false; 
  forever:
    t := arctime cas of P;
    if t mod 1>0:  % not a key point
      w := (arclength(subpath(floor t,t) of P) / 
            arclength(subpath(floor t,ceiling t) of P));
      if alw_perpendicular:
        a := 90;
      else:
        a := w[dirs[floor t],dirs[ceiling t]];
      fi;
      l := w[lengths[floor t],lengths[ceiling t]];
    else:
      if alw_perpendicular:
        a := 90;
      else:
        a:= dirs[t];
      fi; 
      l:=lengths[t];
    fi;
    
    a := a + angle(thdir(P,t));
    
    if par:
      thfill (point t of P) + mojkrok/2.5 * unitvector(dir(a+90))-- 
        ((point t of P) + l * unitvector(dir(a))) --
        (point t of P) + mojkrok/2.5 * unitvector(dir(a-90)) -- cycle;
    fi;
    cas := cas + mojkrok;
    par := not par;
    exitif cas > dlzka + offset + 0.1mm;  % for rounding errors
  endfor;
enddef;


def l_contour_UIS(expr P)(text txt) =
  T:=identity;
  pickup PenD;
  thdraw P;
  for pnt=txt:
    if pnt=-2:
      mark_(P,arctime(arclength(P)/2) of P, 0.2u);
    elseif pnt>=0:
      mark_(P,pnt,0.2*u);
    fi;
    exitif pnt<0;
  endfor;
enddef;

def l_contour_SKBB(expr P)(text txt) =
  T:=identity;
  pickup PenD;
  thdraw P;
  for pnt=txt:
    if (pnt=-2) or (pnt=-1):
      mark_(P,arctime(arclength(P)/2) of P, 0.2u);
    elseif pnt>=0:
      mark_(P,pnt,0.2*u);
    fi;
    exitif pnt<0;
  endfor;
enddef;

def l_rockborder_UIS (expr P) = 
  T:=identity;
  pickup PenC;
  if cycle P: thclean P fi;
  thdraw P;
enddef;

def l_rockedge_UIS (expr P) = 
  T:=identity;
  pickup PenD;
  thdraw P;
enddef;

def l_border_visible_SKBB (expr Path) =
  T:=identity;
  pickup PenC;
  draw Path;
enddef;

def l_border_temporary_SKBB (expr Path) =
  T:=identity;
  pickup PenC;
  draw Path dashed evenly scaled optical_zoom;
enddef;

def l_flowstone_UIS (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .7u);
  if (cycle P) and (dlzka < 3.5u):   % make at least 5 curls on a cyclic path
    mojkrok := dlzka/5;
  fi;
  pickup PenC;  
  t1:=0;
  forever:
    t2 := arctime (cas + mojkrok) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 60)} ..
           {dir (angle(thdir(P,t2)) - 60)}(point t2 of P);
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
    t1:=t2;
  endfor;
enddef;


def l_moonmilk_UIS (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .3u);
  pickup PenC;  
  t1:=0;
  forever:
    t2 := arctime (cas + mojkrok) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 80)} ..
           {dir (angle(thdir(P,t2)) - 80)}(point t2 of P);
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
    t1:=t2;
  endfor;
enddef;


def l_survey_surface_SKBB (expr P) =
  T:=identity;
  thdrawoptions(dashed withdots scaled (0.2 * optical_zoom) withpen PenC);
  thdraw P;
  thdrawoptions();
enddef;

def l_survey_cave_SKBB (expr P) =
  T:=identity;
  pickup PenC;
  if ATTR__scrap_centerline:
    thdraw P;
  else:
    PolygonLine:=.8u;
    pair zz[];
    for t = 0 upto length P - 1:
      zz1 := point t of P;
      zz2 := point t+1 of P;
      if length (zz2-zz1) > 2*PolygonLine:
        thdraw zz1 -- zz1 + PolygonLine * unitvector(zz2 - zz1);
        thdraw zz2 -- zz2 + PolygonLine * unitvector(zz1 - zz2);
      else:
        thdraw zz1 -- zz2;
      fi;
    endfor;
  fi;
enddef;

def l_survey_cave_UIS (expr P) =
  T:=identity;
  pair zz[];
  pickup PenC;
  for t = 0 upto length P - 1:
    zz1 := point t of P;
    zz2 := point t+1 of P;
    draw zz1 -- zz2;
  endfor;
enddef;

def l_waterflow_permanent_UIS (expr Path) =
  path ppp;
  T:=identity;
  cas := 0;
  dlzka := arclength Path;
  mojkrok:=adjust_step(dlzka, 0.5u);
    pickup PenD;  
    vardef azim = 50 + 15*normaldeviate enddef;
    az1 := azim;
    sgn := 1;
    ppp := point 0 of Path;
    forever:
        t1 := arctime cas of Path;
        t2 := arctime (cas+mojkrok) of Path;
        if cas+1.1*mojkrok > dlzka:
            az2 := 0;
        else:
            az2 := azim;
        fi;
        d1 := angle(thdir(Path,t1)) + sgn * az1;
        d2 := angle(thdir(Path,t2)) - sgn * az2;
        ppp := ppp & (point t1 of Path){dir d1} .. {dir d2}(point t2 of Path);
        az1 := az2;
        sgn := -1 * sgn;
        cas := cas + mojkrok;
        exitif cas > dlzka + mojkrok/3;     % for rounding errors
    endfor;
%    drawarrow ppp;
    thdraw ppp;
    thdrawoptions();
    oldahlength:=ahlength;
    ahlength:=ahlength*optical_zoom;
    thdraw arrowhead ppp;
    thfill arrowhead ppp;
    ahlength:=oldahlength;
enddef;

def l_waterflow_intermittent_SKBB (expr Path) =
  thdrawoptions(dashed evenly scaled optical_zoom);
  l_waterflow_permanent_UIS (Path);
  thdrawoptions();
enddef;

def l_waterflow_conjectural_SKBB (expr Path) =
  thdrawoptions(dashed withdots scaled (0.5 * optical_zoom) withpen PenB);
  l_waterflow_permanent_UIS (Path);
  thdrawoptions();
enddef;

def l_invisible (expr P) = 
enddef;

def l_undefined (expr P) = 
  T:=identity;
  pickup PenC;
  thdraw P withcolor red;
  thwarning("undefined line symbol used");
enddef;

% Q = 0 -- no arrows
%     1 -- end
%     2 -- begin
%     3 -- both

def l_arrow_SKBB (expr P, Q) =
  T:=identity;
  pickup PenC;
  thdraw P;
  p := (-.1u,-.25u)--(0,0)--(.1u,-.25u);
  if odd Q:
    draw p rotated (angle(thdir(P,0))+90) shifted (point 0 of P);
  fi;
  if Q>1:
    draw p rotated (angle(thdir(P,length P))-90) 
         shifted (point infinity of P);
  fi;
enddef;

def l_mapconnection_SKBB (expr P) =
  thdrawoptions(dashed withdots scaled (0.5 * optical_zoom) withpen PenB);
  l_arrow_SKBB(P,3);
  thdrawoptions();
enddef;


def l_section_SKBB (expr P)(text txt) =
  T:=identity;
  path Q; Q = punked P;
  pickup PenC;
  for t = 0 upto length P - 1:
    pair zz[];
    zz1 := point t of P;
    zz2 := point t+1 of P;
    zz3 := postcontrol t of P;
    zz4 := precontrol t+1 of P;
    if (length(zz3-1/3[zz1,zz2]) > 0.1pt) or
       (length(zz4-2/3[zz1,zz2]) > 0.1pt):
      zz5 = whatever[zz1,zz2];
      (zz3-zz5) = whatever * (zz1-zz2) rotated 90;
      draw zz1--zz5;
      zz6 = whatever[zz1,zz2];
      (zz4-zz6) = whatever * (zz1-zz2) rotated 90;
      draw zz2--zz6;
    else:
      draw zz1--zz2;
    fi;
  endfor;
  for pnt=txt:
    if pnt=-1:
    else:
      T:=identity rotated angle(thdir(Q,pnt)) shifted (point pnt of Q);
      pickup PenC;
      thdraw (0,0)--(0,.8u);
      thdraw (-.1u,.55u)--(0,.8u)--(.1u,.55u);
    fi;
    exitif pnt=-1;
  endfor;
enddef;

let l_border_invisible = l_invisible;
let l_wall_invisible = l_invisible;

def l_debug (expr col, pen, P) =
  T:=identity;
  pickup if pen=0: PenD else: PenB fi;
  thdraw P 
    withcolor if col=-2: (1,.85,0)
          elseif col=-1: black 
           elseif col=0: red 
                   else: blue fi;
enddef;


def l_u (expr P) =
  T:=identity;
  pickup PenA;
  thdraw P withcolor red;
enddef;


def l_gradient_UIS (expr P) =
  T:=identity;
  pickup PenC;
  thdraw P;
  p:=(-.15u,-.4u)--(0,0)--(.15u,-.4u)--cycle;
  thfill (p rotated (angle(thdir(P,length P))-90) 
         shifted (point infinity of P));
  thdraw (p rotated (angle(thdir(P,length P))-90) 
         shifted (point infinity of P));
enddef;

def l_gradient_BCRA (expr P) =
  T:=identity;
  pickup PenC;
  for t = 0 upto length P - 1:
    pair zz[];
    zz1 := point t of P;
    zz2 := point t+1 of P;
    zz3 := unitvector(zz2 - zz1);
    thfill zz1 + u/3 * zz3 + .25u * (zz3 rotated 90) --
           zz2 - u/3 * zz3 --
	   zz1 + u/3 * zz3 + .25u * (zz3 rotated -90) -- cycle;
  endfor;
enddef;


def l_rope_SKBB (expr P,exact) =
  T:=identity;
  pickup PenC;
  if exact:
    draw P;
  else:
    d:=0.5u;
    for i:=0 upto (length P - 2):
      x1 := xpart point i of P;
      y1 := ypart point i of P;
      x2 := xpart point i+1 of P;
      y2 := ypart point i+1 of P;
    
      dx1:=x1; dy1:=y1; x1:=0; y1:=0; x2:=x2-dx1; y2:=y2-dy1;
      if y2 > y1:
        y3 := y1 - d;
        x3 := x1 + (x2-x1)*sqrt(d)/(sqrt(d)+sqrt(y2-y1+d));
      else:
        y3 := y2 - d;
        x3 := x1 + (x2-x1)*sqrt(y1-y2+d)/(sqrt(d)+sqrt(y1-y2+d));
      fi;
      numeric a,b,c;
      a*x1/10*x1 + b/10*x1 + c/10 = y1/10;
      a*x2/10*x2 + b/10*x2 + c/10 = y2/10;
      a*x3/10*x3 + b/10*x3 + c/10 = y3/10;
      draw (x1+dx1,y1+dy1)
      for t = x1 step (x2-x1)/20 until x2+10*epsilon:
        -- (t+dx1,a*t*t+b*t+c+dy1)
      endfor;
    endfor;
    pair x;
    x = point (length P)-1 of P + whatewer * down;
    x = point (length P) of P + whatever * right;
    draw point (length P)-1 of P -- x;
%    thdraw point length P of P withpen pencircle scaled 0.3u withcolor red;
  fi;
  for i:=0 upto length P if not exact: -1 fi:
    thdraw point i of P withpen pencircle scaled 0.3u;
  endfor;
enddef;

def l_border_presumed_SKBB (expr Path) =
  T:=identity;
  pickup PenC;
  draw Path dashed evenly scaled (0.25 * optical_zoom);
enddef;

def l_steps_SKBB (expr P) =
 if known ATTR_c: c := scantokens ATTR_c; else: c := 2; fi;
 if ATTR__elevation:
   if (c < 2):
     thwarning("Invalid stairs definition (c<2)");
     pickup PenA;
     draw P withcolor red;
   else:
     path PP;
     if (ypart point 0 of P) < (ypart point length P of P):
       PP := P;
     else:
       PP := reverse P;
     fi;
     path p;     
     for j:=0 upto ((length PP) - 1):
       p := (point j of PP) -- (point (j + 1) of PP);
       c := ceiling(abs((ypart point 0 of p) - (ypart point length p of p)) / (0.2 / Scale * 72 / 2.54));  % 20 cm height
       if (c < 2): c:=2 fi;
       pair cp;
       cp = point length p of p - point 0 of p;
       dx := (xpart cp) / c;
       dy := (ypart cp) / c;
       cp := point 0 of p;
       for i:= 0 upto c - 1:
         l_border_visible(cp -- cp + (0,dy) -- cp + (dx,dy));
         cp := cp + (dx, dy);
       endfor;
       %draw P;
     endfor;
   fi;
 else:
   if known ATTR_l: l := scantokens ATTR_l; else: l := (length(P)-2)/2; fi;
   if ((length(P) < 4) or (c < 2)) or ((odd length P) and (not known ATTR_l)):
     thwarning("Invalid stairs definition" if c<2: &" (c<2)" fi);
     pickup PenA;
     draw P withcolor red;
   else:
     path p, q;
     p = subpath (1, 1+l) of P;
     q = reverse subpath (l+2, length(P)) of P;
     lp := arclength(p);
     lq := arclength(q);
     for i=1 upto c:
       l_border_visible(point(arctime ((i-1)/(c-1)*lp) of p) of p -- point(arctime ((i-1)/(c-1)*lq) of q) of q);
     endfor;
     l_border_visible(p);
     l_border_visible(q);
     drawoptions(withcolor 0.3*white);
     %p_label(decimal c, point 0.5 of P, 0, 6);
     drawoptions();
   fi;
 fi;
enddef;

def l_handrail_SKBB (expr P) = 
    if ATTR__elevation:
      T:=identity;
      cas := 0;
      dlzka := arclength P;
      mojkrok:=adjust_step(dlzka, 1u);
      pickup PenD;  
      pair tmppoint;
      tmph := 1 / Scale * 72 / 2.54;  % 1 m height
      tmppoint:=(point 0 of P) +(0,tmph);
      forever:
        t := arctime cas of P;
        draw point t of P -- (point t of P)+(0,tmph) withpen PenD;
        if cas > 0:
          draw tmppoint -- (point t of P)+(0,tmph) withpen PenC;
          tmppoint := (point t of P)+(0,tmph);
        fi;
        cas := cas + mojkrok;
        exitif cas > dlzka + (mojkrok / 3); % for rounding errors
      endfor;
    else:
      T:=identity;
      cas := 0;
      dlzka := arclength P;
      mojkrok:=adjust_step(dlzka, u);
      pickup PenD;  
      forever:
        t := arctime cas of P;
        thdraw point t of P withpen pencircle scaled .25u;
        cas := cas + mojkrok;
        exitif cas > dlzka + (mojkrok / 3); % for rounding errors
      endfor;
      pickup PenC;  
      thdraw P;
    fi;
enddef;

def l_fixedladder_SKBB (expr P) = 
  pickup PenD;
  draw P withcolor red;
enddef;

def l_ropeladder_SKBB (expr P) = 
  pickup PenD;
  draw P withcolor red;
enddef;

def l_viaferrata_SKBB (expr P) = 
  pickup PenD;
  draw P withcolor red;
enddef;




%%%%% ENDINPUT thLine %%%%%





%%%%% INPUT thArea %%%%%


%% therion source code
%%
%% This file defines tiling patterns
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thPatterns.mp,v $
%% $Revision: 1.6 $
%%
%% Copyright (C) 2000-2004 Martin Budaj
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

if unknown a_water_UIS: else: endinput fi;

% patterns

beginpattern(pattern_water_UIS);
    draw origin--10up withpen pensquare scaled (0.02u);
    patternxstep(.18u);
    patterntransform(identity rotated 45);
endpattern;

beginpattern(pattern_sump_UIS);
    draw origin--(0,.25u) withpen pensquare scaled (0.02u);
    draw origin--(.25u,0) withpen pensquare scaled (0.02u);
    patterntransform(identity rotated 45);
endpattern;

beginpattern(pattern_sand_UIS);
    pickup PenC;
    draw (0.2u,.3u);
    draw (0.35u,.7u);
    draw (0.6u,.5u);
    draw (0.8u,.1u);    
endpattern;

beginpattern(pattern_debris_SKBB);
    pickup PenC;
    p:=(-.15u,0)--(.15u,0);
    draw p rotated -40 shifted (.2u,.3u);
    draw p rotated 70 shifted (.9u,1.5u);
    draw p rotated 20 shifted (1.5u,.8u);
%    draw p rotated 95 shifted (.9u,.8u);
endpattern;


beginpattern(pattern_moonmilk_SKBB);
    pickup PenC;
    p:=(-.5u,0){down} .. {up}(-.1666u,0){down}..
        {up}(.1666u,0){down} .. {up}(.5u,0);
    draw p;
    draw p shifted (0.5u,0.3u);
    patternxstep(1.0u);
    patternystep(0.6u);
endpattern;


beginpattern(pattern_flowstone_ASF);
    pickup PenC;
    p:=(-.35u,0){dir -60} .. {dir 60}(0.35u,0);
    draw p;
    draw p shifted (0.35u,0.4u);
    patternxstep(u);
    patternystep(0.8u);
endpattern;


beginpattern(pattern_empty);
  patternbbox(0,0,10,10);
  patternstep(10,10);
endpattern;

% symbols

def a_water_UIS (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_water_UIS;
enddef;

def a_sump_UIS (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_sump_UIS;
enddef;


def a_flowstone_ASF (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_flowstone_ASF;
enddef;


def a_moonmilk_SKBB (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_moonmilk_SKBB;
enddef;



def a_sand_UIS (expr p) =
  T:=identity;
%  thclean p;
  pickup PenC;
  path q; q = bbox p;
  picture tmp_pic; 
  tmp_pic := image(
    for i = xpart llcorner q step 1u until xpart urcorner q:
      for j = ypart llcorner q step 1u until ypart urcorner q:
        draw origin shifted ((i,j) randomized 0.7u) withpen PenC;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_debris_UIS (expr Path) =
  T:=identity;
%  thclean Path;
  thfill Path withpattern pattern_debris_SKBB;
enddef;


def a_bedrock_SKBB (expr Path) =
  T:=identity;
  thclean Path;
enddef;


% used to export centerline LRUD envelope for maps created from surveys

def a_dimensions_SKBB (expr Path) =
  T:=identity;
  thclean Path;
enddef;


def a_debris_SKBB (expr p) =
  T:=identity;
%  thclean p;
  pickup PenC;
  path q; q = bbox p;
  picture tmp_pic; 
  tmp_pic := image(
    for i = xpart llcorner q step 1u until xpart urcorner q:
      for j = ypart llcorner q step 1u until ypart urcorner q:
        draw ((-.2u,0)--(.2u,0)) 
             rotated uniformdeviate(360) 
             shifted ((i,j) randomized 0.6u) withpen PenC;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_clay_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q, qq; q = bbox p;
  picture tmp_pic; 
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        qq := ((-.25u,0){up}..origin{down}..{up}(0.25u,0)) randomized (u/15)
             shifted ((i,j) randomized 1.3u);
	if xpart (p intersectiontimes qq) < 0:
	  thdraw qq;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_ice_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q; q = bbox p;
  picture tmp_pic, tmp_ice; 
  pair z;
  tmp_ice := image (
    draw (-.2u,0)--(.2u,0);
    draw (0,-.2u)--(0,.2u);
  );
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        z := ((i,j) randomized 1.3u);
	if xpart (p intersectiontimes ((bbox tmp_ice) shifted z)) < 0:
	  draw tmp_ice shifted z;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;


def a_snow_SKBB (expr P) =
  T:=identity;
  pickup PenC;
  path q; q = bbox P;
  picture tmp_pic, tmp_sn; 
  pair z;
  tmp_sn := image(
    pickup PenC;
    p := origin--(0,.2*u);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240); draw p rotated (300);
    p := ((0,.3u)--(0,0.2u)--(0.1u,0.2u)) rotatedaround ((0,0.2u),45);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240);
    draw p rotated (300);
  );
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        z:=((i,j) randomized 1.3u);
	if xpart (P intersectiontimes ((bbox tmp_sn) shifted z)) < 0:
          draw tmp_sn shifted z;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to P;
  drawoptions();
  draw tmp_pic;
enddef;

def a_blocks_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q, qq; q = bbox p;
  picture tmp_pic; 
  uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart llcorner q)/100);
  tmp_pic := image(
    for i = xpart llcorner q step 2uu until xpart urcorner q:
      for j = ypart llcorner q step 2uu until ypart urcorner q:
        qq := punked (((-.5uu,-.5uu)--(.5uu,-.5uu)--(.5uu,.5uu)--(-.5uu,.5uu)--cycle) 
	     randomized (uu/2))
             rotated uniformdeviate(360) 
             shifted ((i,j) randomized 1.6uu);
	if xpart (p intersectiontimes qq) < 0:
	  thclean qq;
	  thdraw qq;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_blocks_SKBB_ (expr p,o,s_beg,s_end,d_beg,d_end) =
  T:=identity;
  orient = 90-o;
  pickup PenC;
  path q[], qq; q1 = bbox p;
  draw q1; draw p;
  q2 = llcorner q1 .. lrcorner q1 .. urcorner q1 .. ulcorner q1 .. cycle;
  draw q2;
  pair zz[];
  radius := .5*length(llcorner q1 - urcorner q1);
  zz1 := .5[llcorner q1,urcorner q1];
  zz2 := zz1 - dir(orient)*radius;
  zz3 = zz1 rotatedaround (zz2,90);
  draw zz1 withpen pencircle scaled 2mm;
  draw zz2 withpen pencircle scaled 2mm;
  draw zz3 withpen pencircle scaled 2mm;
  picture tmp_pic; 
  tmp_pic := image(
    j := 0;
    forever:
      i := 0;
      forever:
        qq := punked (((-.5,-.5)--(.5,-.5)--(.5,.5)--(-.5,.5)--cycle) 
             scaled (0.7(5u-(j/(2*radius))[u*s_beg,u*s_end]))
	     randomized (u/2))
             rotated uniformdeviate(360) 
             shifted (((zz3 + (i,j)) rotatedaround (zz3,-o)) randomized 1.6u);
        draw ((zz3 + (i,j)) rotatedaround (zz3,-o)) withpen pencircle scaled 1mm withcolor red;
	if xpart (p intersectiontimes qq) < 0:
	  thclean qq;
	  thdraw qq;
	fi;
        i := i + (j/(2*radius))[u*d_beg,u*d_end];
        exitif i > 2*radius;
      endfor;  
      j := j + (j/(2*radius))[u*d_beg,u*d_end];
      exitif j > 2*radius;
    endfor;
  );
%  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;


def a_pebbles_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q, qq; q = bbox p;
  picture tmp_pic; 
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        qq := (superellipse((.2u,0),(0,.1u),(-.2u,0),(0,.-.1u),.75))
%             randomized (u/25)
             rotated uniformdeviate(360) 
             shifted ((i,j) randomized 0.8u);
	if xpart (p intersectiontimes qq) < 0:
	  thdraw qq;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_water_SKBB (expr Path) =
  T:=identity;
  thfill Path;
enddef;

let a_sump_SKBB = a_water_SKBB;

def a_u (expr p) =
    T:=identity;
    thfill p withcolor red;
enddef;




%%%%% ENDINPUT thArea %%%%%





%%%%% INPUT thText %%%%%


%% therion source code
%%
%% This file defines macros for labels
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thText.mp,v $
%% $Revision: 1.6 $
%%
%% Copyright (C) 2000-2004 Martin Budaj
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

labeloffset:=0bp;

def l_label(expr txt,path) =
  picture pict,pic;
  pair pos;
  numeric dx[],dy[],ptime;
  string ss,ch;

  pic := thelabel(txt,(0,0));
  strl := xpart(lrcorner pic - llcorner pic);
  pathl := arclength (path);
  dx0 := xpart(llcorner pic);
%  dy0 := ypart(llcorner pic);

  if strl>pathl:
    txtzoom := pathl / strl;
    thwarning("text scaled down to fit the path");
  else:
    txtzoom := 1;
  fi;
  zoom := pathl / strl;

  for p within pic:
    if textual p:                                
      ss := textpart p;
      dx1 := xpart p;
      dy1 := ypart p;
      dx2 := dx1;

      if xxpart p / yypart p <> 1: message("Error: distorted text!") fi;
      txtscale := txtzoom * xxpart p;

      l := length(ss);
      ptime := 0;
      for i=0 upto (l - 1):
        ch := substring(i,i+1) of ss;
        pict := ch infont fontpart p scaled txtscale;
        charwidth := xpart (lrcorner pict - llcorner pict) / txtzoom;
        dy2 := ypart lrcorner pict / txtzoom;
        ptime := (dx2 - dx0 + 0.5*charwidth) * zoom;
        t := arctime ptime of (path);
        pos := point t of path + 
          (dy1+dy2)*txtzoom*unitvector((direction t of path) rotated 90);
        begingroup
%          interim labeloffset:=0bp;
          lab:=thelabel.top(pict,pos);
          process_label(pos,angle direction t of path);
        endgroup;
        dx2 := dx2 + charwidth;
      endfor;

    else: message("Strange component of line label!");
    fi;
  endfor;
  % draw path;
enddef;

vardef p_label@#(expr txt,pos,rot,mode) =
  if (mode=1) or (mode=7): interim labeloffset:=(u/8) fi;
  lab:=thelabel@#(txt, pos);
  if mode>1: pickup PenD fi;
  if mode=1:
    pickup pencircle scaled (u/6);
    drawdot(pos);
    process_label(pos,0);
  elseif mode=2: process_uplabel;       
  elseif mode=3: process_downlabel;
  elseif mode=4: process_updownlabel;
  elseif mode=5: process_circledlabel;
  elseif mode=6: process_boxedlabel;
  elseif mode=7: process_label(pos,rot);  % station name
  elseif mode=8: process_filledlabel(pos, rot);
  else: process_label(pos,rot); fi;
enddef;


% at beginfig: save smartll[], smartur[]; pair smartll[], smartur[]; smart_count=0;
numeric smart_count, smart_D;
boolean smart_quit, smart_inner_quit;

def p_smartlabel (expr txt, pos) =
  begingroup;
  interim bboxmargin:=0.2pt;
  lab:=thelabel.rt(txt,pos+(0.4u,0));
  q:=bbox lab;
  smart_D := 0;
  forever:
    smart_quit := true;
    smart_inner_quit := false;
    for i=1 upto smart_count:
      if smart_overlap(((point 0 of q) shifted (0,smart_D)), 
                       ((point 2 of q) shifted (0,smart_D)),
                       smartll[i], smartur[i]) = 1:
        smart_quit := false;
        smart_D := smart_D - 3pt;
        smart_inner_quit := true;
      fi;
      exitif smart_inner_quit;
    endfor;
    exitif smart_quit;
  endfor;
  smart_U := 0;
  forever:
    smart_quit := true;
    smart_inner_quit := false;
    for i=1 upto smart_count:
      if smart_overlap(((point 0 of q) shifted (0,smart_U)), 
                       ((point 2 of q) shifted (0,smart_U)),
                       smartll[i], smartur[i]) = 1:
        smart_quit := false;
        smart_U := smart_U + 3pt;
        smart_inner_quit := true;
      fi;
      exitif smart_inner_quit;
    endfor;
    exitif smart_quit;
  endfor;
  if (smart_U < -smart_D): smart_D := smart_U; fi;
  draw lab shifted (0,smart_D);
  if (abs(smart_D)>3pt):
    pickup PenB;
    draw pos{left}..{right}(pos shifted (.4u, smart_D)) dashed withdots scaled 0.2;
    pickup PenA;
    drawdot pos;
  fi;
  smart_count := smart_count + 1;
  smartll[smart_count] := point 0 of (q shifted (0,smart_D));
  smartur[smart_count] := point 2 of (q shifted (0,smart_D));
  endgroup;
enddef;

def smart_overlap (expr llA, urA, llB, urB) =
  if ((xpart llA < xpart urB) and (xpart urA > xpart llB)) and
     ((ypart llA < ypart urB) and (ypart urA > ypart llB)):
    1
  else:
    0 
  fi
enddef;




def p_wallaltitude (expr pprev,pos,pnext,txt) =
  rot:=angle(unitvector(pnext-pos)+unitvector(pos-pprev)) - 90;
  pickup PenD;
  pair zz;
%  zz:=(pos + 3*unitvector(dir rot));
  zz:=(pos + (u/4)*unitvector(dir rot));
  draw (pos)--zz;
  begingroup 
%    interim labeloffset:=2pt;
    interim labeloffset:=(u/12);
    if horiz_labels:
      rot:=rot mod 360;
      if rot<=22.5: lab:=thelabel.rt(txt, zz);
      elseif rot<=67.5: lab:=thelabel.urt(txt, zz);
      elseif rot<=112.5: lab:=thelabel.top(txt, zz);
      elseif rot<=157.5: lab:=thelabel.ulft(txt, zz);
      elseif rot<=202.5: lab:=thelabel.lft(txt, zz);
      elseif rot<=247.5: lab:=thelabel.llft(txt, zz);
      elseif rot<=292.5: lab:=thelabel.bot(txt, zz);
      elseif rot<=337.5: lab:=thelabel.lrt(txt, zz);
      else: lab:=thelabel.rt(txt, zz);
      fi;
    else:
      if (abs rot>90) and (abs rot <=270):
        rot:=rot-180;
        lab:=thelabel.lft(txt, pos);
      else:
        lab:=thelabel.rt(txt, pos);
      fi;
    fi;
    process_label(pos, if horiz_labels: 0 else: rot fi);
  endgroup;
enddef;




%%%%% ENDINPUT thText %%%%%





%%%%% INPUT thSpecial %%%%%


%% therion source code
%%
%% This file defines macros for special symbols
%%
%% $Date: $
%% $RCSfile: $
%% $Revision: $
%%
%% Copyright (C) 2004 Martin Budaj
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

def s_northarrow_SKBB_old (expr rot) = 
  T:=identity;
  picture tmp_pic;
  tmp_pic = image (
    begingroup
      interim defaultscale:=3;
      label(if (lang="sk") or (lang="cz"): "S" else: "N" fi, origin);
    endgroup;
    drawarrow (0,-1cm)--(0,1cm);
  );
  draw tmp_pic rotatedaround(origin, -rot);
enddef;

def s_northarrow_SKBB (expr rot) =
  T:=identity scaled 0.7 rotated -rot;
  thdraw (-.5cm,-1cm)--(0,1.5cm)--(.5cm,-1cm)--(0,-.5cm)--cycle;
  thfill (-.5cm,-1cm)--(0,1.5cm)--(0,-.5cm)--cycle;
enddef;

def s_scalebar_SKBB (expr l, units, txt) = 
  begingroup
    interim warningcheck:=0;
    tmpl:=l / Scale * cm * units / 2;
  endgroup;
  pickup PenC;
  draw (-tmpl,0)--(tmpl,0);
  draw (-tmpl,0)--(-tmpl,2bp);
  draw (tmpl,0)--(tmpl,2bp);
  begingroup
    interim labeloffset:=2bp;
    label.top(thTEX(decimal (l) & "\thinspace" & txt),origin);
  endgroup
enddef;

def s_scalebar_SM (expr l, units, txt) = 
  begingroup
    interim warningcheck:=0;
    tmpl:=l / Scale * cm * units / 2;
  endgroup;
  pickup PenC;
  draw (-tmpl,0)--(tmpl,0);
  draw (-tmpl,0)--(-tmpl,2bp);
  draw (tmpl,0)--(tmpl,2bp);
  draw (0,0)--(0,2bp);
  begingroup
    interim labeloffset:=3.5bp;
    label.top(thTEX(decimal (0)),(-tmpl,0));
    label.top(thTEX(decimal (l/2)),origin);
    label.top(thTEX(decimal (l) & "\thinspace" & txt),(tmpl,0));
  endgroup
enddef;


def s_hgrid_SM (expr xpos, ypos, xsize, ysize) =
  pickup PenD;
  draw (
    if xpos < 0: 0 else: -5mm fi, 0
  ) -- (
    if xpos > 0: 0 else: 5mm fi, 0
  );
  draw (
    0, if ypos < 0: 0 else: -5mm fi
  ) -- (
    0, if ypos > 0: 0 else: 5mm fi
  );
enddef;


def s_vgrid_SM (expr xpos, ypos, xsize, ysize) =
  pickup PenD;
  draw (
    if xpos < 0: 0 else: -xsize/2 fi, 0
  ) -- (
    if xpos > 0: 0 else: xsize/2 fi, 0
  ) dashed evenly;
enddef;




%%%%% ENDINPUT thSpecial %%%%%





%%%%% INPUT uAUT %%%%%


% Austrian Symbol Set, author Georg Pacher

% color (for Austrian symbol-set)

color col_water_bg;
col_water_bg :=(226/255,244/255,253/255);

%%%%%%%%%%%%%%%%%%%%%%%


%% areas

% returns true if pair point lies within path q. 
% outside_point is any pair outside of path q (needed for reference).
vardef pointinside(expr pt,q,outside_point)=
  T:=identity;
  path test;
  test:= outside_point--pt;
  %thdraw test;
  boolean isinside;
  isinside:=false;
  numintersections:=recgetnumintersections(test,q,0);
  if (numintersections <0):
    isinside:=true;
  elseif odd(numintersections):
     isinside:=true;
  else:
     isinside:=false;
  fi;
  isinside
enddef;

% get number of intersection between paths p (length 1!) and q
% recnum is needed for limitation of recursions. 
% If the number of allowed recursions is reached, a negativ number of intersections is returned
vardef recgetnumintersections(expr p,q,recnum)=
  
  pair inter;
  save preinter;
  save postinter;
  save numintersections;
  path preinter, postinter;
  inter:=p intersectiontimes q;
  %show recnum;
  if recnum >25:
    numintersections:=-100;
  else:  
    if xpart(inter)>0 :
     %show (xpart inter);
    % split p into two paths and call yourself again
    
    preinter:=subpath (0,xpart(inter)-2eps) of p;
    
    postinter:=subpath (xpart(inter)+2eps,1) of p;
    
    numintersections:= recgetnumintersections(preinter,q,recnum+1)
                     + recgetnumintersections(postinter,q,recnum+1)
                     + 1;
    else:
      numintersections:=0;
    fi;
  fi;
  numintersections
  
enddef;

beginpattern(pattern_water_AUT);
    draw origin--10up withpen pensquare scaled (0.02u);
    patternxstep(.18u);
    patterntransform(identity rotated 90);
endpattern;

beginpattern(pattern_sump_AUT);
    draw origin--(0,.25u) withpen pensquare scaled (0.02u);
    draw origin--(.25u,0) withpen pensquare scaled (0.02u);
endpattern;

beginpattern(pattern_sand_AUT);
    pickup PenC;
    p:= origin -- (0.01u,0.01u);
    for i=0.0u step 0.2u until 2.4u:
        for j=0.0u step 0.2u until 2.4u:
          draw p rotated uniformdeviate(360) 
           shifted ((i,j) randomized 0.09u);
        endfor;
    endfor;
    if BaseScale<=2.5:
      my_step:=2.4u;
    else:
      my_step:=2.6u;
    fi;
    patternstep(my_step,my_step);       
endpattern;

beginpattern(pattern_pebbles_AUT);
    pickup PenC;
    path qq;
    for i=0.0u step 0.3u until 5.1u:
        for j=0.0u step 0.3u until 5.1u:
          qq := (superellipse((.1u,0),(0,.05u),(-.1u,0),(0,.-.05u),.75))
             randomized (u/45)
             scaled (uniformdeviate(0.4)+.55)
             rotated uniformdeviate(360) 
             shifted ((i,j) randomized 0.15u);
           draw qq;
        endfor;
    endfor;
    patternstep(5.1u,5.1u);
endpattern;

beginpattern(pattern_ice_AUT);
    pickup PenC;
    p:=(-.15u,.0u) -- (0.15u,.0u);
    draw p;
    draw p shifted (0.25u,.0u) rotated (90);
    draw p shifted (0.45u,0.25u);
    draw p shifted (0.0u,0.45u) rotated (90);
    patternxstep(.9u);
    patternystep(0.5u);
endpattern;

def a_water_AUT (expr Path) =
  T:=identity;
  thclean Path;
  pickup PenC;
  thfill Path withcolor col_water_bg;
  thfill Path withpattern pattern_water_AUT;
  thdraw Path;
enddef;

def a_sump_AUT (expr Path) =
  T:=identity;
  thclean Path;
  pickup PenC;
  thfill Path withcolor col_water_bg;
  thfill Path withpattern pattern_sump_AUT;
  thdraw Path;
enddef;

def a_sand_AUT (expr Path) =
  T:=identity;
%  thclean Path;
  thfill Path withpattern pattern_sand_AUT ;
enddef;

let a_clay_AUT = a_sand_AUT;


def a_pebbles_AUT (expr p) =
  T:=identity;
  thfill p withpattern pattern_pebbles_AUT;
enddef;



def a_debris_AUT (expr p) =
  T:=identity;
  
  symbol_distance:=1.0;
  scale_factor:= 0.3;
  pickup PenC;
  path q, qq; q = bbox p;
  pair outside;
  outside:= ulcorner q + up;
  picture tmp_pic; 
  uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart     llcorner q)/100);
  tmp_pic := image(
     for i = xpart llcorner q step symbol_distance*uu until xpart urcorner q:
        for j = ypart llcorner q step symbol_distance*uu until ypart urcorner q:
           qq := punked (((-.5uu,-.5uu)--(.5uu,-.5uu)--(1.05uu,0.01uu)--(.5uu,.5uu)--(-.5uu,.5uu)--cycle) 
           randomized (uu/2))
           scaled (uniformdeviate(0.4)+scale_factor )
           rotated uniformdeviate(360) 
           shifted ((i,j) randomized 0.5uu);
           if xpart (p intersectiontimes qq) < 0:
             if pointinside((i,j),p,outside):
               thclean qq;
               thdraw qq;
             fi;
           else:
             qq:= qq scaled (uniformdeviate(.2)+.5 )
             if xpart (p intersectiontimes qq) < 0:
               if pointinside((i,j),p,outside):
                 thclean qq;
                 thdraw qq;
               fi;
             fi;
           fi;
        endfor;  
     endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;  

def a_ice_AUT (expr p) =
  T:=identity;
  thclean p;
  thfill p withpattern pattern_ice_AUT;
  pickup PenC;
  thdraw p;
enddef;

def a_snow_AUT (expr P) =
  T:=identity;
  pickup PenC;
  path q; q = bbox P;
  picture tmp_pic, tmp_sn; 
  pair z;
  tmp_sn := image(
    pickup PenC;
    p := origin--(0,.2*u);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240); draw p rotated (300);
    p := ((0,.3u)--(0,0.2u)--(0.1u,0.2u)) rotatedaround ((0,0.2u),45);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240);
    draw p rotated (300);
  );
  tmp_pic := image(
    for i = xpart llcorner q step 1.0u until xpart urcorner q:
      for j = ypart llcorner q step 1.0u until ypart urcorner q:
        z:=((i,j) randomized 0.5u);
	if xpart (P intersectiontimes ((bbox tmp_sn) shifted z)) < 0:
          draw tmp_sn shifted z;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to P;
  draw tmp_pic;
  thdraw P;
enddef;

def a_blocks_AUT (expr p) =
   T:=identity;
  symbol_distance:=1.6;
  scale_factor:= 0.8;
  pickup PenC;
  path q, qq; q = bbox p;
  pair outside;
  outside:= ulcorner q + up;
  picture tmp_pic; 
  uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart     llcorner q)/100);
  tmp_pic := image(
     for i = xpart llcorner q step symbol_distance*uu until xpart urcorner q:
        for j = ypart llcorner q step symbol_distance*uu until ypart urcorner q:
           qq := punked (((-.5uu,-.5uu)--(.5uu,-.5uu)--(1.05uu,0.01uu)--(.5uu,.5uu)--(-.5uu,.5uu)--cycle) 
           randomized (uu/2))
           scaled (uniformdeviate(0.7)+scale_factor )
           rotated uniformdeviate(360) 
           shifted ((i,j) randomized 0.75uu);
           if xpart (p intersectiontimes qq) < 0:
             if pointinside((i,j),p,outside):
               thclean qq;
               thdraw qq;
             fi;
           else:
             qq:= qq scaled (uniformdeviate(.2)+.5 )
             if xpart (p intersectiontimes qq) < 0:
               if pointinside((i,j),p,outside):
                 thclean qq;
                 thdraw qq;
               fi;
             fi;
           fi;
        endfor;  
     endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;  


%% lines

def l_wall_pit_AUT (expr P) = 
    T:=identity;
    % draw outer path
    pickup PenA;
    thdraw P;

    laenge:= arclength P;

    pair inner[],innerdir[], inter;
    pair test;
    
    samplingdistance:=max(0.15u,laenge/1500);
 
    path testcircle;
    % testcircle, used to test, whether the path makes a 'v'-like bend, 
    % where normal sampling and offsetting gives poor results for the parallel line
    % size of testcircle= size PenA/2 + 2* (distance between outer and inner line)
    % + PenC (inner line)
    testcircle := halfcircle scaled (.5*u/10+2*.125u+.5*u/10) shifted (0,.5*u/10);
    cur:=samplingdistance/2;
    count:=0;
    forever:
      t:= arctime cur of P;
      inter:=P intersectiontimes (testcircle rotated (angle thdir(P,t)) shifted (point t of P));
      
      %thdraw testcircle rotated (angle thdir(P,t)) shifted (point t of P) withpen (pencircle scaled 0.01u) ;
      if (xpart inter) >=0:
        % we are at a 'sharp bend', so set next point to intersectionpoint
        cur:=cur+samplingdistance;
        t := max( xpart inter, arctime cur of P);
        %thdraw point t of P withcolor 0.7*green;
        forever:
          t:= arctime cur of P;
          inter:=P intersectiontimes (testcircle rotated (angle thdir(P,t)) shifted (point t of P));
          exitif (xpart inter <0);
          cur := cur + samplingdistance;
          exitif (cur >=laenge); 
        endfor;
        if (cur <laenge):
          inner[count]:=(point t of P + .125u*unitvector(thdir(P,t) rotated 90) );
          innerdir[count]:=unitvector(thdir(P,t));
          count := count+1;
        fi;
      else:
        inner[count]:= (point t of P + .125u*unitvector(thdir(P,t) rotated 90) );
        innerdir[count]:=unitvector(thdir(P,t));
        %thdraw inner[count] withpen PenD withcolor 0.5*red;
        count:=count +1;
        cur:= cur+ samplingdistance;
      fi;
      exitif (cur >=laenge);
    endfor;
    if count>2:
      % draw inner path
      pickup PenC;
      path innerpath;
      innerpath =
      for i=0 upto count-2:
        inner[i]{(innerdir[i])} ..
      endfor
      if cycle P: cycle;
      else:  inner[count-1];
      fi;
      thdraw innerpath;
        
    % draw the triangles

    path draw_triangle;
    pair l_triangle;
       
    laenge:= arclength innerpath;
    symsize:= adjust_step(laenge,0.5u);
    triangle_width:=symsize/2;
    cur:=(symsize/2);
    t := arctime (cur) of innerpath;
    t1:= arctime (cur-triangle_width/2) of innerpath;
    t2:= arctime (cur+triangle_width/2) of innerpath;         
    l_triangle := (point t of innerpath);
    if ATTR__height >= 10: thfill else: thdraw fi (subpath (t1,t2) of innerpath) -- 
           ((point t of innerpath) + symsize/2 * unitvector(thdir(innerpath,t) rotated 90))
           --  cycle;

    for cur=(symsize/2) step symsize until laenge:
      t := arctime (cur) of innerpath;
      test := (point t of innerpath);
      my_dist := length(test-l_triangle);
      if (abs(my_dist-symsize) < 0.05u) or (my_dist>symsize):
         t1:= arctime (cur-triangle_width/2) of innerpath;
         t2:= arctime (cur+triangle_width/2) of innerpath;         
	 draw_triangle:=(subpath (t1,t2) of innerpath) -- 
                        ((point t of innerpath) + symsize/2 * unitvector(thdir(innerpath,t) rotated 90))
                         --  cycle;
	 if xpart (draw_triangle intersectiontimes P) < 0:
	    if ATTR__height >= 10: 
	      thfill draw_triangle;
	    else:
	      thclean draw_triangle;
	      thdraw draw_triangle;
	    fi;
	    l_triangle:= test;
	 fi;
      fi;
    endfor;
    
    fi;
enddef;


def l_wall_sand_AUT (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.1u);
  pickup PenC;  
  forever:
    t := arctime cas of P;
    thdraw (((0.01u,0.01u)--origin) rotated uniformdeviate(360) shifted ((point t of P) + (uniformdeviate 1) * .4u 
            * unitvector(thdir(P,t) rotated -90)));
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
  pickup PenC;  
  thdraw P;

enddef;

def l_wall_pebbles_AUT (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .18u);
  pickup PenC;
  q:=superellipse((.1u,0),(0,.05u),(-.1u,0),(0,.-.05u),.75);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q randomized (u/45) rotated (angle(thdir(P,t)) + (normaldeviate*40)) shifted point t of P;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;


let l_wall_clay_AUT = l_wall_sand_AUT;


def l_wall_debris_AUT (expr P) = 
  T:=identity;
  pickup PenC;
  laenge := arclength P;
  path block;
  path old_block;
  
  cur := 0;
  t:= arctime cur of P;
  % draw first block
  old_block := (((-.0u,-.0u)--(.25u,-.15u)--(.45u,0.01u)--(.2u,.25u)--(.05u,.15u)--cycle));
  block_width := (xpart urcorner old_block - xpart ulcorner old_block);
  old_block:=old_block rotated angle(thdir(P,0)) shifted point t of P;
  thclean old_block;
  thdraw old_block;
   
  cur := cur + 0.9*block_width;
  t:= arctime cur of P;
	% proceed with path
    forever:
	  % generate random block
        block := punked (((-.25u,-.25u)--(0.25.u,-.25u)--(0.50u,0.01u)--(0.25u,.25u)--(-.25u,.25u)--cycle) 
          randomized (u/4))
          scaled (uniformdeviate(0.3)+.4)
          rotated uniformdeviate(360);
	  % check width of block
        block_width := (xpart urcorner block - xpart ulcorner block);
        exitif cur > (laenge- 2.5*block_width/2);
        % find next position where the block fits in without intersecting the previous one
	  forever:           
	    exitif xpart ( (block rotated angle(-direction t of P) shifted point t of P) intersectiontimes old_block) < 0;
            cur:=cur+0.01u;
            t:= arctime cur of P;
            exitif cur > (laenge- 2.5*block_width/2);
          endfor;
        exitif cur > (laenge- 2.5*block_width/2);

        old_block:= block rotated angle(-direction t of P) shifted point t of P;
        thclean old_block;
        thdraw old_block;
        cur := cur + block_width/2;
        t:= arctime cur of P;
    endfor;
	t:= arctime laenge-eps of P;

	% generate last block
      block := (((-.0u,-.0u)--(.25u,-.15u)--(.45u,0.01u)--(.2u,.25u)--(.1u,.15u)--cycle));
     block_width := (xpart urcorner block - xpart ulcorner block);
     
	% scale last block to fit in the remaining gap
     scale_factor:=1.5*(laenge-cur)/block_width;
     forever:
           exitif scale_factor < 0;  % bruces stab at preventing endless loop at large scales
           exitif xpart ( (block rotated angle(-direction t of P) scaled scale_factor shifted (point t of P)) intersectiontimes old_block) < 0;
           scale_factor:=scale_factor-0.01;
     endfor;
     if scale_factor > 0:
       thclean block rotated angle(-direction t of P) scaled scale_factor shifted (point t of P);
       thdraw block rotated angle(-direction t of P) scaled scale_factor shifted (point t of P);
     fi;
enddef;


def l_wall_blocks_AUT (expr P) = 

  T:=identity;
  pickup PenC;
  laenge := arclength P;

  path block;
  path old_block;
  
  cur := 0;
  t:= arctime cur of P;
  
  % draw first block
  old_block := ( (.7u,-.35u)--(.85u,0.01u)--(.4u,.5u)--(.1u,.3u)--(-.0u,-.0u) );
  block_width := (xpart urcorner old_block - xpart ulcorner old_block);
  old_block:=old_block rotated angle( thdir(P,0) ) shifted point t of P;
  thclean (old_block--cycle);
  thdraw old_block;
  
  
  cur := cur + block_width/2;
  t:= arctime cur of P;
  forever:
    % generate random block
    block := punked ( ( (.8u,-.35u)--(.85u,0.01u)--(.6u,.4u)--(.1u,.1u)--(-.0u,-.3u) )
          randomized (0.3u) )
           scaled (uniformdeviate(0.3)+.65)
          rotated (uniformdeviate(45)-15);
    % check width of block
    block_width := (xpart urcorner block - xpart ulcorner block);
    
    exitif cur > (laenge- 3.5*block_width/2);
    % find next position where the block fits in without intersecting the previous one
    forever:    
      exitif xpart ( ((block--cycle) rotated angle(direction t of P) shifted point t of P) intersectiontimes old_block) < 0;
      cur:=cur+0.01u;
      t:= arctime cur of P;
      exitif cur > (laenge- 3.5*block_width/2);
    endfor;
    exitif cur > (laenge- 3.5*block_width/2);
    
    old_block:= block rotated angle(direction t of P) shifted point t of P;
    thclean (old_block--cycle);
    thdraw old_block;
    
    
    cur := cur + block_width/2;
    t:= arctime cur of P;
  endfor;
  
    % generate last block
    t:= arctime laenge-eps of P;
    block := (( (-.15u,-.35u)--(.0u,.0u)--(-.45u,.5u)--(-.75u,.3u)--(-.85u,-.0u)) );
    block_width := (xpart urcorner block - xpart ulcorner block);
    % scale last block to fit in the remaining gap
    scale_factor:=(laenge-cur)/block_width;
    forever:
	  exitif scale_factor < 0;
      exitif xpart ( ( (block) rotated angle (direction t of P) scaled scale_factor shifted (point t of P) ) intersectiontimes old_block) < 0;
      scale_factor:=scale_factor-0.001;
    endfor;
    if scale_factor > 0:
      thclean (block--cycle) rotated angle (direction t of P) scaled scale_factor shifted (point t of P);
      thdraw (block) rotated angle (direction t of P) scaled scale_factor shifted (point t of P);
    fi;
enddef;



def l_wall_ice_AUT (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .6u);
  pickup PenC;
  p := (-.15u,0)--(.15u,0);
  q := p rotated 90 shifted (.25u,.0u);
  picture symbol,test_symbol;
  symbol:= image (
             thdraw p;
             thdraw q;
             );
  path bound,old_bound,test_bound;
  begingroup;
    interim bboxmargin:=0;
    bound := bbox (symbol);
  endgroup;
  t := arctime (cas + mojkrok/2) of P;
  thdraw symbol rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
  old_bound:=bound rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));

  forever:
    t := arctime (cas + mojkrok/2) of P;
    test_bound:= bound rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    if xpart ((old_bound) intersectiontimes (test_bound))<0:
      if xpart (P intersectiontimes (test_bound))<0:
        thdraw symbol rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
        old_bound:=bound rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
      fi;
    fi;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
  thdraw P;
enddef;


def l_wall_underlying_AUT (expr P) = 
  T:=identity;
  pickup PenA;
  laenge:= arclength P;
  t1 := arctime (0.5u) of P;
  t2 := arctime (laenge-.5u) of P;
  thdraw (subpath (t1,t2) of P) dashed evenly scaled optical_zoom;
enddef;


def l_wall_overlying_AUT (expr P) = 
  T:=identity;
  laenge:= arclength P;
  t1 := arctime (0.25u) of P;
  t2 := arctime (laenge-.25u) of P;
  t3 :=arctime (laenge) of P;
  pickup pensquare scaled (3.5*u/10);
  thdraw (subpath (t1,t2) of P) withcolor background;
    pickup PenA;
  thdraw subpath(0,t1) of P; 
  thdraw subpath(t2,t3) of P;
  thdraw (subpath (t1,t2) of P) dashed dashpattern(on 2bp off 2bp on .5bp off 2bp on 2bp) scaled optical_zoom;
enddef;

def l_wall_moonmilk_AUT (expr P) = 
  T:=identity;
  laenge:= arclength P;
  symsize:=adjust_step(laenge,0.8u);
  circle_width:=symsize/2;
  cur:=(symsize-circle_width)/2;
  pickup PenC;
  forever:
    t1 := arctime (cur) of P;
    t2 := arctime (cur + circle_width) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 90)} ..
           {dir (angle(thdir(P,t2)) - 90)}(point t2 of P);
    cur := cur + symsize;
    exitif cur > laenge + (symsize / 3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_flowstone_AUT (expr P) = 
  T:=identity;
  laenge:= arclength P;
  symsize:=adjust_step(laenge,0.8u);
  circle_width:=symsize/2;
  cur:=(symsize-circle_width)/2;
  pickup PenC;
  forever:
    t1 := arctime (cur) of P;
    t2 := arctime (cur + circle_width) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 90)} ..
           {dir (angle(thdir(P,t2)) - 90)}(point t2 of P);
    thfill (point t1 of P){dir (angle(thdir(P,t1)) + 90)} ..
           {dir (angle(thdir(P,t2)) - 90)}(point t2 of P) --
           (point t1 of P)--cycle;
    cur := cur + symsize;
    exitif cur > laenge + (symsize / 3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_pit_AUT (expr P) =
  T:=identity;
  laenge:= arclength P;
  symsize:=adjust_step(laenge,0.5u);
  triangle_width:=symsize/2;
  cur:=(symsize-triangle_width)/2;
  pickup PenC;
  forever:
    t1 := arctime (cur) of P;
    t  := arctime (cur + triangle_width/2) of P;
    t2 := arctime (cur + triangle_width) of P;
    if ATTR__height >= 10:
      thfill (subpath (t1,t2) of P) -- 
        ((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) -- 
        cycle;
    else:
      thclean (subpath (t1,t2) of P) -- 
        ((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) -- 
        cycle;
      thdraw (point t2 of P) --((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) -- 
        (point t1 of P);
    fi;
    cur := cur + symsize;
    exitif cur > laenge - (1*symsize/3); % for rounding errors
    t1:=arctime (cur) of P;
  endfor;
  thdraw P;
enddef;


let l_overhang_AUT = l_pit_AUT;

let l_floorstep_AUT = l_floorstep_UIS;

let l_contour_AUT =l_contour_SKBB;

def l_flowstone_AUT (expr P) = 
  T:=identity;
  pickup PenC;
  thdraw P dashed evenly scaled optical_zoom;
enddef;

def l_survey_cave_AUT (expr P) =
  T:=identity;
  pair zz[];
  pickup PenD;
  thdraw P;
enddef;

%% points

def p_stalactite_AUT(expr pos,theta,sc,al) =
    pickup PenC;
    if ATTR__elevation:
      U:=(.15u, .4u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
      thdraw (0,.15u) -- (.15u,.4u);
    else:
      U:=(.175u, .175u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thclean fullcircle scaled 0.35u;
      thdraw fullcircle scaled 0.35u;
    fi;
enddef;

let p_icestalactite_AUT = p_stalactite_AUT;

def p_stalagmite_AUT(expr pos,theta,sc,al) =
    pickup PenC;
    if ATTR__elevation:
      U:=(.15u,.4u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
      thdraw (0,-.15u) -- (.15u,-.4u);
    else:
      U:=(.15u,.15u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thfill fullcircle scaled 0.3u;
    fi;
enddef;

let p_icestalagmite_AUT = p_stalagmite_AUT;

def p_pillar_AUT(expr pos,theta,sc,al) =
    pickup PenC;
    if ATTR__elevation:
      U:=(.15u,.4u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thdraw (0,.15u)--(0,-.15u);
      thdraw (-.15u,-.4u)--(0,-.15u)--(.15u,-.4u);
      thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
    else:
      U:=(.225u,.225u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thclean fullcircle scaled 0.45u;
      thdraw fullcircle scaled 0.45u;
      thfill fullcircle scaled 0.3u;
    fi;
enddef;

let p_icepillar_AUT = p_pillar_AUT;

def p_crystal_AUT (expr pos,theta,sc,al)=
    U:=(.35u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
   
    pickup PenC;
    p := ((-.35*u,0)--(.35*u,0));
    thdraw p;
    thdraw p rotated (45);
    thdraw p rotated (90);
    thdraw p rotated (135);
    
    thdrawoptions();

enddef;

def p_spring_AUT (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,.1u)..(0,-.1u)..(.3u,.1u);
enddef;


def p_sink_AUT (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,-.1u)..(0,.1u)..(.3u,-.1u);
enddef;

def p_breakdownchoke_AUT (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity rotated -theta aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thclean (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.21u,.305u)--(.0u,-.305u)--(.21u,.305u);
enddef;

def p_sand_AUT (expr pos,theta,sc,al)=
    U:=(.2u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:= origin -- (0.01u,0.01u);
    for i=-0.1u step 0.2u until .15u:
        for j=-0.1u step 0.2u until .15u:
          thdraw p rotated uniformdeviate(360) 
           shifted ((i,j) randomized 0.09u);
        endfor;
    endfor;
    thdrawoptions();
enddef;

let p_clay_AUT  = p_sand_AUT;

def p_pebbles_AUT (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    path qq;
    for i=-0.15u step 0.3u until .2u:
        for j=-0.15u step 0.3u until .2u:
          qq := (superellipse((.1u,0),(0,.05u),(-.1u,0),(0,.-.05u),.75))
             randomized (u/45)
             scaled (uniformdeviate(0.4)+.55)
             rotated uniformdeviate(360) 
             shifted ((i,j) randomized 0.15u);
           thdraw qq;
        endfor;
    endfor;
enddef;

def p_debris_AUT (expr pos,theta,sc,al)=
    U:=(.5u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    path block,q;
    block :=  ((-.15u,-.15u)--(.15u,-.15u)--(.3u,0.01u)--(.15u,.15u)--(-.15u,.15u)--cycle) ;
    
    q:= (punked (block randomized (0.15u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.3)+0.3) shifted (0.0u,0.15u);
    thclean q; thdraw q;
    
    q:= (punked (block randomized (0.15u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.5)+0.7) shifted (-0.15u,-0.15u);
    thclean q; thdraw q;

    q:=  (punked (block randomized (0.15u))) rotated uniformdeviate(360) shifted (0.15u,-0.15u);
    thclean q; thdraw q;
    
enddef;

def p_blocks_AUT (expr pos,theta,sc,al)=
    U:=(u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;

    path block,q;
    block :=  ((-.25u,-.25u)--(.25u,-.25u)--(.5u,0.01u)--(.25u,.25u)--(-.25u,.25u)--cycle) ;
    
    q:= (punked (block randomized (0.3u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.3)+0.3) shifted (0.0u,0.25u);
    thclean q; thdraw q;
    
    q:= (punked (block randomized (0.3u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.5)+0.7) shifted (-0.25u,-0.25u);
    thclean q; thdraw q;

    q:=  (punked (block randomized (0.3u))) rotated uniformdeviate(360) shifted (0.25u,-0.25u);
    thclean q; thdraw q;
    
enddef;

def p_water_AUT (expr pos,theta,sc,al)=
    U:=(.425u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenD;
    p:=fullcircle xscaled (.85u) yscaled (.6u);
    thfill p withcolor col_water_bg;
    thfill p withpattern pattern_water_AUT;
    thdraw p;
enddef;

def p_ice_AUT (expr pos,theta,sc,al)=
    U:=(.6u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.15u,.0u) -- (0.15u,.0u);
    thdraw p rotated 90;
    thdraw p shifted (0.45u,.0u);
    thdraw p shifted (-0.45u,.0u);
    
    thdraw p rotated 90 shifted (-0.45u,0.25u);
    thdraw p shifted (0u,0.25u);
    thdraw p rotated 90 shifted (0.45u,.25u);
enddef;

def p_entrance_AUT (expr pos,theta,sc,al)=
    U:=(.3u,.75u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    path slice;
    for i= -0.5 step 0.01 until 0.5:
      slice:= (-.3u*(0.5-i),1.5*i*u)--(0,.75u)--(.3u*(0.5-i),1.5i*u)--cycle;
      thfill slice withcolor (min(0.95,0.5-1.75i),min(0.95,.5-1.75i),min(0.95,.5-1.75i));
    endfor;
    thdraw ((-.3u,-0.75u)--(0,.75u)--(.3u,-0.75u)--cycle);
enddef;
    
def p_gradient_AUT (expr pos,theta,sc,al)=
    U:=(.15u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-0.5u)--(0,0.5u);
    p:=(-.15u,.3u)--(0,0.7u)--(.15u,.3u)--cycle;
    thfill p;
    thdraw p;
enddef;

def p_airdraught_AUT (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,.5u)--(0,-0.8u);
	p:=(-.2u,.2u)--(0,.55u)--(.2u,.2u)--cycle;
	thfill p;
	for i:=1 upto round(3+2*mlog(sc)/mlog 2):
	  thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
	  thdraw (0,-(1-0.2i)*u)--(-.2u,-(1-0.2(i-1))*u);
	endfor;
enddef;

def p_station_temporary_AUT (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    thclean fullcircle scaled 0.15u;
    thdraw fullcircle scaled 0.15u;
enddef;

let p_station_painted_AUT = p_station_temporary_AUT ;
let p_station_fixed_AUT = p_station_temporary_AUT ;

def p_claychoke_AUT (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity rotated -theta aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thclean (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.15u,.3u)--(-.15u,-.25u)--(.15u,-.25u);
enddef;

def p_claytree_AUT (expr pos,theta,sc,al)=
    U:=(.55u,.6u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:= (-.15u,.15u)--(.0u,.6u)--(.15u,.15u);
    thdraw p ;
    thdraw p shifted (-.4u,-.3u);
    thdraw p shifted (.4u,-.2u) ;
enddef;




%%%%% ENDINPUT uAUT %%%%%






%%%%% INPUT thTrans %%%%%


% default translations

let p_station_fixed = p_station_fixed_ASF;
let p_station_painted = p_station_painted_SKBB;
let p_station_natural = p_station_natural_ASF;              
let p_station_temporary = p_station_temporary_ASF;

let p_waterflow_paleo = p_waterflow_paleo_UIS;
let p_waterflow_permanent = p_waterflow_permanent_UIS;
let p_waterflow_intermittent = p_waterflow_intermittent_UIS;

let p_stalactite = p_stalactite_UIS;
let p_stalagmite = p_stalagmite_UIS;
let p_pillar = p_pillar_UIS;
let p_icestalactite = p_icestalactite_AUT;
let p_icestalagmite = p_icestalagmite_AUT;
let p_icepillar = p_icepillar_AUT;
let p_curtain = p_curtain_UIS;
let p_helictite = p_helictite_UIS;
let p_sodastraw = p_sodastraw_UIS;
let p_crystal = p_crystal_UIS;
let p_flowstone = p_flowstone_UIS;
let p_moonmilk = p_moonmilk_UIS;
let p_wallcalcite = p_wallcalcite_UIS;
let p_popcorn = p_popcorn_UIS;
let p_disk = p_disk_UIS;
let p_gypsum = p_gypsum_NSS;
let p_aragonite = p_aragonite_NSS;
let p_cavepearl = p_cavepearl_SKBB;
let p_gypsumflower = p_gypsumflower_NSS;
let p_rimstonepool = p_rimstonepool_ASF;
let p_rimstonedam = p_rimstonedam_ASF;
let p_anastomosis = p_anastomosis_UIS;
let p_karren = p_karren_UIS;
let p_scallop = p_scallop_UIS;
let p_flute = p_flute_UIS;
let p_raft = p_raft_NSS;
let p_raftcone = p_raftcone_NSS;
let p_spring = p_spring_SKBB;
let p_sink = p_sink_SKBB;
let p_narrowend = p_narrowend_UIS;
let p_lowend = p_lowend_UIS;
let p_flowstonechoke = p_flowstonechoke_NSS;
let p_breakdownchoke = p_breakdownchoke_NSS;
let p_claychoke = p_claychoke_AUT;
let p_claytree = p_claytree_AUT;
let p_bedrock = p_bedrock_ASF;
let p_clay = p_clay_SKBB;                        
let p_sand = p_sand_UIS;
let p_pebbles = p_pebbles_UIS;
let p_debris = p_debris_UIS;
let p_blocks = p_blocks_UIS;
let p_water = p_water_UIS;
let p_ice = p_ice_UIS;
let p_snow = p_snow_SKBB;
let p_archeomaterial = p_archeomaterial_UIS;
let p_paleomaterial = p_paleomaterial_UIS;
let p_guano = p_guano_UIS;
let p_vegetabledebris = p_vegetabledebris_ASF;
let p_root = p_root_ASF;
let p_entrance = p_entrance_UIS;
let p_gradient = p_gradient_UIS;
let p_rope = p_rope_SKBB;          
let p_fixedladder = p_fixedladder_SKBB;   
let p_ropeladder = p_ropeladder_SKBB;    
let p_steps = p_steps_SKBB;         
let p_bridge = p_bridge_SKBB;        
let p_traverse = p_traverse_SKBB;
let p_anchor = p_anchor_SKBB;
let p_camp = p_camp_SKBB;
let p_dig = p_dig_UIS;
let p_noequipment = p_noequipment_SKBB;
let p_sectionarrow = p_sectionarrow_SKBB;
let p_continuation = p_continuation_UIS;
let p_airdraught = p_airdraught_UIS;
let p_airdraught_winter = p_airdraught_winter_UIS;
let p_airdraught_summer = p_airdraught_summer_UIS;
let p_station = p_station_SKBB;
let p_handrail = p_handrail_SKBB;
let p_viaferrata = p_viaferrata_SKBB;
let p_stalactites = p_stalactites_UIS;
let p_stalagmites = p_stalagmites_UIS;
let p_pillars = p_pillars_UIS;

let l_wall_bedrock = l_wall_bedrock_UIS;
let l_wall_sand = l_wall_sand_SKBB;
let l_wall_clay = l_wall_clay_SKBB;
let l_wall_pebbles = l_wall_pebbles_SKBB;
let l_wall_debris = l_wall_debris_SKBB;
let l_wall_blocks = l_wall_blocks_SKBB;
let l_wall_ice = l_wall_ice_SKBB;
let l_wall_underlying = l_wall_underlying_UIS;
let l_wall_unsurveyed = l_wall_unsurveyed_SKBB;
let l_wall_presumed = l_wall_presumed_UIS;
%let l_wall_invisible = l_wall_invisible;
let l_wall_pit = l_wall_pit_AUT;
let l_wall_overlying = l_wall_overlying_AUT;
let l_wall_flowstone = l_wall_flowstone_AUT;
let l_wall_moonmilk = l_wall_moonmilk_AUT;

let l_waterflow_permanent = l_waterflow_permanent_UIS;
let l_waterflow_intermittent = l_waterflow_intermittent_SKBB;
let l_waterflow_conjectural = l_waterflow_conjectural_SKBB;

let l_border_visible = l_border_visible_SKBB;
let l_border_temporary = l_border_temporary_SKBB;
let l_border_presumed = l_border_presumed_SKBB;
%let l_border_invisible = l_border_invisible;

let l_floorstep = l_floorstep_UIS;
let l_pit = l_pit_UIS;
let l_ceilingstep = l_ceilingstep_SKBB;
let l_chimney = l_chimney_UIS;
let l_overhang = l_overhang_SKBB;
let l_slope = l_slope_SKBB;
let l_ceilingmeander = l_ceilingmeander_SKBB;
let l_floormeander = l_floormeander_SKBB;
let l_contour = l_contour_SKBB;
let l_rockborder = l_rockborder_UIS;
let l_rockedge = l_rockedge_UIS;
let l_flowstone = l_flowstone_UIS;
let l_moonmilk = l_moonmilk_UIS;
let l_section = l_section_SKBB;
let l_survey_cave = l_survey_cave_SKBB;
let l_survey_surface = l_survey_surface_SKBB;
let l_arrow = l_arrow_SKBB;
let l_gradient = l_gradient_UIS;
let l_mapconnection = l_mapconnection_SKBB;
let l_handrail = l_handrail_SKBB;
let l_steps = l_steps_SKBB;
let l_fixedladder = l_fixedladder_SKBB;
let l_ropeladder = l_ropeladder_SKBB;
let l_rope = l_rope_SKBB;
let l_viaferrata = l_viaferrata_SKBB;

let a_water = a_water_UIS;
let a_sump = a_sump_UIS;
let a_sand = a_sand_UIS;
let a_debris = a_debris_SKBB;
let a_blocks = a_blocks_SKBB;
let a_snow = a_snow_SKBB;
let a_ice = a_ice_SKBB;
let a_pebbles = a_pebbles_SKBB;
let a_clay = a_clay_SKBB;
let a_bedrock = a_bedrock_SKBB;
let a_flowstone = a_flowstone_ASF;
let a_moonmilk = a_moonmilk_SKBB;
let a_dimensions = a_dimensions_SKBB;

let s_northarrow = s_northarrow_SKBB;
let s_scalebar = s_scalebar_SKBB;
let s_hgrid = s_hgrid_SM;
let s_vgrid = s_vgrid_SM;



%%%%% ENDINPUT thTrans %%%%%



nonstopmode;
initsymbol("s_hgrid_SM");
initsymbol("s_northarrow_SKBB");
initsymbol("s_scalebar_SKBB");
initsymbol("s_scalebar_SM");
initsymbol("s_vgrid_SM");
initsymbol("p_airdraught_AUT");
initsymbol("p_airdraught_UIS");
initsymbol("p_airdraught_summer_UIS");
initsymbol("p_airdraught_winter_UIS");
initsymbol("p_anastomosis_UIS");
initsymbol("p_anchor_SKBB");
initsymbol("p_aragonite_NSS");
initsymbol("p_archeomaterial_UIS");
initsymbol("p_bedrock_ASF");
initsymbol("p_blocks_AUT");
initsymbol("p_blocks_UIS");
initsymbol("p_breakdownchoke_AUT");
initsymbol("p_breakdownchoke_NSS");
initsymbol("p_bridge_SKBB");
initsymbol("p_camp_SKBB");
initsymbol("p_cavepearl_SKBB");
initsymbol("p_clay_AUT");
initsymbol("p_clay_SKBB");
initsymbol("p_claychoke_AUT");
initsymbol("p_claytree_AUT");
initsymbol("p_continuation_UIS");
initsymbol("p_crystal_AUT");
initsymbol("p_crystal_UIS");
initsymbol("p_curtain_UIS");
initsymbol("p_debris_AUT");
initsymbol("p_debris_UIS");
initsymbol("p_dig_UIS");
initsymbol("p_disk_UIS");
initsymbol("p_entrance_AUT");
initsymbol("p_entrance_UIS");
initsymbol("p_fixedladder_SKBB");
initsymbol("p_flowstone_UIS");
initsymbol("p_flowstonechoke_NSS");
initsymbol("p_flute_UIS");
initsymbol("p_gradient_AUT");
initsymbol("p_gradient_BCRA");
initsymbol("p_gradient_NSS");
initsymbol("p_gradient_SKBB");
initsymbol("p_gradient_UIS");
initsymbol("p_guano_UIS");
initsymbol("p_gypsum_NSS");
initsymbol("p_gypsumflower_NSS");
initsymbol("p_handrail_SKBB");
initsymbol("p_helictite_UIS");
initsymbol("p_ice_AUT");
initsymbol("p_ice_UIS");
initsymbol("p_icepillar_AUT");
initsymbol("p_icestalactite_AUT");
initsymbol("p_icestalagmite_AUT");
initsymbol("p_karren_UIS");
initsymbol("p_lowend_NSS");
initsymbol("p_lowend_UIS");
initsymbol("p_moonmilk_UIS");
initsymbol("p_narrowend_UIS");
initsymbol("p_noequipment_SKBB");
initsymbol("p_paleomaterial_UIS");
initsymbol("p_pebbles_AUT");
initsymbol("p_pebbles_UIS");
initsymbol("p_pillar_AUT");
initsymbol("p_pillar_UIS");
initsymbol("p_pillars_UIS");
initsymbol("p_popcorn_UIS");
initsymbol("p_raft_NSS");
initsymbol("p_raftcone_NSS");
initsymbol("p_rimstonedam_ASF");
initsymbol("p_rimstonepool_ASF");
initsymbol("p_root_ASF");
initsymbol("p_rope_SKBB");
initsymbol("p_ropeladder_SKBB");
initsymbol("p_sand_AUT");
initsymbol("p_sand_UIS");
initsymbol("p_scallop_UIS");
initsymbol("p_sink_AUT");
initsymbol("p_sink_SKBB");
initsymbol("p_snow_SKBB");
initsymbol("p_sodastraw_UIS");
initsymbol("p_spring_AUT");
initsymbol("p_spring_SKBB");
initsymbol("p_stalactite_AUT");
initsymbol("p_stalactite_UIS");
initsymbol("p_stalactites_UIS");
initsymbol("p_stalagmite_AUT");
initsymbol("p_stalagmite_UIS");
initsymbol("p_stalagmites_UIS");
initsymbol("p_station_SKBB");
initsymbol("p_station_fixed_ASF");
initsymbol("p_station_fixed_AUT");
initsymbol("p_station_natural_ASF");
initsymbol("p_station_painted_AUT");
initsymbol("p_station_painted_SKBB");
initsymbol("p_station_temporary_ASF");
initsymbol("p_station_temporary_AUT");
initsymbol("p_station_temporary_SKBB");
initsymbol("p_steps_SKBB");
initsymbol("p_traverse_SKBB");
initsymbol("p_vegetabledebris_ASF");
initsymbol("p_viaferrata_SKBB");
initsymbol("p_wallcalcite_UIS");
initsymbol("p_water_AUT");
initsymbol("p_water_UIS");
initsymbol("p_waterflow_intermittent_UIS");
initsymbol("p_waterflow_paleo_UIS");
initsymbol("p_waterflow_permanent_UIS");
initsymbol("l_arrow_SKBB");
initsymbol("l_border_presumed_SKBB");
initsymbol("l_border_temporary_SKBB");
initsymbol("l_border_visible_SKBB");
initsymbol("l_ceilingmeander_NZSS");
initsymbol("l_ceilingmeander_SKBB");
initsymbol("l_ceilingmeander_UIS");
initsymbol("l_ceilingstep_NZSS");
initsymbol("l_ceilingstep_SKBB");
initsymbol("l_ceilingstep_UIS");
initsymbol("l_chimney_NZSS");
initsymbol("l_chimney_UIS");
initsymbol("l_contour_AUT");
initsymbol("l_contour_SKBB");
initsymbol("l_contour_UIS");
initsymbol("l_fixedladder_SKBB");
initsymbol("l_floormeander_SKBB");
initsymbol("l_floorstep_AUT");
initsymbol("l_floorstep_UIS");
initsymbol("l_flowstone_AUT");
initsymbol("l_flowstone_UIS");
initsymbol("l_gradient_BCRA");
initsymbol("l_gradient_UIS");
initsymbol("l_handrail_SKBB");
initsymbol("l_mapconnection_SKBB");
initsymbol("l_moonmilk_UIS");
initsymbol("l_overhang_AUT");
initsymbol("l_overhang_SKBB");
initsymbol("l_pit_AUT");
initsymbol("l_pit_UIS");
initsymbol("l_rockborder_UIS");
initsymbol("l_rockedge_UIS");
initsymbol("l_rope_SKBB");
initsymbol("l_ropeladder_SKBB");
initsymbol("l_section_SKBB");
initsymbol("l_slope_BCRA");
initsymbol("l_slope_SKBB");
initsymbol("l_steps_SKBB");
initsymbol("l_survey_cave_AUT");
initsymbol("l_survey_cave_SKBB");
initsymbol("l_survey_cave_UIS");
initsymbol("l_survey_surface_SKBB");
initsymbol("l_viaferrata_SKBB");
initsymbol("l_wall_bedrock_UIS");
initsymbol("l_wall_blocks_AUT");
initsymbol("l_wall_blocks_SKBB");
initsymbol("l_wall_clay_AUT");
initsymbol("l_wall_clay_SKBB");
initsymbol("l_wall_debris_AUT");
initsymbol("l_wall_debris_SKBB");
initsymbol("l_wall_flowstone_AUT");
initsymbol("l_wall_ice_AUT");
initsymbol("l_wall_ice_SKBB");
initsymbol("l_wall_moonmilk_AUT");
initsymbol("l_wall_overlying_AUT");
initsymbol("l_wall_pebbles_AUT");
initsymbol("l_wall_pebbles_SKBB");
initsymbol("l_wall_pit_AUT");
initsymbol("l_wall_presumed_NZSS");
initsymbol("l_wall_presumed_UIS");
initsymbol("l_wall_sand_AUT");
initsymbol("l_wall_sand_SKBB");
initsymbol("l_wall_underlying_AUT");
initsymbol("l_wall_underlying_UIS");
initsymbol("l_wall_unsurveyed_SKBB");
initsymbol("l_waterflow_conjectural_SKBB");
initsymbol("l_waterflow_intermittent_SKBB");
initsymbol("l_waterflow_permanent_UIS");
initsymbol("a_bedrock_SKBB");
initsymbol("a_blocks_AUT");
initsymbol("a_blocks_SKBB");
initsymbol("a_clay_AUT");
initsymbol("a_clay_SKBB");
initsymbol("a_debris_AUT");
initsymbol("a_debris_SKBB");
initsymbol("a_debris_UIS");
initsymbol("a_dimensions_SKBB");
initsymbol("a_flowstone_ASF");
initsymbol("a_ice_AUT");
initsymbol("a_ice_SKBB");
initsymbol("a_moonmilk_SKBB");
initsymbol("a_pebbles_AUT");
initsymbol("a_pebbles_SKBB");
initsymbol("a_sand_AUT");
initsymbol("a_sand_UIS");
initsymbol("a_snow_AUT");
initsymbol("a_snow_SKBB");
initsymbol("a_sump_AUT");
initsymbol("a_sump_SKBB");
initsymbol("a_sump_UIS");
initsymbol("a_water_AUT");
initsymbol("a_water_SKBB");
initsymbol("a_water_UIS");

lang:="fr";
ATTR__elevation:=false;

% user defined symbols defaults
% end of user defined symbols

defaultfont:="cmss10";
NorthDir:="true";
def l_u_doline (expr P) =
T:=identity;
laenge:= arclength P;
symsize:=adjust_step(laenge,2u);
triangle_width:=symsize/10;
cur:=(symsize-triangle_width)/2;
pickup PenC;
forever:
t1 := arctime (cur) of P;
t  := arctime (cur + triangle_width/2) of P;
t2 := arctime (cur + triangle_width) of P;
thfill (subpath (t1,t2) of P) --
((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) --
cycle;
thdraw (point t2 of P) --((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) --
(point t1 of P) withcolor (0.5, 0, 0);
cur := cur + symsize;
exitif cur > laenge - (1*symsize/3); % for rounding errors
t1:=arctime (cur) of P;
endfor;
enddef;
def a_blocks (expr p) =
T:=identity;
pickup PenC;
path q, qq; q = bbox p;
picture tmp_pic;
uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart     llcorner q)/100);
tmp_pic := image(
for i = xpart llcorner q step 1.0uu until xpart urcorner q:
for j = ypart llcorner q step 1.0uu until ypart urcorner q:
qq := punked (((-.3uu,-.3uu)--(.3uu,-.3uu)--(.3uu,.3uu)--(-.3uu,.3uu)--cycle)
randomized (uu/2))
rotated uniformdeviate(360)
shifted ((i,j) randomized 1.0uu);
if xpart (p intersectiontimes qq) < 0:
thclean qq;
thdraw qq;
fi;
endfor;
endfor;
);
clip tmp_pic to p;
draw tmp_pic;
enddef;
def a_sands (expr p) =
T:=identity;
pickup PenC;
path q; q = bbox p;
picture tmp_pic;
tmp_pic := image(
for i = xpart llcorner q step 0.1u until xpart urcorner q:
for j = ypart llcorner q step 0.1u until ypart urcorner q:
draw origin shifted ((i,j) randomized 0.1u) withpen PenC;
endfor;
endfor;
);
draw tmp_pic;
enddef;
def a_pebbles_SKBB (expr p) =
T:=identity;
pickup PenC;
path q, qq; q = bbox p;
picture tmp_pic;
tmp_pic := image(
for i = xpart llcorner q step .1u until xpart urcorner q:
for j = ypart llcorner q step .5u until ypart urcorner q:
qq := (superellipse((.07u,0),(0,.03u), (-.07u,0),(0,.-.03u),.75))
%randomized (u/25)
rotated uniformdeviate(360)
shifted ((i,j) randomized 0.27u);
if xpart (p intersectiontimes qq) < 0:
thdraw qq;
fi;
endfor;
endfor;
);
clip tmp_pic to p;
draw tmp_pic;
enddef;
def l_slope (expr P,S)(text Q) =
%show Q;
T:=identity;
numeric dirs[];
numeric lengths[];
for i=Q:
dirs[redpart i]:=greenpart i;
lengths[redpart i]:=bluepart i;
endfor;
li:=length(P); % last
alw_perpendicular:=true;
for i=0 upto li:
if unknown dirs[i]: dirs[i]:=-1;
else:
if dirs[i]>-1:
dirs[i]:=((90-dirs[i]) - angle(thdir(P,i))) mod 360;
alw_perpendicular:=false;
fi;
fi;
if unknown lengths[i]: lengths[i]:=-1; fi;
endfor;
%for i=0 upto li: show dirs[i]; endfor;
ni:=0; % next
pi:=0; % previous
for i=0 upto li:
d:=dirs[i];
if d=-1:
if (i=0) or (i=li):
dirs[i] := angle(thdir(P,i) rotated 90) mod 360;
pi:=i;
else:
if ni<=i:
for j=i upto li:
ni:=j;
exitif dirs[j]>-1;
endfor;
fi;
w:=arclength(subpath(pi,i) of P) /
arclength(subpath(pi,ni) of P);
dirs[i]:=w[dirs[pi],dirs[ni]];
%if (dirs[i]-angle(thdir(P,i))) mod 360>180:
%dirs[i]:=w[dirs[ni],dirs[pi]];
%message("*******");
%fi;
fi;
else:
pi:=i;
fi;
endfor;
%for i=0 upto li: show dirs[i]; endfor;
ni:=0; % next
pi:=0; % previous
for i=0 upto li:
l:=lengths[i];
if l=-1:
if (i=0) or (i=li):
lengths[i] := 1cm; % should never happen!
thwarning("slope width at the end point not specified");
pi:=i;
else:
if ni<=i:
for j=i+1 upto li:
ni:=j;
exitif lengths[j]>-1;
endfor;
fi;
w:=arclength(subpath(pi,i) of P) /
arclength(subpath(pi,ni) of P);
lengths[i]:=w[lengths[pi],lengths[ni]];
pi:=i;
fi;
else:
pi:=i;
fi;
endfor;
%for i=0 upto li: show lengths[i]; endfor;
T:=identity;
boolean par;
cas := 0.3u;
krok := 0.7u;
dlzka := (arclength P);
if dlzka>3u: dlzka:=dlzka-0.6u fi;
mojkrok:=adjust_step(dlzka,1.4u) / 5;
pickup PenD;
par := false;
forever:
t := arctime cas of P;
if t mod 1>0:  % not a key point
w := (arclength(subpath(floor t,t) of P) /
arclength(subpath(floor t,ceiling t) of P));
if alw_perpendicular:
a := 90;
else:
a := w[dirs[floor t],dirs[ceiling t]];
fi;
l := w[lengths[floor t],lengths[ceiling t]];
else:
if alw_perpendicular:
a := 90;
else:
a:= dirs[t];
fi;
l:=lengths[t];
fi;
a := a + angle(thdir(P,t));
thdraw (point t of P) --
((point t of P) + if par: 0.333 * fi l * unitvector(dir(a)));
cas := cas + mojkrok;
par := not par;
exitif cas > dlzka + .3u + (krok / 3);  % for rounding errors
endfor;
if S = 1: pickup PenC; draw P fi;
%pickup pencircle scaled 3pt;
%for i=0 upto li: draw point i of P; endfor;
enddef;
def a_u_boue (expr p) =
T:=identity;
thfill p withcolor (0.49, 0.20, 0.00);
enddef;
def a_sump (expr p) =
T:=identity;
thfill p withcolor (0.06, 0.20, 0.65);
enddef;
def a_u_guano (expr p) =
T:=identity;
thfill p withcolor (0.53, 0.26, 0.11);
enddef;
def a_water (expr p) =
T:=identity;
thfill p withcolor (0.17, 0.46, 1);
enddef;
def s_northarrow (expr rot) =
begingroup
interim defaultscale:=0.7; % scale your north arrow here
T:=identity scaled defaultscale rotated -rot;
interim linecap:=squared;
interim linejoin:=rounded;
thfill (-.5cm,-.1cm)--(0,2.5cm)--(.5cm,-.1cm)--cycle;
pickup pencircle scaled (0.08cm * defaultscale);
thdraw (0,0)--(0,-2.5cm);
pickup pencircle scaled (0.16cm * defaultscale);
p:=(0.4cm,0.6cm);
thdraw ((p--(p yscaled -1)--(p xscaled -1)--(p scaled -1)) shifted (0,-1.0cm));
label.rt(thTEX("mg") scaled 1.6, (.6cm,-1.6cm)) transformed T;
endgroup;
enddef;
def s_scalebar (expr l, units, txt) =
begingroup
interim warningcheck:=0;
tmpl:=l / Scale * cm * units / 2;
tmpx:=l / Scale * cm * units / 5;
tmph:=5bp; % bar height
endgroup;
pickup PenC;
draw (-tmpl,0)--(tmpl,0)--(tmpl,-tmph)--(-tmpl,-tmph)--cycle;
p:=(0,0)--(tmpx,0)--(tmpx,-tmph)--(0,-tmph)--cycle;
for i:=-2.5 step 2 until 2:
fill p shifted (i * tmpx,0);
endfor;
begingroup
interim labeloffset:=3.5bp;
for i:=0 step (l/5) until (l-1):
tmpx:=tmpl * (i * 2 / l - 1);
label.bot(thTEX(decimal (i)),(tmpx,-tmph));
endfor;
label.bot(thTEX(decimal (l) & "\thinspace" & txt),(tmpl,-tmph));
% To write the scale "1:scale"; Comment it ?
%label.top(thTEX("Echelle 1 : " & decimal (Scale*100)),(0,0));
endgroup;
enddef;
def p_u_prof (expr pos) =
T:=identity shifted pos;
pickup PenD;
p:=(-.3u,0)--(.3u,0);
thdraw p; thdraw p rotated 90;
p:=fullcircle scaled .2u;
thclean p; thdraw p;
enddef;
vardef p_label@#(expr txt,pos,rot,mode) =
if mode=1:
thdrawoptions(withcolor .8red + .4blue);
p_u_prof(pos);
% append "m" to label
picture txtm;
% calcul profondeur
%numeric profondeur;
profondeur:=(\thaltitude-\cavemaxz);
picture txtprofondeur;
txtm:=image(
draw txt;
interim labeloffset:=0;
label.urt(btex \thaltitude m etex, lrcorner txt);
%label.urt(btex \thdepth m etex, lrcorner txt);
);
% give extra offset in case of l/r/t/b alignment
pair ctmp;
ctmp:=center thelabel@#("x", (0,0));
if (xpart ctmp * ypart ctmp)=0:
interim labeloffset:=(.4u);
else: % diagonal alignment
interim labeloffset:=(.2u);
fi;
% draw label
lab:=thelabel@#(txtm, pos);
draw lab _thop_; % use color
thdrawoptions();
bboxmargin:=0.8bp;
write_circ_bbox((bbox lab) smoothed 2);
else:
if mode=7: interim labeloffset:=(u/8) fi;
lab:=thelabel@#(txt, pos);
if mode>1: pickup PenD fi;
if mode=2: process_uplabel;
elseif mode=3: process_downlabel;
elseif mode=4: process_updownlabel;
elseif mode=5: process_circledlabel;
elseif mode=6: process_boxedlabel;
elseif mode=7: process_label(pos,rot);  % station name
elseif mode=8: process_filledlabel(pos, rot);
else: process_label(pos,rot); fi;
fi;
enddef;
def p_altitude (expr pos) =
T:=identity shifted pos;
pickup PenD;
p:=(-.3u,0)--(.3u,0);
thdraw p; thdraw p rotated 90;
p:=fullcircle scaled .2u;
thclean p; thdraw p;
enddef;
vardef p_label@#(expr txt,pos,rot,mode) =
if mode=1:
thdrawoptions(withcolor .8red + .4blue);
p_altitude(pos);
% append "m" to label
picture txtm;
txtm:=image(
draw txt;
interim labeloffset:=0;
label.urt(btex \thaltitude  m etex, lrcorner txt);
);
% give extra offset in case of l/r/t/b alignment
pair ctmp;
ctmp:=center thelabel@#("x", (0,0));
if (xpart ctmp * ypart ctmp)=0:
interim labeloffset:=(.4u);
else: % diagonal alignment
interim labeloffset:=(.2u);
fi;
% draw label
lab:=thelabel@#(txtm, pos);
draw lab _thop_; % use color
thdrawoptions();
bboxmargin:=0.8bp;
write_circ_bbox((bbox lab) smoothed 2);
else:
if mode=7: interim labeloffset:=(u/8) fi;
lab:=thelabel@#(txt, pos);
if mode>1: pickup PenD fi;
if mode=2: process_uplabel;
elseif mode=3: process_downlabel;
elseif mode=4: process_updownlabel;
elseif mode=5: process_circledlabel;
elseif mode=6: process_boxedlabel;
elseif mode=7: process_label(pos,rot);  % station name
elseif mode=8: process_filledlabel(pos, rot);
else: process_label(pos,rot); fi;
fi;
enddef;
verbatimtex \def\thheightpos{E}\def\thheightneg{P} etex
def l_u_strata (expr P) =
T:=identity;
path Q; Q = punked P;
for t = 0 upto length P - 1:
pair zz[];
zz1 := point t of P;
zz2 := point t+1 of P;
zz3 := postcontrol t of P;
zz4 := precontrol t+1 of P;
linecap:=0;
if (length(zz3-1/3[zz1,zz2]) > 0.1pt) or (length(zz4-2/3[zz1,zz2]) > 0.1pt):
zz5 = whatever[zz1,zz2];
(zz3-zz5) = whatever * (zz1-zz2) rotated 90;
pickup pencircle scaled 1 mm;
draw zz1--zz5 dashed evenly;
pickup PenA;
draw zz1--zz5 withcolor background;
zz6 = whatever[zz1,zz2];
(zz4-zz6) = whatever * (zz1-zz2) rotated 90;
pickup pencircle scaled 1 mm;
draw zz2--zz6 dashed evenly;
pickup PenA;
draw zz2--zz6 withcolor background;
else:
pickup pencircle scaled 1 mm;
draw zz1--zz2 dashed evenly;
pickup PenA;
draw zz1--zz2 withcolor background;
fi;
endfor;
enddef;
def l_u_fault (expr P) =
T:=identity;
path Q; Q = punked P;
pickup PenA;
for t = 0 upto length P - 1:
pair zz[];
zz1 := point t of P;
zz2 := point t+1 of P;
zz3 := postcontrol t of P;
zz4 := precontrol t+1 of P;
if (length(zz3-1/3[zz1,zz2]) > 0.1pt) or (length(zz4-2/3[zz1,zz2]) > 0.1pt):
zz5 = whatever[zz1,zz2];
(zz3-zz5) = whatever * (zz1-zz2) rotated 90;
draw zz1--zz5 dashed evenly;
zz6 = whatever[zz1,zz2];
(zz4-zz6) = whatever * (zz1-zz2) rotated 90;
draw zz2--zz6 dashed evenly;
else:
draw zz1--zz2 dashed evenly;
fi;
endfor;
enddef;
def l_u_doline (expr P) =
T:=identity;
laenge:= arclength P;
symsize:=adjust_step(laenge,2u);
triangle_width:=symsize/10;
cur:=(symsize-triangle_width)/2;
pickup PenC;
forever:
t1 := arctime (cur) of P;
t  := arctime (cur + triangle_width/2) of P;
t2 := arctime (cur + triangle_width) of P;
thfill (subpath (t1,t2) of P) --
((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) --
cycle;
thdraw (point t2 of P) --((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) --
(point t1 of P) withcolor (0.5, 0, 0);
cur := cur + symsize;
exitif cur > laenge - (1*symsize/3); % for rounding errors
t1:=arctime (cur) of P;
endfor;
enddef;
def p_gradient_XA (expr P,R,S,A) =
U:=(.15u, .4u);
T:=identity aligned A rotated R scaled S shifted P;
pickup PenC;
thdraw (0u, 0u) -- (0u, .4u);
thdraw (-.4u, 0u) -- (.4u, 0u);
enddef;
initsymbol ("p_gradient_XA");
def p_u_bat(expr pos, theta, sc, al) =
T := identity shifted pos;
thfill (bat_path scaled 2.0) withcolor black;
enddef;
def p_u_boss (expr pos,theta,sc,al)=
T:=identity aligned al rotated theta scaled sc shifted pos;
pickup PenD;
p := (0.08u,0.25u)..(0,0.29u)..(-0.08u,0.25u);
q := (0.16u,0.5u)..(0u,0.58u)..(-0.16u,0.5u);
for i=0 upto 9:
thdraw p rotated 36i;
thdraw q rotated 36i;
endfor
p := fullcircle scaled 0.15u;
thdraw p;
enddef;
mapsymbol("p_station_temporary","SKBB",true);
mapsymbol("p_gradient","XA",true);
transparency:=true;
background:=(1.00000,1.00000,0.80000);
def_transparent_rgb(tr_bg, 1.00000, 1.00000, 0.80000);
current_scrap := "A21-8";
ATTR__scrap := "A21-8";
beginfig(1);
ATTR__height := -1;
drawoptions();
l_pit(((-32.26,4.69)
 .. controls (-32.26,4.69) and (-29.82,4.69) .. (-29.75,2.97)
 .. controls (-29.69,1.19) and (-30.24,-0.85) .. (-30.24,-0.85)
));
ATTR__height := -1;
drawoptions();
l_pit(((-45.69,-26.69)
 .. controls (-45.69,-26.69) and (-48.41,-25.85) .. (-48.26,-24.95)
 .. controls (-48.10,-24.05) and (-49.47,-26.96) .. (-49.63,-27.86)
 .. controls (-49.78,-28.76) and (-50.27,-31.12) .. (-48.65,-31.26)
 .. controls (-47.02,-31.40) and (-44.52,-30.44) .. (-44.52,-30.44)
 -- cycle
));
drawoptions();
p_pebbles((-29.34,7.04),0.0,1.00,(0,0));
drawoptions();
p_pebbles((-26.52,7.94),0.0,1.00,(0,0));
drawoptions();
p_pebbles((-27.83,4.59),0.0,1.00,(0,0));
drawoptions();
p_pebbles((-25.38,6.01),0.0,1.00,(0,0));
drawoptions();
p_pebbles((-22.60,6.65),0.0,1.00,(0,0));
drawoptions();
p_pebbles((-29.05,10.23),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_contour(((47.65,36.35)
 .. controls (47.65,36.35) and (45.40,32.53) .. (43.77,32.85)
 .. controls (42.15,33.18) and (39.44,33.83) .. (39.44,33.83)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((50.38,34.79)
 .. controls (50.38,34.79) and (50.06,32.81) .. (46.86,31.48)
 .. controls (43.65,30.16) and (43.30,29.79) .. (41.50,30.10)
 .. controls (39.69,30.42) and (38.23,31.47) .. (38.23,31.47)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((44.57,37.36)
 .. controls (44.57,37.36) and (44.24,35.91) .. (42.81,35.88)
 .. controls (41.37,35.85) and (39.74,36.53) .. (39.74,36.53)
),-1);
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-47.32,-27.88) -- (-47.32,-27.88)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-45.41,-29.18) -- (-47.32,-27.88)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-45.41,-29.18) -- (-39.21,-20.44)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-39.21,-20.44) -- (-45.41,-29.18)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-39.21,-20.44) -- (-30.69,-22.00)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-30.69,-22.00) -- (-39.21,-20.44)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-30.69,-22.00) -- (-31.99,-10.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-31.99,-10.84) -- (-30.69,-22.00)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-31.99,-10.84) -- (-28.68,-8.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-28.68,-8.29) -- (-31.99,-10.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-28.68,-8.29) -- (-14.77,0.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-27.81,6.77) -- (-28.91,1.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-27.81,6.77) -- (-29.34,16.30)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-28.91,1.96) -- (-14.77,0.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-28.91,1.96) -- (-27.81,6.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-14.77,0.61) -- (-28.68,-8.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-14.77,0.61) -- (-4.15,1.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-14.77,0.61) -- (-28.91,1.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-4.15,1.10) -- (1.65,-4.86)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-4.15,1.10) -- (-14.77,0.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1.65,-4.86) -- (15.36,0.07)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1.65,-4.86) -- (-4.15,1.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.36,0.07) -- (18.85,5.48)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.36,0.07) -- (1.65,-4.86)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((18.85,5.48) -- (26.98,13.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((18.85,5.48) -- (15.36,0.07)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((26.98,13.61) -- (32.11,20.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((26.98,13.61) -- (18.85,5.48)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((32.11,20.96) -- (35.49,25.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((32.11,20.96) -- (26.98,13.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.65,-23.39) -- (4.50,-21.06)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((4.50,-21.06) -- (2.65,-23.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((4.50,-21.06) -- (7.44,-21.86)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((7.44,-21.86) -- (4.50,-21.06)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((7.44,-21.86) -- (9.67,-18.34)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((9.67,-18.34) -- (7.44,-21.86)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((9.67,-18.34) -- (20.18,-14.38)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((20.18,-14.38) -- (9.67,-18.34)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((20.18,-14.38) -- (31.79,-8.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((31.79,-8.56) -- (20.18,-14.38)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((31.79,-8.56) -- (34.89,-11.19)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((34.89,-11.19) -- (31.79,-8.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((34.89,-11.19) -- (38.21,-9.30)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((38.21,-9.30) -- (34.89,-11.19)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((38.21,-9.30) -- (41.96,-2.91)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((41.96,-2.91) -- (38.21,-9.30)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((41.96,-2.91) -- (39.66,3.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((39.66,3.54) -- (41.96,-2.91)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((39.66,3.54) -- (39.32,10.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((39.32,10.84) -- (39.66,3.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((39.32,10.84) -- (37.10,16.43)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((37.10,16.43) -- (39.32,10.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((37.10,16.43) -- (35.49,25.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((35.49,25.03) -- (37.10,16.43)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((35.49,25.03) -- (45.12,29.09)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((35.49,25.03) -- (32.11,20.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((45.12,29.09) -- (60.77,17.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((45.12,29.09) -- (35.49,25.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((60.77,17.01) -- (72.54,14.17)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((60.77,17.01) -- (45.12,29.09)));
endfig;
beginfig(2);
draw_upscrap(1)(1,((3.63,-24.36)
 .. controls (3.63,-24.36) and (3.57,-21.84) .. (4.66,-22.35)
 .. controls (5.76,-22.87) and (8.85,-24.25) .. (8.82,-22.80)
 .. controls (8.79,-21.36) and (8.76,-20.28) .. (10.90,-19.52)
 .. controls (13.05,-18.75) and (20.73,-15.88) .. (21.97,-14.96)
 .. controls (23.21,-14.03) and (31.01,-8.64) .. (32.49,-10.41)
 .. controls (33.97,-12.18) and (34.70,-12.70) .. (36.31,-11.94)
 .. controls (37.91,-11.19) and (39.32,-9.90) .. (40.36,-8.08)
 .. controls (41.40,-6.26) and (42.56,-1.37) .. (42.18,-0.48)
 .. controls (41.80,0.41) and (41.22,2.20) .. (41.19,3.64)
 .. controls (41.16,5.08) and (40.01,8.11) .. (40.70,9.57)
 .. controls (41.39,11.03) and (43.88,12.34) .. (43.88,12.34)
),
1,((43.67,13.59)
 .. controls (43.67,13.59) and (40.67,11.01) .. (40.09,12.62)
 .. controls (39.52,14.23) and (40.59,14.79) .. (40.54,16.95)
 .. controls (40.49,19.11) and (39.14,23.40) .. (41.27,24.17)
 .. controls (43.41,24.94) and (45.58,24.08) .. (45.58,24.08)
 -- (45.82,21.21)
),
1,((46.93,19.97)
 .. controls (46.93,19.97) and (47.01,24.11) .. (48.11,23.41)
 .. controls (49.20,22.72) and (55.56,19.07) .. (56.85,18.02)
 .. controls (58.13,16.97) and (63.56,14.74) .. (63.56,14.74)
),
1,((64.03,17.81)
 .. controls (64.03,17.81) and (53.26,26.04) .. (52.70,27.28)
 .. controls (52.13,28.53) and (53.60,35.40) .. (51.95,36.98)
 .. controls (50.30,38.56) and (43.66,37.88) .. (42.19,39.28)
 .. controls (40.72,40.68) and (39.95,43.00) .. (39.95,43.00)
),
1,((37.99,42.06)
 .. controls (37.99,42.06) and (40.18,40.85) .. (39.32,39.22)
 .. controls (38.46,37.58) and (35.97,28.54) .. (34.55,27.43)
 .. controls (33.14,26.32) and (29.96,23.91) .. (29.46,22.46)
 .. controls (28.95,21.01) and (28.36,15.60) .. (26.73,15.93)
 .. controls (25.10,16.25) and (25.18,13.19) .. (23.20,13.14)
 .. controls (21.22,13.09) and (19.20,14.48) .. (19.20,14.48)
),
1,((17.62,12.82)
 .. controls (17.62,12.82) and (23.03,12.60) .. (20.90,11.47)
 .. controls (18.76,10.34) and (17.58,7.26) .. (16.84,7.96)
 .. controls (16.11,8.66) and (15.51,10.98) .. (15.51,10.98)
),
1,((13.72,10.39)
 .. controls (13.72,10.39) and (15.03,8.63) .. (14.89,6.65)
 .. controls (14.76,4.67) and (15.70,2.90) .. (13.40,1.59)
 .. controls (11.09,0.28) and (3.64,-3.84) .. (2.54,-2.97)
 .. controls (1.45,-2.09) and (-3.61,6.93) .. (-3.61,6.93)
),
1,((-5.61,7.42)
 .. controls (-5.61,7.42) and (-2.61,3.22) .. (-4.06,3.54)
 .. controls (-5.51,3.87) and (-8.71,1.98) .. (-9.83,3.38)
 .. controls (-10.95,4.78) and (-9.75,7.30) .. (-11.78,8.47)
 .. controls (-13.81,9.64) and (-15.39,7.81) .. (-16.40,10.39)
 .. controls (-17.40,12.98) and (-16.90,14.79) .. (-16.90,14.79)
),
1,((-18.75,14.84)
 .. controls (-18.75,14.84) and (-16.72,9.32) .. (-18.15,8.38)
 .. controls (-19.57,7.44) and (-22.35,8.48) .. (-23.80,8.46)
 .. controls (-25.21,8.44) and (-27.07,9.10) .. (-27.21,9.77)
 .. controls (-27.36,10.45) and (-26.81,12.04) .. (-26.81,12.04)
),
1,((-33.25,10.09)
 .. controls (-33.25,10.09) and (-31.03,9.06) .. (-31.09,8.16)
 .. controls (-31.14,7.25) and (-29.66,4.88) .. (-31.62,3.37)
 .. controls (-33.59,1.85) and (-36.53,2.08) .. (-36.53,2.08)
),
1,((-36.28,0.34)
 .. controls (-36.28,0.34) and (-31.17,0.75) .. (-30.07,0.80)
 .. controls (-28.98,0.85) and (-27.90,-0.62) .. (-28.06,-2.07)
 .. controls (-28.22,-3.51) and (-27.70,-2.78) .. (-29.97,-5.32)
 .. controls (-32.25,-7.87) and (-33.72,-6.67) .. (-34.54,-9.90)
 .. controls (-35.37,-13.17) and (-34.00,-18.17) .. (-35.97,-18.57)
 .. controls (-37.94,-18.96) and (-40.65,-18.66) .. (-41.33,-20.29)
 .. controls (-42.02,-21.93) and (-44.07,-26.83) .. (-45.69,-26.69)
 .. controls (-47.31,-26.54) and (-46.98,-25.46) .. (-48.26,-24.95)
 .. controls (-49.53,-24.44) and (-51.32,-24.85) .. (-51.32,-24.85)
),
1,((-51.82,-26.84)
 .. controls (-51.82,-26.84) and (-49.66,-26.42) .. (-49.63,-27.86)
 .. controls (-49.59,-29.30) and (-50.64,-30.95) .. (-48.65,-31.26)
 .. controls (-46.66,-31.57) and (-45.60,-30.46) .. (-44.52,-30.44)
 .. controls (-43.45,-30.42) and (-41.63,-31.28) .. (-41.63,-31.28)
),
1,((-41.63,-31.28)
 .. controls (-41.63,-31.28) and (-36.56,-33.16) .. (-35.13,-32.60)
 .. controls (-33.70,-32.03) and (-34.11,-29.87) .. (-29.97,-29.79)
 .. controls (-25.84,-29.70) and (-25.67,-29.34) .. (-24.05,-29.31)
 .. controls (-22.43,-29.28) and (-19.02,-29.75) .. (-19.02,-29.75)
),
1,((-19.07,-27.41)
 .. controls (-19.07,-27.41) and (-23.16,-29.11) .. (-22.66,-26.94)
 .. controls (-22.17,-24.77) and (-22.76,-22.26) .. (-21.69,-22.24)
 .. controls (-20.61,-22.22) and (-18.81,-22.36) .. (-18.81,-22.36)
),
1,((-19.93,-20.41)
 .. controls (-19.93,-20.41) and (-21.90,-20.45) .. (-23.70,-20.48)
 .. controls (-25.49,-20.51) and (-27.12,-20.18) .. (-27.12,-20.18)
),
1,((-27.12,-20.18)
 .. controls (-27.12,-20.18) and (-29.63,-20.04) .. (-29.66,-18.79)
 .. controls (-29.70,-17.54) and (-31.06,-11.97) .. (-30.17,-11.60)
 .. controls (-29.28,-11.22) and (-28.71,-13.20) .. (-24.79,-11.51)
 .. controls (-20.88,-9.82) and (-13.97,-4.44) .. (-11.83,-3.30)
 .. controls (-9.70,-2.17) and (-5.79,0.46) .. (-5.05,-0.42)
 .. controls (-4.32,-1.31) and (-0.12,-4.28) .. (-0.10,-5.36)
 .. controls (-0.08,-6.44) and (-1.83,-9.18) .. (-1.83,-9.18)
),
1,((0.70,-10.02)
 .. controls (0.70,-10.02) and (1.37,-7.12) .. (2.26,-6.74)
 .. controls (3.15,-6.37) and (14.90,-0.89) .. (16.16,-1.22)
 .. controls (17.42,-1.55) and (19.59,-2.05) .. (19.59,-2.05)
),
1,((20.98,-0.22)
 .. controls (20.98,-0.22) and (17.03,0.06) .. (18.45,0.81)
 .. controls (19.87,1.56) and (21.59,4.84) .. (23.34,7.03)
 .. controls (25.08,9.23) and (27.34,12.88) .. (28.40,13.63)
 .. controls (29.46,14.37) and (31.81,13.52) .. (31.81,13.52)
),
1,((32.85,15.16)
 .. controls (32.85,15.16) and (29.63,15.09) .. (31.04,16.20)
 .. controls (32.45,17.31) and (34.65,23.12) .. (34.89,20.43)
 .. controls (35.12,17.73) and (37.75,12.93) .. (37.77,11.85)
 .. controls (37.79,10.77) and (38.08,5.91) .. (38.30,4.12)
 .. controls (38.52,2.32) and (40.75,-0.87) .. (40.42,-2.50)
 .. controls (40.10,-4.13) and (38.20,-7.95) .. (37.13,-8.51)
 .. controls (36.06,-9.07) and (34.85,-11.26) .. (34.10,-9.83)
 .. controls (33.35,-8.41) and (32.58,-6.27) .. (31.86,-6.11)
 .. controls (31.14,-5.94) and (30.02,-4.35) .. (30.02,-4.35)
),
1,((28.78,-5.46)
 .. controls (28.78,-5.46) and (31.52,-7.01) .. (30.10,-7.94)
 .. controls (28.68,-8.88) and (21.73,-12.26) .. (20.12,-12.84)
 .. controls (18.51,-13.41) and (9.20,-15.60) .. (8.69,-17.23)
 .. controls (8.19,-18.86) and (8.04,-20.12) .. (6.60,-20.15)
 .. controls (5.15,-20.18) and (4.42,-19.48) .. (3.53,-20.22)
 .. controls (2.65,-20.96) and (1.43,-22.61) .. (1.43,-22.61)
));
draw_upscrap(0)(1,((-33.64,-26.44)
 .. controls (-33.64,-26.44) and (-34.47,-30.06) .. (-35.90,-30.45)
 .. controls (-37.33,-30.84) and (-40.78,-29.28) .. (-40.78,-29.28)
),
1,((-40.78,-29.28)
 .. controls (-40.78,-29.28) and (-43.64,-29.52) .. (-42.60,-27.88)
 .. controls (-41.56,-26.24) and (-39.84,-22.60) .. (-38.76,-22.76)
 .. controls (-37.67,-22.92) and (-33.02,-21.55) .. (-32.99,-23.17)
 .. controls (-32.95,-24.80) and (-33.64,-26.44) .. (-33.64,-26.44)
));
draw_upscrap(0)(1,((-28.33,-21.99)
 .. controls (-28.33,-21.99) and (-23.86,-21.20) .. (-23.84,-22.46)
 .. controls (-23.81,-23.72) and (-24.82,-26.80) .. (-24.82,-26.80)
 .. controls (-24.82,-26.80) and (-26.97,-27.02) .. (-28.58,-27.41)
 .. controls (-30.19,-27.81) and (-31.64,-27.30) .. (-31.64,-27.30)
),
1,((-31.64,-27.30)
 .. controls (-31.64,-27.30) and (-30.60,-25.29) .. (-30.26,-24.19)
 .. controls (-29.92,-23.10) and (-29.59,-22.01) .. (-28.33,-21.99)
));
draw_upscrap(0)(1,((-25.76,-0.23)
 .. controls (-25.76,-0.23) and (-21.10,-0.51) .. (-21.99,-0.89)
 .. controls (-22.88,-1.27) and (-25.34,-3.64) .. (-26.43,-3.30)
 .. controls (-27.51,-2.96) and (-25.76,-0.23) .. cycle
));
draw_upscrap(0)(1,((37.53,23.18)
 .. controls (38.43,22.84) and (40.07,19.18) .. (39.26,18.00)
 .. controls (38.38,16.72) and (39.51,14.59) .. (38.77,15.47)
 .. controls (38.03,16.35) and (37.06,19.57) .. (37.04,20.83)
 .. controls (37.01,22.09) and (36.62,23.52) .. cycle
));
draw_downscrap;
endfig;
beginfig(3);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((64.03,17.81)
 .. controls (64.03,17.81) and (53.26,26.04) .. (52.70,27.28)
 .. controls (52.13,28.53) and (53.60,35.40) .. (51.95,36.98)
 .. controls (50.30,38.56) and (43.66,37.88) .. (42.19,39.28)
 .. controls (40.72,40.68) and (39.95,43.00) .. (39.95,43.00)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((37.99,42.06)
 .. controls (37.99,42.06) and (40.18,40.85) .. (39.32,39.22)
 .. controls (38.46,37.58) and (35.97,28.54) .. (34.55,27.43)
 .. controls (33.14,26.32) and (29.96,23.91) .. (29.46,22.46)
 .. controls (28.95,21.01) and (28.36,15.60) .. (26.73,15.93)
 .. controls (25.10,16.25) and (25.18,13.19) .. (23.20,13.14)
 .. controls (21.22,13.09) and (19.20,14.48) .. (19.20,14.48)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((17.62,12.82)
 .. controls (17.62,12.82) and (23.03,12.60) .. (20.90,11.47)
 .. controls (18.76,10.34) and (17.58,7.26) .. (16.84,7.96)
 .. controls (16.11,8.66) and (15.51,10.98) .. (15.51,10.98)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((13.72,10.39)
 .. controls (13.72,10.39) and (15.03,8.63) .. (14.89,6.65)
 .. controls (14.76,4.67) and (15.70,2.90) .. (13.40,1.59)
 .. controls (11.09,0.28) and (3.64,-3.84) .. (2.54,-2.97)
 .. controls (1.45,-2.09) and (-3.61,6.93) .. (-3.61,6.93)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((0.70,-10.02)
 .. controls (0.70,-10.02) and (1.37,-7.12) .. (2.26,-6.74)
 .. controls (3.15,-6.37) and (14.90,-0.89) .. (16.16,-1.22)
 .. controls (17.42,-1.55) and (19.59,-2.05) .. (19.59,-2.05)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((20.98,-0.22)
 .. controls (20.98,-0.22) and (17.03,0.06) .. (18.45,0.81)
 .. controls (19.87,1.56) and (21.59,4.84) .. (23.34,7.03)
 .. controls (25.08,9.23) and (27.34,12.88) .. (28.40,13.63)
 .. controls (29.46,14.37) and (31.81,13.52) .. (31.81,13.52)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((32.85,15.16)
 .. controls (32.85,15.16) and (29.63,15.09) .. (31.04,16.20)
 .. controls (32.45,17.31) and (34.65,23.12) .. (34.89,20.43)
 .. controls (35.12,17.73) and (37.75,12.93) .. (37.77,11.85)
 .. controls (37.79,10.77) and (38.08,5.91) .. (38.30,4.12)
 .. controls (38.52,2.32) and (40.75,-0.87) .. (40.42,-2.50)
 .. controls (40.10,-4.13) and (38.20,-7.95) .. (37.13,-8.51)
 .. controls (36.06,-9.07) and (34.85,-11.26) .. (34.10,-9.83)
 .. controls (33.35,-8.41) and (32.58,-6.27) .. (31.86,-6.11)
 .. controls (31.14,-5.94) and (30.02,-4.35) .. (30.02,-4.35)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((28.78,-5.46)
 .. controls (28.78,-5.46) and (31.52,-7.01) .. (30.10,-7.94)
 .. controls (28.68,-8.88) and (21.73,-12.26) .. (20.12,-12.84)
 .. controls (18.51,-13.41) and (9.20,-15.60) .. (8.69,-17.23)
 .. controls (8.19,-18.86) and (8.04,-20.12) .. (6.60,-20.15)
 .. controls (5.15,-20.18) and (4.42,-19.48) .. (3.53,-20.22)
 .. controls (2.65,-20.96) and (1.43,-22.61) .. (1.43,-22.61)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((3.63,-24.36)
 .. controls (3.63,-24.36) and (3.57,-21.84) .. (4.66,-22.35)
 .. controls (5.76,-22.87) and (8.85,-24.25) .. (8.82,-22.80)
 .. controls (8.79,-21.36) and (8.76,-20.28) .. (10.90,-19.52)
 .. controls (13.05,-18.75) and (20.73,-15.88) .. (21.97,-14.96)
 .. controls (23.21,-14.03) and (31.01,-8.64) .. (32.49,-10.41)
 .. controls (33.97,-12.18) and (34.70,-12.70) .. (36.31,-11.94)
 .. controls (37.91,-11.19) and (39.32,-9.90) .. (40.36,-8.08)
 .. controls (41.40,-6.26) and (42.56,-1.37) .. (42.18,-0.48)
 .. controls (41.80,0.41) and (41.22,2.20) .. (41.19,3.64)
 .. controls (41.16,5.08) and (40.01,8.11) .. (40.70,9.57)
 .. controls (41.39,11.03) and (43.88,12.34) .. (43.88,12.34)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((43.67,13.59)
 .. controls (43.67,13.59) and (40.67,11.01) .. (40.09,12.62)
 .. controls (39.52,14.23) and (40.59,14.79) .. (40.54,16.95)
 .. controls (40.49,19.11) and (39.14,23.40) .. (41.27,24.17)
 .. controls (43.41,24.94) and (45.58,24.08) .. (45.58,24.08)
 -- (45.82,21.21)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((46.93,19.97)
 .. controls (46.93,19.97) and (47.01,24.11) .. (48.11,23.41)
 .. controls (49.20,22.72) and (55.56,19.07) .. (56.85,18.02)
 .. controls (58.13,16.97) and (63.56,14.74) .. (63.56,14.74)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((37.53,23.18)
 .. controls (38.43,22.84) and (40.07,19.18) .. (39.26,18.00)
 .. controls (38.38,16.72) and (39.51,14.59) .. (38.77,15.47)
 .. controls (38.03,16.35) and (37.06,19.57) .. (37.04,20.83)
 .. controls (37.01,22.09) and (36.62,23.52) .. cycle
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-25.76,-0.23)
 .. controls (-25.76,-0.23) and (-21.10,-0.51) .. (-21.99,-0.89)
 .. controls (-22.88,-1.27) and (-25.34,-3.64) .. (-26.43,-3.30)
 .. controls (-27.51,-2.96) and (-25.76,-0.23) .. cycle
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-5.61,7.42)
 .. controls (-5.61,7.42) and (-2.61,3.22) .. (-4.06,3.54)
 .. controls (-5.51,3.87) and (-8.71,1.98) .. (-9.83,3.38)
 .. controls (-10.95,4.78) and (-9.75,7.30) .. (-11.78,8.47)
 .. controls (-13.81,9.64) and (-15.39,7.81) .. (-16.40,10.39)
 .. controls (-17.40,12.98) and (-16.90,14.79) .. (-16.90,14.79)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-18.75,14.84)
 .. controls (-18.75,14.84) and (-16.72,9.32) .. (-18.15,8.38)
 .. controls (-19.57,7.44) and (-22.35,8.48) .. (-23.80,8.46)
 .. controls (-25.21,8.44) and (-27.07,9.10) .. (-27.21,9.77)
 .. controls (-27.36,10.45) and (-26.81,12.04) .. (-26.81,12.04)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-33.25,10.09)
 .. controls (-33.25,10.09) and (-31.03,9.06) .. (-31.09,8.16)
 .. controls (-31.14,7.25) and (-29.66,4.88) .. (-31.62,3.37)
 .. controls (-33.59,1.85) and (-36.53,2.08) .. (-36.53,2.08)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-36.28,0.34)
 .. controls (-36.28,0.34) and (-31.17,0.75) .. (-30.07,0.80)
 .. controls (-28.98,0.85) and (-27.90,-0.62) .. (-28.06,-2.07)
 .. controls (-28.22,-3.51) and (-27.70,-2.78) .. (-29.97,-5.32)
 .. controls (-32.25,-7.87) and (-33.72,-6.67) .. (-34.54,-9.90)
 .. controls (-35.37,-13.17) and (-34.00,-18.17) .. (-35.97,-18.57)
 .. controls (-37.94,-18.96) and (-40.65,-18.66) .. (-41.33,-20.29)
 .. controls (-42.02,-21.93) and (-44.07,-26.83) .. (-45.69,-26.69)
 .. controls (-47.31,-26.54) and (-46.98,-25.46) .. (-48.26,-24.95)
 .. controls (-49.53,-24.44) and (-51.32,-24.85) .. (-51.32,-24.85)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-51.82,-26.84)
 .. controls (-51.82,-26.84) and (-49.66,-26.42) .. (-49.63,-27.86)
 .. controls (-49.59,-29.30) and (-50.64,-30.95) .. (-48.65,-31.26)
 .. controls (-46.66,-31.57) and (-45.60,-30.46) .. (-44.52,-30.44)
 .. controls (-43.45,-30.42) and (-41.63,-31.28) .. (-41.63,-31.28)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-40.78,-29.28)
 .. controls (-40.78,-29.28) and (-43.64,-29.52) .. (-42.60,-27.88)
 .. controls (-41.56,-26.24) and (-39.84,-22.60) .. (-38.76,-22.76)
 .. controls (-37.67,-22.92) and (-33.02,-21.55) .. (-32.99,-23.17)
 .. controls (-32.95,-24.80) and (-33.64,-26.44) .. (-33.64,-26.44)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-31.64,-27.30)
 .. controls (-31.64,-27.30) and (-30.60,-25.29) .. (-30.26,-24.19)
 .. controls (-29.92,-23.10) and (-29.59,-22.01) .. (-28.33,-21.99)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-27.12,-20.18)
 .. controls (-27.12,-20.18) and (-29.63,-20.04) .. (-29.66,-18.79)
 .. controls (-29.70,-17.54) and (-31.06,-11.97) .. (-30.17,-11.60)
 .. controls (-29.28,-11.22) and (-28.71,-13.20) .. (-24.79,-11.51)
 .. controls (-20.88,-9.82) and (-13.97,-4.44) .. (-11.83,-3.30)
 .. controls (-9.70,-2.17) and (-5.79,0.46) .. (-5.05,-0.42)
 .. controls (-4.32,-1.31) and (-0.12,-4.28) .. (-0.10,-5.36)
 .. controls (-0.08,-6.44) and (-1.83,-9.18) .. (-1.83,-9.18)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-19.93,-20.41)
 .. controls (-19.93,-20.41) and (-21.90,-20.45) .. (-23.70,-20.48)
 .. controls (-25.49,-20.51) and (-27.12,-20.18) .. (-27.12,-20.18)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-28.33,-21.99)
 .. controls (-28.33,-21.99) and (-23.86,-21.20) .. (-23.84,-22.46)
 .. controls (-23.81,-23.72) and (-24.82,-26.80) .. (-24.82,-26.80)
 .. controls (-24.82,-26.80) and (-26.97,-27.02) .. (-28.58,-27.41)
 .. controls (-30.19,-27.81) and (-31.64,-27.30) .. (-31.64,-27.30)
));
drawoptions();
p_narrowend((-16.01,-28.42),97.4,1.00,(0,0));
drawoptions();
p_narrowend((-15.63,-20.49),97.4,1.00,(0,0));
drawoptions();
p_narrowend((-0.90,-12.76),344.5,1.00,(0,0));
drawoptions();
p_narrowend((0.62,-26.96),330.0,1.00,(0,0));
drawoptions();
p_narrowend((-41.03,1.62),271.0,1.00,(0,0));
drawoptions();
p_narrowend((-18.09,19.05),182.5,1.00,(0,0));
drawoptions();
p_narrowend((-5.55,11.87),195.1,1.00,(0,0));
drawoptions();
p_narrowend((12.93,13.42),204.5,1.00,(0,0));
drawoptions();
p_narrowend((15.56,16.37),229.8,1.00,(0,0));
drawoptions();
p_narrowend((27.47,-2.60),221.0,1.00,(0,0));
drawoptions();
p_narrowend((22.45,-1.80),75.6,1.00,(0,0));
drawoptions();
p_narrowend((33.63,12.12),52.9,1.00,(0,0));
drawoptions();
p_narrowend((45.59,16.34),340.2,1.00,(0,0));
drawoptions();
p_narrowend((-56.00,-25.33),259.5,1.00,(0,0));
string ATTR_code;
ATTR_code := "D";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \thfc\char233 \thfb\char116 \char114 \char111 \char105 \char116 \mainfont{}etex;
drawoptions();
p_continuation((-54.22,-31.94),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
drawoptions();
p_dig((-34.26,6.35),0.0,1.00,(0,0));
drawoptions();
p_archeomaterial((3.36,0.45),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((38.67,28.06),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((-10.48,0.68),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((-16.89,-2.70),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((25.51,22.00),0.0,0.50,(0,0));
ATTR__height := -1;
drawoptions();
l_gradient(((42.60,37.13)
 -- (45.15,27.67)
));
drawoptions();
p_narrowend((37.91,45.83),200.4,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-33.64,-26.44)
 .. controls (-33.64,-26.44) and (-34.47,-30.06) .. (-35.90,-30.45)
 .. controls (-37.33,-30.84) and (-40.78,-29.28) .. (-40.78,-29.28)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-41.63,-31.28)
 .. controls (-41.63,-31.28) and (-36.56,-33.16) .. (-35.13,-32.60)
 .. controls (-33.70,-32.03) and (-34.11,-29.87) .. (-29.97,-29.79)
 .. controls (-25.84,-29.70) and (-25.67,-29.34) .. (-24.05,-29.31)
 .. controls (-22.43,-29.28) and (-19.02,-29.75) .. (-19.02,-29.75)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-19.07,-27.41)
 .. controls (-19.07,-27.41) and (-23.16,-29.11) .. (-22.66,-26.94)
 .. controls (-22.17,-24.77) and (-22.76,-22.26) .. (-21.69,-22.24)
 .. controls (-20.61,-22.22) and (-18.81,-22.36) .. (-18.81,-22.36)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((60.77,17.01),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((45.12,29.09),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((35.49,25.03),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((37.10,16.43),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((39.32,10.84),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((39.66,3.54),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((41.96,-2.91),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((38.21,-9.30),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((34.89,-11.19),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((31.79,-8.56),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((20.18,-14.38),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((9.67,-18.34),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((7.44,-21.86),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((4.50,-21.06),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((2.65,-23.39),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((32.11,20.96),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((26.98,13.61),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((18.85,5.48),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((15.36,0.07),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((1.65,-4.86),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-4.15,1.10),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-14.77,0.61),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-28.91,1.96),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-27.81,6.77),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-28.68,-8.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-31.99,-10.84),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-30.69,-22.00),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-39.21,-20.44),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-45.41,-29.18),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-47.32,-27.88),1,0,"");
endfig;
beginfig(4);
drawoptions(withcolor (1.000000,0.500000,0.000000));
p_label(btex \thaltitude \thfb\char49 \char55 \char54 \char51 \mainfont{} etex,(-50.07,-17.29),0.0,1);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char45 \char57 \char51 \ \char109 \mainfont{} etex,(-63.45,-38.84),0.0,0);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char49 \char56 \mainfont{} etex,(-46.71,-37.53),0.0,7);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char103 \char46 \ \char100 \char117 \ \char82 \char111 \char110 \char100 \ \char80 \char111 \char105 \char110 \char116 \mainfont{} etex,(-34.85,-45.74),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char109 \char46 \ \char100 \char117 \ \char68 \char111 \char117 \char98 \char108 \char101 \ \char83 \char101 \char110 \char115 \mainfont{} etex,(31.17,-24.12),25.8,0);
endfig;
current_scrap := "A24-1";
ATTR__scrap := "A24-1";
beginfig(5);
drawoptions();
p_blocks((2.50,3.63),0.0,0.50,(0,0));
drawoptions();
p_pebbles((-49.35,-36.02),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-45.52,-37.72),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-45.06,-34.47),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-41.25,-35.45),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-42.62,-31.34),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-38.78,-33.41),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-41.26,-28.07),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-44.02,-25.79),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-50.34,-25.59),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-48.47,-28.25),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-49.38,-20.69),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-36.38,-28.85),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-33.37,-26.97),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-33.82,-30.22),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-29.41,-26.87),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-1.07,-16.78),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-7.71,-17.51),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-9.05,-20.77),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-9.13,-24.55),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-7.72,-30.09),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-11.54,-22.09),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-5.90,-23.93),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-4.34,-28.57),0.0,0.71,(0,0));
drawoptions();
p_pebbles((0.14,-27.73),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-1.84,-21.48),0.0,0.71,(0,0));
drawoptions();
p_pebbles((2.03,-17.59),0.0,0.71,(0,0));
drawoptions();
p_pebbles((3.08,-22.78),0.0,0.71,(0,0));
drawoptions();
p_pebbles((3.39,-27.80),0.0,0.71,(0,0));
drawoptions();
p_pebbles((-0.15,-23.78),0.0,0.71,(0,0));
drawoptions();
p_pebbles((5.10,-17.87),0.0,0.71,(0,0));
drawoptions();
p_pebbles((6.54,-23.76),0.0,0.71,(0,0));
drawoptions();
p_pebbles((28.84,-25.09),0.0,0.71,(0,0));
drawoptions();
p_pebbles((32.44,-23.81),0.0,0.71,(0,0));
drawoptions();
p_pebbles((30.68,-26.86),0.0,0.71,(0,0));
drawoptions();
p_pebbles((25.62,-14.34),0.0,0.71,(0,0));
drawoptions();
p_pebbles((29.82,-16.58),0.0,0.71,(0,0));
drawoptions();
p_pebbles((37.18,-16.95),0.0,0.71,(0,0));
ATTR__height := -1;
drawoptions();
l_contour(((41.38,-1.62)
 .. controls (41.38,-1.62) and (39.61,-2.56) .. (36.69,-1.20)
 .. controls (33.77,0.16) and (30.26,3.30) .. (30.26,3.30)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((41.12,-5.05)
 .. controls (41.12,-5.05) and (38.63,-5.99) .. (35.92,-5.16)
 .. controls (33.20,-4.33) and (30.27,-2.61) .. (30.27,-2.61)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((39.77,-7.95)
 .. controls (39.77,-7.95) and (37.64,-8.70) .. (34.91,-7.51)
 .. controls (32.18,-6.32) and (29.63,-5.13) .. (29.63,-5.13)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((50.68,-6.24)
 .. controls (50.68,-6.24) and (47.98,-6.51) .. (46.51,-5.47)
 .. controls (45.05,-4.42) and (44.12,-3.18) .. (44.12,-3.18)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((50.96,-9.65)
 .. controls (50.96,-9.65) and (49.36,-10.60) .. (47.00,-9.77)
 .. controls (44.63,-8.94) and (42.43,-7.00) .. (42.43,-7.00)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((50.55,-14.34)
 .. controls (50.55,-14.34) and (47.08,-13.01) .. (45.79,-11.78)
 .. controls (44.51,-10.55) and (42.12,-8.80) .. (42.12,-8.80)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-45.77,-20.60)
 .. controls (-45.77,-20.60) and (-46.98,-22.80) .. (-49.13,-23.57)
 .. controls (-51.28,-24.35) and (-54.52,-24.43) .. (-54.52,-24.43)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-43.03,-22.16)
 .. controls (-43.03,-22.16) and (-45.82,-25.84) .. (-48.51,-26.63)
 .. controls (-51.20,-27.42) and (-54.45,-27.13) .. (-54.45,-27.13)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-41.92,-23.40)
 .. controls (-41.92,-23.40) and (-42.02,-26.46) .. (-44.87,-27.80)
 .. controls (-47.73,-29.13) and (-51.30,-30.48) .. (-51.30,-30.48)
),-1);
ATTR__height := -1;
drawoptions();
l_pit(((40.36,-9.73)
 .. controls (40.36,-9.73) and (41.28,-10.61) .. (36.81,-10.69)
 .. controls (32.33,-10.78) and (29.38,-8.72) .. (28.63,-7.66)
 .. controls (27.88,-6.61) and (25.10,-9.72) .. (25.10,-9.72)
 .. controls (25.10,-9.72) and (26.12,-13.25) .. (29.20,-14.08)
 .. controls (32.28,-14.90) and (34.99,-15.74) .. (37.30,-14.98)
 .. controls (39.60,-14.23) and (41.36,-13.30) .. (41.36,-13.30)
));
ATTR__height := -1;
drawoptions();
l_overhang(((-47.73,-21.91)
 .. controls (-47.73,-21.91) and (-49.78,-19.25) .. (-51.04,-19.47)
 .. controls (-52.30,-19.68) and (-53.93,-19.18) .. (-53.55,-20.25)
 .. controls (-53.16,-21.33) and (-54.56,-23.17) .. (-52.93,-23.13)
 .. controls (-51.31,-23.09) and (-47.73,-21.91) .. cycle
));
ATTR__height := -1;
drawoptions();
l_contour(((-2.15,-29.41)
 .. controls (-2.15,-29.41) and (-4.55,-27.49) .. (-4.61,-25.16)
 .. controls (-4.68,-22.82) and (-4.55,-21.20) .. (-4.55,-21.20)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-4.64,-30.55)
 .. controls (-4.64,-30.55) and (-6.90,-27.38) .. (-6.93,-25.94)
 .. controls (-6.97,-24.50) and (-6.68,-21.97) .. (-6.68,-21.97)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((1.22,-20.85)
 .. controls (1.22,-20.85) and (2.55,-23.34) .. (2.42,-25.14)
 .. controls (2.28,-26.94) and (1.64,-29.47) .. (1.64,-29.47)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((4.29,-20.94)
 .. controls (4.29,-20.94) and (5.83,-24.32) .. (5.51,-25.76)
 .. controls (5.18,-27.21) and (4.71,-29.56) .. (4.71,-29.56)
),-1);
ATTR__height := -1;
drawoptions();
l_chimney(((37.40,-18.38)
 .. controls (37.40,-18.38) and (37.84,-21.25) .. (37.93,-23.17)
 .. controls (38.01,-25.10) and (38.84,-24.67) .. (40.24,-24.67)
 .. controls (41.67,-24.67) and (40.13,-22.04) .. (40.11,-20.55)
 .. controls (40.09,-19.08) and (37.40,-18.38) .. cycle
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((40.70,15.82) -- (50.02,-0.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((36.98,5.63) -- (50.02,-0.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((36.98,5.63) -- (32.24,-20.78)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((60.72,-8.56) -- (50.02,-0.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((50.02,-0.15) -- (40.70,15.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((50.02,-0.15) -- (36.98,5.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((50.02,-0.15) -- (60.72,-8.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((50.02,-0.15) -- (46.48,-7.48)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((46.48,-7.48) -- (50.02,-0.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((46.48,-7.48) -- (46.36,-14.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((46.36,-14.42) -- (46.48,-7.48)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((46.36,-14.42) -- (40.49,-22.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((45.88,-18.52) -- (40.49,-22.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((47.97,-24.23) -- (40.49,-22.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((55.10,-25.99) -- (40.49,-22.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((48.93,-31.78) -- (40.49,-22.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((43.15,-33.80) -- (40.49,-22.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((40.10,-26.94) -- (40.49,-22.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((40.49,-22.39) -- (40.10,-26.94)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((40.49,-22.39) -- (46.36,-14.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((40.49,-22.39) -- (55.10,-25.99)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((40.49,-22.39) -- (45.88,-18.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((40.49,-22.39) -- (47.97,-24.23)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((40.49,-22.39) -- (48.93,-31.78)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((40.49,-22.39) -- (43.15,-33.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((40.49,-22.39) -- (32.80,-28.87)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((40.49,-22.39) -- (32.24,-20.78)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((32.24,-20.78) -- (40.49,-22.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((32.24,-20.78) -- (36.98,5.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((32.24,-20.78) -- (12.49,-25.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((32.24,-20.78) -- (33.77,-30.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((32.24,-20.78) -- (17.18,-18.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((12.49,-25.82) -- (8.79,-11.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((12.49,-25.82) -- (32.24,-20.78)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((12.49,-25.82) -- (-2.03,-25.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((8.79,-11.97) -- (4.66,-6.74)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((8.79,-11.97) -- (12.49,-25.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((4.66,-6.74) -- (2.39,1.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((4.66,-6.74) -- (8.79,-11.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.39,1.76) -- (6.97,9.13)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.39,1.76) -- (4.66,-6.74)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((6.97,9.13) -- (2.39,1.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2.03,-25.37) -- (-3.94,-18.21)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2.03,-25.37) -- (12.49,-25.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2.03,-25.37) -- (-10.40,-27.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-3.94,-18.21) -- (-12.04,-4.32)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-3.94,-18.21) -- (-2.03,-25.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-12.04,-4.32) -- (-3.94,-18.21)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-51.80,-21.53) -- (-47.37,-26.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-51.80,-21.53) -- (-51.76,-21.41)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-47.37,-26.37) -- (-37.25,-30.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-47.37,-26.37) -- (-51.80,-21.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-37.25,-30.97) -- (-30.84,-28.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-37.25,-30.97) -- (-47.37,-26.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-30.84,-28.51) -- (-23.79,-29.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-30.84,-28.51) -- (-37.25,-30.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-23.79,-29.29) -- (-21.26,-16.45)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-23.79,-29.29) -- (-15.70,-29.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-23.79,-29.29) -- (-30.84,-28.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-15.70,-29.53) -- (-10.40,-27.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-15.70,-29.53) -- (-23.79,-29.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-28.50,-17.29) -- (-10.40,-27.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-10.40,-27.01) -- (-28.50,-17.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-10.40,-27.01) -- (-22.25,-9.34)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-10.40,-27.01) -- (-2.03,-25.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-10.40,-27.01) -- (-15.70,-29.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-22.25,-9.34) -- (-26.82,1.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-22.25,-9.34) -- (-10.40,-27.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-26.82,1.89) -- (-31.79,4.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-26.82,1.89) -- (-22.25,-9.34)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-31.79,4.47) -- (-34.99,0.12)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-31.79,4.47) -- (-26.82,1.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-34.99,0.12) -- (-31.79,4.47)));
endfig;
beginfig(6);
draw_upscrap(1)(1,((-51.04,-19.47)
 .. controls (-51.04,-19.47) and (-53.58,-18.81) .. (-53.55,-20.25)
 .. controls (-53.51,-21.70) and (-54.06,-21.53) .. (-52.93,-23.13)
 .. controls (-51.81,-24.72) and (-52.71,-24.75) .. (-52.48,-26.73)
 .. controls (-52.25,-28.70) and (-50.07,-29.01) .. (-49.34,-29.53)
 .. controls (-48.60,-30.06) and (-42.83,-30.27) .. (-45.12,-32.31)
 .. controls (-47.41,-34.35) and (-52.67,-33.22) .. (-52.43,-35.56)
 .. controls (-52.19,-37.90) and (-54.28,-40.29) .. (-50.14,-40.00)
 .. controls (-46.00,-39.72) and (-38.89,-36.11) .. (-36.60,-34.43)
 .. controls (-34.30,-32.76) and (-32.75,-30.02) .. (-30.76,-30.32)
 .. controls (-28.77,-30.63) and (-27.53,-30.25) .. (-23.53,-31.58)
 .. controls (-19.53,-32.92) and (-17.02,-32.49) .. (-15.23,-32.45)
 .. controls (-13.43,-32.40) and (-13.64,-37.05) .. (-10.96,-36.83)
 .. controls (-7.72,-36.56) and (-9.97,-33.57) .. (-6.74,-32.94)
 .. controls (-3.51,-32.31) and (-2.80,-32.11) .. (0.61,-31.47)
 .. controls (4.02,-30.83) and (11.75,-29.90) .. (11.75,-29.90)
 .. controls (11.75,-29.90) and (9.11,-32.12) .. (10.38,-32.25)
 .. controls (11.65,-32.39) and (11.57,-30.11) .. (13.93,-30.00)
 .. controls (16.30,-29.90) and (21.49,-29.49) .. (23.19,-29.30)
 .. controls (24.91,-29.10) and (28.33,-26.99) .. (28.33,-26.99)
),
1,((34.77,-25.04)
 .. controls (34.77,-25.04) and (38.32,-26.27) .. (39.09,-28.10)
 .. controls (39.84,-29.86) and (39.84,-35.31) .. (42.13,-35.10)
 .. controls (44.46,-34.90) and (48.22,-34.04) .. (49.10,-33.48)
 .. controls (49.98,-32.92) and (49.27,-26.62) .. (50.72,-26.76)
 .. controls (52.16,-26.90) and (56.15,-28.06) .. (56.15,-28.06)
),
1,((57.12,-23.89)
 .. controls (57.12,-23.89) and (50.98,-23.52) .. (49.88,-22.65)
 .. controls (48.77,-21.78) and (42.87,-22.82) .. (44.81,-21.33)
 .. controls (46.73,-19.86) and (47.78,-18.57) .. (48.08,-16.22)
 .. controls (48.37,-13.87) and (50.87,-12.89) .. (50.12,-11.65)
 .. controls (49.36,-10.42) and (48.61,-9.72) .. (48.92,-7.74)
 .. controls (49.22,-5.75) and (47.90,-3.45) .. (49.88,-3.57)
 .. controls (51.87,-3.69) and (59.27,-11.05) .. (59.27,-11.05)
),
1,((59.27,-11.05)
 -- (64.25,-14.85)
),
1,((66.19,-13.17)
 -- (62.75,-6.81)
),
1,((62.75,-6.81)
 .. controls (62.75,-6.81) and (63.06,-4.63) .. (63.01,-2.65)
 .. controls (62.95,-0.66) and (63.97,1.71) .. (63.97,1.71)
),
1,((63.97,1.71)
 -- (66.50,8.27)
),
1,((63.05,9.07)
 -- (60.69,3.24)
),
1,((60.69,3.24)
 .. controls (60.69,3.24) and (59.38,-1.67) .. (57.20,-1.01)
 .. controls (55.02,-0.35) and (52.28,0.81) .. (51.68,2.96)
 .. controls (51.08,5.12) and (43.38,16.05) .. (43.51,18.04)
 .. controls (43.64,20.03) and (44.13,22.03) .. (44.13,22.03)
),
1,((44.13,22.03)
 .. controls (44.13,22.03) and (43.08,27.78) .. (45.06,27.84)
 .. controls (47.04,27.89) and (54.40,28.64) .. (54.40,28.64)
),
1,((55.45,36.42)
 .. controls (55.45,36.42) and (50.96,35.93) .. (43.57,36.27)
 .. controls (36.18,36.60) and (33.03,39.76) .. (33.03,39.76)
 -- (30.45,42.04)
),
1,((27.84,38.72)
 .. controls (27.84,38.72) and (34.91,36.75) .. (34.99,33.87)
 .. controls (35.07,30.99) and (35.28,23.23) .. (35.28,23.23)
),
1,((35.28,23.23)
 .. controls (35.28,23.23) and (33.61,11.66) .. (32.16,5.67)
 .. controls (30.73,-0.27) and (33.08,-6.48) .. (29.74,-8.71)
 .. controls (26.40,-10.93) and (24.21,-10.10) .. (23.13,-15.29)
 .. controls (22.07,-20.44) and (19.88,-15.57) .. (17.70,-15.48)
 .. controls (15.51,-15.38) and (15.39,-17.35) .. (13.19,-16.72)
 .. controls (11.00,-16.09) and (10.72,-13.24) .. (10.15,-12.55)
 .. controls (9.59,-11.85) and (5.68,-7.09) .. (5.65,-6.01)
 .. controls (5.62,-4.93) and (3.13,0.40) .. (4.21,0.43)
 .. controls (5.29,0.47) and (7.32,-1.27) .. (7.27,0.53)
 .. controls (7.22,2.33) and (7.08,7.17) .. (8.15,7.74)
 .. controls (9.22,8.32) and (11.42,7.13) .. (11.19,8.74)
 .. controls (10.96,10.35) and (8.25,10.63) .. (9.64,12.66)
 .. controls (11.03,14.69) and (11.90,15.79) .. (11.90,15.79)
),
1,((10.43,17.19)
 .. controls (10.43,17.19) and (8.74,12.45) .. (7.46,13.32)
 .. controls (6.18,14.18) and (4.69,16.13) .. (4.69,16.13)
),
1,((3.64,14.84)
 .. controls (3.64,14.84) and (7.65,12.96) .. (6.96,11.86)
 .. controls (6.26,10.75) and (6.49,8.96) .. (4.69,9.09)
 .. controls (2.89,9.23) and (-3.66,5.09) .. (-2.02,4.41)
 .. controls (-0.38,3.73) and (-0.03,3.92) .. (0.57,1.77)
 .. controls (1.17,-0.37) and (1.63,-4.14) .. (3.13,-6.08)
 .. controls (4.62,-8.02) and (7.80,-12.25) .. (7.83,-13.15)
 .. controls (7.86,-14.04) and (8.78,-14.73) .. (6.09,-14.80)
 .. controls (3.39,-14.87) and (-0.93,-15.15) .. (-4.03,-13.80)
 .. controls (-7.13,-12.44) and (-11.73,-2.50) .. (-11.73,-2.50)
),
1,((-13.87,-3.46)
 .. controls (-13.87,-3.46) and (-5.64,-14.21) .. (-6.52,-14.95)
 .. controls (-7.40,-15.70) and (-10.21,-18.10) .. (-10.93,-17.94)
 .. controls (-11.66,-17.78) and (-18.67,-11.86) .. (-20.18,-9.56)
 .. controls (-21.69,-7.26) and (-24.50,3.29) .. (-26.12,3.42)
 .. controls (-27.75,3.55) and (-31.99,6.86) .. (-32.49,5.58)
 .. controls (-32.99,4.31) and (-35.94,0.45) .. (-35.94,0.45)
),
1,((-34.10,-1.12)
 .. controls (-34.10,-1.12) and (-32.99,4.12) .. (-31.71,3.44)
 .. controls (-30.43,2.76) and (-27.54,2.48) .. (-26.95,0.70)
 .. controls (-26.36,-1.09) and (-24.20,-7.51) .. (-23.42,-9.65)
 .. controls (-22.64,-11.79) and (-17.17,-20.27) .. (-18.61,-20.49)
 .. controls (-20.05,-20.71) and (-26.29,-16.57) .. (-27.20,-16.24)
 .. controls (-28.11,-15.90) and (-28.89,-13.76) .. (-28.89,-13.76)
),
1,((-28.89,-13.76)
 -- (-29.15,-10.52)
),
1,((-30.95,-10.57)
 .. controls (-30.95,-10.57) and (-31.93,-14.56) .. (-31.33,-16.53)
 .. controls (-30.74,-18.49) and (-29.19,-22.03) .. (-29.19,-22.03)
 -- (-29.32,-23.46)
),
1,((-29.32,-23.46)
 .. controls (-29.32,-23.46) and (-28.92,-24.70) .. (-30.18,-24.91)
 .. controls (-31.43,-25.12) and (-31.44,-24.94) .. (-33.77,-25.36)
 .. controls (-36.10,-25.78) and (-38.08,-25.46) .. (-40.08,-24.97)
 .. controls (-42.07,-24.48) and (-46.76,-24.42) .. (-47.73,-21.91)
 .. controls (-48.69,-19.41) and (-51.04,-19.47) .. (-51.04,-19.47)
));
draw_upscrap(0)(1,((-27.58,-21.64)
 .. controls (-28.15,-20.76) and (-28.55,-19.51) .. (-28.55,-19.51)
),
1,((-28.55,-19.51)
 .. controls (-28.55,-19.51) and (-28.97,-17.55) .. (-27.30,-18.94)
 .. controls (-25.64,-20.33) and (-23.45,-21.35) .. (-22.15,-22.75)
 .. controls (-20.85,-24.15) and (-21.19,-24.88) .. (-23.16,-24.92)
 .. controls (-25.14,-24.97) and (-27.65,-22.55) .. (-27.58,-21.64)
));
draw_upscrap(0)(1,((39.86,13.43)
 .. controls (39.86,13.43) and (47.13,4.83) .. (46.24,4.44)
 .. controls (45.35,4.06) and (38.99,5.66) .. (38.76,7.64)
 .. controls (38.53,9.62) and (39.86,13.43) .. cycle
));
draw_upscrap(0)(1,((40.59,0.69)
 .. controls (40.59,0.69) and (46.69,1.03) .. (46.19,-0.43)
 .. controls (45.70,-1.88) and (45.89,-2.23) .. (44.20,-6.43)
 .. controls (42.53,-10.59) and (43.10,-18.14) .. (41.29,-17.26)
 .. controls (39.48,-16.38) and (40.34,-15.30) .. (40.07,-12.07)
 .. controls (39.80,-8.85) and (38.22,-10.13) .. (38.16,-7.98)
 .. controls (38.09,-5.83) and (40.59,0.69) .. cycle
));
draw_upscrap(0)(1,((-27.70,-23.60)
 .. controls (-27.70,-23.60) and (-24.79,-24.60) .. (-25.50,-24.98)
 .. controls (-26.21,-25.35) and (-27.83,-25.21) .. (-27.83,-25.21)
 -- cycle
));
draw_downscrap;
endfig;
beginfig(7);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-51.04,-19.47)
 .. controls (-51.04,-19.47) and (-53.58,-18.81) .. (-53.55,-20.25)
 .. controls (-53.51,-21.70) and (-54.06,-21.53) .. (-52.93,-23.13)
 .. controls (-51.81,-24.72) and (-52.71,-24.75) .. (-52.48,-26.73)
 .. controls (-52.25,-28.70) and (-50.07,-29.01) .. (-49.34,-29.53)
 .. controls (-48.60,-30.06) and (-42.83,-30.27) .. (-45.12,-32.31)
 .. controls (-47.41,-34.35) and (-52.67,-33.22) .. (-52.43,-35.56)
 .. controls (-52.19,-37.90) and (-54.28,-40.29) .. (-50.14,-40.00)
 .. controls (-46.00,-39.72) and (-38.89,-36.11) .. (-36.60,-34.43)
 .. controls (-34.30,-32.76) and (-32.75,-30.02) .. (-30.76,-30.32)
 .. controls (-28.77,-30.63) and (-27.53,-30.25) .. (-23.53,-31.58)
 .. controls (-19.53,-32.92) and (-17.02,-32.49) .. (-15.23,-32.45)
 .. controls (-13.43,-32.40) and (-13.64,-37.05) .. (-10.96,-36.83)
 .. controls (-7.72,-36.56) and (-9.97,-33.57) .. (-6.74,-32.94)
 .. controls (-3.51,-32.31) and (-2.80,-32.11) .. (0.61,-31.47)
 .. controls (4.02,-30.83) and (11.75,-29.90) .. (11.75,-29.90)
 .. controls (11.75,-29.90) and (9.11,-32.12) .. (10.38,-32.25)
 .. controls (11.65,-32.39) and (11.57,-30.11) .. (13.93,-30.00)
 .. controls (16.30,-29.90) and (21.49,-29.49) .. (23.19,-29.30)
 .. controls (24.91,-29.10) and (28.33,-26.99) .. (28.33,-26.99)
));
drawoptions();
p_archeomaterial((-11.45,-32.17),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((32.01,-12.23),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((34.68,-17.37),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((45.05,-23.48),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((47.50,-27.56),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((43.43,-29.26),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((48.14,-11.89),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((52.37,-2.42),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((56.33,-2.30),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((58.96,-6.38),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((61.95,-10.44),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((42.14,3.07),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((38.60,26.93),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((40.86,23.02),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((36.67,18.21),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((43.24,14.97),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((45.37,9.82),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((48.19,5.58),0.0,0.50,(0,0));
drawoptions();
p_archeomaterial((-11.21,-34.32),0.0,0.50,(0,0));
drawoptions();
p_entrance((-55.28,-15.60),212.2,1.00,(0,0));
drawoptions();
p_airdraught_summer((-62.81,-3.23),29.2,1.00,(0,0));
string ATTR_code;
ATTR_code := "D";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char67 \char111 \char110 \char100 \char117 \char105 \char116 \char101 \ \char102 \char111 \char114 \char99 \thfc\char233 \thfb\char101 \ \thfc\char184 \ \thfb\char100 \thfc\char233 \thfb\char115 \char111 \char98 \char115 \char116 \char114 \char117 \char101 \char114 \char44 \ \char99 \char111 \char117 \char114 \char97 \char110 \char116 \ \char100 \char39 \char97 \char105 \char114 \char44 \ \char109 \char97 \char105 \char115 \ \char111 \char115 \char115 \char101 \char109 \char101 \char110 \char116 \char115 \ \char101 \char116 \ \char100 \thfc\char233 \thfb\char115 \char111 \char98 \char115 \char116 \char114 \char117 \char99 \char116 \char105 \char111 \char110 \ \char105 \char110 \char116 \char101 \char114 \char100 \char105 \char116 \char101 \ \char97 \char99 \char116 \char117 \char101 \char108 \char108 \char101 \char109 \char101 \char110 \char116 \mainfont{}etex;
drawoptions();
p_continuation((40.61,32.40),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
drawoptions();
p_crystal((2.96,6.71),0.0,0.71,(0,0));
drawoptions();
p_dig((-46.97,-16.12),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-29.32,-23.46)
 .. controls (-29.32,-23.46) and (-28.92,-24.70) .. (-30.18,-24.91)
 .. controls (-31.43,-25.12) and (-31.44,-24.94) .. (-33.77,-25.36)
 .. controls (-36.10,-25.78) and (-38.08,-25.46) .. (-40.08,-24.97)
 .. controls (-42.07,-24.48) and (-46.76,-24.42) .. (-47.73,-21.91)
 .. controls (-48.69,-19.41) and (-51.04,-19.47) .. (-51.04,-19.47)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((34.77,-25.04)
 .. controls (34.77,-25.04) and (38.32,-26.27) .. (39.09,-28.10)
 .. controls (39.84,-29.86) and (39.84,-35.31) .. (42.13,-35.10)
 .. controls (44.46,-34.90) and (48.22,-34.04) .. (49.10,-33.48)
 .. controls (49.98,-32.92) and (49.27,-26.62) .. (50.72,-26.76)
 .. controls (52.16,-26.90) and (56.15,-28.06) .. (56.15,-28.06)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((57.12,-23.89)
 .. controls (57.12,-23.89) and (50.98,-23.52) .. (49.88,-22.65)
 .. controls (48.77,-21.78) and (42.87,-22.82) .. (44.81,-21.33)
 .. controls (46.73,-19.86) and (47.78,-18.57) .. (48.08,-16.22)
 .. controls (48.37,-13.87) and (50.87,-12.89) .. (50.12,-11.65)
 .. controls (49.36,-10.42) and (48.61,-9.72) .. (48.92,-7.74)
 .. controls (49.22,-5.75) and (47.90,-3.45) .. (49.88,-3.57)
 .. controls (51.87,-3.69) and (59.27,-11.05) .. (59.27,-11.05)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((62.75,-6.81)
 .. controls (62.75,-6.81) and (63.06,-4.63) .. (63.01,-2.65)
 .. controls (62.95,-0.66) and (63.97,1.71) .. (63.97,1.71)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((60.69,3.24)
 .. controls (60.69,3.24) and (59.38,-1.67) .. (57.20,-1.01)
 .. controls (55.02,-0.35) and (52.28,0.81) .. (51.68,2.96)
 .. controls (51.08,5.12) and (43.38,16.05) .. (43.51,18.04)
 .. controls (43.64,20.03) and (44.13,22.03) .. (44.13,22.03)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((35.28,23.23)
 .. controls (35.28,23.23) and (33.61,11.66) .. (32.16,5.67)
 .. controls (30.73,-0.27) and (33.08,-6.48) .. (29.74,-8.71)
 .. controls (26.40,-10.93) and (24.21,-10.10) .. (23.13,-15.29)
 .. controls (22.07,-20.44) and (19.88,-15.57) .. (17.70,-15.48)
 .. controls (15.51,-15.38) and (15.39,-17.35) .. (13.19,-16.72)
 .. controls (11.00,-16.09) and (10.72,-13.24) .. (10.15,-12.55)
 .. controls (9.59,-11.85) and (5.68,-7.09) .. (5.65,-6.01)
 .. controls (5.62,-4.93) and (3.13,0.40) .. (4.21,0.43)
 .. controls (5.29,0.47) and (7.32,-1.27) .. (7.27,0.53)
 .. controls (7.22,2.33) and (7.08,7.17) .. (8.15,7.74)
 .. controls (9.22,8.32) and (11.42,7.13) .. (11.19,8.74)
 .. controls (10.96,10.35) and (8.25,10.63) .. (9.64,12.66)
 .. controls (11.03,14.69) and (11.90,15.79) .. (11.90,15.79)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((10.43,17.19)
 .. controls (10.43,17.19) and (8.74,12.45) .. (7.46,13.32)
 .. controls (6.18,14.18) and (4.69,16.13) .. (4.69,16.13)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((3.64,14.84)
 .. controls (3.64,14.84) and (7.65,12.96) .. (6.96,11.86)
 .. controls (6.26,10.75) and (6.49,8.96) .. (4.69,9.09)
 .. controls (2.89,9.23) and (-3.66,5.09) .. (-2.02,4.41)
 .. controls (-0.38,3.73) and (-0.03,3.92) .. (0.57,1.77)
 .. controls (1.17,-0.37) and (1.63,-4.14) .. (3.13,-6.08)
 .. controls (4.62,-8.02) and (7.80,-12.25) .. (7.83,-13.15)
 .. controls (7.86,-14.04) and (8.78,-14.73) .. (6.09,-14.80)
 .. controls (3.39,-14.87) and (-0.93,-15.15) .. (-4.03,-13.80)
 .. controls (-7.13,-12.44) and (-11.73,-2.50) .. (-11.73,-2.50)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-13.87,-3.46)
 .. controls (-13.87,-3.46) and (-5.64,-14.21) .. (-6.52,-14.95)
 .. controls (-7.40,-15.70) and (-10.21,-18.10) .. (-10.93,-17.94)
 .. controls (-11.66,-17.78) and (-18.67,-11.86) .. (-20.18,-9.56)
 .. controls (-21.69,-7.26) and (-24.50,3.29) .. (-26.12,3.42)
 .. controls (-27.75,3.55) and (-31.99,6.86) .. (-32.49,5.58)
 .. controls (-32.99,4.31) and (-35.94,0.45) .. (-35.94,0.45)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-34.10,-1.12)
 .. controls (-34.10,-1.12) and (-32.99,4.12) .. (-31.71,3.44)
 .. controls (-30.43,2.76) and (-27.54,2.48) .. (-26.95,0.70)
 .. controls (-26.36,-1.09) and (-24.20,-7.51) .. (-23.42,-9.65)
 .. controls (-22.64,-11.79) and (-17.17,-20.27) .. (-18.61,-20.49)
 .. controls (-20.05,-20.71) and (-26.29,-16.57) .. (-27.20,-16.24)
 .. controls (-28.11,-15.90) and (-28.89,-13.76) .. (-28.89,-13.76)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-28.55,-19.51)
 .. controls (-28.55,-19.51) and (-28.97,-17.55) .. (-27.30,-18.94)
 .. controls (-25.64,-20.33) and (-23.45,-21.35) .. (-22.15,-22.75)
 .. controls (-20.85,-24.15) and (-21.19,-24.88) .. (-23.16,-24.92)
 .. controls (-25.14,-24.97) and (-27.65,-22.55) .. (-27.58,-21.64)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-27.70,-23.60)
 .. controls (-27.70,-23.60) and (-24.79,-24.60) .. (-25.50,-24.98)
 .. controls (-26.21,-25.35) and (-27.83,-25.21) .. (-27.83,-25.21)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((59.27,-11.05)
 -- (64.25,-14.85)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((66.19,-13.17)
 -- (62.75,-6.81)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((63.97,1.71)
 -- (66.50,8.27)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((63.05,9.07)
 -- (60.69,3.24)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((44.13,22.03)
 .. controls (44.13,22.03) and (43.08,27.78) .. (45.06,27.84)
 .. controls (47.04,27.89) and (54.40,28.64) .. (54.40,28.64)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((55.45,36.42)
 .. controls (55.45,36.42) and (50.96,35.93) .. (43.57,36.27)
 .. controls (36.18,36.60) and (33.03,39.76) .. (33.03,39.76)
 -- (30.45,42.04)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((27.84,38.72)
 .. controls (27.84,38.72) and (34.91,36.75) .. (34.99,33.87)
 .. controls (35.07,30.99) and (35.28,23.23) .. (35.28,23.23)
));
drawoptions();
p_narrowend((58.81,-26.18),77.5,1.00,(0,0));
drawoptions();
p_narrowend((1.57,18.21),225.8,1.00,(0,0));
drawoptions();
p_narrowend((14.66,20.55),136.9,1.00,(0,0));
drawoptions();
p_narrowend((-14.16,0.86),202.5,1.00,(0,0));
drawoptions();
p_narrowend((-36.94,-2.46),326.3,1.00,(0,0));
drawoptions();
p_narrowend((-30.15,-7.13),172.7,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((40.59,0.69)
 .. controls (40.59,0.69) and (46.69,1.03) .. (46.19,-0.43)
 .. controls (45.70,-1.88) and (45.89,-2.23) .. (44.20,-6.43)
 .. controls (42.53,-10.59) and (43.10,-18.14) .. (41.29,-17.26)
 .. controls (39.48,-16.38) and (40.34,-15.30) .. (40.07,-12.07)
 .. controls (39.80,-8.85) and (38.22,-10.13) .. (38.16,-7.98)
 .. controls (38.09,-5.83) and (40.59,0.69) .. cycle
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((39.86,13.43)
 .. controls (39.86,13.43) and (47.13,4.83) .. (46.24,4.44)
 .. controls (45.35,4.06) and (38.99,5.66) .. (38.76,7.64)
 .. controls (38.53,9.62) and (39.86,13.43) .. cycle
));
ATTR__height := -1;
drawoptions();
l_gradient(((-50.24,-22.52)
 -- (-44.31,-28.86)
));
ATTR__height := -1;
drawoptions();
l_gradient(((36.78,1.66)
 -- (34.77,-8.59)
));
ATTR__height := -1;
drawoptions();
l_gradient(((47.53,-3.09)
 -- (44.82,-15.77)
));
ATTR__height := -1;
drawoptions();
l_gradient(((-2.03,-25.37)
 -- (-7.79,-27.76)
));
ATTR__height := -1;
drawoptions();
l_gradient(((1.18,-26.08)
 -- (6.97,-26.62)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-27.58,-21.64)
 .. controls (-28.15,-20.76) and (-28.55,-19.51) .. (-28.55,-19.51)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-28.89,-13.76)
 -- (-29.15,-10.52)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-30.95,-10.57)
 .. controls (-30.95,-10.57) and (-31.93,-14.56) .. (-31.33,-16.53)
 .. controls (-30.74,-18.49) and (-29.19,-22.03) .. (-29.19,-22.03)
 -- (-29.32,-23.46)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-34.99,0.12),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-31.79,4.47),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-26.82,1.89),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-22.25,-9.34),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-10.40,-27.01),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-28.50,-17.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-15.70,-29.53),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-23.79,-29.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-30.84,-28.51),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-37.25,-30.97),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-47.37,-26.37),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-51.80,-21.53),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-12.04,-4.32),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-3.94,-18.21),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-2.03,-25.37),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((6.97,9.13),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((2.39,1.76),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((4.66,-6.74),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((8.79,-11.97),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((12.49,-25.82),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((32.24,-20.78),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((40.49,-22.39),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((40.10,-26.94),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((43.15,-33.80),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((48.93,-31.78),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((55.10,-25.99),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((47.97,-24.23),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((45.88,-18.52),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((46.36,-14.42),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((46.48,-7.48),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((50.02,-0.15),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((60.72,-8.56),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((36.98,5.63),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((40.70,15.82),1,0,"");
endfig;
beginfig(8);
drawoptions();
p_label(btex \thlabel\thhugesize \thfb\char65 \char50 \char52 \mainfont{} etex,(-72.20,-16.77),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{\hfil#\hfil\cr\thfb\char85 \char114 \char115 \char117 \char115 \ \cr\thfb \char97 \char114 \char99 \char116 \char111 \char115 \cr}}\mainfont{} etex,(-9.61,-46.50),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char85 \char114 \char115 \char117 \char115 \ \char115 \char112 \char101 \char108 \char101 \char117 \char115 \mainfont{} etex,(42.73,47.42),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char98 \char97 \char117 \char103 \char101 \mainfont{} etex,(72.81,-5.24),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char67 \char111 \char108 \char109 \char46 \mainfont{} etex,(24.35,28.18),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char67 \char111 \char108 \char109 \char46 \mainfont{} etex,(65.60,14.55),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char67 \char111 \char108 \char109 \char46 \mainfont{} etex,(68.81,-16.51),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char45 \char54 \char48 \ \char109 \mainfont{} etex,(-63.65,-33.86),0.0,0);
drawoptions(withcolor (1.000000,0.500000,0.000000));
p_label(btex \thaltitude \thfb\char49 \char55 \char57 \char53 \mainfont{} etex,(-65.32,-25.06),0.0,1);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char83 \char97 \char108 \char108 \char101 \ \char100 \char117 \ \char67 \char114 \accent94 \char97 \char110 \char101 \mainfont{} etex,(-36.14,13.95),33.5,0);
endfig;
current_scrap := "A21-3";
ATTR__scrap := "A21-3";
beginfig(9);
ATTR__height := -1;
drawoptions();
l_pit(((3.65,-20.27)
 .. controls (3.65,-20.27) and (5.99,-20.41) .. (7.48,-22.71)
 .. controls (8.98,-25.02) and (8.84,-26.64) .. (8.84,-26.64)
));
ATTR__height := -1;
drawoptions();
l_pit(((15.57,-14.25)
 .. controls (15.57,-14.25) and (14.18,-16.26) .. (11.46,-16.32)
 .. controls (8.76,-16.38) and (5.52,-16.28) .. (5.52,-16.28)
));
drawoptions();
p_blocks((5.36,-24.37),0.0,0.50,(0,0));
ATTR__height := -1;
drawoptions();
l_floormeander(((-0.59,26.99)
 .. controls (-0.59,26.99) and (3.89,20.24) .. (5.79,16.67)
 .. controls (7.70,13.11) and (11.03,9.05) .. (10.40,5.44)
 .. controls (9.76,1.83) and (5.04,-3.85) .. (5.04,-3.85)
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.37,-34.09) -- (6.39,-23.25)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((6.39,-23.25) -- (11.89,-22.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((6.39,-23.25) -- (2.37,-34.09)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((6.39,-23.25) -- (15.49,-26.05)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.49,-26.05) -- (6.39,-23.25)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.49,-26.05) -- (16.47,-24.46)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((11.89,-22.31) -- (10.69,-15.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((11.89,-22.31) -- (6.39,-23.25)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((10.69,-15.66) -- (4.53,-5.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((10.69,-15.66) -- (11.89,-22.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((4.53,-5.01) -- (7.36,1.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((4.53,-5.01) -- (10.69,-15.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((7.36,1.10) -- (11.98,5.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((7.36,1.10) -- (4.53,-5.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((11.98,5.76) -- (0.95,24.79)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((11.98,5.76) -- (7.36,1.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-14.04,18.90) -- (-11.86,22.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-11.86,22.62) -- (-14.04,18.90)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-11.86,22.62) -- (0.95,24.79)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((0.87,24.79) -- (-3.28,31.94)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((0.87,24.79) -- (0.95,24.79)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-3.28,31.94) -- (1.98,35.65)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-3.28,31.94) -- (0.87,24.79)));
endfig;
beginfig(10);
draw_upscrap(1)(1,((13.16,-18.26)
 .. controls (13.16,-18.26) and (13.86,-17.89) .. (12.89,-15.39)
 .. controls (11.92,-12.89) and (5.85,-7.62) .. (6.70,-5.26)
 .. controls (7.54,-2.90) and (13.51,2.82) .. (13.45,5.51)
 .. controls (13.39,8.20) and (4.12,26.19) .. (2.85,26.35)
 .. controls (1.59,26.50) and (1.22,27.03) .. (0.48,27.73)
 .. controls (-0.26,28.44) and (-2.66,30.91) .. (-1.78,31.65)
 .. controls (-0.90,32.39) and (0.34,33.32) .. (0.34,33.32)
),
1,((-0.26,36.19)
 .. controls (-0.26,36.19) and (-4.37,35.01) .. (-4.14,32.67)
 .. controls (-3.90,30.34) and (-0.41,27.17) .. (-1.85,27.14)
 .. controls (-3.29,27.11) and (-12.25,25.84) .. (-13.30,24.56)
 .. controls (-14.35,23.27) and (-15.78,22.70) .. (-15.72,20.18)
 .. controls (-15.66,17.66) and (-14.54,15.70) .. (-12.76,16.82)
 .. controls (-10.98,17.94) and (-12.60,17.91) .. (-12.60,17.91)
),
1,((-12.60,17.91)
 .. controls (-12.60,17.91) and (-13.90,19.32) .. (-10.49,19.94)
 .. controls (-7.08,20.55) and (-3.22,23.86) .. (-0.99,21.21)
 .. controls (1.23,18.56) and (10.49,9.21) .. (8.57,6.66)
 .. controls (6.65,4.10) and (6.29,4.27) .. (4.93,0.82)
 .. controls (3.57,-2.63) and (1.99,-4.28) .. (1.84,-5.37)
 .. controls (1.68,-6.45) and (-0.67,-11.84) .. (1.23,-10.24)
 .. controls (3.88,-8.02) and (2.73,-5.17) .. (3.49,-6.77)
 .. controls (4.25,-8.38) and (8.34,-14.05) .. (8.41,-16.57)
 .. controls (8.47,-19.09) and (8.85,-19.80) .. (6.02,-21.30)
 .. controls (3.17,-22.80) and (1.56,-31.66) .. (1.23,-33.11)
),
1,((3.78,-34.67)
 .. controls (3.78,-34.67) and (3.39,-33.06) .. (5.55,-33.01)
 .. controls (7.71,-32.97) and (9.68,-32.03) .. (8.93,-30.96)
 .. controls (8.19,-29.90) and (6.28,-25.08) .. (7.91,-25.22)
 .. controls (9.54,-25.37) and (15.36,-27.40) .. (15.36,-27.40)
),
1,((15.11,-24.52)
 .. controls (15.11,-24.52) and (11.13,-23.71) .. (12.03,-23.69)
));
draw_upscrap(0)(1,((5.51,-31.03)
 .. controls (5.51,-31.03) and (5.44,-27.97) .. (6.19,-29.04)
 .. controls (6.93,-30.10) and (8.04,-31.34) .. (6.96,-31.36)
 .. controls (5.88,-31.39) and (5.51,-31.03) .. cycle
));
draw_downscrap;
endfig;
beginfig(11);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-12.60,17.91)
 .. controls (-12.60,17.91) and (-13.90,19.32) .. (-10.49,19.94)
 .. controls (-7.08,20.55) and (-3.22,23.86) .. (-0.99,21.21)
 .. controls (1.23,18.56) and (10.49,9.21) .. (8.57,6.66)
 .. controls (6.65,4.10) and (6.29,4.27) .. (4.93,0.82)
 .. controls (3.57,-2.63) and (1.99,-4.28) .. (1.84,-5.37)
 .. controls (1.68,-6.45) and (-0.67,-11.84) .. (1.23,-10.24)
 .. controls (3.88,-8.02) and (2.73,-5.17) .. (3.49,-6.77)
 .. controls (4.25,-8.38) and (8.34,-14.05) .. (8.41,-16.57)
 .. controls (8.47,-19.09) and (8.85,-19.80) .. (6.02,-21.30)
 .. controls (3.17,-22.80) and (1.56,-31.66) .. (1.23,-33.11)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((3.78,-34.67)
 .. controls (3.78,-34.67) and (3.39,-33.06) .. (5.55,-33.01)
 .. controls (7.71,-32.97) and (9.68,-32.03) .. (8.93,-30.96)
 .. controls (8.19,-29.90) and (6.28,-25.08) .. (7.91,-25.22)
 .. controls (9.54,-25.37) and (15.36,-27.40) .. (15.36,-27.40)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((5.51,-31.03)
 .. controls (5.51,-31.03) and (5.44,-27.97) .. (6.19,-29.04)
 .. controls (6.93,-30.10) and (8.04,-31.34) .. (6.96,-31.36)
 .. controls (5.88,-31.39) and (5.51,-31.03) .. cycle
));
drawoptions();
p_narrowend((-0.14,-36.20),319.8,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((15.11,-24.52)
 .. controls (15.11,-24.52) and (11.13,-23.71) .. (12.03,-23.69)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((13.16,-18.26)
 .. controls (13.16,-18.26) and (13.86,-17.89) .. (12.89,-15.39)
 .. controls (11.92,-12.89) and (5.85,-7.62) .. (6.70,-5.26)
 .. controls (7.54,-2.90) and (13.51,2.82) .. (13.45,5.51)
 .. controls (13.39,8.20) and (4.12,26.19) .. (2.85,26.35)
 .. controls (1.59,26.50) and (1.22,27.03) .. (0.48,27.73)
 .. controls (-0.26,28.44) and (-2.66,30.91) .. (-1.78,31.65)
 .. controls (-0.90,32.39) and (0.34,33.32) .. (0.34,33.32)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-0.26,36.19)
 .. controls (-0.26,36.19) and (-4.37,35.01) .. (-4.14,32.67)
 .. controls (-3.90,30.34) and (-0.41,27.17) .. (-1.85,27.14)
 .. controls (-3.29,27.11) and (-12.25,25.84) .. (-13.30,24.56)
 .. controls (-14.35,23.27) and (-15.78,22.70) .. (-15.72,20.18)
 .. controls (-15.66,17.66) and (-14.54,15.70) .. (-12.76,16.82)
 .. controls (-10.98,17.94) and (-12.60,17.91) .. (-12.60,17.91)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-3.28,31.94),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((0.87,24.79),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-11.86,22.62),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-14.04,18.90),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((11.98,5.76),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((7.36,1.10),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((4.53,-5.01),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((10.69,-15.66),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((11.89,-22.31),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((15.49,-26.05),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((6.39,-23.25),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((2.37,-34.09),1,0,"");
endfig;
current_scrap := "A21-6";
ATTR__scrap := "A21-6";
beginfig(12);
ATTR__height := -1;
drawoptions();
l_pit(((-0.02,-10.63)
 .. controls (-0.02,-10.63) and (0.44,-7.02) .. (-1.23,-4.55)
 .. controls (-2.91,-2.07) and (-7.05,-1.44) .. (-7.05,-1.44)
));
ATTR__height := -1;
drawoptions();
l_pit(((-50.34,-25.22)
 .. controls (-50.34,-25.22) and (-45.86,-24.58) .. (-46.44,-22.80)
 .. controls (-47.02,-21.01) and (-47.29,-16.88) .. (-49.09,-16.92)
 .. controls (-50.89,-16.96) and (-52.00,-15.37) .. (-53.05,-16.83)
 .. controls (-54.09,-18.30) and (-54.63,-18.31) .. (-54.94,-20.65)
 .. controls (-55.25,-23.00) and (-54.88,-23.35) .. (-54.88,-23.35)
));
ATTR__height := -1;
drawoptions();
l_floormeander(((-32.82,-12.97)
 .. controls (-32.82,-12.97) and (-32.06,-15.29) .. (-32.56,-16.92)
 .. controls (-33.07,-18.55) and (-33.22,-19.81) .. (-33.22,-19.81)
));
drawoptions();
p_blocks((-36.75,-14.13),0.0,0.50,(0,0));
drawoptions();
p_blocks((-27.00,-16.80),0.0,0.50,(0,0));
drawoptions();
p_blocks((-46.04,-16.68),0.0,0.50,(0,0));
ATTR__height := -1;
drawoptions();
l_pit(((33.91,6.12)
 .. controls (33.91,6.12) and (38.38,7.29) .. (38.71,8.92)
 .. controls (39.03,10.55) and (39.20,11.09) .. (39.15,13.25)
 .. controls (39.10,15.41) and (38.53,17.20) .. (38.53,17.20)
));
ATTR__height := -1;
drawoptions();
l_pit(((3.45,9.24)
 .. controls (3.50,7.79) and (4.55,2.24) .. (7.32,-0.93)
 .. controls (10.08,-4.10) and (13.70,-5.46) .. (13.70,-5.46)
));
drawoptions();
p_blocks((49.35,2.90),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_contour(((22.29,19.90)
 .. controls (22.29,19.90) and (19.90,14.28) .. (19.06,11.56)
 .. controls (18.22,8.84) and (24.76,5.39) .. (24.76,5.39)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((29.30,19.88)
 .. controls (29.30,19.88) and (25.59,16.92) .. (26.39,13.16)
 .. controls (27.19,9.40) and (28.88,6.38) .. (28.88,6.38)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((13.83,20.26)
 .. controls (13.83,20.26) and (8.41,12.95) .. (10.66,9.22)
 .. controls (12.90,5.49) and (19.26,2.40) .. (19.26,2.40)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((3.93,12.13)
 .. controls (3.93,12.13) and (5.33,6.75) .. (8.10,3.76)
 .. controls (10.87,0.77) and (16.30,-1.26) .. (16.30,-1.26)
),-1);
drawoptions();
p_blocks((59.47,6.50),0.0,0.50,(0,0));
ATTR__height := -1;
drawoptions();
l_pit(((50.63,7.38)
 .. controls (50.63,7.38) and (50.30,6.12) .. (50.36,3.60)
 .. controls (50.41,1.08) and (52.08,-1.41) .. (52.08,-1.41)
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-53.53,-21.75) -- (-40.04,-14.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-53.53,-21.75) -- (-53.49,-21.74)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-40.04,-14.31) -- (-26.88,-15.33)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-40.04,-14.31) -- (-53.53,-21.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-26.88,-15.33) -- (-2.05,-5.86)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-26.88,-15.33) -- (-40.04,-14.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2.05,-5.86) -- (-26.88,-15.33)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2.05,-5.86) -- (5.66,0.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-9.78,22.82) -- (-25.29,9.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-9.78,22.82) -- (-1.24,19.65)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1.24,19.65) -- (-9.78,22.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1.24,19.65) -- (5.08,14.28)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((5.08,14.28) -- (-1.24,19.65)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((5.08,14.28) -- (14.02,9.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((5.66,0.61) -- (-2.05,-5.86)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((5.66,0.61) -- (14.02,9.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((14.02,9.04) -- (5.08,14.28)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((14.02,9.04) -- (5.66,0.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((14.02,9.04) -- (34.67,12.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((57.74,5.09) -- (49.35,2.90)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((49.35,2.90) -- (57.74,5.09)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((49.35,2.90) -- (45.35,6.30)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((45.35,6.30) -- (49.35,2.90)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((45.35,6.30) -- (34.67,12.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((34.67,12.56) -- (45.35,6.30)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((34.67,12.56) -- (14.02,9.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((34.67,12.56) -- (45.73,8.40)));
endfig;
beginfig(13);
draw_upscrap(1)(1,((-1.74,1.73)
 .. controls (-1.74,1.73) and (-1.65,-1.86) .. (-4.32,-3.00)
 .. controls (-6.99,-4.14) and (-24.95,-11.91) .. (-27.10,-12.13)
 .. controls (-29.25,-12.36) and (-37.32,-12.71) .. (-40.19,-12.77)
 .. controls (-43.07,-12.83) and (-47.18,-14.00) .. (-51.28,-15.35)
 .. controls (-55.38,-16.71) and (-54.94,-20.47) .. (-56.40,-19.43)
 .. controls (-57.86,-18.38) and (-62.00,-18.11) .. (-62.00,-18.11)
),
1,((-62.47,-21.18)
 .. controls (-62.47,-21.18) and (-54.37,-22.08) .. (-54.88,-23.35)
 .. controls (-55.39,-24.62) and (-56.79,-25.91) .. (-56.79,-25.91)
),
1,((-55.33,-27.13)
 .. controls (-55.33,-27.13) and (-52.63,-27.07) .. (-51.95,-25.62)
 .. controls (-51.26,-24.17) and (-50.39,-23.07) .. (-50.01,-23.78)
 .. controls (-49.64,-24.49) and (-48.72,-25.19) .. (-47.27,-25.87)
 .. controls (-45.82,-26.56) and (-38.79,-27.47) .. (-37.37,-26.72)
 .. controls (-35.95,-25.97) and (-32.13,-20.32) .. (-32.13,-20.32)
),
1,((-27.19,-24.35)
 .. controls (-27.19,-24.35) and (-28.68,-21.87) .. (-24.58,-20.34)
 .. controls (-20.49,-18.81) and (-3.12,-8.36) .. (-0.77,-8.85)
 .. controls (1.57,-9.33) and (3.55,-9.47) .. (4.62,-9.08)
 .. controls (5.69,-8.70) and (6.20,-7.43) .. (6.20,-7.43)
),
1,((6.20,-7.43)
 .. controls (6.20,-7.43) and (9.63,-7.71) .. (11.55,-5.51)
 .. controls (13.47,-3.31) and (12.56,4.95) .. (16.67,5.76)
 .. controls (20.78,6.56) and (31.11,11.10) .. (33.84,9.54)
 .. controls (36.57,7.98) and (41.16,3.93) .. (43.52,3.26)
),
1,((43.52,3.26)
 .. controls (43.52,3.26) and (49.99,3.77) .. (47.32,2.27)
 .. controls (44.65,0.77) and (36.31,-4.63) .. (36.31,-4.63)
),
1,((37.97,-6.39)
 .. controls (37.97,-6.39) and (48.43,1.21) .. (50.42,0.90)
 .. controls (52.40,0.58) and (54.34,2.42) .. (54.38,0.62)
 .. controls (54.42,-1.18) and (52.31,-3.38) .. (52.31,-3.38)
),
1,((54.30,-3.88)
 .. controls (54.30,-3.88) and (54.76,-0.45) .. (56.38,-0.41)
 .. controls (58.00,-0.38) and (60.34,-0.51) .. (60.32,0.57)
 .. controls (60.29,1.65) and (62.84,8.01) .. (62.84,8.01)
),
1,((61.01,9.41)
 .. controls (61.01,9.41) and (57.98,8.63) .. (57.78,9.34)
 .. controls (57.58,10.06) and (56.12,11.11) .. (55.06,10.18)
 .. controls (54.01,9.26) and (51.40,5.42) .. (49.76,6.11)
 .. controls (48.12,6.79) and (38.71,8.92) .. (38.71,8.92)
),
1,((39.15,13.25)
 .. controls (39.15,13.25) and (40.74,14.91) .. (35.69,15.52)
 .. controls (30.64,16.13) and (17.49,17.46) .. (13.55,16.66)
 .. controls (9.61,15.85) and (6.97,12.74) .. (5.48,15.22)
 .. controls (3.99,17.71) and (3.73,21.49) .. (0.48,22.14)
 .. controls (-2.78,22.79) and (-7.24,29.00) .. (-11.49,25.66)
 .. controls (-15.74,22.33) and (-17.33,21.21) .. (-17.33,21.21)
),
1,((-11.80,15.39)
 .. controls (-11.80,15.39) and (-11.91,20.07) .. (-9.37,19.41)
 .. controls (-6.83,18.74) and (-2.50,18.48) .. (-1.95,17.77)
 .. controls (-1.39,17.06) and (-1.65,12.19) .. (-0.79,14.19)
 .. controls (0.06,16.19) and (-0.31,16.72) .. (1.16,15.49)
 .. controls (2.62,14.26) and (5.70,13.61) .. (5.37,12.16)
 .. controls (5.04,10.71) and (2.84,5.79) .. (1.61,4.69)
 .. controls (0.38,3.58) and (-1.74,1.73) .. (-1.74,1.73)
));
draw_upscrap(0)(1,((-32.13,-20.32)
 .. controls (-29.61,-20.63) and (-26.20,-19.43) .. (-27.09,-20.57)
 .. controls (-28.67,-22.58) and (-29.17,-24.03) .. (-29.17,-24.03)
));
draw_upscrap(0)(1,((-34.30,-19.47)
 .. controls (-34.30,-19.47) and (-37.24,-24.56) .. (-38.67,-24.60)
 .. controls (-40.11,-24.63) and (-47.86,-23.55) .. (-47.70,-22.65)
 .. controls (-47.54,-21.74) and (-42.60,-17.86) .. (-40.62,-17.99)
 .. controls (-38.64,-18.12) and (-34.30,-19.47) .. cycle
));
draw_upscrap(0)(1,((-7.13,24.14)
 .. controls (-7.13,24.14) and (-3.69,23.31) .. (-4.57,22.39)
 .. controls (-5.45,21.47) and (-6.52,20.73) .. (-7.08,21.62)
 .. controls (-7.64,22.51) and (-7.13,24.14) .. cycle
));
draw_downscrap;
endfig;
beginfig(14);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-7.13,24.14)
 .. controls (-7.13,24.14) and (-3.69,23.31) .. (-4.57,22.39)
 .. controls (-5.45,21.47) and (-6.52,20.73) .. (-7.08,21.62)
 .. controls (-7.64,22.51) and (-7.13,24.14) .. cycle
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-11.80,15.39)
 .. controls (-11.80,15.39) and (-11.91,20.07) .. (-9.37,19.41)
 .. controls (-6.83,18.74) and (-2.50,18.48) .. (-1.95,17.77)
 .. controls (-1.39,17.06) and (-1.65,12.19) .. (-0.79,14.19)
 .. controls (0.06,16.19) and (-0.31,16.72) .. (1.16,15.49)
 .. controls (2.62,14.26) and (5.70,13.61) .. (5.37,12.16)
 .. controls (5.04,10.71) and (2.84,5.79) .. (1.61,4.69)
 .. controls (0.38,3.58) and (-1.74,1.73) .. (-1.74,1.73)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1.74,1.73)
 .. controls (-1.74,1.73) and (-1.65,-1.86) .. (-4.32,-3.00)
 .. controls (-6.99,-4.14) and (-24.95,-11.91) .. (-27.10,-12.13)
 .. controls (-29.25,-12.36) and (-37.32,-12.71) .. (-40.19,-12.77)
 .. controls (-43.07,-12.83) and (-47.18,-14.00) .. (-51.28,-15.35)
 .. controls (-55.38,-16.71) and (-54.94,-20.47) .. (-56.40,-19.43)
 .. controls (-57.86,-18.38) and (-62.00,-18.11) .. (-62.00,-18.11)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-62.47,-21.18)
 .. controls (-62.47,-21.18) and (-54.37,-22.08) .. (-54.88,-23.35)
 .. controls (-55.39,-24.62) and (-56.79,-25.91) .. (-56.79,-25.91)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-55.33,-27.13)
 .. controls (-55.33,-27.13) and (-52.63,-27.07) .. (-51.95,-25.62)
 .. controls (-51.26,-24.17) and (-50.39,-23.07) .. (-50.01,-23.78)
 .. controls (-49.64,-24.49) and (-48.72,-25.19) .. (-47.27,-25.87)
 .. controls (-45.82,-26.56) and (-38.79,-27.47) .. (-37.37,-26.72)
 .. controls (-35.95,-25.97) and (-32.13,-20.32) .. (-32.13,-20.32)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-34.30,-19.47)
 .. controls (-34.30,-19.47) and (-37.24,-24.56) .. (-38.67,-24.60)
 .. controls (-40.11,-24.63) and (-47.86,-23.55) .. (-47.70,-22.65)
 .. controls (-47.54,-21.74) and (-42.60,-17.86) .. (-40.62,-17.99)
 .. controls (-38.64,-18.12) and (-34.30,-19.47) .. cycle
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-32.13,-20.32)
 .. controls (-29.61,-20.63) and (-26.20,-19.43) .. (-27.09,-20.57)
 .. controls (-28.67,-22.58) and (-29.17,-24.03) .. (-29.17,-24.03)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-27.19,-24.35)
 .. controls (-27.19,-24.35) and (-28.68,-21.87) .. (-24.58,-20.34)
 .. controls (-20.49,-18.81) and (-3.12,-8.36) .. (-0.77,-8.85)
 .. controls (1.57,-9.33) and (3.55,-9.47) .. (4.62,-9.08)
 .. controls (5.69,-8.70) and (6.20,-7.43) .. (6.20,-7.43)
));
drawoptions();
p_rope((-52.81,-11.07),0.0,1.00,(0,0));
drawoptions();
p_rope((-9.41,-0.60),0.0,1.00,(0,0));
drawoptions();
p_rope((15.04,-9.02),0.0,1.00,(0,0));
drawoptions();
p_narrowend((-58.34,-29.00),318.0,1.00,(0,0));
drawoptions();
p_narrowend((-29.62,-27.99),339.8,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_gradient(((7.26,1.40)
 -- (12.98,9.99)
));
ATTR__height := -1;
drawoptions();
l_gradient(((16.71,12.05)
 -- (32.87,12.76)
));
string ATTR_code;
ATTR_code := "D";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \thfc\char233 \thfb\char116 \char114 \char111 \char105 \char116 \mainfont{}etex;
drawoptions();
p_continuation((32.95,-7.39),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((6.20,-7.43)
 .. controls (6.20,-7.43) and (9.63,-7.71) .. (11.55,-5.51)
 .. controls (13.47,-3.31) and (12.56,4.95) .. (16.67,5.76)
 .. controls (20.78,6.56) and (31.11,11.10) .. (33.84,9.54)
 .. controls (36.57,7.98) and (41.16,3.93) .. (43.52,3.26)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((43.52,3.26)
 .. controls (43.52,3.26) and (49.99,3.77) .. (47.32,2.27)
 .. controls (44.65,0.77) and (36.31,-4.63) .. (36.31,-4.63)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((37.97,-6.39)
 .. controls (37.97,-6.39) and (48.43,1.21) .. (50.42,0.90)
 .. controls (52.40,0.58) and (54.34,2.42) .. (54.38,0.62)
 .. controls (54.42,-1.18) and (52.31,-3.38) .. (52.31,-3.38)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((54.30,-3.88)
 .. controls (54.30,-3.88) and (54.76,-0.45) .. (56.38,-0.41)
 .. controls (58.00,-0.38) and (60.34,-0.51) .. (60.32,0.57)
 .. controls (60.29,1.65) and (62.84,8.01) .. (62.84,8.01)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((61.01,9.41)
 .. controls (61.01,9.41) and (57.98,8.63) .. (57.78,9.34)
 .. controls (57.58,10.06) and (56.12,11.11) .. (55.06,10.18)
 .. controls (54.01,9.26) and (51.40,5.42) .. (49.76,6.11)
 .. controls (48.12,6.79) and (38.71,8.92) .. (38.71,8.92)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((39.15,13.25)
 .. controls (39.15,13.25) and (40.74,14.91) .. (35.69,15.52)
 .. controls (30.64,16.13) and (17.49,17.46) .. (13.55,16.66)
 .. controls (9.61,15.85) and (6.97,12.74) .. (5.48,15.22)
 .. controls (3.99,17.71) and (3.73,21.49) .. (0.48,22.14)
 .. controls (-2.78,22.79) and (-7.24,29.00) .. (-11.49,25.66)
 .. controls (-15.74,22.33) and (-17.33,21.21) .. (-17.33,21.21)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((34.67,12.56),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((45.35,6.30),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((49.35,2.90),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((57.74,5.09),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((14.02,9.04),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((5.66,0.61),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((5.08,14.28),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-1.24,19.65),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-9.78,22.82),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-2.05,-5.86),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-26.88,-15.33),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-40.04,-14.31),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-53.53,-21.75),1,0,"");
endfig;
beginfig(15);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char49 \char48 \mainfont{} etex,(0.09,-15.12),0.0,7);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char52 \mainfont{} etex,(-51.83,-30.65),0.0,7);
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char55 \mainfont{} etex,(19.75,-2.99),0.0,7);
endfig;
current_scrap := "A21-7";
ATTR__scrap := "A21-7";
beginfig(16);
ATTR__height := -1;
drawoptions();
l_floormeander(((-8.26,-19.79)
 .. controls (-8.26,-19.79) and (19.85,-12.88) .. (25.02,-10.61)
 .. controls (30.19,-8.34) and (31.88,-11.36) .. (34.59,-12.02)
 .. controls (37.31,-12.68) and (39.47,-12.46) .. (39.47,-12.46)
));
ATTR__height := -1;
drawoptions();
l_pit(((40.85,-9.91)
 .. controls (40.85,-9.91) and (35.09,-10.03) .. (33.05,-7.01)
 .. controls (31.00,-4.00) and (29.51,-1.69) .. (29.51,-1.69)
));
drawoptions();
p_pebbles((-40.53,-10.04),0.0,1.00,(0,0));
drawoptions();
p_pebbles((-37.73,-14.67),0.0,1.00,(0,0));
drawoptions();
p_pebbles((-39.88,-6.97),0.0,1.00,(0,0));
drawoptions();
p_pebbles((-34.31,-14.59),0.0,1.00,(0,0));
drawoptions();
p_pebbles((-8.57,-22.50),0.0,1.00,(0,0));
drawoptions();
p_pebbles((-7.97,-16.55),0.0,1.00,(0,0));
drawoptions();
p_pebbles((-14.09,-16.86),0.0,1.00,(0,0));
drawoptions();
p_pebbles((-13.43,-22.25),0.0,1.00,(0,0));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-30.60,-16.89) -- (-11.42,-20.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-11.42,-20.39) -- (-30.60,-16.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-11.42,-20.39) -- (19.68,-12.27)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((19.68,-12.27) -- (-11.42,-20.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((19.68,-12.27) -- (29.38,-8.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((29.38,-8.80) -- (19.68,-12.27)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((29.38,-8.80) -- (44.89,4.04)));
endfig;
beginfig(17);
draw_upscrap(1)(1,((-45.49,-5.65)
 .. controls (-45.49,-5.65) and (-42.79,-14.05) .. (-40.23,-15.62)
 .. controls (-37.68,-17.19) and (-32.59,-19.06) .. (-30.96,-19.56)
 .. controls (-29.33,-20.07) and (-27.38,-18.40) .. (-25.55,-19.81)
 .. controls (-23.72,-21.21) and (-17.16,-24.67) .. (-11.94,-24.56)
 .. controls (-6.72,-24.44) and (17.04,-16.36) .. (21.00,-16.28)
 .. controls (24.96,-16.19) and (28.01,-15.58) .. (31.79,-15.50)
 .. controls (35.57,-15.42) and (48.01,-16.23) .. (46.17,-14.29)
 .. controls (44.32,-12.35) and (35.69,-12.90) .. (37.44,-10.52)
 .. controls (39.19,-8.14) and (42.87,-3.38) .. (42.87,-3.38)
),
1,((37.34,2.44)
 .. controls (37.34,2.44) and (30.48,-4.91) .. (27.78,-4.79)
 .. controls (25.07,-4.66) and (22.69,-2.91) .. (16.98,-5.38)
 .. controls (11.28,-7.84) and (-6.97,-13.28) .. (-10.93,-13.19)
 .. controls (-14.89,-13.09) and (-28.53,-15.55) .. (-30.00,-14.14)
 .. controls (-31.47,-12.73) and (-35.26,-12.09) .. (-36.41,-9.05)
 .. controls (-37.56,-6.02) and (-39.62,-2.28) .. (-39.62,-2.28)
));
draw_downscrap;
endfig;
beginfig(18);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((37.34,2.44)
 .. controls (37.34,2.44) and (30.48,-4.91) .. (27.78,-4.79)
 .. controls (25.07,-4.66) and (22.69,-2.91) .. (16.98,-5.38)
 .. controls (11.28,-7.84) and (-6.97,-13.28) .. (-10.93,-13.19)
 .. controls (-14.89,-13.09) and (-28.53,-15.55) .. (-30.00,-14.14)
 .. controls (-31.47,-12.73) and (-35.26,-12.09) .. (-36.41,-9.05)
 .. controls (-37.56,-6.02) and (-39.62,-2.28) .. (-39.62,-2.28)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-45.49,-5.65)
 .. controls (-45.49,-5.65) and (-42.79,-14.05) .. (-40.23,-15.62)
 .. controls (-37.68,-17.19) and (-32.59,-19.06) .. (-30.96,-19.56)
 .. controls (-29.33,-20.07) and (-27.38,-18.40) .. (-25.55,-19.81)
 .. controls (-23.72,-21.21) and (-17.16,-24.67) .. (-11.94,-24.56)
 .. controls (-6.72,-24.44) and (17.04,-16.36) .. (21.00,-16.28)
 .. controls (24.96,-16.19) and (28.01,-15.58) .. (31.79,-15.50)
 .. controls (35.57,-15.42) and (48.01,-16.23) .. (46.17,-14.29)
 .. controls (44.32,-12.35) and (35.69,-12.90) .. (37.44,-10.52)
 .. controls (39.19,-8.14) and (42.87,-3.38) .. (42.87,-3.38)
));
drawoptions();
p_archeomaterial((39.29,-4.54),0.0,0.50,(0,0));
drawoptions();
p_airdraught_summer((-47.71,5.47),23.1,1.00,(0,0));
string ATTR_code;
ATTR_code := "D";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char84 \char114 \thfc\char233 \thfb\char109 \char105 \char101 \ \char97 \char118 \char101 \char99 \ \char100 \char117 \ \char99 \char111 \char117 \char114 \char97 \char110 \char116 \ \char100 \char39 \char97 \char105 \char114 \ \char59 \ \char65 \char84 \char84 \char69 \char78 \char84 \char73 \char79 \char78 \char44 \ \char100 \char97 \char110 \char103 \char101 \char117 \char114 \char101 \char117 \char120 \mainfont{}etex;
drawoptions();
p_continuation((-39.04,4.57),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
drawoptions();
p_dig((-34.37,-3.25),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_gradient(((24.41,-7.20)
 -- (4.55,-13.03)
));
drawoptions();
p_breakdownchoke((-43.23,-1.82),204.5,1.00,(0,0));
drawoptions();
p_breakdownchoke((-42.44,-4.86),196.3,1.00,(0,0));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((29.38,-8.80),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((19.68,-12.27),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-11.42,-20.39),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-30.60,-16.89),1,0,"");
endfig;
beginfig(19);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char103 \char46 \ \char100 \char101 \char115 \ \char79 \char117 \char114 \char115 \char111 \char110 \char115 \mainfont{} etex,(-3.46,-0.42),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{\hfil#\hfil\cr\thfb\char116 \char114 \thfc\char233 \thfb\char109 \char105 \char101 \cr\thfb \ \char100 \char101 \char115 \ \char70 \char114 \char97 \char121 \char101 \char117 \char114 \char115 \cr}}\mainfont{} etex,(-45.93,22.97),0.0,0);
endfig;
current_scrap := "A21-2";
ATTR__scrap := "A21-2";
beginfig(20);
ATTR__height := -1;
drawoptions();
l_pit(((11.44,22.77)
 .. controls (11.44,22.77) and (9.94,25.79) .. (9.90,27.23)
 .. controls (9.87,28.67) and (10.21,29.04) .. (9.81,30.83)
 .. controls (9.41,32.62) and (6.99,36.17) .. (6.99,36.17)
 -- (7.47,38.71)
));
ATTR__height := -1;
drawoptions();
l_pit(((1.10,34.06)
 .. controls (1.10,34.06) and (3.47,32.67) .. (3.51,31.23)
 .. controls (3.54,29.79) and (2.52,27.60) .. (2.52,27.60)
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-64.76,-56.71) -- (-62.45,-58.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-64.76,-56.71) -- (-70.03,-60.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-62.45,-58.75) -- (-57.13,-58.32)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-62.45,-58.75) -- (-64.76,-56.71)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-57.13,-58.32) -- (-53.75,-55.92)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-57.13,-58.32) -- (-62.45,-58.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-53.75,-55.92) -- (-46.46,-55.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-53.75,-55.92) -- (-57.13,-58.32)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-46.46,-55.97) -- (-47.06,-52.70)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-46.46,-55.97) -- (-53.75,-55.92)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-47.06,-52.70) -- (-46.31,-49.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-47.06,-52.70) -- (-46.46,-55.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-46.31,-49.84) -- (-54.80,-39.73)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-46.31,-49.84) -- (-47.06,-52.70)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-54.80,-39.73) -- (-57.25,-33.05)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-54.80,-39.73) -- (-46.31,-49.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-57.25,-33.05) -- (-58.27,-27.33)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-57.25,-33.05) -- (-54.80,-39.73)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-58.27,-27.33) -- (-62.80,-23.57)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-58.27,-27.33) -- (-57.25,-33.05)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-62.80,-23.57) -- (-67.18,-16.02)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-62.80,-23.57) -- (-58.27,-27.33)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-67.18,-16.02) -- (-64.01,-14.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-67.18,-16.02) -- (-62.80,-23.57)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-64.01,-14.51) -- (-59.94,-8.67)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-64.01,-14.51) -- (-67.18,-16.02)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-59.94,-8.67) -- (-61.08,-6.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-59.94,-8.67) -- (-64.01,-14.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-61.08,-6.29) -- (-58.09,-1.06)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-61.08,-6.29) -- (-59.94,-8.67)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-58.09,-1.06) -- (-66.08,2.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-58.09,-1.06) -- (-61.08,-6.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-66.08,2.66) -- (-67.07,5.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-66.08,2.66) -- (-58.09,-1.06)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-67.07,5.82) -- (-60.46,7.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-67.07,5.82) -- (-66.08,2.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-60.46,7.96) -- (-51.84,9.44)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-60.46,7.96) -- (-67.07,5.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-51.84,9.44) -- (-51.49,12.07)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-51.84,9.44) -- (-60.46,7.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-51.49,12.07) -- (-47.55,12.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-51.49,12.07) -- (-51.84,9.44)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-42.01,11.97) -- (-40.47,12.98)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-42.01,11.97) -- (-47.55,12.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-47.55,12.61) -- (-42.01,11.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-47.55,12.61) -- (-51.49,12.07)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-40.47,12.98) -- (-34.84,14.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-40.47,12.98) -- (-42.01,11.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-34.84,14.81) -- (-30.32,17.44)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-34.84,14.81) -- (-40.47,12.98)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-30.32,17.44) -- (-24.28,17.18)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-30.32,17.44) -- (-34.84,14.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-24.28,17.18) -- (-17.59,13.19)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-24.28,17.18) -- (-30.32,17.44)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-17.59,13.19) -- (-9.19,14.33)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-17.59,13.19) -- (-24.28,17.18)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-9.19,14.33) -- (-7.14,11.48)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-9.19,14.33) -- (-17.59,13.19)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-7.14,11.48) -- (6.54,10.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-7.14,11.48) -- (-9.19,14.33)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((6.54,10.42) -- (10.81,11.55)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((6.54,10.42) -- (-7.14,11.48)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((10.81,11.55) -- (3.33,21.45)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((10.81,11.55) -- (6.54,10.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((3.33,21.45) -- (7.77,24.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((3.33,21.45) -- (10.81,11.55)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((7.77,24.03) -- (3.82,39.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((7.77,24.03) -- (3.33,21.45)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((3.82,39.76) -- (8.02,44.30)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((3.82,39.76) -- (7.77,24.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((8.02,44.30) -- (14.62,36.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((8.02,44.30) -- (3.82,39.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((14.62,36.76) -- (16.60,28.34)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((14.62,36.76) -- (8.02,44.30)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((16.60,28.34) -- (24.91,25.20)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((16.60,28.34) -- (14.62,36.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((24.91,25.20) -- (32.39,25.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((24.91,25.20) -- (16.60,28.34)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((32.39,25.81) -- (31.20,29.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((32.39,25.81) -- (24.91,25.20)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((31.20,29.03) -- (32.11,30.57)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((31.20,29.03) -- (32.39,25.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((32.11,30.57) -- (29.20,33.43)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((32.11,30.57) -- (31.20,29.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((29.20,33.43) -- (33.91,35.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((29.20,33.43) -- (32.11,30.57)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((33.91,35.84) -- (36.50,37.26)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((33.91,35.84) -- (29.20,33.43)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((36.50,37.26) -- (33.91,35.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((36.50,37.26) -- (40.09,36.26)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((40.09,36.26) -- (36.50,37.26)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((40.09,36.26) -- (43.37,36.43)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((43.37,36.43) -- (40.09,36.26)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((43.37,36.43) -- (48.37,38.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((48.37,38.10) -- (43.37,36.43)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((48.37,38.10) -- (50.89,40.43)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((50.89,40.43) -- (48.37,38.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((50.89,40.43) -- (54.97,41.87)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((54.97,41.87) -- (50.89,40.43)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((54.97,41.87) -- (59.77,43.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((59.77,43.01) -- (54.97,41.87)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((59.77,43.01) -- (62.17,44.13)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((62.17,44.13) -- (59.77,43.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((62.17,44.13) -- (63.96,43.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((63.96,43.15) -- (62.17,44.13)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((63.96,43.15) -- (66.91,44.21)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((66.91,44.21) -- (63.96,43.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((66.91,44.21) -- (68.30,45.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((68.30,45.66) -- (66.91,44.21)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((68.30,45.66) -- (66.67,48.38)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((66.67,48.38) -- (68.30,45.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((66.67,48.38) -- (64.34,53.25)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((64.34,53.25) -- (66.67,48.38)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((64.34,53.25) -- (62.20,57.50)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((62.20,57.50) -- (64.34,53.25)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((62.20,57.50) -- (68.57,55.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((68.57,55.51) -- (62.20,57.50)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((68.57,55.51) -- (72.69,57.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((72.69,57.76) -- (68.57,55.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((72.69,57.76) -- (78.22,56.46)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((78.22,56.46) -- (72.69,57.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((78.22,56.46) -- (84.95,50.72)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((83.11,50.62) -- (84.95,50.72)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((83.11,50.62) -- (82.18,55.18)));
endfig;
beginfig(21);
draw_upscrap(1)(1,((-66.41,-59.04)
 .. controls (-66.41,-59.04) and (-66.09,-57.23) .. (-65.00,-58.29)
 .. controls (-63.90,-59.35) and (-63.88,-60.25) .. (-61.20,-60.02)
 .. controls (-58.52,-59.78) and (-56.37,-59.91) .. (-54.97,-58.44)
 .. controls (-53.57,-56.97) and (-54.46,-56.99) .. (-50.88,-56.91)
 .. controls (-47.30,-56.84) and (-44.03,-58.38) .. (-44.78,-56.78)
 .. controls (-45.54,-55.18) and (-45.90,-54.83) .. (-45.94,-53.39)
 .. controls (-45.97,-51.95) and (-44.92,-50.66) .. (-45.50,-49.23)
 .. controls (-46.07,-47.80) and (-49.97,-43.03) .. (-53.11,-39.67)
 .. controls (-56.25,-36.32) and (-56.87,-32.74) .. (-56.92,-30.58)
 .. controls (-56.97,-28.42) and (-57.74,-26.27) .. (-59.58,-25.05)
 .. controls (-61.42,-23.83) and (-65.85,-18.89) .. (-65.53,-17.44)
 .. controls (-65.21,-15.99) and (-63.09,-15.04) .. (-62.05,-13.58)
 .. controls (-61.00,-12.12) and (-57.84,-8.81) .. (-58.77,-7.57)
 .. controls (-59.70,-6.32) and (-59.52,-6.50) .. (-58.48,-4.68)
 .. controls (-57.45,-2.85) and (-54.80,-0.45) .. (-57.52,0.21)
 .. controls (-60.24,0.86) and (-64.96,2.38) .. (-65.18,3.82)
 .. controls (-65.41,5.25) and (-65.41,5.25) .. (-63.09,5.84)
 .. controls (-60.78,6.43) and (-59.72,7.36) .. (-56.31,7.61)
 .. controls (-52.91,7.87) and (-50.22,8.29) .. (-50.25,9.55)
 .. controls (-50.28,10.81) and (-50.30,11.53) .. (-47.98,11.58)
 .. controls (-45.65,11.63) and (-45.10,10.73) .. (-42.41,10.80)
 .. controls (-39.73,10.86) and (-39.95,12.47) .. (-37.98,12.69)
 .. controls (-36.01,12.92) and (-32.14,16.06) .. (-30.17,16.10)
 .. controls (-28.20,16.15) and (-27.87,17.23) .. (-24.79,15.50)
 .. controls (-21.70,13.76) and (-21.48,11.97) .. (-18.25,12.03)
 .. controls (-15.02,12.10) and (-11.13,14.89) .. (-9.67,13.30)
 .. controls (-8.20,11.71) and (-5.47,9.79) .. (-2.24,9.86)
 .. controls (1.00,9.93) and (6.23,8.97) .. (7.83,9.54)
 .. controls (9.43,10.12) and (13.35,11.46) .. (11.34,13.04)
 .. controls (9.32,14.61) and (3.06,20.60) .. (5.04,20.64)
 .. controls (7.01,20.69) and (9.50,21.46) .. (9.83,22.73)
 .. controls (10.16,24.00) and (8.83,27.02) .. (10.30,25.44)
 .. controls (11.77,23.85) and (13.04,22.62) .. (13.04,22.62)
),
1,((13.04,22.62)
 .. controls (13.04,22.62) and (15.72,21.96) .. (15.78,20.17)
 .. controls (15.85,18.36) and (14.51,15.63) .. (14.51,15.63)
),
1,((16.33,14.41)
 .. controls (16.33,14.41) and (17.60,18.95) .. (17.65,17.51)
 .. controls (17.71,16.06) and (17.95,13.91) .. (17.95,13.91)
),
1,((19.37,14.12)
 .. controls (19.37,14.12) and (19.05,18.08) .. (18.81,20.23)
 .. controls (18.57,22.39) and (16.75,23.43) .. (16.54,24.68)
 .. controls (16.34,25.93) and (12.68,29.27) .. (12.28,31.25)
 .. controls (11.88,33.22) and (10.24,34.44) .. (9.84,36.42)
 .. controls (9.43,38.39) and (6.61,37.25) .. (6.61,37.25)
),
1,((6.61,37.25)
 .. controls (6.61,37.25) and (5.67,39.03) .. (6.55,39.59)
 .. controls (7.43,40.15) and (7.59,40.86) .. (9.78,38.93)
 .. controls (11.97,37.00) and (14.16,35.96) .. (14.38,33.81)
 .. controls (14.60,31.65) and (13.58,28.75) .. (15.40,27.89)
 .. controls (17.21,27.03) and (25.71,23.98) .. (26.97,23.82)
 .. controls (28.23,23.67) and (33.59,23.09) .. (33.93,25.77)
 .. controls (34.24,28.12) and (32.45,27.72) .. (33.14,28.82)
 .. controls (33.83,29.92) and (33.42,31.53) .. (32.51,32.04)
 .. controls (31.60,32.56) and (29.94,33.78) .. (31.01,33.81)
 .. controls (32.09,33.83) and (35.77,36.97) .. (37.05,36.11)
 .. controls (38.32,35.25) and (40.47,34.95) .. (42.07,35.35)
 .. controls (43.67,35.75) and (47.41,36.75) .. (48.65,37.14)
 .. controls (49.90,37.54) and (50.17,40.24) .. (52.85,40.50)
 .. controls (55.53,40.76) and (61.68,44.32) .. (62.56,42.78)
 .. controls (63.49,41.17) and (66.79,42.39) .. (67.66,43.18)
 .. controls (68.46,43.91) and (68.94,45.82) .. (68.20,47.40)
 .. controls (67.44,49.01) and (67.38,50.62) .. (66.27,51.68)
 .. controls (65.16,52.73) and (61.98,56.42) .. (63.96,56.30)
 .. controls (65.93,56.17) and (67.98,53.70) .. (69.38,54.64)
 .. controls (70.78,55.58) and (70.93,56.49) .. (72.54,56.54)
 .. controls (74.12,56.58) and (77.11,55.59) .. (77.58,54.89)
),
1,((77.72,57.39)
 .. controls (77.72,57.39) and (74.75,59.64) .. (72.65,59.05)
 .. controls (70.52,58.45) and (70.58,56.29) .. (68.25,56.76)
 .. controls (65.90,57.24) and (62.23,60.21) .. (61.74,58.58)
 .. controls (61.25,56.94) and (62.40,54.63) .. (63.73,52.14)
 .. controls (65.07,49.66) and (66.73,47.36) .. (66.71,45.90)
 .. controls (66.69,44.55) and (65.10,42.48) .. (63.95,44.15)
 .. controls (63.03,45.47) and (63.09,46.03) .. (61.51,44.94)
 .. controls (59.96,43.88) and (58.69,43.37) .. (56.90,43.13)
 .. controls (55.11,42.90) and (50.14,41.14) .. (49.45,40.40)
 .. controls (48.75,39.66) and (47.36,38.54) .. (45.40,37.95)
 .. controls (43.45,37.36) and (40.06,37.08) .. (38.79,37.58)
 .. controls (37.53,38.09) and (33.10,36.73) .. (31.50,35.79)
 .. controls (29.91,34.86) and (26.53,33.34) .. (28.17,32.66)
 .. controls (29.81,31.98) and (31.27,31.11) .. (30.39,30.37)
 .. controls (29.52,29.63) and (32.46,27.18) .. (31.02,26.96)
 .. controls (29.60,26.75) and (27.29,25.63) .. (24.76,26.47)
 .. controls (22.23,27.31) and (17.74,27.40) .. (17.35,29.37)
 .. controls (16.95,31.34) and (16.85,36.02) .. (15.73,37.97)
 .. controls (14.61,39.93) and (10.37,45.24) .. (10.37,45.24)
 .. controls (10.37,45.24) and (9.42,47.55) .. (6.91,47.14)
 .. controls (4.41,46.72) and (4.75,39.72) .. (3.06,42.74)
 .. controls (1.37,45.76) and (1.27,50.43) .. (1.27,50.43)
),
1,((-1.41,49.83)
 .. controls (-1.41,49.83) and (0.34,43.76) .. (1.17,38.92)
 .. controls (2.00,34.08) and (4.20,32.50) .. (2.76,32.47)
 .. controls (1.32,32.44) and (-1.01,32.39) .. (-1.01,32.39)
),
1,((-1.31,30.03)
 .. controls (-1.31,30.03) and (2.60,31.57) .. (3.00,29.77)
 .. controls (3.41,27.98) and (5.60,26.59) .. (4.38,25.12)
 .. controls (3.17,23.66) and (1.03,23.07) .. (1.97,20.94)
 .. controls (2.92,18.80) and (10.10,12.11) .. (8.67,12.07)
 .. controls (7.24,12.04) and (-4.07,11.62) .. (-5.71,12.48)
 .. controls (-7.34,13.34) and (-7.02,15.69) .. (-10.25,15.44)
 .. controls (-13.47,15.19) and (-15.60,13.89) .. (-17.76,14.56)
 .. controls (-19.93,15.23) and (-21.45,18.98) .. (-23.96,18.92)
 .. controls (-26.47,18.87) and (-30.78,19.32) .. (-32.19,18.03)
 .. controls (-33.59,16.74) and (-36.77,14.70) .. (-39.09,14.28)
 .. controls (-41.41,13.87) and (-42.28,12.95) .. (-44.97,13.25)
 .. controls (-47.67,13.55) and (-50.19,14.57) .. (-51.42,13.47)
 .. controls (-52.65,12.36) and (-51.69,9.87) .. (-54.75,9.80)
 .. controls (-57.80,9.73) and (-63.16,8.71) .. (-64.93,7.78)
 .. controls (-66.70,6.84) and (-68.69,7.15) .. (-67.35,3.76)
 .. controls (-66.00,0.37) and (-65.10,0.57) .. (-63.28,-0.11)
 .. controls (-61.46,-0.79) and (-58.04,-0.53) .. (-60.14,-2.92)
 .. controls (-62.25,-5.30) and (-62.25,-5.48) .. (-61.27,-8.53)
 .. controls (-60.30,-11.56) and (-63.90,-11.28) .. (-64.94,-12.75)
 .. controls (-65.98,-14.21) and (-69.40,-13.39) .. (-68.63,-15.71)
 .. controls (-67.85,-18.03) and (-67.03,-22.88) .. (-64.47,-24.62)
 .. controls (-61.90,-26.37) and (-60.08,-26.69) .. (-59.12,-29.01)
 .. controls (-58.17,-31.33) and (-56.63,-35.43) .. (-55.84,-38.65)
 .. controls (-55.04,-41.88) and (-49.50,-47.88) .. (-48.03,-49.11)
 .. controls (-46.55,-50.34) and (-47.45,-50.54) .. (-47.77,-51.99)
 .. controls (-48.10,-53.44) and (-46.62,-55.03) .. (-48.23,-55.06)
 .. controls (-49.84,-55.10) and (-53.45,-54.28) .. (-54.87,-55.03)
 .. controls (-56.29,-55.78) and (-57.14,-57.60) .. (-59.10,-57.64)
 .. controls (-61.07,-57.68) and (-62.31,-58.43) .. (-63.41,-56.83)
 .. controls (-64.51,-55.23) and (-66.31,-54.90) .. (-67.01,-56.17)
));
draw_upscrap(0)(1,((9.50,29.02)
 -- (7.76,34.21)
),
1,((7.76,34.21)
 .. controls (7.76,34.21) and (9.53,34.79) .. (9.75,32.99)
 .. controls (9.98,31.20) and (11.42,29.97) .. (11.27,29.06)
 .. controls (11.12,28.16) and (9.50,29.02) .. (9.50,29.02)
));
draw_downscrap;
endfig;
beginfig(22);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((77.72,57.39)
 .. controls (77.72,57.39) and (74.75,59.64) .. (72.65,59.05)
 .. controls (70.52,58.45) and (70.58,56.29) .. (68.25,56.76)
 .. controls (65.90,57.24) and (62.23,60.21) .. (61.74,58.58)
 .. controls (61.25,56.94) and (62.40,54.63) .. (63.73,52.14)
 .. controls (65.07,49.66) and (66.73,47.36) .. (66.71,45.90)
 .. controls (66.69,44.55) and (65.10,42.48) .. (63.95,44.15)
 .. controls (63.03,45.47) and (63.09,46.03) .. (61.51,44.94)
 .. controls (59.96,43.88) and (58.69,43.37) .. (56.90,43.13)
 .. controls (55.11,42.90) and (50.14,41.14) .. (49.45,40.40)
 .. controls (48.75,39.66) and (47.36,38.54) .. (45.40,37.95)
 .. controls (43.45,37.36) and (40.06,37.08) .. (38.79,37.58)
 .. controls (37.53,38.09) and (33.10,36.73) .. (31.50,35.79)
 .. controls (29.91,34.86) and (26.53,33.34) .. (28.17,32.66)
 .. controls (29.81,31.98) and (31.27,31.11) .. (30.39,30.37)
 .. controls (29.52,29.63) and (32.46,27.18) .. (31.02,26.96)
 .. controls (29.60,26.75) and (27.29,25.63) .. (24.76,26.47)
 .. controls (22.23,27.31) and (17.74,27.40) .. (17.35,29.37)
 .. controls (16.95,31.34) and (16.85,36.02) .. (15.73,37.97)
 .. controls (14.61,39.93) and (10.37,45.24) .. (10.37,45.24)
 .. controls (10.37,45.24) and (9.42,47.55) .. (6.91,47.14)
 .. controls (4.41,46.72) and (4.75,39.72) .. (3.06,42.74)
 .. controls (1.37,45.76) and (1.27,50.43) .. (1.27,50.43)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((19.37,14.12)
 .. controls (19.37,14.12) and (19.05,18.08) .. (18.81,20.23)
 .. controls (18.57,22.39) and (16.75,23.43) .. (16.54,24.68)
 .. controls (16.34,25.93) and (12.68,29.27) .. (12.28,31.25)
 .. controls (11.88,33.22) and (10.24,34.44) .. (9.84,36.42)
 .. controls (9.43,38.39) and (6.61,37.25) .. (6.61,37.25)
));
drawoptions();
p_narrowend((19.30,10.17),10.1,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((13.04,22.62)
 .. controls (13.04,22.62) and (15.72,21.96) .. (15.78,20.17)
 .. controls (15.85,18.36) and (14.51,15.63) .. (14.51,15.63)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((16.33,14.41)
 .. controls (16.33,14.41) and (17.60,18.95) .. (17.65,17.51)
 .. controls (17.71,16.06) and (17.95,13.91) .. (17.95,13.91)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((7.76,34.21)
 .. controls (7.76,34.21) and (9.53,34.79) .. (9.75,32.99)
 .. controls (9.98,31.20) and (11.42,29.97) .. (11.27,29.06)
 .. controls (11.12,28.16) and (9.50,29.02) .. (9.50,29.02)
));
drawoptions();
p_narrowend((-0.64,55.59),188.4,1.00,(0,0));
drawoptions();
p_narrowend((-6.17,31.18),270.1,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1.41,49.83)
 .. controls (-1.41,49.83) and (0.34,43.76) .. (1.17,38.92)
 .. controls (2.00,34.08) and (4.20,32.50) .. (2.76,32.47)
 .. controls (1.32,32.44) and (-1.01,32.39) .. (-1.01,32.39)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1.31,30.03)
 .. controls (-1.31,30.03) and (2.60,31.57) .. (3.00,29.77)
 .. controls (3.41,27.98) and (5.60,26.59) .. (4.38,25.12)
 .. controls (3.17,23.66) and (1.03,23.07) .. (1.97,20.94)
 .. controls (2.92,18.80) and (10.10,12.11) .. (8.67,12.07)
 .. controls (7.24,12.04) and (-4.07,11.62) .. (-5.71,12.48)
 .. controls (-7.34,13.34) and (-7.02,15.69) .. (-10.25,15.44)
 .. controls (-13.47,15.19) and (-15.60,13.89) .. (-17.76,14.56)
 .. controls (-19.93,15.23) and (-21.45,18.98) .. (-23.96,18.92)
 .. controls (-26.47,18.87) and (-30.78,19.32) .. (-32.19,18.03)
 .. controls (-33.59,16.74) and (-36.77,14.70) .. (-39.09,14.28)
 .. controls (-41.41,13.87) and (-42.28,12.95) .. (-44.97,13.25)
 .. controls (-47.67,13.55) and (-50.19,14.57) .. (-51.42,13.47)
 .. controls (-52.65,12.36) and (-51.69,9.87) .. (-54.75,9.80)
 .. controls (-57.80,9.73) and (-63.16,8.71) .. (-64.93,7.78)
 .. controls (-66.70,6.84) and (-68.69,7.15) .. (-67.35,3.76)
 .. controls (-66.00,0.37) and (-65.10,0.57) .. (-63.28,-0.11)
 .. controls (-61.46,-0.79) and (-58.04,-0.53) .. (-60.14,-2.92)
 .. controls (-62.25,-5.30) and (-62.25,-5.48) .. (-61.27,-8.53)
 .. controls (-60.30,-11.56) and (-63.90,-11.28) .. (-64.94,-12.75)
 .. controls (-65.98,-14.21) and (-69.40,-13.39) .. (-68.63,-15.71)
 .. controls (-67.85,-18.03) and (-67.03,-22.88) .. (-64.47,-24.62)
 .. controls (-61.90,-26.37) and (-60.08,-26.69) .. (-59.12,-29.01)
 .. controls (-58.17,-31.33) and (-56.63,-35.43) .. (-55.84,-38.65)
 .. controls (-55.04,-41.88) and (-49.50,-47.88) .. (-48.03,-49.11)
 .. controls (-46.55,-50.34) and (-47.45,-50.54) .. (-47.77,-51.99)
 .. controls (-48.10,-53.44) and (-46.62,-55.03) .. (-48.23,-55.06)
 .. controls (-49.84,-55.10) and (-53.45,-54.28) .. (-54.87,-55.03)
 .. controls (-56.29,-55.78) and (-57.14,-57.60) .. (-59.10,-57.64)
 .. controls (-61.07,-57.68) and (-62.31,-58.43) .. (-63.41,-56.83)
 .. controls (-64.51,-55.23) and (-66.31,-54.90) .. (-67.01,-56.17)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-66.41,-59.04)
 .. controls (-66.41,-59.04) and (-66.09,-57.23) .. (-65.00,-58.29)
 .. controls (-63.90,-59.35) and (-63.88,-60.25) .. (-61.20,-60.02)
 .. controls (-58.52,-59.78) and (-56.37,-59.91) .. (-54.97,-58.44)
 .. controls (-53.57,-56.97) and (-54.46,-56.99) .. (-50.88,-56.91)
 .. controls (-47.30,-56.84) and (-44.03,-58.38) .. (-44.78,-56.78)
 .. controls (-45.54,-55.18) and (-45.90,-54.83) .. (-45.94,-53.39)
 .. controls (-45.97,-51.95) and (-44.92,-50.66) .. (-45.50,-49.23)
 .. controls (-46.07,-47.80) and (-49.97,-43.03) .. (-53.11,-39.67)
 .. controls (-56.25,-36.32) and (-56.87,-32.74) .. (-56.92,-30.58)
 .. controls (-56.97,-28.42) and (-57.74,-26.27) .. (-59.58,-25.05)
 .. controls (-61.42,-23.83) and (-65.85,-18.89) .. (-65.53,-17.44)
 .. controls (-65.21,-15.99) and (-63.09,-15.04) .. (-62.05,-13.58)
 .. controls (-61.00,-12.12) and (-57.84,-8.81) .. (-58.77,-7.57)
 .. controls (-59.70,-6.32) and (-59.52,-6.50) .. (-58.48,-4.68)
 .. controls (-57.45,-2.85) and (-54.80,-0.45) .. (-57.52,0.21)
 .. controls (-60.24,0.86) and (-64.96,2.38) .. (-65.18,3.82)
 .. controls (-65.41,5.25) and (-65.41,5.25) .. (-63.09,5.84)
 .. controls (-60.78,6.43) and (-59.72,7.36) .. (-56.31,7.61)
 .. controls (-52.91,7.87) and (-50.22,8.29) .. (-50.25,9.55)
 .. controls (-50.28,10.81) and (-50.30,11.53) .. (-47.98,11.58)
 .. controls (-45.65,11.63) and (-45.10,10.73) .. (-42.41,10.80)
 .. controls (-39.73,10.86) and (-39.95,12.47) .. (-37.98,12.69)
 .. controls (-36.01,12.92) and (-32.14,16.06) .. (-30.17,16.10)
 .. controls (-28.20,16.15) and (-27.87,17.23) .. (-24.79,15.50)
 .. controls (-21.70,13.76) and (-21.48,11.97) .. (-18.25,12.03)
 .. controls (-15.02,12.10) and (-11.13,14.89) .. (-9.67,13.30)
 .. controls (-8.20,11.71) and (-5.47,9.79) .. (-2.24,9.86)
 .. controls (1.00,9.93) and (6.23,8.97) .. (7.83,9.54)
 .. controls (9.43,10.12) and (13.35,11.46) .. (11.34,13.04)
 .. controls (9.32,14.61) and (3.06,20.60) .. (5.04,20.64)
 .. controls (7.01,20.69) and (9.50,21.46) .. (9.83,22.73)
 .. controls (10.16,24.00) and (8.83,27.02) .. (10.30,25.44)
 .. controls (11.77,23.85) and (13.04,22.62) .. (13.04,22.62)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((9.50,29.02)
 -- (7.76,34.21)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((6.61,37.25)
 .. controls (6.61,37.25) and (5.67,39.03) .. (6.55,39.59)
 .. controls (7.43,40.15) and (7.59,40.86) .. (9.78,38.93)
 .. controls (11.97,37.00) and (14.16,35.96) .. (14.38,33.81)
 .. controls (14.60,31.65) and (13.58,28.75) .. (15.40,27.89)
 .. controls (17.21,27.03) and (25.71,23.98) .. (26.97,23.82)
 .. controls (28.23,23.67) and (33.59,23.09) .. (33.93,25.77)
 .. controls (34.24,28.12) and (32.45,27.72) .. (33.14,28.82)
 .. controls (33.83,29.92) and (33.42,31.53) .. (32.51,32.04)
 .. controls (31.60,32.56) and (29.94,33.78) .. (31.01,33.81)
 .. controls (32.09,33.83) and (35.77,36.97) .. (37.05,36.11)
 .. controls (38.32,35.25) and (40.47,34.95) .. (42.07,35.35)
 .. controls (43.67,35.75) and (47.41,36.75) .. (48.65,37.14)
 .. controls (49.90,37.54) and (50.17,40.24) .. (52.85,40.50)
 .. controls (55.53,40.76) and (61.68,44.32) .. (62.56,42.78)
 .. controls (63.49,41.17) and (66.79,42.39) .. (67.66,43.18)
 .. controls (68.46,43.91) and (68.94,45.82) .. (68.20,47.40)
 .. controls (67.44,49.01) and (67.38,50.62) .. (66.27,51.68)
 .. controls (65.16,52.73) and (61.98,56.42) .. (63.96,56.30)
 .. controls (65.93,56.17) and (67.98,53.70) .. (69.38,54.64)
 .. controls (70.78,55.58) and (70.93,56.49) .. (72.54,56.54)
 .. controls (74.12,56.58) and (77.11,55.59) .. (77.58,54.89)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((83.11,50.62),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((78.22,56.46),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((72.69,57.76),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((68.57,55.51),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((62.20,57.50),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((64.34,53.25),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((66.67,48.38),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((68.30,45.66),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((66.91,44.21),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((63.96,43.15),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((62.17,44.13),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((59.77,43.01),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((54.97,41.87),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((50.89,40.43),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((48.37,38.10),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((43.37,36.43),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((40.09,36.26),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((36.50,37.26),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((33.91,35.84),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((29.20,33.43),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((32.11,30.57),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((31.20,29.03),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((32.39,25.81),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((24.91,25.20),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((16.60,28.34),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((14.62,36.76),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((8.02,44.30),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((3.82,39.76),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((7.77,24.03),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((3.33,21.45),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((10.81,11.55),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((6.54,10.42),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-7.14,11.48),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-9.19,14.33),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-17.59,13.19),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-24.28,17.18),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-30.32,17.44),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-34.84,14.81),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-40.47,12.98),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-47.55,12.61),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-42.01,11.97),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-51.49,12.07),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-51.84,9.44),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-60.46,7.96),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-67.07,5.82),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-66.08,2.66),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-58.09,-1.06),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-61.08,-6.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-59.94,-8.67),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-64.01,-14.51),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-67.18,-16.02),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-62.80,-23.57),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-58.27,-27.33),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-57.25,-33.05),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-54.80,-39.73),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-46.31,-49.84),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-47.06,-52.70),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-46.46,-55.97),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-53.75,-55.92),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-57.13,-58.32),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-62.45,-58.75),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-64.76,-56.71),1,0,"");
endfig;
beginfig(23);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char69 \char116 \char114 \char46 \mainfont{} etex,(68.40,37.81),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char69 \char116 \char114 \char46 \mainfont{} etex,(40.61,24.52),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{\hfil#\hfil\cr\ \thfb\char77 \char97 \char114 \char113 \char117 \char97 \char103 \char101 \ \cr\thfb \ \char57 \char54 \cr}}\mainfont{} etex,(21.41,56.92),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{\hfil#\hfil\cr\thfb\char77 \char97 \char114 \char113 \char117 \char97 \char103 \char101 \ \cr\thfb \ \char55 \char52 \cr}}\mainfont{} etex,(7.68,0.20),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{\hfil#\hfil\cr\ \thfb\char76 \char101 \ \char71 \char114 \char97 \char110 \char100 \ \cr\thfb \ \char77 \thfc\char233 \thfb\char97 \char110 \char100 \char114 \char101 \cr}}\mainfont{} etex,(-18.30,44.19),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char76 \char101 \ \char77 \thfc\char233 \thfb\char97 \char110 \char100 \char114 \char101 \ \char84 \char97 \char110 \char116 \ \char82 \char101 \char100 \char111 \char117 \char116 \thfc\char233 \mainfont{} etex,(-84.26,-9.43),93.9,0);
endfig;
current_scrap := "A21-5";
ATTR__scrap := "A21-5";
beginfig(24);
ATTR__height := -1;
drawoptions();
l_pit(((-11.66,0.82)
 .. controls (-10.94,0.67) and (-10.69,3.20) .. (-10.69,3.20)
));
ATTR__height := -1;
drawoptions();
l_contour(((-1.13,-1.76)
 .. controls (-1.13,-1.76) and (-1.93,0.00) .. (-0.56,1.50)
 .. controls (0.81,3.00) and (3.47,3.66) .. (3.47,3.66)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-5.25,0.50)
 .. controls (-5.25,0.50) and (-6.36,2.68) .. (-4.95,3.28)
 .. controls (-3.54,3.88) and (-0.70,4.73) .. (-0.70,4.73)
),-1);
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-4.75,-2.91) -- (-2.06,-8.28)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-4.75,-2.91) -- (-12.51,-2.18)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-4.75,-2.91) -- (-6.54,-1.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-12.51,-2.18) -- (-4.75,-2.91)));
endfig;
beginfig(25);
draw_upscrap(1)(1,((3.02,1.84)
 -- (-10.69,3.20)
),
1,((-11.66,0.82)
 -- (1.36,-1.29)
));
draw_downscrap;
endfig;
beginfig(26);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((3.02,1.84)
 -- (-10.69,3.20)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-11.66,0.82)
 -- (1.36,-1.29)
));
ATTR__height := -1;
drawoptions();
l_gradient(((1.84,-0.01)
 -- (-7.18,1.02)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-12.51,-2.18),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-4.75,-2.91),1,0,"");
endfig;
beginfig(27);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char67 \char111 \char108 \char109 \char46 \mainfont{} etex,(12.49,2.81),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char69 \char115 \char99 \char97 \char108 \char97 \char100 \char101 \mainfont{} etex,(11.20,-4.43),0.0,0);
endfig;
current_scrap := "A21-4";
ATTR__scrap := "A21-4";
beginfig(28);
ATTR__height := -1;
drawoptions();
l_pit(((-46.39,-6.35)
 .. controls (-46.39,-6.35) and (-44.24,-5.04) .. (-43.21,-3.22)
 .. controls (-42.17,-1.40) and (-42.22,0.22) .. (-42.22,0.22)
));
ATTR__height := -1;
drawoptions();
l_pit(((-42.92,-8.25)
 .. controls (-42.92,-8.25) and (-39.31,-7.99) .. (-39.17,-6.55)
 .. controls (-39.03,-5.11) and (-38.01,-2.03) .. (-38.01,-2.03)
));
ATTR__height := -1;
drawoptions();
l_pit(((-1.50,-21.07)
 .. controls (-1.50,-21.07) and (-3.56,-19.13) .. (-4.91,-15.90)
 .. controls (-6.24,-12.69) and (-7.01,-10.56) .. (-7.01,-10.56)
));
ATTR__height := -1;
drawoptions();
l_pit(((-5.60,-10.07)
 .. controls (-5.60,-10.07) and (-4.37,-11.79) .. (-2.27,-9.86)
 .. controls (0.10,-7.69) and (-0.04,-5.91) .. (-0.04,-5.91)
));
ATTR__height := -1;
drawoptions();
l_pit(((26.17,12.32)
 .. controls (26.17,12.32) and (29.10,10.05) .. (30.72,9.90)
 .. controls (32.35,9.76) and (34.51,9.81) .. (36.26,11.82)
 .. controls (38.02,13.84) and (38.05,12.58) .. (38.37,14.21)
 .. controls (38.70,15.84) and (37.25,16.17) .. (36.52,16.69)
 .. controls (35.79,17.21) and (35.42,17.57) .. (34.15,18.08)
));
ATTR__height := -1;
drawoptions();
l_floormeander(((-12.65,1.05)
 .. controls (-12.65,1.05) and (-12.42,-1.47) .. (-15.62,-3.52)
 .. controls (-18.81,-5.57) and (-20.02,-8.12) .. (-24.70,-8.40)
 .. controls (-29.38,-8.69) and (-28.24,-10.82) .. (-32.59,-10.19)
 .. controls (-36.93,-9.56) and (-40.21,-7.95) .. (-40.52,-7.09)
));
drawoptions();
p_blocks((-41.37,-4.80),0.0,0.50,(0,0));
drawoptions();
p_blocks((-38.84,-12.49),0.0,0.50,(0,0));
drawoptions();
p_blocks((-28.75,-12.27),0.0,0.50,(0,0));
drawoptions();
p_blocks((-36.19,-17.65),0.0,0.50,(0,0));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-63.17,-24.85) -- (-74.23,-20.70)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-63.17,-24.85) -- (-45.75,-18.59)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-45.75,-18.59) -- (-63.17,-24.85)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-45.75,-18.59) -- (-34.12,-16.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((33.81,13.84) -- (25.99,9.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((33.81,13.84) -- (33.81,13.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((25.99,9.39) -- (23.98,7.02)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((25.99,9.39) -- (33.81,13.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((23.98,7.02) -- (19.21,5.32)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((23.98,7.02) -- (25.99,9.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((19.21,5.32) -- (6.08,-2.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((19.21,5.32) -- (23.98,7.02)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((6.08,-2.15) -- (2.08,-8.98)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((6.08,-2.15) -- (19.21,5.32)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((0.71,-10.59) -- (2.49,-12.40)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((0.71,-10.59) -- (2.08,-8.98)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.08,-8.98) -- (0.71,-10.59)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.08,-8.98) -- (6.08,-2.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.49,-12.40) -- (5.19,-17.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.49,-12.40) -- (-5.26,-11.67)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.49,-12.40) -- (0.71,-10.59)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((5.19,-17.77) -- (-9.45,-13.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((5.19,-17.77) -- (2.49,-12.40)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-9.45,-13.75) -- (-10.39,-2.21)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-9.45,-13.75) -- (5.19,-17.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.69,15.03) -- (2.60,-0.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.60,-0.01) -- (2.69,15.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.60,-0.01) -- (-10.39,-2.21)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-10.39,-2.21) -- (-22.94,-12.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-10.39,-2.21) -- (2.60,-0.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-10.39,-2.21) -- (-9.45,-13.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-22.94,-12.61) -- (-34.12,-16.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-22.94,-12.61) -- (-10.39,-2.21)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-34.12,-16.60) -- (-42.77,-4.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-34.12,-16.60) -- (-45.75,-18.59)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-34.12,-16.60) -- (-22.94,-12.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-40.52,-7.09) -- (-41.49,-8.68)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-40.52,-7.09) -- (-42.77,-4.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-42.77,-4.29) -- (-40.52,-7.09)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-42.77,-4.29) -- (-34.12,-16.60)));
endfig;
beginfig(29);
draw_upscrap(1)(1,((-46.06,-25.24)
 .. controls (-46.06,-25.24) and (-44.20,-20.70) .. (-42.95,-20.49)
 .. controls (-41.70,-20.29) and (-39.37,-19.88) .. (-33.82,-19.04)
 .. controls (-28.26,-18.20) and (-24.63,-19.56) .. (-20.37,-16.77)
 .. controls (-16.11,-13.98) and (-15.91,-14.88) .. (-10.81,-17.65)
 .. controls (-5.67,-20.45) and (2.91,-19.33) .. (5.09,-20.18)
 .. controls (7.28,-21.03) and (10.21,-22.02) .. (10.21,-22.02)
),
1,((11.05,-19.66)
 .. controls (11.05,-19.66) and (6.81,-16.17) .. (5.69,-14.75)
 .. controls (4.58,-13.32) and (2.26,-12.51) .. (3.28,-10.35)
 .. controls (4.33,-8.12) and (3.67,-4.37) .. (6.89,-3.76)
 .. controls (10.12,-3.14) and (18.58,-2.94) .. (21.57,0.17)
 .. controls (24.57,3.28) and (24.33,5.80) .. (25.93,7.10)
 .. controls (27.52,8.39) and (28.01,10.38) .. (30.72,9.90)
 .. controls (33.44,9.42) and (33.43,9.78) .. (35.38,11.08)
 .. controls (37.33,12.39) and (37.51,12.57) .. (38.37,14.21)
 .. controls (39.24,15.85) and (41.38,16.62) .. (41.38,16.62)
),
1,((41.38,16.62)
 .. controls (41.38,16.62) and (44.87,21.21) .. (46.68,20.90)
 .. controls (48.49,20.59) and (50.32,19.01) .. (51.36,20.67)
 .. controls (52.40,22.32) and (52.70,25.04) .. (53.36,27.41)
 .. controls (54.02,29.78) and (55.98,30.55) .. (60.47,30.69)
 .. controls (64.96,30.82) and (70.00,30.62) .. (70.00,30.62)
),
1,((69.95,32.79)
 .. controls (69.95,32.79) and (64.20,32.61) .. (60.43,32.50)
 .. controls (56.65,32.38) and (51.52,29.34) .. (51.55,27.90)
 .. controls (51.59,26.45) and (52.05,22.13) .. (49.71,22.06)
 .. controls (47.37,22.00) and (47.88,23.64) .. (45.74,22.50)
 .. controls (43.61,21.36) and (40.44,18.40) .. (40.44,18.40)
),
1,((40.44,18.40)
 .. controls (40.44,18.40) and (37.27,15.27) .. (36.52,16.69)
 .. controls (35.77,18.11) and (38.05,20.69) .. (38.05,20.69)
),
1,((36.05,21.55)
 .. controls (36.05,21.55) and (35.94,18.30) .. (34.15,18.08)
 .. controls (32.35,17.86) and (30.28,21.78) .. (30.16,19.07)
 .. controls (30.04,16.37) and (33.68,14.83) .. (30.26,14.75)
 .. controls (26.84,14.68) and (26.45,16.11) .. (26.45,16.11)
),
1,((25.05,14.10)
 .. controls (25.05,14.10) and (30.12,12.77) .. (29.05,12.57)
 .. controls (27.97,12.36) and (26.73,11.44) .. (25.84,10.88)
 .. controls (24.95,10.32) and (24.81,8.69) .. (22.29,8.64)
 .. controls (19.77,8.59) and (20.29,9.50) .. (17.09,7.45)
 .. controls (13.90,5.40) and (6.27,0.19) .. (4.86,-1.10)
 .. controls (3.44,-2.39) and (2.35,-9.26) .. (0.03,-8.54)
),
1,((0.03,-8.54)
 .. controls (0.03,-8.54) and (-7.13,-4.79) .. (-3.74,-4.00)
 .. controls (-0.34,-3.20) and (3.45,-2.93) .. (3.43,-1.49)
 .. controls (3.40,-0.05) and (3.69,2.84) .. (3.98,6.08)
 .. controls (4.27,9.33) and (4.16,14.37) .. (4.68,15.10)
 .. controls (5.21,15.83) and (6.24,17.65) .. (6.24,17.65)
),
1,((5.14,18.89)
 .. controls (1.58,17.19) and (0.32,17.16) .. (0.36,15.18)
 .. controls (0.40,13.20) and (2.24,3.34) .. (0.08,3.30)
 .. controls (-2.09,3.25) and (-8.70,1.49) .. (-11.43,2.51)
 .. controls (-12.27,2.83) and (-10.77,4.86) .. (-10.77,4.86)
),
1,((-13.48,5.34)
 .. controls (-13.48,5.34) and (-10.96,5.21) .. (-14.64,1.00)
 .. controls (-18.32,-3.22) and (-19.52,-6.31) .. (-24.20,-6.41)
 .. controls (-28.89,-6.52) and (-36.65,-6.32) .. (-38.86,-4.57)
 .. controls (-41.06,-2.81) and (-43.28,-1.24) .. (-43.83,-0.89)
),
1,((-44.96,-6.32)
 .. controls (-44.96,-6.32) and (-43.72,-4.85) .. (-43.32,-6.46)
 .. controls (-42.93,-8.07) and (-40.78,-7.66) .. (-42.12,-11.30)
 .. controls (-43.46,-14.93) and (-43.39,-16.91) .. (-46.43,-17.69)
 .. controls (-49.46,-18.48) and (-61.57,-24.15) .. (-63.02,-23.28)
 .. controls (-64.48,-22.41) and (-69.74,-20.01) .. (-69.74,-20.01)
),
1,((-70.19,-24.33)
 .. controls (-70.19,-24.33) and (-64.04,-26.00) .. (-62.07,-25.78)
 .. controls (-60.10,-25.55) and (-48.83,-21.88) .. (-45.80,-21.10)
 .. controls (-42.77,-20.31) and (-47.89,-23.84) .. (-47.89,-23.84)
));
draw_upscrap(0)(1,((-6.92,-6.59)
 .. controls (-6.92,-6.59) and (-5.01,-7.39) .. (-4.44,-8.72)
 .. controls (-3.88,-10.04) and (5.74,-16.92) .. (0.67,-15.06)
 .. controls (-3.74,-13.44) and (-7.87,-12.00) .. (-8.63,-10.21)
 .. controls (-9.39,-8.43) and (-6.92,-6.59) .. cycle
));
draw_downscrap;
endfig;
beginfig(30);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-44.96,-6.32)
 .. controls (-44.96,-6.32) and (-43.72,-4.85) .. (-43.32,-6.46)
 .. controls (-42.93,-8.07) and (-40.78,-7.66) .. (-42.12,-11.30)
 .. controls (-43.46,-14.93) and (-43.39,-16.91) .. (-46.43,-17.69)
 .. controls (-49.46,-18.48) and (-61.57,-24.15) .. (-63.02,-23.28)
 .. controls (-64.48,-22.41) and (-69.74,-20.01) .. (-69.74,-20.01)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-70.19,-24.33)
 .. controls (-70.19,-24.33) and (-64.04,-26.00) .. (-62.07,-25.78)
 .. controls (-60.10,-25.55) and (-48.83,-21.88) .. (-45.80,-21.10)
 .. controls (-42.77,-20.31) and (-47.89,-23.84) .. (-47.89,-23.84)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-46.06,-25.24)
 .. controls (-46.06,-25.24) and (-44.20,-20.70) .. (-42.95,-20.49)
 .. controls (-41.70,-20.29) and (-39.37,-19.88) .. (-33.82,-19.04)
 .. controls (-28.26,-18.20) and (-24.63,-19.56) .. (-20.37,-16.77)
 .. controls (-16.11,-13.98) and (-15.91,-14.88) .. (-10.81,-17.65)
 .. controls (-5.67,-20.45) and (2.91,-19.33) .. (5.09,-20.18)
 .. controls (7.28,-21.03) and (10.21,-22.02) .. (10.21,-22.02)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((11.05,-19.66)
 .. controls (11.05,-19.66) and (6.81,-16.17) .. (5.69,-14.75)
 .. controls (4.58,-13.32) and (2.26,-12.51) .. (3.28,-10.35)
 .. controls (4.33,-8.12) and (3.67,-4.37) .. (6.89,-3.76)
 .. controls (10.12,-3.14) and (18.58,-2.94) .. (21.57,0.17)
 .. controls (24.57,3.28) and (24.33,5.80) .. (25.93,7.10)
 .. controls (27.52,8.39) and (28.01,10.38) .. (30.72,9.90)
 .. controls (33.44,9.42) and (33.43,9.78) .. (35.38,11.08)
 .. controls (37.33,12.39) and (37.51,12.57) .. (38.37,14.21)
 .. controls (39.24,15.85) and (41.38,16.62) .. (41.38,16.62)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((40.44,18.40)
 .. controls (40.44,18.40) and (37.27,15.27) .. (36.52,16.69)
 .. controls (35.77,18.11) and (38.05,20.69) .. (38.05,20.69)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((36.05,21.55)
 .. controls (36.05,21.55) and (35.94,18.30) .. (34.15,18.08)
 .. controls (32.35,17.86) and (30.28,21.78) .. (30.16,19.07)
 .. controls (30.04,16.37) and (33.68,14.83) .. (30.26,14.75)
 .. controls (26.84,14.68) and (26.45,16.11) .. (26.45,16.11)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((25.05,14.10)
 .. controls (25.05,14.10) and (30.12,12.77) .. (29.05,12.57)
 .. controls (27.97,12.36) and (26.73,11.44) .. (25.84,10.88)
 .. controls (24.95,10.32) and (24.81,8.69) .. (22.29,8.64)
 .. controls (19.77,8.59) and (20.29,9.50) .. (17.09,7.45)
 .. controls (13.90,5.40) and (6.27,0.19) .. (4.86,-1.10)
 .. controls (3.44,-2.39) and (2.35,-9.26) .. (0.03,-8.54)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((5.14,18.89)
 .. controls (1.58,17.19) and (0.32,17.16) .. (0.36,15.18)
 .. controls (0.40,13.20) and (2.24,3.34) .. (0.08,3.30)
 .. controls (-2.09,3.25) and (-8.70,1.49) .. (-11.43,2.51)
 .. controls (-12.27,2.83) and (-10.77,4.86) .. (-10.77,4.86)
));
string ATTR_code;
ATTR_code := "D";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \thfc\char233 \thfb\char116 \char114 \char111 \char105 \char116 \mainfont{}etex;
drawoptions();
p_continuation((-11.61,8.79),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
string ATTR_code;
ATTR_code := "D";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \thfc\char233 \thfb\char116 \char114 \char111 \char105 \char116 \mainfont{}etex;
drawoptions();
p_continuation((8.46,22.40),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
string ATTR_code;
ATTR_code := "E";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \char101 \char110 \ \char104 \char97 \char117 \char116 \char101 \char117 \char114 \mainfont{}etex;
drawoptions();
p_continuation((22.04,19.81),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
string ATTR_code;
ATTR_code := "E";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \char101 \char110 \ \char104 \char97 \char117 \char116 \char101 \char117 \char114 \mainfont{}etex;
drawoptions();
p_continuation((37.72,27.18),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-13.48,5.34)
 .. controls (-13.48,5.34) and (-10.96,5.21) .. (-14.64,1.00)
 .. controls (-18.32,-3.22) and (-19.52,-6.31) .. (-24.20,-6.41)
 .. controls (-28.89,-6.52) and (-36.65,-6.32) .. (-38.86,-4.57)
 .. controls (-41.06,-2.81) and (-43.28,-1.24) .. (-43.83,-0.89)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-6.92,-6.59)
 .. controls (-6.92,-6.59) and (-5.01,-7.39) .. (-4.44,-8.72)
 .. controls (-3.88,-10.04) and (5.74,-16.92) .. (0.67,-15.06)
 .. controls (-3.74,-13.44) and (-7.87,-12.00) .. (-8.63,-10.21)
 .. controls (-9.39,-8.43) and (-6.92,-6.59) .. cycle
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((0.03,-8.54)
 .. controls (0.03,-8.54) and (-7.13,-4.79) .. (-3.74,-4.00)
 .. controls (-0.34,-3.20) and (3.45,-2.93) .. (3.43,-1.49)
 .. controls (3.40,-0.05) and (3.69,2.84) .. (3.98,6.08)
 .. controls (4.27,9.33) and (4.16,14.37) .. (4.68,15.10)
 .. controls (5.21,15.83) and (6.24,17.65) .. (6.24,17.65)
));
drawoptions();
p_rope((27.71,23.71),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((41.38,16.62)
 .. controls (41.38,16.62) and (44.87,21.21) .. (46.68,20.90)
 .. controls (48.49,20.59) and (50.32,19.01) .. (51.36,20.67)
 .. controls (52.40,22.32) and (52.70,25.04) .. (53.36,27.41)
 .. controls (54.02,29.78) and (55.98,30.55) .. (60.47,30.69)
 .. controls (64.96,30.82) and (70.00,30.62) .. (70.00,30.62)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((69.95,32.79)
 .. controls (69.95,32.79) and (64.20,32.61) .. (60.43,32.50)
 .. controls (56.65,32.38) and (51.52,29.34) .. (51.55,27.90)
 .. controls (51.59,26.45) and (52.05,22.13) .. (49.71,22.06)
 .. controls (47.37,22.00) and (47.88,23.64) .. (45.74,22.50)
 .. controls (43.61,21.36) and (40.44,18.40) .. (40.44,18.40)
));
string ATTR_code;
ATTR_code := "D";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \thfc\char233 \thfb\char116 \char114 \char111 \char105 \char116 \mainfont{}etex;
drawoptions();
p_continuation((14.95,-22.40),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-42.77,-4.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-40.52,-7.09),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-34.12,-16.60),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-22.94,-12.61),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-10.39,-2.21),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((2.60,-0.01),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((2.69,15.03),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-9.45,-13.75),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((5.19,-17.77),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((2.49,-12.40),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((2.08,-8.98),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((0.71,-10.59),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((6.08,-2.15),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((19.21,5.32),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((23.98,7.02),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((25.99,9.39),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((33.81,13.84),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-45.75,-18.59),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-63.17,-24.85),1,0,"");
endfig;
beginfig(31);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char69 \char116 \char114 \char46 \mainfont{} etex,(68.19,38.15),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \char115 \ \char84 \char97 \char114 \thfc\char233 \mainfont{} etex,(38.47,1.64),36.1,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char52 \mainfont{} etex,(-35.06,3.07),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{\hfil#\hfil\cr\ \thfb\char76 \char101 \ \char82 \thfc\char233 \thfb\char115 \char101 \char97 \char117 \ \cr\thfb \ \char100 \char39 \char73 \char109 \char109 \char101 \char110 \char115 \char101 \char115 \ \char67 \char111 \char110 \char100 \char117 \char105 \char116 \char101 \char115 \ \cr\thfb \ \char70 \char111 \char114 \char99 \thfc\char233 \thfb\char101 \char115 \ .\cr}}\mainfont{} etex,(-8.37,-36.48),0.0,0);
drawoptions(withcolor (1.000000,0.500000,0.000000));
p_label(btex \thaltitude \thfb\char49 \char56 \char49 \char55 \mainfont{} etex,(54.35,15.89),0.0,1);
endfig;
current_scrap := "A21-1";
ATTR__scrap := "A21-1";
beginfig(32);
ATTR__height := -1;
drawoptions();
l_pit(((-2.56,50.19)
 .. controls (-2.56,50.19) and (-2.62,42.78) .. (-0.81,42.11)
 .. controls (1.01,41.45) and (3.20,40.08) .. (4.27,40.29)
 .. controls (5.34,40.51) and (4.90,43.56) .. (5.40,44.66)
 .. controls (5.90,45.75) and (10.68,48.07) .. (8.09,50.32)
 .. controls (5.50,52.58) and (4.08,51.63) .. (2.78,53.03)
 .. controls (1.48,54.43) and (-0.19,52.40) .. (-0.19,52.40)
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.86,-85.69) -- (7.23,-87.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((7.23,-87.29) -- (2.86,-85.69)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((7.23,-87.29) -- (13.49,-84.90)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((13.49,-84.90) -- (13.49,-84.90)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.42,-76.75) -- (16.48,-81.34)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.42,-76.75) -- (17.86,-75.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((16.48,-81.34) -- (13.49,-84.90)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((16.48,-81.34) -- (15.42,-76.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((17.86,-75.96) -- (15.42,-76.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((17.86,-75.96) -- (20.80,-71.44)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((20.80,-71.44) -- (17.86,-75.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((20.80,-71.44) -- (17.33,-67.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((17.33,-67.29) -- (20.80,-71.44)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((17.33,-67.29) -- (15.81,-64.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.81,-64.84) -- (17.33,-67.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.81,-64.84) -- (7.53,-57.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((7.53,-57.63) -- (15.81,-64.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((7.53,-57.63) -- (2.52,-57.45)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((4.51,-52.54) -- (2.52,-57.45)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((4.51,-52.54) -- (3.21,-51.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.52,-57.45) -- (7.53,-57.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.52,-57.45) -- (4.51,-52.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((3.21,-51.04) -- (4.51,-52.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((3.21,-51.04) -- (-4.50,-42.14)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-4.50,-42.14) -- (3.21,-51.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-4.50,-42.14) -- (-3.01,-38.48)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-3.01,-38.48) -- (-4.50,-42.14)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-3.01,-38.48) -- (-6.22,-29.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-6.22,-29.62) -- (-3.01,-38.48)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-6.22,-29.62) -- (-11.84,-19.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-11.84,-19.03) -- (-6.22,-29.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-11.84,-19.03) -- (-19.07,-13.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-19.07,-13.56) -- (-11.84,-19.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-19.07,-13.56) -- (-20.08,-8.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-20.08,-8.77) -- (-19.07,-13.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-20.08,-8.77) -- (-22.87,-9.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-22.87,-9.95) -- (-20.08,-8.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-22.87,-9.95) -- (-21.11,-5.59)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-21.11,-5.59) -- (-22.87,-9.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-21.11,-5.59) -- (-27.11,-1.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-27.11,-1.97) -- (-21.11,-5.59)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-27.11,-1.97) -- (-26.53,4.59)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-26.53,4.59) -- (-27.11,-1.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-26.53,4.59) -- (-22.81,8.86)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-22.81,8.86) -- (-26.53,4.59)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-22.81,8.86) -- (-20.74,6.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-20.74,6.11) -- (-22.81,8.86)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-20.74,6.11) -- (-14.66,12.17)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-14.66,12.17) -- (-20.74,6.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-14.66,12.17) -- (-11.58,6.36)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-11.58,6.36) -- (-14.66,12.17)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-11.58,6.36) -- (-7.67,6.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-7.67,6.22) -- (-11.58,6.36)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-7.67,6.22) -- (-5.06,9.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-5.06,9.11) -- (-7.67,6.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-5.06,9.11) -- (-0.16,7.12)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-0.16,7.12) -- (-5.06,9.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-0.16,7.12) -- (2.37,9.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.37,9.47) -- (-0.16,7.12)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.37,9.47) -- (6.54,8.88)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((6.54,8.88) -- (2.37,9.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((6.54,8.88) -- (11.27,6.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((11.27,6.03) -- (6.54,8.88)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((11.27,6.03) -- (16.43,3.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((16.43,3.39) -- (11.27,6.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((16.43,3.39) -- (21.57,4.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((21.57,4.01) -- (16.43,3.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((21.57,4.01) -- (26.46,7.55)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((26.46,7.55) -- (21.57,4.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((26.46,7.55) -- (23.56,12.79)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((23.56,12.79) -- (26.46,7.55)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((23.56,12.79) -- (23.32,17.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((23.32,17.47) -- (23.56,12.79)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((23.32,17.47) -- (19.86,17.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((19.86,17.60) -- (23.32,17.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((19.86,17.60) -- (17.12,19.45)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((17.12,19.45) -- (19.86,17.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((17.12,19.45) -- (13.84,26.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((13.84,26.52) -- (17.12,19.45)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((13.84,26.52) -- (8.13,36.05)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((8.13,36.05) -- (13.84,26.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((8.13,36.05) -- (2.03,50.48)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.03,50.48) -- (2.97,45.91)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.03,50.48) -- (0.06,55.87)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.03,50.48) -- (8.13,36.05)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.03,50.48) -- (-0.25,55.99)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((0.06,55.87) -- (2.03,50.48)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((0.06,55.87) -- (0.30,59.25)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((0.30,59.25) -- (0.06,55.87)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((0.30,59.25) -- (-2.44,81.41)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((0.20,63.10) -- (-0.25,55.99)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((0.20,63.10) -- (0.17,63.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2.44,81.41) -- (0.30,59.25)));
endfig;
beginfig(33);
draw_upscrap(1)(1,((0.21,-85.55)
 .. controls (0.21,-85.55) and (5.21,-89.71) .. (6.99,-89.11)
 .. controls (8.77,-88.51) and (12.72,-88.19) .. (14.10,-86.17)
 .. controls (15.47,-84.14) and (17.46,-83.84) .. (17.36,-81.56)
 .. controls (17.27,-79.28) and (14.89,-77.50) .. (16.33,-77.45)
 .. controls (17.76,-77.40) and (19.18,-76.62) .. (19.18,-76.62)
 .. controls (19.18,-76.62) and (22.63,-72.19) .. (21.88,-71.31)
 .. controls (21.13,-70.44) and (19.61,-67.98) .. (18.10,-66.22)
 .. controls (17.35,-65.34) and (18.43,-65.13) .. (16.40,-63.75)
 .. controls (14.37,-62.38) and (9.84,-56.23) .. (7.87,-56.48)
 .. controls (5.90,-56.73) and (2.71,-58.46) .. (3.56,-56.99)
 .. controls (4.41,-55.52) and (7.22,-53.45) .. (5.55,-51.88)
 .. controls (3.88,-50.31) and (-4.08,-43.91) .. (-3.25,-41.90)
 .. controls (-2.41,-39.90) and (-1.46,-41.30) .. (-1.92,-38.44)
 .. controls (-2.38,-35.57) and (-4.16,-31.13) .. (-5.31,-28.83)
 .. controls (-6.47,-26.53) and (-9.61,-18.89) .. (-10.71,-18.39)
 .. controls (-11.80,-17.88) and (-17.02,-15.66) .. (-18.09,-13.05)
 .. controls (-19.17,-10.45) and (-17.79,-8.33) .. (-19.35,-7.87)
 .. controls (-20.44,-7.55) and (-22.54,-9.24) .. (-21.67,-8.31)
 .. controls (-20.80,-7.38) and (-18.00,-5.12) .. (-19.99,-4.65)
 .. controls (-21.99,-4.18) and (-26.19,-2.52) .. (-26.23,-1.26)
 .. controls (-26.27,0.00) and (-27.36,2.58) .. (-25.69,3.98)
 .. controls (-24.02,5.38) and (-23.86,8.55) .. (-23.11,7.49)
 .. controls (-22.35,6.44) and (-21.72,3.94) .. (-20.32,5.06)
 .. controls (-18.92,6.19) and (-14.99,12.27) .. (-14.58,10.84)
 .. controls (-14.17,9.42) and (-13.66,5.11) .. (-11.86,5.17)
 .. controls (-10.06,5.23) and (-7.51,4.24) .. (-7.00,5.16)
 .. controls (-6.49,6.07) and (-6.22,8.78) .. (-4.76,8.11)
 .. controls (-3.29,7.44) and (-1.25,5.71) .. (-0.00,6.11)
 .. controls (1.24,6.51) and (1.17,8.67) .. (2.79,8.55)
 .. controls (4.42,8.42) and (3.99,9.52) .. (5.87,8.11)
 .. controls (7.75,6.70) and (8.65,5.68) .. (11.20,4.87)
 .. controls (13.75,4.05) and (14.36,2.09) .. (16.87,2.36)
 .. controls (19.38,2.62) and (20.85,1.77) .. (22.60,3.27)
 .. controls (24.35,4.77) and (28.98,6.37) .. (27.86,7.59)
 .. controls (26.74,8.82) and (23.99,10.82) .. (24.62,12.89)
 .. controls (25.24,14.95) and (25.92,16.89) .. (24.26,18.10)
 .. controls (22.60,19.30) and (21.21,17.81) .. (19.91,18.85)
 .. controls (18.62,19.89) and (18.26,19.87) .. (17.30,21.64)
 .. controls (16.34,23.41) and (17.20,24.70) .. (15.12,27.52)
 .. controls (13.05,30.33) and (10.43,33.12) .. (9.63,35.43)
 .. controls (8.83,37.74) and (3.47,43.33) .. (5.40,44.66)
 .. controls (7.33,45.98) and (10.86,48.25) .. (8.09,50.32)
 .. controls (5.32,52.39) and (3.54,51.44) .. (2.78,53.03)
 .. controls (2.02,54.63) and (1.29,54.61) .. (1.60,56.23)
 .. controls (1.91,57.87) and (1.93,57.69) .. (1.85,59.67)
 .. controls (1.77,61.66) and (1.94,61.31) .. (2.41,63.13)
 .. controls (2.88,64.95) and (0.94,79.80) .. (2.70,81.29)
 .. controls (4.46,82.78) and (6.39,83.92) .. (6.39,83.92)
),
0,((6.39,83.92)
 .. controls (6.39,83.92) and (-2.45,85.30) .. (-6.38,83.92)
 .. controls (-10.30,82.55) and (-11.36,81.44) .. (-11.36,81.44)
),
1,((-11.36,81.44)
 .. controls (-11.36,81.44) and (-10.30,82.37) .. (-8.23,79.19)
 .. controls (-6.15,76.01) and (-2.12,65.85) .. (-2.05,63.14)
 .. controls (-1.97,60.44) and (-1.41,60.46) .. (-1.35,58.66)
 .. controls (-1.29,56.87) and (-0.19,52.40) .. (-0.19,52.40)
 -- (-2.43,52.69)
),
1,((-2.56,50.19)
 .. controls (-2.56,50.19) and (-3.36,43.65) .. (-0.81,42.11)
 .. controls (1.75,40.57) and (2.46,40.96) .. (4.27,40.29)
 .. controls (6.08,39.63) and (5.79,37.28) .. (7.12,35.17)
 .. controls (8.45,33.05) and (10.93,28.99) .. (12.65,25.99)
 .. controls (14.37,22.99) and (14.81,21.86) .. (17.12,19.45)
 .. controls (19.44,17.03) and (19.09,16.48) .. (20.53,16.53)
 .. controls (21.97,16.58) and (23.55,17.71) .. (23.43,16.09)
 .. controls (23.30,14.46) and (20.97,14.20) .. (22.47,12.46)
 .. controls (23.97,10.71) and (26.20,8.80) .. (24.96,8.04)
 .. controls (23.73,7.27) and (22.70,5.62) .. (20.92,5.02)
 .. controls (19.14,4.42) and (18.98,3.87) .. (16.44,4.50)
 .. controls (13.89,5.14) and (14.04,6.05) .. (11.67,7.05)
 .. controls (9.29,8.05) and (7.79,9.79) .. (5.81,9.91)
 .. controls (3.82,10.02) and (2.79,11.82) .. (1.29,10.48)
 .. controls (0.24,9.54) and (0.11,7.92) .. (-0.98,8.42)
 .. controls (-2.08,8.92) and (-3.97,11.38) .. (-5.37,10.25)
 .. controls (-6.77,9.12) and (-6.89,7.32) .. (-8.15,7.28)
 .. controls (-9.41,7.24) and (-10.63,6.11) .. (-11.04,7.36)
 .. controls (-11.44,8.61) and (-12.70,13.97) .. (-14.31,13.55)
 .. controls (-15.92,13.14) and (-19.85,7.06) .. (-20.77,7.57)
 .. controls (-21.69,8.08) and (-22.19,12.21) .. (-23.21,10.37)
 .. controls (-24.22,8.53) and (-28.01,8.59) .. (-27.90,5.35)
 .. controls (-27.79,2.11) and (-29.17,0.30) .. (-27.80,-2.75)
 .. controls (-26.43,-5.81) and (-22.15,-4.72) .. (-22.28,-6.17)
 .. controls (-22.41,-7.61) and (-25.59,-9.53) .. (-24.12,-10.38)
 .. controls (-22.65,-11.23) and (-20.41,-8.45) .. (-20.34,-10.42)
 .. controls (-20.28,-12.41) and (-22.04,-13.55) .. (-20.20,-14.57)
 .. controls (-18.37,-15.59) and (-14.34,-17.43) .. (-12.81,-20.08)
 .. controls (-11.28,-22.73) and (-8.40,-28.03) .. (-7.24,-30.33)
 .. controls (-6.08,-32.64) and (-4.00,-35.63) .. (-4.27,-38.16)
 .. controls (-4.55,-40.69) and (-7.45,-40.06) .. (-5.75,-42.53)
 .. controls (-4.05,-44.99) and (2.47,-51.08) .. (2.70,-52.69)
 .. controls (2.93,-54.31) and (0.08,-55.12) .. (1.42,-57.42)
 .. controls (2.76,-59.71) and (5.04,-58.02) .. (6.88,-59.03)
 .. controls (8.71,-60.05) and (13.17,-64.04) .. (15.03,-65.96)
 .. controls (16.90,-67.88) and (20.01,-69.40) .. (19.71,-71.03)
 .. controls (19.40,-72.66) and (18.38,-74.49) .. (17.14,-74.90)
 .. controls (15.89,-75.30) and (13.69,-74.12) .. (14.32,-76.62)
 .. controls (14.94,-79.12) and (15.89,-80.52) .. (15.20,-81.63)
 .. controls (14.52,-82.73) and (14.70,-82.72) .. (12.58,-84.06)
 .. controls (10.47,-85.39) and (9.59,-85.96) .. (7.61,-86.03)
 .. controls (5.63,-86.09) and (2.50,-84.04) .. (2.50,-84.04)
));
draw_downscrap;
endfig;
beginfig(34);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((0.21,-85.55)
 .. controls (0.21,-85.55) and (5.21,-89.71) .. (6.99,-89.11)
 .. controls (8.77,-88.51) and (12.72,-88.19) .. (14.10,-86.17)
 .. controls (15.47,-84.14) and (17.46,-83.84) .. (17.36,-81.56)
 .. controls (17.27,-79.28) and (14.89,-77.50) .. (16.33,-77.45)
 .. controls (17.76,-77.40) and (19.18,-76.62) .. (19.18,-76.62)
 .. controls (19.18,-76.62) and (22.63,-72.19) .. (21.88,-71.31)
 .. controls (21.13,-70.44) and (19.61,-67.98) .. (18.10,-66.22)
 .. controls (17.35,-65.34) and (18.43,-65.13) .. (16.40,-63.75)
 .. controls (14.37,-62.38) and (9.84,-56.23) .. (7.87,-56.48)
 .. controls (5.90,-56.73) and (2.71,-58.46) .. (3.56,-56.99)
 .. controls (4.41,-55.52) and (7.22,-53.45) .. (5.55,-51.88)
 .. controls (3.88,-50.31) and (-4.08,-43.91) .. (-3.25,-41.90)
 .. controls (-2.41,-39.90) and (-1.46,-41.30) .. (-1.92,-38.44)
 .. controls (-2.38,-35.57) and (-4.16,-31.13) .. (-5.31,-28.83)
 .. controls (-6.47,-26.53) and (-9.61,-18.89) .. (-10.71,-18.39)
 .. controls (-11.80,-17.88) and (-17.02,-15.66) .. (-18.09,-13.05)
 .. controls (-19.17,-10.45) and (-17.79,-8.33) .. (-19.35,-7.87)
 .. controls (-20.44,-7.55) and (-22.54,-9.24) .. (-21.67,-8.31)
 .. controls (-20.80,-7.38) and (-18.00,-5.12) .. (-19.99,-4.65)
 .. controls (-21.99,-4.18) and (-26.19,-2.52) .. (-26.23,-1.26)
 .. controls (-26.27,0.00) and (-27.36,2.58) .. (-25.69,3.98)
 .. controls (-24.02,5.38) and (-23.86,8.55) .. (-23.11,7.49)
 .. controls (-22.35,6.44) and (-21.72,3.94) .. (-20.32,5.06)
 .. controls (-18.92,6.19) and (-14.99,12.27) .. (-14.58,10.84)
 .. controls (-14.17,9.42) and (-13.66,5.11) .. (-11.86,5.17)
 .. controls (-10.06,5.23) and (-7.51,4.24) .. (-7.00,5.16)
 .. controls (-6.49,6.07) and (-6.22,8.78) .. (-4.76,8.11)
 .. controls (-3.29,7.44) and (-1.25,5.71) .. (-0.00,6.11)
 .. controls (1.24,6.51) and (1.17,8.67) .. (2.79,8.55)
 .. controls (4.42,8.42) and (3.99,9.52) .. (5.87,8.11)
 .. controls (7.75,6.70) and (8.65,5.68) .. (11.20,4.87)
 .. controls (13.75,4.05) and (14.36,2.09) .. (16.87,2.36)
 .. controls (19.38,2.62) and (20.85,1.77) .. (22.60,3.27)
 .. controls (24.35,4.77) and (28.98,6.37) .. (27.86,7.59)
 .. controls (26.74,8.82) and (23.99,10.82) .. (24.62,12.89)
 .. controls (25.24,14.95) and (25.92,16.89) .. (24.26,18.10)
 .. controls (22.60,19.30) and (21.21,17.81) .. (19.91,18.85)
 .. controls (18.62,19.89) and (18.26,19.87) .. (17.30,21.64)
 .. controls (16.34,23.41) and (17.20,24.70) .. (15.12,27.52)
 .. controls (13.05,30.33) and (10.43,33.12) .. (9.63,35.43)
 .. controls (8.83,37.74) and (3.47,43.33) .. (5.40,44.66)
 .. controls (7.33,45.98) and (10.86,48.25) .. (8.09,50.32)
 .. controls (5.32,52.39) and (3.54,51.44) .. (2.78,53.03)
 .. controls (2.02,54.63) and (1.29,54.61) .. (1.60,56.23)
 .. controls (1.91,57.87) and (1.93,57.69) .. (1.85,59.67)
 .. controls (1.77,61.66) and (1.94,61.31) .. (2.41,63.13)
 .. controls (2.88,64.95) and (0.94,79.80) .. (2.70,81.29)
 .. controls (4.46,82.78) and (6.39,83.92) .. (6.39,83.92)
));
drawoptions();
p_rope((7.92,56.45),0.0,1.00,(0,0));
drawoptions();
p_airdraught_winter((6.07,75.82),185.1,1.00,(0,0));
drawoptions();
p_airdraught_summer((-9.84,71.55),206.8,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-11.36,81.44)
 .. controls (-11.36,81.44) and (-10.30,82.37) .. (-8.23,79.19)
 .. controls (-6.15,76.01) and (-2.12,65.85) .. (-2.05,63.14)
 .. controls (-1.97,60.44) and (-1.41,60.46) .. (-1.35,58.66)
 .. controls (-1.29,56.87) and (-0.19,52.40) .. (-0.19,52.40)
 -- (-2.43,52.69)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2.56,50.19)
 .. controls (-2.56,50.19) and (-3.36,43.65) .. (-0.81,42.11)
 .. controls (1.75,40.57) and (2.46,40.96) .. (4.27,40.29)
 .. controls (6.08,39.63) and (5.79,37.28) .. (7.12,35.17)
 .. controls (8.45,33.05) and (10.93,28.99) .. (12.65,25.99)
 .. controls (14.37,22.99) and (14.81,21.86) .. (17.12,19.45)
 .. controls (19.44,17.03) and (19.09,16.48) .. (20.53,16.53)
 .. controls (21.97,16.58) and (23.55,17.71) .. (23.43,16.09)
 .. controls (23.30,14.46) and (20.97,14.20) .. (22.47,12.46)
 .. controls (23.97,10.71) and (26.20,8.80) .. (24.96,8.04)
 .. controls (23.73,7.27) and (22.70,5.62) .. (20.92,5.02)
 .. controls (19.14,4.42) and (18.98,3.87) .. (16.44,4.50)
 .. controls (13.89,5.14) and (14.04,6.05) .. (11.67,7.05)
 .. controls (9.29,8.05) and (7.79,9.79) .. (5.81,9.91)
 .. controls (3.82,10.02) and (2.79,11.82) .. (1.29,10.48)
 .. controls (0.24,9.54) and (0.11,7.92) .. (-0.98,8.42)
 .. controls (-2.08,8.92) and (-3.97,11.38) .. (-5.37,10.25)
 .. controls (-6.77,9.12) and (-6.89,7.32) .. (-8.15,7.28)
 .. controls (-9.41,7.24) and (-10.63,6.11) .. (-11.04,7.36)
 .. controls (-11.44,8.61) and (-12.70,13.97) .. (-14.31,13.55)
 .. controls (-15.92,13.14) and (-19.85,7.06) .. (-20.77,7.57)
 .. controls (-21.69,8.08) and (-22.19,12.21) .. (-23.21,10.37)
 .. controls (-24.22,8.53) and (-28.01,8.59) .. (-27.90,5.35)
 .. controls (-27.79,2.11) and (-29.17,0.30) .. (-27.80,-2.75)
 .. controls (-26.43,-5.81) and (-22.15,-4.72) .. (-22.28,-6.17)
 .. controls (-22.41,-7.61) and (-25.59,-9.53) .. (-24.12,-10.38)
 .. controls (-22.65,-11.23) and (-20.41,-8.45) .. (-20.34,-10.42)
 .. controls (-20.28,-12.41) and (-22.04,-13.55) .. (-20.20,-14.57)
 .. controls (-18.37,-15.59) and (-14.34,-17.43) .. (-12.81,-20.08)
 .. controls (-11.28,-22.73) and (-8.40,-28.03) .. (-7.24,-30.33)
 .. controls (-6.08,-32.64) and (-4.00,-35.63) .. (-4.27,-38.16)
 .. controls (-4.55,-40.69) and (-7.45,-40.06) .. (-5.75,-42.53)
 .. controls (-4.05,-44.99) and (2.47,-51.08) .. (2.70,-52.69)
 .. controls (2.93,-54.31) and (0.08,-55.12) .. (1.42,-57.42)
 .. controls (2.76,-59.71) and (5.04,-58.02) .. (6.88,-59.03)
 .. controls (8.71,-60.05) and (13.17,-64.04) .. (15.03,-65.96)
 .. controls (16.90,-67.88) and (20.01,-69.40) .. (19.71,-71.03)
 .. controls (19.40,-72.66) and (18.38,-74.49) .. (17.14,-74.90)
 .. controls (15.89,-75.30) and (13.69,-74.12) .. (14.32,-76.62)
 .. controls (14.94,-79.12) and (15.89,-80.52) .. (15.20,-81.63)
 .. controls (14.52,-82.73) and (14.70,-82.72) .. (12.58,-84.06)
 .. controls (10.47,-85.39) and (9.59,-85.96) .. (7.61,-86.03)
 .. controls (5.63,-86.09) and (2.50,-84.04) .. (2.50,-84.04)
));
string ATTR_code;
ATTR_code := "D";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char77 \thfc\char233 \thfb\char97 \char110 \char100 \char114 \char101 \ \thfc\char233 \thfb\char116 \char114 \char111 \char105 \char116 \ \thfc\char184 \ \thfb\char100 \thfc\char233 \thfb\char115 \char111 \char98 \char115 \char116 \char114 \char117 \char101 \char114 \mainfont{}etex;
drawoptions();
p_continuation((-6.89,-77.69),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
drawoptions();
p_narrowend((-1.71,-81.84),229.0,1.00,(0,0));
drawoptions();
p_entrance((-2.89,88.16),186.7,1.00,(0,0));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-2.44,81.41),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((0.20,63.10),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((0.30,59.25),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((0.06,55.87),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((2.03,50.48),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((8.13,36.05),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((13.84,26.52),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((17.12,19.45),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((19.86,17.60),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((23.32,17.47),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((23.56,12.79),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((26.46,7.55),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((21.57,4.01),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((16.43,3.39),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((11.27,6.03),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((6.54,8.88),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((2.37,9.47),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-0.16,7.12),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-5.06,9.11),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-7.67,6.22),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-11.58,6.36),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-14.66,12.17),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-20.74,6.11),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-22.81,8.86),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-26.53,4.59),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-27.11,-1.97),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-21.11,-5.59),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-22.87,-9.95),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-20.08,-8.77),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-19.07,-13.56),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-11.84,-19.03),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-6.22,-29.62),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-3.01,-38.48),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((-4.50,-42.14),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((3.21,-51.04),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((2.52,-57.45),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((4.51,-52.54),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((7.53,-57.63),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((15.81,-64.84),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((17.33,-67.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((20.80,-71.44),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((17.86,-75.96),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((16.48,-81.34),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((15.42,-76.75),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((13.49,-84.90),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((7.23,-87.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station((2.86,-85.69),1,0,"");
endfig;
beginfig(35);
drawoptions(withcolor (1.000000,0.500000,0.000000));
p_label(btex \thaltitude \thfb\char49 \char56 \char53 \char57 \mainfont{} etex,(14.61,83.30),0.0,1);
drawoptions(withcolor (1.000000,0.500000,0.000000));
p_label(btex \thaltitude \thfb\char49 \char56 \char51 \char51 \mainfont{} etex,(4.25,-98.74),0.0,1);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char51 \char52 \mainfont{} etex,(17.12,49.37),0.0,7);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char69 \char116 \char114 \char46 \mainfont{} etex,(-7.34,-91.38),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char77 \thfc\char233 \thfb\char97 \char110 \char100 \char114 \char101 \ \char83 \char117 \char112 \thfc\char233 \thfb\char114 \char105 \char101 \char117 \char114 \mainfont{} etex,(18.81,-28.20),305.5,0);
drawoptions();
p_label(btex \thlabel\thhugesize \thfb\char65 \char50 \char49 \char45 \char86 \char50 \char49 \mainfont{} etex,(-4.50,98.73),0.0,0);
endfig;
beginfig(36);
s_northarrow(0);
endfig;
beginfig(37);
s_scalebar(100, 1, "\thfb\char109 \mainfont{}");
endfig;
Scale:=10.00;
initialize(Scale);
background:=(1.00000,1.00000,0.80000);
transparency:=false;
beginfig(38);
clean_legend_box;
drawoptions(withcolor (0.540000,0.070000,0.600000));
p_station_temporary((0.5,0.5) inscale);
draw_legend_box;
endfig;
beginfig(39);
clean_legend_box;
drawoptions();
l_survey_cave(((-1,1) -- (0.8,0.6) -- (0,-1)) inscale);
drawoptions(withcolor HelpSymbolColor);
p_station_temporary((0.8,0.6) inscale);
drawoptions();
draw_legend_box;
endfig;
beginfig(40);
clean_legend_box;
drawoptions();
p_entrance((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(41);
clean_legend_box;
drawoptions();
l_wall_bedrock(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(42);
clean_legend_box;
drawoptions();
l_wall_unsurveyed(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(43);
clean_legend_box;
drawoptions();
l_wall_presumed(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(44);
clean_legend_box;
drawoptions(withcolor (1.000000,0.500000,0.000000));
p_label.rt(btex \thaltitude \thfb\char49 \char53 \char49 \char48 \mainfont{} etex,((0.3,0.5) inscale),0,1);
draw_legend_box;
endfig;
beginfig(45);
clean_legend_box;
drawoptions();
p_airdraught_winter((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(46);
clean_legend_box;
drawoptions();
p_airdraught_summer((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(47);
clean_legend_box;
drawoptions();
p_dig((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(48);
clean_legend_box;
drawoptions(withcolor HelpSymbolColor);
l_wall_bedrock(((0,.2){dir 30} .. {dir 0}(.5,.4)) inscale);
l_wall_bedrock(((.5,.6){dir 180} .. {dir 210}(0,.8)) inscale);
drawoptions();
drawoptions();
p_continuation((.6,.5) inscale,270.0,1.0,(0,1));
draw_legend_box;
endfig;
beginfig(49);
clean_legend_box;
drawoptions(withcolor HelpSymbolColor);
l_wall_bedrock(((0,.2){dir 30} .. {dir 0}(.5,.4)) inscale);
l_wall_bedrock(((.5,.6){dir 180} .. {dir 210}(0,.8)) inscale);
drawoptions();
drawoptions();
p_narrowend((.6,.5) inscale,270.0,1.0,(0,1));
draw_legend_box;
endfig;
beginfig(50);
clean_legend_box;
drawoptions(withcolor HelpSymbolColor);
l_wall_bedrock(((0,.2){dir 30} .. {dir 0}(.5,.4)) inscale);
l_wall_bedrock(((.5,.6){dir 180} .. {dir 210}(0,.8)) inscale);
drawoptions();
drawoptions();
p_breakdownchoke((.6,.5) inscale,270.0,1.0,(0,1));
draw_legend_box;
endfig;
beginfig(51);
clean_legend_box;
drawoptions();
l_overhang((((.1,.6) .. (.5,.4) .. (.9,.6)) inscale));
draw_legend_box;
endfig;
beginfig(52);
clean_legend_box;
drawoptions();
l_floormeander((((.1,.6) .. (.5,.4) .. (.9,.6)) inscale));
draw_legend_box;
endfig;
beginfig(53);
clean_legend_box;
drawoptions();
l_pit((((.85,.5){dir 90} .. (.5,.85){dir 180} .. (.4,.15){dir 0} .. cycle) inscale));
draw_legend_box;
endfig;
beginfig(54);
clean_legend_box;
drawoptions();
l_chimney((((.85,.5){dir 90} .. (.5,.85){dir 180} .. (.4,.15){dir 0} .. cycle) inscale));
draw_legend_box;
endfig;
beginfig(55);
clean_legend_box;
drawoptions();
l_gradient(((0.2,0.5) -- (0.8,0.5)) inscale);
draw_legend_box;
endfig;
beginfig(56);
clean_legend_box;
drawoptions(withcolor HelpSymbolColor);
l_chimney((((.5,.5){dir 90} .. (.3,.75){dir 180} .. (.15,.5) .. (.2,.25){dir 0} .. cycle) inscale));
drawoptions();
drawoptions();
p_label.rt(btex \thheightpos \thfb\char49 \char53 \mainfont{} etex,((0.5,0.5) inscale),0,7);
draw_legend_box;
endfig;
beginfig(57);
clean_legend_box;
drawoptions(withcolor HelpSymbolColor);
l_pit((((.5,.5){dir 90} .. (.3,.75){dir 180} .. (.15,.5) .. (.2,.25){dir 0} .. cycle) inscale));
drawoptions();
drawoptions();
p_label.rt(btex \thheightneg \thfb\char51 \char48 \mainfont{} etex,((0.5,0.5) inscale),0,7);
draw_legend_box;
endfig;
beginfig(58);
clean_legend_box;
drawoptions();
l_contour((((.1,.6) .. (.5,.4) .. (.9,.6)) inscale),-1);
draw_legend_box;
endfig;
beginfig(59);
clean_legend_box;
drawoptions();
p_blocks((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(60);
clean_legend_box;
drawoptions();
p_pebbles((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(61);
clean_legend_box;
drawoptions();
p_crystal((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(62);
clean_legend_box;
drawoptions();
p_archeomaterial((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(63);
clean_legend_box;
drawoptions();
p_rope((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
end;
