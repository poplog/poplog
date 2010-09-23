/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_kill_selected_windows.p
 > Purpose:         Kill windows selected using mouse 3
 > Author:          Aaron Sloman, Nov 15 1997 (see revisions)
 > Documentation:
 > Related Files:
 */

section;

uses rclib
uses rc_mousepic

define rc_kill_selected_windows();
	applist(rc_selected_window_objects, rc_kill_window_object);
	[] -> rc_selected_window_objects
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov 29 1997
	Added last line
 */
