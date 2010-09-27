/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_centred_square.p
 > Purpose:			Draw a square centred round the specified location
 > Author:          Aaron Sloman, Jul  7 1997
 > Documentation:   HELP * RCLIB, HELP * RC_LINEPIC, RC * GRAPHIC
 > Related Files:   LIB * rc_draw_centred_rect
 */

/*
rc_start();
1 -> rc_xscale;
-1 -> rc_yscale;
rc_drawline(0,0,100,100);

rc_draw_centred_square(100,0,50, 'blue', 10);
rc_draw_centred_square(100,0,50, 'yellow' ,false);


rc_draw_centred_square(0,0,50, 'pink', 50);
rc_draw_centred_square(0,0,50, 'blue', 10);
rc_draw_centred_square(0,0,50, 'yellow' ,false);

rc_draw_centred_square(0,100,50, 'pink', 50);
rc_draw_centred_square(0,100,50, 'blue', 10);
rc_draw_centred_square(0,100,50, 'yellow' ,false);
*/

section;
compile_mode :pop11 +strict;

define rc_draw_centred_square(x, y, side, colour, width);
	rc_draw_centred_rect(x, y, side, side, colour, width)
enddefine;

endsection;
