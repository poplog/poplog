/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_query_mouse.p
 > Author:          Aaron Sloman, 15 Aug 1997
 > Purpose:			Find location of mouse pointer on screen
 > Documentation:   HELP RCLIB
 > Related Files:	LIB RCLIB
 > 			Base on the following (with thanks to John Gibson)
 > 					$usepop/pop/x/ui/lib/S-poplog_uiS-prompttool_xol.p
 */



/*
TEST commands

repeat 30 times
	[%rc_query_mouse()%] =>
	syssleep(20);
endrepeat;

*/

compile_mode :pop11 +strict;
section;

uses xt_display
include xpt_xtypes;


XptLoadProcedures 'rc_query'
	lvars
		XQueryPointer;
		;;; Query the pointer location

define rc_query_mouse() -> (x,y);
	;;; Return coordinates of mouse pointer on window, or (undef,undef)

	lvars
		widget = rc_widget(rc_default_window_object),
		dpy = XtDisplay(widget),
		win = XtWindow(widget),
		status;
	undef ->> x -> y;

	l_typespec raw_XQueryPointer (9):XptLongBoolean;
	lconstant
		mouse_x	= EXPTRINITSTR(:int),
		mouse_y	= EXPTRINITSTR(:int),
		dummy	= EXPTRINITSTR(:XptXID),
	;
	exacc raw_XQueryPointer(XtDisplay(widget), XtWindow(widget), dummy,
			dummy, mouse_x, mouse_y, dummy,dummy,dummy) -> status;
	if status then
		exacc :int mouse_x -> x;  exacc :int mouse_y -> y;
	endif;

enddefine;

endsection;
