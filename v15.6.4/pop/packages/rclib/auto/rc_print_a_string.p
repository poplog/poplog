/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_print_a_string.p
 > Purpose:			Print a string with specified location, font, and colour
 > Author:          Aaron Sloman, Aug 29 2000
 > Documentation:	HELP RCLIB
 > Related Files:
 */


section;

compile_mode :pop11 +strict;

define vars rc_print_a_string(x, y, string, colour, font);
	
	dlocal
		%rc_foreground(rc_window)%,
		%rc_font(rc_window)%;

	if colour then colour -> rc_foreground(rc_window) endif;
	if font then font -> rc_font(rc_window) endif;

	rc_print_at(x, y, string);

enddefine;

endsection;
