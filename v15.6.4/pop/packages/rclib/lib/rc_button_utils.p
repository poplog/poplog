/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_button_utils.p
 > Purpose:			Extras not essentail for LIB * RC_BUTTONS
					Probably totally redundant, but may be useful
					for tutorial purposes
 > Author:          Aaron Sloman, Jun 29 1997 (see revisions)
 > Documentation:	HELP * RC_BUTTONS
 > Related Files:	LIB * RC_BUTTONS
 */

section;
compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

uses rclib
uses rc_buttons

define create_action_button(x, y, width, height, label, action, specs) -> button;
	create_rc_button(x, y, width, height, label, "action", specs) -> button;
	if action then action else label endif -> rc_button_action(button);
enddefine;


define create_blob_button(x, y, width, height, label, action, specs) -> button;

	;;; check and if necessarily update default blob radius
	dlocal rc_button_blobrad_def;
	if rc_button_blobrad_def == 0 then
		round((height or rc_button_height_def)*0.2) -> rc_button_blobrad_def;
	endif;

	create_rc_button(x, y, width, height, label, "blob", specs) -> button;

	if action then action else label endif -> rc_button_action(button);

enddefine;

define create_option_button(x, y, width, height, label, specs) -> button;
	;;; either or both of width and height may be false
	create_rc_button(x, y, width, height, label, "option", specs) -> button;
enddefine;

define create_select_button(x, y, width, height, label, specs) -> button;
	;;; either or both of width and height may be false
	create_rc_button(x, y, width, height, label, "select", specs) -> button;
enddefine;

define create_radio_button_columns(x, y, width, height, spacing, columns, string, list, specs) -> buttons;

	rc_check_current_window('For create_radio_button_columns');

	lvars
		( , , stringH, ascent) = valof("rc_text_area")([^string], rc_button_font_def);
	;;; Print the string
	rc_print_at(x, y + ascent/rc_yscale, string);
	;;; create the buttons
	create_button_columns(
		x, y + (stringH + 1)/rc_yscale, width, height, spacing, columns, list, "radio", specs) -> buttons;
	;;; Now tell each button about all the others
	rc_inform_button_siblings(buttons);
enddefine;

define create_someof_button_columns(x, y, width, height, spacing, columns, string, list, specs) -> buttons;

	rc_check_current_window('For create_someof_button_columns');

	lvars
		( , , stringH, ascent) = valof("rc_text_area")([^string], rc_button_font_def);
	;;; Print the string
	rc_print_at(x, y + ascent/rc_yscale, string);
	;;; create the buttons
	create_button_columns(x, y + (stringH + 1)/rc_yscale, width, height, spacing, columns, list, "someof", specs) -> buttons;
	;;; Now tell each button about all the others
	rc_inform_button_siblings(buttons);
enddefine;

define create_button_row(x, y, width, height, spacing, list, type, specs) -> buttons;
	;;; specify 0 columns
	create_button_columns(x, y, width, height, spacing, 0, list, type, specs) -> buttons;
enddefine;


define create_button_column(x, y, width, height, spacing, list, type, specs) -> buttons;
	;;; specify 1 column
	create_button_columns(x, y, width, height, spacing, 1, list, type, specs) -> buttons;
enddefine;

;;; for uses
global vars rc_button_utils = true;

endsection;

/*
         CONTENTS

 define create_action_button(x, y, width, height, label, action, specs) -> button;
 define create_blob_button(x, y, width, height, label, action, specs) -> button;
 define create_option_button(x, y, width, height, label, specs) -> button;
 define create_select_button(x, y, width, height, label, specs) -> button;
 define create_radio_button_columns(x, y, width, height, spacing, columns, string, list, specs) -> buttons;
 define create_someof_button_columns(x, y, width, height, spacing, columns, string, list, specs) -> buttons;
 define create_button_row(x, y, width, height, spacing, list, type, specs) -> buttons;
 define create_button_column(x, y, width, height, spacing, list, type, specs) -> buttons;

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 12 2002
		REmoved bogus partial definition causing compilation error;
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Feb  3 1998
	Removed test example in middle. Updated HELP * RC_BUTTONS
--- Aaron Sloman, Nov  7 1997
	Added "uses"
	Made orientation independent, like rc_buttons.

 */
