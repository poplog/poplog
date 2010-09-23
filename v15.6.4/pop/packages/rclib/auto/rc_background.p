/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_background.p
 > Also:            $poplocal/local/auto/rc_background.p
 > Purpose:         Get or set background of rc_graphic window
 > Author:          Aaron Sloman, Feb 13 1995 (see revisions)
 > Documentation:
 > Related Files:
 */

uses rc_graphic;
/*

rc_start();
rc_background(rc_window) =>

'seagreen' -> rc_background(rc_window);
'lightblue' -> rc_background(rc_window);

*/

section;
compile_mode :pop11 +strict;

define global rc_background(window) -> colour;
	rc_check_window(window);
	window(XtN background) -> colour;
enddefine;


define updaterof rc_background(window);
	rc_check_window(window);
	-> window(XtN background);
	 XpwClearWindow(window);
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug  4 1997
	Added check for live window
 */
