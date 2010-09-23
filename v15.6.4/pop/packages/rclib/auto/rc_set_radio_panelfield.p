/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:			$poplocal/local/rclib/auto/rc_set_radio_panelfield.p
 > Purpose:			Set buttons in a radio field of a panel	
 > Author:			Aaron Sloman, Jul 31 2002 (see revisions)
 > Documentation:	HELP RCLIB, RC_BUTTONS, RC_CONTROL_PANEL
 > Related Files:	LIB RC_BUTTONS, RC_CONTROL_PANEL
					LIB rc_set_someof_panelfield
 */


section;

compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

define rc_set_radio_panelfield(item, field, panel);
	;;; Item is either "none" or one of the labels of the
	;;; buttons in the field. In the first case set them all off
	;;; and in the second case set the specified button on and
	;;; all the others off.
	rc_set_radio_buttons(item, rc_fieldcontents_of(panel, field));

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
 */
