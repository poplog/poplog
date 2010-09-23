/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:			$poplocal/local/rclib/auto/rc_set_someof_panelfield.p
 > Purpose:			Set buttons in a field of a panel	
 > Author:			Aaron Sloman, Jul 31 2002 (see revisions)
 > Documentation:	HELP RCLIB, RC_BUTTONS, RC_CONTROL_PANEL
 > Related Files:	LIB RC_BUTTONS, RC_CONTROL_PANEL
 >				    LIB rc_unset_someof_panelfield
 >				    LIB rc_set_radio_panelfield				
 */


section;

uses rclib
uses rc_buttons
uses rc_control_panel

compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;


define rc_set_someof_panelfield(list, field, panel);
	;;; List is either empty, which means set none of the buttons,
	;;; or the word "all" meaning set them all,
	;;; or a list of labels of buttons (usually strings). Select all the
	;;; buttons in list, leaving any others that were previously selected
	;;; still selected.

	rc_set_someof_buttons(list, rc_fieldcontents_of(panel, field));

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug 10 2002
		Fixed the comment and header
 */
