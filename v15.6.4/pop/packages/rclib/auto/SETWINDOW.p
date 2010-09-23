/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/SETWINDOW.p
 > Purpose:			Define a syntax word to assign to rc_current_window_object
 > Author:          Aaron Sloman, Oct 10 1999
 > Documentation:	HELP RCLIB, HELP RCLIB_COMPATIBILITY
 > Related Files:	LIB RC_WINDOW_OBJECT
 */

section;

define syntax SETWINDOW;
	;;; read an expression and then plant an assignment to
	;;; rc_current_window_object

	pop11_comp_expr();
	sysPOP("rc_current_window_object");

enddefine;

endsection;
