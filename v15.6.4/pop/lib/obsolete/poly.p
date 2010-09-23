/*  --- Copyright University of Sussex 1995.  All rights reserved. ---------
 >  File:           C.all/lib/obsolete/poly.p
 >  Purpose:        draw pretty pictures on a TECTRONIX terminal
 >  Author:         Aaron Sloman, 1977 (see revisions)
 >  Documentation:  DOC * TEKTRONIX
 >  Related Files:  LIB * GINREAD  LIB * GRAPHIC
 */
#_TERMIN_IF DEF POPC_COMPILING

;;; --------------------------------------------------------------------------
;;; WARNING: This program is liable to be removed or substatially altered in
;;; future version of POPLOG.  If you find a use for it then you are advised
;;; to make a private copy.
;;; ---------------------------------------------------------------------------
pr('WARNING: PLEASE READ WARNING NOTICE IN SHOWLIB POLY.P\n');

;;;     / p o p / u s r / l i b / p o l y . p
;;;     aaron sloman    dec 1977
;;;     the main thing is the operation poly, which uses function
;;;     polyspi to draw pretty pictures.

vars usingpoly; true ->usingpoly;
		;;; controls printing when lib graphic is compiled.

;;;     set origin to be near centre of screen, but not exactly the same point
;;;     each time, to reduce wear on screen:


vars gxyout;
unless isprocedure(gxyout) then popval([lib graphic;]) endunless;

512 + random(20) - random(20) ->gxorigin;
390 + random(15) - random(15) -> gyorigin;


1 ->gxscale;
1 ->gyscale;
'origin at centre of screen. scales set to 1\
'.pr;


define polyspi side inc ang num;
	;;; draw a polygonal spiral. initial arm length is side. inc is added at each turn.
	;;; the angle turned (to left) is ang (in degrees). num is the total number of sides.
	;;; see also operation poly below.
	;;; in case globals are not right after an interrupt do two jumps
	jumpto(500,500);
	jumpto(0,0); 45 ->heading;
	;;; move to a location and heading which will cause the centre of the spiral to
	;;; be near centre of screen (very approximate).
	;;; but first normalise ang to lie in range 0 to 359
	until ang >= 0 do ang + 360 ->ang enduntil;
	until ang < 360 do ang - 360 ->ang enduntil;
	if ang > 1 then
		jump(min(side/(2*cos(90 - ang/2)),side));
	endif;
	turn(90 + round(ang/2));
	repeat num times
		draw(side); turn(ang);
		side+inc ->side;
	endrepeat;
enddefine;

vars getnumber;         ;;;defined below

define 2 poly;
	;;; for convenient repeated use of polyspi.
	vars cucharout; gcucharout ->cucharout;
	vars itemin;
	define interrupt;
		vars interrupt; setpop ->interrupt;
		setvdu();
		pr('\nrestarting poly\n');
		0 -> lastx; 0 -> lasty;
		exitto(valof("poly"));
	enddefine;

	define prmishap;
		sysprmishap();
		interrupt();
	enddefine;
	'type CTRL Z when you want to stop'=>
	'Type CTRL C to interrupt and restart poly'=>
	charout(0);     ;;; flush charout;
	repeat;
		clearstack();
		;;; enter a function, so that exitto(poly) comes out just before goto l
		procedure;
			setvdu();
			incharitem(gcucharin) -> itemin;
			polyspi(
				' initial length        '.getnumber,
				' increment             '.getnumber,
				' angle to turn         '.getnumber,
				' total number of sides '.getnumber,
				('thank you' =>),
				.greset);
			jumpto(-gxorigin,-gyorigin);
;;;         pr('PRESS RETURN to continue.'); charout(0);
			erase(rawcharin());
			greset();
			setvdu();
			if random(100) > 85 then 'wasnt that pretty ? ' =>
			elseif random(100) > 80 then 'i preferred your previous effort' =>
			elseif random(100) > 75 then 'practice makes perfect' =>
			elseif random(100) > 70 then 'beauty is in the eye of the beholder'=>
			elseif random(100) > 60 then 'i think ive seen that one before'=>
			elseif random(100) > 55 then 'beginners luck?' =>
			elseif random(100) > 60  then  'ugh ' =>
			endif;
		endprocedure.apply;
	endrepeat;
enddefine;

define getnumber(string)->num;
	;;; reads in a number using itemin defined in poly.
	pr(string);cucharout(0);
	until (.itemin ->>num).isnumber do
		if num=termin then
			'bye'=>
			greset(); setvdu(); setpop()
		endif;
		pr('please type a number ')
	enduntil;
enddefine;

pr('\n  TYPE:   poly;\n');

/* --- Revision History ---------------------------------------------------
--- Robert John Duncan, May 22 1995
		Moved to obsolete lib
 */
