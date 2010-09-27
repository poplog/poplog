/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/ved_open_file.p
 > Purpose:			Open file for use with rclib facilities
 > Author:          Aaron Sloman, Aug 20 2000
 > Documentation:	HELP RCLIB
 > Related Files:
 */

section;

compile_mode :pop11 +strict;

define vars ved_open_file(name, x, y, cols, rows, saveable);
	;;; If the file called name is not already in ved, open it with
	;;; a window at location x, y on screen with cols columns and rows rows.
	;;; If saveable is true then the file will be writeable, otherwise not.

	unless vedpresent(name) then
		;;; Open the file with the required window settings.
		;;; Those settings are ignored if XVed is not running
		x, y, cols, rows -> xved_value("nextWindow", [x y numColumns numRows]);
		edit(name);
		saveable -> vedwriteable;
		ved_save_file_globals();
		vedputcommand(nullstring);
		;;; the next three lines may be redundant
		vedputmessage(nullstring);
		vedsetstatus(nullstring, false, true);
		vedrefreshstatus();
	endunless;
enddefine;



endsection;
