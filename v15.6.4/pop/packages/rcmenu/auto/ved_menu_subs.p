/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/auto/ved_menu_subs.p
 > Previously:      $poplocal/local/menu/auto/ved_menu_subs.p
 > Purpose:         Search and replace control panel
 > Author:          Aaron Sloman, Jan 21 1995 (see revisions)
 > Documentation:
 > Related Files:
 */

section;

uses rclib
uses rc_buttons
uses rc_control_panel

/*
   -- Define a search and replace control panel

ved_menu_subs();
*/

lvars
	search_string,
	replace_string,
	;;; defaults for SOMEOF buttons
	search_options = ['Embedded' 'Wrap' 'Interactive'],
	;;; Where to do the substitution
	range_option = "file",
	interact_option = 'Interactive',
	subs_panel = false;

define lconstant do_subs();
	dlocal vedediting ved_search_state;
	lvars
		options_list,
		caseless = true,
		embedded = false,
		wrapping = false,
		textinfield = rc_fieldcontents_of(rc_active_window_object, "textin"),
		replacefield = rc_fieldcontents_of(rc_active_window_object, "replacetext"),
			;

	;;; Use the text input field, no matter what its state
	if rc_text_input_active(textinfield) then
		consolidate_or_activate(textinfield)
	endif;
	;;; Use the text input field, no matter what its state
	if rc_text_input_active(replacefield) then
		consolidate_or_activate(replacefield)
	endif;

	;;; Now get the options from the SOMEOF and RADIO buttons		
	[%
		if member('CaseLess', search_options) then "nocase"
			else false -> caseless endif,
		unless member('Embedded', search_options) then "noembed"
			else true -> embedded endunless,
		if member('Wrap', search_options) then
			true -> wrapping
		else
			"nowrap"
		endif,
		range_option
	%] -> options_list;

	lvars mode, new_command = 's';

	if interact_option = 'Interactive' then
		range_option >< ' +ask'
	else
		'gs' -> new_command;
		range_option >< ' -ask'
	endif -> mode;

	unless wrapping then mode >< ' -wrap'  -> mode endunless;


	define run_search();
		lvars old_command = vedcommand;

		ved_set_search(search_string, replace_string, options_list);
		vedputcommand(new_command ->> vedcommand);

		vedrefreshstatus();
		ved_search_or_substitute(mode, true);

		;;; vedputcommand(old_command);
		vedrefreshstatus();
		vedcheck(); vedsetcursor();
	enddefine;

	if vedusewindows == "x" then
		vedinput(run_search)
	else
		run_search()
	endif;

/*
	;;; Fix this later ??
	lvars command, delimiter = 's/';

	if forward then
		if embedded then '/' else '"' endif -> delimiter
	else
		if embedded then '\\' else '\`' endif -> delimiter ;
	endif;

	delimiter <> search_string <> delimiter -> command;
	unless command = vedcommand then vedputcommand(command) endunless;
	command -> vedcommand;
*/
enddefine;

define lconstant do_the_subs(panel, string);
	returnif(iscaller(do_subs));
	do_subs();
enddefine;



define ved_menu_subs();
	lvars
		menu_subs_options =
			[
				[TEXT :
					'SEARCH AND REPLACE'
					;;; 'Type in search string or pattern.'
					;;;'Type in replacement string'
					'Decide whether embedded (part word) or not.'
					'Select other options']
				[SOMEOF
					{width 90}
					{ident ^(ident search_options)}:
					'Embedded'
					'Wrap'
					'CaseLess'
					]
				[TEXT : 'Select scope for search and replace:']
				[RADIO
					{width 95}{cols 4}
					{ident ^(ident range_option)}:
					file procedure range line paragraph window
					toendfile tostartfile
					]
				[TEXTIN
					{label textin} {width 260}
					{ident ^(ident search_string)} {align left}
					{fieldbg 'grey90'}
					{labelcolour 'grey10'}
					{labelstring 'Search String:'} : '']
				[TEXTIN
					{label replacetext} {width 260}
					{ident ^(ident replace_string)} {align left}
					{fieldbg 'grey90'}
					{labelcolour 'grey10'}
					{labelstring 'Replacement: '} : '']
				;;; [TEXT : 'Select Interactive or Automatic:']
				[RADIO
					{width 100}{cols 0}
					{ident ^(ident interact_option)}:
					'Interactive' 'Automatic']
				[ACTIONS {cols 2}{spacing 10}:
					{blob 'Do It' ^do_subs}
					{blob 'Dismiss' rc_hide_panel}]
			];

	if subs_panel then
		rc_show_window(subs_panel)
	else
		rc_control_panel("middle", "middle", menu_subs_options, 'Ved Search') -> subs_panel;
	endif;

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 18 1999
	Changed to use rclib
 */
