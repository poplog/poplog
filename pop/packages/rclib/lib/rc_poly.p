/* --- The University of Birmingham 1995.  --------------------------------
 >  File: 			$poplocal/local/lib/rc_poly.p
 >  Purpose:        draw pretty pictures using  LIB * RC_GRAPHIC
 > Author:          Aaron Sloman, Mar 20 1995 (see revisions)
 > Documentation:   Below
 */

/*  --- Copyright University of Sussex 1990.  All rights reserved. ---------
 >  File:           $popcontrib/x/demos/rc_poly.p
 >  Author:         Aaron Sloman, May 1990
 >  Documentation:  Comments below. Also see HELP * RC_GRAPHIC
 >  Related Files:  LIB * RC_GRAPHIC

 */

/*
The operation rc_poly, repeatedly uses procedure polyspi to draw pretty
pictures, in response to four numbers typed in by the user:

	Initial length
	Increment
	Angle to turn
	Number of sides

All but the last can be positive or negative, integers or decimals.

This is based on the old LIB POLY, originally implemented circa 1977
in Pop-11 on the PDP11/40, and before that on the DEC-10 in Pop-2.

*/
section;

uses rc_graphic

define polyspi(side, inc, ang, num);
	;;; Draw a polygonal spiral. Initial arm length is side.
	;;; inc is added at each turn.
	;;; The angle turned (to left) is ang (in degrees).
	;;; The total number of sides is num.
	;;; This is invoked by the operation -rc_poly- below

	lvars side, inc, ang, num;
	dlocal popradians = false;

	1 -> rc_xscale;
	-1 -> rc_yscale;
	rc_window_xsize >> 1 -> rc_xorigin;
	rc_window_ysize >> 1 -> rc_yorigin;
	rc_jumpto(0, 0); 45 -> rc_heading;

	;;; move to a location and heading which will cause the centre of the
	;;; spiral to be near centre of screen (very approximate).
	;;; but first normalise ang to lie in range 0 to 359
	until ang >= 0 do ang + 360 ->ang enduntil;
	until ang < 360 do ang - 360 ->ang enduntil;
	if ang > 0.5 then
		ang/2.0 -> rc_heading;
		rc_jump(min(side/(2.0*sin(ang/2.0)),side));
	endif;
	rc_turn(90 + ang/2.0);
	repeat num times
		rc_draw(side); rc_turn(ang);
		side+inc ->side;
	endrepeat;
enddefine;




define 2 rc_poly;
	;;; for convenient repeated use of polyspi.
	lvars procedure itemin = incharitem(charin);

	define lconstant getnumber(string)->num;
		;;; prints out string and reads in a number
		lvars string;
		pr(string);pr(newline);
		repeat
			itemin() ->num;
		quitif(isnumber(num));
			if num=termin or num == "bye" then
				'bye'=>
				exitfrom(nonop rc_poly)
			endif;
			pr('please type a number ')
		endrepeat;
	enddefine;

	'type CTRL Z or "bye" when you want to stop'=>
	'Type CTRL C to interrupt and restart rc_poly'=>
	pr(newline);     ;;; flush charout;
	rc_start();
	repeat;
		clearstack();
		polyspi(
			' initial length        '.getnumber,
			' increment             '.getnumber,
			' angle to turn         '.getnumber,
			' total number of sides '.getnumber,
			('thank you' =>),
			rc_start());

		if random(100) > 65 then 'wasnt that pretty ? ' =>
		else
			oneof([
					'I preferred your previous effort'
					'Practice makes perfect'
					'You\'ve been here before'
					'Everyone tries that'
					'Keep at it, you can only get better'
					'Bet you can\'t make it draw a face'
					'Beauty is in the eye of the beholder'
					'There\'s hidden beauty in numbers'
					'I think Ive seen that one before'
					'Beginner\'s luck?'
			  		'Ugh!'
					])=>
		endif;
	endrepeat;
enddefine;

pr('\n  TYPE:   rc_poly;\n');

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 20 1995
	changed heading to rc_heading
 */
