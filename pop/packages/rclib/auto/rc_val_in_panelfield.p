/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:			$poplocal/local/rclib/auto/rc_val_in_panelfield.p
 > Purpose:			Get an val from a panel field, given labels of
                        field and item
 > Author:			Aaron Sloman, and Mark Gemmell 31 Jul 2002 (see revisions)
 > Documentation:
 > Related Files:
 */

section;

compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

uses rclib
uses rc_window_object
uses rc_informant
uses rc_control_panel

define vars rc_val_in_panelfield(label, fieldlabel, panel) -> val;
	;;; return/update the value of of the item with the label in the
	;;; field with the fieldlabel in the panel

	rc_informant_value(rc_item_in_panelfield(label, fieldlabel, panel)) -> val;

enddefine;

define updaterof rc_val_in_panelfield(val, label, fieldlabel, panel);
	;;; return/update the value of of the item with the label in the
	;;; field with the fieldlabel in the panel

	val -> rc_informant_value(rc_item_in_panelfield(label, fieldlabel, panel));

enddefine;



endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug 25 2002
	replaced rc_informant_contents with rc_informant_value
 */
