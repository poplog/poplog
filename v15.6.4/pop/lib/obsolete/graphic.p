/*  --- Copyright University of Sussex 1995.  All rights reserved. ---------
 >  File:           C.all/lib/obsolete/graphic.p
 >  Purpose:        collection of procedures for driving TEKTRONIX 4012
 >  Author:         Aaron Sloman, Nov 1977 (see revisions)
 >  Documentation:  DOC TEKTRONIX
 >  Related Files:  LIB * GINREAD
 */
#_TERMIN_IF DEF POPC_COMPILING

;;; --------------------------------------------------------------------------
;;; WARNING: This program is liable to be removed or substatially altered in
;;; future version of POPLOG.  If you find a use for it then you are advised
;;; to make a private copy.
;;; ---------------------------------------------------------------------------
pr('WARNING: PLEASE READ WARNING NOTICE IN SHOWLIB GRAPHIC.P\n');

;;;     NB NOT YET DEBUGGED FOR VAX POP11 see also GINREAD.P
;;; Clipping routines by Frank O'Gorman.
;;; See also /pop/usr/lib/graphops.p /pop/usr/lib/ginread.p
;;; A collection of procedures for driving TEKTRONIX 4012,
;;; which may be linked to a VDU via a switching unit.

vars xposition; ;;;     A number representing the x - position of the turtle
vars yposition;
0 -> xposition; 0 -> yposition;
vars heading;   ;;;     The angle the turtle would have to turn, in a clockwise direction,
				;;;     to be facing along the x - axis, to the right.
0 ->heading;

define Newposition(amount) -> newx newy;
	(xposition + amount * cos(heading)) -> newx;
	(yposition + amount * sin(heading)) -> newy;
enddefine;

define jump(amount);
	Newposition(amount) -> yposition -> xposition;
enddefine;

define jumpto(newx, newy);
	newx -> xposition;
	newy -> yposition;
enddefine;

define jumpby(dx, dy);
	xposition + dx -> xposition;
	yposition + dy -> yposition;
enddefine;


define turn(angle);
	heading + angle -> heading;
	while heading >= 360 then heading - 360 -> heading endwhile;
	while heading < 0 then heading + 360 -> heading endwhile;
enddefine;


vars procedure(conspoint, destpoint);       ;;; user definable
conspair ->conspoint;
destpair ->destpoint;


vars procedure outascii;
rawcharout -> outascii;

vars procedure inascii;
rawcharin ->inascii;



;;; when the character designated "scopecode" is output, this switches the
;;; switching unit so that all output thereafter goes to the graphics unit.
;;; similarly, outputting the value of "vducode" switches output thereafter to the
;;; vdu (or tty etc).



;;; jumpto and drawto take either two numbers or a point data-structure.
;;; it is assumed that points have destructor called "destpoint".


;;;the functions echo and noecho are for turning echoing on and off.
;;;e.g. the computer should not echo characters while the 4012 is in gin mode or graphic mode.

vars inechomode; true ->inechomode;

define echo;
	unless inechomode then
		sysobey('set term/echo');
		true -> inechomode
	endunless;
enddefine;

define noecho;
	if inechomode then
		sysobey('set term/noecho');
		false ->inechomode
	endif
enddefine;


;;; all printing goes through goutascii, gcharout, user definable.

;;; subfile: variables - 26 7 1977

vars ginascii goutascii gcharout;
inascii ->ginascii;
outascii ->goutascii;
charout ->gcharout;

define clrinputbuff;
	;;; clear input buffer. may need to be redefined.
	sys_clear_input(poprawdevin);
	sys_clear_input(popdevin);
	inascii ->ginascii;                             ;;; is this needed
enddefine;

vars vducode scopecode;

;;; now assign switching codes. reverse if required.
;;;2->vducode;  3->scopecode;  ;;; these values for CADC switching unit
unless isinteger(vducode) then 0 -> vducode endunless;
unless isinteger(scopecode) then 0 -> scopecode endunless;

;;; now some variables representing the state of the program.
;;; when inscopemode is true it is assumed that everything is transmitted to 4012,
;;; otherwise to vdu.
;;; ingraphmode, inginmode and inalphamode record state of 4012.
;;; graphx and graphy record screen co-ordinates last transmitted while
;;; scope in graphic mode.
;;; alphax and alphay are available to record position of alphanumeric cursor
;;; on 4012. however, they are not used at present, except that
;;; greset gives them values corresponding to top left of screen.

vars ingraphmode inscopemode inginmode inalphamode graphx graphy alphay alphax;


0->graphx;
0->graphy;
false->inscopemode;
false->ingraphmode;


;;; the next three variables remember character codes transmitted to
;;; the 4012. this enables the function gptout to make use of the internal memory
;;; of the 4012 and sometimes avoid transmitting all four characters corresponding
;;; to a pair of screen co-ordinates. (see 4012 reference manual for details).

vars lastyhi lastylo lastxhi;


;;; the next three operations are used for translating between numerical
;;; co-ordinates and the codes used by the 4012, in function gptout.


define 5 x addkey y;
	;;; take a five bit number and add a two bit key for bits 6 and 7.
	;;; assume x contains five bits to be used and y
	;;;  contains two bits for positions 7 and 6.
	||(&&(x,8:37), y<<5)
enddefine;

;;; now two user-definable functions for transforming co-ordinates from user's
;;; framework to screen co-ordinates and back.
;;; gtransxyout takes user co-ordinates and produces screen co-ordinates.
;;; gtransxyin takes screen co-ordinates and produces user co-ordinates.
;;; both can be given value identfn to have no effect.

vars gtransxyout gtransxyin;            ;;; Defined below.


;;; subfile: gptout - 29 3 1977


;;; procedures for clipping output to tektronix 4012.


vars clipping;          ;;; used in gptout
true ->clipping;

define gxyout x y;
	;;; this function transmits a "point" to the 4012, in the form of up to four
	;;; character codes.
	;;; gxyout uses the memory in the 4012 to avoid transmitting all four
	;;;  character codes if possible.

	vars  xlobits xhibits ylobits yhibits;

	y>>5 addkey 1        ->yhibits;
	y addkey 3            ->ylobits;
	x>>5 addkey 1        ->xhibits;
	x addkey 2            ->xlobits;

	unless yhibits=lastyhi then
		yhibits.goutascii; yhibits->lastyhi
	endunless;

	unless ylobits=lastylo and xhibits=lastxhi then
		ylobits.goutascii; ylobits->lastylo;
	endunless;

	unless xhibits=lastxhi then
		xhibits.goutascii; xhibits->lastxhi;
	endunless;

	xlobits.goutascii;             ;;;this code must always be transmitted.
	.rawoutflush;  ;;; flush output
enddefine;


vars setgraphic;        ;;; defined below
vars lastx lasty;
0 -> lastx; 0 -> lasty;


vars outofbounds; false ->outofbounds;

vars gxmin gxmax gymin gymax;

0 ->gxmin; 1023 ->gxmax;
0 ->gymin; 1023 ->gymax;

define gptout y jumping;
	vars x x1 y1 x2 y2  p1out p2out bothout;
	;;; y may be either a point data structure, in which case it
	;;; is assumed that a function destpoint will decompose it,
	;;; or a number, in which case it is assumed that the other
	;;; co-ordinate is on the stack.
	if y.isnumber.not then y.destpoint -> y -> x; else -> x endif;
	x -> graphx; y -> graphy;
	gtransxyout(x,y) -> y -> x;             ;;; for scale change, etc. user definable.
	lastx -> x1; lasty -> y1; x -> x2; y -> y2;

	;;; x1 y1 are co-ordinates of starting point, p1, x2 y2 of target point p2.
	;;; now a function to find if either point is beyond the boundary, and
	;;; if so to replace either p1 or p2 with a point on the boundary.

	define gclip x1 y1 x2 y2 xl pred -> x1 y1 x2 y2;
		;;; pred is either > or < . xl is the co-ordinate of the boundary.
		;;; this function can also be used with x and y co-ordinates interchanged.
		pred(x1,xl) -> p1out;         ;;; first point out of bounds.
		pred(x2,xl) -> p2out;         ;;; target point out of bounds.
		if p2out then
			true ->outofbounds;
			if jumping then true ->p1out endif
		endif;

		if p1out and p2out then
			true ->bothout; x.round ->lastx; y.round ->lasty
		elseif p1out or p2out then
			;;; find coordinates of intersection point.
			xl,
			y2 - (y2 - y1 + 0.0)*(x2-xl)/(x2 - x1);         ;;; 0.0 forces use of real numbers
			;;; assign them to initial or final point:
			if p1out then   ->y1 ->x1
			else            ->y2 ->x2
			endif;
		endif
	enddefine;

	if clipping then
		false ->outofbounds;
		false ->bothout;
		;;; test if line crosses x=gxmin boundary.
		gclip(x1,y1,x2,y2, gxmin, nonop <) ->y2 ->x2 ->y1 ->x1;
		if bothout then return; endif;

		;;; test if line crosses x=gxmax boundary.
		gclip(x1,y1,x2,y2, gxmax, nonop >) ->y2 ->x2 ->y1 ->x1;
		if bothout then return; endif;

		;;; now do tests for y=gymin and y=gymax

		gclip(y1,x1,y2,x2, gymin, nonop <) ->x2 ->y2 ->x1 ->y1;
		if bothout then return; endif;

		gclip(y1,x1,y2,x2, gymax, nonop >) ->x2 ->y2 ->x1 ->y1;
		if bothout then return; endif;

		;;; prepare to draw line or jump.
		x1.round -> x1; y1.round -> y1;
		unless jumping or (x1=lastx and y1=lasty)
		then setgraphic();  gxyout(x1,y1)
		endunless
	endif;

	x2.round -> x2; y2.round -> y2;
	gxyout(x2,y2);
	x.round -> lastx; y.round -> lasty
enddefine;

;;; subfile: setstate - 29 3 1977


vars gcucharout;                ;;; defined below.

define setscope;
	;;; prepare to transmit to 4012.
	unless inscopemode then
		scopecode.goutascii; true->inscopemode;
		rawoutflush();
	endunless
enddefine;

define setnullstatus;
	;;;used by functions which alter status of 4012, before they record the change.
	false->inalphamode; false->inginmode; false->ingraphmode;
enddefine;


define setgraphic;
	;;; set scope ready to receive graphics instructions.
	.setscope;             ;;;alter switching unit.
	.setnullstatus;
	true ->ingraphmode;    ;;;record new status.
	goutascii(29);         ;;;switch 4012 to graphic mode.
	rawoutflush();
enddefine;

define setgin;
	;;; set 4012 into "gin" mode. i.e. get "cross" on screen.
	;;; then if a key is typed, 4012 will transmit the character followed
	;;; four characters representing cross co-ordinates, then cr and lf.
	.setscope;
	;;; .clrinputbuff;                      ;;; clear the input buffer.
	.setnullstatus; true ->inginmode;
	.noecho;
	goutascii(27); goutascii(26);  ;;;set 4012 into gin mode.
	rawoutflush();
enddefine;


define setalpha;
	;;; set 4012 into alphanumeric mode, e.g. for printing characters.
	unless inscopemode then .setscope endunless;
	.echo;
	goutascii(31); rawoutflush();
	.setnullstatus;  true->inalphamode;
enddefine;



define setvdu;
	if inscopemode then
		.setalpha;           ;;;set scope to alpha, so that it can darken screen.
		vducode.goutascii;   ;;;set switching unit to vdu.
		rawoutflush();
		gcucharout ->cucharout;
	endif;
	false ->inscopemode;
enddefine;

vars athome;    ;;;true immediately after greset.

define greset;
	;;;used to clear screen on scope and reset it to alpha status.
	.setscope;
	goutascii(27); goutascii(12);  ;;;transmit reset code.
	rawoutflush(); ;;; flush output
	syssleep(200);
	;;;now pause to give scope time to settle down.
	true->athome;
	;;;record alphanumeric cursor co-ordinates.
	0->alphax;767 ->alphay;
	.setalpha;
enddefine;


;;;the next two functions may be useful someday
;;;function genquire;
;;;;;; ask the 4012 about its status and read the reply.
;;; ;;; see tektronix manual for details.
;;; .setscope;
;;; .clrinputbuff;
;;;  goutascii(27); goutascii(5);
;;;  status(.ginascii);
;;;  gincoords(.ginascii,.ginascii,.ginascii.ginascii);
;;;  .clrinputbuff;
;;;enddefine;
;;;
;;;function status  char;
;;; ;;;interpret the character received by genquire.
;;; &&(char>>3,1) ->settodraw;
;;; &&(char>>2,1).not ->ingraphmode;
;;; &&(char>>1,1) -> atmargin1;
;;;enddefine;



define gnumof xhibits xlobits;
	;;;interpret two characters received from 4012 as representing a 10 bit number.
	||(&&(xhibits,8:37)<<5, &&(xlobits,8:37))
enddefine;

cancel addkey;

define gincoords xhibits xlobits yhibits ylobits;
	;;; takes four character codes transmitted by 4012, and translates them
	;;; into two numbers representing x and y coords on screen.
	;;;finally gtransxyin translates them from screen co-ords to user co-ords.
	gtransxyin(gnumof(xhibits,xlobits), gnumof(yhibits,ylobits))
enddefine;

define getgin;
	;;; returns character typed on scope and x and y coordinates of cross.
	.setgin;      ;;;set 4012 in gin mode. expect "cross" info back.
	;;;now read in character typed, & 4 character position codes.
	.ginascii.ginascii.ginascii.ginascii.ginascii;
	.clrinputbuff;      ;;;disregard everything else.
	.gincoords;   ;;;uses four last characters read in.
enddefine;

;;; subfile: turtle - 26 7 1977


vars xturt yturt;

define gsetturt;
	;;; coordinate the turtle record with what's happened to the scope.
	graphx ->xposition; graphy ->yposition;
enddefine;

define jumpto;
	;;;takes either a point or two numbers as arguments.
	.setgraphic;
	.gsetturt;
	gptout(true);
	gsetturt();
enddefine;

define drawto;
	;;; argument may be a point or two numbers.
	unless ingraphmode then
		jumpto(graphx,graphy);
	endunless;
	gptout(false);
	gsetturt()
enddefine;



define draw steps;
	.gsetturt;
	Newposition(steps) -> yposition ->xposition;
	drawto(xposition,yposition);
	.gsetturt;
enddefine;

define jump steps;
	.gsetturt;
	Newposition(steps) ->yposition ->xposition;
	jumpto(xposition,yposition);
enddefine;

;;; subfile: printing - 26 7 1977


define gprintlength wd;
	;;; calculates number of characters needed to print a word, string or integer.
	vars n;
	define cucharout x; n+1 ->n enddefine;
	0 ->n;
	if wd.isstring then pr(wd) else pr(wd) endif;
	n
enddefine;


define gprintat wd;
	;;; takes a point, or two numbers, and something to print at the location specified.
	;;; in case cucharout has been redefined, reset it.
	vars cucharout; gcharout ->cucharout;
	jumpto();
	setalpha();
	if wd.isstring then wd.pr else wd.pr endif;
	graphy ->alphay;
	graphx + 14*gprintlength(wd) ->alphax;
enddefine;



;;; to enable scope and vdu to be used easily use gcucharin, defined below,
;;; as input character repeater. it assumes that whenever input is requested
;;; through it, the vdu will be used, so it switches to vdu.
;;; if you want echoing to occur on 4012 while reading in, then temporarily
;;; compile charin.


define gcucharin;
	if inscopemode then
		.rawoutflush;
		.setvdu;
	endif;
	.charin
enddefine;

define gcucharout x;
	if inscopemode then .setvdu endif;
	x.gcharout;
enddefine;


;;; subfile: graphic - 30 10 1977

define 2 graphic;
	define interrupt;
		.setvdu;
		exitto(nonop graphic);
	enddefine;

	define prmishap;
		.setvdu;
		.sysprmishap;
	enddefine;
	false -> pdprops(prmishap);

l:
	procedure;
		'setgraphic'.pr;pr(newline);
		.clrinputbuff;
		pop11_compile(gcucharin);
		.setpop;
	endprocedure.apply;
	goto l
enddefine;



;;; a collection of facilities for transforming user-coordinates to screen
;;; co-ordinates, when using the graphics package.

;;; first two variables to determine scale change in horizontal and vertical
;;; directions. user co-ordinates will be multiplied by these factors to produce
;;; screen co-ordinates. if both xscale and yscale are set at 10, then the
;;; screen is 102 units wide and 79 units high, approximately.

vars gxscale gyscale;

;;; two coordinates representing position on screen of origin of user's frame.
;;; setting them to 500 and 395 puts origin in centre of screen.
;;; please try to vary these to minimise uneven wear on the scope.

vars gxorigin gyorigin;

;;; now two functions for transforming between user co-ordinates and screen
;;; co-ordinates. these are used in functions gptout and gincoords.

define gtransxyin x y;
	(x - gxorigin)/gxscale, (y - gyorigin)/gyscale
enddefine;

define gtransxyout x y;
	if gxscale == 1 then x else x * gxscale endif + gxorigin,
	if gyscale == 1 then y else y * gyscale endif + gyorigin,
enddefine;


;;; these can be redefined by the user for more complex transformations, e.g. for
;;; rotations.


;;; give default settings for the variables, unless the user has already assigned
;;; numbers to them.

unless gxorigin.isnumber then 495->gxorigin endunless;
unless gyorigin.isnumber then 385->gyorigin endunless;
unless gxscale.isnumber  then 1->gxscale endunless;
unless gyscale.isnumber  then 1->gyscale endunless;


;;; some procedures for manipulating the frame. the names should explain.

define gmirrorx;
	- gxscale ->gxscale;
enddefine;

define gmirrory;
	- gyscale ->gyscale;
enddefine;

define gstretchx n;
	n * gxscale -> gxscale;
enddefine;

define gstretchy n;
	n * gyscale -> gyscale;
enddefine;

define gstretch n;
	gstretchx(n); gstretchy(n);
enddefine;

define gshiftby x y;
	;;; move the users frame by x, y in screen coordinates.
	gxorigin + x -> gxorigin;
	gyorigin + y -> gyorigin;
enddefine;

define gshiftr x;
	;;; move user's origin by x user units, to the right.
	gxorigin + x * abs(gxscale) ->gxorigin
enddefine;

define gshiftup y;
	;;; move user's origin by y user units, upwards.
	gyorigin + y * abs(gyscale) -> gyorigin
enddefine;

jumpto(0,0);
setvdu();

vars usingpoly;
unless usingpoly = true then
	'Type \n        : graphic;\n'.pr;
endunless;

define turtle();
	greset();
	jumpto(0,0);
	0 -> heading;
	setvdu();
enddefine;


/* --- Revision History ---------------------------------------------------
--- Robert John Duncan, May 22 1995
		Moved to obsolete lib
--- John Gibson, Nov 11 1987
		Replaced -popdevraw- with -poprawdevin- and -poprawdevout-,
		and -sys_purge_terminal- with -sys_clear_input-
 */
