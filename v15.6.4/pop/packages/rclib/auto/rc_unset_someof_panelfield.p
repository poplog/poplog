/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:			$poplocal/local/rclib/auto/rc_unset_someof_panelfield.p
 > Purpose:			Set buttons in a field of a panel	
 > Author:			Aaron Sloman, Jul 31 2002 (see revisions)
 > Documentation:	HELP RCLIB, RC_BUTTONS, RC_CONTROL_PANEL
 > Related Files:	LIB RC_BUTTONS, RC_CONTROL_PANEL
					LIB auto/rc_set_someof_panelfield.p
 */


section;

compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

define rc_unset_someof_panelfield(list, field, panel);
	;;; unset the buttons in the field of the panel if they have the
	;;; labels in the list. If list is "all" then unset all of them.
	rc_unset_someof_buttons(list, rc_fieldcontents_of(panel, field));

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 10 2002
		Fixed header and comment
 */
