/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_testbrowser.p
 > Purpose:			Test current version of rc_browse_files.p
 > Author:          Aaron Sloman, May 14 1999 (see revisions)
 > Documentation:
 > Related Files:
 */
/*

;;; test

rc_testbrowser(400, 10, '~', 'a*', 30, '9x15');
rc_testbrowser(400, 10, '~/', '*.p', 30, '9x15');

the_selected_string =>
*/

uses rclib
uses rc_browse_files

vars the_selected_string = false;

define rc_testbrowser(x, y, file, filter, rows, font);

	lvars instruct =
		['Select your string' 'after scrolling if necessary'];

	rc_browse_files (x,y, file, filter, instruct, rows, 0, font, ident the_selected_string) ->;

enddefine;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 28 1999
		replaced the_selected_*file with the_selected_string
	
 */
