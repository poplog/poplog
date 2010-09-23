/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_title.p
 > Purpose:         Get or set title of window
 > Author:          Aaron Sloman, May  2 1996 (see revisions)
 > Documentation:	Below
 > Related Files:
 */


/*

rc_title(window) -> string;
string -> rc_title(window)

Get or set title of window

*/

compile_mode :pop11 +strict;
uses xpt_coretypes;
uses popxlib
uses xt_widgetinfo

section;

;;; cache for accessing and updating titles
lvars old_title = false, old_window = false;

define rc_title(window);
	if window == old_window then old_title
	else
		XptValue(XtParent(window), XtN title, TYPESPEC(:XptString))
			->> old_title;
		window -> old_window;
	endif;
enddefine;

define updaterof rc_title(string, window);
	if window == old_window and string == old_title then
		;;; do nothing
	else
		string
			->> XptValue(XtParent(window), XtN title, TYPESPEC(:XptString))
			->> XptValue(XtParent(window), XtN iconName, TYPESPEC(:XptString))
		-> old_title;
		
		window -> old_window
	endif		
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 13 2001
Made to compile xt_widgetinfo, to prevent warning messages
--- Aaron Sloman, Apr 15 1997
	Changed to update iconName also
 */
