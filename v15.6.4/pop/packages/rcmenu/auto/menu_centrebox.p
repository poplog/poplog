/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:			$poplocal/local/rcmenu/auto/menu_centrebox.p
 > Previously:		$poplocal/local/menu/auto/menu_centrebox.p
 > Purpose:         Utility for creating and displaying boxes
 > Author:          Aaron Sloman, Dec  5 1993 (see revisions)
 > Documentation:	HELP * VED_MENU
 > Related Files:	LIB * VED_MENU
 */

/*
-- A utility for creating and displaying panels (previously used propsheet)
(E.g. the Search and Substitute Control Panels.)
*/

section;

uses rclib
uses rc_control_panel
uses ved_menu


define lconstant getaction(box, menubutton, property, hide) -> result;
	;;; This is the callback associated with each centre box
    ;;; The third argument will be a property, which
	;;; maps menubutton names to actions; When invoked this procedure is
	;;; given the box and the selected menubutton (a word or string)
	;;; The fourth argument determines whether the box is hidden after
	;;; the action.
	;;; Return false to ensure that the menu is left displayed by
	;;; default. Actions can call propsheet_hide if necessary.
	lvars box, menubutton, property, P,
		result = hide;

	;;; set global variable
	box -> menu_current_box;

	;;; Get the action associated with the menubutton
	;;; 	(dereferencing as needed)
	recursive_valof(property(menubutton)) -> P;
	if P then
		;;; create a closure to do the action;
		XptDeferApply(menu_do_the_action(%box, P%));
		XptSetXtWakeup();
	elseif menubutton = "Dismiss" then
		propsheet_hide(box)
	endif
enddefine;

define global menu_centrebox(label, tellstring, actions, options, hide, ref);
	lvars
		label,		;;; for widget
		tellstring,	;;; explanatory text
		actions,	;;; like menu_subs_actions (associated with buttons)
		options,	;;; like menu_subs_options (to go in prop sheet)
		ref, 		;;; initially false, then holds the sheet.
		buttons		;;; names, in the actions
		hide,		;;; if true, hide the box after selection
		sheet,
		propbox;
		cont(ref) -> propbox;	;;; the cont of the ref is initially false

	if ispropbox(propbox) then
		;;; Use existing existing box
		propsheet_show(propbox)
	else
		;;; create propbox, show it, and store it in the ref
		maplist(actions, hd) <> [Dismiss] -> buttons;

		propsheet_new_box(
			label,
			false,
			getaction(%newmapping(actions, 4, false, false), hide%),
			buttons) ->> propbox -> cont(ref);

		if isstring(menu_explanation_font) then
			valof("menu_set_box_font")(propbox, menu_explanation_font);
		endif;

		;;; Now add the sheets spelling out the purpose, what to do and
		;;; the command format
		propsheet_new(tellstring, propbox, false) -> sheet;
		propsheet_field(sheet, options);
		propsheet_show(sheet);

		if	isstring(menu_explanation_foreground)
		and isstring(menu_explanation_background)
		then
		;;; postpone compilation till needed
		valof("menu_set_box_colours")(
				propbox,
				menu_explanation_foreground, menu_explanation_background);
		endif;
		XtRealizeWidget(propbox);
		XptCenterWidgetOn(propbox, "screen");
		propsheet_show(propbox);
	endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 22 1995
	Added the hide option, and copied getaction from ved_menu.p


         CONTENTS - (Use <ENTER> g to access required sections)

 define lconstant getaction(box, menubutton, property, hide) -> result;
 define global menu_centrebox(label, tellstring, actions, options, hide, ref);

 */
