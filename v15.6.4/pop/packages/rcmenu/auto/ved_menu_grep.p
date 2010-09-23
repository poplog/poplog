/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/auto/ved_menu_grep.p
 > File:            $poplocal/local/menu/auto/ved_menu_grep.p
 > Purpose:			Using ved_grep to search files
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:   LIB RCLIB
 */

/*
-- Using ved_grep to search files

For use with Searchfiles* menu button

;;; test
ved_menu_grep();
*/

section;

uses rclib
uses rc_buttons
uses rc_control_panel

uses rcmenulib

lvars
		searchstring = nullstring,
		files = nullstring;

define global procedure ved_menu_grep();
	;;; Use lconstant so that the same widget is always used.
	
	lconstant
		title = 'Search files',
		tellstrings =
			[TEXT :
				'SEARCH FILES FOR STRINGS'
				'Decide whether you want it to be case sensitive.'];

	lvars
		oldfile = vedcurrentfile,
		search_caseless = true;

	define lconstant do_case(button);
    	lvars label = rc_button_label(button);
		label = 'CaseLess' -> search_caseless;
	enddefine;


	define do_search();
	
		lvars
			field1 = rc_fieldcontents_of(rc_active_window_object, "text1"),
			field2 = rc_fieldcontents_of(rc_active_window_object, "text2"),
			;

		if rc_text_input_active(field1) then
			consolidate_or_activate(field1)
		endif;

		if rc_text_input_active(field2) then
			consolidate_or_activate(field2)
		endif;

		returnif(files = nullstring or searchstring = nullstring);

		lvars command;
		if search_caseless then 'grep -i ' else 'grep ' endif
					<> searchstring <> ' ' <> files -> command;

		define sub_search();
			veddo(command, true);

			if ved_on_status then false -> ved_on_status endif;
			if oldfile /== vedcurrentfile then
				vedputmessage('DONE');
			else
				vedputmessage('NOTHING FOUND');
			endif;
			vedrefreshstatus();
		enddefine;
		
		if vedusewindows == "x" then
			;;; running this directly causes a crash
			vedinput(sub_search);
			XptSetXtWakeup();
		else
			sub_search();
		endif;
	enddefine;

	define do_react(button, val);
		do_search();
	enddefine;


	lvars

		menu_grep_options =
			[
				[RADIO {select ^do_case}{default 'CaseLess'}
					{cols 2}{spacing 10}:
					'CaseLess'
					'CaseSensitive']
				[ACTIONS {cols 2}{spacing 10}:
					{blob 'Search' ^do_search}
					{blob 'Dismiss' rc_kill_panel}]
				[TEXTIN
					{label text1} {width 180}
					{ident ^(ident searchstring)} {align left}
					{labelcolour 'grey10'}
					{reactor ^do_react}
					{labelstring 'Search Pattern:'} : '']
				[TEXTIN
					{label text2}  {width 240}
					{ident ^(ident files)} {align left}
					{labelcolour 'grey10'}
					{reactor ^do_react}
					{labelstring 'File Pattern:'}: '']
			],

		grep_fields =
			[^tellstrings ^^menu_grep_options ];

	rc_control_panel("middle", "middle", grep_fields, title) ->;

enddefine;


endsection;
