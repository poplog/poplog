/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_browse_files.p
 > Purpose:			Browse file directories
 > Author:          Aaron Sloman, May 13 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
::: TESTS

vars the_string;
the_string =>

vars instruct = ['Select your string' 'after scrolling if necessary'];
vars panel, panel1, panel2;
rc_browse_files (300,20,'~/', 'a*', instruct, 20, 50, '7x13', ident the_string) -> panel;
rc_browse_files (300,20,'~/', '', instruct, 20, 50, '7x13', ident the_string) -> panel;
rc_browse_files (30,20,'~/', 'v*', instruct, 10, 20, '10x20', ident the_string,panel) -> panel1;
;;; rc_browse_files (x, y, path, filter, instruct, rows, cols, font, wident) -> panel2;

*/

uses rclib
uses rc_scrolltext
uses rc_control_panel
uses rc_display_strings
uses rc_defaults


;;; Global variables, and their default values
define :rc_defaults;
	rc_show_dot_files = false;
	rc_list_dirs_first = true;
	rc_browser_button_width_def = 90;
enddefine;

define rc_browse_files (x, y, path, filter, instruct, rows, cols, font, wident) -> panel;

	lvars container = false;

	ARGS x, y, path, filter, instruct,
			rows, cols, font, wident, &OPTIONAL container:isrc_window_object;

	sysfileok(path) -> path;


	;;; make a vector of files matching the path
	lvars

		;;; files_matching(path, filter, with_dirs, with_dotfiles, dirs_first)==>
		vec = files_matching(path, filter,true, rc_show_dot_files, rc_list_dirs_first),
		len = datalength(vec);

	define recurse();
		;;; invoked by "Expand" action button, or the accepter procedure
		external_defer_apply(
        	procedure();
				lvars
					container = rc_window_container(panel),
					string = valof(wident),
					filter_panel = rc_fieldcontents_of(panel, "filter"),
					Filter ;

				if rc_text_input_active(filter_panel) then
					consolidate_or_activate(filter_panel)
				endif;

				rc_informant_value(filter_panel) -> Filter;

				;;; It's unlikely that the same filter is wanted for subdirectory
				if Filter = filter then
					nullstring -> Filter
				endif;

				lvars xloc, yloc;
				if container then
					(x, y) -> (xloc, yloc)
				else
					rc_window_location(panel) -> (xloc, yloc, , );
				endif;
				;;; displace new window a standard amount
				xloc + rc_window_x_offset -> xloc;
				yloc + rc_window_y_offset-> yloc;

				if sysisdirectory(string) then

					rc_browse_files (
						xloc, yloc, string, Filter, instruct, rows, cols, font, wident,
							if container then container endif) -> ;
				else
					rc_browser_action(string);
				endif;
			endprocedure);
	enddefine;

	define default_acceptor(obj, val, item);
		;;; The procedure invoked by the "acceptor" mechanism, e.g.
		;;; double click, or RETURN
		val -> valof(wident);
		recurse();
	enddefine;

	define do_edit();
		external_defer_apply(edit(% the_selected_string %))
	enddefine;

	define do_compile();
		external_defer_apply(pop11_compile(% the_selected_string %))
	enddefine;

	define do_unix();
		external_defer_apply(veddo(%'csh ' <> the_selected_string %))
	enddefine;

	define do_getaction();
		lvars command_name =
			rc_getinput("middle", "middle",['Type required command'], '', [], 'GetCommand');

		if isstartstring('ved_', command_name) then
			external_defer_apply(edit(% the_selected_string %)<> valof(consword(command_name)))
		else
			external_defer_apply(sysobey(%command_name <> ' ' <> the_selected_string %))
		endif
	enddefine;

	define do_clear_filter();
		lvars
			filter_panel = rc_fieldcontents_of(panel, "filter"),
			filter ;

		if rc_text_input_active(filter_panel) then
			consolidate_or_activate(filter_panel)
		endif;

		nullstring -> rc_informant_value(filter_panel);

	enddefine;


	define lconstant default_reactor(obj, val);
		if isword(wident) or isident(wident) then
			val -> valof(wident);
		endif;
		val -> the_selected_string
	enddefine;

	lvars panel_fields =
		[
            [ACTIONS {width ^rc_browser_button_width_def} {cols 3}:
				['Expand/Display' ^recurse]
				['Edit (Ved)' ^do_edit]
				['Compile' ^do_compile]
				['Obey(unix)' ^do_unix]
				['Get action' ^do_getaction]
				['Clear filter' ^do_clear_filter]
			]

			[TEXT : ^^instruct
				% if len > rows then len sys_>< ' files found' endif%
			]
			[TEXTIN
				{label filter}
				{fieldbg 'grey20'}
				{width 250}{labelstring 'Filter:'} : ^filter
			]
		],

	scroll_specs =
		[{font ^font} {ident ^wident}
			{acceptor ^default_acceptor} {reactor ^default_reactor}]

	;

	rc_display_strings(x, y, vec, panel_fields,
		default_acceptor, default_reactor, rows, cols,
			scroll_specs, path, if container then container endif) -> panel;


enddefine;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 26 2002
    replaced rc_informant_contents with rc_informant_value
		
--- Aaron Sloman, Jul 22 2000
	Introduced rc_browser_button_width_def, and used rc_defaults
	If an action name that is typed in begins with 'ved_' the file is
	edited and the command run in that buffer. E.g. if it is a latex
	file, then the command ved_latex in the action field will be equivalent
	to ENTER latex.
--- Aaron Sloman, Aug 28 1999
		replaced the_selected_*file with the_selected_string
--- Aaron Sloman, Aug 26 1999
	Slightly modified text in buttons.
--- Aaron Sloman, Aug 11 1999
	Added extra actions to the browser panel. Still more options possible.
--- Aaron Sloman, Aug  9 1999
	Changed so that if recurse action is invoked and filter has not been
	changed, the filter is nullstring, i.e. match anything.
--- Aaron Sloman, May 19 1999
	 Allowed optional container argument for parent rc_window_object
 */
