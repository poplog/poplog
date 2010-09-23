/* --- The University of Birmingham 1995. ------
 > File:            $poplocal/local/menu/auto/menu_reset_menus.p
 > Purpose:         Reset all the menus
 > Author:          Aaron Sloman, Sun Dec  5 1993
 > Documentation:	Below
 > Related Files:	LIB * VED_MENU
 */

section;
uses menulib
uses menu_new_menu;
uses menu_dismiss_all;


define global vars procedure menu_reset_menus();
	;;; First remove them from the screen
	menu_dismiss_all();
	;;; clear the property, set the lists to be the values of the
	;;; variables, not the propboxes
	appproperty(menu_lists,
		procedure(propbox,val);
			lvars propbox, val;
			;;; val contains word and list
		val(2) -> valof(val(1));
			false -> menu_lists(propbox);
		endprocedure);
	false ->> menu_current_menu -> menu_current_box;
enddefine;

endsection;
