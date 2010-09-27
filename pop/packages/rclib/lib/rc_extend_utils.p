/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_extend_utils.p
 > Purpose:			Extend window utilities to cope with win_obj instances
 > Author:          Aaron Sloman, Jun 14 1997
 > Documentation:
 > Related Files:	LIB * RC_APPLY_UTIL
 */

uses rclib
uses rc_apply_util	

;;; the above defines the syntax word rc_extend_utils

;;; convert the following to work with rc_window_object instances
rc_extend_utils
	rc_font, rc_line_style, rc_line_width, rc_line_function,
	rc_background, rc_foreground, rc_title,
	;
