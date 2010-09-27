/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/auto/ved_menu_search.p
 > Originally:      $poplocal/local/menu/auto/ved_menu_search.p
 > Purpose:         Search control panel
 > Author:          Aaron Sloman, Jan 21 1995 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
-- Define a search control panel

ved_menu_search();
*/

section;


lvars
	search_string,
	;;; defaults
	search_options = ['CaseLess' 'Forward' 'Embedded' 'Wrap'],
	search_panel = false;

define lconstant do_search();
	dlocal vedediting ved_search_state;
	lvars
		options_list,
		caseless = true,
		embedded = false,
		forward = member('Forward', search_options),
		textinfield = rc_fieldcontents_of(rc_active_window_object, "textin"),
			;

	;;; Use the text input field, no matter what its state
	if rc_text_input_active(textinfield) then
		consolidate_or_activate(textinfield)
	endif;

	;;; Now get the options from the SOMEOF buttons		
	[%
		if member('CaseLess', search_options) then "nocase"
			else false -> caseless endif,
		unless member('Embedded', search_options) then "noembed"
			else true -> embedded endunless,
		unless member('Wrap', search_options) then "nowrap" endunless,
		if member('InRange', search_options) then "range" endif,
	%] -> options_list;

	ved_set_search(search_string, false, options_list);

	if forward then ved_re_search() else ved_re_backsearch() endif;

	lvars command, delimiter = '/';

	if forward then
		if embedded then '/' else '"' endif -> delimiter
	else
		if embedded then '\\' else '\`' endif -> delimiter ;
	endif;

	delimiter <> search_string <> delimiter -> command;
	unless command = vedcommand then vedputcommand(command) endunless;
	command -> vedcommand;
	vedrefreshstatus();
	vedcheck(); vedsetcursor();
		vedwiggle(vedline,vedcolumn);
enddefine;

define lconstant do_the_search(panel, string);
	returnif(iscaller(do_search));
	do_search();
enddefine;

define global procedure ved_menu_search();

	lvars
		menu_search_options =
			[
				[TEXT :
					'SEARCH FOR STRING OR PATTERN'
					'Type in search string or pattern,'
					'and select options' ]
				[SOMEOF
					{width 80}
					{ident ^(ident search_options)}:
					'CaseLess'
					'Embedded'
					'Forward'
					'Wrap'
					'InRange']
				[ACTIONS {cols 2}{spacing 10}:
					{blob 'Search' ^do_search}
					{blob 'Dismiss' rc_hide_panel}]
				[TEXTIN
					{label textin} {width 250}
					{ident ^(ident search_string)} {align left}
					{labelcolour 'grey10'}
					{reactor ^do_the_search}
					{labelstring 'Search Pattern:'} : '']
			];

	if search_panel then
		rc_show_window(search_panel)
	else
		rc_control_panel("middle", "middle", menu_search_options, 'Ved Search') -> search_panel;
	endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 18 1999
	Converted to RCLIB
 */
