/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/menu_choosefile1.p
 > Purpose:			Demonstrating one of the button options
 > Author:          Aaron Sloman, Jan  8 1997 (see revisions)
 > Documentation:	HELP * RCLIB
 > Related Files:
 */



section;

uses rclib

uses rc_getfile
uses rc_browse_files

global vars
	menu_choosefile_font = '7x13',
	menu_choosefile_rows = 30,
	;;;  make this 0 to allow it to expand or contract as needed:
	menu_choosefile_cols = 40;

;;; Two styles of file browsers

define menu_choosefile1();
	;;; A single panel
    lvars string;

	rc_getfile("middle" ,"top",
		'~/', false, 20, 0, menu_choosefile_font, "recurse") -> string;

	if string then
	    vededitor(vedveddefaults, string);
	endif;
enddefine;


define menu_choosefile2();

	lvars selected_file = false;

	lvars instruct =
		['Select your string, after scrolling'
			'up or down if necessary.'
			'Select a directory to expand it (with filter).'
			'Select a file to view or act on it.'];

	rc_browse_files(
		"middle", "top",
		current_directory, nullstring, instruct,
		menu_choosefile_rows, menu_choosefile_cols, menu_choosefile_font,
		ident selected_file) ->;	;;; ignore panel

enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 22 2000
	Changed the default font: made it smaller.
--- Aaron Sloman, Aug 26 1999
	Extended instructions. Still need to extend options (e.g. list
	chronologically.)
--- Aaron Sloman, Aug 20 1999
	Changed to use rclib stuff
 */
