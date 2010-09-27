/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_check_current_window.p
 > Purpose:			Check that window is OK before starting to draw
 > Author:          Aaron Sloman, Jul  8 1997
 > Documentation:
 > Related Files:
 */

section;

compile_mode :pop11 +strict;

uses rclib
uses rc_window_object

define rc_check_current_window(explain);
	unless rc_current_window_object and XptIsLiveType(rc_window, "Widget") then
		mishap('Live current window object needed',[^explain])
	endunless;
enddefine;

endsection;
