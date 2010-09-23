/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_line_width.p
 > Linked to:       $poplocal/local/auto/rc_line_width.p
 > Purpose:			Cached version of rc_linewidth
 > Author:          Aaron Sloman, Jan  1 1997 (see revisions)
 > Documentation:   HELP * RC_GRAPHIC, HELP * RC_LINEPIC
 > Related Files:	LIB * RC_GRAPHIC, LIB * RC_MOUSEPIC
 */


;;; compile_mode :pop11 +strict

uses rc_graphic
uses rclib;

section;
;;; cached value of rc_linewidth
lvars current_linewidth = false, current_window = false;

;;; A cached version of rc_linewidth (from LIB RC_GRAPHIC).
define rc_line_width(window) /*-> int */;
	;;; return current linewidth
	rc_check_window(window);

	if current_linewidth and current_window == window then
		current_linewidth
	else
		window -> current_window;
		;;; rc_linewidth
		XptVal[fast] window(XtN lineWidth:int) ->> current_linewidth;
	endif /* -> int */
enddefine;

define updaterof rc_line_width(int, window);
	;;; change current linewidth
	rc_check_window(window);
	if int == current_linewidth and current_window == window then
		;;; do nothing
	else
		window -> current_window;
		fi_check(int, 0, false) ->> current_linewidth
			;;; -> rc_linewidth
			-> XptVal[fast] window(XtN lineWidth:int);
	endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug  4 1997
	Changed to use rc_check_window
 */
