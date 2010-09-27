/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_getfile.p
 > Purpose:			Find files on disk
 > Author:          Aaron Sloman, May  6 1999 (see revisions)
 > Documentation:	
 > Related Files:	LIB * PUI_POPUPTOOL
 */

/*
vars panel =
	rc_control_panel(400, 10,
		[{width 500}{height 400}
			[ACTIONS {gap 200}:
				[KILL rc_kill_menu]]], 'TEST');

true -> rc_show_dot_files;
false -> rc_show_dot_files;

rc_getfile(500 ,20, '~/v*', false, 10, 50, '9x15') =>
rc_getfile(500 ,20, '~/', false, 20, 50, '10x20') =>
rc_getfile(500 ,20, '~/', false, 20, 50, '10x20', "recurse") =>
rc_getfile(500 ,20, '~', false, 20, 0, '10x20', "recurse") =>
rc_getfile(500 ,20, '~/adm', false, 20, 50, '10x20', "recurse") =>
rc_getfile(500 ,20, '~/a*', false, 20, 50, '10x20', "recurse") =>
rc_getfile(500 ,20, '~/a*', false, 0, 50, '10x20', "recurse") =>
rc_getfile(500 ,20, '~/a*', false, 25, 0, '10x20', "recurse") =>
rc_getfile(500 ,20, '~/a*?/.../a*', false, 25, 0, '10x20', "recurse") =>
rc_getfile(5 ,20, './.../?*.p', false, 10, 0, '10x20', "recurse", panel) =>
rc_getfile(5,20, '~/adm', false, 10, 25, '10x20', "recurse", panel) =>

*/


compile_mode :pop11 +strict;


section;
uses rclib
uses rc_scrolltext
uses rc_popup_strings

global vars
	rc_show_dot_files = false,
	rc_list_dirs_first = true;


define rc_getfile(x, y, path, filter, rows, cols, font) -> selection;
	;;; allows optional extra argument, "recurse", and container

	lvars container = false,  recurse = false;

	ARGS x, y, path, filter, rows, cols, font,
		&OPTIONAL recurse:isword, container:isrc_window_object;

	lvars len, file, count, strings, vec;


	dlocal rc_slider_field_radius_def = 8;

	;;; make a vector of files matching the path
	lvars

		;;; files_matching(path, filter, with_dirs, with_dotfiles, dirs_first)==>
		vec = files_matching(path, filter,true, rc_show_dot_files, rc_list_dirs_first),
		len = datalength(vec);

	lvars files = if recurse then len - 1 else len endif;

	if vec == {} then false
	else
		[%
			if  isinteger(rows) and (len > rows) then
				if rows == 0 then files >< ' files matched filespec.'
				else 'Showing ' sys_>< rows  sys_>< ' files out of 'sys_>< len,
				endif,
				'Use button 1 or Up Down arrow keys',
				'to change selected file.',
			endif,
			'Select your file', 'then press OK or double-click'
		%] -> strings;
		rc_popup_strings(x, y, vec, strings, rows, cols, font,
			if container then container endif) -> selection;

		if recurse and selection and sysisdirectory(selection) then
			chain(x, y, selection, filter, rows, cols, font, "recurse",
				if container then container endif, rc_getfile);
		endif;
	endif;

enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, May 19 1999
	Allowed optional container argument for parent rc_window_object	
--- Aaron Sloman, May  9 1999
	Added "recurse" option.
*/
