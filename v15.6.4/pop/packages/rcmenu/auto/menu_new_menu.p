/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/auto/menu_new_menu.p
 > Purpose:			RCLIB version of old "menu" program
 > Author:          Aaron Sloman, Aug  9 1999 (see revisions)
 > Documentation:	HELP * VED_MENU
 > Related Files:   LIB * VED_MENU, LIB * RCLIB, LIB * RCMENULIB
 > 					Various libraries in $poploca/local/rclib
 */


/* --- The University of Birmingham 1995. -------------------------
	ORIGINALLY
 > File:            $poplocal/local/menu/auto/menu_new_menu.p
 > Author:          Aaron Sloman, Jun 21 1993 (see revisions)
 */


/*
         CONTENTS

 -- USES commands
 -- Top level global variables and constants
 -- Utilities for operating on menus
 -- Use rc_control_panel to create a menu from a list

*/


;;; compile_mode :pop11 +strict;

section;

/*
-- USES commands
*/

uses rclib
uses rc_buttons
uses rc_control_panel

uses rcmenulib;	;;; sets up search lists and global variables
				;;; including menu_root menu_dirs and menu_user_dir

uses rc_defaults;

/*
-- Top level global variables and constants
*/


define :rc_defaults;

	;;; String which starts file names and identifier names for Menus
	menu_startstring = 'menu_' ;

	menu_toplevel_name = "menu_toplevel";

	;;; default location for top level menu: offset from bottom right
	menu_toplevel_location = {-180 bottom};

	menu_toplevel_name = "toplevel";

	menu_current_menu = false; 			;;; This is the current menu

	;;; This can be a vector e.g. {0 0} {-1 -5} {top left} {-120 bottom}
	;;; Negative numbers are subtracted from screen width or height
	;;; Default is bottom right corner
	menu_default_location = {right bottom}; 		;;;{-2 -2} ;

	menu_button_width = 88;
	menu_button_height = 20;

	;;; This may be too small on some screens, and too large on others.
	menu_font = '-adobe-helvetica-bold-r-normal-*-10-*-*-*-p-*-*-*';

	;;; Assign strings to these two if you wish to alter colours
	;;; of the buttons and their font
	menu_default_foreground = 'black';
	menu_default_background = 'white';

	menu_default_columns = 1;	;;; make it 0 for horizontal buttons
enddefine;

global vars

	;;; Font to be used in explanation boxes should be fairly big
	;;; NB this does not work in all cases, so should be unset
	;;; for now.
	menu_explanation_font,
	;;; = '-adobe-helvetica-bold-r-normal-*-12-*-*-*-p-*-*-*'

	;;; default location for explanation boxes
	menu_explanation_coords,
	;;; try {450 50},

	menu_explanation_foreground,
		;;; = 'yellow';
	menu_explanation_background,
		;;; = 'SlateBlue',

;

;;; Define a property to keep the original menu lists for rebuilding
global vars procedure menu_lists =
	newproperty([], 32, false, "tmparg");

/*
-- Utilities for operating on menus
*/

/*
;;; tests for next procedure
false -> pop_pr_quotes;
true -> pop_pr_quotes;
[%splitstring(
'the cat sat\non the very old\nand very shabby mat\nin the corner of the room'
) %]==>

*/

define lconstant splitstring(string) /* -> strings */ ;
	sys_parse_string(string,`\n`);
enddefine;

/*
-- Use rc_control_panel to create a menu from a list
*/

define menu_create_menu(word, menu_list);
	;;; This is the main menu creation procedure.
	;;; menu_list will have been read in using the define :menu construct
	;;; The first item should be a string to be used as the title of the
	;;; menu.
	;;; The rest of the list may start with a set of vectors specifying
	;;; properties the panel,
	;;; e.g. the kinds of two element vectors allowed in rc_control_panel.
	;;; After the vectors there can be a set of strings: they will be displayed
	;;; in a text field.
	;;; Then come the buttons.

	lvars word, menu_list, title, list,
		columnspec = {cols 1},
		coords = false;

    unless XptDefaultDisplay then XptDefaultSetup(); endunless;

	;;; Various defaults may need to be changed by lower level menus
	dlocal
		menu_default_columns, menu_font,
		menu_default_foreground, menu_default_background;

	;;; First the title, a string
	dest(menu_list) -> (title, list);
	check_string(title);

	lconstant
		xwords = [left middle right],
		ywords = [top middle bottom];


	;;; Now examine any vectors to see how they affect defaults.

	lvars panel_props =
		[%while isvector(hd(list)) do
		  lblock lvars vec;
			dest(list) -> (vec, list);
			if (isinteger(vec(1)) or lmember(vec(1), xwords))
			and (isinteger(vec(2))  or lmember(vec(2), ywords))
			then
				vec -> coords;
			elseif vec(1) = "cols" then vec -> columnspec;
			else
				vec	;;; save the vector for rc_control_panel
			endif;
			quitif(null(list));
		  endlblock;
		endwhile%];

	unless coords then menu_default_location -> coords endunless;

	lvars description = false ;
		
	if isstring(hd(list)) then
		;;; Starts with a string
		;;; Build up description list by collecting initial strings
		[TEXT : %
		while isstring(hd(list)) do
			splitstring(hd(list));
			tl(list) -> list;
		endwhile;
		%] -> description;
	endif;



	unless description then [TEXT : 'Select'] -> description endunless;

	;;; A procedure to recognize when a new type of field for
	;;; rc_control_panel has started, e.g. SLIDERS, RADIO, SOMEOF, etc
	define lconstant ispanelfield(item) -> boole;
		;;; must be alist starting with a recognised panel field type name
		false -> boole;
		if ispair(item) then
			lvars speclist, key = front(item);
			for speclist in rc_control_panel_keyspec do
				lvars (types, specs) = destpair(speclist);
				if lmember(key, types) then
					true -> boole;
					return()
				endif
			endfor;
		endif
	enddefine;

	;;;
	;;; now get the actions
	lvars actions =
		[ACTIONS
			;;; These defaults may be overridden by menu specs
			{textfg ^menu_default_foreground}
			{textbg ^menu_default_background}
			{font ^menu_font}
			{height ^menu_button_height}
			{width ^menu_button_width}
			^^panel_props ^columnspec :
			%
				until list == [] or ispanelfield(front(list)) do
					destpair(list) -> list
				enduntil;
			%
			{blob DISMISS rc_hide_panel}
		];


	;;; Build the list, with header information, the ACTIONS list ending with
	;;; a dismiss button, followed by any other types of rc_control_panel
	;;; fields
	lvars panel_specs =
		[{events [button]} ^description ^actions ^^list ];

	lvars menu_panel;
	rc_control_panel(explode(coords), panel_specs, title) -> menu_panel;

	;;; assign the widget to the word and make it current
	menu_panel -> valof(word);

	;;; not sure this is of any use
	menu_panel -> menu_current_menu;

	;;; Store it in the global property
	{^word ^menu_list} -> menu_lists(menu_panel);

enddefine;

define global menu_dismiss_all();
	;;; previously in a separate file
	;;; get rid of all menus
	appproperty(menu_lists,
		procedure(item,value);
			if isrc_window_object(item) and rc_widget(item)
			and XptIsLiveType( rc_widget(item), "Widget") then
				rc_hide_window(item);
			endif;
		endprocedure);
enddefine;


define lconstant DO_menu_new_menu(menu_name, reload);
	;;; The main procedure for creating menus given a name.
	;;; If reload == 1, it will always try to recompile from a
	;;; Library. If true it will rebuild the menu
	lvars menu, undefined = false, old = true;

	unless systranslate('DISPLAY') then
		vederror('$DISPLAY NOT SET');
	endunless;

	unless isstartstring(menu_startstring, menu_name) then
		consword(menu_startstring sys_>< menu_name)  -> menu_name;
	endunless;

	if isdeclared(menu_name)then
		;;; it is defined
		recursive_valof(menu_name) -> menu;
		if reload and isrc_window_object(menu) then
			rc_kill_window_object(menu);
			false -> old;
		endif;
	else
		true -> undefined;
		false -> old;
	endif;

	if undefined or isundef(menu) or reload == 1 then
		;;; Try to autoload or reload the menu definition from the library
		if syslibcompile(menu_name, menu_dirs)
		and isdeclared(menu_name)
		then
			recursive_valof(menu_name) -> menu;
		else
			mishap('WORD FOR MENU UNDEFINED', [^menu_name])
		endif;
	endif;

	;;;; Veddebug([menu ^menu]);

	if isrc_window_object(menu) then
		if rc_widget(menu) then
			if old then rc_raise_window else rc_show_window endif(menu);
			;;; not sure this is of any use
			menu -> menu_current_menu;
		else
			menu_create_menu(explode(menu_lists(menu)));
		endif;
	elseif islist(menu) then
		menu_create_menu(menu_name, menu)
	else
		mishap('CANNOT CREATE MENU ', [^menu_name ^menu])
	endif
enddefine;

define lconstant restore_window(win_obj);
	false -> rc_current_window_object;
	win_obj -> rc_current_window_object;
enddefine;

define menu_new_menu(menu_name, reload);
	;;; The main procedure for creating menus given a name.
	;;; If reload == 1, it will always try to recompile from a
	;;; Library. If true it will rebuild the menu

	;;; Make sure that creation of menus does not interfere with
	;;; existing windows, or window objects.
	lvars
		old_win_obj = rc_current_window_object,
		associated_obj = rc_window_object_of(rc_window);
	
	dlocal
		rc_xorigin, rc_yorigin, rc_xscale, rc_yscale, rc_window,
		rc_window_xsize, rc_window_ysize, rc_window_x, rc_window_y,
		rc_xposition , rc_yposition,
		rc_current_window_object;
	procedure();
		;;; stop rc_current_window_object being updated
		dlocal rc_current_window_object = false;
		DO_menu_new_menu(menu_name, reload);
	endprocedure();

	if old_win_obj then
		chain(old_win_obj , restore_window)
	elseif associated_obj then
		chain(associated_obj, restore_window)
	endif;
enddefine;

endsection;

nil -> proglist;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  7 2002
		Changed to stop panels being sensitive to mouse movement.
--- Aaron Sloman, Jul 22 2000
	Slightly reorganised, and changed to use smaller default font and smaller
	menu buttons.

	Fixed various default mechanisms to match documentation, and made sure that
	other types of rc_control_panel fields are handled properly.

--- Aaron Sloman, Oct  9 1999
	Changed so as not to leave rc_current_window_object set
--- Aaron Sloman, Sep 18 1999
	Changed to allow symbolic location specifier
--- Aaron Sloman, Sep 17 1999
	Fixed menu_dismiss_all with an extra check
--- Aaron Sloman, Aug 18 1999
	Made it "raise" existing menus.
--- Aaron Sloman, Aug 10 1999
	Added splitstring

--- 9 Aug 1999
	Changed to work with RCLIB

CONTENTS (define)

 define lconstant splitstring(string) /* -> strings */ ;
 define menu_create_menu(word, menu_list);
 define global menu_dismiss_all();
 define lconstant DO_menu_new_menu(menu_name, reload);
 define lconstant restore_window(win_obj);
 define menu_new_menu(menu_name, reload);

 */
