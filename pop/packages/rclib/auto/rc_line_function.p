/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_line_function.p
 > Linked to:       $poplocal/local/auto/rc_line_function.p
 > Purpose:			Cached version of rc_linefunction
 > Author:          Aaron Sloman, Jan  1 1997
 > Documentation:   HELP * RC_GRAPHIC, HELP * RC_LINEPIC
 > Related Files:	LIB * RC_GRAPHIC, LIB * RC_MOUSEPIC
 */


compile_mode :pop11 +strict;

uses rc_graphic

section;
;;; cached value of rc_linefunction
lvars current_linefunction = false, current_window = false;

;;; A cached version of rc_linefunction (from LIB RC_GRAPHIC).
define rc_line_function(window) /*-> int */;
	;;; return current linefunction
	if current_linefunction and current_window == window then
		current_linefunction
	else
		window -> current_window;
		;;; rc_linefunction
		XptVal[fast] window(XtN function:int) ->> current_linefunction;
	endif /* -> int */
enddefine;

define updaterof rc_line_function(int, window);
	;;; change current linefunction
	if int == current_linefunction and current_window == window then
		;;; do nothing
	else
		window -> current_window;
		fi_check(int, 0, false) ->> current_linefunction
			;;; -> rc_linefunction
			-> XptVal[fast] window(XtN function:int);
	endif
enddefine;

endsection;
