/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/ved_browser.p
 > Purpose:			Invoke file browser from VED command
 > Author:          Aaron Sloman, May 15 1999
 > Documentation:
 > Related Files:
 */


section;

uses rclib
uses rc_browse_files

global vars
	vedbrowser_x = 400,
	vedbrowser_y = 5,
	vedbrowser_rows = 20,
	vedbrowser_font = '10x20',
;

;;; from rc_browse_files
global vars the_selected_file;

define rc_vedbrowser(x, y, path, filter, rows, font);
	;;; invoked by ENTER browser.
	;;; user definable

	;;; you may wish to remove this.
	lvars instruct =
		['Select your string' 'after scrolling if necessary'];

	rc_browse_files (x,y, path, filter, instruct, rows, 0, font, ident the_selected_file) ->;

enddefine;

define ved_browser();

	lvars
		list = sysparse_string(vedargument),
		path, filter;

	if vedargument = '-k' then
		rc_kill_browser_panels();
	else
		if vedargument = nullstring then
			nullstring, nullstring
		elseif listlength(list) == 1 then
			hd(list) -> path;
			if is_pattern_string(path) then
				nullstring, path
			else
				path, nullstring
			endif
		elseif listlength(list) == 2 then
			explode(list)
		else
			vederror('CANNOT INTERPRET: '<>vedargument)
		endif -> (path, filter);

		rc_vedbrowser(vedbrowser_x, vedbrowser_y, path, filter, vedbrowser_rows, vedbrowser_font);
	endif
enddefine;

endsection;
