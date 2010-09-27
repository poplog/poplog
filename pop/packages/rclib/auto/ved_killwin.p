/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/ved_killwin.p
 > Purpose:			Kill current window object
 > Author:          Aaron Sloman, Aug  2 1997
 > Documentation:	HELP * RCLIB
 > Related Files:
 */

/*
Make a window current, by clicking on it with mouse button 1 (left)
while CTRL/Control key is held down.

Then ENTER killwin

*/

section;

define ved_killwin();
	rc_kill_window_object(rc_current_window_object);
enddefine;

endsection;
