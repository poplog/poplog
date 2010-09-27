/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_drawline_absolute.p
 > Purpose:         Draw a line with absolute coordinates
 > Author:          Aaron Sloman, Jun 15 1997 (see revisions)
 > Documentation:	HELP * RCLIB
 > Related Files:	LIB * rc_drawline_relative, rc_draw_bar
 */

/*
rc_start();
rc_drawline(0, 0, 150, 150);
rc_drawline_absolute(20,0,20,150,'blue',5);
rc_drawline_absolute(0,100,200,100,'orange',25);
rc_drawline_absolute(0,50,200,150,'ivory',35);
rc_drawline_absolute(0,50,400,150,'pink',135);
rc_drawline_absolute(0,50,400,150,false,100);
rc_drawline_absolute(0,50,400,150,"background",60);
rc_drawline_absolute(0,100,200,100,true,35);
rc_drawline_absolute(100,0,100,200,false,35);
rc_drawline_absolute(0,100,200,100,true,35);
rc_destroy();
*/

section;
uses rclib
uses rc_graphic
compile_mode :pop11 +strict;

define rc_drawline_absolute(x1, y1, x2, y2, colour, width);
	round(width) -> width;
	checkinteger(width,0,false);

	dlocal
		%rc_foreground(rc_window)%,
		%rc_line_width(rc_window)% = width;

	if isstring(colour) or isinteger(colour) then
		 colour  -> rc_foreground(rc_window);
	elseif colour == "background" then
		;;; colour should be background
		rc_background(rc_window)  -> rc_foreground(rc_window);
	elseif isboolean(colour) then
		;;; use default foreground colour
		;;; should produce an error for true, but leave it for now,
		;;; for partial backward compatibility.
	else
		mishap('String or integer colour code needed', [^colour]);
	endif;

	XpwDrawLine(rc_window, round(x1), round(y1), round(x2), round(y2));
	
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Feb 19 2000
	Changed specification again, to be closer to spec for rc_foreground.
	I.e. "background" means use background. false means use foreground.
--- Aaron Sloman, Nov  6 1997
	Made sure the width was rounded.
--- Aaron Sloman, Jun 17 1997
	Changed specification so that if colour == false then background
	colour is used, whereas if it is true then default foreground colour
	is used.
 */
