/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:			$poplocal/local/rclib/auto/rc_button_in_panelfield.p
 > Purpose:			Get a button from a panel field
 > Author:			Aaron Sloman, and Mark Gemmell 31 Jul 2002
 > Documentation:
 > Related Files:
 */

section;

uses rclib
uses rc_window_object
uses rc_buttons
uses rc_control_panel

define rc_button_in_panelfield(label, fieldlabel, panel) -> button;
	
	rc_button_with_label(label, rc_fieldcontents_of(panel, fieldlabel)) -> button

enddefine;

endsection;
