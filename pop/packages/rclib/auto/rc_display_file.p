/* --- Copyright University of Birmingham 2001. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_display_file.p
 > Purpose:			Use rc_display-strings to display text strings from a file
 > 					in a scrolling text panel
 > Author:          Aaron Sloman, 17 Jan 2001 (see revisions)
 > Documentation:	HELP RCLIB
 > Related Files:	LIB rc_control_panel
 */


/*

;;; tests
vars the_string;

the_string =>

vars panel1 = rc_display_file(500, 20, '.login', [], false, false, 5, 50, [], 'RC');

vars panel2 = rc_display_file(500, 20, '.xmain', [], false, false,
	20, 80,
	[{font '8x13'}{blobcol ^false}], 'RC');

vars panel3 = rc_display_file("right", "top", '.login', [], false, false, 10, 40,
		[{font '6x13'} {fieldbg 'black'} {ident the_string}], 'RC', panel2);

define test_acceptor(obj, val, button);
	;;; [selected ^val]=>
	rc_kill_menu();
enddefine;


rc_display_file(500, 20, '.login', [], test_acceptor, false,
	20, 50, [{font '7x13'} {ident the_selected_string} ], 'RC')=>
the_string =>
the_selected_string =>

*/


section;


uses rclib
uses rc_defaults

exload_batch;

	uses rc_scrolltext
	uses rc_control_panel

	uses rc_display_strings
endexload_batch;

define vars rc_display_file(x, y, file, panel_fields, acceptor, reactor, rows, cols, scrollspecs, title) -> panel;

	lvars container = false;

	ARGS x, y, file, panel_fields, acceptor, reactor,
			rows, cols, scrollspecs, title, &OPTIONAL container:isrc_window_object;


	lvars strings, rep, string;

	line_repeater(file, sysstring) -> rep;

	{%
		repeat
			rep() -> string;
			quitif(string == termin);
			string
		endrepeat
	%} -> strings;
	
	[{blobcol ^rc_display_strings_surround_def} ^^scrollspecs] -> scrollspecs;
	rc_display_strings(x, y, strings, panel_fields, acceptor, reactor, rows, cols, scrollspecs, title,
		if container then container endif) -> panel;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 18 2001
	Changed so as to make the scroll-bars and pointer on left invisible.
	To make them visible use a property like {blobcol 'black'} in the
	the scrollspecs list.
 */
