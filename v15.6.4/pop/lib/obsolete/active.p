/*  --- Copyright University of Sussex 1996.  All rights reserved. ---------
 >  File:           C.all/lib/obsolete/active.p
 >  Purpose:        turtle program to drive a VDU screen (vt-52 or v200)
 >  Author:         Steven Hardy (originally), July 1980 (see revisions)
 >  Documentation:  HELP * ACTIVE
 >  Related Files:	LIB * V200GRAPH
 */

;;; NB "uses active" can't be used to load this because "active" is now
;;; a syntax word - Sept 1986

;;; A space between the bottom of
;;; the picture and the bottom of the screen is reserved for commands,
;;; and scrolling is handled by the program instead of the terminal.
;;; For this purpose make the picture not more than about 15 high.
;;; Scrolling is defeated by
;;; local 'wrap-around', if lines of more than 79 characters are typed.
;;; Setpop will redraw picture (e.g. ^X)

;;; The function cursor(x,y) shows the cursor at (x,y)
;;; function move(n) moves the cursor continuously n steps

section;

vars Vpoint;
unless isprocedure(Vpoint) then
	popval([lib v200graph;])     ;;; get functions to drive Visual 200
endunless;

uses turtle;

;;; Picture bounds: set in display and newpicture
vars Xsize Ysize;

define procedure Outpt(x,y);
	lvars x,y;
	;;; Like Vpoint in /usr/lib/v200.p, but uses turtle coords, not screen co-ords.
	Vpoint(x,Ysize-y)
enddefine;

define procedure Outchar(p);
	;;;make sure only a character is output, corresponding to p
	lvars p;
	rawcharout(
	if  isword(p) then  subscrw(1,p)
	elseif  isinteger(p) and 0 fi_<= p and p fi_<= 9 then `0` fi_+ p
	else `?`
	endif)
enddefine;


vars activesetpop;
define sysdisplay();
	lvars x, y, p;
	define prmishap();
		rawoutflush();
		sysprmishap(); exitfrom(activesetpop);
	enddefine;
	sysflush(popdevout);     ;;; flush charout buffer
	true -> Displayed;
	pdprops(picture)(3) + 1 -> Xsize;
	pdprops(picture)(5) ->> Ysize->Scrolrow;
	;;; clear the picture area
	fast_for y from 0 to Ysize do Vcl(y) endfast_for;
	for Ysize->y step y fi_- 1->y till y==0 do
		for 1->x step x fi_+ 1->x till x==Xsize do
			picture(x, y) -> p;
			unless  p == space then
				Outpt(x,y);
				Outchar(p);
			endunless
		endfor
	endfor;
	Scroll();
	rawoutflush();
enddefine;
vars display; sysdisplay -> display;


define Active(p, x, y, f);
	;;; f is the updater of picture, p the new contents for picture(x,y)
	lvars p,x,y,f;
	pdprops(picture)(3) -> Xsize;
	pdprops(picture)(5) ->> Ysize->Scrolrow;
	f(p, x, y);
	Outpt(x,y);
	Outchar(p);
	true -> Displayed;
enddefine;

vars NEWPICTURE;
unless NEWPICTURE.isprocedure then  newpicture -> NEWPICTURE endunless;

;;; some functions for 'movies' made with the cursor

vars cursorcount;
1 -> cursorcount;
	;;; make this bigger to slow down move

define procedure cursor(x,y);
	;;; Show the cursor at picture location x,y
	lvars x,y;
	repeat cursorcount times Outpt(x,y) endrepeat;
	true -> Displayed;
enddefine;

define move(x);
	;;; for dynamic display with cursor
	lvars x;
	cursor(xposition,yposition);
	repeat x times
		jump(1); cursor(xposition,yposition)
	endrepeat;
enddefine;

define newpicture(x, y);
	lvars x,y;
	NEWPICTURE(x, y);
	Active(%updater(picture)%) -> updater(picture);
	x ->Xsize;
	y ->>Ysize->Scrolrow;
	sysdisplay();
enddefine;

procedure; vars sysdisplay; identfn -> sysdisplay;
	newpicture(50,15);
endprocedure.apply;


define activesetpop;
	vars interrupt;
	setpop -> interrupt;
	Vout -> cucharout;
	define prmishap;
		vars cucharout;
		charout -> cucharout;
		Scroll();
		rawoutflush();
		sysprmishap();
		pr('\n\nTYPE CTRL-C to CONTINUE'); charin();
	enddefine;
	sysdisplay();
	;;; prevent charout messing up format.
	100000000 ->> poplinewidth  -> poplinemax;
	pop11_compile(Vin);
enddefine;

activesetpop -> popsetpop;

define 1 startactive;
	activesetpop -> popsetpop;
	Scroll();
	popsetpop();
enddefine;

define 1 endactive;
	identfn -> popsetpop;
	if cucharin = Vin then exitfrom(pop11_compile) endif;
enddefine;

vars macro activemode;
[;vars cucharin cucharout proglist;
  Vin -> cucharin;
  Vout -> cucharout;
  pdtolist(incharitem(cucharin)) -> proglist;] -> nonmac activemode;

pr('DO CTRL-C or \'ACTIVE;\' TO SET UP ACTIVE TURTLE');

endsection;

nil -> proglist;

/*  --- Revision History ---------------------------------------------------
--- John Williams, Jan  3 1996
		Moved from C.all/lib/turtle to C.all/lib/obsolete.
		Also included the help file below this revision history.
--- Aaron Sloman, Nov 21 1986
	Changed "active" to "startactive" and updated help file.
--- Aaron Sloman, Aug 19 1986
	Some tidying up. replaced spaces with tabs.
--- Roger Evans, June 1983 - addition of macro ACTIVEMODE plus renaming of
	display procedure as sysdisplay - the default value of display (but can
	set display to identfn for better compatibility with turtle). Note -
	activesetpop calls sysdisplay not display!
--- Aaron Sloman, 1982 - modified to use v200graph properly.
 */

/*
HELP ACTIVE                                            R.Evans June 1983
											   Updated A.Sloman Nov 1986

Lib ACTIVE enhances lib TURTLE by providing an 'active' turtle picture
on the screen which is updated whenever a turtle command is given. It
leaves an area below the picture to use for commands. This area is
scrolled automatically.

For details of LIB TURTLE, see TEACH *TURTLE. HELP *TURTLE gives a very
brief summary of available commands.

   [N.B The "active" operator has been re-named as "startactive" to
   prevent a clash with the new syntax word "active" used in defining
   active variables.
   For information on "active" variables, see HELP * ACTIVE_VARIABLES ]

ACTIVE makes use of LIB * V200GRAPH, which works on VT-52/VISUAL 200
terminals only. To make LIB ACTIVE work on another terminal, copy
V200GRAPH.P (using <ENTER> SHOWLIB v200graph), then redefine the
facilities to work on the terminal. Alternatively, use  VTURTLE,
which works within VED to provide similar, though less efficient,
facilities. See HELP * VTURTLE, LIB * VTURTLE

LIB ACTIVE
divides the screen into two parts - the picture in the upper portion and
a normal scrolling window (like the whole screen is normally) in the
lower portion. The size of the portions depends on the size of the
turtle picture - which shouldn't be larger than 79 by 22 and to be
comfortable, not larger than 79 by about 18.

To load the library type

	lib active

and as it loads you will get the messages:

	;;; LOADING LIB v200graph

	DO CTRL-C or 'ACTIVE;' TO SET UP ACTIVE TURTLE

(also, if you're not in ved, the prompt ':' will be at the end of the latter
message, not on the next line as usual)

Typing CTRL-C will put you into ACTIVE mode (ie split the screen into two
halves), but that's not the recommended way - it's better to do

	startactive;

You probably won't see any difference at first, but hit <RETURN> a few
times and you will see that the text disappears half way up the screen,
rather than off the top as usual. Give a turtle command like

	drawto(5,5);

and drawing will happen immediately on the top half of your screen. (You
don't have to do display(); as you do in turtle).

To get out of ACTIVE mode type

	endactive;

Again, you probably won't see any difference, but if you hit <RETURN>
the whole screen will scroll up, not just the lower half - it's gone
back to normal.

If you're in ACTIVE mode and you get a mishap, a new message appears at
the end of the mishap message:

	TYPE CTRL-C TO CONTINUE:

It is wisest to do as it says - type CTRL-C - even though it sometimes
works properly even if you don't.


In ACTIVE mode, you can use all the turtle commands exactly as you would
using lib TURTLE, except, of course, that you won't have to keep typing
display(); all the time to see what's happening.


USING ACTIVE MODE IN PROGRAMS
-----------------------------

	It is often nice to use ACTIVE mode in a program - for example for
the display of a game etc. As the library stands there can be a few
problems:

1) the library tries to put you into ACTIVE mode straightaway. In a
   program this isn't usually what you want - you want to be in ordinary
   mode until (and after) you run your 'main' procedure.
2) Using lib turtle is useful for doing write-ups etc since you can print
   out the result (you can't with ACTIVE). But turtle needs all those
   display(); calls which slow down ACTIVE a lot since it refreshes the
   WHOLE picture every time!

So here is how to cope with all this! In your main program file, near the
top you probably have the command

	lib turtle

(or "uses turtle" - which would be better).

To use lib active, insert the following commands AFTER the 'lib turtle' line

	loadlib("active");
	identfn -> popsetpop;
	identfn -> display;

The first loads lib active, the second stops it trying to go into active
mode straight away and the third stops display from getting in the way.

NB It is no longer possible to load lib active with the command
	uses active;

This is because "active" is now a syntax word, used in defining active
variables.

	Doing all that won't actually put you into active mode. To do that
you can type 'active' and 'endactive' before you run your program, but a
neater way is provided by the macro ACTIVEMODE. All you have to do is
insert

	activemode;

in your main procedure up at the top (ie with your VARS statements etc.)
For example, suppose your main procedure is called GO, then it might
look like this:

	define go();
		vars foo baz;
		activemode;
		...
		...
	enddefine;


Typing

	go();

in this form is about the same as typing

	active;
	go();
	endactive;

for the old version of GO (without the activemode in it), but it's
tidier, and you don't have to remember the 'endactive' afterwards.

-----<Copyright University of Sussex 1986.  All rights reserved.>-------
*/
