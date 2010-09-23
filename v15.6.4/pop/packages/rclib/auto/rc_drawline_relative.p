/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_drawline_relative.p
 > Purpose:         Draw a line with relative coordinates
 > Author:          Aaron Sloman, 1 Jul 1997 (see revisions)
 > Documentation:   HELP * RCLIB
 > Related Files:   LIB * RC_DRAWLINE_ABSOLUTE
 */

/*
rc_start();
rc_drawline(0, 0, 150, 150);
rc_drawline_relative(0,0,150,150,'blue',5);
rc_drawline_relative(0,100,200,100,'orange',25);
rc_drawline_relative(0,50,200,150,'ivory',35);
rc_drawline_relative(-150,50,150,150,'red',135);
rc_drawline_relative(-150,50,150,150,"background",100);
rc_drawline_relative(-150,50,150,150,false,80);
rc_drawline_relative(0,100,200,100,true,35);
rc_drawline_relative(100,0,100,200,false,35);
rc_drawline_relative(0,100,200,100,true,35);
rc_destroy();
*/

section;
uses rclib
uses rc_graphic
uses rc_drawline_absolute
compile_mode :pop11 +strict;

define rc_drawline_relative(x1, y1, x2, y2, colour, width);

	rc_drawline_absolute(
		rc_transxyout(x1, y1), rc_transxyout(x2, y2), colour, abs(width * rc_yscale))

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Feb 19 2000
	owing to changes in rc_drawline_absolute, this now accepts "background" and
	"false" means use current foreground.
--- Aaron Sloman, Nov  8 1997
	made sure last argument to drawline_absolute is positive
 */
