/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_display_strings.p
 > Purpose:			Use rc_scrolltext and rc_control_panel to display text strings
 > 					in a scrolling text panel
 > Author:          Aaron Sloman, May 15 1999 (see revisions)
 > Documentation:	HELP RCLIB
 > Related Files:	LIB rc_control_panel
 */


/*

;;; tests
vars
	strings =
	['Select your string' 'after scrolling if necessary'],
	vec =
	{%
		lvars x;
	for x to 40 do
		x ><
		'. a very useful number to display today is the number '
		>< x
	endfor;
	%};

vars the_string;

the_string =>

vars panel1 = rc_display_strings(500, 20, vec, [], false, false, 1, 50, [], 'RC');

vars panel2 = rc_display_strings(500, 20, datalist(vec), [], false, false, 30, 0, [{font '8x13'}], 'RC');

vars panel3 = rc_display_strings(5, 2, vec, [], false, false, 10, 40,
		[{font '6x13'} {fieldbg 'black'} {ident the_string}], 'RC', panel2);

define test_acceptor(obj, val, button);
	;;; [selected ^val]=>
	rc_kill_menu();
enddefine;


rc_display_strings(500, 20, vec, [], test_acceptor, false,
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

endexload_batch;

define :rc_defaults;
	rc_display_strings_fieldbg_def = 'white';
	rc_display_strings_textfg_def = 'grey10';
	rc_display_strings_textbg_def = 'grey90';
	rc_display_strings_surround_def = 'grey80';
	rc_display_strings_blobcol_def = 'grey20';
	rc_display_strings_buttonwidth_def = 90;
enddefine;

global vars
	;;; list of current browsers, to prevent them being garbage collected
	browse_panels = [],
	;;; variable set when selecting files
	the_selected_string = false;


define vars rc_kill_browser_panels();
	applist(browse_panels, rc_kill_window_object);
	[] -> browse_panels;
enddefine;

define vars rc_display_strings(x, y, strings, panel_fields, acceptor, reactor, rows, cols, scrollspecs, title) -> panel;

	lvars container = false;

	ARGS x, y, strings, panel_fields, acceptor, reactor,
			rows, cols, scrollspecs, title, &OPTIONAL container:isrc_window_object;


	lvars len, file, count, string, vec;

	dlocal rc_slider_field_radius_def = 8;

	;;; prepare a vector if necessary
	if strings == [] or strings = #_< {} >_# then
		false -> the_selected_string;
		if isprocedure(acceptor) then
			acceptor(false, false, false)
		endif;
		false -> panel;
		return();
	else
		if isvector(strings) then strings
		else
			;;; convert strings to vector
			{%	 explode(strings) %}
		endif -> vec;

		;;; set default value for the associated identifier
		subscrv(1, vec) -> the_selected_string;

		datalength(vec) -> len;

		define lconstant default_reactor(obj, val);
			val -> the_selected_string
		enddefine;

		unless isprocedure(reactor) then
			default_reactor -> reactor
		endunless;

		define lconstant default_acceptor(obj, val, button);
			;;; [obj ^obj val ^val button ^button]=>
			val -> the_selected_string
		enddefine;

		unless isprocedure(acceptor) then
			default_acceptor -> acceptor;
		endunless;

		define lconstant destroy_panel();
			rc_kill_menu();
			delete(panel, browse_panels, nonop ==) -> browse_panels;
		enddefine;


		lvars fields =
		  	[
				[ACTIONS {width ^rc_display_strings_buttonwidth_def} :
					{blob 'Dismiss' ^ destroy_panel}
					{blob 'Dismiss All' rc_kill_browser_panels}
				]
				^^panel_fields
				[SCROLLTEXT
					{reactor ^reactor}
					{acceptor ^acceptor}
					{fieldbg ^rc_display_strings_fieldbg_def}
					{textfg ^rc_display_strings_textfg_def}
					{textbg ^rc_display_strings_textbg_def}
					{surroundcol ^rc_display_strings_surround_def}
					{blobcol ^rc_display_strings_blobcol_def}
					{rows ^(min(len, rows))} {cols ^cols}
					^^scrollspecs
					: ^vec
				]
			];
		rc_control_panel(x, y, fields, title, if container then container endif) -> panel;
		panel :: browse_panels -> browse_panels;
	endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 21 2000
	Added rc_display_strings_buttonwidth_def
--- Aaron Sloman, Jul  4 2000
	Introduced new default globals
	rc_display_strings_fieldbg_def
	rc_display_strings_textfg_def
	rc_display_strings_textbg_def
	rc_display_strings_surround_def
	rc_display_strings_blobcol_def
--- Aaron Sloman, Sep 14 1999
	Fixed recursion bug in call of delete
--- Aaron Sloman, Aug 28 1999
		replaced the_selected_*file with the_selected_string
--- Aaron Sloman, May 19 1999
	 Allowed optional container argument for parent rc_window_object
 */
