/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_centred_rect.p
 > Purpose:			Draw a rectangle centred round the specified location
 > Author:          Aaron Sloman, Jul  7 1997
 > Documentation:
 > Related Files:
 */

/*

1 -> rc_yscale;
-1 -> rc_xscale;
rc_start();
rc_drawline(0,0,100,100);
rc_drawline(0,0,100,120);
rc_drawline(0,0,70,120);
rc_drawline(0,0,70,100);
rc_drawline(0,0,130,100);
rc_drawline(0,0,130,80);

rc_draw_centred_rect(100,100,60,40,'blue',40);
rc_draw_centred_rect(100,100,60,40,'pink',16);
rc_draw_centred_rect(100,100,60,40,'yellow',5);

rc_drawline(0,0,30,20);

rc_draw_centred_rect(0,0,60,40,'blue',40);
rc_draw_centred_rect(0,0,60,40,'pink',16);
rc_draw_centred_rect(0,0,60,40,'yellow',5);

*/

section;
compile_mode :pop11 +strict;

define rc_draw_centred_rect(x, y, width, height, colour, linewidth);
	dlocal
		%rc_foreground(rc_window)%,
		rc_linewidth;
	if colour then colour -> rc_foreground(rc_window) endif;
	if linewidth then linewidth -> rc_linewidth endif;
	
	lvars
		halfwidth = width/2.0,
		halfheight = height/2.0;

	rc_draw_rect(
		x - halfwidth*sign(rc_xscale),
		y - halfheight*sign(rc_yscale),
		width, height);
enddefine;

endsection;
