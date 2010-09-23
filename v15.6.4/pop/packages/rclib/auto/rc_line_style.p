/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_line_style.p
 > Linked to:       $poplocal/local/auto/rc_line_style.p
 > Purpose:         Cached version of rc_linestyle
 > Author:          Aaron Sloman, Jan  1 1997
 > Documentation:
 > Related Files:
 */

uses rc_graphic
;;; compile_mode :pop11 +strict
section;

;;; cached value of rc_linestyle
lvars current_linestyle = false, current_window = false;

;;; A cached version of rc_linestyle (from LIB RC_GRAPHIC).
define procedure rc_line_style(window) /*-> int */;
	;;; return current linestyle
	if current_linestyle and current_window == window then
		current_linestyle
	else
		window -> current_window;
		;;; rc_linestyle
		XptVal[fast] window(XtN lineStyle:int) ->> current_linestyle;
	endif; /* -> int */
enddefine;

define updaterof rc_line_style(int,window);
	;;; change current linestyle
	if int == current_linestyle and current_window == window then
		;;; do nothing
	else
		window -> current_window;
		fi_check(int, 0, false) ->> current_linestyle
			;;; -> rc_linestyle
			-> XptVal[fast] window(XtN lineStyle:int);
	endif
enddefine;

endsection;
