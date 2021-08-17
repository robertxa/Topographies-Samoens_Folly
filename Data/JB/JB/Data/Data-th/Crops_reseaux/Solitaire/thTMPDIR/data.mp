Scale:=10.00;
MagDecl:=0.00;
GridConv:=0.00;
string OutputColormodel;
OutputColormodel:="cmyk";
BaseScale:=10.00;
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

if unknown mpversion: string mpversion; mpversion := "0.0"; fi
if scantokens(mpversion) < 1.0:
  errmessage "MetaPost 1.0 or later required";
fi

tracingstats:=1;
prologues:=0;

% Set the random seed to a fixed value so therion reproducibly produces the
% same output for a given input.
randomseed:=42;

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
% no effect, when it is true, it suppresses all drawing
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

save black, white, red, green, blue, background, HelpSymbolColor, tmpcol;
if OutputColormodel = "cmyk":
  cmykcolor black, white, red, green, blue, background, HelpSymbolColor, tmpcol;
  black := (0,0,0,1);
  white := (0,0,0,0);
  red   := (0,0.9,0.9,0.2);
  green := (0.7,0,0.8,0.4);
  blue  := (0.6,0.4,0,0.1);
  HelpSymbolColor := (0,0,0,0.2);
  defaultcolormodel := 7;
elseif OutputColormodel = "rgb":
  rgbcolor black, white, red, green, blue, background, HelpSymbolColor, tmpcol;
  black := (0,0,0);
  white := (1,1,1);
  red   := (1,0,0);
  green := (0,1,0);
  blue  := (0,0,1);
  HelpSymbolColor := (0.8,0.8,0.8);
  defaultcolormodel := 5;
else:
  black := 0;
  white := 1;
  red   := 0.3;
  green := 0.59;
  blue  := 0.11;
  HelpSymbolColor := 0.8;
  defaultcolormodel := 3;
fi;
background = white;

string includeprefix;
includeprefix = ".";
def inputrel(expr p) =
  scantokens("input " & includeprefix & p);
enddef;

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
% draws a label split into down and up oriented semicircular boxes and
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
  begingroup;
    interim bboxmargin:=1.0bp;
    q:=bbox lab;
    draw lab;
    draw q;
    write_bbox(q);
  endgroup;
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
    thfill c withcolor background withalpha -1
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
% We can't use one file for both, while PDF XObject has to be explicitly
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
      if drawnext: draw i withpen PenD withoutcolor; fi;
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
  addto bgfill contour q withoutcolor;
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

vardef tightbbox primary p =
  llcorner p -- lrcorner p -- urcorner p -- ulcorner p -- cycle
enddef;

% https://tug.org/pipermail/metapost/2008-February/001218.html
vardef log primary x =
     (if x=0: 0 else: mlog(x)/mlog(10) fi)
enddef;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% P. Bolek's MPATTERN package adapted and simplified for Therion
% (with the same user interface except of patterncolor)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

string Pname_, PXYsteps_;
string Pmatrix_;

numeric Pnum_; Pnum_=0;
string Psuffix_; Psuffix_="-patt";

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
  write Pname_ & ":"
    & jobname & Psuffix_ & "." & decimal charcode & ":"
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
  outputtemplate := "%j"&Psuffix_&".%c";
  beginfig(Pnum_);
enddef;

def endpattern=
  if unknown PBBox_:
     Pfindbounds_;
  fi;
  endfig;
  Psteps_;
  PmakePattern_(Pname_);
  scantokens("string " & Pname_ & "; "&Pname_&"="&ditto&Pname_&ditto&";");
  outputtemplate := "%j.%c";
enddef;

picture pattpict;
string patterncolor_;
patterncolor_ := "0 0 0 1";

vardef colortostr(expr c, s) =
  hide(pattpict := image(draw (0,0)--(10,10) withcolor c);
    for i within pattpict:
      if colormodel i = 1:
        patterncolor_ := decimal greypart i;
      elseif colormodel i = 5:
        patterncolor_ := decimal redpart i & s & decimal greenpart i & s & decimal bluepart i;
      elseif colormodel i = 7:
        patterncolor_ := decimal cyanpart i & s & decimal magentapart i & s & decimal yellowpart i & s & decimal blackpart i;
      fi
    endfor;)
  patterncolor_
enddef;

primarydef p withpattern s=
  if known s:
    p
    hide(pattpict := image(draw (0,0)--(10,10));
      for i within pattpict:
        if colormodel i = 1:
          patterncolor_ := decimal greypart i;
        elseif colormodel i = 5:
          patterncolor_ := decimal redpart i & " " & decimal greenpart i & " " & decimal bluepart i;
        elseif colormodel i = 7:
          patterncolor_ := decimal cyanpart i & " " & decimal magentapart i & " " & decimal yellowpart i & " " & decimal blackpart i;
        fi
      endfor;)
    withprescript(" " & s & " THsetpattern")
    withprescript(" " & patterncolor_ & " THsetpatterncolor")
    withoutcolor
  else:
    p withcolor red;
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

% transparent colors

primarydef p withalpha t =
    p withprescript(decimal t & " THsetalpha")
enddef;

def withlinearshading (expr p, n, ca, cb) =
    withprescript("L " &
                  decimal xpart point n of tightbbox p & " " &
                  decimal ypart point n of tightbbox p & " " &
                  decimal xpart point ((n+2) mod 4) of tightbbox  p & " " &
                  decimal ypart point ((n+2) mod 4) of tightbbox  p & " " &
                  colortostr(ca, " ") & " " &
                  colortostr(cb, " ") & " " &
                  "THgradient") withoutcolor
enddef;

def withradialshading (expr p, ca, cb) =
    withprescript("R " &
                  decimal xpart center p & " " &
                  decimal ypart center p & " " &
                  decimal xpart center p & " " &
                  decimal ypart center p & " " &
                  colortostr(ca, " ") & " " &
                  colortostr(cb, " ") & " " &
                  "0 " &
                  decimal (((xpart lrcorner p - xpart llcorner p) ++ (ypart urcorner p - ypart lrcorner p)) / 2) & " " &
                  "THgradient") withoutcolor
enddef;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% some useful macros from H. Hagen's MetaFun package (adapted)
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
    U:=(.5u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.3u){dir -85}..{dir 85}(-.32u,-.3u)..(-.28u,.3u){dir 85}..
        {dir -85}(-.12u,.3u)..(-.08u,-.3u){dir-85}..{dir 85}(.08u,-.3u)..
        {dir85}(.12u,.3u)..(.28u,.3u){dir -85}..(.32u,-.3u){dir -85}..
        {dir 85}(.5u,-.3u);
enddef;

def p_karren_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.4u,-.2u)--(-.3u,-.3u)--(0,.3u)--(.1u,.2u);
    thdraw p;
    thdraw p shifted (.3u,0);
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
  T:=identity aligned al rotated theta scaled sc shifted pos;
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
%      thfill fullcircle scaled 1 cm withcolor blue withalpha 0.5;
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

vardef polyline_offset(expr p, amount, direction) =
  % direction should be 90 or -90
  save P;
  path P,R;
  P = punked p;   % convert to polyline
  pair za, zb;
  for i=0 upto length P:
    if i > 0:
      za := unitvector(point i of P - point i-1 of P);      % direction of the previous segment
    else:                       % the first segment
      if cycle P:
        za := unitvector(point length P of P - point (length P)-1 of P);
      else:
        za := unitvector(point 1 of P - point 0 of P);    % za == zb
      fi;
    fi;
    if i < length P:
      zb := unitvector(point i+1 of P - point i of P);    % direction of the next segment
    else:                       % the last segment
      if cycle P:
        % zb is unused as the path is closed by "-- cycle"
      else:
        zb := za;
      fi;
    fi;
    A := 180-(angle(za)-angle(zb));
    R := if i>0: R -- fi
         if (i=length P) and cycle P: cycle else:
         point i of P + amount*unitvector(((za+zb)/2) rotated direction)/abs(sind(A/2)) fi;
  endfor;
  R
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
    if cas + mojkrok >= dlzka: t2 := arctime (dlzka-epsilon) of P; fi
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


def l_rope_SKBB (expr P, show_anchors, show_rebelays) =
  T:=identity;
  pickup PenC;
  if not show_rebelays:
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
    x = point (length P)-1 of P + whatever * down;
    x = point (length P) of P + whatever * right;
    draw point (length P)-1 of P -- x;
  fi;
  if show_anchors:
    for i:=0 upto length P if show_rebelays: -1 fi:
      thdraw point i of P withpen pencircle scaled 0.25u;
    endfor;
  fi;
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
     drawoptions(withcolor 0.3[black,white]);
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
      pair coord;
      sq_size:=0.12u;
      dlzka := arclength P;
      mojkrok:=adjust_step(dlzka, u);
      pickup PenD;
      forever:
        t := arctime cas of P;
        coord := point t of P;
        thfill coord+(-sq_size,-sq_size)--coord+(sq_size,-sq_size)--coord+(sq_size,sq_size)--coord+(-sq_size,sq_size)--cycle;
        cas := cas + mojkrok;
        exitif cas > dlzka + (mojkrok / 3); % for rounding errors
      endfor;
      pickup PenC;
      thdraw P;
    fi;
enddef;

def l_fixedladder_SKBB (expr Q) =
  % TODO: support side view in elevation (front view could be the same as in the plan view)
  T:=identity;
  path P, P_left, P_right;
  P := punked Q;     % ensure that there is no bezier curve
  pair p_tmp, za, zb;
  len := arclength P;
  dt:=adjust_step(len, 0.3u);
  t := dt/2;
  wdth := 0.25u;     % half-width of the ladder
  pickup PenC;
  % draw the steps
  forever:
    p_tmp := point arctime t of P of P;
    draw p_tmp+wdth*unitvector(thdir(P,arctime t of P) rotated -90) --
         p_tmp+wdth*unitvector(thdir(P,arctime t of P) rotated  90);
    t := t + dt;
    exitif t > len + 10*epsilon;
  endfor;
  draw polyline_offset(P,wdth, 90);
  draw polyline_offset(P,wdth,-90);
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


% Label processing modes
% 0 = generic label
% 1 = altitude with a dot and increased offset from the anchor point
% 2 = semi circle up
% 3 = semi circle down
% 4 = semi circle up + semi circle down
% 5 = circle
% 6 = boxed label
% 7 = generic label for station name with an increased offset from the anchor point
% 8 = filled label; not implemented in the standard symbol sets, but see samples/q-marks for a usage example
p_label_mode_label:=0;
p_label_mode_station:=7;
p_label_mode_altitude:=1;
p_label_mode_date:=0;
p_label_mode_passageheight:=5;
p_label_mode_passageheightpos:=2;
p_label_mode_passageheightneg:=3;
p_label_mode_passageheightposneg:=4;
p_label_mode_height:=7;
p_label_mode_debugscrap:=6;
p_label_mode_debugstation:=7;

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
 % -numbersystem=double gets bbox wrong for labels generated from empty strings; unnecessary to do anything in this case, anyway
 boolean exitdef; exitdef = false;
 if string txt: if txt = "": exitdef := true; fi; fi;
 if not exitdef:
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
 fi;
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
      label(if (lang="sk") or (lang="cs"): "S" else: "N" fi, origin);
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

def s_altitudebar_SKBB (expr zmin, zmax, units)(text t)(text labels) =
  begingroup;
    j := 0;
    string s;
    hs := 36 bp;
    vs := 252 bp;
    prevpos := -1;
    for i = t:
      if not odd j:
        k := (1-i)*vs;
      else:
        if prevpos >= 0:
          p := (0,prevpos)--(hs,prevpos)--(hs,k)--(0,k)--cycle;
          fill p withalpha -2 withlinearshading(p, 2.5, tmpcol, i);
        fi;
        tmpcol := i;
        prevpos := k;
      fi;
      j := j+1;
    endfor;
    % check if the labels parameter contains anything useful
    ii := 0;
    for i=labels:
      ii := ii+1;
    endfor;
    interim labeloffset := 15 bp;
    interim linecap := butt;
    if ii>1: % custom labeling
      j := 0;
      for i=labels:
        if not odd j:
          k := (1-i)*vs;
        else:
          draw (hs, k) -- (hs+5bp, k) withpen PenD;
          label.rt(thTEX(i), (hs, k));
        fi;
        j := j+1;
      endfor;
    else:   % calculated labeling; breakpoints for the (zmax-zmin) difference: 1*10^n, 2*10^n, 5*10^n
      d := zmax - zmin;
      dlog := log(d);
      if dlog mod 1 < 0.301: dv := 2;
      elseif dlog mod 1 < 0.7: dv := 5;
      else: dv := 10;
      fi;
      dv := floor(dv*(10**(floor(dlog-1))));
      if (dv > 0) or (floor zmax - floor zmin >= 2):
        if dv > 0:    % zmax-zmin >= 10
          i := dv * floor(zmin/dv);
          if i < zmin: i := i + dv; fi;
        else:         % at least two whole numbers between zmin and zmax
          i := floor(zmin);
          if i < zmin: i := i + 1; fi;
          dv := 1;
        fi;
        forever:
          exitif i > zmax;
          j := (i-zmin)/d*vs;
          draw (hs, j) -- (hs+5bp, j) withpen PenD;
          label.rt(thTEX(decimal round i & "\thinspace " & units), (hs, j));
          i := i + dv;
        endfor;
      else:
        draw (0, 0) -- (hs+5bp, 0) withpen PenD;
        draw (0, vs) -- (hs+5bp, vs) withpen PenD;
        label.rt(thTEX(decimal(round(10*zmin)/10) & "\thinspace " & units),(hs,0));
        label.rt(thTEX(decimal(round(10*zmax)/10) & "\thinspace " & units),(hs,vs));
      fi;
    fi;
  endgroup;
enddef;



%%%%% ENDINPUT thSpecial %%%%%





%%%%% INPUT uAUT %%%%%


% Austrian Symbol Set, author Georg Pacher
% enhanced 2017 by Benedikt Hallinger

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
% If the number of allowed recursions is reached, a negative number of intersections is returned
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

beginpattern(pattern_flowstone_AUT);
    pickup PenC;
    draw (0.0u, 0.01u)--(0.33u, 0.01u);
    draw (0.33u, 0.33u)--(0.66u, 0.33u);
    patternbbox(0u,0u, 0.66u, 0.66u); % definiert Rechteckgroesse des Symbols
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

def a_clay_AUT (expr Path) =
  T:=identity;
%  thclean Path;
  thfill Path withpattern pattern_sand_AUT;
enddef;


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
             qq:= qq scaled (uniformdeviate(.2)+.5 );
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


def a_flowstone_AUT (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_flowstone_AUT ;
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

let l_ceilingstep_AUT = l_ceilingstep_UIS;

let l_ceilingmeander_AUT = l_ceilingmeander_UIS;

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

let p_station_painted_AUT = p_station_fixed_ASF ;
let p_station_fixed_AUT = p_station_fixed_ASF ;

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





%%%%% INPUT uSBE %%%%%


% Symbol set of Brazilian Speleological Society (SBE - Sociedade Brasileira de
% Espeleologia), author Rodrigo Severo.


%%%%%%%%%%%%%%%%%%%%%%%%% Points %%%%%%%%%%%%%%%%%%%%%%%%%


picture SBE_altar_raw;
SBE_altar_raw := image(
	fill (406,482)..controls (364,491) and (340,542)..(360,581)
		..controls (378,621) and (436,633)..(469,603)
		..controls (504,575) and (500,514)..(461,491)
		..controls (445,480) and (425,478)..(406,482)
		--cycle;
	pickup pencircle scaled 99bp;
	draw (225,307)--(319,460);
	pickup pencircle scaled 70bp;
	draw (329,472)--(391,364)--(466,419);
	draw (154,188)--(326,188)--(224,290);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_altar_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_altar_raw;
enddef;


picture SBE_archeo_excavation_raw;
SBE_archeo_excavation_raw := image(
	begingroup;
		fill (199,415)--(242,555)--(312,574)
			--(329,558)--(351,580)--(335,597)
			--(422,683)--(466,640)--(379,553)
			--(362,569)--(340,547)--(359,528)
			--(339,457)--cycle;
		pickup pencircle scaled 17bp;
		interim linecap := rounded;
		draw (138,464)..controls (152,460) and (169,461)..(187,461);
		draw (368,463)..controls (411,458) and (449,461)..(489,464);
		pickup pencircle scaled 11bp;
		interim linecap := squared;
		draw (291,403)..controls (279,402) and (262,395)..(253,372);
		draw (371,409)..controls (370,422) and (359,429)..(346,430);
		draw (423,399)..controls (432,402) and (437,411)..(437,418);
		currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
	endgroup;
);

def p_archeoexcavation_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_archeo_excavation_raw;
enddef;


picture SBE_audio_raw;
SBE_audio_raw := image(
	fill (125,196)--(81,171)--(44,171)
		..controls (34,171) and (27,163)..(27,154)
		--(27,115)..controls (27,106) and (34,98)..(44,98)
		--(81,98)--(125,73)..controls (133,68) and (140,72)..(140,81)
		--(140,188)..controls (140,197) and (133,201)..(125,196)
		--cycle;
	pickup pencircle scaled 11bp;
	draw (158,186)..controls (178,152) and (179,118)..(158,82);
	draw (185,202)..controls (208,166) and (213,112)..(185,67);
	draw (213,218)..controls (248,150) and (243,105)..(213,50);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_audio_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_audio_raw;
enddef;


picture SBE_bat_raw;
SBE_bat_raw := image(
	fill (538,34)..controls (484,144) and (350,326)..(287,197)
		..controls (249,375) and (141,347)..(83,352)
		..controls (58,356) and (10,339)..(53,371)
		..controls (100,409) and (147,451)..(204,474)
		..controls (286,503) and (318,471)..(376,407)
		..controls (439,342) and (510,278)..(599,252)
		..controls (601,278) and (580,480)..(623,338)
		..controls (621,373) and (696,393)..(707,345)
		..controls (719,377) and (741,417)..(737,370)
		..controls (732,310) and (745,281)..(749,252)
		..controls (837,323) and (902,458)..(1017,478)
		..controls (1114,499) and (1201,436)..(1266,371)
		..controls (1285,353) and (1316,330)..(1270,343)
		..controls (1174,357) and (1033,396)..(1018,231)
		..controls (905,326) and (818,126)..(798,41)
		..controls (718,124) and (662,-13)..(637,34)
		..controls (621,76) and (562,52)..(538,34)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_bat_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_bat_raw;
enddef;


picture SBE_bones_raw;
SBE_bones_raw := image(
	fill (328,272)..controls (258,226) and (188,192)..(132,134)
		..controls (119,115) and (103,80)..(80,78)
		..controls (68,76) and (49,83)..(39,93)
		..controls (35,97) and (15,102)..(25,118)
		..controls (44,150) and (30,150)..(18,154)
		..controls (6,159) and (-2,159)..(-3,168)
		..controls (2,202) and (32,206)..(54,205)
		..controls (83,204) and (94,199)..(126,215)
		..controls (148,226) and (183,243)..(278,300)
		--cycle;
	fill (663,585)..controls (648,585) and (632,579)..(620,571)
		..controls (609,563) and (597,547)..(587,527)
		..controls (571,497) and (555,479)..(529,463)
		..controls (506,448) and (493,443)..(445,412)
		--(501,378)..controls (544,403) and (605,415)..(650,416)
		..controls (671,416) and (672,416)..(683,422)
		..controls (708,436) and (714,455)..(701,474)
		..controls (674,489) and (653,488)..(674,511)
		..controls (686,524) and (702,548)..(698,562)
		..controls (692,578) and (679,585)..(663,585)
		--cycle;
	fill (584,155)..controls (572,180) and (570,192)..(541,213)
		..controls (506,237) and (222,404)..(158,436)
		..controls (118,456) and (92,463)..(43,466)
		..controls (22,468) and (21,468)..(10,474)
		..controls (-12,490) and (-17,510)..(-3,527)
		..controls (23,541) and (45,538)..(25,563)
		..controls (15,576) and (0,601)..(5,615)
		..controls (19,647) and (61,636)..(83,619)
		..controls (93,610) and (104,593)..(114,572)
		..controls (127,542) and (142,523)..(166,505)
		..controls (205,477) and (361,387)..(421,358)
		..controls (480,330) and (597,259)..(609,256)
		..controls (631,255) and (670,257)..(683,238)
		..controls (690,228) and (693,208)..(690,195)
		..controls (688,189) and (693,170)..(674,171)
		..controls (637,172) and (644,159)..(646,147)
		..controls (648,134) and (652,126)..(644,121)
		..controls (612,110) and (594,134)..(584,155)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_bones_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_bones_raw;
enddef;


def p_curtains_UIS(expr pos, theta, sc, al) =
	U := (.3u, .8u);
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
		thdraw (0,.15u)--(0,0){dir 180}..(-.12u,-.11u)..{dir 0}(0,-.22u)--(0,-.4u);
	endfor;
enddef;


picture SBE_danger_raw;
SBE_danger_raw := image(
	fill (331,489)..controls (330,489) and (328,489)..(326,488)
		--(291,422)..controls (291,422) and (291,421)..(291,421)
		..controls (291,417) and (294,414)..(297,413)
		--(365,413)..controls (369,414) and (371,417)..(371,421)
		..controls (371,422) and (371,422)..(371,423)
		--(336,488)..controls (335,489) and (333,489)..(331,489)
		..controls (331,489) and (331,489)..(331,489)
		--cycle withcolor red;
	fill (336,427)..controls (336,430) and (334,432)..(331,432)
		..controls (328,432) and (326,430)..(326,427)
		..controls (326,424) and (328,422)..(331,422)
		..controls (334,422) and (336,424)..(336,427)
		--cycle withcolor white;
	fill (335,464)..controls (336,466) and (332,466)..(331,466)
		..controls (330,466) and (327,466)..(327,464)
		--(330,436)..controls (330,435) and (330,435)..(331,435)
		..controls (332,435) and (332,435)..(332,436)
		--cycle withcolor white;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_danger_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_danger_raw;
enddef;


def p_discpillar_UIS(expr pos,theta,sc,al) =
	U := (.15u, .4u);
	T := identity rotated theta aligned al scaled sc shifted pos;
	pickup PenC;
	thdraw (-.15u,.4u) -- (0,.15u) -- (0,-.15u) -- (-.15u,-.4u);
	thdraw (0,-.15u) -- (.15u,-.4u);
	thdraw (0,.15u) -- (.15u,.4u);
	thdraw (-.15u,0) -- (.15u,0);
enddef;


def p_discpillars_UIS(expr pos,theta,sc,al) =
	U := (.3u, .8u);
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (-.15u,.4u) -- (0,.15u) -- (0,-.15u) -- (-.15u,-.4u);
		thdraw (0,-.15u) -- (.15u,-.4u);
		thdraw (0,.15u) -- (.15u,.4u);
		thdraw (-.15u,0) -- (.15u,0);
	endfor;
enddef;


def p_discstalactites_UIS(expr pos,theta,sc,al) =
	U := (.3u, .8u);
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
		thdraw (0,.15u) -- (.15u,.4u);
		thdraw (-.15u,-.1u) -- (.15u,-.1u);
	endfor;
enddef;


def p_discstalagmites_UIS(expr pos,theta,sc,al) =
	U := (.3u, .8u);
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
		thdraw (0,-.15u) -- (.15u,-.4u);
		thdraw (-.15u,.1u) -- (.15u,.1u);
	endfor;
enddef;


def p_discstalactite_UIS(expr pos,theta,sc,al) =
	U := (.15u, .4u);
	T := identity rotated theta aligned al scaled sc shifted pos;
	pickup PenC;
	thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
	thdraw (0,.15u) -- (.15u,.4u);
	thdraw (-.15u,-.1u) -- (.15u,-.1u);
enddef;


def p_discstalagmite_UIS(expr pos,theta,sc,al) =
	U := (.15u, .4u);
	T := identity rotated theta aligned al scaled sc shifted pos;
	pickup PenC;
	thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
	thdraw (0,-.15u) -- (.15u,-.4u);
	thdraw (-.15u,.1u) -- (.15u,.1u);
enddef;


picture SBE_electric_light_raw;
SBE_electric_light_raw := image(
	begingroup;
		fill (334,564)..controls (341,561) and (346,556)..(349,550)
			..controls (350,548) and (351,546)..(351,543)
			..controls (349,543) and (347,543)..(345,543)
			..controls (329,543) and (313,543)..(296,543)
			..controls (294,545) and (296,548)..(297,550)
			..controls (300,556) and (305,561)..(312,564)
			..controls (317,567) and (324,567)..(330,565)
			..controls (332,565) and (333,565)..(334,564)
			--cycle;
		fill (394,393)..controls (402,379) and (406,361)..(404,344)
			..controls (399,312) and (375,287)..(348,280)
			..controls (317,271) and (282,283)..(263,310)
			..controls (246,333) and (244,370)..(258,391)
			..controls (277,419) and (281,466)..(281,466)
			--(368,466)..controls (369,439) and (383,413)..(394,393)
			--cycle;
		pickup pencircle scaled 25bp;
		draw (153,248)--(224,303);
		draw (489,255)--(424,301);
		draw (408,208)--(377,259);
		draw (241,218)--(266,265);
		draw (324,161)--(324,245);
		pickup pencircle scaled 22bp;
		interim linecap := rounded;
		draw (282,489)--(370,489);
		draw (280,524)--(371,524);
		currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
	endgroup;
);

def p_electriclight_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_electric_light_raw;
enddef;


picture SBE_exvoto_raw;
SBE_exvoto_raw := image(
	pickup pencircle scaled 29bp;
	draw (274,659)--(381,623);
	draw (209,277)--(247,393);
	draw (187,282)--(228,270);
	draw (297,647)--(224,427)--(247,393)
		--(283,408)--(357,631);
	draw (251,497)--(302,494);
	draw (490,657)--(578,587);
	draw (297,321)--(373,417);
	draw (282,334)--(313,309);
	draw (508,638)--(363,457)--(373,417)
		--(412,418)--(558,602);
	draw (421,524)--(452,482);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_exvoto_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_exvoto_raw;
enddef;


picture SBE_gate_raw;
SBE_gate_raw := image(
	begingroup;
		pickup pencircle scaled 28bp;
		interim linecap := butt;
		interim linejoin := rounded;
		draw (121,221)--(249,244)--(249,546)
			--(121,454)--cycle;
		draw (466,221)--(337,244)--(337,546)
			--(465,454)--cycle;
		pickup pencircle scaled 22bp;
		interim linejoin := mitered;
		draw (121,307)--(249,330);
		draw (184,496)--(184,234);
		draw (466,307)--(337,330);
		draw (402,496)--(402,234);
		currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
	endgroup;
);

def p_gate_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_gate_raw;
enddef;


def p_helictites_UIS(expr pos,theta,sc,al) =
	U:=(.4u,.8u);
	pickup PenC;
	for i=-1 upto 1:
		if i < 0:
			T:=identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .45u, abs(i) * .15u));
		else:
			T:=identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		fi;
		thdraw (0,.4u)--(0,-.4u);
		p := (-.2u,.4u)---(-.2u,.1u){down}..{dir -10}(-.1u,0.02u)---origin;
		thdraw p;
		thdraw p reflectedabout (origin,(0,u)) reflectedabout (origin,(u,0));
	endfor;
enddef;


picture SBE_human_bones_raw;
SBE_human_bones_raw := image(
	fill (52,279)..controls (50,279) and (48,279)..(47,278)
		--(47,278)..controls (37,276) and (32,266)..(33,258)
		..controls (26,254) and (20,247)..(20,240)
		..controls (20,230) and (30,221)..(41,221)
		..controls (45,222) and (49,223)..(52,225)
		--(88,205)..controls (88,205) and (88,206)..(87,206)
		--(86,210)..controls (82,221) and (81,236)..(82,251)
		--(72,257)..controls (72,261) and (71,265)..(70,268)
		..controls (66,275) and (59,279)..(52,279)
		--cycle;
	fill (258,151)..controls (256,139) and (255,125)..(249,113)
		--(296,87)..controls (295,79) and (300,71)..(306,67)
		..controls (323,63) and (335,72)..(335,86)
		..controls (342,90) and (347,97)..(347,104)
		..controls (347,114) and (337,123)..(326,122)
		..controls (322,122) and (319,121)..(315,119)
		--cycle;
	fill (316,279)..controls (309,279) and (302,275)..(298,268)
		..controls (296,265) and (296,261)..(296,257)
		--(291,254)..controls (293,239) and (292,221)..(288,210)
		--(288,209)--(315,225)..controls (319,223) and (322,222)..(327,221)
		..controls (338,221) and (347,230)..(347,240)
		..controls (347,247) and (342,254)..(335,258)
		..controls (335,266) and (331,276)..(321,278)
		--(321,278)..controls (319,279) and (318,279)..(316,279)
		--cycle;
	fill (116,155)--(52,119)..controls (49,121) and (46,122)..(41,122)
		..controls (30,123) and (20,114)..(20,104)
		..controls (20,97) and (25,90)..(33,86)
		..controls (32,72) and (44,63)..(62,67)
		..controls (67,71) and (72,79)..(72,87)
		--(123,116)..controls (118,128) and (117,143)..(116,155)
		--cycle;
	fill (187,311)..controls (179,311) and (171,310)..(165,308)
		..controls (136,296) and (120,285)..(109,255)
		..controls (105,242) and (105,223)..(109,211)
		--(110,208)..controls (119,188) and (127,188)..(129,184)
		..controls (135,174) and (130,139)..(148,126)
		..controls (156,124) and (165,119)..(171,120)
		..controls (176,122) and (182,120)..(187,120)
		..controls (192,120) and (198,121)..(203,120)
		..controls (211,120) and (218,123)..(226,126)
		..controls (244,139) and (239,174)..(245,184)
		..controls (246,188) and (255,188)..(263,208)
		--(265,211)..controls (269,223) and (269,242)..(265,255)
		..controls (265,255) and (259,272)..(249,282)
		..controls (236,295) and (230,302)..(209,308)
		..controls (203,310) and (195,311)..(187,311)
		--cycle;
	fill (171,230)..controls (162,217) and (161,207)..(148,207)
		..controls (125,206) and (126,224)..(125,231)
		..controls (123,240) and (136,248)..(148,248)
		..controls (159,248) and (176,239)..(171,230)
		--cycle withcolor white;
	fill (203,230)..controls (212,217) and (212,207)..(226,207)
		..controls (249,206) and (247,224)..(249,231)
		..controls (251,240) and (238,248)..(226,248)
		..controls (215,248) and (198,239)..(203,230)
		--cycle withcolor white;
	fill (187,212)..controls (177,207) and (175,183)..(175,174)
		..controls (175,174) and (176,173)..(177,173)
		..controls (186,178) and (189,178)..(198,173)
		..controls (199,173) and (200,174)..(200,174)
		..controls (200,183) and (197,213)..(187,212)
		--cycle withcolor white;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_humanbones_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_human_bones_raw;
enddef;


picture SBE_masonry_raw;
SBE_masonry_raw := image(
	begingroup;
		pickup pencircle scaled 28bp;
		interim linecap := butt;
		interim linejoin := mitered;
		draw (287,482)--(355,482);
		draw (247,442)--(315,442);
		draw (327,442)--(395,442);
		draw (206,401)--(275,401);
		draw (287,401)--(355,401);
		draw (247,360)--(315,360);
		draw (327,360)--(395,360);
		currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
	endgroup;
);

def p_masonry_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_masonry_raw;
enddef;


picture UIS_minus_raw;
UIS_minus_raw := image(
	pickup pencircle scaled 3bp;
	draw (383,401)--(403,401);
	pickup pencircle scaled 2bp;
	draw (407,401)..controls (407,394) and (401,387)..(393,387)
		..controls (385,387) and (379,394)..(379,401)
		..controls (379,409) and (385,415)..(393,415)
		..controls (401,415) and (407,409)..(407,401)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_minus_UIS(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw UIS_minus_raw;
enddef;


picture SBE_mud_raw;
SBE_mud_raw := image(
	fill (240,321)..controls (232,352) and (217,388)..(183,397)
		..controls (156,398) and (135,369)..(108,381)
		..controls (82,388) and (66,417)..(74,442)
		..controls (78,479) and (59,518)..(79,552)
		..controls (87,582) and (41,598)..(52,628)
		..controls (68,653) and (99,634)..(121,630)
		..controls (147,623) and (162,645)..(172,664)
		..controls (200,685) and (236,674)..(267,676)
		..controls (290,675) and (312,676)..(333,685)
		..controls (352,692) and (380,696)..(394,676)
		..controls (406,653) and (421,627)..(450,623)
		..controls (474,620) and (506,635)..(520,605)
		..controls (536,576) and (533,543)..(533,512)
		..controls (531,476) and (511,442)..(521,407)
		..controls (523,374) and (483,370)..(459,370)
		..controls (431,371) and (407,359)..(382,348)
		..controls (357,337) and (326,324)..(300,340)
		..controls (277,343) and (264,298)..(241,320)
		--(240,320)--cycle withcolor (0.53, 0.24, 0.02);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_mud_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_mud_raw;
enddef;


picture SBE_mudcrack_raw;
SBE_mudcrack_raw := image(
	fill (320,501)--(340,468)--(320,462)
		--(320,462)--(320,457)--(348,464)
		--(387,451)--(371,434)--(345,421)
		--(320,427)--(320,427)--(320,424)
		--(331,422)--(320,385)--(325,385)
		--(335,422)--(344,418)--(351,385)
		--(355,385)--(355,385)--(348,419)
		--(373,429)--(401,403)--(393,388)
		--(395,385)--(397,385)--(396,387)
		--(403,402)--(416,400)--(428,389)
		--(429,390)--(417,404)--(403,404)
		--(378,432)--(393,448)--(431,415)
		--(436,415)--(436,419)--(433,419)
		--(396,452)--(406,464)--(436,460)
		--(436,464)--(408,468)--(403,484)
		--(436,490)--(436,493)--(403,488)
		--(403,501)--(399,501)--(400,483)
		--(403,468)--(391,457)--(351,467)
		--(378,501)--(370,501)--(346,468)
		--(324,501)--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_mudcrack_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_mudcrack_raw;
enddef;


picture SBE_nameplate_raw;
SBE_nameplate_raw := image(
	pickup pencircle scaled 24bp;
	draw (77,563)--(505,563)--(505,340)
		--(77,340)--cycle;
	pickup pencircle scaled 10bp;
	draw (208,496)--(422,496);
	draw (117,450)--(358,450);
	draw (264,401)--(470,401);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_nameplate_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_nameplate_raw;
enddef;


picture SBE_wheelchair_raw;
SBE_wheelchair_raw := image(
	fill (363,192)..controls (363,97) and (286,20)..(192,20)
		..controls (97,20) and (20,97)..(20,192)
		..controls (20,287) and (97,364)..(192,364)
		..controls (286,364) and (363,287)..(363,192)
		--cycle withcolor white;
	pickup pencircle scaled 39bp;
	draw (363,192)..controls (363,97) and (286,20)..(192,20)
		..controls (97,20) and (20,97)..(20,192)
		..controls (20,287) and (97,364)..(192,364)
		..controls (286,364) and (363,287)..(363,192)
		--cycle withcolor red;
	fill (202,301)..controls (202,286) and (190,274)..(175,274)
		..controls (160,274) and (148,286)..(148,301)
		..controls (148,316) and (160,328)..(175,328)
		..controls (190,328) and (202,316)..(202,301)
		--cycle;
	pickup pencircle scaled 21bp;
	draw (139,221)..controls (109,212) and (88,184)..(88,152)
		..controls (88,113) and (120,81)..(160,81)
		..controls (192,81) and (221,102)..(229,133);
	draw (177,254)--(177,178)--(259,178)
		--(278,129)--(299,134);
	draw (177,233)--(239,233);
);

picture SBE_nowheelchair_raw;
SBE_nowheelchair_raw := image(
	draw SBE_wheelchair_raw;
	begingroup;
		pickup pencircle scaled 30bp;
		interim linecap := butt;
		interim linejoin := mitered;
		draw (60,307)--(323,77) withcolor red;
	endgroup;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_nowheelchair_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_nowheelchair_raw;
enddef;


picture SBE_pendant_raw;
SBE_pendant_raw := image(
	pickup pencircle scaled 22bp;
	draw (476,639)..controls (471,639) and (422,621)..(428,575)
		..controls (434,533) and (506,503)..(505,457)
		..controls (502,260) and (383,164)..(289,164)
		..controls (196,164) and (77,260)..(73,457)
		..controls (72,503) and (144,533)..(150,575)
		..controls (156,621) and (107,639)..(102,639);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_pendant_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_pendant_raw;
enddef;


def p_pillarwithcurtains_UIS(expr pos, theta, sc, al) =
	U := (.15u,.5u);
	T := identity rotated theta aligned al scaled sc shifted pos;
	pickup PenC;
	thdraw (0,.25u)--(0,.1u){dir 180}..(-.1u,0)..{dir 0}(0,-.1u)--(0,-.25u);
	thdraw (-.15u,-.5u)--(0,-.25u)--(.15u,-.5u);
	thdraw (-.15u,.5u)--(0,.25u)--(.15u,.5u);
enddef;


def p_pillarswithcurtains_UIS(expr pos, theta, sc, al) =
	U := (.3u,u);
	pickup PenC;
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (0,.25u)--(0,.1u){dir 180}..(-.1u,0)..{dir 0}(0,-.1u)--(0,-.25u);
		thdraw (-.15u,-.5u)--(0,-.25u)--(.15u,-.5u);
		thdraw (-.15u,.5u)--(0,.25u)--(.15u,.5u);
	endfor;
enddef;


picture SBE_photo_raw;
SBE_photo_raw := image(
	fill (186,476)--(186,445)--(111,445)
		--(75,408)--(75,302)--(188,302)
		--(188,286)--(329,286)--(329,302)
		--(440,302)--(440,408)--(405,445)
		--(328,445)--(328,476)--cycle;
	pickup pencircle scaled 18bp;
	draw (194,499)--(107,621);
	draw (320,499)--(407,621);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_photo_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_photo_raw;
enddef;


picture UIS_plus_raw;
UIS_plus_raw := image(
	pickup pencircle scaled 3bp;
	draw (383,401)--(403,401);
	draw (393,411)--(393,392);
	pickup pencircle scaled 2bp;
	draw (407,401)..controls (407,394) and (401,387)..(393,387)
		..controls (385,387) and (379,394)..(379,401)
		..controls (379,409) and (385,415)..(393,415)
		..controls (401,415) and (407,409)..(407,401)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_plus_UIS(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw UIS_plus_raw;
enddef;


picture UIS_plusminus_raw;
UIS_plusminus_raw := image(
	pickup pencircle scaled 3bp;
	draw (383,427)--(403,427);
	draw (393,418)--(393,437);
	draw (383,401)--(403,401);
	pickup pencircle scaled 2bp;
	draw (393,387)..controls (385,387) and (379,394)..(379,401)
		--(379,427)..controls (379,435) and (385,441)..(393,441)
		..controls (401,441) and (407,435)..(407,427)
		--(407,401)..controls (407,394) and (401,387)..(393,387)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / (xpart urcorner currentpicture) - (xpart llcorner currentpicture));
);

def p_plusminus_UIS(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw UIS_plusminus_raw;
enddef;


picture SBE_seed_germination_raw;
SBE_seed_germination_raw := image(
	fill (443,464)..controls (441,492) and (411,512)..(389,501)
		..controls (406,574) and (355,622)..(378,509)
		..controls (350,513) and (331,473)..(333,452)
		..controls (350,440) and (374,461)..(381,474)
		..controls (382,466) and (417,441)..(443,464)
		--cycle;
	pickup pencircle scaled 25bp;
	draw (101,276)..controls (177,243) and (396,296)..(502,269);
	pickup pencircle scaled 19bp;
	draw (194,270)..controls (160,669) and (364,759)..(382,543);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_seedgermination_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_seed_germination_raw;
enddef;


def p_stalactitestalagmite_UIS(expr pos,theta,sc,al) =
	U := (.15u, .4u);
	T := identity rotated theta aligned al scaled sc shifted pos;
	pickup PenC;
	thdraw (-.15u,.4u) -- (0,.2u) -- (.15u,.4u);
	thdraw (.15u,-.4u) -- (0,-.2u) -- (-.15u,-.4u);
	thdraw (0,-.2u) -- (0,-.1u);
	thdraw (0,.2u) -- (0,.1u);
enddef;


def p_stalactitesstalagmites_UIS(expr pos,theta,sc,al) =
	U := (.3u, .8u);
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (-.15u,.4u) -- (0,.2u) -- (.15u,.4u);
		thdraw (.15u,-.4u) -- (0,-.2u) -- (-.15u,-.4u);
		thdraw (0,-.2u) -- (0,-.1u);
		thdraw (0,.2u) -- (0,.1u);
	endfor;
enddef;


picture SBE_tree_trunk_raw;
SBE_tree_trunk_raw := image(
	pickup pencircle scaled 11bp;
	draw (338,554)--(153,393)..controls (64,292) and (204,143)..(312,243)
		--(504,488);
	pickup pencircle scaled 0.1bp;
	fill (313,318)..controls (313,274) and (277,238)..(232,238)
		..controls (188,238) and (152,274)..(152,318)
		..controls (152,363) and (188,398)..(232,398)
		..controls (277,398) and (313,363)..(313,318)
		--cycle;
	pickup pencircle scaled 5bp;
	draw (290,453)--(348,506);
	draw (375,406)--(445,481);
	draw (316,397)--(348,429);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_treetrunk_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_tree_trunk_raw;
enddef;


picture SBE_volcano_raw;
SBE_volcano_raw := image(
	pickup pencircle scaled 21bp;
	draw (36,222)--(169,567)..controls (177,510) and (212,485)..(265,485)
		..controls (319,485) and (353,510)..(361,567)
		--(494,222);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_volcano_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_volcano_raw;
enddef;


picture SBE_walkway_raw;
SBE_walkway_raw := image(
	begingroup;
		pickup pencircle scaled 9bp;
		interim linecap := butt;
		interim linejoin := mitered;
		draw (19,26)--(171,26);
		draw (135,61)--(171,61);
		draw (19,61)--(55,61);
		draw (89,61)--(104,61);
		pickup pencircle scaled 12bp;
		interim linecap := rounded;
		draw (63,43)--(79,72)--(93,135);
		draw (124,44)--(115,72)--(93,97)
			--(100,133);
		pickup pencircle scaled 9bp;
		interim linejoin := rounded;
		draw (133,109)--(115,117)--(99,144)
			--(72,128)--(62,107);
		pickup pencircle scaled 0.1bp;
		fill (113,162)..controls (113,157) and (108,152)..(102,152)
			..controls (96,152) and (91,157)..(91,162)
			..controls (91,168) and (96,173)..(102,173)
			..controls (108,173) and (113,168)..(113,162)
			--cycle;
	endgroup;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_walkway_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_walkway_raw;
enddef;


picture SBE_water_drip_raw;
SBE_water_drip_raw := image(
	fill (493,1196)..controls (535,1234) and (583,1266)..(635,1290)
		..controls (595,1233) and (566,1160)..(588,1091)
		..controls (622,981) and (733,912)..(757,796)
		..controls (789,684) and (728,556)..(622,509)
		..controls (524,461) and (398,489)..(328,572)
		..controls (278,629) and (259,710)..(272,785)
		..controls (293,942) and (375,1090)..(493,1196)
		--cycle;
	fill (495,1159)..controls (403,1066) and (329,950)..(299,821)
		..controls (287,761) and (285,694)..(314,637)
		..controls (354,571) and (425,522)..(502,512)
		..controls (513,511) and (550,509)..(522,518)
		..controls (449,551) and (384,613)..(366,694)
		..controls (342,794) and (371,898)..(411,990)
		..controls (441,1059) and (481,1123)..(524,1185)
		..controls (514,1177) and (505,1168)..(495,1159)
		--cycle withcolor white;
	fill (353,484)..controls (341,488) and (325,494)..(316,504)
		..controls (300,537) and (261,574)..(232,540)
		..controls (209,503) and (241,469)..(276,471)
		..controls (299,473) and (344,478)..(353,484)
		--cycle;
	fill (702,500)..controls (714,503) and (731,509)..(739,520)
		..controls (756,553) and (795,591)..(825,557)
		..controls (848,519) and (816,485)..(780,486)
		..controls (757,488) and (711,493)..(702,500)
		--cycle;
	fill (290,571)..controls (279,580) and (262,592)..(246,594)
		..controls (203,588) and (140,602)..(154,654)
		..controls (176,701) and (231,693)..(253,656)
		..controls (266,632) and (291,584)..(290,571)
		--cycle;
	fill (761,591)..controls (772,601) and (789,613)..(805,614)
		..controls (848,609) and (911,623)..(897,674)
		..controls (875,721) and (820,713)..(798,676)
		..controls (785,652) and (760,604)..(761,591)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_waterdrip_SBE(expr pos, theta, sc, al) =
	T := identity aligned al rotated theta scaled sc shifted pos;
	thdraw SBE_water_drip_raw;
enddef;


def p_wheelchair_SBE(expr pos, theta, sc, al) =
	T := identity aligned al rotated theta scaled sc shifted pos;
	thdraw SBE_wheelchair_raw shifted (-(llcorner SBE_wheelchair_raw)-(urcorner SBE_wheelchair_raw - llcorner SBE_wheelchair_raw)/2) scaled (u / max((xpart urcorner SBE_wheelchair_raw) - (xpart llcorner SBE_wheelchair_raw), (ypart urcorner SBE_wheelchair_raw) - (ypart llcorner SBE_wheelchair_raw)));
enddef;


%%%%%%%%%%%%%%%%%%%%%%%%% Lines %%%%%%%%%%%%%%%%%%%%%%%%%


def l_abyssentrance_SBE(expr P) =
	begingroup
		path SBE_Tick, SBE_T;

		T := identity;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length
		SBE_Tick := (0,0.1u) -- (0,-0.1u);
		SBE_T := (0,0) -- (0,-0.1u);
		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize * 1/8) of P;
			t2 := arctime (cursor + elementSize * 2/8) of P;
			t3 := arctime (cursor + elementSize * 4/8) of P;
			t4 := arctime (cursor + elementSize * 6/8) of P;
			t5 := arctime (cursor + elementSize * 7/8) of P;

			thdraw SBE_Tick rotated angle(thdir(P,t1)) shifted (point t1 of P);
			thdraw (subpath (t2,t4) of P);
			thdraw SBE_T rotated (180+angle(thdir(P,t3))) shifted (point t3 of P);
			thdraw SBE_Tick rotated angle(thdir(P,t5)) shifted (point t5 of P);

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


def l_dripline_SBE(expr P) =
	begingroup
		path SBE_Tick;

		T := identity;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length
		SBE_Tick := (0,0.1u) -- (0,-0.1u);
		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize * 1/8) of P;
			t2 := arctime (cursor + elementSize * 2/8) of P;
			t3 := arctime (cursor + elementSize * 4/8) of P;
			t4 := arctime (cursor + elementSize * 6/8) of P;
			t5 := arctime (cursor + elementSize * 7/8) of P;

			thdraw SBE_Tick rotated angle(thdir(P,t1)) shifted (point t1 of P);
			thdraw (subpath (t2,t4) of P);
			thdraw SBE_Tick rotated angle(thdir(P,t5)) shifted (point t5 of P);

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


def l_fault_SBE(expr P) =
	begingroup
		path SBE_Dot;
		pair SBE_Ppb, SBE_Pdb, SBE_Pvb, SBE_Ppe, SBE_Pde, SBE_Pve;

		T := identity;

		pickup PenA;
		thdraw P;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length
		SBE_Dot := (0,-0.05u) -- (0,0.05u);
		pickup PenC;
		distance := 0.2u;
		forever:
			t0 := arctime (cursor + elementSize * 1/8) of P;
			t1 := arctime (cursor + elementSize * 5/8) of P;
			t2 := arctime (cursor + elementSize * 7/8) of P;

			SBE_Ppb := (point t0 of P);
			SBE_Pdb := unitvector(thdir(P,t0));
			SBE_Pvb := SBE_Pdb rotated -90;
			SBE_Ppe := (point t1 of P);
			SBE_Pde := unitvector(thdir(P,t1));
			SBE_Pve := SBE_Pde rotated -90;

			if cursor > 0:
				thdraw (SBE_Ppb - distance * SBE_Pvb) -- (SBE_Ppe - distance * SBE_Pve);
			fi;

			thdraw SBE_Dot rotated (angle(thdir(P,t2))+90) shifted (point t2 of P + distance * unitvector(thdir(P,t2) rotated 90));

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


def l_joint_SBE(expr P) =
	T := identity;

	cursor := 0;
	totalLength := arclength P;
	elementSize := adjust_step(totalLength, u); % symbol length nudged to be multiple of path length
	pickup PenC;
	forever:
		t0 := arctime (cursor + elementSize * 3/22) of P;
		t1 := arctime (cursor + elementSize * 10/22) of P;
		t2 := arctime (cursor + elementSize * 16/22) of P;
		t3 := arctime (cursor + elementSize * 19/22) of P;

		thdraw (subpath (t0,t1) of P);
		thdraw (subpath (t2,t3) of P);

		cursor := cursor + elementSize;
		exitif cursor > totalLength - (elementSize / 2);
	endfor;
enddef;


def l_lowceiling_SBE(expr P) =
	begingroup
		path SBE_T;

		T := identity;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length
		SBE_T := (0,0) -- (0,-0.1u);
		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize * 1/7) of P;
			t2 := arctime (cursor + elementSize * 3/7) of P;
			t3 := arctime (cursor + elementSize * 4/7) of P;
			t4 := arctime (cursor + elementSize * 6/7) of P;

			thdraw (subpath (t1,t4) of P);
			thdraw SBE_T rotated (180+angle(thdir(P,t2))) shifted (point t2 of P);
			thdraw SBE_T rotated (180+angle(thdir(P,t3))) shifted (point t3 of P);

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


def l_pitchimney_SBE(expr P) =
	begingroup
		path SBE_Tsmall, SBE_Tlarge;

		T := identity;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length
		SBE_Tsmall := (0,0) -- (0,-0.1u);
		SBE_Tlarge := (0,0) -- (0,-0.175u);
		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize * 1/6) of P;
			t2 := arctime (cursor + elementSize * 2/6) of P;
			t3 := arctime (cursor + elementSize * 3/6) of P;
			t4 := arctime (cursor + elementSize * 4/6) of P;
			t5 := arctime (cursor + elementSize * 5/6) of P;

			thdraw (subpath (t1,t5) of P);

			thdraw SBE_Tsmall rotated (180+angle(thdir(P,t2))) shifted (point t2 of P);
			thdraw SBE_Tlarge rotated (180+angle(thdir(P,t3))) shifted (point t3 of P);
			thdraw SBE_Tsmall rotated (180+angle(thdir(P,t4))) shifted (point t4 of P);

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


def l_rimstonedam_SBE(expr P) =
	cas := 0;
	distance := arclength P;
	mystep := adjust_step(distance, 0.9u);
	pickup PenC;
	forever:
		t  := arctime (cas + mystep/2) of P;
		T := identity rotated angle(thdir(P,t)) scaled 0.7 shifted (point t of P);
		thdraw (-.45u,.2u){dir -80}..{dir -50}(-.15u,0){dir 30}..{dir -30}(.15u,.1u){dir -50}..{dir 70}(.45u,.2u);
		cas := cas + mystep;
		exitif cas > distance - (2*mystep/3); % for rounding errors
	endfor;
enddef;


def l_rimstonepool_SBE(expr P) =
	cas := 0;
	distance := arclength P;
	mystep := adjust_step(distance, 0.9u);
	pickup PenC;
	forever:
		t  := arctime (cas + mystep/2) of P;
		T := identity rotated angle(thdir(P,t)) scaled 0.7 shifted (point t of P);
		p := (-.45u,.2u){dir -80}..{dir -50}(-.15u,-.1u){dir 30}..{dir -30}(.15u,.1u){dir -50}..{dir 70}(.45u,.2u);
		thfill buildcycle(p,((.5u,.15u)--(-.5u,.15u)));
		thdraw p;
		cas := cas + mystep;
		exitif cas > distance - (2*mystep/3); % for rounding errors
	endfor;
enddef;


def l_walkway_SBE(expr P) =
	begingroup
		pair SBE_da, SBE_db, SBE_pa, SBE_pb, SBE_ta, SBE_tb, SBE_tc, SBE_td;

		T := identity;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.2u); % symbol length nudged to be multiple of path length
		distance := 0.1u;

		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize * 1/5) of P;
			t2 := arctime (cursor + elementSize * 4/5) of P;

			SBE_pa := point t1 of P;
			SBE_pb := point t2 of P;

			SBE_da := unitvector(thdir(P,t1)) * distance;
			SBE_db := unitvector(thdir(P,t2)) * distance;

			SBE_ta := SBE_pa + (SBE_da rotated 90);
			SBE_tb := SBE_pb + (SBE_db rotated 90);
			SBE_tc := SBE_pa + (SBE_da rotated -90);
			SBE_td := SBE_pb + (SBE_db rotated -90);

			thdraw SBE_ta -- SBE_tb;
			thdraw SBE_tc -- SBE_td;

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


%%%%%%%%%%%%%%%%%%%%%%%%% Areas %%%%%%%%%%%%%%%%%%%%%%%%%


picture SBE_a_mudcrack_raw;
SBE_a_mudcrack_raw := image(
	begingroup;
		interim linecap := butt;
		interim linejoin := mitered;
		pickup pencircle scaled 8bp;
		draw (172,466)--(225,425)--(271,440)
			--(323,390)--(346,423)--(414,363)
			--(390,275)--(414,281)--(438,322);
		pickup pencircle scaled 4bp;
		draw (244,252)--(232,272)--(308,293)
			--(257,310)--(266,357)--(291,380)
			--(303,428)--(282,477)--(393,502)
			--(380,518);
		pickup pencircle scaled 6bp;
		draw (172,466)--(244,518);
		pickup pencircle scaled 8bp;
		draw (173,322)--(205,357)--(244,322)
			--(266,357);
		pickup pencircle scaled 8bp;
		draw (380,252)--(364,292)--(380,322)
			--(346,423)--(417,491)--(393,502);
		pickup pencircle scaled 8bp;
		draw (437,466)--(417,491)--(380,392);
		currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (1.5u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
	endgroup;
);

beginpattern(pattern_mudcrack_SBE);
	draw SBE_a_mudcrack_raw;
endpattern;

def a_mudcrack_SBE(expr Path) =
	T := identity;
	thclean Path;
	thfill Path withpattern pattern_mudcrack_SBE;
enddef;


def pillar_main_SBE(expr P) =
	begingroup
		rgbcolor SBE_Orange;
		pair SBE_d, SBE_p;

		T := identity;

		SBE_Orange := (1, 0.6, 0);

		pickup PenD;
		thfill P withcolor SBE_Orange;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.01u); % symbol length nudged to be multiple of path length
		borderWidth := 0.3u;

		pickup PenA;
		forever:
			t1 := arctime (cursor + elementSize / 2) of P;

			SBE_p := point t1 of P;

			SBE_d := unitvector(thdir(P,t1)) * borderWidth;

			thdraw SBE_p -- SBE_p + (SBE_d rotated 90) withcolor white;;

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;

		pickup PenA;
		thdraw P withcolor SBE_Orange;
	endgroup;
enddef;

def a_pillar_SBE(expr P) =
	picture SBE_Pillar;

	SBE_Pillar := image(pillar_main_SBE(P));

	thdraw SBE_Pillar;
enddef;


def a_pillarwithcurtains_SBE(expr P) =
	begingroup
		picture SBE_Pillar;
		path SBE_Curtain;

		SBE_Pillar := image(pillar_main_SBE(P));

		thdraw SBE_Pillar;

		SBE_Curtain := (0,-.4u){dir 180}..(-0.1u,-0.3u)..{dir 0}(0,-0.2u)..(0.1u,-0.1u)..{dir -180}(0,0);
		SBE_Curtain := SBE_Curtain scaled (0.2 / 0.4);
		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length

		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize / 2) of P;

			thdraw SBE_Curtain rotated (180+angle(thdir(P,t1))) shifted (point t1 of P) withcolor (1,0.6,0);

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 3);
		endfor;
	endgroup;
enddef;


def a_stalactite_SBE(expr P) =
	T := identity;

	pickup PenA;
	thfill P withcolor (1, 0.9, 0.67);
	thdraw P withcolor (1, 0.6, 0);
enddef;


def a_stalactitestalagmite_SBE(expr P) =
	begingroup
		rgbcolor SBE_Orange, SBE_LightOrange;

		picture SBE_PicFill, SBE_PicDraw;
		path SBE_bboxP, SBE_clipFill, SBE_clipDraw;

		T := identity;

		SBE_LightOrange := (1, 0.9, 0.67);
		SBE_Orange := (1, 0.6, 0);
		SBE_bboxP := bbox P;
		SBE_clipFill := ulcorner SBE_bboxP -- llcorner SBE_bboxP -- lrcorner SBE_bboxP -- cycle;
		SBE_clipDraw := ulcorner SBE_bboxP -- urcorner SBE_bboxP -- lrcorner SBE_bboxP -- cycle;

		pickup PenA;
		thclean P;

		SBE_PicFill := image(
			fill P withcolor SBE_Orange;
			draw P withcolor SBE_Orange;
		);
		clip SBE_PicFill to SBE_clipFill;
		drawoptions();
		draw SBE_PicFill;

		SBE_PicDraw := image(
			fill P withcolor SBE_LightOrange;
			draw P withcolor SBE_Orange;
		);
		clip SBE_PicDraw to SBE_clipDraw;
		drawoptions();
		draw SBE_PicDraw;
	endgroup;
enddef;


def a_stalagmite_SBE(expr P) =
	T := identity;

	pickup PenA;
	thfill P withcolor (1, 0.6, 0);
enddef;



%%%%% ENDINPUT uSBE %%%%%






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
let p_altar = p_altar_SBE;
let p_archeoexcavation = p_archeoexcavation_SBE;
let p_audio = p_audio_SBE;
let p_bat = p_bat_SBE;
let p_bones = p_bones_SBE;
let p_curtains = p_curtains_UIS;
let p_danger = p_danger_SBE;
let p_discpillar = p_discpillar_UIS;
let p_discpillars = p_discpillars_UIS;
let p_discstalactites = p_discstalactites_UIS;
let p_discstalagmites = p_discstalagmites_UIS;
let p_discstalactite = p_discstalactite_UIS;
let p_discstalagmite = p_discstalagmite_UIS;
let p_electriclight = p_electriclight_SBE;
let p_exvoto = p_exvoto_SBE;
let p_gate = p_gate_SBE;
let p_helictites = p_helictites_UIS;
let p_humanbones = p_humanbones_SBE;
let p_masonry = p_masonry_SBE;
let p_minus = p_minus_UIS;
let p_mud = p_mud_SBE;
let p_mudcrack = p_mudcrack_SBE;
let p_nameplate = p_nameplate_SBE;
let p_nowheelchair = p_nowheelchair_SBE;
let p_pendant = p_pendant_SBE;
let p_pillarwithcurtains = p_pillarwithcurtains_UIS;
let p_pillarswithcurtains = p_pillarswithcurtains_UIS;
let p_photo = p_photo_SBE;
let p_plus = p_plus_UIS;
let p_plusminus = p_plusminus_UIS;
let p_seedgermination = p_seedgermination_SBE;
let p_stalactitestalagmite = p_stalactitestalagmite_UIS;
let p_stalactitesstalagmites = p_stalactitesstalagmites_UIS;
let p_treetrunk = p_treetrunk_SBE;
let p_volcano = p_volcano_SBE;
let p_walkway = p_walkway_SBE;
let p_waterdrip = p_waterdrip_SBE;
let p_wheelchair = p_wheelchair_SBE;
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
let l_abyssentrance = l_abyssentrance_SBE;
let l_dripline = l_dripline_SBE;
let l_fault = l_fault_SBE;
let l_joint = l_joint_SBE;
let l_lowceiling = l_lowceiling_SBE;
let l_pitchimney = l_pitchimney_SBE;
let l_rimstonedam = l_rimstonedam_SBE;
let l_rimstonepool = l_rimstonepool_SBE;
let l_walkway = l_walkway_SBE;

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
let a_mudcrack = a_mudcrack_SBE;
let a_pillar = a_pillar_SBE;
let a_pillarwithcurtains = a_pillarwithcurtains_SBE;
let a_stalactite = a_stalactite_SBE;
let a_stalactitestalagmite = a_stalactitestalagmite_SBE;
let a_stalagmite = a_stalagmite_SBE;

let s_northarrow = s_northarrow_SKBB;
let s_scalebar = s_scalebar_SKBB;
let s_hgrid = s_hgrid_SM;
let s_vgrid = s_vgrid_SM;
let s_altitudebar = s_altitudebar_SKBB;



%%%%% ENDINPUT thTrans %%%%%



nonstopmode;
initsymbol("s_altitudebar_SKBB");
initsymbol("s_hgrid_SM");
initsymbol("s_northarrow_SKBB");
initsymbol("s_scalebar_SKBB");
initsymbol("s_scalebar_SM");
initsymbol("s_vgrid_SM");
initsymbol("p_airdraught_AUT");
initsymbol("p_airdraught_UIS");
initsymbol("p_airdraught_summer_UIS");
initsymbol("p_airdraught_winter_UIS");
initsymbol("p_altar_SBE");
initsymbol("p_anastomosis_UIS");
initsymbol("p_anchor_SKBB");
initsymbol("p_aragonite_NSS");
initsymbol("p_archeoexcavation_SBE");
initsymbol("p_archeomaterial_UIS");
initsymbol("p_audio_SBE");
initsymbol("p_bat_SBE");
initsymbol("p_bedrock_ASF");
initsymbol("p_blocks_AUT");
initsymbol("p_blocks_UIS");
initsymbol("p_bones_SBE");
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
initsymbol("p_curtains_UIS");
initsymbol("p_danger_SBE");
initsymbol("p_debris_AUT");
initsymbol("p_debris_UIS");
initsymbol("p_dig_UIS");
initsymbol("p_discpillar_UIS");
initsymbol("p_discpillars_UIS");
initsymbol("p_discstalactite_UIS");
initsymbol("p_discstalactites_UIS");
initsymbol("p_discstalagmite_UIS");
initsymbol("p_discstalagmites_UIS");
initsymbol("p_disk_UIS");
initsymbol("p_electriclight_SBE");
initsymbol("p_entrance_AUT");
initsymbol("p_entrance_UIS");
initsymbol("p_exvoto_SBE");
initsymbol("p_fixedladder_SKBB");
initsymbol("p_flowstone_UIS");
initsymbol("p_flowstonechoke_NSS");
initsymbol("p_flute_UIS");
initsymbol("p_gate_SBE");
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
initsymbol("p_helictites_UIS");
initsymbol("p_humanbones_SBE");
initsymbol("p_ice_AUT");
initsymbol("p_ice_UIS");
initsymbol("p_icepillar_AUT");
initsymbol("p_icestalactite_AUT");
initsymbol("p_icestalagmite_AUT");
initsymbol("p_karren_UIS");
initsymbol("p_lowend_NSS");
initsymbol("p_lowend_UIS");
initsymbol("p_masonry_SBE");
initsymbol("p_minus_UIS");
initsymbol("p_moonmilk_UIS");
initsymbol("p_mud_SBE");
initsymbol("p_mudcrack_SBE");
initsymbol("p_nameplate_SBE");
initsymbol("p_narrowend_UIS");
initsymbol("p_noequipment_SKBB");
initsymbol("p_nowheelchair_SBE");
initsymbol("p_paleomaterial_UIS");
initsymbol("p_pebbles_AUT");
initsymbol("p_pebbles_UIS");
initsymbol("p_pendant_SBE");
initsymbol("p_photo_SBE");
initsymbol("p_pillar_AUT");
initsymbol("p_pillar_UIS");
initsymbol("p_pillars_UIS");
initsymbol("p_pillarswithcurtains_UIS");
initsymbol("p_pillarwithcurtains_UIS");
initsymbol("p_plus_UIS");
initsymbol("p_plusminus_UIS");
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
initsymbol("p_seedgermination_SBE");
initsymbol("p_sink_AUT");
initsymbol("p_sink_SKBB");
initsymbol("p_snow_SKBB");
initsymbol("p_sodastraw_UIS");
initsymbol("p_spring_AUT");
initsymbol("p_spring_SKBB");
initsymbol("p_stalactite_AUT");
initsymbol("p_stalactite_UIS");
initsymbol("p_stalactites_UIS");
initsymbol("p_stalactitesstalagmites_UIS");
initsymbol("p_stalactitestalagmite_UIS");
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
initsymbol("p_treetrunk_SBE");
initsymbol("p_vegetabledebris_ASF");
initsymbol("p_viaferrata_SKBB");
initsymbol("p_volcano_SBE");
initsymbol("p_walkway_SBE");
initsymbol("p_wallcalcite_UIS");
initsymbol("p_water_AUT");
initsymbol("p_water_UIS");
initsymbol("p_waterdrip_SBE");
initsymbol("p_waterflow_intermittent_UIS");
initsymbol("p_waterflow_paleo_UIS");
initsymbol("p_waterflow_permanent_UIS");
initsymbol("p_wheelchair_SBE");
initsymbol("l_abyssentrance_SBE");
initsymbol("l_arrow_SKBB");
initsymbol("l_border_presumed_SKBB");
initsymbol("l_border_temporary_SKBB");
initsymbol("l_border_visible_SKBB");
initsymbol("l_ceilingmeander_AUT");
initsymbol("l_ceilingmeander_NZSS");
initsymbol("l_ceilingmeander_SKBB");
initsymbol("l_ceilingmeander_UIS");
initsymbol("l_ceilingstep_AUT");
initsymbol("l_ceilingstep_NZSS");
initsymbol("l_ceilingstep_SKBB");
initsymbol("l_ceilingstep_UIS");
initsymbol("l_chimney_NZSS");
initsymbol("l_chimney_UIS");
initsymbol("l_contour_AUT");
initsymbol("l_contour_SKBB");
initsymbol("l_contour_UIS");
initsymbol("l_dripline_SBE");
initsymbol("l_fault_SBE");
initsymbol("l_fixedladder_SKBB");
initsymbol("l_floormeander_SKBB");
initsymbol("l_floorstep_AUT");
initsymbol("l_floorstep_UIS");
initsymbol("l_flowstone_AUT");
initsymbol("l_flowstone_UIS");
initsymbol("l_gradient_BCRA");
initsymbol("l_gradient_UIS");
initsymbol("l_handrail_SKBB");
initsymbol("l_joint_SBE");
initsymbol("l_lowceiling_SBE");
initsymbol("l_mapconnection_SKBB");
initsymbol("l_moonmilk_UIS");
initsymbol("l_overhang_AUT");
initsymbol("l_overhang_SKBB");
initsymbol("l_pit_AUT");
initsymbol("l_pit_UIS");
initsymbol("l_pitchimney_SBE");
initsymbol("l_rimstonedam_SBE");
initsymbol("l_rimstonepool_SBE");
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
initsymbol("l_walkway_SBE");
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
initsymbol("a_flowstone_AUT");
initsymbol("a_ice_AUT");
initsymbol("a_ice_SKBB");
initsymbol("a_moonmilk_SKBB");
initsymbol("a_mudcrack_SBE");
initsymbol("a_pebbles_AUT");
initsymbol("a_pebbles_SKBB");
initsymbol("a_pillar_SBE");
initsymbol("a_pillarwithcurtains_SBE");
initsymbol("a_sand_AUT");
initsymbol("a_sand_UIS");
initsymbol("a_snow_AUT");
initsymbol("a_snow_SKBB");
initsymbol("a_stalactite_SBE");
initsymbol("a_stalactitestalagmite_SBE");
initsymbol("a_stalagmite_SBE");
initsymbol("a_sump_AUT");
initsymbol("a_sump_SKBB");
initsymbol("a_sump_UIS");
initsymbol("a_water_AUT");
initsymbol("a_water_SKBB");
initsymbol("a_water_UIS");

background:=(0.00000,0.00000,0.20000,0.00000);
lang:="fr";
ATTR__elevation:=false;

% user defined symbols defaults
let p_u_bats = p_u;
def p_u_bats_legend = p_u_bats((0.5,0.5) inscale,0.0,1.0,(0,0)) enddef;
let p_u_boss = p_u;
def p_u_boss_legend = p_u_boss((0.5,0.5) inscale,0.0,1.0,(0,0)) enddef;
let l_u_rope = l_u;
def l_u_rope_legend = l_u_rope(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale) enddef;
let a_u_galerie = a_u;
def a_u_galerie_legend = a_u_galerie(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale))) enddef;
% end of user defined symbols

defaultfont:="cmss10";
NorthDir:="true";
includeprefix := "/Users/robertxaold/Documents/Speleo/Samoens/Samoens_Folly/Data/JB/JB/Data/Data-th/Crops_reseaux/Solitaire/../../../../../../../";
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
%<en> To write the scale "1:scale" uncomment it the next line:
%<fr> Pour écrire l'échelle "1:scale" au dessus de la barre décommenter la ligne suivante :
%label.top(thTEX("Echelle 1 : " & decimal (Scale*100)),(0,0));
endgroup;
enddef;
def l_wall_presumed (expr P) =
T:=identity;
pickup PenA;
thdraw P dashed evenly scaled (.1u);
enddef;
def l_chimney (expr P) =
T:=identity;
pickup PenC;
%thdraw P dashed evenly scaled optical_zoom;
thdraw P dashed evenly scaled (.05u);
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
def a_u_tronc (expr p) =
T:=identity;
thfill p withcolor (0.62, 0.24, 0.05);
enddef;
def a_u_feuilles (expr p) =
T:=identity;
thfill p withcolor (0.0, 1.0, 0.0);
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
label.urt(btex \thaltitude { m} etex, lrcorner txt);
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
def p_wallaltitude (expr pprev,pos,pnext,txt) =
rot:=angle(unitvector(pnext-pos)+unitvector(pos-pprev)) - 90;
pickup PenD;
pair zz;
%zz:=(pos + 3*unitvector(dir rot));
zz:=(pos + (u/4)*unitvector(dir rot));
%draw (pos)--zz withcolor (0.78, 0.08, 0.52); % tic in black
draw (pos)--zz withcolor (0.78, 0.08, 0.52); % tic in color
% add the unit (here, meters as m)
txtm:=image(
%draw txt; % altitude in black
draw txt withcolor (0.78, 0.08, 0.52); % altitude in color
%interim labeloffset:=0;
%label.urt(btex \thaltitude { m} etex, lrcorner txt); % unit in black
label.urt(btex \thaltitude { m} etex, lrcorner txt) withcolor (0.78, 0.08, 0.52); % unit in color
);
begingroup
%    interim labeloffset:=2pt;
interim labeloffset:=(u/12);
if horiz_labels:
rot:=rot mod 360;
if rot<=22.5: lab:=thelabel.rt(txtm, zz);
elseif rot<=67.5: lab:=thelabel.urt(txtm, zz);
elseif rot<=112.5: lab:=thelabel.top(txtm, zz);
elseif rot<=157.5: lab:=thelabel.ulft(txtm, zz);
elseif rot<=202.5: lab:=thelabel.lft(txtm, zz);
elseif rot<=247.5: lab:=thelabel.llft(txtm, zz);
elseif rot<=292.5: lab:=thelabel.bot(txtm, zz);
elseif rot<=337.5: lab:=thelabel.lrt(txtm, zz);
else: lab:=thelabel.rt(txtm, zz);
fi;
else:
if (abs rot>90) and (abs rot <=270):
rot:=rot-180;
lab:=thelabel.lft(txtm, pos);
else:
lab:=thelabel.rt(txtm, pos);
fi;
fi;
process_label(pos, if horiz_labels: 0 else: rot fi);
endgroup;
enddef;
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
def l_u_coupole (expr P) =
T:=identity;
cas := 0;                            % cursor to step along path
dlzka := arclength P;
mojkrok:=adjust_step(dlzka, 0.25u);  % symbol length nudged to be multiple of path length
q:= (0.10u,0.16u) -- (0.13u,0.17u);         % dot
pickup PenC;  %2nd thinnest pen
forever:
t := arctime cas of P;
thdraw q rotated angle(thdir(P,t)) shifted (point t of P ); % draw dots
cas := cas + mojkrok;
exitif cas > dlzka + (mojkrok / 3); % for rounding errors
endfor;
pickup PenC;   %2nd thickest pen
thdraw P;      %continuous line
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
def l_u_surf (expr P) =
T:=identity;
path Q; Q = punked P;
pickup PenC;
draw Q dashed evenly withcolor (0.5, 0, 0);
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
path bat_path_x;
bat_path_x := (160.43589,619.76148)
.. controls (200.83034,598.56215) and (225.01974,599.82632) .. (242.33709,601.15842)
.. controls (250.91988,585.02142) and (280.12279,545.7622) .. (328.92385,566.52372)
.. controls (343.18917,529.89929) and (387.77695,513.04018) .. (453.54702,518.36185)
.. controls (456.6654,525.97557) and (466.09064,533.43257) .. (471.27843,523.05007)
.. controls (463.85291,520.67657) and (466.71891,517.42483) .. (471.63814,522.23522)
.. controls (472.87859,519.83044) and (472.11254,517.25674) .. (467.00984,516.24193)
.. controls (498.08181,494.38071) and (518.37927,488.7935) .. (554.08261,484.34703)
.. controls (536.23968,468.87122) and (526.7451,451.32142) .. (536.0878,433.78585)
.. controls (539.04313,428.23891) and (549.65293,437.81051) .. (550.08905,431.99134)
.. controls (543.35122,428.68782) and (547.16851,429.31755) .. (550.93619,430.90592)
.. controls (555.01514,419.20795) and (542.29889,420.82043) .. (539.21019,422.32967)
.. controls (526.80565,412.03922) and (538.14174,362.22955) .. (562.04206,325.41289)
.. controls (560.70416,305.4475) and (552.94665,275.48765) .. (596.42383,240.15823)
.. controls (586.13796,214.86512) and (584.21841,176.344) .. (618.88684,158.99293)
.. controls (600.38363,161.42082) and (571.90452,163.00167) .. (555.87287,173.29962)
.. controls (533.80922,180.31406) and (511.7587,189.77279) .. (494.76462,217.75852)
.. controls (469.02274,260.15007) and (465.60841,280.08537) .. (466.27659,287.73284)
.. controls (467.27295,299.13663) and (456.20597,295.4343) .. (455.42733,284.84646)
.. controls (447.034,297.47822) and (465.71846,292.96944) .. (457.40227,311.17742)
.. controls (451.51715,333.88534) and (454.55183,344.68208) .. (455.22274,365.27634)
.. controls (445.59186,380.66207) and (438.52169,394.98144) .. (432.56329,406.97544)
.. controls (421.27321,411.75599) and (411.86904,413.85884) .. (403.92838,423.33244)
.. controls (391.19793,418.79449) and (380.875,414.46152) .. (373.6673,409.41976)
.. controls (365.11095,413.84661) and (372.76761,437.1554) .. (372.88328,437.30963)
-- (360.72573,447.88215)
.. controls (360.72573,447.88215) and (348.36583,439.38367) .. (342.32921,440.26049)
.. controls (340.52016,451.25937) and (343.58923,463.9528) .. (354.67087,475.2679)
.. controls (341.63825,482.57642) and (339.10347,494.24676) .. (313.80723,490.57484)
.. controls (304.61922,489.24114) and (282.31298,490.61764) .. (258.32359,496.84657)
.. controls (246.18809,499.99759) and (248.48311,482.8706) .. (236.36849,493.22467)
.. controls (239.32461,491.85429) and (242.55704,492.01948) .. (245.59044,495.64662)
.. controls (248.83726,499.52895) and (249.4495,502.08244) .. (244.59097,503.87878)
.. controls (221.93401,514.80409) and (190.83965,541.85436) .. (178.69512,574.11392)
.. controls (176.80431,577.00681) and (162.4873,600.33708) .. cycle;
path bat_path_bb;
bat_path_bb = bbox bat_path_x;
path bat_path;
bat_path = bat_path_x shifted (-(llcorner bat_path_bb) - (urcorner bat_path_bb - llcorner bat_path_bb) / 2.0) scaled (1u / ((xpart urcorner bat_path_bb) - (xpart llcorner bat_path_bb))) rotated 210;
def p_u_bats(expr pos, theta, sc, al) =
T := identity shifted pos;
thfill (bat_path scaled 1.5) withcolor black;
enddef;
def l_u_bats(expr P) =
T:=identity;
cas := 0;
dlzka := arclength P;
mojkrok:=adjust_step(dlzka, 1.0u);
pickup PenD;
forever:
t := arctime cas of P;
thfill bat_path scaled 0.5 shifted (point t of P) withcolor black;
cas := cas + mojkrok;
exitif cas > dlzka + (mojkrok / 3); % for rounding errors
endfor;
enddef;
% bat pattern
beginpattern(pattern_bat);
fill bat_path withcolor black;
endpattern;
% bat area symbol
def a_u_bats (expr Path) =
T:=identity;
thclean Path;
thfill Path withpattern pattern_bat;
enddef;
def l_u_bats_legend =
l_u_bats(((.2,.2) -- (.8,.8)) inscale)
enddef;
def p_u_boss (expr pos,theta,sc,al)=
T:=identity aligned al rotated theta scaled sc shifted pos;
pickup PenD;
p := (0.08u,0.25u)..(0,0.29u)..(-0.08u,0.25u);
q := (0.16u,0.5u)..(0u,0.58u)..(-0.16u,0.5u);
for i=0 upto 9:
thdraw p rotated 36i withcolor (100, 0.6, 0.2);
thdraw q rotated 36i withcolor (100, 0.6, 0.2);
% black color
%thdraw p rotated 36i;
%thdraw q rotated 36i;
endfor
p := fullcircle scaled 0.15u;
thdraw p withcolor (100, 0.6, 0.2);
% black color
%thdraw p withcolor;
enddef;
def p_u_shell (expr pos,theta,sc,al)=
T:=identity shifted pos;
pickup PenB;
numeric turns, radius;
path ss, cesta;
pair za, zb;
turns = 1.55;
radius = .3u;
za = ( xpart(origin)+0, ypart(origin)+.1u ) rotated 370 turns;
zb = ( xpart(origin)+.3u, ypart(origin)+0 ) rotated 360 turns;
cesta := za--zb;
ss := (origin for t=1 upto 360 turns: -- dir t scaled t endfor) scaled (radius/turns/360);
thdraw ss withcolor (0.3);
thdraw (cesta cutbefore ss) withcolor (0.6);
enddef;
initsymbol ("p_u_shell");
def p_u_danger (expr P,R,S,A)=
T:=identity aligned A rotated R scaled S shifted P;
thfill (0,-u)--(u,0)--(0,u)--(0,.9u)--(.9u,0)--(0,-.9u)--cycle;
thfill (0,-u)--(-u,0)--(0,u)--(0,.9u)--(-.9u,0)--(0,-.9u)--cycle;
thfill (.1u,-.45u)..(0,-.35u)..(-.1u,-.45u)..(0,-.55u)..cycle;
thfill (0,-.2u)..(.1u,-.1u)--(.2u,.4u)..(0,.6u)..(-.2u,.4u)--(-.1u,-.1u)..cycle;
enddef;
def l_u_ariane (expr Path) =
T:=identity;
pickup PenD;
draw Path withcolor (100, 0, 0);
enddef;
def l_u_plankwalk  (expr P) = T:=identity;
cas := 0;
dlzka := arclength P;
mojrok := adjust_step(dlzka, 0.5u);
pickup PenD;
forever:
t := arctime cas of P;
thdraw ((point t of P) + 0.5 * u * unitvector(thdir(P,t) rotated 90)) --
((point t of P) - 0.5 * u * unitvector(thdir(P,t) rotated 90) );
cas := cas + mojrok;
exitif cas > dlzka + (mojrok/3);  % for rounding errors
endfor;
pickup PenC;
%thdraw P;
%draw path withcolor (0.5, 0 ,0)
enddef;
def l_u_rail (expr P) =
T:=identity;
cas := 0;
dlzka := arclength P;
mojkrok:=adjust_step(dlzka, 0.8u);
pickup PenC;
forever:
t0 := arctime (cas) of P;
t1 := arctime (cas + mojkrok*2/5) of P;
t  := arctime (cas + mojkrok/2) of P;
t4 := arctime (cas + mojkrok*3/5) of P;
t5 := arctime (cas + mojkrok) of P;
thdraw (subpath (t0,t1) of P);
thdraw (subpath (t4,t5) of P);
drawdot
(point t of P);
cas := cas + mojkrok;
exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
endfor;
enddef;
def l_flowstone (expr p) =
T:=identity;
cas := 0;
dlzka := arclength p;
mojkrok:=adjust_step(dlzka, .3u);
pickup PenC;
t1:=0;
forever:
t2 := arctime (cas + mojkrok) of p;
thdraw (point t1 of p){dir (angle(thdir(p,t1)) + 60)} ..
{dir (angle(thdir(p,t2)) - 60)}(point t2 of p);
cas := cas + mojkrok;
exitif cas > dlzka + (mojkrok / 3); % for rounding errors
t1:=t2;
endfor;
enddef;
def p_u_nid (expr pos,theta,sc,al)=
U:=(.4u,.2u);
T:=identity aligned al rotated theta scaled sc shifted pos;
pickup PenC;
thdraw (-.2u,.1u){dir -70}..{dir 70}(.2u,.1u) withcolor (0.53, 0.26, 0.11);
enddef;
def p_u_anchor_artificial(expr pos,theta,sc,al) =
T:=identity shifted pos;
thdraw origin withpen pencircle scaled 0.25u withcolor (0.58, 0.44, 0.25);
enddef;
initsymbol ("p_u_anchor_artificial");
def p_u_anchor_natural(expr pos,theta,sc,al) =
U:=(.2u,.2u);
T:=identity aligned al rotated theta scaled sc shifted pos;
thfill (-.2u,-.2u)--(0,.2u)--(.2u,-.2u)--cycle withcolor (0.58, 0.44, 0.25);
enddef;
initsymbol ("p_u_anchor_natural");
def l_u_deviation (expr P) =
begingroup;
save ellipse;
T:=identity;
pickup PenC;
path ellipse;
ellipse:=fullcircle xscaled (.5u) yscaled (.25u) shifted (point (length P) of P);
thdraw P cutafter ellipse;
draw ellipse;
endgroup;
enddef;
initsymbol("l_u_deviation");
def l_u_deviation_legend =
l_u_deviation(((.1,.5)--(.8,.5)) inscale);
enddef;
picture u_man_c_pic;
u_man_c_pic := image (
draw (0cm, -0cm) -- (-8cm, 27cm) -- (-36cm, 55cm) -- (-50cm, 99cm) withpen pencircle scaled 16cm;
draw (27cm, 48cm) -- (0, 64cm) -- (-29cm, 61cm) -- (-38cm, 102cm)  withpen pencircle scaled 16cm;
draw (-65cm, 48cm) -- (-75cm, 75cm) -- (-53cm, 106cm) -- (0, 106cm) withpen pencircle scaled 14cm;
draw (-44cm, 130cm) withpen pencircle scaled 27cm withcolor black;
) shifted (20cm, -67cm);
def p_u_man_c (expr P, R, S, A) =
U := (60cm, 85cm) scaled (0.01 / Scale);
T:=identity aligned A rotated R scaled S shifted P;
thdraw u_man_c_pic scaled (0.01 / Scale);
enddef;
initsymbol ("p_u_man_c");
def p_u_man_c_legend =
draw u_man_c_pic scaled (u / 175cm) shifted ((.5, .5) inscale);
enddef;
picture u_man_w_pic;
u_man_w_pic := image (
draw (0, 0) -- (7.5cm, 36cm) -- (0cm, 69cm) -- (9cm, 99cm) withpen pencircle scaled 16cm;
draw (42cm, 9cm) -- (37.5cm, 42cm) -- (13.5cm, 69cm) -- (30cm, 102cm) withpen pencircle scaled 16cm;
draw (21.5cm, 100.5cm) -- (6.6cm, 69cm) withpen pencircle scaled 16cm;
draw (-24cm, 75cm) -- (-13.5cm, 102cm) -- (9cm, 112.5cm) -- (30cm, 108cm) -- (51cm, 87cm) -- (75cm, 93cm) withpen pencircle scaled 14cm;
draw (30cm, 132cm) withpen pencircle scaled 27cm withcolor black;
) shifted (-20cm, -70cm);
def p_u_man_w (expr P, R, S, A) =
U := (60cm, 80cm) scaled (0.01 / Scale);
T:=identity aligned A rotated R scaled S shifted P;
thdraw u_man_w_pic scaled (0.01 / Scale);
enddef;
initsymbol ("p_u_man_w");
def p_u_man_w_legend =
draw u_man_w_pic scaled (u / 175cm) shifted ((.5, .5) inscale);
enddef;
def p_u_symbol_plan (expr pos,theta,sc,al) =
U := (-3.25u, 3.25u);
T := identity aligned al rotated theta scaled sc shifted pos;
pickup PenB;
q := ((-3.26u, -.95u) -- (1.74u, -.95u) -- (2.8u, .82u) -- (-1.49u, .82u) -- cycle);
thfill q withcolor .85;
thdraw q;
q := ((-.175u, .5u) -- (0u, 0u) -- (.175u, .5u) .. (0u, .45u) .. cycle);
thfill q withcolor .5green;
thdraw q withcolor .5green;
thdraw (0u, 0u) -- (0u, 2.31u) withcolor .5green;
enddef;
def p_u_symbol_extend (expr pos,theta,sc,al) =
U := (-2.5u, 2.5u);
T := identity aligned al rotated theta scaled sc shifted pos;
pickup PenB;
q := ((-2.346u, -2.480u) -- (-.48u, -2.116u) -- (-.48u, 1.573u) -- (-2.346u, 1.354u) -- cycle);
thfill q withcolor .85;
q := ((-1.551u, -2.878u) -- (1.438u, -.766u) -- (1.438u, 2.388u) -- (-1.551u, 1.118u) -- cycle);
thfill q withcolor .75;
thdraw q;
thdraw (-.48u, -2.116u) -- (-.48u, 1.573u) dashed evenly;
q := ((.446u, -1.461u) -- (2.120u, -1.094u) -- (2.120u, 2.184u) -- (.446u, 1.965u) -- cycle);
thfill q withcolor .85;
thdraw (.446u, -1.461u) -- (.446u, 1.965u) dashed evenly;
q := ((-.175u, .5u) -- (0u, 0u) -- (.175u, .5u) .. (0u, .45u) .. cycle) rotated -90;
thfill q withcolor .5green;
thdraw q withcolor .5green;
thdraw (0u, 0u) -- (2.31u, 0u) withcolor .5green;
enddef;
def a_u_galerie(expr P) =
T:=identity;
thfill P withcolor (0.82,0.75,0.48) withalpha 0.5;
enddef;
def l_wall_unsurveyed (expr P) =
T:=identity;
pickup PenC;
thdraw P dashed evenly scaled (0.5*optical_zoom);
enddef;
def l_survey_cave (expr P) =
% always draws full centreline, rather than short stubs like default cave centrelines
T:=identity;
pickup PenC;
if ATTR__shotflag_splay:
drawoptions(withcolor(0.5,0.5,0.5) withpen PenD);
thdraw P; %  grey & thin
drawoptions();
else: % not splay but may have either or both duplicate and approx flags set
if ATTR__shotflag_duplicate:
drawoptions(withcolor (1,1,0)); % differentiate duplicate with colour yellow
fi;
if ATTR__shotflag_approx:
thdraw P dashed evenly scaled optical_zoom;	% differentiate approx with dashed
else:
thdraw P;
fi;
thdrawoptions();
fi;
enddef;
mapsymbol("p_station_temporary","SKBB",true);
mapsymbol("p_pillar","AUT",true);
mapsymbol("p_gradient","XA",true);
transparency:=true;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-Solitaire-2019c4";
ATTR__scrap := "SP-Solitaire-2019c4";
beginfig(1);
ATTR__height := -1;
drawoptions();
l_rockborder(((14.49,29.69)
 -- (13.95,27.89)
 -- (16.47,28.43)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((11.79,27.53)
 -- (11.43,25.91)
 -- (13.05,26.45)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((14.85,26.99)
 -- (13.05,26.45)
 -- (13.59,25.37)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((10.71,25.01)
 -- (11.79,23.93)
 -- (13.59,25.37)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_pit(((14.67,33.65)
 .. controls (15.57,30.77) and (20.97,29.15) .. (20.97,29.15)
));
ATTR__height := -1;
drawoptions();
l_pit(((-7.66,-2.53)
 .. controls (-7.66,-2.53) and (-2.08,-5.95) .. (-0.10,-3.79)
));
endfig;
beginfig(2);
draw_upscrap(1)(1,((17.37,33.29)
 .. controls (17.37,33.29) and (0.80,16.37) .. (-2.62,11.69)
 .. controls (-6.04,7.01) and (-5.50,5.39) .. (-5.32,3.77)
 .. controls (-5.14,2.15) and (-5.32,-3.97) .. (-6.76,-4.33)
 .. controls (-8.20,-4.69) and (-8.20,-3.61) .. (-8.20,-6.67)
 .. controls (-8.20,-9.73) and (-7.30,-17.46) .. (-8.20,-20.52)
 .. controls (-9.10,-23.57) and (-18.27,-40.49) .. (-18.27,-40.49)
),
1,((-11.98,-41.20)
 .. controls (-11.98,-41.20) and (-6.94,-25.73) .. (-6.40,-23.75)
 .. controls (-5.86,-21.78) and (-4.96,-19.08) .. (-4.24,-16.20)
 .. controls (-3.52,-13.32) and (-2.44,-8.29) .. (-2.44,-7.39)
 .. controls (-2.44,-6.49) and (-0.64,-2.35) .. (-1.90,-1.63)
 .. controls (-3.16,-0.91) and (-4.24,1.61) .. (-2.80,3.41)
 .. controls (-1.36,5.21) and (-0.46,7.91) .. (0.98,9.89)
 .. controls (2.42,11.87) and (13.23,24.47) .. (15.39,26.27)
 .. controls (17.55,28.07) and (19.71,31.31) .. (19.71,31.31)
));
draw_downscrap;
endfig;
beginfig(3);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((17.37,33.29)
 .. controls (17.37,33.29) and (0.80,16.37) .. (-2.62,11.69)
 .. controls (-6.04,7.01) and (-5.50,5.39) .. (-5.32,3.77)
 .. controls (-5.14,2.15) and (-5.32,-3.97) .. (-6.76,-4.33)
 .. controls (-8.20,-4.69) and (-8.20,-3.61) .. (-8.20,-6.67)
 .. controls (-8.20,-9.73) and (-7.30,-17.46) .. (-8.20,-20.52)
 .. controls (-9.10,-23.57) and (-18.27,-40.49) .. (-18.27,-40.49)
));
string ATTR_code;
ATTR_code := "P";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char80 \char54 \ \thfc\char184 \ \thfb\char100 \char101 \char115 \char99 \char101 \char110 \char100 \char114 \char101 \ \char59 \ \char82 \char101 \char106 \char111 \char105 \char110 \char116 \ \char108 \char39 \char97 \char99 \char116 \char105 \char102 \ \char100 \char117 \ \char83 \char111 \char108 \char105 \char116 \char97 \char105 \char114 \char101 \mainfont{}etex;
drawoptions();
p_continuation((29.80,41.20),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-11.98,-41.20)
 .. controls (-11.98,-41.20) and (-6.94,-25.73) .. (-6.40,-23.75)
 .. controls (-5.86,-21.78) and (-4.96,-19.08) .. (-4.24,-16.20)
 .. controls (-3.52,-13.32) and (-2.44,-8.29) .. (-2.44,-7.39)
 .. controls (-2.44,-6.49) and (-0.64,-2.35) .. (-1.90,-1.63)
 .. controls (-3.16,-0.91) and (-4.24,1.61) .. (-2.80,3.41)
 .. controls (-1.36,5.21) and (-0.46,7.91) .. (0.98,9.89)
 .. controls (2.42,11.87) and (13.23,24.47) .. (15.39,26.27)
 .. controls (17.55,28.07) and (19.71,31.31) .. (19.71,31.31)
));
ATTR__height := -1;
drawoptions();
l_arrow(((-15.58,13.13)
 .. controls (-15.58,13.13) and (-15.58,7.73) .. (-12.70,5.21)
 .. controls (-9.82,2.69) and (-7.30,3.23) .. (-7.30,3.23)
),2);
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
p_waterflow_permanent((21.70,37.07),150.1,1.00,(0,0));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-6.66,-19.87),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-5.25,-6.39),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-1.73,10.17),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((17.25,30.52),1,0,"");
endfig;
beginfig(4);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char54 \mainfont{} etex,(19.89,22.84),0.0,p_label_mode_height);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.ulft(btex \thaltitude \thfb\char45 \char49 \char54 \char57 \mainfont{} etex,(17.37,33.29),0.0,p_label_mode_altitude);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char99 \char104 \char97 \char116 \char105 \accent18 \char101 \char114 \char101 \mainfont{} etex,(-29.80,12.95),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char53 \mainfont{} etex,(-20.62,-1.27),0.0,p_label_mode_label);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-Solitaire2021-1";
ATTR__scrap := "SP-Solitaire2021-1";
beginfig(5);
current_src := "th2/solitaire-plan2021.th2 [85]";
string area_border[];
area_border[1] := "l18-821-373";
drawoptions();
a_blocks(buildcycle(((83.34,-0.54)
 .. controls (83.34,-0.54) and (83.70,24.66) .. (77.58,24.30)
 .. controls (71.46,23.94) and (44.64,-8.64) .. (44.64,-8.64)
 -- (38.52,-11.16)
 .. controls (38.52,-11.16) and (35.64,-20.16) .. (40.68,-20.52)
 .. controls (45.72,-20.88) and (83.34,-0.54) .. cycle
)));
ATTR__height := -1;
drawoptions();
l_pit(((30.60,-19.08)
 .. controls (30.60,-19.08) and (29.16,-12.06) .. (31.68,-9.72)
));
ATTR__height := -1;
drawoptions();
l_pit(((44.64,-8.64)
 .. controls (44.64,-8.64) and (43.38,-11.34) .. (38.52,-11.16)
));
endfig;
beginfig(6);
draw_upscrap(1)(1,((-88.38,-12.78)
 .. controls (-88.38,-12.78) and (-86.94,-10.44) .. (-85.68,-10.44)
 .. controls (-84.42,-10.44) and (-79.20,-8.46) .. (-77.76,-5.94)
 .. controls (-76.32,-3.42) and (-72.18,4.14) .. (-66.24,4.50)
 .. controls (-60.30,4.86) and (-43.38,4.32) .. (-38.34,3.96)
 .. controls (-33.30,3.60) and (-21.42,0.00) .. (-16.20,-1.44)
 .. controls (-10.98,-2.88) and (-6.30,-4.50) .. (-0.54,-6.48)
 .. controls (5.22,-8.46) and (25.38,-17.64) .. (30.60,-16.92)
 .. controls (35.82,-16.20) and (47.16,-15.48) .. (49.32,-14.40)
 .. controls (51.48,-13.32) and (56.70,-10.80) .. (62.64,-7.38)
 .. controls (68.58,-3.96) and (84.42,4.50) .. (87.48,7.56)
 .. controls (90.54,10.62) and (96.66,18.90) .. (96.66,18.90)
),
1,((91.44,20.70)
 .. controls (91.44,20.70) and (78.84,25.20) .. (72.72,20.16)
 .. controls (66.60,15.12) and (57.96,-4.32) .. (53.64,-5.40)
 .. controls (49.32,-6.48) and (46.44,-9.00) .. (44.64,-8.64)
),
1,((38.52,-11.16)
 .. controls (38.52,-11.16) and (33.48,-10.08) .. (31.68,-9.72)
 .. controls (29.88,-9.36) and (13.32,-2.88) .. (7.56,-0.36)
 .. controls (1.80,2.16) and (1.08,3.42) .. (-4.86,3.78)
 .. controls (-5.40,3.81) and (-4.86,0.72) .. (-6.84,0.90)
 .. controls (-8.82,1.08) and (-18.18,5.22) .. (-21.78,5.94)
 .. controls (-25.38,6.66) and (-29.16,5.94) .. (-33.48,6.66)
 .. controls (-37.80,7.38) and (-43.92,10.08) .. (-50.22,9.72)
 .. controls (-56.52,9.36) and (-68.58,8.64) .. (-71.82,6.30)
 .. controls (-75.06,3.96) and (-80.64,-0.90) .. (-82.80,-3.78)
 .. controls (-84.96,-6.66) and (-90.00,-11.52) .. (-90.00,-11.52)
));
draw_downscrap;
endfig;
beginfig(7);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((91.44,20.70)
 .. controls (91.44,20.70) and (78.84,25.20) .. (72.72,20.16)
 .. controls (66.60,15.12) and (57.96,-4.32) .. (53.64,-5.40)
 .. controls (49.32,-6.48) and (46.44,-9.00) .. (44.64,-8.64)
));
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
p_waterflow_permanent((42.84,-3.96),189.6,1.00,(0,0));
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
p_waterflow_permanent((12.06,2.88),158.4,1.00,(0,0));
drawoptions();
p_claytree((1.98,0.90),0.0,1.00,(0,0));
drawoptions();
p_claytree((4.86,-1.26),0.0,1.00,(0,0));
drawoptions();
p_claytree((9.00,-3.24),0.0,1.00,(0,0));
drawoptions();
p_breakdownchoke((-14.58,2.16),341.6,1.00,(0,0));
drawoptions();
p_breakdownchoke((-18.72,4.32),341.6,1.00,(0,0));
drawoptions();
p_breakdownchoke((-10.62,-1.62),165.4,1.00,(0,0));
drawoptions();
p_breakdownchoke((-50.40,5.94),180.7,1.00,(0,0));
drawoptions();
p_narrowend((-92.16,-14.40),0.0,1.00,(0,0));
drawoptions();
p_airdraught_summer((-93.96,-7.38),320.7,1.00,(0,0));
string ATTR_code;
ATTR_code := "D";
string ATTR_cavite;
ATTR_cavite := "Jean-Bernard";
string ATTR_ca;
ATTR_ca := "Courant d'air soufflant en Ã©tÃ©";
string ATTR_reseau;
ATTR_reseau := "Jean-Bernard";
picture ATTR__text;
ATTR__text := btex \thcomment \thfc\char233 \thfb\char116 \char114 \char111 \char105 \char116 \char117 \char114 \char101 \ \thfc\char184 \ \thfb\char100 \char121 \char110 \char97 \char109 \char105 \char116 \char101 \char114 \mainfont{}etex;
drawoptions();
p_continuation((-96.66,-20.88),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
save ATTR_cavite;
save ATTR_ca;
save ATTR_reseau;
drawoptions();
p_traverse((95.58,8.28),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((38.52,-11.16)
 .. controls (38.52,-11.16) and (33.48,-10.08) .. (31.68,-9.72)
 .. controls (29.88,-9.36) and (13.32,-2.88) .. (7.56,-0.36)
 .. controls (1.80,2.16) and (1.08,3.42) .. (-4.86,3.78)
 .. controls (-5.40,3.81) and (-4.86,0.72) .. (-6.84,0.90)
 .. controls (-8.82,1.08) and (-18.18,5.22) .. (-21.78,5.94)
 .. controls (-25.38,6.66) and (-29.16,5.94) .. (-33.48,6.66)
 .. controls (-37.80,7.38) and (-43.92,10.08) .. (-50.22,9.72)
 .. controls (-56.52,9.36) and (-68.58,8.64) .. (-71.82,6.30)
 .. controls (-75.06,3.96) and (-80.64,-0.90) .. (-82.80,-3.78)
 .. controls (-84.96,-6.66) and (-90.00,-11.52) .. (-90.00,-11.52)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-88.38,-12.78)
 .. controls (-88.38,-12.78) and (-86.94,-10.44) .. (-85.68,-10.44)
 .. controls (-84.42,-10.44) and (-79.20,-8.46) .. (-77.76,-5.94)
 .. controls (-76.32,-3.42) and (-72.18,4.14) .. (-66.24,4.50)
 .. controls (-60.30,4.86) and (-43.38,4.32) .. (-38.34,3.96)
 .. controls (-33.30,3.60) and (-21.42,0.00) .. (-16.20,-1.44)
 .. controls (-10.98,-2.88) and (-6.30,-4.50) .. (-0.54,-6.48)
 .. controls (5.22,-8.46) and (25.38,-17.64) .. (30.60,-16.92)
 .. controls (35.82,-16.20) and (47.16,-15.48) .. (49.32,-14.40)
 .. controls (51.48,-13.32) and (56.70,-10.80) .. (62.64,-7.38)
 .. controls (68.58,-3.96) and (84.42,4.50) .. (87.48,7.56)
 .. controls (90.54,10.62) and (96.66,18.90) .. (96.66,18.90)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((94.86,19.52),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((86.49,8.81),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((55.53,-9.80),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((45.44,-14.08),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((31.75,-11.91),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-4.67,-2.83),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-22.29,2.89),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-33.90,4.53),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-50.25,7.71),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-70.72,5.55),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-79.76,-3.49),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-88.08,-10.72),1,0,"");
endfig;
beginfig(8);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.lrt(btex \thaltitude \thfb\char45 \char49 \char54 \char57 \mainfont{} etex,(-88.38,-12.78),0.0,p_label_mode_altitude);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{\hfil#\hfil\cr\thfb\char115 \char97 \char108 \char108 \char101 \ \char100 \char101 \char115 \cr\thfb \char83 \char97 \char112 \char105 \char110 \char115 \ \char100 \char39 \char65 \char114 \char103 \char105 \char108 \char101 \cr}}\mainfont{} etex,(18.72,23.40),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char55 \mainfont{} etex,(46.08,-21.24),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char49 \char48 \mainfont{} etex,(30.42,-25.20),0.0,p_label_mode_height);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-Solitaire-2019c3";
ATTR__scrap := "SP-Solitaire-2019c3";
beginfig(9);
current_src := "th2/solitaire2019_3.th2 [153]";
string area_border[];
area_border[1] := "l35-410-386";
drawoptions();
a_blocks(buildcycle(((28.16,-1.52)
 .. controls (28.16,-1.52) and (17.89,12.52) .. (13.93,9.46)
 .. controls (9.97,6.39) and (2.59,4.23) .. (2.95,1.71)
 .. controls (3.31,-0.81) and (14.29,-15.93) .. (16.63,-13.95)
 .. controls (18.98,-11.96) and (28.16,-1.52) .. cycle
)));
drawoptions();
p_pebbles((17.92,47.43),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_pit(((0.61,-2.79)
 .. controls (0.61,-2.79) and (-1.54,-20.96) .. (-8.56,-21.86)
));
ATTR__height := -1;
drawoptions();
l_pit(((-1.54,-28.34)
 .. controls (-1.54,-28.34) and (0.80,-13.41) .. (2.24,-13.23)
 .. controls (3.67,-13.05) and (5.11,-9.81) .. (6.01,-10.89)
 .. controls (6.91,-11.97) and (9.97,-15.57) .. (9.97,-15.57)
));
ATTR__height := -1;
drawoptions();
l_pit(((-4.94,-39.32)
 .. controls (-4.94,-39.32) and (-17.18,-36.62) .. (-16.10,-38.96)
 .. controls (-15.02,-41.30) and (-12.32,-48.50) .. (-9.98,-46.70)
 .. controls (-7.64,-44.90) and (-4.94,-39.32) .. cycle
));
endfig;
beginfig(10);
draw_upscrap(1)(1,((-22.77,-55.35)
 .. controls (-22.77,-55.35) and (-20.06,-56.07) .. (-16.64,-51.93)
 .. controls (-13.22,-47.78) and (-9.26,-44.36) .. (-7.64,-39.86)
 .. controls (-6.02,-35.36) and (-3.52,-25.64) .. (-1.00,-23.48)
 .. controls (1.52,-21.32) and (2.06,-13.23) .. (5.11,-13.59)
 .. controls (8.17,-13.95) and (15.74,-9.63) .. (18.62,-6.93)
 .. controls (21.50,-4.22) and (22.40,0.46) .. (26.36,4.06)
 .. controls (30.32,7.66) and (33.73,9.47) .. (33.74,14.86)
 .. controls (33.74,20.26) and (38.25,29.24) .. (33.04,34.46)
 .. controls (27.82,39.68) and (11.26,56.07) .. (11.26,56.07)
),
1,((6.94,51.21)
 .. controls (6.94,51.21) and (29.08,35.90) .. (29.62,29.97)
 .. controls (30.15,24.04) and (32.84,15.40) .. (28.52,12.34)
 .. controls (24.19,9.28) and (19.69,10.54) .. (16.63,8.38)
 .. controls (13.57,6.22) and (4.57,2.07) .. (2.05,-2.61)
 .. controls (-0.46,-7.29) and (-6.22,-18.81) .. (-8.73,-24.20)
 .. controls (-11.25,-29.60) and (-11.78,-37.16) .. (-15.56,-41.30)
 .. controls (-19.34,-45.44) and (-26.37,-50.31) .. (-26.37,-50.31)
));
draw_downscrap;
endfig;
beginfig(11);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((6.94,51.21)
 .. controls (6.94,51.21) and (29.08,35.90) .. (29.62,29.97)
 .. controls (30.15,24.04) and (32.84,15.40) .. (28.52,12.34)
 .. controls (24.19,9.28) and (19.69,10.54) .. (16.63,8.38)
 .. controls (13.57,6.22) and (4.57,2.07) .. (2.05,-2.61)
 .. controls (-0.46,-7.29) and (-6.22,-18.81) .. (-8.73,-24.20)
 .. controls (-11.25,-29.60) and (-11.78,-37.16) .. (-15.56,-41.30)
 .. controls (-19.34,-45.44) and (-26.37,-50.31) .. (-26.37,-50.31)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-22.77,-55.35)
 .. controls (-22.77,-55.35) and (-20.06,-56.07) .. (-16.64,-51.93)
 .. controls (-13.22,-47.78) and (-9.26,-44.36) .. (-7.64,-39.86)
 .. controls (-6.02,-35.36) and (-3.52,-25.64) .. (-1.00,-23.48)
 .. controls (1.52,-21.32) and (2.06,-13.23) .. (5.11,-13.59)
 .. controls (8.17,-13.95) and (15.74,-9.63) .. (18.62,-6.93)
 .. controls (21.50,-4.22) and (22.40,0.46) .. (26.36,4.06)
 .. controls (30.32,7.66) and (33.73,9.47) .. (33.74,14.86)
 .. controls (33.74,20.26) and (38.25,29.24) .. (33.04,34.46)
 .. controls (27.82,39.68) and (11.26,56.07) .. (11.26,56.07)
));
drawoptions();
p_traverse((9.08,-22.58),0.0,1.00,(0,0));
drawoptions();
p_breakdownchoke((-25.11,-53.01),302.6,1.00,(0,0));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((30.93,31.85),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((31.96,12.23),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((3.69,-4.09),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-7.15,-24.49),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-11.06,-41.38),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-20.72,-51.05),1,0,"");
endfig;
beginfig(12);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{\hfil#\hfil\cr\thfb\char112 \char117 \char105 \char116 \char115 \ \char100 \char117 \cr\thfb \char67 \char111 \char109 \char112 \char108 \char101 \char120 \char101 \cr}}\mainfont{} etex,(-38.25,-26.19),0.0,p_label_mode_label);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.ulft(btex \thaltitude \thfb\char45 \char49 \char53 \char55 \mainfont{} etex,(-26.37,-50.31),0.0,p_label_mode_altitude);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char49 \char49 \mainfont{} etex,(1.72,-45.44),0.0,p_label_mode_height);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-Solitaire2021-2";
ATTR__scrap := "SP-Solitaire2021-2";
beginfig(13);
ATTR__height := -1;
drawoptions();
l_pit(((-20.97,3.60)
 .. controls (-20.97,3.60) and (-18.09,1.08) .. (-17.91,2.16)
 .. controls (-17.73,3.24) and (-18.09,4.68) .. (-18.09,4.68)
));
endfig;
beginfig(14);
draw_upscrap(1)(1,((30.15,-10.62)
 .. controls (30.15,-10.62) and (27.99,-12.60) .. (25.65,-11.88)
 .. controls (23.31,-11.16) and (23.31,-10.98) .. (20.07,-7.56)
 .. controls (16.83,-4.14) and (16.65,-0.36) .. (13.05,-1.98)
 .. controls (9.45,-3.60) and (3.15,-4.68) .. (1.35,-7.74)
 .. controls (-0.45,-10.80) and (-0.99,-14.94) .. (-4.05,-12.06)
 .. controls (-7.11,-9.18) and (-18.09,4.68) .. (-18.09,4.68)
),
1,((-20.97,3.60)
 .. controls (-20.97,3.60) and (-4.23,-20.88) .. (-2.43,-21.06)
 .. controls (-0.63,-21.24) and (0.81,-22.14) .. (2.25,-18.54)
 .. controls (3.69,-14.94) and (8.01,-3.60) .. (12.69,-6.30)
 .. controls (17.37,-9.00) and (16.47,-10.26) .. (20.43,-12.06)
 .. controls (24.39,-13.86) and (24.03,-13.14) .. (24.03,-13.14)
));
draw_downscrap;
endfig;
beginfig(15);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((30.15,-10.62)
 .. controls (30.15,-10.62) and (27.99,-12.60) .. (25.65,-11.88)
 .. controls (23.31,-11.16) and (23.31,-10.98) .. (20.07,-7.56)
 .. controls (16.83,-4.14) and (16.65,-0.36) .. (13.05,-1.98)
 .. controls (9.45,-3.60) and (3.15,-4.68) .. (1.35,-7.74)
 .. controls (-0.45,-10.80) and (-0.99,-14.94) .. (-4.05,-12.06)
 .. controls (-7.11,-9.18) and (-18.09,4.68) .. (-18.09,4.68)
));
string ATTR_code;
ATTR_code := "P";
string ATTR_cavite;
ATTR_cavite := "Jean-Bernard";
string ATTR_ca;
ATTR_ca := "Courant d'air";
string ATTR_reseau;
ATTR_reseau := "Jean-Bernard";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char65 \char114 \char114 \accent94 \char101 \char116 \ \char115 \char117 \char114 \ \char80 \char49 \char48 \char47 \char49 \char53 \ \thfc\char184 \ \char233 \thfb\char113 \char117 \char105 \char112 \char101 \char114 \mainfont{}etex;
drawoptions();
p_continuation((-21.87,9.72),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
save ATTR_cavite;
save ATTR_ca;
save ATTR_reseau;
drawoptions();
p_airdraught_summer((-30.15,22.14),205.6,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-20.97,3.60)
 .. controls (-20.97,3.60) and (-4.23,-20.88) .. (-2.43,-21.06)
 .. controls (-0.63,-21.24) and (0.81,-22.14) .. (2.25,-18.54)
 .. controls (3.69,-14.94) and (8.01,-3.60) .. (12.69,-6.30)
 .. controls (17.37,-9.00) and (16.47,-10.26) .. (20.43,-12.06)
 .. controls (24.39,-13.86) and (24.03,-13.14) .. (24.03,-13.14)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((28.69,-13.73),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((21.69,-11.46),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((14.48,-2.87),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((3.87,-7.59),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-1.02,-19.69),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-16.64,0.30),1,0,"");
endfig;
beginfig(16);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.top(btex \thaltitude \thfb\char45 \char49 \char52 \char50 \mainfont{} etex,(-18.09,4.68),0.0,p_label_mode_altitude);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-Solitaire-2019c2";
ATTR__scrap := "SP-Solitaire-2019c2";
beginfig(17);
ATTR__height := -1;
drawoptions();
l_pit(((14.38,-7.01)
 .. controls (14.38,-7.01) and (20.32,-8.46) .. (21.05,0.90)
));
endfig;
beginfig(18);
draw_upscrap(1)(1,((-20.52,-7.55)
 .. controls (-20.52,-7.55) and (-21.96,10.08) .. (-18.72,12.78)
 .. controls (-15.48,15.48) and (-13.14,16.38) .. (-8.11,15.30)
 .. controls (-3.07,14.23) and (8.63,10.10) .. (13.13,9.38)
 .. controls (17.63,8.66) and (18.70,-1.98) .. (20.51,-1.26)
 .. controls (22.31,-0.54) and (24.65,1.44) .. (24.65,1.44)
),
1,((26.98,-7.03)
 .. controls (26.98,-7.03) and (18.69,-11.88) .. (15.82,-6.30)
 .. controls (12.94,-0.71) and (16.37,1.81) .. (10.97,2.72)
 .. controls (5.57,3.62) and (-9.18,12.25) .. (-11.16,8.29)
 .. controls (-13.14,4.33) and (-12.60,-6.65) .. (-13.14,-7.55)
 .. controls (-13.68,-8.44) and (-13.32,-10.42) .. (-13.32,-10.42)
));
draw_downscrap;
endfig;
beginfig(19);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-20.52,-7.55)
 .. controls (-20.52,-7.55) and (-21.96,10.08) .. (-18.72,12.78)
 .. controls (-15.48,15.48) and (-13.14,16.38) .. (-8.11,15.30)
 .. controls (-3.07,14.23) and (8.63,10.10) .. (13.13,9.38)
 .. controls (17.63,8.66) and (18.70,-1.98) .. (20.51,-1.26)
 .. controls (22.31,-0.54) and (24.65,1.44) .. (24.65,1.44)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((26.98,-7.03)
 .. controls (26.98,-7.03) and (18.69,-11.88) .. (15.82,-6.30)
 .. controls (12.94,-0.71) and (16.37,1.81) .. (10.97,2.72)
 .. controls (5.57,3.62) and (-9.18,12.25) .. (-11.16,8.29)
 .. controls (-13.14,4.33) and (-12.60,-6.65) .. (-13.14,-7.55)
 .. controls (-13.68,-8.44) and (-13.32,-10.42) .. (-13.32,-10.42)
));
string ATTR_code;
ATTR_code := "E";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char80 \char117 \char105 \char116 \char115 \ \char114 \char101 \char109 \char111 \char110 \char116 \char97 \char110 \char116 \ \char100 \char101 \ \char49 \char49 \ \char109 \ \thfc\char184 \ \thfb\char101 \char115 \char99 \char97 \char108 \char97 \char100 \char101 \char114 \ \char59 \ \ \char82 \char101 \char106 \char111 \char105 \char110 \char116 \ \char112 \char101 \char117 \char116 \char45 \accent94 \char101 \char116 \char114 \char101 \ \char108 \char101 \ \char112 \char111 \char105 \char110 \char116 \ \char50 \char48 \char49 \char57 \char45 \char70 \char68 \char45 \char53 \char54 \char50 \mainfont{}etex;
drawoptions();
p_continuation((31.49,-0.91),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-14.90,11.68),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((13.41,5.15),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((19.81,-3.34),1,0,"");
endfig;
beginfig(20);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char49 \char51 \mainfont{} etex,(-31.49,-5.75),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char49 \char49 \mainfont{} etex,(17.79,-16.38),0.0,p_label_mode_height);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-Solitaire-2019c1";
ATTR__scrap := "SP-Solitaire-2019c1";
beginfig(21);
current_src := "th2/solitaire2019_3.th2 [25]";
string area_border[];
area_border[1] := "l9-394-650";
drawoptions();
a_blocks(buildcycle(((28.24,15.81)
 .. controls (28.24,15.81) and (-12.18,20.74) .. (-12.20,12.43)
 .. controls (-12.21,4.15) and (-1.99,-18.63) .. (1.25,-18.61)
 .. controls (4.48,-18.58) and (17.28,-16.07) .. (21.42,-13.09)
 .. controls (25.55,-10.12) and (28.24,15.81) .. cycle
)));
ATTR__height := -1;
drawoptions();
l_pit(((27.51,18.47)
 .. controls (27.51,18.47) and (8.94,17.80) .. (6.65,20.91)
));
ATTR__height := -1;
drawoptions();
l_pit(((-0.37,-10.72)
 .. controls (-0.37,-10.72) and (8.44,-17.86) .. (8.81,-11.02)
 .. controls (9.17,-4.26) and (1.45,-3.65) .. (1.45,-3.65)
));
ATTR__height := -1;
drawoptions();
l_pit(((26.01,8.69)
 .. controls (26.01,8.69) and (20.00,15.47) .. (19.04,18.02)
));
endfig;
beginfig(22);
draw_upscrap(1)(1,((15.79,20.45)
 .. controls (15.79,20.45) and (11.18,22.66) .. (10.59,20.13)
 .. controls (9.88,17.04) and (3.10,7.31) .. (2.90,2.13)
 .. controls (2.70,-3.11) and (0.72,-13.56) .. (2.69,-16.06)
 .. controls (4.67,-18.58) and (12.96,-24.85) .. (12.96,-24.85)
),
1,((17.28,-20.00)
 .. controls (17.28,-20.00) and (10.07,-15.88) .. (11.87,-14.28)
 .. controls (13.67,-12.68) and (22.31,-7.93) .. (22.49,-2.94)
 .. controls (22.67,1.91) and (25.38,20.13) .. (24.80,21.54)
));
draw_downscrap;
endfig;
beginfig(23);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((15.79,20.45)
 .. controls (15.79,20.45) and (11.18,22.66) .. (10.59,20.13)
 .. controls (9.88,17.04) and (3.10,7.31) .. (2.90,2.13)
 .. controls (2.70,-3.11) and (0.72,-13.56) .. (2.69,-16.06)
 .. controls (4.67,-18.58) and (12.96,-24.85) .. (12.96,-24.85)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((17.28,-20.00)
 .. controls (17.28,-20.00) and (10.07,-15.88) .. (11.87,-14.28)
 .. controls (13.67,-12.68) and (22.31,-7.93) .. (22.49,-2.94)
 .. controls (22.67,1.91) and (25.38,20.13) .. (24.80,21.54)
));
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
p_waterflow_permanent((9.26,24.85),206.3,1.00,(0,0));
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
p_waterflow_permanent((22.13,3.62),206.3,1.00,(0,0));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((15.00,-2.60),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((6.37,-13.64),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((13.44,19.70),1,0,"");
endfig;
beginfig(24);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char116 \char114 \thfc\char233 \thfb\char109 \char105 \char101 \mainfont{} etex,(-28.24,7.16),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char50 \char48 \mainfont{} etex,(-4.05,21.88),0.0,p_label_mode_height);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-Sol_2019b_1";
ATTR__scrap := "SP-Sol_2019b_1";
beginfig(25);
current_src := "th2/solitaire2019_1.th2 [372]";
string area_border[];
area_border[1] := "l135-64-54";
drawoptions();
a_blocks(buildcycle(((-67.87,16.36)
 .. controls (-67.87,16.36) and (-68.77,14.73) .. (-67.15,13.64)
 .. controls (-60.99,9.48) and (-52.57,-2.85) .. (-44.82,-2.68)
 .. controls (-37.07,-2.52) and (-22.50,-1.53) .. (-21.24,2.60)
 .. controls (-19.98,6.74) and (-12.05,19.87) .. (-15.11,19.68)
 .. controls (-18.18,19.48) and (-38.51,21.35) .. (-47.16,21.37)
 .. controls (-55.80,21.39) and (-67.87,16.36) .. cycle
)));
ATTR__height := -1;
drawoptions();
l_rockborder(((-55.99,-7.37)
 -- (-58.33,-9.52)
 -- (-55.99,-10.62)
 -- (-55.27,-8.62)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-59.59,-13.51)
 -- (-59.23,-16.61)
 -- (-56.17,-16.67)
 -- (-55.81,-13.91)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-53.11,-15.92)
 -- (-53.11,-20.26)
 -- (-50.40,-19.99)
 -- (-50.59,-17.32)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_pit(((-23.40,46.32)
 .. controls (-23.40,46.32) and (-27.90,39.66) .. (-36.36,41.10)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-29.34,44.33)
 -- (-27.36,44.69)
 -- (-27.36,47.39)
 -- (-30.42,47.38)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_pit(((-39.97,90.40)
 .. controls (-39.97,90.40) and (-47.88,88.43) .. (-54.71,92.93)
));
ATTR__height := -1;
drawoptions();
l_pit(((-34.21,77.09)
 .. controls (-34.21,77.09) and (-45.19,71.69) .. (-50.59,73.86)
));
ATTR__height := -1;
drawoptions();
l_pit(((-44.49,-39.54)
 .. controls (-44.49,-39.54) and (-57.80,-46.94) .. (-60.66,-41.10)
));
ATTR__height := -1;
drawoptions();
l_pit(((-3.59,-54.51)
 .. controls (-3.59,-54.51) and (-16.36,-46.83) .. (-16.19,-41.66)
));
ATTR__height := -1;
drawoptions();
l_pit(((-52.57,-3.60)
 .. controls (-52.57,-3.60) and (-63.37,4.74) .. (-65.89,10.55)
));
ATTR__height := -1;
drawoptions();
l_slope(((-22.14,-2.42)
 .. controls (-22.14,-2.42) and (-24.30,-7.44) .. (-29.87,-7.41)
),0,(0,-1,3.60004),(1,-1,3.60004));
ATTR__height := -1;
drawoptions();
l_slope(((-14.76,-8.52)
 .. controls (-14.76,-8.52) and (-19.80,-13.98) .. (-25.91,-13.90)
),0,(0,-1,3.60004),(1,-1,3.60004));
ATTR__height := -1;
drawoptions();
l_slope(((-8.99,-17.67)
 .. controls (-13.85,-19.85) and (-16.01,-23.76) .. (-22.31,-22.83)
),0,(0,-1,3.60004),(1,-1,3.60004));
ATTR__height := -1;
drawoptions();
l_slope(((-3.05,-22.68)
 .. controls (-3.05,-22.68) and (-16.01,-35.19) .. (-20.14,-33.11)
),0,(0,-1,3.60004),(1,-1,3.60004));
endfig;
beginfig(26);
draw_upscrap(1)(1,((75.62,-65.59)
 .. controls (75.62,-65.59) and (70.20,-83.31) .. (64.63,-79.52)
 .. controls (59.04,-75.72) and (42.48,-67.42) .. (37.81,-58.80)
 .. controls (33.11,-50.15) and (33.10,-44.59) .. (28.43,-39.73)
 .. controls (23.75,-34.87) and (25.01,-33.26) .. (17.99,-31.98)
 .. controls (10.97,-30.69) and (7.92,-36.78) .. (-0.36,-29.55)
 .. controls (-8.63,-22.33) and (-11.53,-18.78) .. (-15.48,-13.24)
 .. controls (-19.46,-7.65) and (-28.43,-0.49) .. (-25.02,4.01)
 .. controls (-21.59,8.53) and (-16.56,18.05) .. (-18.71,22.54)
 .. controls (-20.88,27.06) and (-25.74,47.93) .. (-26.64,49.01)
 .. controls (-27.54,50.09) and (-29.16,45.76) .. (-31.50,52.42)
 .. controls (-33.84,59.07) and (-35.28,64.83) .. (-35.28,66.64)
 .. controls (-35.28,68.44) and (-37.45,79.79) .. (-38.71,83.57)
 .. controls (-39.97,87.35) and (-45.18,91.29) .. (-40.15,91.84)
 .. controls (-35.12,92.39) and (-33.86,95.27) .. (-31.34,90.95)
 .. controls (-28.81,86.63) and (-25.39,78.35) .. (-20.70,81.05)
 .. controls (-16.02,83.74) and (-16.38,85.18) .. (-10.80,83.75)
 .. controls (-5.22,82.31) and (-0.54,81.41) .. (2.16,82.49)
 .. controls (4.86,83.57) and (5.03,77.07) .. (8.99,78.87)
 .. controls (12.96,80.67) and (21.42,83.20) .. (21.42,87.16)
 .. controls (21.42,91.13) and (22.13,100.12) .. (25.02,100.85)
 .. controls (27.91,101.59) and (31.52,102.31) .. (32.24,102.85)
 .. controls (32.96,103.40) and (33.50,104.48) .. (33.50,104.48)
),
1,((30.44,105.56)
 .. controls (30.44,105.56) and (28.28,104.65) .. (25.20,104.10)
 .. controls (22.13,103.55) and (19.79,104.09) .. (19.25,100.12)
 .. controls (18.71,96.17) and (20.52,87.16) .. (17.10,85.72)
 .. controls (13.67,84.28) and (9.17,79.95) .. (7.20,83.02)
 .. controls (5.22,86.09) and (3.79,88.43) .. (1.81,87.17)
 .. controls (-0.18,85.91) and (-0.90,83.03) .. (-4.50,85.01)
 .. controls (-8.10,86.99) and (-13.68,90.94) .. (-16.56,89.14)
 .. controls (-19.44,87.34) and (-19.26,82.13) .. (-22.68,86.81)
 .. controls (-26.11,91.50) and (-26.84,96.18) .. (-29.90,97.62)
 .. controls (-32.96,99.06) and (-46.61,102.62) .. (-50.57,98.13)
 .. controls (-54.53,93.64) and (-53.09,94.90) .. (-51.30,88.97)
 .. controls (-49.51,83.03) and (-42.67,67.18) .. (-40.86,61.05)
 .. controls (-39.06,54.94) and (-39.42,54.94) .. (-35.46,45.58)
 .. controls (-31.50,36.25) and (-24.47,22.90) .. (-26.10,19.12)
 .. controls (-27.71,15.36) and (-24.66,8.51) .. (-31.86,8.53)
 .. controls (-39.05,8.56) and (-59.03,15.42) .. (-63.55,9.45)
 .. controls (-68.04,3.52) and (-69.14,4.98) .. (-65.89,-2.02)
 .. controls (-62.66,-8.97) and (-60.88,-14.76) .. (-59.59,-21.60)
 .. controls (-58.36,-28.09) and (-55.13,-41.43) .. (-55.13,-41.43)
 -- (-53.77,-44.37)
),
1,((-44.76,-43.29)
 .. controls (-44.76,-43.29) and (-47.18,-21.64) .. (-49.32,-18.35)
 .. controls (-51.51,-14.99) and (-59.05,-1.50) .. (-53.65,-1.29)
 .. controls (-48.24,-1.07) and (-34.57,2.59) .. (-30.96,-1.19)
 .. controls (-27.37,-4.94) and (-21.44,-12.71) .. (-19.26,-18.28)
 .. controls (-17.11,-23.77) and (-7.38,-42.82) .. (-10.44,-43.11)
 .. controls (-13.49,-43.39) and (-15.28,-50.77) .. (-15.28,-50.77)
),
1,((-9.35,-54.45)
 .. controls (-9.35,-54.45) and (-8.26,-47.26) .. (-1.80,-44.39)
 .. controls (4.70,-41.50) and (17.99,-34.68) .. (19.97,-37.20)
 .. controls (21.95,-39.72) and (24.28,-40.99) .. (26.45,-46.04)
 .. controls (28.61,-51.06) and (29.16,-59.88) .. (32.05,-62.59)
 .. controls (34.92,-65.28) and (52.92,-79.67) .. (55.26,-82.02)
 .. controls (57.60,-84.38) and (63.00,-85.29) .. (62.46,-88.35)
 .. controls (61.92,-91.40) and (58.68,-95.16) .. (58.68,-95.16)
),
1,((65.70,-97.32)
 .. controls (65.70,-97.32) and (79.76,-75.15) .. (80.12,-73.17)
 .. controls (80.48,-71.18) and (81.92,-67.21) .. (81.92,-67.21)
));
draw_downscrap;
endfig;
beginfig(27);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((30.44,105.56)
 .. controls (30.44,105.56) and (28.28,104.65) .. (25.20,104.10)
 .. controls (22.13,103.55) and (19.79,104.09) .. (19.25,100.12)
 .. controls (18.71,96.17) and (20.52,87.16) .. (17.10,85.72)
 .. controls (13.67,84.28) and (9.17,79.95) .. (7.20,83.02)
 .. controls (5.22,86.09) and (3.79,88.43) .. (1.81,87.17)
 .. controls (-0.18,85.91) and (-0.90,83.03) .. (-4.50,85.01)
 .. controls (-8.10,86.99) and (-13.68,90.94) .. (-16.56,89.14)
 .. controls (-19.44,87.34) and (-19.26,82.13) .. (-22.68,86.81)
 .. controls (-26.11,91.50) and (-26.84,96.18) .. (-29.90,97.62)
 .. controls (-32.96,99.06) and (-46.61,102.62) .. (-50.57,98.13)
 .. controls (-54.53,93.64) and (-53.09,94.90) .. (-51.30,88.97)
 .. controls (-49.51,83.03) and (-42.67,67.18) .. (-40.86,61.05)
 .. controls (-39.06,54.94) and (-39.42,54.94) .. (-35.46,45.58)
 .. controls (-31.50,36.25) and (-24.47,22.90) .. (-26.10,19.12)
 .. controls (-27.71,15.36) and (-24.66,8.51) .. (-31.86,8.53)
 .. controls (-39.05,8.56) and (-59.03,15.42) .. (-63.55,9.45)
 .. controls (-68.04,3.52) and (-69.14,4.98) .. (-65.89,-2.02)
 .. controls (-62.66,-8.97) and (-60.88,-14.76) .. (-59.59,-21.60)
 .. controls (-58.36,-28.09) and (-55.13,-41.43) .. (-55.13,-41.43)
 -- (-53.77,-44.37)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-44.76,-43.29)
 .. controls (-44.76,-43.29) and (-47.18,-21.64) .. (-49.32,-18.35)
 .. controls (-51.51,-14.99) and (-59.05,-1.50) .. (-53.65,-1.29)
 .. controls (-48.24,-1.07) and (-34.57,2.59) .. (-30.96,-1.19)
 .. controls (-27.37,-4.94) and (-21.44,-12.71) .. (-19.26,-18.28)
 .. controls (-17.11,-23.77) and (-7.38,-42.82) .. (-10.44,-43.11)
 .. controls (-13.49,-43.39) and (-15.28,-50.77) .. (-15.28,-50.77)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-9.35,-54.45)
 .. controls (-9.35,-54.45) and (-8.26,-47.26) .. (-1.80,-44.39)
 .. controls (4.70,-41.50) and (17.99,-34.68) .. (19.97,-37.20)
 .. controls (21.95,-39.72) and (24.28,-40.99) .. (26.45,-46.04)
 .. controls (28.61,-51.06) and (29.16,-59.88) .. (32.05,-62.59)
 .. controls (34.92,-65.28) and (52.92,-79.67) .. (55.26,-82.02)
 .. controls (57.60,-84.38) and (63.00,-85.29) .. (62.46,-88.35)
 .. controls (61.92,-91.40) and (58.68,-95.16) .. (58.68,-95.16)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((65.70,-97.32)
 .. controls (65.70,-97.32) and (79.76,-75.15) .. (80.12,-73.17)
 .. controls (80.48,-71.18) and (81.92,-67.21) .. (81.92,-67.21)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((75.62,-65.59)
 .. controls (75.62,-65.59) and (70.20,-83.31) .. (64.63,-79.52)
 .. controls (59.04,-75.72) and (42.48,-67.42) .. (37.81,-58.80)
 .. controls (33.11,-50.15) and (33.10,-44.59) .. (28.43,-39.73)
 .. controls (23.75,-34.87) and (25.01,-33.26) .. (17.99,-31.98)
 .. controls (10.97,-30.69) and (7.92,-36.78) .. (-0.36,-29.55)
 .. controls (-8.63,-22.33) and (-11.53,-18.78) .. (-15.48,-13.24)
 .. controls (-19.46,-7.65) and (-28.43,-0.49) .. (-25.02,4.01)
 .. controls (-21.59,8.53) and (-16.56,18.05) .. (-18.71,22.54)
 .. controls (-20.88,27.06) and (-25.74,47.93) .. (-26.64,49.01)
 .. controls (-27.54,50.09) and (-29.16,45.76) .. (-31.50,52.42)
 .. controls (-33.84,59.07) and (-35.28,64.83) .. (-35.28,66.64)
 .. controls (-35.28,68.44) and (-37.45,79.79) .. (-38.71,83.57)
 .. controls (-39.97,87.35) and (-45.18,91.29) .. (-40.15,91.84)
 .. controls (-35.12,92.39) and (-33.86,95.27) .. (-31.34,90.95)
 .. controls (-28.81,86.63) and (-25.39,78.35) .. (-20.70,81.05)
 .. controls (-16.02,83.74) and (-16.38,85.18) .. (-10.80,83.75)
 .. controls (-5.22,82.31) and (-0.54,81.41) .. (2.16,82.49)
 .. controls (4.86,83.57) and (5.03,77.07) .. (8.99,78.87)
 .. controls (12.96,80.67) and (21.42,83.20) .. (21.42,87.16)
 .. controls (21.42,91.13) and (22.13,100.12) .. (25.02,100.85)
 .. controls (27.91,101.59) and (31.52,102.31) .. (32.24,102.85)
 .. controls (32.96,103.40) and (33.50,104.48) .. (33.50,104.48)
));
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
p_waterflow_permanent((-32.04,64.66),147.1,1.00,(0,0));
string ATTR_code;
ATTR_code := "A";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \thfc\char184 \ \thfb\char101 \char120 \char112 \char108 \char111 \char114 \char101 \char114 \mainfont{}etex;
drawoptions();
p_continuation((80.84,-57.65),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
string ATTR_code;
ATTR_code := "A";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \thfc\char184 \ \thfb\char101 \char120 \char112 \char108 \char111 \char114 \char101 \char114 \ \char59 \ \char98 \char114 \char117 \char105 \char116 \ \char100 \char101 \ \char114 \char105 \char118 \char105 \accent18 \char101 \char114 \char101 \mainfont{}etex;
drawoptions();
p_continuation((58.68,-105.56),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
string ATTR_code;
ATTR_code := "P";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char80 \char117 \char105 \char116 \char115 \ \thfc\char184 \ \thfb\char100 \char101 \char115 \char99 \char101 \char110 \char100 \char114 \char101 \mainfont{}etex;
drawoptions();
p_continuation((-14.20,-55.77),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
drawoptions(withcolor (0.00000,0.36538,0.88462,0.48000));
p_clay((-9.00,92.75),0.0,1.00,(0,0));
drawoptions(withcolor (0.00000,0.36538,0.88462,0.48000));
p_clay((-0.01,73.67),0.0,1.00,(0,0));
drawoptions(withcolor (0.00000,0.36538,0.88462,0.48000));
p_clay((11.34,94.91),0.0,1.00,(0,0));
drawoptions(withcolor (0.00000,0.36538,0.88462,0.48000));
p_clay((27.55,92.76),0.0,1.00,(0,0));
drawoptions();
p_guano((31.33,-70.29),0.0,1.00,(0,0));
drawoptions();
p_gypsum((61.03,-80.60),0.0,1.00,(0,0));
drawoptions();
p_gypsum((56.89,-77.52),0.0,1.00,(0,0));
drawoptions();
p_claytree((7.91,-26.50),0.0,1.00,(0,0));
drawoptions();
p_claytree((16.91,-26.54),0.0,1.00,(0,0));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((21.48,101.08),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((19.28,85.42),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((7.68,80.25),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((3.36,85.40),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-3.11,83.05),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-16.01,87.49),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-22.67,82.28),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-31.33,94.65),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-47.07,96.86),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-44.76,82.28),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-37.95,61.31),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-33.55,48.54),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-23.00,19.56),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-28.11,2.84),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-60.95,4.56),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-55.08,-18.98),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-50.38,-41.07),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-18.98,-15.08),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-5.61,-41.32),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((20.67,-33.79),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((28.03,-43.22),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((33.77,-60.89),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((63.23,-85.60),1,0,"");
endfig;
beginfig(28);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.llft(btex \thaltitude \thfb\char45 \char49 \char49 \char54 \mainfont{} etex,(55.26,-82.02),0.0,p_label_mode_altitude);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char50 \mainfont{} etex,(-13.50,48.13),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char49 \char50 \mainfont{} etex,(-68.03,94.40),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char56 \mainfont{} etex,(-67.15,71.19),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{\hfil#\hfil\cr\thfb\char115 \char97 \char108 \char108 \char101 \cr\thfb \char100 \char117 \ \char67 \char104 \char97 \char111 \char115 \cr}}\mainfont{} etex,(-52.92,28.03),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char49 \char52 \mainfont{} etex,(-81.92,8.33),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char99 \char46 \char102 \char46 \mainfont{} etex,(54.55,-58.03),0.0,p_label_mode_label);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-Sol2019d-1";
ATTR__scrap := "SP-Sol2019d-1";
beginfig(29);
ATTR__height := -1;
drawoptions();
l_pit(((25.82,-31.27)
 .. controls (25.82,-31.27) and (25.65,-24.05) .. (23.55,-23.57)
));
ATTR__height := -1;
drawoptions();
l_pit(((1.24,-31.13)
 .. controls (1.24,-31.13) and (-2.19,-30.23) .. (-2.45,-32.40)
));
ATTR__height := -1;
drawoptions();
l_pit(((-5.05,-18.08)
 .. controls (-5.05,-18.08) and (-7.40,-18.42) .. (-8.56,-19.61)
));
ATTR__height := -1;
drawoptions();
l_pit(((-16.74,3.68)
 .. controls (-16.74,3.68) and (-18.25,1.95) .. (-19.23,1.76)
 .. controls (-20.27,1.56) and (-23.09,2.45) .. (-23.09,2.45)
));
ATTR__height := -1;
drawoptions();
l_pit(((-24.16,1.06)
 .. controls (-24.16,1.06) and (-21.45,0.12) .. (-20.33,-0.08)
 .. controls (-19.35,-0.24) and (-18.64,-0.84) .. (-17.75,-1.04)
 .. controls (-16.68,-1.27) and (-15.08,-5.07) .. (-15.08,-5.07)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((5.38,-31.39)
 -- (6.55,-32.02)
 -- (7.81,-30.85)
 -- (6.37,-30.13)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((22.47,-29.29)
 -- (22.69,-30.21)
 -- (23.23,-29.75)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((24.28,-28.75)
 -- (24.15,-29.75)
 -- (24.97,-29.38)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((22.85,-30.93)
 -- (23.96,-31.38)
 -- (23.71,-30.47)
 -- cycle
));
endfig;
beginfig(30);
draw_upscrap(1)(1,((27.65,-22.85)
 .. controls (27.65,-22.85) and (24.06,-24.30) .. (23.20,-25.31)
 .. controls (22.23,-26.42) and (21.69,-27.18) .. (21.65,-29.57)
 .. controls (21.61,-31.92) and (22.56,-34.73) .. (20.17,-33.87)
 .. controls (17.80,-33.02) and (7.43,-28.35) .. (6.37,-30.13)
 .. controls (5.28,-31.93) and (5.66,-35.71) .. (4.04,-34.99)
 .. controls (2.41,-34.27) and (2.78,-35.71) .. (0.97,-32.66)
 .. controls (-0.84,-29.60) and (-2.02,-26.10) .. (-3.70,-23.33)
 .. controls (-5.42,-20.52) and (-6.15,-19.15) .. (-6.04,-16.65)
 .. controls (-5.93,-14.17) and (-5.58,-7.74) .. (-6.95,-6.64)
 .. controls (-8.28,-5.58) and (-12.11,-1.49) .. (-12.85,-0.29)
 .. controls (-13.57,0.87) and (-9.42,14.66) .. (-9.44,17.00)
 .. controls (-9.45,19.37) and (-7.78,24.06) .. (-8.36,25.92)
 .. controls (-8.93,27.73) and (-9.64,29.00) .. (-9.61,30.76)
 .. controls (-9.57,32.52) and (-9.35,34.11) .. (-9.35,34.11)
),
1,((-10.71,33.93)
 .. controls (-10.71,33.93) and (-11.23,30.95) .. (-11.97,29.52)
 .. controls (-12.70,28.09) and (-16.62,28.94) .. (-16.59,26.86)
 .. controls (-16.56,24.74) and (-15.24,3.47) .. (-16.97,3.10)
 .. controls (-18.59,2.76) and (-21.69,3.82) .. (-21.69,3.82)
),
1,((-22.85,0.99)
 .. controls (-22.85,0.99) and (-19.31,-0.93) .. (-16.58,-2.94)
 .. controls (-13.04,-5.55) and (-9.10,-5.52) .. (-8.46,-8.73)
 .. controls (-7.81,-12.03) and (-8.47,-17.28) .. (-7.58,-19.24)
 .. controls (-6.67,-21.24) and (-3.45,-28.87) .. (-2.55,-30.41)
 .. controls (-1.64,-31.95) and (0.16,-34.90) .. (1.70,-36.52)
 .. controls (3.23,-38.15) and (4.85,-39.13) .. (5.75,-37.78)
 .. controls (6.64,-36.43) and (6.01,-33.19) .. (8.52,-33.66)
 .. controls (11.02,-34.14) and (20.92,-37.28) .. (22.11,-36.63)
 .. controls (23.28,-35.99) and (23.87,-34.57) .. (23.80,-33.33)
 .. controls (23.73,-32.09) and (25.43,-30.67) .. (26.22,-30.07)
 .. controls (26.93,-29.52) and (27.24,-29.02) .. (27.24,-29.02)
));
draw_downscrap;
endfig;
beginfig(31);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((27.65,-22.85)
 .. controls (27.65,-22.85) and (24.06,-24.30) .. (23.20,-25.31)
 .. controls (22.23,-26.42) and (21.69,-27.18) .. (21.65,-29.57)
 .. controls (21.61,-31.92) and (22.56,-34.73) .. (20.17,-33.87)
 .. controls (17.80,-33.02) and (7.43,-28.35) .. (6.37,-30.13)
 .. controls (5.28,-31.93) and (5.66,-35.71) .. (4.04,-34.99)
 .. controls (2.41,-34.27) and (2.78,-35.71) .. (0.97,-32.66)
 .. controls (-0.84,-29.60) and (-2.02,-26.10) .. (-3.70,-23.33)
 .. controls (-5.42,-20.52) and (-6.15,-19.15) .. (-6.04,-16.65)
 .. controls (-5.93,-14.17) and (-5.58,-7.74) .. (-6.95,-6.64)
 .. controls (-8.28,-5.58) and (-12.11,-1.49) .. (-12.85,-0.29)
 .. controls (-13.57,0.87) and (-9.42,14.66) .. (-9.44,17.00)
 .. controls (-9.45,19.37) and (-7.78,24.06) .. (-8.36,25.92)
 .. controls (-8.93,27.73) and (-9.64,29.00) .. (-9.61,30.76)
 .. controls (-9.57,32.52) and (-9.35,34.11) .. (-9.35,34.11)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-10.71,33.93)
 .. controls (-10.71,33.93) and (-11.23,30.95) .. (-11.97,29.52)
 .. controls (-12.70,28.09) and (-16.62,28.94) .. (-16.59,26.86)
 .. controls (-16.56,24.74) and (-15.24,3.47) .. (-16.97,3.10)
 .. controls (-18.59,2.76) and (-21.69,3.82) .. (-21.69,3.82)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-22.85,0.99)
 .. controls (-22.85,0.99) and (-19.31,-0.93) .. (-16.58,-2.94)
 .. controls (-13.04,-5.55) and (-9.10,-5.52) .. (-8.46,-8.73)
 .. controls (-7.81,-12.03) and (-8.47,-17.28) .. (-7.58,-19.24)
 .. controls (-6.67,-21.24) and (-3.45,-28.87) .. (-2.55,-30.41)
 .. controls (-1.64,-31.95) and (0.16,-34.90) .. (1.70,-36.52)
 .. controls (3.23,-38.15) and (4.85,-39.13) .. (5.75,-37.78)
 .. controls (6.64,-36.43) and (6.01,-33.19) .. (8.52,-33.66)
 .. controls (11.02,-34.14) and (20.92,-37.28) .. (22.11,-36.63)
 .. controls (23.28,-35.99) and (23.87,-34.57) .. (23.80,-33.33)
 .. controls (23.73,-32.09) and (25.43,-30.67) .. (26.22,-30.07)
 .. controls (26.93,-29.52) and (27.24,-29.02) .. (27.24,-29.02)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((9.15,-31.87)
 -- (19.37,-34.96)
));
string ATTR_code;
ATTR_code := "E";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char83 \char117 \char105 \char116 \char101 \ \char100 \char117 \ \char109 \thfc\char233 \thfb\char97 \char110 \char100 \char114 \char101 \char44 \ \char112 \char97 \char115 \ \char100 \char101 \ \char99 \char111 \char117 \char114 \char97 \char110 \char116 \ \char100 \char39 \char97 \char105 \char114 \char44 \ \thfc\char184 \ \thfb\char69 \char113 \char117 \char105 \char112 \char101 \char114 \mainfont{}etex;
drawoptions();
p_continuation((-27.65,4.88),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
string ATTR_code;
ATTR_code := "D";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char80 \char97 \char115 \char115 \char97 \char103 \char101 \ \char100 \char105 \char102 \char102 \char105 \char99 \char105 \char108 \char101 \char109 \char101 \char110 \char116 \ \char112 \thfc\char233 \thfb\char110 \thfc\char233 \thfb\char116 \char114 \char97 \char98 \char108 \char101 \mainfont{}etex;
drawoptions();
p_continuation((-10.17,39.13),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
drawoptions();
p_narrowend((-3.29,32.80),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-11.81,27.38)
 .. controls (-11.81,27.38) and (-14.33,9.01) .. (-14.37,5.96)
 .. controls (-14.41,3.13) and (-16.00,0.33) .. (-13.88,-1.96)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((27.23,-27.56),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((22.88,-27.10),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((22.44,-35.51),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((6.40,-30.91),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((4.79,-36.89),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((0.96,-34.76),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-2.77,-28.78),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-6.90,-18.57),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-7.70,-7.15),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-15.58,-0.54),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-10.67,27.29),1,0,"");
endfig;
beginfig(32);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char50 \mainfont{} etex,(17.39,-18.41),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char49 \char46 \char53 \mainfont{} etex,(-9.35,-36.89),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char50 \mainfont{} etex,(0.55,-16.47),0.0,p_label_mode_label);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.ulft(btex \thaltitude \thfb\char45 \char51 \char56 \mainfont{} etex,(-16.59,26.86),0.0,p_label_mode_altitude);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-solitaire2019-1";
ATTR__scrap := "SP-solitaire2019-1";
beginfig(33);
ATTR__height := -1;
drawoptions();
l_pit(((-131.53,-55.87)
 .. controls (-131.53,-55.87) and (-133.32,-52.80) .. (-136.74,-52.80)
));
ATTR__height := -1;
drawoptions();
l_pit(((-96.01,-14.42)
 .. controls (-96.01,-14.42) and (-99.79,-15.50) .. (-101.23,-13.70)
));
ATTR__height := -1;
drawoptions();
l_pit(((-14.99,-34.74)
 .. controls (-14.99,-34.74) and (-15.55,-38.53) .. (-17.71,-39.26)
));
ATTR__height := -1;
drawoptions();
l_pit(((-29.60,-44.49)
 .. controls (-29.60,-44.49) and (-33.38,-46.65) .. (-35.00,-42.68)
));
ATTR__height := -1;
drawoptions();
l_pit(((53.39,46.60)
 .. controls (53.39,46.60) and (49.43,43.19) .. (47.46,48.96)
));
ATTR__height := -1;
drawoptions();
l_pit(((58.60,26.44)
 .. controls (58.60,26.44) and (56.98,31.29) .. (63.28,30.93)
));
ATTR__height := -1;
drawoptions();
l_pit(((80.18,-54.17)
 .. controls (80.18,-54.17) and (93.91,-36.49) .. (97.13,-26.98)
 .. controls (100.37,-17.42) and (100.57,-2.97) .. (100.57,-2.97)
));
ATTR__height := -1;
drawoptions();
l_pit(((27.16,18.87)
 .. controls (27.16,18.87) and (28.22,12.34) .. (25.57,12.63)
));
drawoptions();
p_blocks((-81.26,-22.53),0.0,1.00,(0,0));
drawoptions();
p_blocks((-77.31,-27.94),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_rockborder(((28.18,10.94)
 -- (26.74,7.18)
 -- (28.56,6.83)
 -- (29.84,9.04)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_pit(((35.02,51.64)
 .. controls (35.02,51.64) and (29.63,49.30) .. (29.81,47.85)
 .. controls (29.99,46.41) and (28.90,44.60) .. (31.79,45.88)
 .. controls (34.67,47.15) and (36.83,47.14) .. (36.64,48.39)
 .. controls (36.46,49.65) and (35.02,51.64) .. cycle
));
endfig;
beginfig(34);
draw_upscrap(1)(1,((-133.52,-56.41)
 .. controls (-133.52,-56.41) and (-126.08,-38.92) .. (-127.52,-35.68)
 .. controls (-128.96,-32.43) and (-135.08,-21.64) .. (-131.47,-20.92)
 .. controls (-127.87,-20.20) and (-119.95,-20.19) .. (-112.39,-20.19)
 .. controls (-104.83,-20.18) and (-93.68,-18.03) .. (-87.92,-22.71)
 .. controls (-82.17,-27.39) and (-73.54,-32.81) .. (-64.89,-36.40)
 .. controls (-56.23,-39.99) and (-40.39,-51.15) .. (-32.84,-50.43)
 .. controls (-25.27,-49.71) and (-14.48,-50.78) .. (-11.60,-45.03)
 .. controls (-8.70,-39.24) and (-0.01,-24.42) .. (0.71,-26.22)
 .. controls (1.43,-28.02) and (1.79,-31.63) .. (1.79,-31.63)
),
1,((4.31,-31.26)
 .. controls (4.31,-31.26) and (1.07,-25.14) .. (5.38,-19.76)
 .. controls (9.65,-14.41) and (15.12,-8.22) .. (20.32,-3.04)
 .. controls (25.38,2.00) and (28.40,6.13) .. (29.64,5.57)
),
1,((29.64,5.57)
 .. controls (29.64,5.57) and (31.23,7.00) .. (30.78,9.82)
 .. controls (30.31,12.77) and (31.08,28.48) .. (31.08,32.57)
 .. controls (31.07,36.74) and (30.35,43.89) .. (33.42,45.17)
 .. controls (36.47,46.43) and (36.28,48.75) .. (39.34,46.78)
 .. controls (42.41,44.82) and (52.30,38.31) .. (53.02,36.32)
 .. controls (53.73,34.33) and (60.39,26.97) .. (63.64,24.46)
 .. controls (66.88,21.94) and (74.25,15.45) .. (77.49,10.77)
 .. controls (80.74,6.07) and (91.93,-2.22) .. (87.49,-17.08)
 .. controls (83.07,-31.88) and (75.30,-58.30) .. (92.62,-59.44)
 .. controls (109.90,-60.59) and (104.69,-61.46) .. (116.92,-59.32)
),
1,((116.92,-59.32)
 .. controls (116.92,-59.32) and (119.80,-59.14) .. (121.77,-60.03)
 .. controls (123.75,-60.92) and (125.72,-63.61) .. (125.72,-63.61)
),
1,((129.85,-61.45)
 .. controls (129.85,-61.45) and (125.54,-57.15) .. (126.44,-56.07)
 .. controls (127.34,-54.99) and (127.52,-54.81) .. (127.52,-54.81)
),
1,((127.52,-54.81)
 .. controls (131.26,-46.88) and (138.33,-36.35) .. (140.12,-34.73)
),
1,((118.28,-26.49)
 .. controls (118.28,-26.49) and (115.53,-28.76) .. (112.66,-23.98)
 .. controls (109.31,-18.40) and (97.84,-5.84) .. (94.78,-0.78)
 .. controls (91.73,4.25) and (88.12,14.35) .. (83.43,17.06)
 .. controls (78.76,19.77) and (65.25,24.81) .. (62.55,28.77)
 .. controls (59.85,32.73) and (58.42,30.39) .. (58.06,34.52)
 .. controls (57.70,38.67) and (59.14,42.62) .. (56.26,43.71)
 .. controls (53.38,44.79) and (51.23,45.35) .. (51.23,46.79)
 .. controls (51.23,48.23) and (52.31,50.40) .. (52.31,50.40)
),
1,((50.34,51.12)
 .. controls (50.34,51.12) and (50.51,46.07) .. (48.18,46.98)
 .. controls (45.84,47.88) and (40.06,51.99) .. (37.18,50.73)
 .. controls (34.31,49.47) and (33.05,50.74) .. (32.15,52.01)
),
1,((29.81,50.74)
 .. controls (29.81,50.74) and (32.69,48.94) .. (29.63,46.77)
 .. controls (26.57,44.60) and (28.39,40.85) .. (28.39,37.82)
 .. controls (28.39,34.74) and (28.04,28.31) .. (27.93,25.25)
 .. controls (27.83,22.22) and (29.66,18.35) .. (27.53,17.12)
),
1,((27.53,17.12)
 .. controls (27.53,17.12) and (26.66,15.63) .. (26.29,16.92)
 .. controls (25.94,18.15) and (24.65,20.52) .. (24.65,20.52)
),
1,((22.72,18.22)
 .. controls (22.72,18.22) and (25.95,15.22) .. (26.29,14.18)
 .. controls (26.65,13.13) and (27.16,11.44) .. (27.16,11.44)
),
1,((27.16,11.44)
 .. controls (24.84,11.53) and (22.56,15.29) .. (22.56,15.29)
),
1,((22.15,9.12)
 .. controls (22.15,9.12) and (27.14,9.83) .. (25.76,7.61)
 .. controls (24.41,5.42) and (17.45,-1.59) .. (15.41,-3.08)
 .. controls (13.35,-4.59) and (7.64,-10.67) .. (4.45,-14.39)
 .. controls (1.24,-18.13) and (-2.89,-22.80) .. (-6.50,-27.14)
 .. controls (-10.11,-31.48) and (-9.75,-31.84) .. (-10.48,-32.56)
 .. controls (-11.20,-33.29) and (-14.10,-36.55) .. (-15.18,-36.55)
 .. controls (-16.26,-36.55) and (-20.40,-36.73) .. (-20.40,-36.73)
),
1,((-20.40,-36.73)
 .. controls (-20.40,-36.73) and (-27.68,-38.80) .. (-28.69,-39.62)
),
1,((-28.69,-39.62)
 .. controls (-28.69,-39.62) and (-31.94,-43.95) .. (-34.10,-43.95)
 .. controls (-36.26,-43.95) and (-46.51,-38.89) .. (-50.47,-37.27)
 .. controls (-54.43,-35.66) and (-66.34,-32.09) .. (-70.48,-28.49)
 .. controls (-74.61,-24.89) and (-83.77,-15.87) .. (-87.74,-15.51)
 .. controls (-91.70,-15.15) and (-97.45,-16.40) .. (-97.45,-14.24)
 .. controls (-97.45,-12.08) and (-97.45,-9.56) .. (-97.45,-9.56)
),
1,((-99.97,-9.56)
 .. controls (-99.97,-9.56) and (-99.07,-14.78) .. (-100.51,-14.78)
 .. controls (-101.95,-14.78) and (-116.53,-12.81) .. (-121.57,-13.35)
 .. controls (-126.62,-13.89) and (-140.12,-13.37) .. (-139.22,-17.33)
 .. controls (-138.32,-21.28) and (-138.14,-22.18) .. (-136.34,-25.42)
 .. controls (-134.54,-28.66) and (-129.21,-33.60) .. (-130.76,-35.68)
 .. controls (-132.31,-37.75) and (-136.58,-55.33) .. (-136.58,-55.33)
));
draw_upscrap(0)(1,((-29.24,-42.68)
 .. controls (-29.24,-42.68) and (-22.39,-39.07) .. (-20.76,-38.71)
),
1,((-20.76,-38.71)
 .. controls (-20.76,-38.71) and (-15.54,-37.81) .. (-16.45,-39.08)
 .. controls (-17.35,-40.34) and (-19.33,-42.14) .. (-22.03,-43.04)
 .. controls (-24.73,-43.94) and (-31.04,-46.83) .. (-30.86,-45.39)
 .. controls (-30.68,-43.95) and (-29.24,-42.68) .. (-29.24,-42.68)
));
draw_upscrap(0)(1,((117.67,-33.70)
 .. controls (117.67,-33.70) and (126.82,-31.27) .. (129.96,-32.24)
 .. controls (133.17,-33.24) and (133.88,-34.56) .. (133.35,-36.74)
 .. controls (132.83,-38.92) and (126.80,-46.93) .. (121.96,-46.95)
 .. controls (117.12,-46.98) and (94.97,-48.33) .. (98.58,-43.52)
 .. controls (102.19,-38.70) and (105.80,-36.93) .. (109.03,-36.01)
 .. controls (112.25,-35.10) and (117.67,-33.70) .. cycle
));
draw_downscrap;
endfig;
beginfig(35);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-133.52,-56.41)
 .. controls (-133.52,-56.41) and (-126.08,-38.92) .. (-127.52,-35.68)
 .. controls (-128.96,-32.43) and (-135.08,-21.64) .. (-131.47,-20.92)
 .. controls (-127.87,-20.20) and (-119.95,-20.19) .. (-112.39,-20.19)
 .. controls (-104.83,-20.18) and (-93.68,-18.03) .. (-87.92,-22.71)
 .. controls (-82.17,-27.39) and (-73.54,-32.81) .. (-64.89,-36.40)
 .. controls (-56.23,-39.99) and (-40.39,-51.15) .. (-32.84,-50.43)
 .. controls (-25.27,-49.71) and (-14.48,-50.78) .. (-11.60,-45.03)
 .. controls (-8.70,-39.24) and (-0.01,-24.42) .. (0.71,-26.22)
 .. controls (1.43,-28.02) and (1.79,-31.63) .. (1.79,-31.63)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((117.67,-33.70)
 .. controls (117.67,-33.70) and (126.82,-31.27) .. (129.96,-32.24)
 .. controls (133.17,-33.24) and (133.88,-34.56) .. (133.35,-36.74)
 .. controls (132.83,-38.92) and (126.80,-46.93) .. (121.96,-46.95)
 .. controls (117.12,-46.98) and (94.97,-48.33) .. (98.58,-43.52)
 .. controls (102.19,-38.70) and (105.80,-36.93) .. (109.03,-36.01)
 .. controls (112.25,-35.10) and (117.67,-33.70) .. cycle
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((4.31,-31.26)
 .. controls (4.31,-31.26) and (1.07,-25.14) .. (5.38,-19.76)
 .. controls (9.65,-14.41) and (15.12,-8.22) .. (20.32,-3.04)
 .. controls (25.38,2.00) and (28.40,6.13) .. (29.64,5.57)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((127.52,-54.81)
 .. controls (131.26,-46.88) and (138.33,-36.35) .. (140.12,-34.73)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((29.64,5.57)
 .. controls (29.64,5.57) and (31.23,7.00) .. (30.78,9.82)
 .. controls (30.31,12.77) and (31.08,28.48) .. (31.08,32.57)
 .. controls (31.07,36.74) and (30.35,43.89) .. (33.42,45.17)
 .. controls (36.47,46.43) and (36.28,48.75) .. (39.34,46.78)
 .. controls (42.41,44.82) and (52.30,38.31) .. (53.02,36.32)
 .. controls (53.73,34.33) and (60.39,26.97) .. (63.64,24.46)
 .. controls (66.88,21.94) and (74.25,15.45) .. (77.49,10.77)
 .. controls (80.74,6.07) and (91.93,-2.22) .. (87.49,-17.08)
 .. controls (83.07,-31.88) and (75.30,-58.30) .. (92.62,-59.44)
 .. controls (109.90,-60.59) and (104.69,-61.46) .. (116.92,-59.32)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((116.92,-59.32)
 .. controls (116.92,-59.32) and (119.80,-59.14) .. (121.77,-60.03)
 .. controls (123.75,-60.92) and (125.72,-63.61) .. (125.72,-63.61)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((129.85,-61.45)
 .. controls (129.85,-61.45) and (125.54,-57.15) .. (126.44,-56.07)
 .. controls (127.34,-54.99) and (127.52,-54.81) .. (127.52,-54.81)
));
string ATTR_code;
ATTR_code := "A";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \thfc\char184 \ \thfb\char118 \char111 \char105 \char114 \mainfont{}etex;
drawoptions();
p_continuation((121.23,-68.10),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((118.28,-26.49)
 .. controls (118.28,-26.49) and (115.53,-28.76) .. (112.66,-23.98)
 .. controls (109.31,-18.40) and (97.84,-5.84) .. (94.78,-0.78)
 .. controls (91.73,4.25) and (88.12,14.35) .. (83.43,17.06)
 .. controls (78.76,19.77) and (65.25,24.81) .. (62.55,28.77)
 .. controls (59.85,32.73) and (58.42,30.39) .. (58.06,34.52)
 .. controls (57.70,38.67) and (59.14,42.62) .. (56.26,43.71)
 .. controls (53.38,44.79) and (51.23,45.35) .. (51.23,46.79)
 .. controls (51.23,48.23) and (52.31,50.40) .. (52.31,50.40)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((50.34,51.12)
 .. controls (50.34,51.12) and (50.51,46.07) .. (48.18,46.98)
 .. controls (45.84,47.88) and (40.06,51.99) .. (37.18,50.73)
 .. controls (34.31,49.47) and (33.05,50.74) .. (32.15,52.01)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((27.16,11.44)
 .. controls (24.84,11.53) and (22.56,15.29) .. (22.56,15.29)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((29.81,50.74)
 .. controls (29.81,50.74) and (32.69,48.94) .. (29.63,46.77)
 .. controls (26.57,44.60) and (28.39,40.85) .. (28.39,37.82)
 .. controls (28.39,34.74) and (28.04,28.31) .. (27.93,25.25)
 .. controls (27.83,22.22) and (29.66,18.35) .. (27.53,17.12)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((27.53,17.12)
 .. controls (27.53,17.12) and (26.66,15.63) .. (26.29,16.92)
 .. controls (25.94,18.15) and (24.65,20.52) .. (24.65,20.52)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((22.72,18.22)
 .. controls (22.72,18.22) and (25.95,15.22) .. (26.29,14.18)
 .. controls (26.65,13.13) and (27.16,11.44) .. (27.16,11.44)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((22.15,9.12)
 .. controls (22.15,9.12) and (27.14,9.83) .. (25.76,7.61)
 .. controls (24.41,5.42) and (17.45,-1.59) .. (15.41,-3.08)
 .. controls (13.35,-4.59) and (7.64,-10.67) .. (4.45,-14.39)
 .. controls (1.24,-18.13) and (-2.89,-22.80) .. (-6.50,-27.14)
 .. controls (-10.11,-31.48) and (-9.75,-31.84) .. (-10.48,-32.56)
 .. controls (-11.20,-33.29) and (-14.10,-36.55) .. (-15.18,-36.55)
 .. controls (-16.26,-36.55) and (-20.40,-36.73) .. (-20.40,-36.73)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-20.76,-38.71)
 .. controls (-20.76,-38.71) and (-15.54,-37.81) .. (-16.45,-39.08)
 .. controls (-17.35,-40.34) and (-19.33,-42.14) .. (-22.03,-43.04)
 .. controls (-24.73,-43.94) and (-31.04,-46.83) .. (-30.86,-45.39)
 .. controls (-30.68,-43.95) and (-29.24,-42.68) .. (-29.24,-42.68)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((-29.24,-42.68)
 .. controls (-29.24,-42.68) and (-22.39,-39.07) .. (-20.76,-38.71)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((-20.40,-36.73)
 .. controls (-20.40,-36.73) and (-27.68,-38.80) .. (-28.69,-39.62)
));
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
p_waterflow_permanent((52.68,55.99),165.9,1.00,(0,0));
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
p_waterflow_permanent((26.95,59.05),209.9,1.00,(0,0));
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
p_waterflow_permanent((3.94,-34.87),195.6,1.00,(0,0));
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
p_waterflow_permanent((-98.52,-2.71),174.5,1.00,(0,0));
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
p_waterflow_permanent((97.85,-1.50),170.6,1.00,(0,0));
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
p_waterflow_permanent((83.06,-46.64),134.4,1.00,(0,0));
drawoptions();
p_claytree((-2.53,-16.50),0.0,1.00,(0,0));
drawoptions();
p_bridge((35.31,4.81),0.0,1.00,(0,0));
drawoptions();
p_traverse((38.45,57.60),0.0,1.00,(0,0));
drawoptions();
p_stalactites((34.97,23.26),0.0,1.00,(0,0));
drawoptions();
p_narrowend((-92.58,-7.40),0.0,1.00,(0,0));
drawoptions();
p_narrowend((9.17,-32.69),0.0,1.00,(0,0));
drawoptions();
p_narrowend((57.17,50.94),0.0,1.00,(0,0));
string ATTR_code;
ATTR_code := "A";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char65 \char102 \char102 \char108 \char117 \char101 \char110 \char116 \ \thfc\char184 \ \thfb\char101 \char120 \char112 \char108 \char111 \char114 \char101 \char114 \mainfont{}etex;
drawoptions();
p_continuation((32.17,64.82),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
string ATTR_code;
ATTR_code := "A";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char67 \char70 \ \thfc\char184 \ \thfb\char101 \char120 \char112 \char108 \char111 \char114 \char101 \char114 \mainfont{}etex;
drawoptions();
p_continuation((19.93,24.25),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
drawoptions();
p_airdraught_summer((-117.25,-25.23),271.9,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-28.69,-39.62)
 .. controls (-28.69,-39.62) and (-31.94,-43.95) .. (-34.10,-43.95)
 .. controls (-36.26,-43.95) and (-46.51,-38.89) .. (-50.47,-37.27)
 .. controls (-54.43,-35.66) and (-66.34,-32.09) .. (-70.48,-28.49)
 .. controls (-74.61,-24.89) and (-83.77,-15.87) .. (-87.74,-15.51)
 .. controls (-91.70,-15.15) and (-97.45,-16.40) .. (-97.45,-14.24)
 .. controls (-97.45,-12.08) and (-97.45,-9.56) .. (-97.45,-9.56)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-99.97,-9.56)
 .. controls (-99.97,-9.56) and (-99.07,-14.78) .. (-100.51,-14.78)
 .. controls (-101.95,-14.78) and (-116.53,-12.81) .. (-121.57,-13.35)
 .. controls (-126.62,-13.89) and (-140.12,-13.37) .. (-139.22,-17.33)
 .. controls (-138.32,-21.28) and (-138.14,-22.18) .. (-136.34,-25.42)
 .. controls (-134.54,-28.66) and (-129.21,-33.60) .. (-130.76,-35.68)
 .. controls (-132.31,-37.75) and (-136.58,-55.33) .. (-136.58,-55.33)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((133.05,-27.10),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((114.53,-29.04),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((94.53,-3.44),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((80.63,13.72),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((62.25,27.08),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((54.68,34.91),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((56.75,42.13),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((37.84,50.15),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((28.84,44.95),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((28.84,31.72),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((29.70,7.05),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((22.14,10.57),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((8.69,-9.97),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-15.08,-46.57),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-31.52,-46.57),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-71.19,-31.34),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-89.26,-19.61),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-122.56,-16.69),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-137.50,-18.26),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-129.93,-34.50),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-135.14,-55.40),1,0,"");
endfig;
beginfig(36);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char57 \mainfont{} etex,(-124.31,-56.58),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char55 \mainfont{} etex,(18.70,45.76),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char55 \mainfont{} etex,(70.95,-28.53),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char49 \char46 \char53 \mainfont{} etex,(68.51,35.44),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{\hfil#\hfil\cr\thfb\char112 \char117 \char105 \char116 \char115 \ \char100 \char101 \cr\thfb \char78 \char101 \char119 \char116 \char111 \char110 \cr}}\mainfont{} etex,(8.46,68.10),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{\hfil#\hfil\cr\thfb\char112 \char117 \char105 \char116 \char115 \ \char100 \char101 \cr\thfb \char108 \char97 \ \char83 \char97 \char118 \char111 \char110 \char110 \char101 \char116 \char116 \char101 \cr}}\mainfont{} etex,(52.77,-40.51),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char109 \char46 \ \char100 \char101 \char115 \ \char103 \char111 \char117 \char106 \char111 \char110 \char115 \mainfont{} etex,(-39.45,-12.38),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{\hfil#\hfil\cr\thfb\char99 \char97 \char114 \char114 \char101 \char102 \char111 \char117 \char114 \cr\thfb \char68 \char97 \char110 \char105 \char101 \char108 \cr}}\mainfont{} etex,(41.10,-9.95),0.0,p_label_mode_label);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-sol2017-2";
ATTR__scrap := "SP-sol2017-2";
beginfig(37);
ATTR__height := -1;
drawoptions();
l_pit(((9.65,-16.13)
 .. controls (9.65,-16.13) and (6.18,-7.25) .. (5.55,-6.02)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-162.64,-29.03)
 -- (-162.35,-27.64)
 -- (-160.70,-27.66)
 -- (-160.58,-29.32)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-158.78,-27.95)
 -- (-156.99,-27.00)
 -- (-156.18,-28.95)
 -- (-158.11,-29.62)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_pit(((-151.38,-30.94)
 .. controls (-151.38,-30.94) and (-167.72,-29.68) .. (-170.47,-31.18)
));
ATTR__height := -1;
drawoptions();
l_pit(((-92.23,24.75)
 .. controls (-92.23,24.75) and (-91.40,24.55) .. (-90.58,24.35)
 .. controls (-89.76,24.14) and (-89.69,23.75) .. (-88.64,23.78)
 .. controls (-87.63,23.81) and (-88.05,27.32) .. (-88.05,27.32)
));
ATTR__height := -1;
drawoptions();
l_pit(((-107.79,10.05)
 .. controls (-107.79,10.05) and (-106.13,9.99) .. (-105.22,10.24)
 .. controls (-104.31,10.49) and (-104.06,11.52) .. (-104.81,12.10)
 .. controls (-105.55,12.68) and (-106.91,13.42) .. (-107.33,13.43)
 .. controls (-107.75,13.45) and (-108.64,13.54) .. (-108.64,13.54)
));
ATTR__height := -1;
drawoptions();
l_floormeander(((8.09,-17.61)
 .. controls (8.09,-17.61) and (11.73,-18.95) .. (13.92,-19.24)
 .. controls (16.11,-19.52) and (18.57,-19.21) .. (21.49,-19.70)
 .. controls (24.41,-20.19) and (32.72,-20.80) .. (35.71,-20.82)
 .. controls (38.70,-20.85) and (42.16,-21.21) .. (44.95,-21.50)
 .. controls (47.74,-21.79) and (51.93,-22.62) .. (54.79,-22.91)
 .. controls (57.67,-23.21) and (59.78,-24.04) .. (62.89,-24.52)
 .. controls (65.98,-25.00) and (68.24,-26.95) .. (71.04,-28.03)
 .. controls (73.84,-29.11) and (74.86,-30.00) .. (77.14,-31.00)
 .. controls (79.41,-31.99) and (81.98,-32.95) .. (84.47,-33.61)
 .. controls (86.90,-34.26) and (88.70,-35.17) .. (91.49,-35.29)
 .. controls (94.37,-35.41) and (93.73,-36.34) .. (97.14,-35.13)
 .. controls (100.56,-33.92) and (104.56,-32.18) .. (108.57,-30.69)
 .. controls (112.58,-29.21) and (118.74,-26.02) .. (120.97,-24.91)
 .. controls (123.21,-23.80) and (126.82,-22.62) .. (128.36,-20.94)
 .. controls (129.91,-19.28) and (130.30,-17.29) .. (130.20,-15.44)
 .. controls (130.10,-13.59) and (127.99,-10.42) .. (130.69,-9.85)
 .. controls (133.26,-9.30) and (135.63,-8.10) .. (139.19,-8.00)
 .. controls (142.77,-7.89) and (142.97,-7.95) .. (146.95,-6.89)
 .. controls (150.94,-5.82) and (153.10,-4.74) .. (156.28,-4.14)
 .. controls (159.47,-3.54) and (163.55,-3.29) .. (163.55,-3.29)
));
ATTR__height := -1;
drawoptions();
l_pit(((165.79,-7.30)
 .. controls (165.79,-7.30) and (165.94,-2.15) .. (163.61,-0.51)
 .. controls (161.29,1.13) and (159.67,1.55) .. (159.67,1.55)
));
ATTR__height := -1;
drawoptions();
l_pit(((145.23,-17.82)
 .. controls (145.23,-17.82) and (145.79,-13.21) .. (143.71,-9.10)
));
ATTR__height := -1;
drawoptions();
l_pit(((142.50,-6.26)
 .. controls (142.50,-6.26) and (139.00,-1.24) .. (136.98,-0.69)
 .. controls (134.95,-0.14) and (130.97,2.65) .. (130.97,2.65)
));
ATTR__height := -1;
drawoptions();
l_pit(((99.28,-44.54)
 .. controls (99.28,-44.54) and (99.61,-41.45) .. (99.16,-39.46)
 .. controls (98.72,-37.48) and (98.42,-35.77) .. (98.42,-35.77)
));
ATTR__height := -1;
drawoptions();
l_pit(((97.58,-33.80)
 .. controls (97.58,-33.80) and (97.28,-32.62) .. (95.94,-30.94)
 .. controls (94.61,-29.27) and (91.77,-26.45) .. (91.77,-26.45)
));
ATTR__height := -1;
drawoptions();
l_pit(((138.57,-23.58)
 .. controls (138.57,-23.58) and (137.67,-16.42) .. (135.71,-16.04)
 .. controls (135.30,-15.96) and (132.53,-13.39) .. (131.06,-13.15)
));
ATTR__height := -1;
drawoptions();
l_pit(((128.10,-13.27)
 .. controls (128.10,-13.27) and (125.14,-15.89) .. (122.47,-16.03)
));
ATTR__height := -1;
drawoptions();
l_pit(((2.60,-8.65)
 -- (6.66,-19.65)
));
endfig;
beginfig(38);
draw_upscrap(1)(1,((6.66,-19.65)
 .. controls (7.93,-20.18) and (7.87,-21.39) .. (10.65,-21.27)
 .. controls (13.44,-21.15) and (12.31,-20.22) .. (15.23,-20.91)
 .. controls (18.15,-21.60) and (21.27,-22.29) .. (23.93,-22.85)
 .. controls (26.58,-23.40) and (26.65,-22.54) .. (29.31,-23.23)
 .. controls (31.96,-23.92) and (31.96,-23.58) .. (35.95,-24.15)
 .. controls (39.93,-24.72) and (40.47,-24.46) .. (43.39,-25.01)
 .. controls (46.31,-25.57) and (48.44,-25.92) .. (51.16,-26.48)
 .. controls (53.88,-27.03) and (56.09,-27.23) .. (58.23,-28.85)
 .. controls (60.37,-30.47) and (65.14,-33.34) .. (67.49,-34.07)
 .. controls (69.84,-34.80) and (73.28,-36.88) .. (74.70,-37.91)
 .. controls (76.12,-38.94) and (78.56,-41.32) .. (80.22,-43.03)
 .. controls (81.89,-44.74) and (85.24,-46.68) .. (87.62,-46.09)
 .. controls (90.02,-45.49) and (93.68,-42.97) .. (96.64,-42.24)
 .. controls (99.61,-41.51) and (100.92,-40.82) .. (103.81,-39.69)
 .. controls (106.70,-38.57) and (109.43,-36.71) .. (113.06,-35.64)
 .. controls (116.68,-34.57) and (123.65,-32.03) .. (125.66,-31.06)
 .. controls (127.67,-30.08) and (130.30,-29.99) .. (130.79,-28.49)
 .. controls (131.27,-27.00) and (131.40,-26.79) .. (130.95,-25.47)
 .. controls (130.50,-24.14) and (129.95,-23.83) .. (131.92,-22.95)
 .. controls (133.88,-22.06) and (134.83,-22.43) .. (137.13,-20.75)
 .. controls (139.39,-19.11) and (142.25,-16.72) .. (145.03,-15.71)
 .. controls (147.90,-14.67) and (150.29,-13.67) .. (153.30,-12.17)
 .. controls (156.35,-10.65) and (163.47,-6.54) .. (166.21,-5.14)
 .. controls (168.97,-3.72) and (170.86,-3.75) .. (171.25,-1.64)
 .. controls (171.64,0.47) and (172.35,1.86) .. (171.52,2.36)
 .. controls (170.69,2.84) and (170.62,3.88) .. (170.62,3.88)
),
1,((167.88,3.54)
 .. controls (167.88,3.54) and (168.49,2.67) .. (168.05,1.72)
 .. controls (167.60,0.77) and (168.04,0.35) .. (165.84,0.37)
 .. controls (163.67,0.38) and (160.96,0.59) .. (158.72,0.60)
 .. controls (156.49,0.61) and (151.29,0.63) .. (149.20,0.64)
 .. controls (147.10,0.64) and (145.28,0.99) .. (142.45,1.06)
 .. controls (139.61,1.14) and (138.13,1.08) .. (135.42,0.95)
 .. controls (132.71,0.83) and (131.33,1.75) .. (129.02,0.67)
 .. controls (126.70,-0.42) and (124.48,-0.13) .. (123.70,-2.81)
 .. controls (122.91,-5.51) and (122.91,-7.18) .. (123.08,-9.90)
 .. controls (123.25,-12.60) and (124.75,-14.97) .. (123.10,-16.47)
 .. controls (121.51,-17.93) and (116.99,-19.59) .. (114.76,-20.56)
 .. controls (112.53,-21.54) and (103.92,-24.71) .. (100.52,-26.19)
 .. controls (97.13,-27.67) and (92.93,-29.19) .. (91.40,-29.43)
 .. controls (89.89,-29.67) and (87.84,-30.49) .. (86.05,-29.08)
 .. controls (84.25,-27.66) and (81.55,-26.58) .. (79.85,-25.00)
 .. controls (78.13,-23.41) and (76.33,-23.34) .. (74.14,-21.86)
 .. controls (71.94,-20.38) and (68.62,-18.55) .. (66.79,-17.25)
 .. controls (64.96,-15.94) and (63.58,-15.32) .. (62.41,-14.11)
 .. controls (61.24,-12.89) and (59.63,-10.41) .. (59.63,-10.41)
),
1,((56.65,-10.02)
 .. controls (56.65,-10.02) and (58.53,-12.71) .. (57.45,-13.41)
 .. controls (56.38,-14.12) and (53.16,-14.26) .. (51.01,-14.29)
 .. controls (48.87,-14.33) and (45.70,-15.11) .. (43.16,-15.22)
 .. controls (40.63,-15.34) and (39.90,-15.26) .. (37.10,-15.57)
 .. controls (34.30,-15.88) and (30.18,-15.92) .. (28.05,-16.03)
 .. controls (25.92,-16.14) and (22.13,-15.91) .. (19.47,-16.35)
 .. controls (16.80,-16.80) and (14.74,-16.91) .. (12.82,-16.89)
 .. controls (10.90,-16.86) and (9.55,-18.06) .. (9.65,-16.13)
),
0,((9.38,-15.42)
 .. controls (9.38,-15.42) and (8.40,-10.14) .. (7.56,-8.35)
 .. controls (6.72,-6.56) and (5.55,-6.02) .. (5.55,-6.02)
),
1,((5.55,-6.02)
 .. controls (4.92,-4.71) and (3.85,0.12) .. (2.67,1.81)
 .. controls (1.50,3.47) and (0.80,7.30) .. (-0.56,9.37)
 .. controls (-1.93,11.44) and (-2.75,13.99) .. (-3.71,16.33)
 .. controls (-4.67,18.67) and (-5.17,21.89) .. (-6.39,23.62)
 .. controls (-7.61,25.36) and (-7.71,27.86) .. (-9.55,28.09)
 .. controls (-11.40,28.32) and (-13.67,29.44) .. (-15.38,28.60)
 .. controls (-17.10,27.75) and (-16.69,27.03) .. (-18.94,26.82)
 .. controls (-21.19,26.61) and (-24.49,26.58) .. (-27.14,26.59)
 .. controls (-29.72,26.61) and (-30.45,27.63) .. (-33.22,27.52)
 .. controls (-35.99,27.42) and (-39.25,28.22) .. (-40.02,26.44)
 .. controls (-40.78,24.66) and (-39.26,22.35) .. (-40.09,21.12)
 .. controls (-40.90,19.89) and (-44.98,18.57) .. (-48.29,17.51)
 .. controls (-51.61,16.45) and (-54.58,15.38) .. (-57.49,14.11)
 .. controls (-60.39,12.84) and (-62.75,13.50) .. (-63.53,11.14)
 .. controls (-64.32,8.74) and (-64.94,9.03) .. (-64.45,7.04)
 .. controls (-63.97,5.07) and (-62.70,2.19) .. (-62.77,0.50)
 .. controls (-62.84,-1.19) and (-63.17,-2.62) .. (-64.68,-1.37)
 .. controls (-66.20,-0.11) and (-67.24,0.17) .. (-67.23,1.91)
 .. controls (-67.22,3.65) and (-67.29,4.00) .. (-68.60,5.61)
 .. controls (-69.92,7.21) and (-72.20,9.87) .. (-73.53,12.43)
 .. controls (-74.84,14.96) and (-75.27,17.77) .. (-76.72,19.41)
 .. controls (-78.17,21.05) and (-79.71,23.78) .. (-80.47,24.60)
 .. controls (-81.22,25.40) and (-81.76,24.85) .. (-83.90,24.90)
 .. controls (-86.04,24.94) and (-86.58,25.46) .. (-87.78,25.80)
 .. controls (-89.00,26.14) and (-90.31,26.76) .. (-90.85,25.52)
 .. controls (-91.40,24.27) and (-91.59,22.15) .. (-90.67,19.89)
 .. controls (-89.76,17.62) and (-87.41,16.48) .. (-89.10,15.57)
 .. controls (-90.79,14.67) and (-91.00,14.19) .. (-93.92,14.01)
 .. controls (-96.84,13.84) and (-98.43,13.96) .. (-100.38,13.68)
 .. controls (-102.33,13.40) and (-103.79,13.31) .. (-104.90,13.35)
 .. controls (-106.01,13.39) and (-107.33,13.43) .. (-107.33,13.43)
),
1,((-108.64,13.54)
 .. controls (-108.64,13.54) and (-113.99,13.28) .. (-115.51,13.31)
 .. controls (-117.03,13.34) and (-119.27,12.56) .. (-121.91,12.04)
 .. controls (-124.55,11.52) and (-130.53,9.63) .. (-131.94,7.97)
 .. controls (-133.36,6.32) and (-135.67,0.92) .. (-136.67,-1.30)
 .. controls (-137.67,-3.52) and (-135.80,-6.88) .. (-137.18,-7.43)
 .. controls (-138.56,-7.97) and (-140.34,-7.40) .. (-141.44,-8.08)
),
1,((-141.44,-8.08)
 .. controls (-141.44,-8.08) and (-155.00,-17.98) .. (-157.33,-17.55)
 .. controls (-159.66,-17.11) and (-160.76,-17.10) .. (-161.47,-20.15)
 .. controls (-162.18,-23.20) and (-166.23,-33.16) .. (-166.23,-33.16)
),
1,((-153.18,-33.42)
 .. controls (-153.18,-33.42) and (-157.78,-21.85) .. (-156.67,-20.47)
 .. controls (-155.56,-19.09) and (-148.12,-16.09) .. (-148.12,-16.09)
),
1,((-148.12,-16.09)
 .. controls (-148.12,-16.09) and (-136.80,-10.08) .. (-135.98,-9.95)
 .. controls (-135.15,-9.82) and (-133.61,-7.19) .. (-134.00,-6.06)
 .. controls (-134.40,-4.94) and (-135.34,-3.54) .. (-133.95,-2.72)
 .. controls (-132.56,-1.89) and (-130.35,-1.08) .. (-130.04,1.01)
 .. controls (-129.72,3.09) and (-129.40,5.18) .. (-127.02,6.68)
 .. controls (-124.64,8.19) and (-122.45,7.89) .. (-118.69,8.94)
 .. controls (-114.93,9.98) and (-107.79,10.05) .. (-107.79,10.05)
),
1,((-107.79,10.05)
 .. controls (-107.79,10.05) and (-104.96,9.61) .. (-102.66,9.87)
 .. controls (-100.37,10.14) and (-99.78,10.89) .. (-97.43,10.80)
 .. controls (-95.07,10.72) and (-95.71,10.23) .. (-92.48,10.95)
 .. controls (-89.22,11.68) and (-91.34,11.46) .. (-90.14,11.43)
 .. controls (-88.95,11.41) and (-85.87,11.89) .. (-85.98,13.63)
 .. controls (-86.09,15.40) and (-86.71,17.48) .. (-86.71,18.63)
 .. controls (-86.72,19.78) and (-86.29,19.07) .. (-85.71,19.99)
 .. controls (-85.14,20.89) and (-84.59,21.64) .. (-85.20,22.11)
 .. controls (-85.80,22.58) and (-88.43,23.46) .. (-87.02,23.58)
 .. controls (-85.63,23.70) and (-82.89,23.36) .. (-82.01,22.27)
 .. controls (-81.13,21.16) and (-79.93,17.13) .. (-79.10,15.21)
 .. controls (-78.27,13.30) and (-76.41,8.71) .. (-74.91,7.46)
 .. controls (-73.39,6.20) and (-72.09,4.65) .. (-70.70,3.18)
 .. controls (-69.32,1.72) and (-68.78,-0.16) .. (-67.81,-1.70)
 .. controls (-66.85,-3.24) and (-66.64,-3.72) .. (-65.47,-4.84)
 .. controls (-64.29,-5.96) and (-62.63,-8.00) .. (-61.72,-7.79)
 .. controls (-60.81,-7.58) and (-60.32,-8.22) .. (-59.82,-5.70)
 .. controls (-59.33,-3.16) and (-59.19,-3.37) .. (-59.54,-0.98)
 .. controls (-59.89,1.42) and (-61.07,6.33) .. (-59.96,8.31)
 .. controls (-58.87,10.26) and (-57.79,11.70) .. (-54.27,12.90)
 .. controls (-50.74,14.10) and (-47.84,15.09) .. (-45.15,15.68)
 .. controls (-42.46,16.27) and (-41.63,16.67) .. (-39.62,17.20)
 .. controls (-37.61,17.72) and (-37.06,17.72) .. (-37.05,19.17)
 .. controls (-37.05,20.63) and (-38.29,22.76) .. (-36.93,23.61)
 .. controls (-35.62,24.42) and (-34.81,24.02) .. (-32.39,23.85)
 .. controls (-29.95,23.69) and (-28.15,23.14) .. (-25.84,23.35)
 .. controls (-23.46,23.56) and (-21.55,23.89) .. (-19.35,24.94)
 .. controls (-17.14,25.99) and (-15.67,26.22) .. (-13.92,25.96)
 .. controls (-12.14,25.70) and (-10.77,25.68) .. (-10.09,24.00)
 .. controls (-9.40,22.33) and (-8.91,19.38) .. (-8.15,17.43)
 .. controls (-7.40,15.49) and (-5.89,10.94) .. (-4.39,8.66)
 .. controls (-2.89,6.39) and (-2.54,5.32) .. (-1.66,2.98)
 .. controls (-0.78,0.63) and (0.56,-0.73) .. (1.06,-3.14)
 .. controls (1.55,-5.56) and (1.76,-6.04) .. (2.60,-8.65)
),
0,((2.60,-8.65)
 .. controls (2.60,-8.65) and (3.04,-14.31) .. (3.76,-16.37)
 .. controls (4.48,-18.43) and (6.66,-19.65) .. (6.66,-19.65)
));
draw_downscrap;
endfig;
beginfig(39);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((6.66,-19.65)
 .. controls (7.93,-20.18) and (7.87,-21.39) .. (10.65,-21.27)
 .. controls (13.44,-21.15) and (12.31,-20.22) .. (15.23,-20.91)
 .. controls (18.15,-21.60) and (21.27,-22.29) .. (23.93,-22.85)
 .. controls (26.58,-23.40) and (26.65,-22.54) .. (29.31,-23.23)
 .. controls (31.96,-23.92) and (31.96,-23.58) .. (35.95,-24.15)
 .. controls (39.93,-24.72) and (40.47,-24.46) .. (43.39,-25.01)
 .. controls (46.31,-25.57) and (48.44,-25.92) .. (51.16,-26.48)
 .. controls (53.88,-27.03) and (56.09,-27.23) .. (58.23,-28.85)
 .. controls (60.37,-30.47) and (65.14,-33.34) .. (67.49,-34.07)
 .. controls (69.84,-34.80) and (73.28,-36.88) .. (74.70,-37.91)
 .. controls (76.12,-38.94) and (78.56,-41.32) .. (80.22,-43.03)
 .. controls (81.89,-44.74) and (85.24,-46.68) .. (87.62,-46.09)
 .. controls (90.02,-45.49) and (93.68,-42.97) .. (96.64,-42.24)
 .. controls (99.61,-41.51) and (100.92,-40.82) .. (103.81,-39.69)
 .. controls (106.70,-38.57) and (109.43,-36.71) .. (113.06,-35.64)
 .. controls (116.68,-34.57) and (123.65,-32.03) .. (125.66,-31.06)
 .. controls (127.67,-30.08) and (130.30,-29.99) .. (130.79,-28.49)
 .. controls (131.27,-27.00) and (131.40,-26.79) .. (130.95,-25.47)
 .. controls (130.50,-24.14) and (129.95,-23.83) .. (131.92,-22.95)
 .. controls (133.88,-22.06) and (134.83,-22.43) .. (137.13,-20.75)
 .. controls (139.39,-19.11) and (142.25,-16.72) .. (145.03,-15.71)
 .. controls (147.90,-14.67) and (150.29,-13.67) .. (153.30,-12.17)
 .. controls (156.35,-10.65) and (163.47,-6.54) .. (166.21,-5.14)
 .. controls (168.97,-3.72) and (170.86,-3.75) .. (171.25,-1.64)
 .. controls (171.64,0.47) and (172.35,1.86) .. (171.52,2.36)
 .. controls (170.69,2.84) and (170.62,3.88) .. (170.62,3.88)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-107.79,10.05)
 .. controls (-107.79,10.05) and (-104.96,9.61) .. (-102.66,9.87)
 .. controls (-100.37,10.14) and (-99.78,10.89) .. (-97.43,10.80)
 .. controls (-95.07,10.72) and (-95.71,10.23) .. (-92.48,10.95)
 .. controls (-89.22,11.68) and (-91.34,11.46) .. (-90.14,11.43)
 .. controls (-88.95,11.41) and (-85.87,11.89) .. (-85.98,13.63)
 .. controls (-86.09,15.40) and (-86.71,17.48) .. (-86.71,18.63)
 .. controls (-86.72,19.78) and (-86.29,19.07) .. (-85.71,19.99)
 .. controls (-85.14,20.89) and (-84.59,21.64) .. (-85.20,22.11)
 .. controls (-85.80,22.58) and (-88.43,23.46) .. (-87.02,23.58)
 .. controls (-85.63,23.70) and (-82.89,23.36) .. (-82.01,22.27)
 .. controls (-81.13,21.16) and (-79.93,17.13) .. (-79.10,15.21)
 .. controls (-78.27,13.30) and (-76.41,8.71) .. (-74.91,7.46)
 .. controls (-73.39,6.20) and (-72.09,4.65) .. (-70.70,3.18)
 .. controls (-69.32,1.72) and (-68.78,-0.16) .. (-67.81,-1.70)
 .. controls (-66.85,-3.24) and (-66.64,-3.72) .. (-65.47,-4.84)
 .. controls (-64.29,-5.96) and (-62.63,-8.00) .. (-61.72,-7.79)
 .. controls (-60.81,-7.58) and (-60.32,-8.22) .. (-59.82,-5.70)
 .. controls (-59.33,-3.16) and (-59.19,-3.37) .. (-59.54,-0.98)
 .. controls (-59.89,1.42) and (-61.07,6.33) .. (-59.96,8.31)
 .. controls (-58.87,10.26) and (-57.79,11.70) .. (-54.27,12.90)
 .. controls (-50.74,14.10) and (-47.84,15.09) .. (-45.15,15.68)
 .. controls (-42.46,16.27) and (-41.63,16.67) .. (-39.62,17.20)
 .. controls (-37.61,17.72) and (-37.06,17.72) .. (-37.05,19.17)
 .. controls (-37.05,20.63) and (-38.29,22.76) .. (-36.93,23.61)
 .. controls (-35.62,24.42) and (-34.81,24.02) .. (-32.39,23.85)
 .. controls (-29.95,23.69) and (-28.15,23.14) .. (-25.84,23.35)
 .. controls (-23.46,23.56) and (-21.55,23.89) .. (-19.35,24.94)
 .. controls (-17.14,25.99) and (-15.67,26.22) .. (-13.92,25.96)
 .. controls (-12.14,25.70) and (-10.77,25.68) .. (-10.09,24.00)
 .. controls (-9.40,22.33) and (-8.91,19.38) .. (-8.15,17.43)
 .. controls (-7.40,15.49) and (-5.89,10.94) .. (-4.39,8.66)
 .. controls (-2.89,6.39) and (-2.54,5.32) .. (-1.66,2.98)
 .. controls (-0.78,0.63) and (0.56,-0.73) .. (1.06,-3.14)
 .. controls (1.55,-5.56) and (1.76,-6.04) .. (2.60,-8.65)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((167.88,3.54)
 .. controls (167.88,3.54) and (168.49,2.67) .. (168.05,1.72)
 .. controls (167.60,0.77) and (168.04,0.35) .. (165.84,0.37)
 .. controls (163.67,0.38) and (160.96,0.59) .. (158.72,0.60)
 .. controls (156.49,0.61) and (151.29,0.63) .. (149.20,0.64)
 .. controls (147.10,0.64) and (145.28,0.99) .. (142.45,1.06)
 .. controls (139.61,1.14) and (138.13,1.08) .. (135.42,0.95)
 .. controls (132.71,0.83) and (131.33,1.75) .. (129.02,0.67)
 .. controls (126.70,-0.42) and (124.48,-0.13) .. (123.70,-2.81)
 .. controls (122.91,-5.51) and (122.91,-7.18) .. (123.08,-9.90)
 .. controls (123.25,-12.60) and (124.75,-14.97) .. (123.10,-16.47)
 .. controls (121.51,-17.93) and (116.99,-19.59) .. (114.76,-20.56)
 .. controls (112.53,-21.54) and (103.92,-24.71) .. (100.52,-26.19)
 .. controls (97.13,-27.67) and (92.93,-29.19) .. (91.40,-29.43)
 .. controls (89.89,-29.67) and (87.84,-30.49) .. (86.05,-29.08)
 .. controls (84.25,-27.66) and (81.55,-26.58) .. (79.85,-25.00)
 .. controls (78.13,-23.41) and (76.33,-23.34) .. (74.14,-21.86)
 .. controls (71.94,-20.38) and (68.62,-18.55) .. (66.79,-17.25)
 .. controls (64.96,-15.94) and (63.58,-15.32) .. (62.41,-14.11)
 .. controls (61.24,-12.89) and (59.63,-10.41) .. (59.63,-10.41)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((56.65,-10.02)
 .. controls (56.65,-10.02) and (58.53,-12.71) .. (57.45,-13.41)
 .. controls (56.38,-14.12) and (53.16,-14.26) .. (51.01,-14.29)
 .. controls (48.87,-14.33) and (45.70,-15.11) .. (43.16,-15.22)
 .. controls (40.63,-15.34) and (39.90,-15.26) .. (37.10,-15.57)
 .. controls (34.30,-15.88) and (30.18,-15.92) .. (28.05,-16.03)
 .. controls (25.92,-16.14) and (22.13,-15.91) .. (19.47,-16.35)
 .. controls (16.80,-16.80) and (14.74,-16.91) .. (12.82,-16.89)
 .. controls (10.90,-16.86) and (9.55,-18.06) .. (9.65,-16.13)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((5.55,-6.02)
 .. controls (4.92,-4.71) and (3.85,0.12) .. (2.67,1.81)
 .. controls (1.50,3.47) and (0.80,7.30) .. (-0.56,9.37)
 .. controls (-1.93,11.44) and (-2.75,13.99) .. (-3.71,16.33)
 .. controls (-4.67,18.67) and (-5.17,21.89) .. (-6.39,23.62)
 .. controls (-7.61,25.36) and (-7.71,27.86) .. (-9.55,28.09)
 .. controls (-11.40,28.32) and (-13.67,29.44) .. (-15.38,28.60)
 .. controls (-17.10,27.75) and (-16.69,27.03) .. (-18.94,26.82)
 .. controls (-21.19,26.61) and (-24.49,26.58) .. (-27.14,26.59)
 .. controls (-29.72,26.61) and (-30.45,27.63) .. (-33.22,27.52)
 .. controls (-35.99,27.42) and (-39.25,28.22) .. (-40.02,26.44)
 .. controls (-40.78,24.66) and (-39.26,22.35) .. (-40.09,21.12)
 .. controls (-40.90,19.89) and (-44.98,18.57) .. (-48.29,17.51)
 .. controls (-51.61,16.45) and (-54.58,15.38) .. (-57.49,14.11)
 .. controls (-60.39,12.84) and (-62.75,13.50) .. (-63.53,11.14)
 .. controls (-64.32,8.74) and (-64.94,9.03) .. (-64.45,7.04)
 .. controls (-63.97,5.07) and (-62.70,2.19) .. (-62.77,0.50)
 .. controls (-62.84,-1.19) and (-63.17,-2.62) .. (-64.68,-1.37)
 .. controls (-66.20,-0.11) and (-67.24,0.17) .. (-67.23,1.91)
 .. controls (-67.22,3.65) and (-67.29,4.00) .. (-68.60,5.61)
 .. controls (-69.92,7.21) and (-72.20,9.87) .. (-73.53,12.43)
 .. controls (-74.84,14.96) and (-75.27,17.77) .. (-76.72,19.41)
 .. controls (-78.17,21.05) and (-79.71,23.78) .. (-80.47,24.60)
 .. controls (-81.22,25.40) and (-81.76,24.85) .. (-83.90,24.90)
 .. controls (-86.04,24.94) and (-86.58,25.46) .. (-87.78,25.80)
 .. controls (-89.00,26.14) and (-90.31,26.76) .. (-90.85,25.52)
 .. controls (-91.40,24.27) and (-91.59,22.15) .. (-90.67,19.89)
 .. controls (-89.76,17.62) and (-87.41,16.48) .. (-89.10,15.57)
 .. controls (-90.79,14.67) and (-91.00,14.19) .. (-93.92,14.01)
 .. controls (-96.84,13.84) and (-98.43,13.96) .. (-100.38,13.68)
 .. controls (-102.33,13.40) and (-103.79,13.31) .. (-104.90,13.35)
 .. controls (-106.01,13.39) and (-107.33,13.43) .. (-107.33,13.43)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-108.64,13.54)
 .. controls (-108.64,13.54) and (-113.99,13.28) .. (-115.51,13.31)
 .. controls (-117.03,13.34) and (-119.27,12.56) .. (-121.91,12.04)
 .. controls (-124.55,11.52) and (-130.53,9.63) .. (-131.94,7.97)
 .. controls (-133.36,6.32) and (-135.67,0.92) .. (-136.67,-1.30)
 .. controls (-137.67,-3.52) and (-135.80,-6.88) .. (-137.18,-7.43)
 .. controls (-138.56,-7.97) and (-140.34,-7.40) .. (-141.44,-8.08)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-148.12,-16.09)
 .. controls (-148.12,-16.09) and (-136.80,-10.08) .. (-135.98,-9.95)
 .. controls (-135.15,-9.82) and (-133.61,-7.19) .. (-134.00,-6.06)
 .. controls (-134.40,-4.94) and (-135.34,-3.54) .. (-133.95,-2.72)
 .. controls (-132.56,-1.89) and (-130.35,-1.08) .. (-130.04,1.01)
 .. controls (-129.72,3.09) and (-129.40,5.18) .. (-127.02,6.68)
 .. controls (-124.64,8.19) and (-122.45,7.89) .. (-118.69,8.94)
 .. controls (-114.93,9.98) and (-107.79,10.05) .. (-107.79,10.05)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-141.44,-8.08)
 .. controls (-141.44,-8.08) and (-155.00,-17.98) .. (-157.33,-17.55)
 .. controls (-159.66,-17.11) and (-160.76,-17.10) .. (-161.47,-20.15)
 .. controls (-162.18,-23.20) and (-166.23,-33.16) .. (-166.23,-33.16)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-153.18,-33.42)
 .. controls (-153.18,-33.42) and (-157.78,-21.85) .. (-156.67,-20.47)
 .. controls (-155.56,-19.09) and (-148.12,-16.09) .. (-148.12,-16.09)
));
drawoptions();
p_rope((-148.19,-25.14),0.0,1.00,(0,0));
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
p_waterflow_permanent((-98.03,19.52),181.4,1.00,(0,0));
string ATTR_code;
ATTR_code := "Q";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char65 \char114 \char114 \char105 \char118 \thfc\char233 \thfb\char101 \ \char100 \char39 \char101 \char97 \char117 \ \thfc\char184 \ \thfb\char118 \char111 \char105 \char114 \mainfont{}etex;
drawoptions();
p_continuation((57.58,-5.27),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
p_waterflow_permanent((59.74,-15.51),186.4,1.00,(0,0));
drawoptions();
p_gypsumflower((147.18,4.52),0.0,1.00,(0,0));
drawoptions();
p_gypsumflower((155.08,5.30),0.0,1.00,(0,0));
drawoptions();
p_gypsumflower((151.22,-18.55),0.0,1.00,(0,0));
drawoptions();
p_gypsumflower((118.89,-5.07),0.0,1.00,(0,0));
drawoptions();
p_gypsumflower((118.90,-12.26),0.0,1.00,(0,0));
drawoptions();
p_u_boss((131.82,-4.60),0.0,1.00,(0,0));
drawoptions();
p_traverse((-106.91,5.22),0.0,1.00,(0,0));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((170.24,-1.37),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((125.80,-2.82),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((126.16,-19.36),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((87.63,-44.83),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((58.67,-26.88),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((7.07,-19.18),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((1.72,0.79),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-10.86,27.76),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-26.09,24.52),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-38.72,26.30),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-38.22,19.25),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-61.72,11.61),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-61.72,-6.74),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-73.79,10.50),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-81.41,24.25),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-88.92,24.91),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-90.23,14.23),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-104.06,11.80),1,0,"");
endfig;
beginfig(40);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char50 \char53 \mainfont{} etex,(-172.35,-25.07),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char51 \mainfont{} etex,(-103.30,34.53),0.0,p_label_mode_label);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.lrt(btex \thaltitude \thfb\char45 \char52 \char51 \mainfont{} etex,(-102.66,9.87),0.0,p_label_mode_altitude);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char109 \char46 \ \char100 \char117 \ \char83 \char101 \char114 \char112 \char101 \char110 \char116 \mainfont{} etex,(-52.33,46.68),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char109 \char46 \ \char100 \char117 \ \char83 \char101 \char114 \char112 \char101 \char110 \char116 \mainfont{} etex,(-113.70,22.99),0.0,p_label_mode_label);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-Solitaire-c-2018-1";
ATTR__scrap := "SP-Solitaire-c-2018-1";
beginfig(41);
ATTR__height := -1;
drawoptions();
l_floormeander(((26.45,-13.45)
 .. controls (26.45,-13.45) and (22.89,-1.99) .. (22.60,-1.41)
 .. controls (22.31,-0.84) and (20.77,1.80) .. (20.77,1.80)
));
ATTR__height := -1;
drawoptions();
l_slope(((41.93,-10.56)
 .. controls (41.93,-10.56) and (23.63,0.60) .. (22.53,6.19)
),0,(0,-1,2.56981),(1,-1,2.56981));
endfig;
beginfig(42);
draw_upscrap(1)(1,((32.86,-23.46)
 .. controls (31.58,-17.26) and (35.02,-18.79) .. (35.64,-17.25)
 .. controls (36.82,-14.31) and (36.87,-9.36) .. (37.40,-8.35)
 .. controls (39.33,-4.76) and (42.25,-0.25) .. (41.09,3.00)
 .. controls (40.36,5.05) and (35.17,14.59) .. (31.76,13.32)
 .. controls (28.35,12.05) and (23.78,4.31) .. (21.43,2.29)
 .. controls (19.00,0.20) and (15.92,-2.42) .. (14.35,-1.40)
 .. controls (12.57,-0.26) and (10.70,4.01) .. (10.76,6.30)
 .. controls (10.81,8.59) and (11.30,10.84) .. (9.28,13.13)
 .. controls (7.25,15.42) and (6.13,19.74) .. (4.09,21.70)
 .. controls (2.05,23.67) and (-0.41,26.87) .. (-4.56,26.51)
 .. controls (-8.65,26.15) and (-14.43,26.43) .. (-16.74,25.58)
 .. controls (-19.04,24.73) and (-20.36,24.56) .. (-21.41,22.43)
 .. controls (-22.45,20.30) and (-22.68,17.92) .. (-27.46,17.42)
 .. controls (-32.23,16.91) and (-36.72,18.38) .. (-39.31,15.09)
 .. controls (-42.22,11.39) and (-42.25,4.15) .. (-41.84,1.96)
 .. controls (-41.43,-0.22) and (-41.30,-1.48) .. (-41.30,-1.48)
),
1,((-35.77,0.42)
 .. controls (-35.77,0.42) and (-38.94,7.58) .. (-36.25,10.04)
 .. controls (-34.14,11.97) and (-30.16,13.40) .. (-26.02,14.10)
 .. controls (-21.90,14.79) and (-22.14,17.60) .. (-20.67,19.38)
 .. controls (-19.19,21.16) and (-17.85,24.30) .. (-15.29,24.72)
 .. controls (-12.74,25.14) and (-9.33,24.88) .. (-6.09,24.11)
 .. controls (-2.86,23.34) and (-0.88,22.54) .. (1.11,20.32)
 .. controls (3.12,18.09) and (7.87,13.46) .. (7.78,10.44)
 .. controls (7.69,7.45) and (7.52,7.28) .. (8.24,4.52)
 .. controls (8.96,1.77) and (6.87,-2.15) .. (8.43,-2.81)
 .. controls (9.88,-3.42) and (12.19,-6.64) .. (14.83,-9.83)
 .. controls (17.54,-13.10) and (19.04,-16.14) .. (21.74,-18.65)
 .. controls (24.43,-21.15) and (27.64,-25.66) .. (29.53,-26.87)
));
draw_downscrap;
endfig;
beginfig(43);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((32.86,-23.46)
 .. controls (31.58,-17.26) and (35.02,-18.79) .. (35.64,-17.25)
 .. controls (36.82,-14.31) and (36.87,-9.36) .. (37.40,-8.35)
 .. controls (39.33,-4.76) and (42.25,-0.25) .. (41.09,3.00)
 .. controls (40.36,5.05) and (35.17,14.59) .. (31.76,13.32)
 .. controls (28.35,12.05) and (23.78,4.31) .. (21.43,2.29)
 .. controls (19.00,0.20) and (15.92,-2.42) .. (14.35,-1.40)
 .. controls (12.57,-0.26) and (10.70,4.01) .. (10.76,6.30)
 .. controls (10.81,8.59) and (11.30,10.84) .. (9.28,13.13)
 .. controls (7.25,15.42) and (6.13,19.74) .. (4.09,21.70)
 .. controls (2.05,23.67) and (-0.41,26.87) .. (-4.56,26.51)
 .. controls (-8.65,26.15) and (-14.43,26.43) .. (-16.74,25.58)
 .. controls (-19.04,24.73) and (-20.36,24.56) .. (-21.41,22.43)
 .. controls (-22.45,20.30) and (-22.68,17.92) .. (-27.46,17.42)
 .. controls (-32.23,16.91) and (-36.72,18.38) .. (-39.31,15.09)
 .. controls (-42.22,11.39) and (-42.25,4.15) .. (-41.84,1.96)
 .. controls (-41.43,-0.22) and (-41.30,-1.48) .. (-41.30,-1.48)
));
drawoptions(withcolor (0.00000,0.40000,0.80000,0.00000));
p_flowstone((33.23,9.15),0.0,1.00,(0,0));
drawoptions(withcolor (0.00000,0.40000,0.80000,0.00000));
p_flowstone((36.84,4.79),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-35.77,0.42)
 .. controls (-35.77,0.42) and (-38.94,7.58) .. (-36.25,10.04)
 .. controls (-34.14,11.97) and (-30.16,13.40) .. (-26.02,14.10)
 .. controls (-21.90,14.79) and (-22.14,17.60) .. (-20.67,19.38)
 .. controls (-19.19,21.16) and (-17.85,24.30) .. (-15.29,24.72)
 .. controls (-12.74,25.14) and (-9.33,24.88) .. (-6.09,24.11)
 .. controls (-2.86,23.34) and (-0.88,22.54) .. (1.11,20.32)
 .. controls (3.12,18.09) and (7.87,13.46) .. (7.78,10.44)
 .. controls (7.69,7.45) and (7.52,7.28) .. (8.24,4.52)
 .. controls (8.96,1.77) and (6.87,-2.15) .. (8.43,-2.81)
 .. controls (9.88,-3.42) and (12.19,-6.64) .. (14.83,-9.83)
 .. controls (17.54,-13.10) and (19.04,-16.14) .. (21.74,-18.65)
 .. controls (24.43,-21.15) and (27.64,-25.66) .. (29.53,-26.87)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((30.72,-26.71),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((31.76,13.32),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((15.82,-7.08),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((8.96,-1.58),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((8.43,11.84),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-0.04,24.19),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-19.21,24.22),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-39.28,13.49),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-39.54,-4.59),1,0,"");
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-solitaire2019-3";
ATTR__scrap := "SP-solitaire2019-3";
beginfig(44);
ATTR__height := -1;
drawoptions();
l_pit(((13.04,22.32)
 .. controls (13.04,22.32) and (11.52,24.93) .. (11.51,27.63)
));
ATTR__height := -1;
drawoptions();
l_pit(((7.01,18.64)
 .. controls (7.01,18.64) and (7.19,15.75) .. (9.44,16.02)
 .. controls (11.69,16.29) and (12.95,21.33) .. (12.95,21.33)
));
ATTR__height := -1;
drawoptions();
l_slope(((-7.38,-17.63)
 .. controls (-7.38,-17.63) and (-5.49,-22.58) .. (-7.12,-24.19)
),0,(0,-1,1.79999),(1,-1,1.79999));
ATTR__height := -1;
drawoptions();
l_pit(((-9.26,-17.35)
 .. controls (-9.26,-17.35) and (-7.65,-22.03) .. (-9.82,-23.29)
));
endfig;
beginfig(45);
draw_upscrap(1)(1,((-9.45,-21.40)
 .. controls (-9.45,-21.40) and (-9.81,-22.57) .. (-7.48,-23.29)
 .. controls (-5.14,-24.02) and (4.40,-27.63) .. (5.12,-24.66)
 .. controls (5.84,-21.69) and (11.33,6.39) .. (12.77,10.62)
 .. controls (14.21,14.85) and (11.69,22.14) .. (12.32,22.68)
 .. controls (12.95,23.22) and (13.58,22.95) .. (13.58,22.95)
),
1,((13.22,27.63)
 .. controls (13.22,27.63) and (12.32,27.09) .. (9.09,25.29)
 .. controls (5.85,23.49) and (-2.43,18.64) .. (-4.23,20.80)
 .. controls (-6.03,22.96) and (-7.46,25.84) .. (-7.46,25.84)
),
0,((-7.46,25.84)
 .. controls (-7.46,25.84) and (-14.21,16.49) .. (-11.16,12.26)
 .. controls (-8.10,8.03) and (-5.13,6.95) .. (-5.13,6.95)
),
1,((-5.13,6.95)
 .. controls (-5.13,6.95) and (-1.71,16.84) .. (1.71,17.20)
 .. controls (5.12,17.56) and (8.72,21.34) .. (7.64,18.45)
 .. controls (6.56,15.57) and (-0.37,-1.17) .. (-3.34,-7.20)
 .. controls (-6.30,-13.22) and (-6.29,-16.73) .. (-7.02,-18.44)
 .. controls (-7.74,-20.14) and (-9.00,-19.42) .. (-9.00,-19.42)
));
draw_downscrap;
endfig;
beginfig(46);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((13.22,27.63)
 .. controls (13.22,27.63) and (12.32,27.09) .. (9.09,25.29)
 .. controls (5.85,23.49) and (-2.43,18.64) .. (-4.23,20.80)
 .. controls (-6.03,22.96) and (-7.46,25.84) .. (-7.46,25.84)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-5.13,6.95)
 .. controls (-5.13,6.95) and (-1.71,16.84) .. (1.71,17.20)
 .. controls (5.12,17.56) and (8.72,21.34) .. (7.64,18.45)
 .. controls (6.56,15.57) and (-0.37,-1.17) .. (-3.34,-7.20)
 .. controls (-6.30,-13.22) and (-6.29,-16.73) .. (-7.02,-18.44)
 .. controls (-7.74,-20.14) and (-9.00,-19.42) .. (-9.00,-19.42)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-9.45,-21.40)
 .. controls (-9.45,-21.40) and (-9.81,-22.57) .. (-7.48,-23.29)
 .. controls (-5.14,-24.02) and (4.40,-27.63) .. (5.12,-24.66)
 .. controls (5.84,-21.69) and (11.33,6.39) .. (12.77,10.62)
 .. controls (14.21,14.85) and (11.69,22.14) .. (12.32,22.68)
 .. controls (12.95,23.22) and (13.58,22.95) .. (13.58,22.95)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((11.35,23.98),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-10.52,14.69),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((0.92,-25.12),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-6.36,-21.25),1,0,"");
endfig;
beginfig(47);
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char53 \mainfont{} etex,(-11.42,-10.33),0.0,p_label_mode_height);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-Solitaire-c-2018_3";
ATTR__scrap := "SP-Solitaire-c-2018_3";
beginfig(48);
drawoptions(withcolor (0.00000,0.36538,0.88462,0.48000));
p_clay((-42.98,-15.70),0.0,1.00,(0,0));
drawoptions(withcolor (0.00000,0.36538,0.88462,0.48000));
p_clay((-35.61,-22.47),0.0,1.00,(0,0));
drawoptions(withcolor (0.00000,0.36538,0.88462,0.48000));
p_clay((-27.19,-23.04),0.0,1.00,(0,0));
drawoptions(withcolor (0.00000,0.36538,0.88462,0.48000));
p_clay((-21.77,-21.35),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_slope(((-24.34,-14.62)
 .. controls (-24.34,-14.62) and (-26.96,-17.60) .. (-29.99,-17.52)
 .. controls (-33.05,-17.44) and (-36.56,-16.99) .. (-37.62,-15.30)
 .. controls (-38.74,-13.52) and (-39.38,-12.74) .. (-42.53,-11.04)
 .. controls (-45.53,-9.43) and (-48.70,-6.84) .. (-48.70,-6.84)
),0,(0,-1,2.69242),(1,-1,2.69242),(4,-1,2.69242));
ATTR__height := -1;
drawoptions();
l_floormeander(((1.98,4.17)
 .. controls (1.98,4.17) and (-5.83,-1.76) .. (-8.20,-4.53)
 .. controls (-10.56,-7.29) and (-17.22,-14.61) .. (-17.22,-14.61)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((11.05,13.25)
 -- (13.27,14.49)
 -- (13.67,11.07)
 -- (11.80,11.15)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((16.34,11.36)
 -- (17.79,12.19)
 -- (19.22,10.60)
 -- (17.03,10.03)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((21.22,13.48)
 -- (22.25,15.58)
 -- (23.28,14.32)
 -- (23.07,12.46)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_chimney(((19.27,20.51)
 .. controls (19.27,20.51) and (16.46,18.78) .. (18.23,18.72)
 .. controls (19.97,18.66) and (22.37,17.89) .. (22.10,18.97)
 .. controls (21.84,20.08) and (19.27,20.51) .. cycle
));
endfig;
beginfig(49);
draw_upscrap(1)(1,((68.99,-5.88)
 .. controls (68.99,-5.88) and (67.82,-2.48) .. (66.21,-2.08)
 .. controls (64.62,-1.67) and (63.55,-2.78) .. (62.60,-1.63)
 .. controls (61.65,-0.49) and (58.89,5.33) .. (56.45,7.29)
 .. controls (54.00,9.25) and (52.96,10.33) .. (51.33,12.87)
 .. controls (49.69,15.40) and (48.71,17.08) .. (46.88,18.04)
 .. controls (45.08,18.99) and (44.80,19.61) .. (41.71,19.15)
 .. controls (38.60,18.67) and (38.77,19.31) .. (35.29,19.29)
 .. controls (31.81,19.27) and (32.08,19.27) .. (29.67,19.89)
 .. controls (27.27,20.51) and (24.52,22.33) .. (21.28,21.62)
 .. controls (17.94,20.89) and (15.71,20.01) .. (11.74,17.74)
 .. controls (8.08,15.65) and (0.11,10.85) .. (-2.29,9.02)
 .. controls (-4.68,7.20) and (-9.45,3.85) .. (-12.52,0.99)
 .. controls (-15.60,-1.87) and (-18.10,-5.57) .. (-21.59,-8.23)
 .. controls (-25.07,-10.88) and (-27.16,-13.01) .. (-29.86,-12.58)
 .. controls (-32.54,-12.15) and (-33.60,-12.56) .. (-38.59,-9.18)
 .. controls (-44.38,-5.25) and (-48.43,-4.36) .. (-49.71,-2.72)
 .. controls (-51.02,-1.04) and (-54.12,1.08) .. (-54.49,2.64)
 .. controls (-54.87,4.20) and (-55.51,6.48) .. (-56.78,8.65)
 .. controls (-58.04,10.81) and (-59.13,12.52) .. (-60.58,13.15)
 .. controls (-62.03,13.77) and (-62.94,14.05) .. (-62.94,14.05)
),
1,((-65.03,11.33)
 .. controls (-65.03,11.33) and (-55.25,-0.83) .. (-53.88,-3.08)
 .. controls (-52.52,-5.32) and (-50.76,-8.33) .. (-49.29,-10.46)
 .. controls (-47.82,-12.59) and (-44.62,-15.77) .. (-44.56,-17.10)
),
1,((-22.72,-25.33)
 .. controls (-22.72,-25.33) and (-19.55,-23.39) .. (-17.69,-22.24)
 .. controls (-15.83,-21.09) and (-11.93,-19.92) .. (-10.10,-16.91)
 .. controls (-8.21,-13.81) and (-6.61,-12.34) .. (-4.50,-10.04)
 .. controls (-2.39,-7.74) and (1.22,-4.74) .. (2.67,-3.15)
 .. controls (4.11,-1.57) and (4.77,0.24) .. (7.32,0.67)
 .. controls (9.91,1.10) and (14.03,3.14) .. (14.37,4.63)
 .. controls (14.71,6.12) and (14.17,6.61) .. (15.20,6.56)
 .. controls (16.23,6.52) and (16.94,4.95) .. (18.31,6.20)
 .. controls (19.67,7.45) and (20.58,8.80) .. (22.45,10.18)
 .. controls (24.28,11.53) and (26.92,13.99) .. (30.96,14.18)
 .. controls (35.05,14.38) and (37.99,14.85) .. (41.39,14.68)
 .. controls (44.78,14.51) and (47.25,14.23) .. (47.76,12.50)
 .. controls (48.27,10.76) and (49.31,6.46) .. (50.92,4.94)
 .. controls (52.52,3.41) and (53.36,0.31) .. (54.55,-2.78)
 .. controls (55.74,-5.87) and (56.27,-8.54) .. (56.85,-10.85)
 .. controls (57.43,-13.15) and (57.79,-14.46) .. (59.52,-16.47)
 .. controls (61.25,-18.47) and (62.58,-20.83) .. (62.58,-20.83)
));
draw_downscrap;
endfig;
beginfig(50);
drawoptions();
p_narrowend((-68.99,21.92),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-65.03,11.33)
 .. controls (-65.03,11.33) and (-55.25,-0.83) .. (-53.88,-3.08)
 .. controls (-52.52,-5.32) and (-50.76,-8.33) .. (-49.29,-10.46)
 .. controls (-47.82,-12.59) and (-44.62,-15.77) .. (-44.56,-17.10)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-22.72,-25.33)
 .. controls (-22.72,-25.33) and (-19.55,-23.39) .. (-17.69,-22.24)
 .. controls (-15.83,-21.09) and (-11.93,-19.92) .. (-10.10,-16.91)
 .. controls (-8.21,-13.81) and (-6.61,-12.34) .. (-4.50,-10.04)
 .. controls (-2.39,-7.74) and (1.22,-4.74) .. (2.67,-3.15)
 .. controls (4.11,-1.57) and (4.77,0.24) .. (7.32,0.67)
 .. controls (9.91,1.10) and (14.03,3.14) .. (14.37,4.63)
 .. controls (14.71,6.12) and (14.17,6.61) .. (15.20,6.56)
 .. controls (16.23,6.52) and (16.94,4.95) .. (18.31,6.20)
 .. controls (19.67,7.45) and (20.58,8.80) .. (22.45,10.18)
 .. controls (24.28,11.53) and (26.92,13.99) .. (30.96,14.18)
 .. controls (35.05,14.38) and (37.99,14.85) .. (41.39,14.68)
 .. controls (44.78,14.51) and (47.25,14.23) .. (47.76,12.50)
 .. controls (48.27,10.76) and (49.31,6.46) .. (50.92,4.94)
 .. controls (52.52,3.41) and (53.36,0.31) .. (54.55,-2.78)
 .. controls (55.74,-5.87) and (56.27,-8.54) .. (56.85,-10.85)
 .. controls (57.43,-13.15) and (57.79,-14.46) .. (59.52,-16.47)
 .. controls (61.25,-18.47) and (62.58,-20.83) .. (62.58,-20.83)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((68.99,-5.88)
 .. controls (68.99,-5.88) and (67.82,-2.48) .. (66.21,-2.08)
 .. controls (64.62,-1.67) and (63.55,-2.78) .. (62.60,-1.63)
 .. controls (61.65,-0.49) and (58.89,5.33) .. (56.45,7.29)
 .. controls (54.00,9.25) and (52.96,10.33) .. (51.33,12.87)
 .. controls (49.69,15.40) and (48.71,17.08) .. (46.88,18.04)
 .. controls (45.08,18.99) and (44.80,19.61) .. (41.71,19.15)
 .. controls (38.60,18.67) and (38.77,19.31) .. (35.29,19.29)
 .. controls (31.81,19.27) and (32.08,19.27) .. (29.67,19.89)
 .. controls (27.27,20.51) and (24.52,22.33) .. (21.28,21.62)
 .. controls (17.94,20.89) and (15.71,20.01) .. (11.74,17.74)
 .. controls (8.08,15.65) and (0.11,10.85) .. (-2.29,9.02)
 .. controls (-4.68,7.20) and (-9.45,3.85) .. (-12.52,0.99)
 .. controls (-15.60,-1.87) and (-18.10,-5.57) .. (-21.59,-8.23)
 .. controls (-25.07,-10.88) and (-27.16,-13.01) .. (-29.86,-12.58)
 .. controls (-32.54,-12.15) and (-33.60,-12.56) .. (-38.59,-9.18)
 .. controls (-44.38,-5.25) and (-48.43,-4.36) .. (-49.71,-2.72)
 .. controls (-51.02,-1.04) and (-54.12,1.08) .. (-54.49,2.64)
 .. controls (-54.87,4.20) and (-55.51,6.48) .. (-56.78,8.65)
 .. controls (-58.04,10.81) and (-59.13,12.52) .. (-60.58,13.15)
 .. controls (-62.03,13.77) and (-62.94,14.05) .. (-62.94,14.05)
));
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
p_waterflow_permanent((19.37,22.85),183.4,1.00,(0,0));
drawoptions();
p_claytree((24.79,4.74),0.0,1.00,(0,0));
drawoptions(withcolor (0.00000,0.40000,0.80000,0.00000));
p_flowstone((13.28,24.57),0.0,1.00,(0,0));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((63.18,-2.89),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((46.91,16.51),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((18.19,17.51),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((21.04,9.68),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((4.78,5.32),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-22.79,-13.98),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-38.81,-13.98),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-53.29,-0.47),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-62.57,12.78),1,0,"");
endfig;
beginfig(51);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char99 \char111 \char108 \char109 \char46 \mainfont{} etex,(-58.18,25.33),0.0,p_label_mode_label);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.rt(btex \thaltitude \thfb\char45 \char50 \char53 \mainfont{} etex,(-60.58,13.15),0.0,p_label_mode_altitude);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-sol2017-1";
ATTR__scrap := "SP-sol2017-1";
beginfig(52);
ATTR__height := -1;
drawoptions();
l_rockborder(((-1.10,49.59)
 -- (2.16,50.15)
 -- (2.15,48.65)
 -- (-0.02,48.24)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-0.59,44.71)
 -- (0.37,45.93)
 -- (0.35,43.63)
 -- (-1.01,42.94)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((1.84,43.77)
 -- (3.48,45.27)
 -- (4.28,43.65)
 -- (2.78,42.42)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-0.01,40.37)
 -- (1.42,41.26)
 -- (2.56,39.78)
 -- (0.80,38.55)
 -- (-0.62,38.75)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-12.32,2.83)
 -- (-14.43,3.88)
 -- (-13.75,5.29)
 -- (-11.48,5.46)
 -- (-11.38,3.93)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-13.64,1.29)
 -- (-12.45,0.47)
 -- (-13.46,-1.17)
 -- (-15.49,-2.01)
 -- (-15.27,-0.22)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-11.01,-4.12)
 -- (-10.03,-2.36)
 -- (-8.99,-3.52)
 -- (-9.09,-5.13)
 -- (-11.14,-5.21)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-5.22,-4.84)
 -- (-4.00,-3.44)
 -- (-2.49,-4.83)
 -- (-3.34,-6.18)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((9.57,-6.42)
 -- (11.71,-6.06)
 -- (12.32,-8.20)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((29.73,-33.17)
 -- (30.80,-32.50)
 -- (31.76,-33.76)
 -- (30.46,-35.34)
 -- (29.51,-34.35)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((30.78,-40.36)
 -- (30.50,-37.55)
 -- (32.39,-38.00)
 -- (32.06,-40.91)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((31.59,-42.62)
 -- (32.96,-41.98)
 -- (34.07,-42.91)
 -- (34.15,-44.38)
 -- (32.25,-44.34)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((37.09,-54.37)
 -- (35.56,-51.97)
 -- (36.88,-50.70)
 -- (38.16,-53.60)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((38.94,-55.48)
 -- (39.56,-58.77)
 -- (38.10,-58.74)
 -- (37.53,-56.46)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_slope(((27.67,-17.13)
 .. controls (27.67,-17.13) and (24.59,-19.32) .. (24.65,-20.73)
 .. controls (24.71,-22.14) and (24.34,-26.31) .. (24.34,-26.31)
),0,(0,-1,2.13051),(2,-1,2.13051));
ATTR__height := -1;
drawoptions();
l_slope(((9.29,-2.40)
 .. controls (9.29,-2.40) and (4.98,-2.66) .. (5.35,-5.59)
 .. controls (5.75,-8.69) and (6.53,-11.08) .. (6.53,-11.08)
),0,(0,-1,2.13051),(2,-1,2.13051));
ATTR__height := -1;
drawoptions();
l_slope(((2.81,-0.57)
 .. controls (2.81,-0.57) and (0.98,-2.39) .. (1.23,-5.04)
 .. controls (1.49,-7.74) and (1.70,-8.93) .. (2.20,-9.74)
),0,(0,-1,2.13051),(2,-1,2.13051));
ATTR__height := -1;
drawoptions();
l_slope(((-3.09,0.38)
 .. controls (-3.09,0.38) and (-7.38,-0.33) .. (-6.79,-3.45)
 .. controls (-6.22,-6.51) and (-6.31,-8.36) .. (-5.99,-9.71)
),0,(0,-1,2.13051),(2,-1,2.13051));
ATTR__height := -1;
drawoptions();
l_slope(((-10.72,-0.17)
 .. controls (-10.72,-0.17) and (-13.31,-1.99) .. (-13.51,-4.29)
 .. controls (-13.72,-6.57) and (-12.91,-8.94) .. (-12.91,-8.94)
),0,(0,-1,2.13051),(2,-1,2.13051));
ATTR__height := -1;
drawoptions();
l_slope(((-33.13,6.15)
 .. controls (-33.13,6.15) and (-36.05,3.63) .. (-37.03,1.13)
 .. controls (-38.01,-1.40) and (-39.05,-4.93) .. (-39.05,-4.93)
),0,(0,-1,2.13051),(2,-1,2.13051));
ATTR__height := -1;
drawoptions();
l_slope(((-31.16,6.21)
 .. controls (-31.16,6.21) and (-32.61,3.09) .. (-32.76,-0.00)
 .. controls (-32.91,-3.14) and (-32.80,-5.58) .. (-32.16,-6.98)
),0,(0,-1,2.13051),(2,-1,2.13051));
ATTR__height := -1;
drawoptions();
l_slope(((24.98,-13.84)
 .. controls (24.98,-13.84) and (20.37,-14.12) .. (20.41,-16.92)
 .. controls (20.44,-19.73) and (20.38,-21.50) .. (20.38,-21.50)
),0,(0,-1,2.13051),(2,-1,2.13051));
ATTR__height := -1;
drawoptions();
l_slope(((-9.37,18.45)
 .. controls (-9.37,18.45) and (-9.67,12.65) .. (-8.67,11.24)
 .. controls (-7.67,9.81) and (-7.29,7.81) .. (-5.82,7.52)
),0,(0,-1,2.13051),(2,-1,2.13051));
ATTR__height := -1;
drawoptions();
l_slope(((-5.64,19.28)
 .. controls (-5.64,19.28) and (-6.09,14.74) .. (-4.83,13.40)
 .. controls (-3.54,12.04) and (-2.84,12.09) .. (-1.22,11.99)
),0,(0,-1,2.13051),(2,-1,2.13051));
ATTR__height := -1;
drawoptions();
l_slope(((-4.34,21.42)
 .. controls (-4.34,21.42) and (-4.27,18.49) .. (-2.33,17.35)
 .. controls (-0.43,16.23) and (0.80,16.25) .. (1.34,16.25)
),0,(0,-1,2.13051),(2,-1,2.13051));
ATTR__height := -1;
drawoptions();
l_slope(((3.15,27.84)
 .. controls (3.15,27.84) and (1.17,28.63) .. (-0.44,28.01)
 .. controls (-2.06,27.40) and (-3.00,26.72) .. (-3.00,26.72)
),0,(0,-1,2.13051),(2,-1,2.13051));
ATTR__height := -1;
drawoptions();
l_slope(((3.58,32.70)
 .. controls (3.58,32.70) and (1.95,34.04) .. (-0.08,33.48)
 .. controls (-2.11,32.93) and (-2.78,32.11) .. (-3.46,31.64)
),0,(0,-1,2.13051),(2,-1,2.13051));
ATTR__height := -1;
drawoptions();
l_pit(((-3.81,50.46)
 .. controls (-2.52,50.26) and (-0.34,50.41) .. (2.50,50.55)
 .. controls (5.34,50.70) and (8.92,50.51) .. (8.92,50.51)
));
ATTR__height := -1;
drawoptions();
l_pit(((-29.46,7.86)
 .. controls (-29.46,7.86) and (-27.50,5.86) .. (-27.88,3.99)
 .. controls (-28.26,2.07) and (-30.75,-0.67) .. (-30.53,-3.20)
 .. controls (-30.32,-5.63) and (-29.77,-7.56) .. (-29.77,-7.56)
));
ATTR__height := -1;
drawoptions();
l_pit(((-22.85,16.15)
 .. controls (-22.85,16.15) and (-25.49,9.92) .. (-28.76,9.17)
));
ATTR__height := -1;
drawoptions();
l_pit(((-14.95,7.94)
 .. controls (-14.95,7.94) and (-16.42,5.37) .. (-18.18,2.42)
 .. controls (-19.93,-0.55) and (-19.92,-0.67) .. (-20.20,-3.49)
 .. controls (-20.48,-6.30) and (-20.21,-8.38) .. (-20.21,-8.38)
));
endfig;
beginfig(53);
draw_upscrap(1)(1,((-40.81,2.36)
 .. controls (-40.81,2.36) and (-37.85,-5.30) .. (-36.36,-5.64)
 .. controls (-34.88,-5.99) and (-32.06,-6.15) .. (-29.44,-5.91)
 .. controls (-27.01,-5.69) and (-25.27,-4.62) .. (-23.10,-4.76)
 .. controls (-19.77,-4.99) and (-19.16,-6.24) .. (-16.67,-6.49)
 .. controls (-13.99,-6.76) and (-12.72,-6.69) .. (-9.53,-7.68)
 .. controls (-6.57,-8.60) and (-8.21,-6.32) .. (-7.15,-7.24)
 .. controls (-6.07,-8.17) and (-6.36,-9.22) .. (-2.95,-8.91)
 .. controls (0.40,-8.60) and (4.49,-7.33) .. (7.13,-8.44)
 .. controls (9.93,-9.61) and (14.44,-11.82) .. (16.42,-14.21)
 .. controls (18.43,-16.64) and (23.03,-22.54) .. (25.26,-25.01)
 .. controls (27.48,-27.47) and (28.72,-26.86) .. (28.93,-31.00)
 .. controls (29.14,-35.13) and (29.07,-39.54) .. (29.73,-41.73)
 .. controls (30.40,-43.93) and (32.80,-46.91) .. (33.95,-49.80)
 .. controls (35.11,-52.70) and (36.70,-56.71) .. (36.70,-56.71)
 -- (38.06,-60.41)
),
1,((40.81,-60.07)
 .. controls (40.81,-60.07) and (40.49,-58.80) .. (40.05,-56.27)
 .. controls (39.61,-53.74) and (39.39,-53.20) .. (38.35,-50.41)
 .. controls (37.33,-47.66) and (35.91,-44.35) .. (34.96,-42.58)
 .. controls (34.01,-40.81) and (32.59,-40.47) .. (32.78,-36.19)
 .. controls (32.97,-31.91) and (33.69,-29.69) .. (32.18,-26.45)
 .. controls (30.65,-23.16) and (27.68,-19.60) .. (25.60,-16.69)
 .. controls (23.54,-13.82) and (22.09,-13.47) .. (19.88,-11.41)
 .. controls (17.68,-9.37) and (19.38,-9.99) .. (17.87,-8.38)
),
1,((17.87,-8.38)
 .. controls (17.87,-8.38) and (17.07,-5.09) .. (11.75,-4.23)
),
1,((11.75,-4.23)
 .. controls (7.75,-3.43) and (10.79,-3.48) .. (7.03,-2.80)
),
1,((-7.46,0.80)
 .. controls (-10.47,-1.64) and (-12.73,-2.64) .. (-12.48,-0.78)
 .. controls (-12.21,1.24) and (-11.27,3.07) .. (-8.62,6.03)
 .. controls (-5.95,9.00) and (-5.07,11.99) .. (-2.39,15.01)
 .. controls (0.28,18.01) and (1.74,19.67) .. (1.80,23.64)
 .. controls (1.85,27.56) and (2.76,33.50) .. (3.85,38.23)
 .. controls (4.94,42.98) and (6.46,46.09) .. (7.15,48.94)
 .. controls (7.85,51.79) and (8.25,53.28) .. (8.79,55.31)
 .. controls (9.33,57.35) and (9.59,59.51) .. (9.59,59.51)
),
1,((-5.85,60.41)
 .. controls (-5.85,60.41) and (-2.98,58.80) .. (-2.71,56.09)
 .. controls (-2.43,53.38) and (-2.86,50.26) .. (-2.89,45.78)
 .. controls (-2.92,41.30) and (-1.71,40.36) .. (-2.12,36.44)
 .. controls (-2.52,32.52) and (-2.65,31.44) .. (-2.62,28.88)
 .. controls (-2.59,26.31) and (-1.65,23.03) .. (-3.57,20.80)
 .. controls (-5.56,18.49) and (-5.42,16.87) .. (-7.94,16.91)
 .. controls (-10.28,16.96) and (-7.71,13.04) .. (-9.88,11.88)
 .. controls (-14.05,9.65) and (-17.20,4.96) .. (-18.52,3.22)
 .. controls (-21.63,-0.89) and (-22.48,3.27) .. (-22.81,5.87)
 .. controls (-23.05,7.80) and (-11.88,16.01) .. (-11.81,19.15)
 .. controls (-11.74,22.27) and (-12.05,27.78) .. (-12.05,27.78)
),
1,((-15.32,28.15)
 .. controls (-15.32,28.15) and (-15.35,22.54) .. (-17.26,19.80)
 .. controls (-19.33,16.83) and (-21.36,14.25) .. (-24.15,13.90)
 .. controls (-27.08,13.53) and (-29.49,13.08) .. (-29.49,13.08)
),
1,((-30.05,10.18)
 .. controls (-30.05,10.18) and (-28.20,10.15) .. (-28.11,8.91)
 .. controls (-28.01,7.68) and (-29.55,5.59) .. (-31.68,5.38)
 .. controls (-33.67,5.19) and (-36.21,6.54) .. (-36.21,6.54)
));
draw_downscrap;
endfig;
beginfig(54);
drawoptions();
p_gypsumflower((31.52,-53.51),0.0,1.00,(0,0));
drawoptions();
p_gypsumflower((32.35,-58.54),0.0,1.00,(0,0));
drawoptions();
p_continuation((-14.07,34.29),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-40.81,2.36)
 .. controls (-40.81,2.36) and (-37.85,-5.30) .. (-36.36,-5.64)
 .. controls (-34.88,-5.99) and (-32.06,-6.15) .. (-29.44,-5.91)
 .. controls (-27.01,-5.69) and (-25.27,-4.62) .. (-23.10,-4.76)
 .. controls (-19.77,-4.99) and (-19.16,-6.24) .. (-16.67,-6.49)
 .. controls (-13.99,-6.76) and (-12.72,-6.69) .. (-9.53,-7.68)
 .. controls (-6.57,-8.60) and (-8.21,-6.32) .. (-7.15,-7.24)
 .. controls (-6.07,-8.17) and (-6.36,-9.22) .. (-2.95,-8.91)
 .. controls (0.40,-8.60) and (4.49,-7.33) .. (7.13,-8.44)
 .. controls (9.93,-9.61) and (14.44,-11.82) .. (16.42,-14.21)
 .. controls (18.43,-16.64) and (23.03,-22.54) .. (25.26,-25.01)
 .. controls (27.48,-27.47) and (28.72,-26.86) .. (28.93,-31.00)
 .. controls (29.14,-35.13) and (29.07,-39.54) .. (29.73,-41.73)
 .. controls (30.40,-43.93) and (32.80,-46.91) .. (33.95,-49.80)
 .. controls (35.11,-52.70) and (36.70,-56.71) .. (36.70,-56.71)
 -- (38.06,-60.41)
));
drawoptions();
p_rope((-39.79,-10.73),0.0,1.00,(0,0));
drawoptions();
p_rope((-20.63,-23.16),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-7.46,0.80)
 .. controls (-10.47,-1.64) and (-12.73,-2.64) .. (-12.48,-0.78)
 .. controls (-12.21,1.24) and (-11.27,3.07) .. (-8.62,6.03)
 .. controls (-5.95,9.00) and (-5.07,11.99) .. (-2.39,15.01)
 .. controls (0.28,18.01) and (1.74,19.67) .. (1.80,23.64)
 .. controls (1.85,27.56) and (2.76,33.50) .. (3.85,38.23)
 .. controls (4.94,42.98) and (6.46,46.09) .. (7.15,48.94)
 .. controls (7.85,51.79) and (8.25,53.28) .. (8.79,55.31)
 .. controls (9.33,57.35) and (9.59,59.51) .. (9.59,59.51)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((11.75,-4.23)
 .. controls (7.75,-3.43) and (10.79,-3.48) .. (7.03,-2.80)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((40.81,-60.07)
 .. controls (40.81,-60.07) and (40.49,-58.80) .. (40.05,-56.27)
 .. controls (39.61,-53.74) and (39.39,-53.20) .. (38.35,-50.41)
 .. controls (37.33,-47.66) and (35.91,-44.35) .. (34.96,-42.58)
 .. controls (34.01,-40.81) and (32.59,-40.47) .. (32.78,-36.19)
 .. controls (32.97,-31.91) and (33.69,-29.69) .. (32.18,-26.45)
 .. controls (30.65,-23.16) and (27.68,-19.60) .. (25.60,-16.69)
 .. controls (23.54,-13.82) and (22.09,-13.47) .. (19.88,-11.41)
 .. controls (17.68,-9.37) and (19.38,-9.99) .. (17.87,-8.38)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((17.87,-8.38)
 .. controls (17.87,-8.38) and (17.07,-5.09) .. (11.75,-4.23)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-5.85,60.41)
 .. controls (-5.85,60.41) and (-2.98,58.80) .. (-2.71,56.09)
 .. controls (-2.43,53.38) and (-2.86,50.26) .. (-2.89,45.78)
 .. controls (-2.92,41.30) and (-1.71,40.36) .. (-2.12,36.44)
 .. controls (-2.52,32.52) and (-2.65,31.44) .. (-2.62,28.88)
 .. controls (-2.59,26.31) and (-1.65,23.03) .. (-3.57,20.80)
 .. controls (-5.56,18.49) and (-5.42,16.87) .. (-7.94,16.91)
 .. controls (-10.28,16.96) and (-7.71,13.04) .. (-9.88,11.88)
 .. controls (-14.05,9.65) and (-17.20,4.96) .. (-18.52,3.22)
 .. controls (-21.63,-0.89) and (-22.48,3.27) .. (-22.81,5.87)
 .. controls (-23.05,7.80) and (-11.88,16.01) .. (-11.81,19.15)
 .. controls (-11.74,22.27) and (-12.05,27.78) .. (-12.05,27.78)
));
drawoptions();
p_helictite((-24.60,-9.37),0.0,1.00,(0,0));
drawoptions();
p_stalactites((-7.63,-13.44),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-15.32,28.15)
 .. controls (-15.32,28.15) and (-15.35,22.54) .. (-17.26,19.80)
 .. controls (-19.33,16.83) and (-21.36,14.25) .. (-24.15,13.90)
 .. controls (-27.08,13.53) and (-29.49,13.08) .. (-29.49,13.08)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-30.05,10.18)
 .. controls (-30.05,10.18) and (-28.20,10.15) .. (-28.11,8.91)
 .. controls (-28.01,7.68) and (-29.55,5.59) .. (-31.68,5.38)
 .. controls (-33.67,5.19) and (-36.21,6.54) .. (-36.21,6.54)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-39.41,5.55),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-13.55,-1.76),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((13.57,-10.06),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((30.54,-26.94),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((31.25,-41.37),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((35.99,-48.71),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-1.77,19.15),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((2.18,56.79),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-30.10,2.11),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-10.85,8.33),1,0,"");
endfig;
beginfig(55);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char51 \mainfont{} etex,(-12.97,50.35),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char53 \mainfont{} etex,(-29.95,-13.93),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char56 \mainfont{} etex,(-19.41,-14.21),0.0,p_label_mode_height);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-solitaire2019_4";
ATTR__scrap := "SP-solitaire2019_4";
beginfig(56);
ATTR__height := -1;
drawoptions();
l_pit(((5.05,-37.71)
 .. controls (5.05,-37.71) and (7.48,-33.38) .. (11.25,-34.73)
));
ATTR__height := -1;
drawoptions();
l_pit(((-6.38,4.23)
 .. controls (-6.38,4.23) and (-5.11,8.63) .. (-3.58,7.64)
 .. controls (-2.06,6.64) and (-0.71,6.02) .. (-0.71,6.02)
));
ATTR__height := -1;
drawoptions();
l_floormeander(((-9.63,-4.68)
 .. controls (-9.63,-4.68) and (-9.54,12.33) .. (-6.48,12.06)
 .. controls (-3.42,11.79) and (1.89,8.54) .. (2.97,8.00)
 .. controls (4.05,7.45) and (5.13,6.91) .. (5.13,6.91)
));
endfig;
beginfig(57);
draw_upscrap(1)(1,((12.60,-37.97)
 .. controls (12.60,-37.97) and (8.29,-34.19) .. (8.29,-30.96)
 .. controls (8.28,-27.72) and (10.71,-19.72) .. (9.36,-16.85)
 .. controls (8.01,-13.97) and (3.70,-4.88) .. (1.54,-1.28)
 .. controls (-0.62,2.32) and (-5.20,8.00) .. (-2.95,7.64)
 .. controls (-0.72,7.28) and (4.32,5.20) .. (4.32,5.20)
),
1,((5.13,10.24)
 .. controls (5.13,10.24) and (0.01,16.55) .. (-2.33,16.74)
 .. controls (-4.68,16.92) and (-7.20,18.54) .. (-9.18,16.02)
 .. controls (-11.16,13.50) and (-12.60,-3.24) .. (-12.60,-4.95)
),
1,((-7.02,-4.95)
 .. controls (-7.02,-4.95) and (-7.65,6.66) .. (-6.38,5.22)
 .. controls (-5.12,3.77) and (-2.06,-2.26) .. (-0.80,-4.42)
 .. controls (0.46,-6.59) and (5.94,-15.50) .. (5.94,-17.57)
 .. controls (5.94,-19.64) and (3.61,-30.33) .. (4.33,-32.22)
 .. controls (5.05,-34.11) and (6.84,-38.52) .. (6.84,-38.52)
));
draw_downscrap;
endfig;
beginfig(58);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((12.60,-37.97)
 .. controls (12.60,-37.97) and (8.29,-34.19) .. (8.29,-30.96)
 .. controls (8.28,-27.72) and (10.71,-19.72) .. (9.36,-16.85)
 .. controls (8.01,-13.97) and (3.70,-4.88) .. (1.54,-1.28)
 .. controls (-0.62,2.32) and (-5.20,8.00) .. (-2.95,7.64)
 .. controls (-0.72,7.28) and (4.32,5.20) .. (4.32,5.20)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((5.13,10.24)
 .. controls (5.13,10.24) and (0.01,16.55) .. (-2.33,16.74)
 .. controls (-4.68,16.92) and (-7.20,18.54) .. (-9.18,16.02)
 .. controls (-11.16,13.50) and (-12.60,-3.24) .. (-12.60,-4.95)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-7.02,-4.95)
 .. controls (-7.02,-4.95) and (-7.65,6.66) .. (-6.38,5.22)
 .. controls (-5.12,3.77) and (-2.06,-2.26) .. (-0.80,-4.42)
 .. controls (0.46,-6.59) and (5.94,-15.50) .. (5.94,-17.57)
 .. controls (5.94,-19.64) and (3.61,-30.33) .. (4.33,-32.22)
 .. controls (5.05,-34.11) and (6.84,-38.52) .. (6.84,-38.52)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((6.39,-32.86),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((8.00,-17.60),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-4.69,7.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-7.45,16.32),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-9.32,-5.08),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((3.85,6.50),1,0,"");
endfig;
beginfig(59);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char49 \char53 \mainfont{} etex,(7.75,23.39),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{\hfil#\hfil\cr\thfb\char114 \thfc\char233 \thfb\char115 \char101 \char97 \char117 \ \char100 \char101 \ \char108 \char97 \cr\thfb \char80 \char105 \char101 \char114 \char114 \char101 \ \char81 \char117 \char105 \ \char84 \char111 \char109 \char98 \char101 \cr}}\mainfont{} etex,(-3.49,38.52),0.0,p_label_mode_label);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.top(btex \thaltitude \thfb\char45 \char51 \char52 \mainfont{} etex,(-6.84,17.46),0.0,p_label_mode_altitude);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-Solitaire2020-1";
ATTR__scrap := "SP-Solitaire2020-1";
beginfig(60);
current_src := "th2/solitaire-plan2020.th2 [295]";
string area_border[];
area_border[1] := "l63-836-1530";
drawoptions();
a_water(buildcycle(((26.83,-56.83)
 .. controls (26.83,-56.83) and (21.79,-53.60) .. (21.97,-54.95)
 .. controls (22.15,-56.29) and (24.93,-58.98) .. (25.74,-59.25)
 .. controls (26.56,-59.52) and (28.98,-61.68) .. (28.63,-60.25)
 .. controls (28.27,-58.81) and (26.83,-56.83) .. cycle
)));
current_src := "th2/solitaire-plan2020.th2 [272]";
string area_border[];
area_border[1] := "l70-822-1543";
drawoptions();
a_pebbles(buildcycle(((17.10,-50.27)
 .. controls (17.10,-50.27) and (10.98,-45.04) .. (9.99,-47.57)
 .. controls (9.00,-50.09) and (8.63,-58.09) .. (10.98,-58.91)
 .. controls (13.32,-59.72) and (17.83,-53.15) .. (17.47,-51.71)
 .. controls (17.10,-50.27) and (17.10,-50.27) .. cycle
)));
current_src := "th2/solitaire-plan2020.th2 [253]";
string area_border[];
area_border[1] := "l72-829-1786";
drawoptions();
a_blocks(buildcycle(((24.32,24.89)
 .. controls (24.32,24.89) and (21.79,35.07) .. (19.99,37.23)
 .. controls (18.19,39.38) and (17.46,44.79) .. (16.29,48.56)
 .. controls (15.11,52.32) and (8.90,53.05) .. (8.73,56.10)
 .. controls (8.55,59.16) and (10.63,63.49) .. (10.72,63.85)
 .. controls (10.81,64.21) and (17.28,68.73) .. (14.31,71.43)
 .. controls (11.34,74.12) and (4.15,75.20) .. (2.17,73.39)
 .. controls (0.20,71.58) and (0.11,63.57) .. (0.38,60.43)
 .. controls (0.64,57.28) and (2.15,49.01) .. (3.77,44.15)
 .. controls (5.38,39.29) and (7.74,28.22) .. (11.35,26.15)
 .. controls (14.95,24.09) and (24.32,24.89) .. cycle
)));
ATTR__height := -1;
drawoptions();
l_pit(((30.98,-57.73)
 .. controls (30.98,-57.73) and (26.92,-55.75) .. (25.92,-61.77)
));
ATTR__height := -1;
drawoptions();
l_pit(((9.01,-52.77)
 .. controls (9.01,-52.77) and (6.75,-54.20) .. (10.08,-57.37)
));
drawoptions();
p_pebbles((34.20,-38.38),0.0,1.00,(0,0));
drawoptions();
p_pebbles((19.18,-55.40),0.0,1.00,(0,0));
drawoptions();
p_pebbles((11.44,-55.39),0.0,1.00,(0,0));
drawoptions();
p_pebbles((10.80,-51.62),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_border_visible(((17.36,-42.25)
 .. controls (17.36,-42.25) and (13.68,-46.31) .. (12.69,-50.63)
 .. controls (11.71,-54.94) and (13.95,-59.45) .. (13.95,-59.45)
));
ATTR__height := -1;
drawoptions();
l_floormeander(((35.46,-35.04)
 .. controls (35.46,-35.04) and (36.09,-40.53) .. (31.23,-42.16)
 .. controls (26.38,-43.79) and (25.84,-43.52) .. (21.42,-44.78)
 .. controls (17.00,-46.03) and (14.04,-48.38) .. (13.68,-49.55)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-8.18,92.46)
 -- (-9.44,90.48)
 -- (-6.92,89.40)
 -- (-6.38,91.20)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((15.04,40.19)
 -- (12.15,40.28)
 -- (12.15,39.11)
 -- (14.95,38.93)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((12.33,54.12)
 -- (8.64,53.58)
 -- (8.37,51.52)
 -- (11.69,51.52)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((30.43,4.91)
 -- (27.91,4.64)
 -- (29.98,0.59)
 -- (30.79,1.94)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_pit(((14.04,69.18)
 .. controls (14.04,69.18) and (13.41,73.94) .. (11.52,74.48)
 .. controls (9.63,75.02) and (9.72,73.58) .. (7.74,72.22)
 .. controls (5.76,70.87) and (2.71,70.59) .. (2.71,70.59)
));
ATTR__height := -1;
drawoptions();
l_pit(((3.34,86.08)
 .. controls (3.34,86.08) and (0.82,88.15) .. (0.27,89.68)
));
ATTR__height := -1;
drawoptions();
l_pit(((15.92,78.44)
 .. controls (15.92,78.44) and (13.76,77.54) .. (12.24,79.97)
));
ATTR__height := -1;
drawoptions();
l_pit(((-0.79,59.44)
 .. controls (-0.79,59.44) and (1.99,58.09) .. (0.28,55.76)
));
ATTR__height := -1;
drawoptions();
l_pit(((13.68,53.13)
 .. controls (13.68,53.13) and (17.55,55.47) .. (13.32,58.09)
));
ATTR__height := -1;
drawoptions();
l_pit(((14.39,51.25)
 .. controls (14.39,51.25) and (9.81,54.12) .. (9.90,56.29)
 .. controls (9.99,58.44) and (12.07,63.22) .. (12.07,63.22)
));
ATTR__height := -1;
drawoptions();
l_pit(((-3.59,89.94)
 .. controls (-5.75,89.94) and (-5.30,86.52) .. (-5.30,86.52)
));
ATTR__height := -1;
drawoptions();
l_pit(((0.27,88.96)
 .. controls (0.27,88.96) and (-3.77,86.43) .. (-1.79,84.73)
));
ATTR__height := -1;
drawoptions();
l_pit(((4.06,85.55)
 .. controls (4.06,85.55) and (1.36,86.89) .. (-0.17,84.28)
));
ATTR__height := -1;
drawoptions();
l_pit(((16.92,36.96)
 .. controls (16.92,36.96) and (12.43,42.89) .. (9.45,34.97)
));
ATTR__height := -1;
drawoptions();
l_pit(((22.78,28.77)
 .. controls (22.78,28.77) and (15.84,32.73) .. (13.69,26.70)
));
endfig;
beginfig(61);
draw_upscrap(1)(1,((55.24,-91.15)
 .. controls (55.24,-91.15) and (53.72,-90.02) .. (52.34,-89.96)
 .. controls (51.09,-89.91) and (50.17,-90.03) .. (48.95,-88.55)
 .. controls (47.63,-86.93) and (48.60,-86.10) .. (46.07,-86.19)
 .. controls (43.40,-86.28) and (43.88,-86.77) .. (42.02,-86.01)
 .. controls (40.20,-85.26) and (38.41,-83.75) .. (36.63,-83.50)
 .. controls (34.86,-83.25) and (30.87,-82.67) .. (32.40,-81.49)
 .. controls (33.93,-80.31) and (37.79,-78.49) .. (37.90,-77.33)
 .. controls (38.00,-76.17) and (36.45,-73.56) .. (35.54,-72.38)
 .. controls (34.64,-71.22) and (36.16,-69.40) .. (35.17,-68.24)
 .. controls (34.19,-67.08) and (34.63,-67.62) .. (33.83,-65.09)
 .. controls (33.02,-62.58) and (31.16,-58.81) .. (30.17,-58.00)
 .. controls (29.17,-57.19) and (29.08,-55.84) .. (26.92,-54.58)
 .. controls (24.77,-53.33) and (24.04,-52.25) .. (21.88,-52.61)
 .. controls (19.72,-52.96) and (17.11,-53.69) .. (16.12,-53.24)
 .. controls (15.13,-52.79) and (13.95,-50.81) .. (15.21,-49.91)
 .. controls (16.47,-49.01) and (20.25,-47.03) .. (23.13,-46.58)
 .. controls (26.02,-46.14) and (29.26,-45.50) .. (31.50,-44.50)
 .. controls (33.75,-43.50) and (32.67,-43.32) .. (35.55,-41.16)
 .. controls (38.44,-39.00) and (37.44,-35.22) .. (36.35,-34.05)
 .. controls (35.27,-32.88) and (34.01,-31.71) .. (35.63,-31.08)
 .. controls (37.25,-30.45) and (35.09,-29.83) .. (35.81,-28.21)
 .. controls (36.53,-26.59) and (37.26,-26.14) .. (38.34,-24.70)
 .. controls (39.43,-23.26) and (40.88,-15.16) .. (41.51,-13.09)
 .. controls (42.14,-11.02) and (42.95,-9.03) .. (41.60,-8.13)
 .. controls (40.25,-7.23) and (37.45,-4.71) .. (35.92,-2.91)
 .. controls (34.39,-1.11) and (32.14,-0.13) .. (32.68,2.57)
 .. controls (33.21,5.27) and (34.11,8.59) .. (33.30,9.94)
 .. controls (32.49,11.29) and (30.24,15.89) .. (27.09,18.68)
 .. controls (23.95,21.47) and (21.62,23.09) .. (21.53,25.34)
 .. controls (21.44,27.60) and (22.69,29.04) .. (20.53,30.48)
 .. controls (18.37,31.92) and (17.01,33.63) .. (16.29,35.52)
 .. controls (15.57,37.41) and (16.21,38.93) .. (15.85,40.01)
 .. controls (15.49,41.09) and (14.40,43.34) .. (14.40,45.50)
 .. controls (14.40,47.66) and (12.95,49.18) .. (13.31,50.80)
 .. controls (13.67,52.42) and (12.42,53.58) .. (13.68,54.30)
 .. controls (14.94,55.02) and (15.39,55.65) .. (16.56,56.19)
 .. controls (17.73,56.73) and (19.00,58.27) .. (19.00,58.27)
),
1,((17.73,60.61)
 .. controls (17.73,60.61) and (14.85,57.01) .. (13.41,57.28)
 .. controls (11.97,57.55) and (13.14,61.06) .. (11.70,61.87)
 .. controls (10.27,62.67) and (9.38,63.94) .. (10.27,66.37)
 .. controls (11.17,68.81) and (14.13,72.50) .. (14.22,74.12)
 .. controls (14.30,75.74) and (14.48,77.00) .. (14.66,78.08)
 .. controls (14.84,79.16) and (14.30,82.40) .. (14.30,82.40)
),
1,((14.30,82.40)
 .. controls (14.30,82.40) and (7.30,87.71) .. (5.14,87.88)
),
1,((5.14,87.88)
 .. controls (5.14,87.88) and (0.90,88.87) .. (-0.53,88.69)
 .. controls (-1.97,88.51) and (-3.59,89.04) .. (-4.94,90.30)
 .. controls (-6.29,91.56) and (-7.91,93.36) .. (-9.98,93.63)
 .. controls (-12.05,93.90) and (-14.47,91.65) .. (-15.11,93.54)
 .. controls (-15.74,95.43) and (-15.47,96.42) .. (-16.91,97.68)
),
1,((-19.42,94.53)
 .. controls (-19.42,94.53) and (-17.62,91.65) .. (-14.30,90.75)
 .. controls (-10.97,89.85) and (-6.20,88.23) .. (-3.41,86.25)
 .. controls (-0.62,84.28) and (1.63,84.64) .. (0.73,83.83)
 .. controls (-0.17,83.02) and (-3.86,83.29) .. (-1.16,82.21)
 .. controls (1.55,81.14) and (1.19,82.13) .. (2.81,80.78)
 .. controls (4.42,79.43) and (4.95,75.02) .. (4.59,73.57)
 .. controls (4.24,72.13) and (4.42,69.42) .. (1.37,67.35)
 .. controls (-1.69,65.28) and (-3.22,63.49) .. (-2.77,62.23)
 .. controls (-2.32,60.97) and (0.91,58.63) .. (-0.17,58.90)
 .. controls (-1.24,59.17) and (-2.68,59.80) .. (-2.68,59.80)
),
1,((-3.67,58.28)
 .. controls (-3.67,58.28) and (0.82,56.74) .. (0.82,55.67)
 .. controls (0.81,54.59) and (-0.90,53.24) .. (0.36,51.98)
 .. controls (1.61,50.72) and (1.79,50.89) .. (3.50,49.45)
 .. controls (5.21,48.01) and (8.37,47.92) .. (8.55,43.97)
 .. controls (8.72,40.01) and (9.54,40.01) .. (10.26,38.30)
 .. controls (10.98,36.59) and (11.61,33.89) .. (12.96,32.54)
 .. controls (14.31,31.20) and (15.85,26.87) .. (16.66,26.06)
 .. controls (17.47,25.25) and (18.29,23.46) .. (19.64,22.46)
 .. controls (20.98,21.48) and (20.53,19.41) .. (22.50,17.43)
 .. controls (24.48,15.45) and (27.35,12.20) .. (27.36,9.41)
 .. controls (27.36,6.62) and (27.64,5.00) .. (28.09,3.29)
 .. controls (28.54,1.58) and (29.89,0.86) .. (30.70,-0.76)
 .. controls (31.51,-2.38) and (32.95,-4.26) .. (34.75,-5.70)
 .. controls (36.55,-7.14) and (39.44,-9.67) .. (39.35,-11.29)
 .. controls (39.26,-12.91) and (36.47,-16.87) .. (35.75,-17.86)
 .. controls (35.02,-18.85) and (34.38,-20.19) .. (33.03,-22.26)
 .. controls (31.68,-24.34) and (30.78,-25.87) .. (30.51,-27.67)
 .. controls (30.23,-29.47) and (34.02,-35.49) .. (33.93,-37.03)
 .. controls (33.84,-38.56) and (30.05,-39.73) .. (28.53,-40.91)
 .. controls (27.01,-42.08) and (25.57,-42.81) .. (23.86,-42.71)
 .. controls (22.14,-42.62) and (18.89,-41.62) .. (17.00,-43.51)
 .. controls (15.11,-45.40) and (11.61,-48.65) .. (10.35,-50.09)
 .. controls (9.10,-51.52) and (10.27,-51.35) .. (10.09,-52.60)
 .. controls (9.91,-53.86) and (7.93,-54.21) .. (7.93,-54.21)
 -- (6.57,-54.38)
),
1,((6.29,-56.37)
 .. controls (6.29,-56.37) and (9.72,-56.74) .. (12.24,-56.84)
 .. controls (14.77,-56.94) and (16.84,-58.01) .. (18.19,-57.29)
 .. controls (19.54,-56.56) and (19.99,-56.29) .. (21.16,-56.74)
 .. controls (22.33,-57.19) and (23.59,-57.73) .. (24.75,-58.98)
 .. controls (25.92,-60.24) and (26.28,-61.23) .. (27.99,-62.31)
 .. controls (29.69,-63.39) and (29.42,-60.97) .. (29.87,-65.10)
 .. controls (30.32,-69.26) and (29.98,-70.34) .. (30.52,-71.51)
 .. controls (31.06,-72.67) and (30.33,-72.85) .. (32.13,-73.74)
 .. controls (33.93,-74.63) and (35.65,-75.80) .. (33.74,-76.52)
 .. controls (31.85,-77.24) and (31.86,-78.70) .. (29.98,-78.61)
 .. controls (28.08,-78.52) and (26.54,-81.48) .. (26.99,-83.84)
 .. controls (27.44,-86.18) and (28.84,-88.31) .. (30.45,-88.30)
 .. controls (32.05,-88.28) and (34.82,-86.72) .. (36.86,-87.42)
 .. controls (38.92,-88.13) and (42.95,-90.08) .. (44.30,-91.07)
 .. controls (45.69,-92.08) and (47.04,-92.91) .. (48.58,-93.10)
 .. controls (49.82,-93.26) and (54.07,-93.98) .. (54.07,-93.98)
));
draw_upscrap(0)(1,((5.05,86.54)
 .. controls (5.05,86.54) and (11.34,82.49) .. (12.42,81.59)
));
draw_upscrap(1)(1,((12.42,81.59)
 .. controls (12.42,81.59) and (13.67,78.44) .. (12.33,79.34)
 .. controls (10.98,80.24) and (11.25,81.05) .. (9.28,82.13)
 .. controls (7.30,83.21) and (1.54,86.35) .. (2.35,86.44)
 .. controls (3.16,86.53) and (5.05,86.54) .. (5.05,86.54)
));
draw_downscrap;
endfig;
beginfig(62);
drawoptions();
p_breakdownchoke((7.47,-55.20),270.0,1.00,(0,0));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((43.67,-12.45)
 .. controls (43.67,-12.45) and (41.41,-23.44) .. (39.78,-26.23)
 .. controls (38.15,-29.01) and (37.43,-29.91) .. (37.70,-32.34)
 .. controls (37.97,-34.77) and (39.33,-39.09) .. (37.35,-41.25)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((23.30,-61.95)
 .. controls (23.30,-61.95) and (26.35,-65.72) .. (26.54,-68.70)
 .. controls (26.72,-71.67) and (25.63,-75.52) .. (25.54,-78.32)
 .. controls (25.45,-81.11) and (24.03,-89.93) .. (28.17,-90.18)
 .. controls (32.28,-90.43) and (33.46,-88.88) .. (36.92,-89.75)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((2.24,46.49)
 .. controls (2.24,46.49) and (5.47,39.38) .. (7.37,35.14)
 .. controls (9.27,30.92) and (11.89,26.06) .. (11.89,26.06)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-19.06,91.20)
 .. controls (-19.06,91.20) and (-14.39,89.22) .. (-11.06,87.69)
 .. controls (-7.73,86.16) and (-4.31,84.63) .. (-4.31,84.63)
));
string ATTR_code;
ATTR_code := "E";
string ATTR_cavite;
ATTR_cavite := "JB";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \char100 \char101 \ \char109 \thfc\char233 \thfb\char97 \char110 \char100 \char114 \char101 \ \char101 \char110 \ \char104 \char97 \char117 \char116 \char101 \char117 \char114 \char44 \ \char100 \char97 \char110 \char115 \ \char100 \char101 \char115 \ \char98 \char108 \char111 \char99 \char115 \char44 \ \thfc\char184 \ \thfb\char118 \char111 \char105 \char114 \mainfont{}etex;
drawoptions();
p_continuation((2.32,-55.45),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
save ATTR_cavite;
string ATTR_code;
ATTR_code := "E";
string ATTR_cavite;
ATTR_cavite := "JB";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \char100 \char101 \ \char109 \thfc\char233 \thfb\char97 \char110 \char100 \char114 \char101 \ \char101 \char110 \ \char104 \char97 \char117 \char116 \char101 \char117 \char114 \char44 \ \char100 \char97 \char110 \char115 \ \char100 \char101 \char115 \ \char98 \char108 \char111 \char99 \char115 \char44 \ \thfc\char184 \ \thfb\char118 \char111 \char105 \char114 \mainfont{}etex;
drawoptions();
p_continuation((21.60,61.87),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
save ATTR_cavite;
string ATTR_code;
ATTR_code := "E";
string ATTR_cavite;
ATTR_cavite := "JB";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \char100 \char101 \ \char109 \thfc\char233 \thfb\char97 \char110 \char100 \char114 \char101 \ \char101 \char110 \ \char104 \char97 \char117 \char116 \char101 \char117 \char114 \char44 \ \char100 \char97 \char110 \char115 \ \char100 \char101 \char115 \ \char98 \char108 \char111 \char99 \char115 \char44 \ \thfc\char184 \ \thfb\char118 \char111 \char105 \char114 \mainfont{}etex;
drawoptions();
p_continuation((-7.63,60.08),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
save ATTR_cavite;
drawoptions();
p_airdraught_summer((-14.93,82.66),65.9,1.00,(0,0));
drawoptions();
p_airdraught_summer((42.24,-97.68),73.9,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-19.42,94.53)
 .. controls (-19.42,94.53) and (-17.62,91.65) .. (-14.30,90.75)
 .. controls (-10.97,89.85) and (-6.20,88.23) .. (-3.41,86.25)
 .. controls (-0.62,84.28) and (1.63,84.64) .. (0.73,83.83)
 .. controls (-0.17,83.02) and (-3.86,83.29) .. (-1.16,82.21)
 .. controls (1.55,81.14) and (1.19,82.13) .. (2.81,80.78)
 .. controls (4.42,79.43) and (4.95,75.02) .. (4.59,73.57)
 .. controls (4.24,72.13) and (4.42,69.42) .. (1.37,67.35)
 .. controls (-1.69,65.28) and (-3.22,63.49) .. (-2.77,62.23)
 .. controls (-2.32,60.97) and (0.91,58.63) .. (-0.17,58.90)
 .. controls (-1.24,59.17) and (-2.68,59.80) .. (-2.68,59.80)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-3.67,58.28)
 .. controls (-3.67,58.28) and (0.82,56.74) .. (0.82,55.67)
 .. controls (0.81,54.59) and (-0.90,53.24) .. (0.36,51.98)
 .. controls (1.61,50.72) and (1.79,50.89) .. (3.50,49.45)
 .. controls (5.21,48.01) and (8.37,47.92) .. (8.55,43.97)
 .. controls (8.72,40.01) and (9.54,40.01) .. (10.26,38.30)
 .. controls (10.98,36.59) and (11.61,33.89) .. (12.96,32.54)
 .. controls (14.31,31.20) and (15.85,26.87) .. (16.66,26.06)
 .. controls (17.47,25.25) and (18.29,23.46) .. (19.64,22.46)
 .. controls (20.98,21.48) and (20.53,19.41) .. (22.50,17.43)
 .. controls (24.48,15.45) and (27.35,12.20) .. (27.36,9.41)
 .. controls (27.36,6.62) and (27.64,5.00) .. (28.09,3.29)
 .. controls (28.54,1.58) and (29.89,0.86) .. (30.70,-0.76)
 .. controls (31.51,-2.38) and (32.95,-4.26) .. (34.75,-5.70)
 .. controls (36.55,-7.14) and (39.44,-9.67) .. (39.35,-11.29)
 .. controls (39.26,-12.91) and (36.47,-16.87) .. (35.75,-17.86)
 .. controls (35.02,-18.85) and (34.38,-20.19) .. (33.03,-22.26)
 .. controls (31.68,-24.34) and (30.78,-25.87) .. (30.51,-27.67)
 .. controls (30.23,-29.47) and (34.02,-35.49) .. (33.93,-37.03)
 .. controls (33.84,-38.56) and (30.05,-39.73) .. (28.53,-40.91)
 .. controls (27.01,-42.08) and (25.57,-42.81) .. (23.86,-42.71)
 .. controls (22.14,-42.62) and (18.89,-41.62) .. (17.00,-43.51)
 .. controls (15.11,-45.40) and (11.61,-48.65) .. (10.35,-50.09)
 .. controls (9.10,-51.52) and (10.27,-51.35) .. (10.09,-52.60)
 .. controls (9.91,-53.86) and (7.93,-54.21) .. (7.93,-54.21)
 -- (6.57,-54.38)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((6.29,-56.37)
 .. controls (6.29,-56.37) and (9.72,-56.74) .. (12.24,-56.84)
 .. controls (14.77,-56.94) and (16.84,-58.01) .. (18.19,-57.29)
 .. controls (19.54,-56.56) and (19.99,-56.29) .. (21.16,-56.74)
 .. controls (22.33,-57.19) and (23.59,-57.73) .. (24.75,-58.98)
 .. controls (25.92,-60.24) and (26.28,-61.23) .. (27.99,-62.31)
 .. controls (29.69,-63.39) and (29.42,-60.97) .. (29.87,-65.10)
 .. controls (30.32,-69.26) and (29.98,-70.34) .. (30.52,-71.51)
 .. controls (31.06,-72.67) and (30.33,-72.85) .. (32.13,-73.74)
 .. controls (33.93,-74.63) and (35.65,-75.80) .. (33.74,-76.52)
 .. controls (31.85,-77.24) and (31.86,-78.70) .. (29.98,-78.61)
 .. controls (28.08,-78.52) and (26.54,-81.48) .. (26.99,-83.84)
 .. controls (27.44,-86.18) and (28.84,-88.31) .. (30.45,-88.30)
 .. controls (32.05,-88.28) and (34.82,-86.72) .. (36.86,-87.42)
 .. controls (38.92,-88.13) and (42.95,-90.08) .. (44.30,-91.07)
 .. controls (45.69,-92.08) and (47.04,-92.91) .. (48.58,-93.10)
 .. controls (49.82,-93.26) and (54.07,-93.98) .. (54.07,-93.98)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((55.24,-91.15)
 .. controls (55.24,-91.15) and (53.72,-90.02) .. (52.34,-89.96)
 .. controls (51.09,-89.91) and (50.17,-90.03) .. (48.95,-88.55)
 .. controls (47.63,-86.93) and (48.60,-86.10) .. (46.07,-86.19)
 .. controls (43.40,-86.28) and (43.88,-86.77) .. (42.02,-86.01)
 .. controls (40.20,-85.26) and (38.41,-83.75) .. (36.63,-83.50)
 .. controls (34.86,-83.25) and (30.87,-82.67) .. (32.40,-81.49)
 .. controls (33.93,-80.31) and (37.79,-78.49) .. (37.90,-77.33)
 .. controls (38.00,-76.17) and (36.45,-73.56) .. (35.54,-72.38)
 .. controls (34.64,-71.22) and (36.16,-69.40) .. (35.17,-68.24)
 .. controls (34.19,-67.08) and (34.63,-67.62) .. (33.83,-65.09)
 .. controls (33.02,-62.58) and (31.16,-58.81) .. (30.17,-58.00)
 .. controls (29.17,-57.19) and (29.08,-55.84) .. (26.92,-54.58)
 .. controls (24.77,-53.33) and (24.04,-52.25) .. (21.88,-52.61)
 .. controls (19.72,-52.96) and (17.11,-53.69) .. (16.12,-53.24)
 .. controls (15.13,-52.79) and (13.95,-50.81) .. (15.21,-49.91)
 .. controls (16.47,-49.01) and (20.25,-47.03) .. (23.13,-46.58)
 .. controls (26.02,-46.14) and (29.26,-45.50) .. (31.50,-44.50)
 .. controls (33.75,-43.50) and (32.67,-43.32) .. (35.55,-41.16)
 .. controls (38.44,-39.00) and (37.44,-35.22) .. (36.35,-34.05)
 .. controls (35.27,-32.88) and (34.01,-31.71) .. (35.63,-31.08)
 .. controls (37.25,-30.45) and (35.09,-29.83) .. (35.81,-28.21)
 .. controls (36.53,-26.59) and (37.26,-26.14) .. (38.34,-24.70)
 .. controls (39.43,-23.26) and (40.88,-15.16) .. (41.51,-13.09)
 .. controls (42.14,-11.02) and (42.95,-9.03) .. (41.60,-8.13)
 .. controls (40.25,-7.23) and (37.45,-4.71) .. (35.92,-2.91)
 .. controls (34.39,-1.11) and (32.14,-0.13) .. (32.68,2.57)
 .. controls (33.21,5.27) and (34.11,8.59) .. (33.30,9.94)
 .. controls (32.49,11.29) and (30.24,15.89) .. (27.09,18.68)
 .. controls (23.95,21.47) and (21.62,23.09) .. (21.53,25.34)
 .. controls (21.44,27.60) and (22.69,29.04) .. (20.53,30.48)
 .. controls (18.37,31.92) and (17.01,33.63) .. (16.29,35.52)
 .. controls (15.57,37.41) and (16.21,38.93) .. (15.85,40.01)
 .. controls (15.49,41.09) and (14.40,43.34) .. (14.40,45.50)
 .. controls (14.40,47.66) and (12.95,49.18) .. (13.31,50.80)
 .. controls (13.67,52.42) and (12.42,53.58) .. (13.68,54.30)
 .. controls (14.94,55.02) and (15.39,55.65) .. (16.56,56.19)
 .. controls (17.73,56.73) and (19.00,58.27) .. (19.00,58.27)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((17.73,60.61)
 .. controls (17.73,60.61) and (14.85,57.01) .. (13.41,57.28)
 .. controls (11.97,57.55) and (13.14,61.06) .. (11.70,61.87)
 .. controls (10.27,62.67) and (9.38,63.94) .. (10.27,66.37)
 .. controls (11.17,68.81) and (14.13,72.50) .. (14.22,74.12)
 .. controls (14.30,75.74) and (14.48,77.00) .. (14.66,78.08)
 .. controls (14.84,79.16) and (14.30,82.40) .. (14.30,82.40)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((12.42,81.59)
 .. controls (12.42,81.59) and (13.67,78.44) .. (12.33,79.34)
 .. controls (10.98,80.24) and (11.25,81.05) .. (9.28,82.13)
 .. controls (7.30,83.21) and (1.54,86.35) .. (2.35,86.44)
 .. controls (3.16,86.53) and (5.05,86.54) .. (5.05,86.54)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((5.14,87.88)
 .. controls (5.14,87.88) and (0.90,88.87) .. (-0.53,88.69)
 .. controls (-1.97,88.51) and (-3.59,89.04) .. (-4.94,90.30)
 .. controls (-6.29,91.56) and (-7.91,93.36) .. (-9.98,93.63)
 .. controls (-12.05,93.90) and (-14.47,91.65) .. (-15.11,93.54)
 .. controls (-15.74,95.43) and (-15.47,96.42) .. (-16.91,97.68)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((5.05,86.54)
 .. controls (5.05,86.54) and (11.34,82.49) .. (12.42,81.59)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((14.30,82.40)
 .. controls (14.30,82.40) and (7.30,87.71) .. (5.14,87.88)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((47.04,-91.97),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((44.87,-88.43),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((27.63,-84.52),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((30.21,-80.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((37.09,-75.68),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((31.31,-70.34),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((30.54,-58.85),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((24.53,-53.59),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((14.47,-55.18),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((9.05,-54.65),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((11.68,-49.11),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((26.15,-43.99),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((37.02,-38.16),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((32.31,-27.11),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((39.02,-17.41),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((41.32,-10.74),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((30.51,0.85),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((33.07,8.09),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((20.79,24.58),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((11.45,41.64),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((13.35,40.76),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((7.84,53.93),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-2.09,58.56),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((16.78,57.92),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((4.15,64.89),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((13.29,75.63),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((5.20,82.68),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-5.64,89.66),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-16.23,91.82),1,0,"");
endfig;
beginfig(63);
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char50 \mainfont{} etex,(33.65,-53.84),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{\hfil#\hfil\cr\thfb\char103 \char97 \char108 \char101 \char116 \ \char100 \char101 \cr\thfb \char103 \char114 \char97 \char110 \char105 \char116 \char101 \cr}}\mainfont{} etex,(6.99,-23.50),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char55 \mainfont{} etex,(41.38,-46.35),0.0,p_label_mode_height);
ATTR__height := -1;
drawoptions();
l_label(btex \thlabel \thnormalsize \thfb\char109 {}\thfc\char233 {}\thfb\char97 {}\char110 {}\char100 {}\char114 {}\char101 {}\ \char100 {}\char101 {}\char115 {}\ \char79 {}\char101 {}\char117 {}\char102 {}\char115 {}\mainfont{} etex,((-55.24,90.14)
 .. controls (-55.24,90.14) and (-22.90,37.96) .. (-19.30,22.83)
 .. controls (-15.71,7.71) and (-15.71,-22.86) .. (-17.52,-39.77)
 .. controls (-19.33,-56.69) and (-25.87,-79.71) .. (-25.87,-79.71)
));
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char53 \mainfont{} etex,(-0.27,94.17),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char52 \mainfont{} etex,(20.96,74.40),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char52 \mainfont{} etex,(21.79,37.86),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char52 \mainfont{} etex,(12.61,21.66),0.0,p_label_mode_height);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-Solitaire-c-2018_2";
ATTR__scrap := "SP-Solitaire-c-2018_2";
beginfig(64);
ATTR__height := -1;
drawoptions(withcolor (0.00000,0.40000,0.80000,0.00000));
l_flowstone(((27.27,6.60)
 .. controls (27.27,6.60) and (22.99,9.34) .. (18.49,9.42)
 .. controls (13.93,9.50) and (13.12,8.69) .. (10.20,9.51)
));
ATTR__height := -1;
drawoptions();
l_slope(((34.68,21.89)
 .. controls (26.73,20.88) and (23.34,29.53) .. (23.34,29.53)
),0,(0,-1,3.78928),(1,-1,3.78928));
ATTR__height := -1;
drawoptions();
l_slope(((31.30,15.35)
 .. controls (24.67,14.14) and (16.82,25.28) .. (16.82,25.28)
),0,(0,-1,3.78928),(1,-1,3.78928));
ATTR__height := -1;
drawoptions();
l_rockborder(((-3.08,3.50)
 -- (-0.50,6.11)
 -- (0.51,4.49)
 -- (-0.64,2.43)
 -- (-2.72,2.37)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-11.28,2.91)
 -- (-7.67,5.34)
 -- (-6.46,4.29)
 -- (-6.48,2.22)
 -- (-8.48,1.00)
 -- (-11.11,1.02)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-17.58,3.71)
 -- (-15.49,5.12)
 -- (-14.36,4.63)
 -- (-12.51,2.54)
 -- (-15.62,1.99)
 -- (-17.50,2.29)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-31.24,-20.03)
 -- (-27.76,-18.81)
 -- (-25.53,-21.56)
 -- (-25.47,-23.80)
 -- (-27.63,-24.78)
 -- (-30.24,-24.26)
 -- (-29.66,-22.12)
 -- cycle
));
endfig;
beginfig(65);
draw_upscrap(1)(1,((45.59,30.66)
 .. controls (45.59,30.66) and (39.09,30.30) .. (36.93,30.96)
 .. controls (34.73,31.62) and (32.89,34.01) .. (29.81,33.05)
 .. controls (26.73,32.09) and (24.72,26.99) .. (23.29,25.11)
 .. controls (21.85,23.21) and (21.86,21.60) .. (19.60,21.71)
 .. controls (17.32,21.83) and (13.32,22.96) .. (13.27,21.82)
 .. controls (13.21,20.67) and (13.41,10.90) .. (12.50,9.86)
 .. controls (11.60,8.82) and (10.65,8.44) .. (6.97,8.52)
 .. controls (3.30,8.59) and (-3.86,8.91) .. (-8.29,8.76)
 .. controls (-12.72,8.62) and (-14.32,8.62) .. (-17.05,8.18)
 .. controls (-19.79,7.74) and (-21.38,8.72) .. (-21.03,6.42)
 .. controls (-20.68,4.13) and (-18.72,2.49) .. (-20.15,0.80)
 .. controls (-21.59,-0.88) and (-23.57,-1.03) .. (-26.03,-0.95)
 .. controls (-28.49,-0.87) and (-31.46,-2.90) .. (-32.45,-5.20)
 .. controls (-33.45,-7.50) and (-33.78,-11.24) .. (-35.40,-11.21)
 .. controls (-37.02,-11.17) and (-39.18,-9.25) .. (-39.18,-9.25)
),
1,((-45.59,-24.20)
 .. controls (-45.59,-24.20) and (-41.56,-31.31) .. (-39.89,-31.81)
 .. controls (-38.23,-32.31) and (-37.43,-34.01) .. (-36.94,-32.90)
 .. controls (-36.44,-31.79) and (-35.78,-31.43) .. (-33.97,-30.06)
 .. controls (-32.18,-28.70) and (-31.13,-27.51) .. (-29.56,-28.19)
 .. controls (-27.98,-28.88) and (-27.33,-28.80) .. (-24.55,-29.78)
 .. controls (-21.77,-30.76) and (-18.73,-32.01) .. (-18.73,-32.01)
 .. controls (-18.73,-32.01) and (-17.22,-31.10) .. (-16.52,-29.15)
 .. controls (-15.81,-27.20) and (-14.71,-23.96) .. (-14.38,-21.55)
 .. controls (-14.05,-19.14) and (-14.70,-13.93) .. (-12.42,-12.09)
 .. controls (-10.13,-10.25) and (-9.74,-9.22) .. (-7.00,-8.30)
 .. controls (-4.26,-7.38) and (-4.64,-7.28) .. (-1.11,-4.04)
 .. controls (2.42,-0.80) and (4.87,-0.28) .. (7.40,-0.31)
 .. controls (9.91,-0.34) and (12.91,-1.33) .. (14.26,0.03)
 .. controls (15.61,1.39) and (16.99,2.84) .. (18.66,2.23)
 .. controls (20.33,1.63) and (19.43,-2.55) .. (20.63,-3.24)
 .. controls (21.83,-3.93) and (22.83,-7.70) .. (22.83,-7.70)
),
1,((24.73,-7.09)
 .. controls (22.32,-3.28) and (24.57,-0.89) .. (25.17,0.13)
 .. controls (25.88,1.34) and (24.46,4.26) .. (25.36,5.72)
 .. controls (26.26,7.18) and (27.35,8.36) .. (28.40,10.65)
 .. controls (29.47,12.96) and (31.40,18.72) .. (33.12,20.81)
 .. controls (34.84,22.90) and (35.10,25.35) .. (36.98,25.95)
 .. controls (38.86,26.55) and (39.94,26.51) .. (41.89,27.06)
 .. controls (43.78,27.61) and (43.45,27.76) .. (45.02,28.70)
));
draw_downscrap;
endfig;
beginfig(66);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((45.59,30.66)
 .. controls (45.59,30.66) and (39.09,30.30) .. (36.93,30.96)
 .. controls (34.73,31.62) and (32.89,34.01) .. (29.81,33.05)
 .. controls (26.73,32.09) and (24.72,26.99) .. (23.29,25.11)
 .. controls (21.85,23.21) and (21.86,21.60) .. (19.60,21.71)
 .. controls (17.32,21.83) and (13.32,22.96) .. (13.27,21.82)
 .. controls (13.21,20.67) and (13.41,10.90) .. (12.50,9.86)
 .. controls (11.60,8.82) and (10.65,8.44) .. (6.97,8.52)
 .. controls (3.30,8.59) and (-3.86,8.91) .. (-8.29,8.76)
 .. controls (-12.72,8.62) and (-14.32,8.62) .. (-17.05,8.18)
 .. controls (-19.79,7.74) and (-21.38,8.72) .. (-21.03,6.42)
 .. controls (-20.68,4.13) and (-18.72,2.49) .. (-20.15,0.80)
 .. controls (-21.59,-0.88) and (-23.57,-1.03) .. (-26.03,-0.95)
 .. controls (-28.49,-0.87) and (-31.46,-2.90) .. (-32.45,-5.20)
 .. controls (-33.45,-7.50) and (-33.78,-11.24) .. (-35.40,-11.21)
 .. controls (-37.02,-11.17) and (-39.18,-9.25) .. (-39.18,-9.25)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-45.59,-24.20)
 .. controls (-45.59,-24.20) and (-41.56,-31.31) .. (-39.89,-31.81)
 .. controls (-38.23,-32.31) and (-37.43,-34.01) .. (-36.94,-32.90)
 .. controls (-36.44,-31.79) and (-35.78,-31.43) .. (-33.97,-30.06)
 .. controls (-32.18,-28.70) and (-31.13,-27.51) .. (-29.56,-28.19)
 .. controls (-27.98,-28.88) and (-27.33,-28.80) .. (-24.55,-29.78)
 .. controls (-21.77,-30.76) and (-18.73,-32.01) .. (-18.73,-32.01)
 .. controls (-18.73,-32.01) and (-17.22,-31.10) .. (-16.52,-29.15)
 .. controls (-15.81,-27.20) and (-14.71,-23.96) .. (-14.38,-21.55)
 .. controls (-14.05,-19.14) and (-14.70,-13.93) .. (-12.42,-12.09)
 .. controls (-10.13,-10.25) and (-9.74,-9.22) .. (-7.00,-8.30)
 .. controls (-4.26,-7.38) and (-4.64,-7.28) .. (-1.11,-4.04)
 .. controls (2.42,-0.80) and (4.87,-0.28) .. (7.40,-0.31)
 .. controls (9.91,-0.34) and (12.91,-1.33) .. (14.26,0.03)
 .. controls (15.61,1.39) and (16.99,2.84) .. (18.66,2.23)
 .. controls (20.33,1.63) and (19.43,-2.55) .. (20.63,-3.24)
 .. controls (21.83,-3.93) and (22.83,-7.70) .. (22.83,-7.70)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((24.73,-7.09)
 .. controls (22.32,-3.28) and (24.57,-0.89) .. (25.17,0.13)
 .. controls (25.88,1.34) and (24.46,4.26) .. (25.36,5.72)
 .. controls (26.26,7.18) and (27.35,8.36) .. (28.40,10.65)
 .. controls (29.47,12.96) and (31.40,18.72) .. (33.12,20.81)
 .. controls (34.84,22.90) and (35.10,25.35) .. (36.98,25.95)
 .. controls (38.86,26.55) and (39.94,26.51) .. (41.89,27.06)
 .. controls (43.78,27.61) and (43.45,27.76) .. (45.02,28.70)
));
drawoptions();
p_u_bats((24.82,15.19),0.0,1.00,(0,0));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-19.62,-1.76),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((14.88,7.22),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((32.40,29.99),1,0,"");
endfig;
beginfig(67);
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char51 \mainfont{} etex,(36.45,8.34),0.0,p_label_mode_height);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-solitaire2019-2";
ATTR__scrap := "SP-solitaire2019-2";
beginfig(68);
ATTR__height := -1;
drawoptions();
l_pit(((-3.95,-38.84)
 .. controls (-3.95,-38.84) and (-18.18,-36.23) .. (-17.21,-28.44)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((1.92,13.79)
 -- (1.01,11.81)
 -- (3.36,10.91)
 -- (3.36,13.43)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-0.43,8.03)
 -- (-0.95,5.32)
 -- (1.20,5.50)
 -- (1.19,8.39)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((5.17,18.10)
 -- (3.55,15.76)
 -- (5.89,15.58)
 -- (6.79,19.00)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((9.84,22.79)
 -- (8.23,20.44)
 -- (10.03,19.72)
 -- (11.28,22.43)
 -- cycle
));
endfig;
beginfig(69);
draw_upscrap(1)(1,((13.26,30.35)
 .. controls (13.26,30.35) and (12.72,28.37) .. (11.28,26.93)
 .. controls (9.84,25.49) and (-0.26,16.49) .. (-1.33,10.19)
 .. controls (-2.41,3.88) and (-1.78,-2.10) .. (-1.79,-6.97)
 .. controls (-1.80,-11.80) and (-1.87,-15.01) .. (-3.45,-18.28)
 .. controls (-5.03,-21.56) and (-8.48,-30.00) .. (-12.64,-30.68)
 .. controls (-16.54,-31.33) and (-31.46,-34.95) .. (-31.46,-34.95)
),
1,((-16.96,-38.56)
 .. controls (-16.96,-38.56) and (-9.55,-38.67) .. (-6.56,-35.33)
 .. controls (-3.58,-32.01) and (2.10,-24.41) .. (3.90,-18.25)
 .. controls (5.68,-12.14) and (2.64,-15.37) .. (3.39,-12.15)
),
1,((3.39,-12.15)
 .. controls (3.39,-12.15) and (7.74,-6.06) .. (9.53,-2.99)
 .. controls (11.32,0.07) and (14.91,11.79) .. (15.26,14.31)
 .. controls (15.62,16.84) and (15.62,18.82) .. (15.62,18.82)
),
1,((15.62,18.82)
 .. controls (15.62,18.82) and (14.17,22.06) .. (15.43,24.59)
 .. controls (16.69,27.11) and (21.18,32.72) .. (20.64,34.16)
 .. controls (20.10,35.60) and (17.75,38.84) .. (17.75,38.84)
),
1,((11.99,38.29)
 .. controls (11.99,38.29) and (14.69,35.58) .. (12.89,35.04)
));
draw_upscrap(0)(1,((13.27,18.82)
 .. controls (13.27,18.82) and (13.46,10.35) .. (10.95,5.12)
 .. controls (8.44,-0.10) and (3.60,-5.52) .. (3.60,-5.52)
),
1,((3.60,-5.52)
 .. controls (3.60,-5.52) and (2.28,6.23) .. (4.44,9.29)
 .. controls (6.60,12.34) and (12.72,23.33) .. (13.09,22.25)
 .. controls (13.45,21.16) and (13.27,18.82) .. (13.27,18.82)
));
draw_downscrap;
endfig;
beginfig(70);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-16.96,-38.56)
 .. controls (-16.96,-38.56) and (-9.55,-38.67) .. (-6.56,-35.33)
 .. controls (-3.58,-32.01) and (2.10,-24.41) .. (3.90,-18.25)
 .. controls (5.68,-12.14) and (2.64,-15.37) .. (3.39,-12.15)
));
drawoptions();
p_traverse((2.87,-38.63),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((3.60,-5.52)
 .. controls (3.60,-5.52) and (2.28,6.23) .. (4.44,9.29)
 .. controls (6.60,12.34) and (12.72,23.33) .. (13.09,22.25)
 .. controls (13.45,21.16) and (13.27,18.82) .. (13.27,18.82)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((13.27,18.82)
 .. controls (13.27,18.82) and (13.46,10.35) .. (10.95,5.12)
 .. controls (8.44,-0.10) and (3.60,-5.52) .. (3.60,-5.52)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((3.39,-12.15)
 .. controls (3.39,-12.15) and (7.74,-6.06) .. (9.53,-2.99)
 .. controls (11.32,0.07) and (14.91,11.79) .. (15.26,14.31)
 .. controls (15.62,16.84) and (15.62,18.82) .. (15.62,18.82)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((15.62,18.82)
 .. controls (15.62,18.82) and (14.17,22.06) .. (15.43,24.59)
 .. controls (16.69,27.11) and (21.18,32.72) .. (20.64,34.16)
 .. controls (20.10,35.60) and (17.75,38.84) .. (17.75,38.84)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((11.99,38.29)
 .. controls (11.99,38.29) and (14.69,35.58) .. (12.89,35.04)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((13.26,30.35)
 .. controls (13.26,30.35) and (12.72,28.37) .. (11.28,26.93)
 .. controls (9.84,25.49) and (-0.26,16.49) .. (-1.33,10.19)
 .. controls (-2.41,3.88) and (-1.78,-2.10) .. (-1.79,-6.97)
 .. controls (-1.80,-11.80) and (-1.87,-15.01) .. (-3.45,-18.28)
 .. controls (-5.03,-21.56) and (-8.48,-30.00) .. (-12.64,-30.68)
 .. controls (-16.54,-31.33) and (-31.46,-34.95) .. (-31.46,-34.95)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-11.60,-31.85),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((1.21,-17.62),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((0.24,10.00),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((12.93,28.12),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((16.83,32.61),1,0,"");
endfig;
beginfig(71);
drawoptions();
p_label(btex \thheight \thheightneg \thfb\char50 \char52 \mainfont{} etex,(31.46,34.52),0.0,p_label_mode_height);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-solitaire_plan";
ATTR__scrap := "SP-solitaire_plan";
beginfig(72);
current_src := "th2/solitaire-plan.th2 [356]";
string area_border[];
area_border[1] := "l168-188-802";
drawoptions(withcolor (0.00000,0.36538,0.88462,0.48000));
a_clay(buildcycle(((-49.72,120.38)
 .. controls (-48.93,118.54) and (-49.36,114.35) .. (-49.36,114.35)
 .. controls (-49.36,114.35) and (-53.68,106.43) .. (-54.40,107.15)
 .. controls (-55.39,108.14) and (-60.88,111.56) .. (-67.27,109.76)
 .. controls (-70.11,108.96) and (-57.82,121.82) .. (-57.82,121.82)
 .. controls (-57.82,121.82) and (-51.43,124.34) .. cycle
)));
current_src := "th2/solitaire-plan.th2 [177]";
string area_border[];
area_border[1] := "l143-295-302";
drawoptions(withcolor (0.00000,0.40000,0.80000,0.00000));
a_flowstone(buildcycle(((-20.02,-55.18)
 .. controls (-22.63,-54.54) and (-24.23,-52.94) .. (-24.96,-55.12)
 .. controls (-25.67,-57.28) and (-25.97,-62.68) .. (-25.97,-63.75)
 .. controls (-25.98,-64.82) and (-22.29,-67.24) .. (-21.03,-67.34)
 .. controls (-19.76,-67.45) and (-17.40,-55.84) .. cycle
)));
current_src := "th2/solitaire-plan.th2 [147]";
string area_border[];
area_border[1] := "l147-255-283";
drawoptions(withcolor (0.00000,0.36538,0.88462,0.48000));
a_clay(buildcycle(((-28.49,-64.31)
 .. controls (-26.88,-65.18) and (-25.35,-66.97) .. (-26.07,-67.78)
 .. controls (-26.79,-68.60) and (-28.76,-69.97) .. (-30.47,-70.88)
 .. controls (-32.18,-71.79) and (-35.78,-75.29) .. (-37.31,-76.63)
 .. controls (-38.84,-77.97) and (-42.45,-81.19) .. (-44.16,-81.64)
 .. controls (-45.87,-82.08) and (-48.12,-79.48) .. (-49.55,-77.78)
 .. controls (-50.99,-76.08) and (-53.06,-71.78) .. (-52.61,-70.97)
 .. controls (-52.16,-70.17) and (-30.10,-63.43) .. cycle
)));
ATTR__height := -1;
drawoptions();
l_pit(((-54.94,102.10)
 .. controls (-55.03,102.82) and (-55.75,102.91) .. (-56.20,103.82)
 .. controls (-56.65,104.72) and (-56.92,104.09) .. (-57.46,104.81)
 .. controls (-58.00,105.53) and (-58.18,106.07) .. (-58.36,106.97)
 .. controls (-58.54,107.87) and (-58.36,108.95) .. (-59.62,109.49)
 .. controls (-60.88,110.03) and (-63.58,110.21) .. (-65.29,109.58)
));
ATTR__height := -1;
drawoptions();
l_pit(((57.02,45.81)
 .. controls (56.39,42.93) and (55.48,40.41) .. (55.48,37.98)
 .. controls (55.48,35.54) and (55.12,32.25) .. (57.19,31.05)
));
ATTR__height := -1;
drawoptions();
l_pit(((-18.31,34.60)
 .. controls (-18.31,34.60) and (-18.31,33.88) .. (-18.40,33.34)
));
ATTR__height := -1;
drawoptions();
l_contour(((-58.54,107.87)
 .. controls (-60.97,109.76) and (-64.75,107.24) .. (-66.01,105.62)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-53.32,100.40)
 .. controls (-54.40,100.31) and (-57.01,99.41) .. (-58.36,96.79)
),-1);
ATTR__height := -1;
drawoptions();
l_rockborder(((-43.78,82.85)
 .. controls (-44.77,83.21) and (-45.13,82.58) .. (-45.49,82.22)
 .. controls (-45.85,81.86) and (-45.94,80.78) .. (-45.31,80.60)
 .. controls (-44.68,80.42) and (-43.51,80.60) .. (-43.51,81.23)
 .. controls (-43.51,81.86) and (-42.79,82.49) .. cycle
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-37.84,75.02)
 .. controls (-39.37,75.02) and (-42.16,73.22) .. (-42.70,72.23)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-30.19,65.47)
 .. controls (-31.63,65.11) and (-34.15,62.77) .. (-34.69,61.96)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-21.10,55.85)
 .. controls (-22.09,55.30) and (-23.71,52.51) .. (-23.98,51.61)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-12.28,43.60)
 .. controls (-13.63,44.05) and (-15.79,43.88) .. (-16.87,43.34)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-6.79,30.02)
 .. controls (-7.96,30.19) and (-10.21,28.93) .. (-10.75,27.76)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-2.92,22.55)
 .. controls (-4.00,22.82) and (-7.15,21.46) .. (-7.78,20.74)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-0.39,12.46)
 .. controls (-1.83,12.91) and (-4.08,11.56) .. (-4.53,11.02)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((2.57,4.27)
 .. controls (1.67,4.27) and (-1.66,3.46) .. (-2.28,2.92)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((5.73,-4.10)
 .. controls (4.19,-3.83) and (2.31,-4.28) .. (1.14,-5.27)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((7.98,-7.69)
 .. controls (6.36,-7.61) and (5.01,-8.60) .. (4.02,-9.59)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((9.69,-11.92)
 .. controls (8.34,-11.93) and (6.45,-13.28) .. (5.91,-13.82)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((11.49,-15.70)
 .. controls (10.13,-15.61) and (7.97,-16.70) .. (7.43,-17.60)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((12.83,-21.56)
 .. controls (11.39,-21.38) and (9.77,-21.56) .. (9.14,-22.36)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((13.46,-25.34)
 .. controls (12.48,-24.78) and (10.58,-25.51) .. (10.03,-25.86)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-55.57,107.96)
 .. controls (-56.11,110.03) and (-59.89,111.02) .. (-61.15,111.20)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-54.40,110.21)
 .. controls (-55.75,111.65) and (-59.35,114.35) .. (-61.87,113.18)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-56.11,114.62)
 .. controls (-56.83,115.25) and (-58.81,115.97) .. (-60.43,115.61)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-55.03,115.70)
 .. controls (-55.21,116.42) and (-57.73,117.59) .. (-59.35,117.59)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-52.78,116.06)
 .. controls (-53.23,117.32) and (-54.58,119.30) .. (-56.29,119.84)
));
ATTR__id := "l120-199-791";
ATTR__height := -1;
drawoptions();
l_border_visible(((-51.61,115.79)
 .. controls (-51.52,117.32) and (-51.43,118.13) .. (-52.06,119.66)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_contour(((-40.92,-82.81)
 .. controls (-42.45,-82.00) and (-42.09,-82.00) .. (-42.63,-81.01)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((52.15,-27.61)
 .. controls (51.41,-27.89) and (48.68,-28.60) .. (47.52,-30.98)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((55.03,-30.43)
 .. controls (54.35,-31.21) and (50.93,-34.75) .. (50.91,-35.84)
),-1);
ATTR__height := -1;
drawoptions();
l_border_visible(((50.04,-25.50)
 .. controls (48.33,-25.59) and (45.67,-27.40) .. (44.94,-28.62)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((23.89,18.89)
 .. controls (23.35,19.34) and (22.54,18.26) .. (22.54,18.26)
 .. controls (22.54,18.26) and (21.72,17.44) .. (22.09,17.27)
 .. controls (23.26,16.73) and (21.82,16.28) .. (22.27,16.28)
 .. controls (22.72,16.28) and (23.62,15.56) .. (23.80,15.92)
 .. controls (23.98,16.28) and (24.97,17.00) .. (24.52,17.45)
 .. controls (24.07,17.90) and (24.43,18.44) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((34.87,28.25)
 .. controls (34.69,28.61) and (33.88,29.11) .. (33.52,28.70)
 .. controls (32.80,27.89) and (32.98,26.90) .. (33.70,26.72)
 .. controls (34.42,26.54) and (34.42,26.36) .. (34.42,25.91)
 .. controls (34.42,25.46) and (34.78,25.37) .. (34.96,25.01)
 .. controls (35.14,24.65) and (35.77,24.38) .. (36.22,24.83)
 .. controls (36.67,25.28) and (37.39,25.20) .. (37.39,25.92)
 .. controls (37.39,26.64) and (36.13,26.36) .. (36.13,26.81)
 .. controls (36.13,27.26) and (35.05,27.89) .. cycle
));
ATTR__height := -1;
drawoptions();
l_border_visible(((49.90,34.64)
 .. controls (50.26,33.65) and (50.53,31.67) .. (51.07,31.04)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((48.10,29.51)
 .. controls (47.65,31.13) and (46.75,33.47) .. (46.48,34.19)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((44.78,26.64)
 .. controls (45.40,27.90) and (43.33,33.21) .. (41.90,33.93)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((52.24,36.71)
 .. controls (52.24,35.90) and (52.60,31.76) .. (53.23,30.68)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((53.77,38.69)
 .. controls (53.50,37.34) and (53.86,32.39) .. (54.58,31.04)
));
ATTR__height := -1;
drawoptions();
l_contour(((-45.40,114.62)
 .. controls (-45.22,115.25) and (-45.13,117.05) .. (-45.22,117.68)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-33.61,120.47)
 .. controls (-33.97,119.39) and (-34.78,116.15) .. (-34.60,115.52)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-29.83,115.25)
 .. controls (-30.91,115.70) and (-33.88,114.98) .. (-34.96,114.80)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-30.19,113.81)
 .. controls (-31.18,114.17) and (-33.70,113.63) .. (-35.05,112.91)
),-1);
drawoptions();
p_blocks((1.38,-15.84),0.0,1.00,(0,0));
drawoptions();
p_blocks((1.89,-21.54),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_contour(((20.85,-27.45)
 .. controls (19.36,-27.04) and (19.19,-26.67) .. (18.55,-25.80)
),-1);
drawoptions();
p_blocks((0.01,-39.87),0.0,1.00,(0,0));
drawoptions();
p_blocks((1.53,-41.59),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_contour(((-22.44,-48.98)
 .. controls (-21.00,-48.53) and (-19.39,-49.14) .. (-18.85,-49.77)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-19.31,-52.35)
 .. controls (-20.21,-52.98) and (-22.63,-52.71) .. (-23.17,-52.09)
),-1);
ATTR__height := -1;
drawoptions();
l_border_visible(((-41.37,-80.02)
 .. controls (-41.37,-80.02) and (-43.26,-81.73) .. (-44.88,-82.36)
 .. controls (-46.50,-82.99) and (-46.05,-82.72) .. (-47.40,-83.62)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-52.97,-75.00)
 .. controls (-54.14,-75.09) and (-56.75,-75.63) .. (-56.93,-76.62)
 .. controls (-57.11,-77.61) and (-57.47,-77.61) .. (-58.46,-78.50)
 .. controls (-59.46,-79.40) and (-60.00,-79.85) .. (-59.28,-80.39)
 .. controls (-58.56,-80.93) and (-56.39,-81.20) .. (-55.31,-81.20)
 .. controls (-54.23,-81.20) and (-51.09,-80.93) .. (-50.73,-79.85)
 .. controls (-50.37,-78.77) and (-51.80,-74.91) .. cycle
));
ATTR__height := -1;
drawoptions();
l_floormeander(((-24.45,-67.96)
 -- (-40.47,-81.10)
));
drawoptions();
p_blocks((-51.72,-88.30),0.0,1.00,(0,0));
drawoptions();
p_blocks((-54.78,-85.97),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_border_visible(((-47.31,-93.70)
 .. controls (-48.48,-93.16) and (-52.71,-92.98) .. (-53.52,-93.34)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-46.59,-98.83)
 .. controls (-47.49,-98.92) and (-52.35,-99.37) .. (-53.25,-100.27)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-44.79,-102.16)
 .. controls (-45.51,-102.25) and (-51.45,-102.97) .. (-52.44,-103.60)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-42.18,-106.57)
 .. controls (-43.26,-106.57) and (-50.73,-107.92) .. (-51.63,-108.19)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-63.33,-91.09)
 .. controls (-66.30,-90.10) and (-69.99,-91.00) .. (-72.15,-91.54)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-64.59,-96.22)
 .. controls (-65.58,-95.68) and (-71.79,-97.03) .. (-74.31,-97.84)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-65.49,-102.43)
 .. controls (-67.47,-102.25) and (-73.14,-103.42) .. (-74.94,-104.86)
));
drawoptions();
p_blocks((3.11,-26.79),0.0,1.00,(0,0));
drawoptions();
p_blocks((-57.10,106.88),0.0,1.00,(0,0));
endfig;
beginfig(73);
draw_upscrap(1)(1,((24.71,-12.83)
 .. controls (23.81,-13.19) and (21.02,-15.34) .. (19.85,-16.06)
 .. controls (18.68,-16.78) and (17.24,-17.68) .. (16.25,-18.22)
 .. controls (15.26,-18.76) and (13.46,-20.93) .. (13.10,-19.57)
 .. controls (12.74,-18.22) and (8.79,-8.50) .. (8.62,-7.06)
 .. controls (8.44,-5.62) and (8.02,-3.55) .. (7.48,-1.84)
 .. controls (6.95,-0.13) and (5.56,1.48) .. (4.38,1.48)
 .. controls (2.12,1.48) and (2.30,4.99) .. (1.40,7.15)
 .. controls (0.51,9.31) and (-1.83,15.79) .. (-2.65,18.77)
 .. controls (-3.46,21.74) and (-4.36,27.14) .. (-6.07,29.12)
 .. controls (-7.78,31.09) and (-9.94,32.00) .. (-11.02,32.80)
 .. controls (-12.10,33.61) and (-12.82,34.69) .. (-12.01,34.51)
 .. controls (-11.20,34.34) and (-9.85,34.16) .. (-9.76,35.24)
 .. controls (-9.67,36.32) and (-9.85,37.22) .. (-10.66,37.13)
 .. controls (-11.47,37.04) and (-11.92,35.32) .. (-12.46,35.32)
 .. controls (-13.00,35.32) and (-13.81,35.32) .. (-13.54,36.22)
 .. controls (-13.27,37.12) and (-12.82,37.57) .. (-12.55,38.56)
 .. controls (-12.28,39.55) and (-12.28,46.75) .. (-13.00,48.37)
 .. controls (-13.72,49.99) and (-15.52,51.44) .. (-17.50,52.43)
 .. controls (-19.48,53.42) and (-26.14,59.35) .. (-27.58,61.06)
 .. controls (-29.02,62.77) and (-34.78,70.34) .. (-36.04,72.41)
 .. controls (-37.30,74.48) and (-42.34,79.97) .. (-42.97,81.77)
 .. controls (-43.60,83.57) and (-49.90,95.45) .. (-51.34,97.07)
 .. controls (-52.78,98.69) and (-54.31,100.13) .. (-54.67,101.03)
 .. controls (-55.03,101.93) and (-55.21,102.64) .. (-54.85,102.73)
 .. controls (-54.49,102.82) and (-54.13,103.63) .. (-53.50,102.55)
 .. controls (-52.87,101.47) and (-52.15,97.43) .. (-50.26,98.06)
 .. controls (-48.37,98.68) and (-48.37,99.22) .. (-49.18,100.30)
 .. controls (-49.99,101.38) and (-53.14,102.46) .. (-51.70,103.09)
 .. controls (-50.26,103.72) and (-46.84,104.54) .. (-45.22,105.26)
 .. controls (-43.60,105.98) and (-40.54,106.70) .. (-39.10,107.42)
 .. controls (-37.66,108.14) and (-35.41,108.95) .. (-33.70,110.21)
 .. controls (-31.99,111.47) and (-30.46,111.11) .. (-30.37,112.37)
 .. controls (-30.28,113.63) and (-31.45,117.23) .. (-30.01,117.68)
),
1,((-30.01,117.68)
 .. controls (-28.21,117.86) and (-27.04,117.95) .. (-25.69,118.49)
 .. controls (-24.81,118.84) and (-25.06,119.12) .. (-24.97,119.48)
),
1,((-25.96,119.84)
 .. controls (-25.96,119.39) and (-26.32,119.21) .. (-27.22,119.21)
 .. controls (-28.12,119.21) and (-29.83,119.39) .. (-30.19,119.30)
),
1,((-30.19,119.30)
 .. controls (-31.36,119.30) and (-33.16,119.30) .. (-34.42,119.03)
 .. controls (-35.68,118.76) and (-40.81,117.59) .. (-42.52,117.59)
 .. controls (-44.23,117.59) and (-45.22,116.69) .. (-45.85,117.23)
 .. controls (-46.48,117.77) and (-54.85,120.02) .. (-56.65,119.30)
 .. controls (-58.45,118.58) and (-61.06,114.44) .. (-61.15,113.09)
 .. controls (-61.24,111.74) and (-60.97,110.66) .. (-61.96,110.93)
 .. controls (-63.94,111.47) and (-67.63,109.49) .. (-64.66,104.00)
),
1,((-64.66,104.00)
 .. controls (-64.12,102.20) and (-61.06,101.03) .. (-60.52,100.31)
 .. controls (-59.98,99.59) and (-59.71,99.95) .. (-58.72,99.04)
 .. controls (-57.73,98.14) and (-52.42,90.14) .. (-51.43,88.61)
 .. controls (-50.44,87.08) and (-46.48,81.50) .. (-45.85,80.06)
 .. controls (-45.22,78.62) and (-43.96,76.28) .. (-43.06,73.85)
 .. controls (-42.16,71.42) and (-38.92,68.00) .. (-37.57,66.20)
 .. controls (-36.22,64.39) and (-31.81,59.08) .. (-30.91,57.73)
 .. controls (-30.01,56.38) and (-20.47,49.72) .. (-19.30,49.36)
 .. controls (-18.13,49.00) and (-17.41,48.64) .. (-16.96,47.74)
 .. controls (-16.51,46.85) and (-16.60,45.32) .. (-16.60,43.88)
 .. controls (-16.60,42.44) and (-17.86,37.39) .. (-18.04,35.59)
 .. controls (-18.22,33.79) and (-18.58,34.96) .. (-19.03,35.41)
),
1,((-19.39,34.33)
 .. controls (-18.40,33.34) and (-10.21,28.21) .. (-9.04,26.41)
 .. controls (-7.87,24.61) and (-7.42,18.76) .. (-5.98,15.88)
 .. controls (-4.53,13.00) and (-2.20,4.27) .. (-1.93,2.29)
 .. controls (-1.66,0.31) and (-1.02,-3.02) .. (-1.02,-4.28)
 .. controls (-1.01,-5.54) and (-1.01,-9.57) .. (-0.66,-11.18)
 .. controls (-0.31,-12.79) and (0.03,-15.37) .. (-0.31,-17.50)
 .. controls (-0.64,-19.64) and (-0.06,-21.52) .. (-0.12,-23.05)
 .. controls (-0.17,-24.59) and (1.49,-28.66) .. (2.45,-33.13)
),
1,((2.45,-33.13)
 .. controls (2.90,-35.55) and (1.95,-35.88) .. (-0.01,-37.84)
 .. controls (-2.01,-39.84) and (-8.62,-40.16) .. (-10.70,-40.20)
 .. controls (-12.78,-40.24) and (-19.12,-39.39) .. (-22.33,-40.95)
),
1,((-22.90,-42.91)
 .. controls (-24.95,-44.14) and (-23.32,-44.12) .. (-22.69,-45.35)
 .. controls (-22.05,-46.60) and (-22.44,-48.89) .. (-22.10,-50.24)
 .. controls (-21.75,-51.68) and (-23.53,-52.28) .. (-23.88,-53.75)
 .. controls (-24.24,-55.20) and (-24.79,-59.14) .. (-25.16,-62.15)
 .. controls (-25.53,-65.17) and (-30.92,-66.12) .. (-34.15,-66.68)
 .. controls (-37.39,-67.23) and (-45.50,-70.26) .. (-49.64,-70.79)
 .. controls (-53.78,-71.33) and (-58.28,-73.84) .. (-61.16,-76.17)
 .. controls (-64.05,-78.50) and (-64.41,-79.93) .. (-66.75,-82.45)
 .. controls (-69.09,-84.97) and (-72.15,-89.11) .. (-74.13,-93.25)
),
1,((-74.13,-93.25)
 .. controls (-75.57,-100.09) and (-75.39,-102.97) .. (-75.21,-106.39)
),
1,((-41.37,-109.90)
 .. controls (-46.41,-103.24) and (-45.69,-101.17) .. (-48.21,-96.67)
),
1,((-48.21,-96.67)
 .. controls (-48.75,-93.25) and (-44.43,-88.57) .. (-43.35,-85.87)
 .. controls (-42.27,-83.17) and (-36.68,-79.60) .. (-33.44,-76.73)
 .. controls (-30.19,-73.85) and (-24.10,-70.40) .. (-22.47,-66.97)
 .. controls (-20.85,-63.58) and (-19.76,-52.98) .. (-19.76,-51.15)
 .. controls (-19.76,-49.39) and (-18.32,-49.08) .. (-17.20,-47.54)
 .. controls (-16.05,-45.96) and (-7.90,-44.98) .. (-2.43,-44.01)
 .. controls (2.99,-43.05) and (4.72,-40.96) .. (7.44,-38.69)
 .. controls (10.20,-36.39) and (12.77,-34.68) .. (14.08,-32.80)
 .. controls (15.40,-30.90) and (17.52,-32.03) .. (17.50,-30.47)
 .. controls (17.48,-28.96) and (21.80,-27.00) .. (23.53,-25.55)
 .. controls (25.25,-24.09) and (25.43,-24.47) .. (31.18,-20.70)
),
1,((31.18,-20.70)
 .. controls (32.56,-19.79) and (32.76,-19.42) .. (34.53,-20.88)
 .. controls (36.29,-22.33) and (41.51,-23.53) .. (42.31,-24.98)
 .. controls (43.10,-26.42) and (49.89,-33.12) .. (51.82,-35.69)
),
1,((56.42,-31.51)
 .. controls (55.26,-30.87) and (54.09,-30.65) .. (53.17,-29.02)
 .. controls (52.26,-27.40) and (50.94,-26.91) .. (51.66,-26.44)
 .. controls (52.54,-25.86) and (60.59,-27.69) .. (62.57,-27.87)
),
1,((63.14,-24.97)
 .. controls (59.34,-24.57) and (52.05,-23.42) .. (49.55,-21.85)
 .. controls (47.01,-20.25) and (47.21,-19.44) .. (45.50,-18.36)
 .. controls (43.79,-17.26) and (44.90,-16.88) .. (45.74,-14.64)
 .. controls (46.58,-12.42) and (44.29,-15.24) .. (42.70,-18.59)
 .. controls (41.08,-22.03) and (40.83,-19.34) .. (39.58,-17.14)
 .. controls (38.36,-14.98) and (40.42,-14.59) .. (38.24,-12.85)
 .. controls (36.12,-11.14) and (35.73,-10.08) .. (34.30,-7.43)
 .. controls (32.87,-4.76) and (31.81,-5.48) .. (31.45,-2.43)
 .. controls (31.09,0.63) and (30.91,0.27) .. (26.77,1.71)
 .. controls (22.63,3.15) and (26.05,2.97) .. (24.79,5.67)
 .. controls (23.53,8.37) and (25.33,13.95) .. (26.59,16.29)
 .. controls (27.85,18.63) and (29.46,18.28) .. (31.63,20.25)
 .. controls (33.79,22.23) and (35.15,24.98) .. (38.11,25.83)
 .. controls (40.64,26.55) and (43.16,26.37) .. (46.03,28.88)
 .. controls (48.91,31.40) and (49.27,31.22) .. (52.87,31.58)
 .. controls (56.41,31.94) and (58.46,30.87) .. (61.16,28.91)
),
1,((60.43,49.60)
 .. controls (54.19,45.01) and (56.48,39.51) .. (51.79,35.72)
 .. controls (47.79,32.48) and (48.91,33.56) .. (46.75,33.74)
 .. controls (43.17,34.04) and (42.25,32.85) .. (39.56,31.77)
 .. controls (36.85,30.69) and (34.15,29.61) .. (32.35,27.98)
 .. controls (30.55,26.36) and (30.55,25.46) .. (28.93,24.39)
 .. controls (27.31,23.31) and (23.53,20.60) .. (22.09,18.80)
 .. controls (20.65,17.00) and (20.83,14.12) .. (19.93,11.61)
 .. controls (19.03,9.09) and (16.69,5.30) .. (17.95,2.78)
 .. controls (19.21,0.26) and (20.29,-0.63) .. (22.45,-1.17)
 .. controls (24.61,-1.71) and (26.23,-2.43) .. (27.12,-4.59)
 .. controls (28.02,-6.75) and (31.27,-16.29) .. (29.74,-17.69)
),
1,((29.74,-17.69)
 .. controls (27.63,-19.48) and (20.57,-23.79) .. (19.41,-25.07)
 .. controls (18.26,-26.36) and (15.55,-28.11) .. (14.47,-27.36)
 .. controls (13.39,-26.61) and (13.81,-26.99) .. (14.05,-25.04)
 .. controls (14.30,-23.14) and (12.47,-22.46) .. (14.09,-21.37)
 .. controls (15.71,-20.29) and (17.15,-18.76) .. (19.13,-17.50)
 .. controls (21.11,-16.23) and (24.62,-14.18) .. (25.34,-13.46)
));
draw_upscrap(0)(1,((-54.33,-96.13)
 .. controls (-56.49,-98.29) and (-56.85,-100.63) .. (-59.19,-102.80)
 .. controls (-61.53,-104.96) and (-63.87,-107.47) .. (-64.77,-105.67)
 .. controls (-65.67,-103.87) and (-64.59,-96.13) .. (-63.69,-95.95)
),
1,((-63.69,-95.95)
 .. controls (-62.97,-93.43) and (-62.61,-92.53) .. (-61.89,-90.73)
 .. controls (-61.17,-88.93) and (-57.21,-88.58) .. (-55.23,-89.11)
 .. controls (-53.25,-89.65) and (-53.43,-89.83) .. (-53.43,-91.81)
 .. controls (-53.43,-93.79) and (-53.61,-94.87) .. (-54.33,-96.13)
));
draw_upscrap(0)(1,((21.91,5.13)
 .. controls (21.91,6.57) and (22.36,6.75) .. (22.99,6.75)
 .. controls (23.62,6.75) and (23.80,5.58) .. (23.80,4.41)
 .. controls (23.80,3.24) and (23.35,2.61) .. (22.81,2.97)
 .. controls (22.27,3.32) and (21.91,3.68) .. cycle
));
draw_upscrap(0)(1,((4.56,-12.38)
 .. controls (5.69,-14.03) and (7.79,-19.75) .. (8.51,-21.73)
 .. controls (9.23,-23.70) and (10.11,-24.60) .. (9.17,-26.19)
 .. controls (8.19,-27.81) and (6.66,-30.66) .. (6.33,-28.69)
 .. controls (6.00,-26.71) and (4.31,-26.52) .. (5.14,-24.17)
 .. controls (5.95,-21.87) and (4.65,-22.38) .. (3.60,-19.87)
 .. controls (2.55,-17.36) and (0.60,-6.62) .. cycle
));
draw_upscrap(0)(1,((-54.15,-99.37)
 .. controls (-52.35,-97.57) and (-52.35,-104.23) .. (-51.45,-106.21)
 .. controls (-50.55,-108.19) and (-51.27,-109.81) .. (-52.53,-110.17)
 .. controls (-53.79,-110.53) and (-57.57,-110.00) .. (-58.65,-108.74)
 .. controls (-59.73,-107.48) and (-59.91,-106.76) .. (-58.11,-105.32)
 .. controls (-56.31,-103.87) and (-55.40,-100.62) .. cycle
));
draw_upscrap(0)(1,((-55.93,107.24)
 .. controls (-55.30,108.32) and (-54.58,109.67) .. (-54.94,110.93)
 .. controls (-55.30,112.19) and (-56.29,113.27) .. (-56.74,114.53)
 .. controls (-57.19,115.79) and (-54.94,116.06) .. (-54.40,116.69)
 .. controls (-53.86,117.32) and (-47.47,115.34) .. (-46.30,115.16)
 .. controls (-45.13,114.98) and (-37.39,115.34) .. (-35.86,115.79)
 .. controls (-34.33,116.24) and (-33.70,115.88) .. (-34.06,114.98)
 .. controls (-34.42,114.08) and (-35.14,114.17) .. (-35.05,112.91)
 .. controls (-34.96,111.65) and (-39.28,110.30) .. (-40.45,109.76)
 .. controls (-41.62,109.22) and (-49.27,106.87) .. (-50.62,106.33)
 .. controls (-51.97,105.79) and (-53.77,105.34) .. (-54.49,105.34)
 .. controls (-55.21,105.35) and (-56.44,106.37) .. cycle
));
draw_downscrap;
endfig;
beginfig(74);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((60.43,49.60)
 .. controls (54.19,45.01) and (56.48,39.51) .. (51.79,35.72)
 .. controls (47.79,32.48) and (48.91,33.56) .. (46.75,33.74)
 .. controls (43.17,34.04) and (42.25,32.85) .. (39.56,31.77)
 .. controls (36.85,30.69) and (34.15,29.61) .. (32.35,27.98)
 .. controls (30.55,26.36) and (30.55,25.46) .. (28.93,24.39)
 .. controls (27.31,23.31) and (23.53,20.60) .. (22.09,18.80)
 .. controls (20.65,17.00) and (20.83,14.12) .. (19.93,11.61)
 .. controls (19.03,9.09) and (16.69,5.30) .. (17.95,2.78)
 .. controls (19.21,0.26) and (20.29,-0.63) .. (22.45,-1.17)
 .. controls (24.61,-1.71) and (26.23,-2.43) .. (27.12,-4.59)
 .. controls (28.02,-6.75) and (31.27,-16.29) .. (29.74,-17.69)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((31.18,-20.70)
 .. controls (32.56,-19.79) and (32.76,-19.42) .. (34.53,-20.88)
 .. controls (36.29,-22.33) and (41.51,-23.53) .. (42.31,-24.98)
 .. controls (43.10,-26.42) and (49.89,-33.12) .. (51.82,-35.69)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((56.42,-31.51)
 .. controls (55.26,-30.87) and (54.09,-30.65) .. (53.17,-29.02)
 .. controls (52.26,-27.40) and (50.94,-26.91) .. (51.66,-26.44)
 .. controls (52.54,-25.86) and (60.59,-27.69) .. (62.57,-27.87)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((29.74,-17.69)
 .. controls (27.63,-19.48) and (20.57,-23.79) .. (19.41,-25.07)
 .. controls (18.26,-26.36) and (15.55,-28.11) .. (14.47,-27.36)
 .. controls (13.39,-26.61) and (13.81,-26.99) .. (14.05,-25.04)
 .. controls (14.30,-23.14) and (12.47,-22.46) .. (14.09,-21.37)
 .. controls (15.71,-20.29) and (17.15,-18.76) .. (19.13,-17.50)
 .. controls (21.11,-16.23) and (24.62,-14.18) .. (25.34,-13.46)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((24.71,-12.83)
 .. controls (23.81,-13.19) and (21.02,-15.34) .. (19.85,-16.06)
 .. controls (18.68,-16.78) and (17.24,-17.68) .. (16.25,-18.22)
 .. controls (15.26,-18.76) and (13.46,-20.93) .. (13.10,-19.57)
 .. controls (12.74,-18.22) and (8.79,-8.50) .. (8.62,-7.06)
 .. controls (8.44,-5.62) and (8.02,-3.55) .. (7.48,-1.84)
 .. controls (6.95,-0.13) and (5.56,1.48) .. (4.38,1.48)
 .. controls (2.12,1.48) and (2.30,4.99) .. (1.40,7.15)
 .. controls (0.51,9.31) and (-1.83,15.79) .. (-2.65,18.77)
 .. controls (-3.46,21.74) and (-4.36,27.14) .. (-6.07,29.12)
 .. controls (-7.78,31.09) and (-9.94,32.00) .. (-11.02,32.80)
 .. controls (-12.10,33.61) and (-12.82,34.69) .. (-12.01,34.51)
 .. controls (-11.20,34.34) and (-9.85,34.16) .. (-9.76,35.24)
 .. controls (-9.67,36.32) and (-9.85,37.22) .. (-10.66,37.13)
 .. controls (-11.47,37.04) and (-11.92,35.32) .. (-12.46,35.32)
 .. controls (-13.00,35.32) and (-13.81,35.32) .. (-13.54,36.22)
 .. controls (-13.27,37.12) and (-12.82,37.57) .. (-12.55,38.56)
 .. controls (-12.28,39.55) and (-12.28,46.75) .. (-13.00,48.37)
 .. controls (-13.72,49.99) and (-15.52,51.44) .. (-17.50,52.43)
 .. controls (-19.48,53.42) and (-26.14,59.35) .. (-27.58,61.06)
 .. controls (-29.02,62.77) and (-34.78,70.34) .. (-36.04,72.41)
 .. controls (-37.30,74.48) and (-42.34,79.97) .. (-42.97,81.77)
 .. controls (-43.60,83.57) and (-49.90,95.45) .. (-51.34,97.07)
 .. controls (-52.78,98.69) and (-54.31,100.13) .. (-54.67,101.03)
 .. controls (-55.03,101.93) and (-55.21,102.64) .. (-54.85,102.73)
 .. controls (-54.49,102.82) and (-54.13,103.63) .. (-53.50,102.55)
 .. controls (-52.87,101.47) and (-52.15,97.43) .. (-50.26,98.06)
 .. controls (-48.37,98.68) and (-48.37,99.22) .. (-49.18,100.30)
 .. controls (-49.99,101.38) and (-53.14,102.46) .. (-51.70,103.09)
 .. controls (-50.26,103.72) and (-46.84,104.54) .. (-45.22,105.26)
 .. controls (-43.60,105.98) and (-40.54,106.70) .. (-39.10,107.42)
 .. controls (-37.66,108.14) and (-35.41,108.95) .. (-33.70,110.21)
 .. controls (-31.99,111.47) and (-30.46,111.11) .. (-30.37,112.37)
 .. controls (-30.28,113.63) and (-31.45,117.23) .. (-30.01,117.68)
));
drawoptions();
p_traverse((51.16,45.09),0.0,1.00,(0,0));
drawoptions();
p_rope((48.91,40.32),0.0,1.00,(0,0));
drawoptions();
p_rope((-51.70,111.56),0.0,1.00,(0,0));
drawoptions();
p_rope((61.66,-20.37),0.0,1.00,(0,0));
drawoptions();
p_narrowend((26.47,-16.02),0.0,1.00,(0,0));
drawoptions();
p_narrowend((-22.63,114.53),0.0,1.00,(0,0));
drawoptions();
p_rope((-43.35,-93.89),0.0,1.00,(0,0));
drawoptions();
p_rope((-79.98,-90.20),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-30.19,119.30)
 .. controls (-31.36,119.30) and (-33.16,119.30) .. (-34.42,119.03)
 .. controls (-35.68,118.76) and (-40.81,117.59) .. (-42.52,117.59)
 .. controls (-44.23,117.59) and (-45.22,116.69) .. (-45.85,117.23)
 .. controls (-46.48,117.77) and (-54.85,120.02) .. (-56.65,119.30)
 .. controls (-58.45,118.58) and (-61.06,114.44) .. (-61.15,113.09)
 .. controls (-61.24,111.74) and (-60.97,110.66) .. (-61.96,110.93)
 .. controls (-63.94,111.47) and (-67.63,109.49) .. (-64.66,104.00)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-55.93,107.24)
 .. controls (-55.30,108.32) and (-54.58,109.67) .. (-54.94,110.93)
 .. controls (-55.30,112.19) and (-56.29,113.27) .. (-56.74,114.53)
 .. controls (-57.19,115.79) and (-54.94,116.06) .. (-54.40,116.69)
 .. controls (-53.86,117.32) and (-47.47,115.34) .. (-46.30,115.16)
 .. controls (-45.13,114.98) and (-37.39,115.34) .. (-35.86,115.79)
 .. controls (-34.33,116.24) and (-33.70,115.88) .. (-34.06,114.98)
 .. controls (-34.42,114.08) and (-35.14,114.17) .. (-35.05,112.91)
 .. controls (-34.96,111.65) and (-39.28,110.30) .. (-40.45,109.76)
 .. controls (-41.62,109.22) and (-49.27,106.87) .. (-50.62,106.33)
 .. controls (-51.97,105.79) and (-53.77,105.34) .. (-54.49,105.34)
 .. controls (-55.21,105.35) and (-56.44,106.37) .. cycle
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-30.01,117.68)
 .. controls (-28.21,117.86) and (-27.04,117.95) .. (-25.69,118.49)
 .. controls (-24.81,118.84) and (-25.06,119.12) .. (-24.97,119.48)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-25.96,119.84)
 .. controls (-25.96,119.39) and (-26.32,119.21) .. (-27.22,119.21)
 .. controls (-28.12,119.21) and (-29.83,119.39) .. (-30.19,119.30)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-48.21,-96.67)
 .. controls (-48.75,-93.25) and (-44.43,-88.57) .. (-43.35,-85.87)
 .. controls (-42.27,-83.17) and (-36.68,-79.60) .. (-33.44,-76.73)
 .. controls (-30.19,-73.85) and (-24.10,-70.40) .. (-22.47,-66.97)
 .. controls (-20.85,-63.58) and (-19.76,-52.98) .. (-19.76,-51.15)
 .. controls (-19.76,-49.39) and (-18.32,-49.08) .. (-17.20,-47.54)
 .. controls (-16.05,-45.96) and (-7.90,-44.98) .. (-2.43,-44.01)
 .. controls (2.99,-43.05) and (4.72,-40.96) .. (7.44,-38.69)
 .. controls (10.20,-36.39) and (12.77,-34.68) .. (14.08,-32.80)
 .. controls (15.40,-30.90) and (17.52,-32.03) .. (17.50,-30.47)
 .. controls (17.48,-28.96) and (21.80,-27.00) .. (23.53,-25.55)
 .. controls (25.25,-24.09) and (25.43,-24.47) .. (31.18,-20.70)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-63.69,-95.95)
 .. controls (-62.97,-93.43) and (-62.61,-92.53) .. (-61.89,-90.73)
 .. controls (-61.17,-88.93) and (-57.21,-88.58) .. (-55.23,-89.11)
 .. controls (-53.25,-89.65) and (-53.43,-89.83) .. (-53.43,-91.81)
 .. controls (-53.43,-93.79) and (-53.61,-94.87) .. (-54.33,-96.13)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((-54.15,-99.37)
 .. controls (-52.35,-97.57) and (-52.35,-104.23) .. (-51.45,-106.21)
 .. controls (-50.55,-108.19) and (-51.27,-109.81) .. (-52.53,-110.17)
 .. controls (-53.79,-110.53) and (-57.57,-110.00) .. (-58.65,-108.74)
 .. controls (-59.73,-107.48) and (-59.91,-106.76) .. (-58.11,-105.32)
 .. controls (-56.31,-103.87) and (-55.40,-100.62) .. cycle
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((-41.37,-109.90)
 .. controls (-46.41,-103.24) and (-45.69,-101.17) .. (-48.21,-96.67)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((-74.13,-93.25)
 .. controls (-75.57,-100.09) and (-75.39,-102.97) .. (-75.21,-106.39)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((4.56,-12.38)
 .. controls (5.69,-14.03) and (7.79,-19.75) .. (8.51,-21.73)
 .. controls (9.23,-23.70) and (10.11,-24.60) .. (9.17,-26.19)
 .. controls (8.19,-27.81) and (6.66,-30.66) .. (6.33,-28.69)
 .. controls (6.00,-26.71) and (4.31,-26.52) .. (5.14,-24.17)
 .. controls (5.95,-21.87) and (4.65,-22.38) .. (3.60,-19.87)
 .. controls (2.55,-17.36) and (0.60,-6.62) .. cycle
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((21.91,5.13)
 .. controls (21.91,6.57) and (22.36,6.75) .. (22.99,6.75)
 .. controls (23.62,6.75) and (23.80,5.58) .. (23.80,4.41)
 .. controls (23.80,3.24) and (23.35,2.61) .. (22.81,2.97)
 .. controls (22.27,3.32) and (21.91,3.68) .. cycle
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-19.39,34.33)
 .. controls (-18.40,33.34) and (-10.21,28.21) .. (-9.04,26.41)
 .. controls (-7.87,24.61) and (-7.42,18.76) .. (-5.98,15.88)
 .. controls (-4.53,13.00) and (-2.20,4.27) .. (-1.93,2.29)
 .. controls (-1.66,0.31) and (-1.02,-3.02) .. (-1.02,-4.28)
 .. controls (-1.01,-5.54) and (-1.01,-9.57) .. (-0.66,-11.18)
 .. controls (-0.31,-12.79) and (0.03,-15.37) .. (-0.31,-17.50)
 .. controls (-0.64,-19.64) and (-0.06,-21.52) .. (-0.12,-23.05)
 .. controls (-0.17,-24.59) and (1.49,-28.66) .. (2.45,-33.13)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-64.66,104.00)
 .. controls (-64.12,102.20) and (-61.06,101.03) .. (-60.52,100.31)
 .. controls (-59.98,99.59) and (-59.71,99.95) .. (-58.72,99.04)
 .. controls (-57.73,98.14) and (-52.42,90.14) .. (-51.43,88.61)
 .. controls (-50.44,87.08) and (-46.48,81.50) .. (-45.85,80.06)
 .. controls (-45.22,78.62) and (-43.96,76.28) .. (-43.06,73.85)
 .. controls (-42.16,71.42) and (-38.92,68.00) .. (-37.57,66.20)
 .. controls (-36.22,64.39) and (-31.81,59.08) .. (-30.91,57.73)
 .. controls (-30.01,56.38) and (-20.47,49.72) .. (-19.30,49.36)
 .. controls (-18.13,49.00) and (-17.41,48.64) .. (-16.96,47.74)
 .. controls (-16.51,46.85) and (-16.60,45.32) .. (-16.60,43.88)
 .. controls (-16.60,42.44) and (-17.86,37.39) .. (-18.04,35.59)
 .. controls (-18.22,33.79) and (-18.58,34.96) .. (-19.03,35.41)
));
drawoptions();
p_airdraught((-27.22,130.82),98.5,1.00,(0,0));
drawoptions();
p_continuation((-56.20,106.07),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_gradient(((3.65,-3.38)
 -- (11.94,-26.22)
));
ATTR__height := -1;
drawoptions();
l_gradient(((-8.77,30.28)
 -- (0.77,3.10)
));
ATTR__height := -1;
drawoptions();
l_gradient(((-41.71,75.83)
 .. controls (-41.71,75.83) and (-30.96,60.75) .. (-29.47,59.26)
 .. controls (-27.94,57.73) and (-21.55,53.05) .. (-21.55,53.05)
));
ATTR__height := -1;
drawoptions();
l_gradient(((45.80,-25.21)
 .. controls (45.80,-25.21) and (49.37,-29.88) .. (50.71,-30.80)
));
drawoptions();
p_helictite((25.15,-0.99),0.0,1.00,(0,0));
drawoptions();
p_stalactites((22.45,-0.09),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_gradient(((47.74,32.12)
 -- (43.15,30.06)
));
ATTR__height := -1;
drawoptions();
l_gradient(((49.90,32.57)
 -- (56.11,34.10)
));
drawoptions();
p_airdraught((22.99,-19.44),128.7,1.00,(0,0));
drawoptions(withcolor (0.00000,0.40000,0.80000,0.00000));
p_stalactite((52.33,-33.42),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_gradient(((-32.35,116.42)
 -- (-32.62,112.37)
));
drawoptions(withcolor (0.00000,0.40000,0.80000,0.00000));
p_flowstone((5.01,-0.86),0.0,1.00,(0,0));
drawoptions();
p_stalactites((24.12,-28.70),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_gradient(((-68.64,-89.29)
 -- (-69.09,-105.22)
));
ATTR__height := -1;
drawoptions();
l_gradient(((-51.54,-98.38)
 -- (-47.31,-109.45)
));
drawoptions();
p_stalagmites((-50.82,-95.41),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_gradient(((-50.35,117.23)
 .. controls (-51.25,117.59) and (-55.12,118.40) .. (-56.47,117.32)
 .. controls (-57.82,116.24) and (-58.90,111.74) .. (-58.81,109.58)
));
string ATTR_code;
ATTR_code := "D";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char67 \char111 \char108 \char109 \char97 \char116 \char97 \char103 \char101 \ \thfc\char184 \ \thfb\char99 \char114 \char101 \char117 \char115 \char101 \char114 \mainfont{}etex;
drawoptions();
p_continuation((-16.06,121.55),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
string ATTR_code;
ATTR_code := "E";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \thfc\char184 \ \thfb\char97 \char116 \char116 \char101 \char105 \char110 \char100 \char114 \char101 \mainfont{}etex;
drawoptions();
p_continuation((-23.17,35.68),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
string ATTR_code;
ATTR_code := "Q";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char80 \char117 \char105 \char116 \char115 \ \thfc\char184 \ \thfb\char100 \char101 \char115 \char99 \char101 \char110 \char100 \char114 \char101 \mainfont{}etex;
drawoptions();
p_continuation((-52.61,-130.82),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((2.45,-33.13)
 .. controls (2.90,-35.55) and (1.95,-35.88) .. (-0.01,-37.84)
 .. controls (-2.01,-39.84) and (-8.62,-40.16) .. (-10.70,-40.20)
 .. controls (-12.78,-40.24) and (-19.12,-39.39) .. (-22.33,-40.95)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-22.90,-42.91)
 .. controls (-24.95,-44.14) and (-23.32,-44.12) .. (-22.69,-45.35)
 .. controls (-22.05,-46.60) and (-22.44,-48.89) .. (-22.10,-50.24)
 .. controls (-21.75,-51.68) and (-23.53,-52.28) .. (-23.88,-53.75)
 .. controls (-24.24,-55.20) and (-24.79,-59.14) .. (-25.16,-62.15)
 .. controls (-25.53,-65.17) and (-30.92,-66.12) .. (-34.15,-66.68)
 .. controls (-37.39,-67.23) and (-45.50,-70.26) .. (-49.64,-70.79)
 .. controls (-53.78,-71.33) and (-58.28,-73.84) .. (-61.16,-76.17)
 .. controls (-64.05,-78.50) and (-64.41,-79.93) .. (-66.75,-82.45)
 .. controls (-69.09,-84.97) and (-72.15,-89.11) .. (-74.13,-93.25)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((-54.33,-96.13)
 .. controls (-56.49,-98.29) and (-56.85,-100.63) .. (-59.19,-102.80)
 .. controls (-61.53,-104.96) and (-63.87,-107.47) .. (-64.77,-105.67)
 .. controls (-65.67,-103.87) and (-64.59,-96.13) .. (-63.69,-95.95)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((63.14,-24.97)
 .. controls (59.34,-24.57) and (52.05,-23.42) .. (49.55,-21.85)
 .. controls (47.01,-20.25) and (47.21,-19.44) .. (45.50,-18.36)
 .. controls (43.79,-17.26) and (44.90,-16.88) .. (45.74,-14.64)
 .. controls (46.58,-12.42) and (44.29,-15.24) .. (42.70,-18.59)
 .. controls (41.08,-22.03) and (40.83,-19.34) .. (39.58,-17.14)
 .. controls (38.36,-14.98) and (40.42,-14.59) .. (38.24,-12.85)
 .. controls (36.12,-11.14) and (35.73,-10.08) .. (34.30,-7.43)
 .. controls (32.87,-4.76) and (31.81,-5.48) .. (31.45,-2.43)
 .. controls (31.09,0.63) and (30.91,0.27) .. (26.77,1.71)
 .. controls (22.63,3.15) and (26.05,2.97) .. (24.79,5.67)
 .. controls (23.53,8.37) and (25.33,13.95) .. (26.59,16.29)
 .. controls (27.85,18.63) and (29.46,18.28) .. (31.63,20.25)
 .. controls (33.79,22.23) and (35.15,24.98) .. (38.11,25.83)
 .. controls (40.64,26.55) and (43.16,26.37) .. (46.03,28.88)
 .. controls (48.91,31.40) and (49.27,31.22) .. (52.87,31.58)
 .. controls (56.41,31.94) and (58.46,30.87) .. (61.16,28.91)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((48.35,32.00),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((33.86,25.55),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((22.97,17.64),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((19.05,3.03),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((29.26,-1.51),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((32.13,-17.79),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((43.75,-23.06),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((53.01,-32.50),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((63.64,-27.65),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((15.83,-28.97),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((11.16,-27.65),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((0.33,-41.85),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-18.98,-43.81),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-21.22,-50.71),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-24.28,-66.45),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-44.58,-82.88),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-51.35,-95.09),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-45.34,-109.96),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-67.72,-83.69),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-71.87,-99.18),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((11.16,-21.92),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((24.88,-13.35),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((1.67,1.56),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-8.38,27.74),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-17.42,33.84),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-14.44,47.87),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-30.06,58.41),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-44.26,81.14),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-56.90,103.02),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-55.02,103.86),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-51.24,98.05),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-39.81,108.92),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-32.10,112.96),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-31.74,118.33),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-26.14,118.72),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-46.18,115.87),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-56.24,118.59),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-60.19,112.84),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-57.71,105.43),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((52.04,33.88),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((69.34,46.92),1,0,"");
endfig;
beginfig(75);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{\hfil#\hfil\cr\thfb\char103 \char46 \ \char100 \char117 \cr\thfb \char83 \char111 \char108 \char105 \char116 \char97 \char105 \char114 \char101 \cr}}\mainfont{} etex,(-42.52,42.90),0.0,p_label_mode_label);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.ulft(btex \thaltitude \thfb\char50 \char49 \mainfont{} etex,(-25.96,119.84),0.0,p_label_mode_altitude);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char99 \char111 \char108 \char109 \char46 \mainfont{} etex,(-16.87,109.58),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char50 \char46 \char53 \mainfont{} etex,(-75.01,110.12),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char99 \char111 \char108 \char109 \char46 \mainfont{} etex,(22.25,-11.64),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{#\hfil\cr\thfb\char80 \char117 \char105 \char116 \char115 \cr\thfb \char65 \char108 \char97 \char105 \char110 \cr}}\mainfont{} etex,(79.98,37.22),0.0,p_label_mode_label);
endfig;
background:=(0.00000,0.00000,0.20000,0.00000);
current_scrap := "SP-Solitaire2020-2";
ATTR__scrap := "SP-Solitaire2020-2";
beginfig(76);
current_src := "th2/solitaire-plan2020.th2 [540]";
string area_border[];
area_border[1] := "l115-711-2179";
drawoptions();
a_blocks(buildcycle(((0.49,43.61)
 .. controls (0.49,43.61) and (-3.92,42.44) .. (-4.01,33.98)
 .. controls (-4.10,25.52) and (-2.31,19.94) .. (-2.31,16.88)
 .. controls (-2.30,13.82) and (-0.41,8.69) .. (-2.93,5.28)
 .. controls (-5.44,1.86) and (2.83,-9.66) .. (4.35,-9.48)
 .. controls (5.88,-9.30) and (13.82,-3.10) .. (10.12,0.60)
 .. controls (6.43,4.29) and (12.19,28.39) .. (10.75,31.27)
 .. controls (9.31,34.16) and (0.49,43.61) .. cycle
)));
ATTR__height := -1;
drawoptions();
l_pit(((-2.57,12.47)
 .. controls (-2.57,12.47) and (-1.04,10.94) .. (-3.11,8.06)
));
ATTR__height := -1;
drawoptions();
l_pit(((6.16,29.47)
 .. controls (6.16,29.47) and (2.01,25.43) .. (-1.67,27.23)
));
ATTR__height := -1;
drawoptions();
l_pit(((7.41,25.60)
 .. controls (7.41,25.60) and (4.26,23.63) .. (-0.50,24.53)
));
ATTR__height := -1;
drawoptions();
l_pit(((-7.61,38.85)
 .. controls (-7.61,38.85) and (-3.02,38.31) .. (-5.36,34.26)
));
ATTR__height := -1;
drawoptions();
l_pit(((3.18,-30.74)
 .. controls (3.18,-30.74) and (4.88,-25.70) .. (-0.61,-26.24)
));
endfig;
beginfig(77);
draw_upscrap(1)(1,((6.52,-37.49)
 .. controls (6.52,-37.49) and (5.62,-36.59) .. (4.00,-35.69)
 .. controls (2.38,-34.79) and (1.75,-35.69) .. (2.19,-33.44)
 .. controls (2.64,-31.19) and (1.38,-29.84) .. (4.53,-29.21)
 .. controls (7.68,-28.58) and (8.67,-28.22) .. (8.58,-27.32)
 .. controls (8.49,-26.42) and (9.03,-24.98) .. (8.04,-23.45)
 .. controls (7.05,-21.91) and (5.07,-20.11) .. (4.62,-18.94)
 .. controls (4.17,-17.77) and (2.82,-15.69) .. (4.08,-15.07)
 .. controls (5.34,-14.44) and (7.77,-13.45) .. (7.86,-12.55)
 .. controls (7.95,-11.65) and (9.84,-8.05) .. (9.31,-6.88)
 .. controls (8.77,-5.71) and (9.22,-3.09) .. (7.78,-2.73)
 .. controls (6.34,-2.37) and (6.52,-1.65) .. (5.35,1.23)
 .. controls (4.18,4.11) and (3.73,10.50) .. (4.26,12.29)
 .. controls (4.80,14.09) and (5.88,15.80) .. (7.23,17.15)
 .. controls (8.58,18.50) and (8.40,20.21) .. (7.23,22.91)
 .. controls (6.06,25.60) and (4.98,27.76) .. (5.17,29.92)
 .. controls (5.35,32.08) and (6.25,34.24) .. (5.71,35.96)
 .. controls (5.17,37.67) and (4.09,40.10) .. (2.65,40.46)
 .. controls (1.21,40.82) and (1.12,42.53) .. (-1.31,41.81)
 .. controls (-3.74,41.09) and (-3.11,41.45) .. (-5.09,39.66)
 .. controls (-7.07,37.86) and (-7.52,37.23) .. (-8.60,36.96)
 .. controls (-9.68,36.69) and (-10.76,36.51) .. (-10.76,36.51)
),
1,((-9.32,34.89)
 .. controls (-9.32,34.89) and (-7.34,36.06) .. (-5.45,35.88)
 .. controls (-3.56,35.70) and (-1.67,35.96) .. (-2.21,34.52)
 .. controls (-2.75,33.08) and (-3.65,33.44) .. (-2.75,31.46)
 .. controls (-1.85,29.48) and (1.03,29.75) .. (0.58,27.50)
 .. controls (0.13,25.25) and (2.46,25.97) .. (0.75,20.66)
 .. controls (-0.96,15.35) and (-1.67,14.45) .. (-2.03,11.48)
),
1,((-2.03,11.48)
 .. controls (-2.03,11.48) and (-2.93,11.30) .. (-3.74,11.48)
),
1,((-4.55,8.96)
 .. controls (-4.55,8.96) and (-2.57,9.05) .. (-2.48,8.51)
),
1,((-2.48,8.51)
 .. controls (-2.84,5.55) and (-2.84,5.82) .. (-1.76,3.03)
 .. controls (-0.68,0.24) and (2.93,-5.07) .. (4.09,-7.05)
 .. controls (5.26,-9.03) and (6.78,-10.30) .. (4.98,-11.29)
 .. controls (3.18,-12.27) and (3.45,-13.81) .. (2.10,-14.79)
 .. controls (0.75,-15.78) and (-0.33,-15.42) .. (0.39,-17.04)
 .. controls (1.10,-18.66) and (1.46,-18.30) .. (2.82,-19.84)
 .. controls (4.17,-21.37) and (5.34,-23.99) .. (5.70,-24.44)
 .. controls (6.06,-24.89) and (2.18,-25.25) .. (1.01,-25.97)
 .. controls (-0.16,-26.69) and (-0.79,-26.43) .. (-0.60,-27.69)
 .. controls (-0.42,-28.94) and (-0.51,-28.67) .. (-1.23,-29.58)
 .. controls (-1.95,-30.48) and (-1.95,-31.20) .. (-1.95,-32.45)
 .. controls (-1.94,-33.71) and (-3.83,-37.77) .. (-1.76,-40.01)
 .. controls (0.31,-42.26) and (1.75,-43.07) .. (2.47,-43.25)
 .. controls (3.19,-43.43) and (1.84,-40.10) .. (2.92,-40.28)
 .. controls (4.00,-40.46) and (4.00,-40.64) .. (4.00,-40.64)
));
draw_downscrap;
endfig;
beginfig(78);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2.48,8.51)
 .. controls (-2.84,5.55) and (-2.84,5.82) .. (-1.76,3.03)
 .. controls (-0.68,0.24) and (2.93,-5.07) .. (4.09,-7.05)
 .. controls (5.26,-9.03) and (6.78,-10.30) .. (4.98,-11.29)
 .. controls (3.18,-12.27) and (3.45,-13.81) .. (2.10,-14.79)
 .. controls (0.75,-15.78) and (-0.33,-15.42) .. (0.39,-17.04)
 .. controls (1.10,-18.66) and (1.46,-18.30) .. (2.82,-19.84)
 .. controls (4.17,-21.37) and (5.34,-23.99) .. (5.70,-24.44)
 .. controls (6.06,-24.89) and (2.18,-25.25) .. (1.01,-25.97)
 .. controls (-0.16,-26.69) and (-0.79,-26.43) .. (-0.60,-27.69)
 .. controls (-0.42,-28.94) and (-0.51,-28.67) .. (-1.23,-29.58)
 .. controls (-1.95,-30.48) and (-1.95,-31.20) .. (-1.95,-32.45)
 .. controls (-1.94,-33.71) and (-3.83,-37.77) .. (-1.76,-40.01)
 .. controls (0.31,-42.26) and (1.75,-43.07) .. (2.47,-43.25)
 .. controls (3.19,-43.43) and (1.84,-40.10) .. (2.92,-40.28)
 .. controls (4.00,-40.46) and (4.00,-40.64) .. (4.00,-40.64)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2.03,11.48)
 .. controls (-2.03,11.48) and (-2.93,11.30) .. (-3.74,11.48)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.55,8.96)
 .. controls (-4.55,8.96) and (-2.57,9.05) .. (-2.48,8.51)
));
string ATTR_code;
ATTR_code := "E";
string ATTR_cavite;
ATTR_cavite := "JB";
string ATTR_ca;
ATTR_ca := "Courant d'aspirant en Ã©tÃ©";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char83 \char117 \char105 \char116 \char101 \ \char100 \char117 \ \char109 \thfc\char233 \thfb\char97 \char110 \char100 \char114 \char101 \ \thfc\char184 \ \thfb\char97 \char116 \char116 \char101 \char105 \char110 \char100 \char114 \char101 \ \char97 \char112 \char114 \accent18 \char101 \char115 \ \char117 \char110 \char101 \ \char69 \char49 \char48 \ \char102 \char97 \char99 \char105 \char108 \char101 \ \char40 \char97 \char114 \char116 \char105 \char102 \char41 \char44 \ \char99 \char111 \char117 \char114 \char97 \char110 \char116 \ \char100 \char39 \char97 \char105 \char114 \ \char97 \char115 \char112 \char105 \char114 \char97 \char110 \char116 \ \char101 \char110 \ \thfc\char233 \thfb\char116 \thfc\char233 \mainfont{}etex;
drawoptions();
p_continuation((-13.82,36.87),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
save ATTR_cavite;
save ATTR_ca;
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-4.64,43.70)
 .. controls (-4.64,43.70) and (1.03,44.60) .. (2.56,43.34)
 .. controls (4.09,42.08) and (7.51,39.38) .. (7.60,37.13)
 .. controls (7.69,34.88) and (5.98,32.71) .. (6.52,30.19)
 .. controls (7.06,27.67) and (8.04,24.71) .. (8.49,23.81)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-2.05,-26.16)
 .. controls (-2.05,-26.16) and (-3.75,-30.84) .. (-4.37,-33.90)
 .. controls (-5.00,-36.96) and (-4.91,-40.92) .. (-2.66,-42.17)
 .. controls (-0.41,-43.43) and (1.12,-44.60) .. (1.12,-44.60)
));
drawoptions();
p_airdraught_summer((10.66,7.89),360.0,1.00,(0,0));
string ATTR_code;
ATTR_code := "E";
string ATTR_cavite;
ATTR_cavite := "JB";
string ATTR_ca;
ATTR_ca := "?";
picture ATTR__text;
ATTR__text := btex \thcomment \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \char97 \char112 \char114 \accent18 \char101 \char115 \ \char69 \char49 \char53 \ \char63 \mainfont{}etex;
drawoptions();
p_continuation((-8.96,10.50),0.0,1.00,(0,0));
save ATTR__text;
save ATTR_code;
save ATTR_cavite;
save ATTR_ca;
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-9.32,34.89)
 .. controls (-9.32,34.89) and (-7.34,36.06) .. (-5.45,35.88)
 .. controls (-3.56,35.70) and (-1.67,35.96) .. (-2.21,34.52)
 .. controls (-2.75,33.08) and (-3.65,33.44) .. (-2.75,31.46)
 .. controls (-1.85,29.48) and (1.03,29.75) .. (0.58,27.50)
 .. controls (0.13,25.25) and (2.46,25.97) .. (0.75,20.66)
 .. controls (-0.96,15.35) and (-1.67,14.45) .. (-2.03,11.48)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((6.52,-37.49)
 .. controls (6.52,-37.49) and (5.62,-36.59) .. (4.00,-35.69)
 .. controls (2.38,-34.79) and (1.75,-35.69) .. (2.19,-33.44)
 .. controls (2.64,-31.19) and (1.38,-29.84) .. (4.53,-29.21)
 .. controls (7.68,-28.58) and (8.67,-28.22) .. (8.58,-27.32)
 .. controls (8.49,-26.42) and (9.03,-24.98) .. (8.04,-23.45)
 .. controls (7.05,-21.91) and (5.07,-20.11) .. (4.62,-18.94)
 .. controls (4.17,-17.77) and (2.82,-15.69) .. (4.08,-15.07)
 .. controls (5.34,-14.44) and (7.77,-13.45) .. (7.86,-12.55)
 .. controls (7.95,-11.65) and (9.84,-8.05) .. (9.31,-6.88)
 .. controls (8.77,-5.71) and (9.22,-3.09) .. (7.78,-2.73)
 .. controls (6.34,-2.37) and (6.52,-1.65) .. (5.35,1.23)
 .. controls (4.18,4.11) and (3.73,10.50) .. (4.26,12.29)
 .. controls (4.80,14.09) and (5.88,15.80) .. (7.23,17.15)
 .. controls (8.58,18.50) and (8.40,20.21) .. (7.23,22.91)
 .. controls (6.06,25.60) and (4.98,27.76) .. (5.17,29.92)
 .. controls (5.35,32.08) and (6.25,34.24) .. (5.71,35.96)
 .. controls (5.17,37.67) and (4.09,40.10) .. (2.65,40.46)
 .. controls (1.21,40.82) and (1.12,42.53) .. (-1.31,41.81)
 .. controls (-3.74,41.09) and (-3.11,41.45) .. (-5.09,39.66)
 .. controls (-7.07,37.86) and (-7.52,37.23) .. (-8.60,36.96)
 .. controls (-9.68,36.69) and (-10.76,36.51) .. (-10.76,36.51)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-0.55,-33.04),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((1.76,-26.12),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((8.23,-26.34),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((1.85,-17.17),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((8.71,-9.38),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((4.28,-5.83),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((1.51,20.89),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((1.64,35.40),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((2.91,39.88),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-8.79,35.79),1,0,"");
endfig;
beginfig(79);
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char53 \mainfont{} etex,(11.20,28.03),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char49 \char48 \mainfont{} etex,(-9.41,42.71),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char49 \char53 \mainfont{} etex,(-7.51,4.38),0.0,p_label_mode_height);
drawoptions();
p_label(btex \thheight \thheightpos \thfb\char50 \mainfont{} etex,(-4.66,-23.72),0.0,p_label_mode_height);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.llft(btex \thaltitude \thfb\char50 \char57 \mainfont{} etex,(-9.32,34.89),0.0,p_label_mode_altitude);
endfig;
beginfig(80);
s_northarrow(0);
endfig;
beginfig(81);
s_scalebar(100, 1, "\thfb\char109 \mainfont{}");
endfig;
Scale:=10.00;
initialize(Scale);
background:=(0.00000,0.00000,0.20000,0.00000);
transparency:=false;
end;
