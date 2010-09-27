/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_item_in_panelfield.p
 > Purpose:         Get an item from a panel field, given labels of
                        field and item
 > Author:          Aaron Sloman, and Mark Gemmell 31 Jul 2002 (see revisions)
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

define vars rc_item_in_panelfield(label, fieldlabel, panel) -> item;

    rc_informant_with_label(label, rc_fieldcontents_of(panel, fieldlabel)) -> item

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
 */
